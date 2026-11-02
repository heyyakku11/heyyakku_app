import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:yakku/core/network/dio_error_mapper.dart';
import 'package:yakku/core/realtime/ask_back_realtime_service.dart';
import 'package:yakku/data/datasources/ask_back_remote_data_source.dart';
import 'package:yakku/data/models/ask_back/ask_back_models.dart';

/// The Ask Back conversation list, kept current by real-time events: a new
/// message moves its conversation to the top and bumps its unread count.
///
/// One instance lives for the app session. Call [start] after sign-in and
/// [reset] on sign-out.
class AskBackInboxController extends ChangeNotifier {
  AskBackInboxController({
    required AskBackRemoteDataSource remote,
    required AskBackRealtime realtime,
  }) : _remote = remote,
       _realtime = realtime;

  final AskBackRemoteDataSource _remote;
  final AskBackRealtime _realtime;

  final List<AskBackListItem> _items = <AskBackListItem>[];
  String? _nextCursor;
  bool _hasMore = false;
  bool _loading = false;
  bool _loadingMore = false;
  bool _loaded = false;
  String? _error;
  String? _activeId;
  bool _started = false;
  final List<StreamSubscription<Object?>> _subscriptions = [];
  Timer? _refreshDebounce;

  List<AskBackListItem> get items => List.unmodifiable(_items);
  bool get isLoading => _loading;
  bool get isLoadingMore => _loadingMore;
  bool get hasMore => _hasMore;
  bool get hasLoaded => _loaded;
  String? get error => _error;

  /// Unread messages across the conversations loaded so far (the badge).
  int get unreadTotal => _items.fold<int>(0, (sum, item) => sum + item.unreadCount);

  /// Starts listening and loads the first page. Safe to call again.
  Future<void> start() async {
    if (!_started) {
      _started = true;
      _subscriptions
        ..add(_realtime.messages.listen(_onMessage))
        ..add(_realtime.statuses.listen(_onStatus))
        ..add(_realtime.reconnected.listen((_) => refresh()));
    }
    // The list works without the socket; real-time just keeps it fresh.
    unawaited(_realtime.ensureConnected().catchError((Object _) {}));
    await refresh();
  }

  Future<void> refresh() async {
    if (_loading) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final page = await _remote.list();
      _items
        ..clear()
        ..addAll(page.items);
      _nextCursor = page.nextCursor;
      _hasMore = page.hasMore;
      _loaded = true;
    } catch (error) {
      _error = DioErrorMapper.map(error, fallback: 'Could not load conversations').message;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_loadingMore || _loading || !_hasMore || _nextCursor == null) return;
    _loadingMore = true;
    notifyListeners();
    try {
      final page = await _remote.list(cursor: _nextCursor);
      final known = _items.map((item) => item.id).toSet();
      _items.addAll(page.items.where((item) => !known.contains(item.id)));
      _nextCursor = page.nextCursor;
      _hasMore = page.hasMore;
    } catch (_) {
      // Keep what is loaded; scrolling to the end tries again.
    } finally {
      _loadingMore = false;
      notifyListeners();
    }
  }

  /// The chat for [id] is open: its messages are read as they arrive.
  void setActive(String id) => _activeId = id;

  void clearActive(String id) {
    if (_activeId == id) _activeId = null;
  }

  /// Everything in [id] was read on this device.
  void markRead(String id) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index < 0 || _items[index].unreadCount == 0) return;
    _items[index] = _items[index].copyWith(unreadCount: 0);
    notifyListeners();
  }

  /// A chat screen has newer details (status, mute) than the list.
  void sync(AskBackConversation conversation) {
    final index = _items.indexWhere((item) => item.id == conversation.id);
    if (index < 0) return;
    _items[index] = _items[index].copyWith(
      status: conversation.status,
      isMuted: conversation.isMuted,
    );
    notifyListeners();
  }

  void _onMessage(AskBackMessage message) {
    final index = _items.indexWhere((item) => item.id == message.conversationId);
    if (index < 0) {
      // A conversation the list has not seen (the first message of a new one).
      _scheduleRefresh();
      return;
    }

    final current = _items[index];
    final unread = message.isMine || _activeId == message.conversationId
        ? current.unreadCount
        : current.unreadCount + 1;
    final updated = current.copyWith(
      lastMessage: AskBackPreview(
        preview: message.content.replaceAll(RegExp(r'\s+'), ' '),
        isMine: message.isMine,
        createdAt: message.createdAt,
      ),
      lastActivityAt: message.createdAt,
      unreadCount: unread,
    );
    _items
      ..removeAt(index)
      ..insert(0, updated);
    notifyListeners();
  }

  void _onStatus(AskBackStatusEvent event) {
    final index = _items.indexWhere((item) => item.id == event.conversationId);
    if (index < 0) return;
    _items[index] = _items[index].copyWith(status: event.status);
    notifyListeners();
  }

  void _scheduleRefresh() {
    _refreshDebounce?.cancel();
    _refreshDebounce = Timer(const Duration(milliseconds: 500), refresh);
  }

  /// Sign-out: forget everything and close the socket.
  Future<void> reset() async {
    _refreshDebounce?.cancel();
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
    _started = false;
    _items.clear();
    _nextCursor = null;
    _hasMore = false;
    _loaded = false;
    _loading = false;
    _error = null;
    _activeId = null;
    notifyListeners();
    await _realtime.disconnect();
  }

  @override
  void dispose() {
    _refreshDebounce?.cancel();
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    super.dispose();
  }
}
