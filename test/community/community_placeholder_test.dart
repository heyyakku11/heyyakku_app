import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yakku/data/datasources/user_remote_data_source.dart';
import 'package:yakku/data/models/community/community_queued_question.dart';
import 'package:yakku/data/models/personality/personality_card.dart';
import 'package:yakku/data/repositories/personality_card_store.dart';
import 'package:yakku/presentation/screens/ask_back/ask_back_inbox_controller.dart';
import 'package:yakku/presentation/screens/community/community_placeholder.dart';

import '../ask_back/ask_back_controllers_test.dart' show FakeRealtime, FakeRemote;
import '../helpers/app_scope_fakes.dart';

PersonalityCard card({
  PersonalityCardStatus status = PersonalityCardStatus.completed,
  bool shareToCommunity = true,
  String shareCode = 'abc123',
}) {
  return PersonalityCard(
    shareCode: shareCode,
    status: status,
    selfTraits: const [],
    totalVotes: status == PersonalityCardStatus.completed ? 5 : 2,
    requiredVotes: 5,
    shareToCommunity: shareToCommunity,
  );
}

CommunityQueuedQuestion queued({
  required String id,
  required String question,
  List<String> tags = const ['career'],
  List<PersonalityTrait> traits = const [],
}) {
  final now = DateTime.utc(2026, 11, 19);
  return CommunityQueuedQuestion(
    id: id,
    question: question,
    tags: tags,
    createdAt: now,
    updatedAt: now,
    personalityTraits: traits,
  );
}

class _UserRemoteStub extends Fake implements UserRemoteDataSource {
  _UserRemoteStub({
    required this.card,
    List<CommunityQueuedQuestion>? queued,
  }) : queued = List.of(queued ?? const []);

  PersonalityCard card;
  final List<CommunityQueuedQuestion> queued;

  @override
  Future<PersonalityCard> getMyPersonalityCard() async => card;

  @override
  Future<List<PersonalityTrait>> getPersonalityTraits() async => const [];

  @override
  Future<void> joinCommunityWaitlist() async {}

  @override
  Future<List<CommunityQueuedQuestion>> listCommunityQueuedQuestions() async {
    return List.of(queued);
  }

  @override
  Future<CommunityQueuedQuestion> createCommunityQueuedQuestion({
    required String question,
    required List<String> tags,
  }) async {
    final item = CommunityQueuedQuestion(
      id: 'new-${queued.length + 1}',
      question: question,
      tags: tags,
      createdAt: DateTime.utc(2026, 11, 19),
      updatedAt: DateTime.utc(2026, 11, 19),
      personalityTraits: card.shareToCommunity
          ? const [PersonalityTrait(id: 't1', name: 'Loyal')]
          : const [],
    );
    queued.add(item);
    return item;
  }

  @override
  Future<CommunityQueuedQuestion> updateCommunityQueuedQuestion({
    required String id,
    required String question,
    required List<String> tags,
  }) async {
    final index = queued.indexWhere((item) => item.id == id);
    final existing = queued[index];
    final updated = CommunityQueuedQuestion(
      id: id,
      question: question,
      tags: tags,
      createdAt: existing.createdAt,
      updatedAt: DateTime.utc(2026, 11, 19, 2),
      personalityTraits: existing.personalityTraits,
    );
    queued[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteCommunityQueuedQuestion(String id) async {
    queued.removeWhere((item) => item.id == id);
  }
}

class _CardsStub extends Fake with ChangeNotifier implements PersonalityCardStore {
  _CardsStub(this._card);

  PersonalityCard? _card;

  @override
  PersonalityCard? get card => _card;

  @override
  List<PersonalityTrait> get traits => const [];

  @override
  List<String> get topTraits => const [];

  @override
  bool get loaded => true;

  @override
  Future<void> refresh() async {}

  void setCard(PersonalityCard? value) {
    _card = value;
    notifyListeners();
  }
}

Future<void> pumpCommunity(
  WidgetTester tester, {
  required PersonalityCard? personality,
  List<CommunityQueuedQuestion> queued = const [],
}) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final remote = _UserRemoteStub(
    card: personality ?? card(status: PersonalityCardStatus.draft),
    queued: queued,
  );
  final cards = _CardsStub(personality);
  final askBack = FakeRemote([]);
  final realtime = FakeRealtime();
  final inbox = AskBackInboxController(remote: askBack, realtime: realtime);

  await tester.pumpWidget(
    testAppScope(
      askBack: askBack,
      realtime: realtime,
      inbox: inbox,
      userRemote: remote,
      personalityCards: cards,
      child: const MaterialApp(home: Scaffold(body: CommunityPlaceholder())),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('draft status keeps early-access, not the queue form', (
    tester,
  ) async {
    await pumpCommunity(
      tester,
      personality: card(status: PersonalityCardStatus.draft),
    );

    expect(find.textContaining('friends describe you'), findsOneWidget);
    expect(find.text('EARLY ACCESS'), findsOneWidget);
    expect(find.text('Queue a question for the community'), findsNothing);
    expect(find.text('Queue my question'), findsNothing);
  });

  testWidgets('completed with empty queue shows the pink form', (tester) async {
    await pumpCommunity(tester, personality: card(), queued: const []);

    expect(find.text('ASK THE COMMUNITY'), findsOneWidget);
    expect(find.text('Goes live on day one'), findsOneWidget);
    expect(find.text('Queue a question for the community'), findsOneWidget);
    expect(find.text('Queue my question'), findsOneWidget);
    expect(find.text('Topic'), findsOneWidget);
    expect(find.text('Friendships'), findsOneWidget);
    expect(find.text('Get early access'), findsNothing);
  });

  testWidgets('completed with items shows list, chips, and queue-another under cap', (
    tester,
  ) async {
    await pumpCommunity(
      tester,
      personality: card(),
      queued: [
        queued(
          id: '1',
          question: 'Should I move cities?',
          tags: const ['friendships'],
          traits: const [PersonalityTrait(id: 't1', name: 'Brave')],
        ),
        queued(
          id: '2',
          question: 'Quit my job?',
          tags: const ['career', 'money'],
        ),
      ],
    );

    expect(find.text('YOUR QUEUED QUESTION'), findsNWidgets(2));
    expect(find.text('Should I move cities?'), findsOneWidget);
    expect(find.text('Friendships'), findsOneWidget);
    expect(find.text('Brave'), findsOneWidget);
    expect(find.text('Career'), findsOneWidget);
    expect(find.text('Money'), findsOneWidget);
    expect(
      find.text(
        '+ Queue another (up to ${CommunityQueuedQuestion.maxPerUser})',
      ),
      findsOneWidget,
    );
    expect(find.text('Queue a question for the community'), findsNothing);
  });

  testWidgets('at max 3 queued questions hides queue-another', (tester) async {
    await pumpCommunity(
      tester,
      personality: card(),
      queued: [
        queued(id: '1', question: 'Q1?'),
        queued(id: '2', question: 'Q2?'),
        queued(id: '3', question: 'Q3?'),
      ],
    );

    expect(find.text('YOUR QUEUED QUESTION'), findsNWidgets(3));
    expect(
      find.text(
        '+ Queue another (up to ${CommunityQueuedQuestion.maxPerUser})',
      ),
      findsNothing,
    );
  });

  testWidgets('trait chips appear only when API returns them (share on)', (
    tester,
  ) async {
    await pumpCommunity(
      tester,
      personality: card(shareToCommunity: true),
      queued: [
        queued(
          id: '1',
          question: 'Shared traits?',
          traits: const [
            PersonalityTrait(id: 't1', name: 'Loyal'),
            PersonalityTrait(id: 't2', name: 'Funny'),
          ],
        ),
      ],
    );

    expect(find.text('Loyal · Funny'), findsOneWidget);
  });

  testWidgets('no trait chips when sharing is off (empty personalityTraits)', (
    tester,
  ) async {
    await pumpCommunity(
      tester,
      personality: card(shareToCommunity: false),
      queued: [
        queued(
          id: '1',
          question: 'No traits please',
          tags: const ['family'],
        ),
      ],
    );

    expect(find.text('Family'), findsOneWidget);
    expect(find.textContaining('Loyal'), findsNothing);
    expect(find.textContaining('Funny'), findsNothing);
  });
}
