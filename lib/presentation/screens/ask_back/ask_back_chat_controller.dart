import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:yakku/core/network/api_exception.dart';
import 'package:yakku/core/network/dio_error_mapper.dart';
import 'package:yakku/core/realtime/ask_back_realtime_service.dart';
import 'package:yakku/data/datasources/ask_back_remote_data_source.dart';
import 'package:yakku/data/models/ask_back/ask_back_models.dart';
import 'package:yakku/presentation/screens/ask_back/ask_back_inbox_controller.dart';

enum ChatMessageState { sending, sent, failed }

/// A message on screen. [id] is null until the server has stored it.
class ChatMessage {
  ChatMessage({
    required this.clientMessageId,
    required this.content,
    required this.isMine,
    required this.createdAt,
    this.id,
    this.cursor,
    this.senderName = '',
    this.state = ChatMessageState.sent,
  });

  factory ChatMessage.fromServer(AskBackMessage message) {
    return ChatMessage(
      id: message.id,
      clientMessageId: message.clientMessageId,
      content: message.content,
      isMine: message.isMine,
      createdAt: message.createdAt,
      cursor: message.cursor,
      senderName: message.senderName,
    );
  }

  final String? id;
  final String clientMessageId;
  final String content;
  final bool isMine;
  final DateTime createdAt;
  final String? cursor;
  final String senderName;
  ChatMessageState state;
}

/// State of one open conversation: history, optimistic sending, real-time
/// events and catching up after a reconnect.
///
/// The REST API is the source of truth. A message can arrive twice (the send
/// response and the SignalR event), so everything is merged by message id and
/// by client message id.
class AskBackChatController extends ChangeNotifier {
  AskBackChatController({
    required this.conversationId,
    required AskBackRemoteDataSource remote,
    required AskBackRealtime realtime,
    required AskBackInboxController inbox,
  }) : _remote = remote,
       _realtime = realtime,
       _inbox = inbox;

  final String conversationId;
  final AskBackRemoteDataSource _remote;
  final AskBackRealtime _realtime;
  final AskBackInboxController _inbox;

  static const Uuid _uuid = Uuid();
  static const int maxLength = 2000;

  AskBackConversation? _conversation;
  final List<ChatMessage> _confirmed = <ChatMessage>[]; // oldest first
  final List<ChatMessage> _pending = <ChatMessage>[]; // sending or failed
  bool _loading = true;
  String? _error;
  bool _loadingOlder = false;
  bool _hasMoreOlder = false;
  String? _olderCursor;
  bool _otherTyping = false;
  bool _foreground = true;
  bool _disposed = false;
  String? _reportedReadId;
  String? _otherReadId;
  DateTime? _lastTypingSent;
  Timer? _typingStop;
  Timer? _otherTypingClear;
  final List<StreamSubscription<Object?>> _subscriptions = [];

  AskBackConversation? get conversation => _conversation;
  bool get isLoading => _loading;
  String? get error => _error;
  bool get isLoadingOlder => _loadingOlder;
  bool get hasMoreOlder => _hasMoreOlder;
  bool get otherTyping => _otherTyping;
  bool get canSend => _conversation?.canSend ?? false;
  ValueNotifier<bool> get connected => _realtime.isConnected;

  /// Oldest first; messages not yet stored by the server come last.
  List<ChatMessage> get messages => <ChatMessage>[..._confirmed, ..._pending];

  /// The latest of my messages the other person has read, to show "Seen".
  String? get lastSeenMessageId {
    final readAt = _readAt;
    if (readAt == null) return null;
    for (var i = _confirmed.length - 1; i >= 0; i--) {
      final message = _confirmed[i];
      if (message.isMine && !message.createdAt.isAfter(readAt)) return message.id;
    }
    return null;
  }

  DateTime? get _readAt {
    final id = _otherReadId;
    if (id == null) return null;
    for (final message in _confirmed) {
      if (message.id == id) return message.createdAt;
    }
    return null;
  }

  Future<void> init() async {
    _inbox.setActive(conversationId);
    _subscriptions
      ..add(_realtime.messages.where((m) => m.conversationId == conversationId).listen(_onIncoming))
      ..add(_realtime.reads.where((e) => e.conversationId == conversationId).listen(_onRead))
      ..add(_realtime.statuses.where((e) => e.conversationId == conversationId).listen((_) => refreshConversation()))
      ..add(_realtime.typing.where((e) => e.conversationId == conversationId).listen(_onTyping))
      ..add(_realtime.reconnected.listen((_) => catchUp()));
    await load();
    unawaited(_join());
  }

  Future<void> load() async {
    _loading = true;
    _error = null;
    _notify();
    try {
      final results = await Future.wait<Object>([
        _remote.get(conversationId),
        _remote.messages(conversationId),
      ]);
      _conversation = results[0] as AskBackConversation;
      final page = results[1] as AskBackPage<AskBackMessage>;
      _confirmed
        ..clear()
        ..addAll(page.items.map(ChatMessage.fromServer));
      _olderCursor = page.nextCursor;
      _hasMoreOlder = page.hasMore;
      _inbox.sync(_conversation!);
      unawaited(_markRead());
    } catch (error) {
      _error = DioErrorMapper.map(error, fallback: 'Could not open this conversation').message;
    } finally {
      _loading = false;
      _notify();
    }
  }

  Future<void> _join() async {
    try {
      await _realtime.join(conversationId);
    } catch (_) {
      // Offline or not allowed: REST still works, and a reconnect rejoins.
    }
  }

  Future<void> loadOlder() async {
    if (_loadingOlder || !_hasMoreOlder || _olderCursor == null) return;
    _loadingOlder = true;
    _notify();
    try {
      final page = await _remote.messages(conversationId, cursor: _olderCursor);
      final fresh = page.items.map(ChatMessage.fromServer).toList();
      for (final message in fresh) {
        _mergeConfirmed(message);
      }
      _olderCursor = page.nextCursor;
      _hasMoreOlder = page.hasMore;
    } catch (_) {
      // Scrolling up again retries.
    } finally {
      _loadingOlder = false;
      _notify();
    }
  }

  /// After a reconnect or coming back to the app: fetch what was missed.
  Future<void> catchUp() async {
    if (_disposed) return;
    try {
      var cursor = _confirmed.isEmpty ? null : _confirmed.last.cursor;
      if (cursor == null) {
        await load();
        return;
      }
      for (var i = 0; i < 20; i++) {
        final page = await _remote.messages(conversationId, cursor: cursor, newer: true);
        for (final message in page.items) {
          _mergeConfirmed(ChatMessage.fromServer(message));
        }
        if (!page.hasMore || page.nextCursor == null) break;
        cursor = page.nextCursor;
      }
      await refreshConversation();
      unawaited(_markRead());
      _notify();
    } catch (_) {
      // The next reconnect or resume tries again.
    }
  }

  Future<void> refreshConversation() async {
    try {
      _conversation = await _remote.get(conversationId);
      _inbox.sync(_conversation!);
      _notify();
    } catch (_) {
      // Keep the last known state.
    }
  }

  // ---- sending ----

  /// Sends [text] now, showing it at once. Returns false when nothing was sent.
  bool send(String text) {
    final content = text.trim();
    if (content.isEmpty || content.length > maxLength || !canSend) return false;
    final pending = ChatMessage(
      clientMessageId: _uuid.v4(),
      content: content,
      isMine: true,
      createdAt: DateTime.now().toUtc(),
      state: ChatMessageState.sending,
    );
    _pending.add(pending);
    _stopTyping();
    _notify();
    unawaited(_deliver(pending));
    return true;
  }

  /// Sends a failed message again. It keeps its client message id, so if the
  /// first attempt did reach the server nothing is duplicated.
  void retry(ChatMessage message) {
    if (message.state != ChatMessageState.failed) return;
    message.state = ChatMessageState.sending;
    _notify();
    unawaited(_deliver(message));
  }

  Future<void> _deliver(ChatMessage pending) async {
    try {
      final stored = await _remote.send(
        conversationId,
        clientMessageId: pending.clientMessageId,
        content: pending.content,
      );
      _mergeConfirmed(ChatMessage.fromServer(stored));
    } catch (error) {
      if (!_pending.contains(pending)) return; // already confirmed by an event
      pending.state = ChatMessageState.failed;
      final mapped = DioErrorMapper.map(error);
      if (mapped.kind == ApiErrorKind.conflict) {
        // Closed or blocked in the meantime.
        unawaited(refreshConversation());
      }
    }
    _notify();
  }

  // ---- incoming ----

  void _onIncoming(AskBackMessage message) {
    _mergeConfirmed(ChatMessage.fromServer(message));
    if (!message.isMine) {
      _otherTyping = false;
      unawaited(_markRead());
    }
    _notify();
  }

  void _onRead(AskBackReadEvent event) {
    _otherReadId = event.lastReadMessageId;
    _notify();
  }

  void _onTyping(({String conversationId, bool typing}) event) {
    _otherTypingClear?.cancel();
    _otherTyping = event.typing;
    if (event.typing) {
      // A lost "stopped" event must not leave the hint on forever.
      _otherTypingClear = Timer(const Duration(seconds: 6), () {
        _otherTyping = false;
        _notify();
      });
    }
    _notify();
  }

  /// Inserts or replaces by message id, then by client message id (which also
  /// resolves my own pending copy). Keeps [_confirmed] oldest first.
  void _mergeConfirmed(ChatMessage message) {
    _pending.removeWhere((pending) => pending.clientMessageId == message.clientMessageId && message.isMine);

    final byId = _confirmed.indexWhere((existing) => existing.id == message.id);
    if (byId >= 0) {
      _confirmed[byId] = message;
      return;
    }

    var index = _confirmed.length;
    while (index > 0 && _after(_confirmed[index - 1], message)) {
      index--;
    }
    _confirmed.insert(index, message);
  }

  bool _after(ChatMessage a, ChatMessage b) {
    final byTime = a.createdAt.compareTo(b.createdAt);
    return byTime > 0 || (byTime == 0 && (a.id ?? '').compareTo(b.id ?? '') > 0);
  }

  // ---- read state ----

  /// The app is in front (or not). Messages are read only while it is.
  void setForeground(bool foreground) {
    _foreground = foreground;
    if (foreground) {
      unawaited(catchUp());
    }
  }

  Future<void> _markRead() async {
    if (!_foreground || _disposed) return;
    ChatMessage? latest;
    for (var i = _confirmed.length - 1; i >= 0; i--) {
      if (!_confirmed[i].isMine) {
        latest = _confirmed[i];
        break;
      }
    }
    final id = latest?.id;
    if (id == null || id == _reportedReadId) {
      _inbox.markRead(conversationId);
      return;
    }
    _reportedReadId = id;
    _inbox.markRead(conversationId);
    try {
      await _remote.markRead(conversationId, id);
    } catch (_) {
      _reportedReadId = null; // try again with the next message
    }
  }

  // ---- typing ----

  /// Call as the text field changes.
  void onTextChanged(String text) {
    if (text.trim().isEmpty) {
      _stopTyping();
      return;
    }
    final now = DateTime.now();
    if (_lastTypingSent == null || now.difference(_lastTypingSent!) > const Duration(seconds: 3)) {
      _lastTypingSent = now;
      unawaited(_realtime.typingStarted(conversationId));
    }
    _typingStop?.cancel();
    _typingStop = Timer(const Duration(seconds: 2), _stopTyping);
  }

  void _stopTyping() {
    _typingStop?.cancel();
    if (_lastTypingSent != null) {
      _lastTypingSent = null;
      unawaited(_realtime.typingStopped(conversationId));
    }
  }

  // ---- actions ----

  Future<void> setMuted(bool muted) => _apply(() => _remote.setMuted(conversationId, muted));

  Future<void> closeConversation() => _apply(() => _remote.close(conversationId));

  Future<void> reopenConversation() => _apply(() => _remote.reopen(conversationId));

  Future<void> block({String? reason}) => _apply(() => _remote.block(conversationId, reason: reason));

  Future<void> unblock() => _apply(() => _remote.unblock(conversationId));

  Future<void> _apply(Future<AskBackConversation> Function() action) async {
    _conversation = await action();
    _inbox.sync(_conversation!);
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _typingStop?.cancel();
    _otherTypingClear?.cancel();
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    _inbox.clearActive(conversationId);
    unawaited(_realtime.leave(conversationId));
    super.dispose();
  }
}
