import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:signalr_netcore/signalr_client.dart';
import 'package:yakku/core/constants/api_constants.dart';
import 'package:yakku/core/network/api_routes.dart';
import 'package:yakku/data/models/ask_back/ask_back_models.dart';

/// Returns an access token that is valid now, refreshing it first when needed.
typedef AccessTokenProvider = Future<String?> Function();

/// The single SignalR connection to `/hubs/ask-back`.
///
/// The hub only delivers: messages are sent over REST, and the database is the
/// source of truth. After a reconnect, listeners get [reconnected] and fetch
/// whatever they missed from the history endpoint.
///
/// One connection serves the whole app. Screens call [ensureConnected] and
/// [join]/[leave] a conversation; the joins are remembered and restored when
/// the connection comes back.
/// What the controllers need from the real-time connection (a fake in tests).
abstract interface class AskBackRealtime {
  Stream<AskBackMessage> get messages;
  Stream<AskBackReadEvent> get reads;
  Stream<AskBackStatusEvent> get statuses;
  Stream<({String conversationId, bool typing})> get typing;
  Stream<void> get reconnected;
  ValueNotifier<bool> get isConnected;
  Future<void> ensureConnected();
  Future<void> join(String conversationId);
  Future<void> leave(String conversationId);
  Future<void> typingStarted(String conversationId);
  Future<void> typingStopped(String conversationId);
  Future<void> disconnect();
}

class AskBackRealtimeService implements AskBackRealtime {
  AskBackRealtimeService({required AccessTokenProvider accessToken})
    : _accessToken = accessToken;

  static const List<int> _retryDelaysMs = [0, 2000, 5000, 10000, 20000];
  static const Duration _reconnectAfterClose = Duration(seconds: 15);

  final AccessTokenProvider _accessToken;

  HubConnection? _connection;
  Future<void>? _starting;
  Timer? _retryTimer;
  bool _wanted = false;
  final Set<String> _joined = <String>{};

  final _messages = StreamController<AskBackMessage>.broadcast();
  final _reads = StreamController<AskBackReadEvent>.broadcast();
  final _statuses = StreamController<AskBackStatusEvent>.broadcast();
  final _typing =
      StreamController<({String conversationId, bool typing})>.broadcast();
  final _reconnected = StreamController<void>.broadcast();

  /// `ReceiveMessage`, for both sides (`isMine` says which).
  @override
  Stream<AskBackMessage> get messages => _messages.stream;

  /// `MessageRead`: the other person read up to a message.
  @override
  Stream<AskBackReadEvent> get reads => _reads.stream;

  /// `ConversationClosed` / `ConversationReopened`.
  @override
  Stream<AskBackStatusEvent> get statuses => _statuses.stream;

  /// `UserTyping` / `UserStoppedTyping` of the other person.
  @override
  Stream<({String conversationId, bool typing})> get typing => _typing.stream;

  /// Fires when the connection is (re)established after a drop. Fetch missed
  /// messages from the history endpoint when it does.
  @override
  Stream<void> get reconnected => _reconnected.stream;

  /// Drives the "reconnecting" hint in the UI.
  @override
  final ValueNotifier<bool> isConnected = ValueNotifier<bool>(false);

  /// Opens the connection if it is not open. Safe to call often.
  @override
  Future<void> ensureConnected() {
    _wanted = true;
    final connection = _connection;
    if (connection != null &&
        connection.state == HubConnectionState.Connected) {
      return Future<void>.value();
    }
    return _starting ??= _start().whenComplete(() => _starting = null);
  }

  Future<void> _start() async {
    try {
      final connection = _connection ??= _build();
      if (connection.state == HubConnectionState.Disconnected) {
        await connection.start();
      }
      isConnected.value = true;
      await _rejoinAll();
    } catch (_) {
      isConnected.value = false;
      _scheduleRetry();
      rethrow;
    }
  }

  HubConnection _build() {
    final connection = HubConnectionBuilder()
        .withUrl(
          '${ApiConstants.baseUrl}${ApiRoutes.askBackHub}',
          options: HttpConnectionOptions(
            // The token goes in the query string (access_token): a mobile
            // WebSocket cannot send an Authorization header.
            accessTokenFactory: () async => await _accessToken() ?? '',
            transport: HttpTransportType.WebSockets,
            skipNegotiation: true,
          ),
        )
        .withAutomaticReconnect(retryDelays: _retryDelaysMs)
        .build();

    connection.on('ReceiveMessage', (args) {
      final map = _first(args);
      if (map != null) _messages.add(AskBackMessage.fromJson(map));
    });
    connection.on('MessageRead', (args) {
      final map = _first(args);
      if (map == null) return;
      _reads.add(
        AskBackReadEvent(
          conversationId: map['conversationId'] as String,
          lastReadMessageId: map['lastReadMessageId'] as String,
        ),
      );
    });
    connection.on('ConversationClosed', (args) => _status(args));
    connection.on('ConversationReopened', (args) => _status(args));
    connection.on('UserTyping', (args) => _typingEvent(args, true));
    connection.on('UserStoppedTyping', (args) => _typingEvent(args, false));

    connection.onreconnecting(({error}) {
      isConnected.value = false;
    });
    connection.onreconnected(({connectionId}) async {
      isConnected.value = true;
      await _rejoinAll();
      _reconnected.add(null);
    });
    connection.onclose(({error}) {
      // Automatic reconnect gave up (or the server closed us).
      isConnected.value = false;
      _scheduleRetry();
    });
    return connection;
  }

  void _status(List<Object?>? args) {
    final map = _first(args);
    if (map == null) return;
    _statuses.add(
      AskBackStatusEvent(
        conversationId: map['conversationId'] as String,
        status: AskBackStatus.parse(map['status']),
      ),
    );
  }

  void _typingEvent(List<Object?>? args, bool typing) {
    final map = _first(args);
    if (map == null) return;
    _typing.add((
      conversationId: map['conversationId'] as String,
      typing: typing,
    ));
  }

  Map<String, dynamic>? _first(List<Object?>? args) {
    if (args == null || args.isEmpty) return null;
    final value = args.first;
    if (value is! Map) return null;
    try {
      return Map<String, dynamic>.from(value);
    } catch (_) {
      return null;
    }
  }

  void _scheduleRetry() {
    if (!_wanted || (_retryTimer?.isActive ?? false)) return;
    _retryTimer = Timer(_reconnectAfterClose, () {
      if (!_wanted) return;
      ensureConnected().then((_) => _reconnected.add(null), onError: (_) {});
    });
  }

  /// Joins the conversation's group (the server checks you are a participant).
  /// Remembered, so it is restored after a reconnect.
  @override
  Future<void> join(String conversationId) async {
    _joined.add(conversationId);
    await ensureConnected();
    await _invoke('JoinConversation', conversationId);
  }

  @override
  Future<void> leave(String conversationId) async {
    _joined.remove(conversationId);
    if (_connection?.state != HubConnectionState.Connected) return;
    try {
      await _invoke('LeaveConversation', conversationId);
    } catch (_) {
      // Leaving a conversation on a dropped connection needs nothing more.
    }
  }

  @override
  Future<void> typingStarted(String conversationId) =>
      _quiet('TypingStarted', conversationId);

  @override
  Future<void> typingStopped(String conversationId) =>
      _quiet('TypingStopped', conversationId);

  Future<void> _quiet(String method, String conversationId) async {
    if (_connection?.state != HubConnectionState.Connected) return;
    try {
      await _invoke(method, conversationId);
    } catch (_) {
      // Typing hints are best effort.
    }
  }

  Future<void> _invoke(String method, String conversationId) async {
    await _connection?.invoke(method, args: <Object>[conversationId]);
  }

  Future<void> _rejoinAll() async {
    for (final id in _joined.toList()) {
      try {
        await _invoke('JoinConversation', id);
      } catch (_) {
        // No longer a participant (or a transient error): the screen's next
        // fetch shows the truth, so stop trying to rejoin it.
        _joined.remove(id);
      }
    }
  }

  /// Closes the connection and forgets the joins (sign out).
  @override
  Future<void> disconnect() async {
    _wanted = false;
    _retryTimer?.cancel();
    _joined.clear();
    final connection = _connection;
    _connection = null;
    isConnected.value = false;
    try {
      await connection?.stop();
    } catch (_) {
      // Already closed.
    }
  }

  Future<void> dispose() async {
    await disconnect();
    await _messages.close();
    await _reads.close();
    await _statuses.close();
    await _typing.close();
    await _reconnected.close();
    isConnected.dispose();
  }

  /// Seconds until the JWT expires, or null when it cannot be read.
  static int? secondsUntilExpiry(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final exp = (jsonDecode(payload) as Map<String, dynamic>)['exp'];
      if (exp is! num) return null;
      return exp.toInt() - DateTime.now().millisecondsSinceEpoch ~/ 1000;
    } catch (_) {
      return null;
    }
  }
}
