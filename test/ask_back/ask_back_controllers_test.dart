import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yakku/core/network/api_exception.dart';
import 'package:yakku/core/realtime/ask_back_realtime_service.dart';
import 'package:yakku/data/datasources/ask_back_remote_data_source.dart';
import 'package:yakku/data/models/ask_back/ask_back_models.dart';
import 'package:yakku/presentation/screens/ask_back/ask_back_chat_controller.dart';
import 'package:yakku/presentation/screens/ask_back/ask_back_inbox_controller.dart';

const String conversationId = 'c1';

AskBackConversation conversation({
  AskBackStatus status = AskBackStatus.active,
  bool canSend = true,
}) {
  return AskBackConversation(
    id: conversationId,
    status: status,
    myRole: 'asker',
    other: const AskBackParticipant(anonymousName: 'Quiet Fox'),
    context: const AskBackContext(
      contentType: 'poll',
      question: 'Which is better?',
      selectedOption: 'A',
      reason: 'Clearer',
    ),
    createdAt: DateTime.utc(2026, 10, 30),
    isMuted: false,
    unreadCount: 0,
    canSend: canSend,
    canReopen: false,
    canUnblock: false,
  );
}

AskBackMessage message(
  int n, {
  bool mine = false,
  String? clientId,
  String conversation = conversationId,
}) {
  final at = DateTime.utc(2026, 10, 30, 9, 0, n);
  return AskBackMessage(
    id: 'm$n',
    conversationId: conversation,
    clientMessageId: clientId ?? 'client-$n',
    content: 'message $n',
    senderName: mine ? 'Me' : 'Quiet Fox',
    isMine: mine,
    createdAt: at,
    cursor: 'cursor-$n',
  );
}

/// An in-memory server: stores messages, pages them, and is idempotent on the client message id.
class FakeRemote implements AskBackRemoteDataSource {
  FakeRemote(this.stored, {this.pageSize = 3});

  final List<AskBackMessage> stored;
  final int pageSize;
  AskBackConversation current = conversation();
  int failSends = 0;
  final List<String> sentClientIds = [];
  final List<String> readCalls = [];
  int nextId = 100;

  @override
  Future<AskBackConversation> get(String id) async => current;

  @override
  Future<AskBackPage<AskBackMessage>> messages(
    String id, {
    String? cursor,
    bool newer = false,
  }) async {
    int indexOf(String c) => stored.indexWhere((m) => m.cursor == c);
    if (newer) {
      final from = indexOf(cursor!) + 1;
      final rest = stored.sublist(from);
      final page = rest.take(pageSize).toList();
      final more = rest.length > pageSize;
      return AskBackPage(
        items: page,
        nextCursor: more ? page.last.cursor : null,
        hasMore: more,
      );
    }
    final end = cursor == null ? stored.length : indexOf(cursor);
    final start = (end - pageSize).clamp(0, end);
    final page = stored.sublist(start, end);
    return AskBackPage(
      items: page,
      nextCursor: start > 0 ? page.first.cursor : null,
      hasMore: start > 0,
    );
  }

  @override
  Future<AskBackMessage> send(
    String id, {
    required String clientMessageId,
    required String content,
  }) async {
    sentClientIds.add(clientMessageId);
    if (failSends > 0) {
      failSends--;
      throw const ApiException(kind: ApiErrorKind.connection, message: 'offline');
    }
    final existing = stored.where((m) => m.clientMessageId == clientMessageId);
    if (existing.isNotEmpty) return existing.first;
    final n = nextId++;
    final saved = AskBackMessage(
      id: 'm$n',
      conversationId: conversationId,
      clientMessageId: clientMessageId,
      content: content,
      senderName: 'Me',
      isMine: true,
      createdAt: DateTime.utc(2026, 10, 30, 10, 0, n - 100),
      cursor: 'cursor-$n',
    );
    stored.add(saved);
    return saved;
  }

  @override
  Future<AskBackReadResult> markRead(String id, String lastReadMessageId) async {
    readCalls.add(lastReadMessageId);
    return const AskBackReadResult(advanced: true, unreadCount: 0);
  }

  @override
  Future<AskBackPage<AskBackListItem>> list({String? cursor}) async {
    return AskBackPage(items: listItems, nextCursor: null, hasMore: false);
  }

  List<AskBackListItem> listItems = [];

  @override
  Future<AskBackConversation> start(String voteId) async => current;

  @override
  Future<AskBackConversation> setMuted(String id, bool muted) async => current;

  @override
  Future<AskBackConversation> close(String id) async => current;

  @override
  Future<AskBackConversation> reopen(String id) async => current;

  @override
  Future<AskBackConversation> block(String id, {String? reason}) async => current;

  @override
  Future<AskBackConversation> unblock(String id) async => current;
}

class FakeRealtime implements AskBackRealtime {
  final messageEvents = StreamController<AskBackMessage>.broadcast();
  final readEvents = StreamController<AskBackReadEvent>.broadcast();
  final statusEvents = StreamController<AskBackStatusEvent>.broadcast();
  final typingEvents =
      StreamController<({String conversationId, bool typing})>.broadcast();
  final reconnectEvents = StreamController<void>.broadcast();
  final List<String> joined = [];
  final List<String> left = [];

  @override
  Stream<AskBackMessage> get messages => messageEvents.stream;
  @override
  Stream<AskBackReadEvent> get reads => readEvents.stream;
  @override
  Stream<AskBackStatusEvent> get statuses => statusEvents.stream;
  @override
  Stream<({String conversationId, bool typing})> get typing => typingEvents.stream;
  @override
  Stream<void> get reconnected => reconnectEvents.stream;
  @override
  final ValueNotifier<bool> isConnected = ValueNotifier<bool>(true);

  @override
  Future<void> ensureConnected() async {}
  @override
  Future<void> join(String id) async => joined.add(id);
  @override
  Future<void> leave(String id) async => left.add(id);
  @override
  Future<void> typingStarted(String id) async {}
  @override
  Future<void> typingStopped(String id) async {}
  @override
  Future<void> disconnect() async {}
}

void main() {
  late FakeRemote remote;
  late FakeRealtime realtime;
  late AskBackInboxController inbox;
  late AskBackChatController chat;

  Future<void> open(List<AskBackMessage> history) async {
    remote = FakeRemote(history);
    realtime = FakeRealtime();
    inbox = AskBackInboxController(remote: remote, realtime: realtime);
    chat = AskBackChatController(
      conversationId: conversationId,
      remote: remote,
      realtime: realtime,
      inbox: inbox,
    );
    await chat.init();
    await pumpEventQueue();
  }

  tearDown(() => chat.dispose());

  test('opens with the newest page, joins the group and marks the latest incoming message read', () async {
    await open([message(1), message(2, mine: true), message(3), message(4), message(5, mine: true)]);

    expect(chat.messages.map((m) => m.id), ['m3', 'm4', 'm5']);
    expect(chat.hasMoreOlder, isTrue);
    expect(realtime.joined, [conversationId]);
    expect(remote.readCalls, ['m4']);
  });

  test('loading older messages prepends them without duplicates', () async {
    await open([for (var i = 1; i <= 8; i++) message(i)]);
    expect(chat.messages.map((m) => m.id), ['m6', 'm7', 'm8']);

    await chat.loadOlder();
    await chat.loadOlder();
    await chat.loadOlder();

    expect(chat.messages.map((m) => m.id), ['m1', 'm2', 'm3', 'm4', 'm5', 'm6', 'm7', 'm8']);
    expect(chat.hasMoreOlder, isFalse);
  });

  test('a sent message shows at once, then becomes the stored one', () async {
    await open([message(1)]);

    expect(chat.send('  hello  '), isTrue);
    expect(chat.messages.last.state, ChatMessageState.sending);
    expect(chat.messages.last.id, isNull);
    await pumpEventQueue();

    expect(chat.messages.last.state, ChatMessageState.sent);
    expect(chat.messages.last.id, isNotNull);
    expect(chat.messages.last.content, 'hello');
    expect(chat.messages.where((m) => m.isMine), hasLength(1));
  });

  test('the REST response and the SignalR event for one message never duplicate it', () async {
    await open([message(1)]);

    chat.send('hello');
    final clientId = remote.sentClientIds.single;
    await pumpEventQueue();
    // The same message arrives again over the socket (isMine for the sender's own devices).
    realtime.messageEvents.add(remote.stored.last);
    // And once more, plus a replay of an old one.
    realtime.messageEvents.add(remote.stored.last);
    realtime.messageEvents.add(message(1));
    await pumpEventQueue();

    expect(chat.messages.where((m) => m.clientMessageId == clientId), hasLength(1));
    expect(chat.messages.map((m) => m.id).toSet().length, chat.messages.length);
    expect(chat.messages, hasLength(2));
  });

  test('the socket event can arrive before the REST response', () async {
    await open([message(1)]);

    final completer = Completer<AskBackMessage>();
    final slow = _SlowRemote(remote, completer);
    final slowChat = AskBackChatController(
      conversationId: conversationId,
      remote: slow,
      realtime: realtime,
      inbox: inbox,
    );
    await slowChat.init();
    await pumpEventQueue();

    slowChat.send('racing');
    final saved = message(50, mine: true, clientId: slow.lastClientId);
    realtime.messageEvents.add(saved);
    await pumpEventQueue();
    expect(slowChat.messages.where((m) => m.isMine), hasLength(1));
    expect(slowChat.messages.last.state, ChatMessageState.sent);

    completer.complete(saved);
    await pumpEventQueue();
    expect(slowChat.messages.where((m) => m.isMine), hasLength(1));
    slowChat.dispose();
  });

  test('a failed send can be retried with the same client message id and is stored once', () async {
    await open([message(1)]);
    remote.failSends = 1;

    chat.send('please');
    await pumpEventQueue();
    final failed = chat.messages.last;
    expect(failed.state, ChatMessageState.failed);

    chat.retry(failed);
    await pumpEventQueue();

    expect(remote.sentClientIds, hasLength(2));
    expect(remote.sentClientIds.toSet(), hasLength(1));
    expect(chat.messages.where((m) => m.isMine), hasLength(1));
    expect(chat.messages.last.state, ChatMessageState.sent);
    expect(remote.stored.where((m) => m.isMine), hasLength(1));
  });

  test('empty, whitespace and over-long messages are not sent', () async {
    await open([message(1)]);

    expect(chat.send('   '), isFalse);
    expect(chat.send('x' * 2001), isFalse);
    expect(chat.send('x' * 2000), isTrue);
    await pumpEventQueue();

    expect(remote.sentClientIds, hasLength(1));
  });

  test('nothing is sent while the conversation is closed or blocked', () async {
    await open([message(1)]);
    remote.current = conversation(status: AskBackStatus.closed, canSend: false);
    await chat.refreshConversation();

    expect(chat.canSend, isFalse);
    expect(chat.send('too late'), isFalse);
    expect(remote.sentClientIds, isEmpty);
  });

  test('an incoming message is appended, read, and clears the typing hint', () async {
    await open([message(1)]);
    realtime.typingEvents.add((conversationId: conversationId, typing: true));
    await pumpEventQueue();
    expect(chat.otherTyping, isTrue);

    realtime.messageEvents.add(message(2));
    await pumpEventQueue();

    expect(chat.messages.map((m) => m.id), ['m1', 'm2']);
    expect(chat.otherTyping, isFalse);
    expect(remote.readCalls.last, 'm2');
  });

  test('events of other conversations are ignored', () async {
    await open([message(1)]);

    realtime.messageEvents.add(message(9, conversation: 'someone-else'));
    await pumpEventQueue();

    expect(chat.messages.map((m) => m.id), ['m1']);
  });

  test('after a reconnect the messages missed while offline are fetched from history', () async {
    await open([message(1), message(2)]);
    // Four messages arrive while the socket is down.
    remote.stored.addAll([message(3), message(4), message(5), message(6)]);

    realtime.reconnectEvents.add(null);
    await pumpEventQueue();

    expect(chat.messages.map((m) => m.id), ['m1', 'm2', 'm3', 'm4', 'm5', 'm6']);
    expect(remote.readCalls.last, 'm6');
  });

  test('the other person reading shows Seen on my latest read message', () async {
    await open([message(1), message(2, mine: true), message(3, mine: true)]);

    realtime.readEvents.add(const AskBackReadEvent(conversationId: conversationId, lastReadMessageId: 'm2'));
    await pumpEventQueue();

    expect(chat.lastSeenMessageId, 'm2');
  });

  test('leaving the screen leaves the group and releases the active conversation', () async {
    await open([message(1)]);

    chat.dispose();
    await pumpEventQueue();

    expect(realtime.left, [conversationId]);
    // tearDown disposes again; the controller tolerates it.
    chat = AskBackChatController(
      conversationId: conversationId,
      remote: remote,
      realtime: realtime,
      inbox: inbox,
    );
  });

  group('conversation list', () {
    AskBackListItem item(String id, {int unread = 0}) => AskBackListItem(
      id: id,
      status: AskBackStatus.active,
      myRole: 'asker',
      other: AskBackParticipant(anonymousName: 'Fox $id'),
      lastMessage: null,
      lastActivityAt: DateTime.utc(2026, 10, 30),
      unreadCount: unread,
      isMuted: false,
    );

    test('a new message moves its conversation to the top and counts as unread', () async {
      await open([message(1)]);
      remote.listItems = [item('a'), item('b'), item('c')];
      await inbox.start();

      realtime.messageEvents.add(message(7, conversation: 'c'));
      await pumpEventQueue();

      expect(inbox.items.map((i) => i.id), ['c', 'a', 'b']);
      expect(inbox.items.first.unreadCount, 1);
      expect(inbox.items.first.lastMessage!.preview, 'message 7');
      expect(inbox.unreadTotal, 1);
    });

    test('a message in the open conversation, or my own, does not add unread', () async {
      await open([message(1)]);
      remote.listItems = [item('a'), item('b')];
      await inbox.start();
      inbox.setActive('b');

      realtime.messageEvents.add(message(7, conversation: 'b'));
      realtime.messageEvents.add(message(8, conversation: 'a', mine: true));
      await pumpEventQueue();

      expect(inbox.unreadTotal, 0);
      expect(inbox.items.first.id, 'a');
    });

    test('reading a conversation clears its unread count', () async {
      await open([message(1)]);
      remote.listItems = [item('a', unread: 4)];
      await inbox.start();

      inbox.markRead('a');

      expect(inbox.unreadTotal, 0);
    });

    test('a status event updates the conversation', () async {
      await open([message(1)]);
      remote.listItems = [item('a')];
      await inbox.start();

      realtime.statusEvents.add(const AskBackStatusEvent(conversationId: 'a', status: AskBackStatus.blocked));
      await pumpEventQueue();

      expect(inbox.items.single.status, AskBackStatus.blocked);
    });
  });

  group('models', () {
    test('conversation JSON parses and never needs a user id', () {
      final parsed = AskBackConversation.fromJson({
        'id': 'x',
        'status': 'blocked',
        'myRole': 'voter',
        'other': {'anonymousName': 'Quiet Fox', 'isDeleted': true},
        'context': {'contentType': 'check', 'question': 'Q', 'selectedOption': null, 'reason': null},
        'createdAt': '2026-10-30T09:00:00Z',
        'isMuted': true,
        'unreadCount': 2,
        'canSend': false,
        'canReopen': false,
        'canUnblock': true,
      });

      expect(parsed.status, AskBackStatus.blocked);
      expect(parsed.isAsker, isFalse);
      expect(parsed.other.isDeleted, isTrue);
      expect(parsed.context.reason, isNull);
      expect(parsed.canUnblock, isTrue);
    });

    test('an unknown status falls back to active', () {
      expect(AskBackStatus.parse('something-new'), AskBackStatus.active);
      expect(AskBackStatus.parse(null), AskBackStatus.active);
    });

    test('the socket token helper reads the JWT expiry', () {
      // header.payload.signature with exp one hour from now
      final exp = DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600;
      final payload = base64Url.encode(utf8.encode('{"exp":$exp}')).replaceAll('=', '');
      final left = AskBackRealtimeService.secondsUntilExpiry('h.$payload.s');
      expect(left, inInclusiveRange(3590, 3600));
      expect(AskBackRealtimeService.secondsUntilExpiry('not-a-jwt'), isNull);
    });
  });
}

/// Holds the REST response until the test completes it, to put the socket event first.
class _SlowRemote extends FakeRemote {
  _SlowRemote(FakeRemote inner, this.completer) : super(inner.stored);

  final Completer<AskBackMessage> completer;
  String lastClientId = '';

  @override
  Future<AskBackMessage> send(
    String id, {
    required String clientMessageId,
    required String content,
  }) {
    lastClientId = clientMessageId;
    return completer.future;
  }
}
