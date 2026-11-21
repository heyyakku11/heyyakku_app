import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yakku/data/datasources/user_remote_data_source.dart';
import 'package:yakku/data/models/ask_back/ask_back_models.dart';
import 'package:yakku/data/models/checks/user_check_response.dart';
import 'package:yakku/data/models/plans/yakku_plan.dart';
import 'package:yakku/data/models/poll/poll_reason.dart';
import 'package:yakku/presentation/screens/ask_back/ask_back_inbox_controller.dart';
import 'package:yakku/presentation/screens/card_results_screen.dart';
import 'package:yakku/presentation/screens/option_results_detail_screen.dart';

import '../ask_back/ask_back_controllers_test.dart'
    show FakeRealtime, FakeRemote;
import '../helpers/app_scope_fakes.dart';
PollReason reason(String id, String text, {bool hidden = false}) =>
    PollReason(id: id, text: text, canAskBack: true, isHidden: hidden);

List<YakkuPlan> _sampleCatalog() => const [
      YakkuPlan(
        id: 'free',
        code: YakkuPlan.freeCode,
        name: 'Free',
        priceMinor: 0,
        currency: 'INR',
      ),
      YakkuPlan(
        id: 'card',
        code: YakkuPlan.thisCardCode,
        name: 'This card',
        priceMinor: 4900,
        currency: 'INR',
        unlockTickets: 1,
        askBackMessageLimit: 1,
      ),
      YakkuPlan(
        id: 'lite',
        code: YakkuPlan.liteCode,
        name: 'Yakku Lite',
        priceMinor: 9900,
        currency: 'INR',
        durationDays: 7,
        unlockTickets: 3,
        askBackMessageLimit: 3,
      ),
      YakkuPlan(
        id: 'love',
        code: YakkuPlan.loveCode,
        name: 'Yakku Love',
        priceMinor: 29900,
        currency: 'INR',
        durationDays: 30,
      ),
    ];

class _PlansUserRemote extends Fake implements UserRemoteDataSource {
  _PlansUserRemote({required this.plans});

  final List<YakkuPlan> plans;

  @override
  Future<List<YakkuPlan>> listPlans() async => plans;
}

AskBackAccess access({
  required bool revealed,
  bool unlocked = false,
  bool paused = false,
  bool? canUnlock,
  int? ticketsLeft,
}) => AskBackAccess(
  unlocked: unlocked,
  paused: paused,
  planCode: revealed || unlocked ? 'yakku_lite' : 'free',
  planName: revealed || unlocked ? 'Yakku Lite' : 'Free',
  planExpired: false,
  canUnlock: canUnlock ?? (revealed && !unlocked),
  reasonsRevealed: revealed,
  ticketsLeft: ticketsLeft ?? (revealed && !unlocked ? 3 : null),
  unlockSource: unlocked ? 'purchase' : null,
);

Future<void> openReasons(
  WidgetTester tester,
  List<PollReason> reasons, {
  int hiddenCount = 0,
  AskBackAccess? cardAccess,
  String? contentType = 'poll',
  String? contentId = 'poll-1',
}) async {
  tester.view.physicalSize = const Size(800, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final remote = FakeRemote([])
    ..access = cardAccess ?? access(revealed: false);
  final realtime = FakeRealtime();
  await tester.pumpWidget(
    testAppScope(
      askBack: remote,
      realtime: realtime,
      inbox: AskBackInboxController(remote: remote, realtime: realtime),
      userRemote: _PlansUserRemote(plans: _sampleCatalog()),
      child: MaterialApp(
        home: OptionReasonsScreen(
          label: 'Like having you around',
          percent: 46,
          fraction: 0.46,
          votes: reasons.length,
          count: reasons.length,
          loadReasons: () async =>
              PollReasonList(items: reasons, hiddenCount: hiddenCount),
          onReport: (_) async => null,
          contentType: contentType,
          contentId: contentId,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// A made check with 3 reasons on A and 2 on B, so 3 reasons are hidden on the
/// free plan.
UserCheckResponse madeCheck() => const UserCheckResponse(
  id: 'check-1',
  checkId: 'c1',
  title: 'Mirror Check',
  question: 'Do people like me?',
  backgroundColor: '#D02E62',
  shareCode: 'abc',
  isOwner: true,
  totalVotes: 6,
  customAnswerVotes: 0,
  resultsUnlocked: true,
  voteProgress: 6,
  options: [
    UserCheckOptionResponse(
      id: 'a',
      text: 'Like having you',
      votes: 4,
      whyCount: 3,
    ),
    UserCheckOptionResponse(
      id: 'b',
      text: 'Genuinely like you',
      votes: 2,
      whyCount: 2,
    ),
  ],
);

Future<FakeRemote> openResults(
  WidgetTester tester, {
  required bool revealed,
}) async {
  tester.view.physicalSize = const Size(800, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final remote = FakeRemote([])..access = access(revealed: revealed);
  final realtime = FakeRealtime();
  await tester.pumpWidget(
    testAppScope(
      askBack: remote,
      realtime: realtime,
      inbox: AskBackInboxController(remote: remote, realtime: realtime),
      child: MaterialApp(home: CardResultsScreen.check(check: madeCheck())),
    ),
  );
  // Share-more shake repeats forever; settle would hang.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  return remote;
}

void main() {
  group('reasons screen on the free plan', () {
    final mixed = [
      reason('1', 'You make every plan better, but I am not sure I know you.'),
      reason('2', '', hidden: true),
      reason('3', '', hidden: true),
    ];

    testWidgets('shows the top reason and blurs the rest behind one button', (
      tester,
    ) async {
      await openReasons(tester, mixed, hiddenCount: 2);

      expect(find.textContaining('You make every plan better'), findsOneWidget);
      expect(find.text('Ask back'), findsOneWidget);
      expect(find.text('1 free \u00B7 2 hidden'), findsOneWidget);
      expect(find.text('2 more reasons \u00B7 Unlock now'), findsOneWidget);
      // The blurred cards are made-up stand-ins, not the voters' words.
      expect(find.byKey(const ValueKey('hidden-reasons')), findsOneWidget);
    });

    testWidgets('one hidden reason is worded in the singular', (tester) async {
      await openReasons(tester, [mixed.first, mixed[1]], hiddenCount: 1);

      expect(find.text('1 more reason \u00B7 Unlock now'), findsOneWidget);
      expect(find.text('1 free \u00B7 1 hidden'), findsOneWidget);
    });

    testWidgets('tapping the button opens the plans sheet', (tester) async {
      await openReasons(tester, mixed, hiddenCount: 2);

      await tester.tap(find.text('2 more reasons \u00B7 Unlock now'));
      await tester.pumpAndSettle();

      expect(find.text('See what they really think'), findsOneWidget);
      expect(find.text('This card'), findsWidgets);
      expect(find.text('\u20B949'), findsOneWidget);
      expect(find.text('\u20B999'), findsOneWidget);
      expect(find.text('\u20B9299'), findsOneWidget);
      expect(find.text('Popular'), findsOneWidget);
      // Yakku Lite is picked first.
      expect(find.text('Get Yakku Lite \u00B7 \u20B999'), findsOneWidget);
      expect(find.text("One-time payment. Doesn't renew."), findsOneWidget);
    });

    testWidgets('the buy button follows the plan picked', (tester) async {
      await openReasons(tester, mixed, hiddenCount: 2);
      await tester.tap(find.text('2 more reasons \u00B7 Unlock now'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const ValueKey('plan-yakku_love')));
      await tester.tap(find.byKey(const ValueKey('plan-yakku_love')));
      await tester.pumpAndSettle();
      expect(find.text('Get Yakku Love \u00B7 \u20B9299'), findsOneWidget);

      await tester.ensureVisible(find.byKey(const ValueKey('plan-this_card')));
      await tester.tap(find.byKey(const ValueKey('plan-this_card')));
      await tester.pumpAndSettle();
      expect(find.text('Get this card \u00B7 \u20B949'), findsOneWidget);
    });

    testWidgets('closing the sheet leaves the screen as it was', (
      tester,
    ) async {
      await openReasons(tester, mixed, hiddenCount: 2);
      await tester.tap(find.text('2 more reasons \u00B7 Unlock now'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();

      expect(find.text('See what they really think'), findsNothing);
      expect(find.text('2 more reasons \u00B7 Unlock now'), findsOneWidget);
    });
  });

  group('reasons screen with a plan or the card bought', () {
    testWidgets('every reason is readable, with Ask back, and no button', (
      tester,
    ) async {
      await openReasons(
        tester,
        [
          reason('1', 'First reason'),
          reason('2', 'Second reason'),
          reason('3', 'Third reason'),
        ],
        cardAccess: access(revealed: true, unlocked: true),
      );

      expect(find.text('First reason'), findsOneWidget);
      expect(find.text('Second reason'), findsOneWidget);
      expect(find.text('Third reason'), findsOneWidget);
      expect(find.text('Ask back'), findsNWidgets(3));
      expect(find.textContaining('Unlock now'), findsNothing);
      expect(find.byKey(const ValueKey('hidden-reasons')), findsNothing);
      expect(find.byKey(const ValueKey('ticket-unlock-reasons')), findsNothing);
      expect(find.textContaining('hidden'), findsNothing);
      expect(find.text('All 3 open'), findsOneWidget);
      expect(find.byIcon(Icons.lock_open_rounded), findsWidgets);
    });

    testWidgets(
      'Lite with tickets shows Unlock this card and opens the ticket sheet',
      (tester) async {
        await openReasons(
          tester,
          [
            reason('1', 'Top reason'),
            reason('2', 'Other reason'),
          ],
          cardAccess: access(
            revealed: true,
            unlocked: false,
            canUnlock: true,
            ticketsLeft: 2,
          ),
        );

        expect(
          find.text('2 tickets left \u00B7 Unlock this card'),
          findsOneWidget,
        );
        expect(find.byKey(const ValueKey('ticket-unlock-reasons')), findsOneWidget);

        await tester.tap(find.byKey(const ValueKey('ticket-unlock-pill')));
        await tester.pumpAndSettle();

        expect(find.text('See what they really think'), findsNothing);
        expect(find.textContaining('Unlock'), findsWidgets);
        expect(find.text('Not now'), findsOneWidget);
      },
    );

    testWidgets(
      'unlocked card with stale hidden flags shows Show Yakku plans without this_card',
      (tester) async {
        await openReasons(
          tester,
          [
            reason('1', 'Visible'),
            reason('2', '', hidden: true),
            reason('3', '', hidden: true),
          ],
          hiddenCount: 2,
          // Unlocked but reasons not marked revealed → CTA is upgrade, not unlock.
          cardAccess: access(revealed: false, unlocked: true),
        );

        expect(find.text('Show Yakku plans'), findsOneWidget);
        expect(find.textContaining('Unlock now'), findsNothing);

        await tester.tap(find.text('Show Yakku plans'));
        await tester.pumpAndSettle();

        expect(find.text('See what they really think'), findsOneWidget);
        expect(find.text('This card'), findsNothing);
        expect(find.textContaining('Get Yakku Lite'), findsOneWidget);
      },
    );
  });

  group('Something else answers', () {
    Future<void> openAnswers(
      WidgetTester tester,
      List<PollCustomAnswer> answers, {
      int hiddenCount = 0,
      AskBackAccess? cardAccess,
    }) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final remote = FakeRemote([])
        ..access = cardAccess ?? access(revealed: false);
      final realtime = FakeRealtime();
      await tester.pumpWidget(
        testAppScope(
          askBack: remote,
          realtime: realtime,
          inbox: AskBackInboxController(remote: remote, realtime: realtime),
          userRemote: _PlansUserRemote(plans: _sampleCatalog()),
          child: MaterialApp(
            home: CustomAnswersScreen(
              percent: 30,
              fraction: 0.3,
              count: answers.length,
              loadAnswers: () async => PollCustomAnswerList(
                items: answers,
                hiddenCount: hiddenCount,
              ),
              onReport: (_) async => null,
              contentType: 'poll',
              contentId: 'poll-1',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('free plan: one answer with its reason, the rest blurred', (
      tester,
    ) async {
      await openAnswers(tester, const [
        PollCustomAnswer(
          id: '1',
          answer: 'Hard to read',
          reason: 'You never say',
          canAskBack: true,
        ),
        PollCustomAnswer(id: '2', answer: '', isHidden: true),
        PollCustomAnswer(id: '3', answer: '', isHidden: true),
      ], hiddenCount: 2);

      expect(find.text('Hard to read'), findsOneWidget);
      expect(find.text('You never say'), findsOneWidget);
      expect(find.text('Ask back'), findsOneWidget);
      expect(find.text('1 free \u00B7 2 hidden'), findsOneWidget);
      expect(find.text('2 more answers \u00B7 Unlock now'), findsOneWidget);
      expect(find.byKey(const ValueKey('hidden-answers')), findsOneWidget);

      await tester.tap(find.text('2 more answers \u00B7 Unlock now'));
      await tester.pumpAndSettle();
      expect(find.text('See what they really think'), findsOneWidget);
    });

    testWidgets('a plan or bought card: every answer, no button', (
      tester,
    ) async {
      await openAnswers(tester, const [
        PollCustomAnswer(id: '1', answer: 'First', reason: 'One'),
        PollCustomAnswer(id: '2', answer: 'Second'),
      ]);

      expect(find.text('First'), findsOneWidget);
      expect(find.text('Second'), findsOneWidget);
      expect(find.textContaining('Unlock now'), findsNothing);
      expect(find.byKey(const ValueKey('hidden-answers')), findsNothing);
    });

    test('hidden answers parse', () {
      final list = parseCustomAnswers({
        'success': true,
        'data': {
          'items': [
            {'id': 'a', 'answer': 'Seen', 'reason': 'Why'},
            {'id': 'b', 'answer': '', 'isHidden': true},
          ],
          'hiddenCount': 1,
        },
      });

      expect(list.hiddenCount, 1);
      expect(list.items.first.isHidden, isFalse);
      expect(list.items.last.isHidden, isTrue);
      expect(list.items.last.reason, isNull);
    });
  });

  group('reasons in the model', () {
    test('hidden reasons and the hidden count parse', () {
      final list = parseReasons({
        'success': true,
        'data': {
          'items': [
            {'id': 'a', 'text': 'Seen', 'canAskBack': true},
            {'id': 'b', 'text': '', 'isHidden': true, 'canAskBack': true},
          ],
          'hiddenCount': 1,
          'blockedCount': 0,
        },
      });

      expect(list.hiddenCount, 1);
      expect(list.items.first.isHidden, isFalse);
      expect(list.items.last.isHidden, isTrue);
      expect(list.items.last.text, isEmpty);
    });

    test('an older server without the fields shows everything', () {
      final list = parseReasons({
        'success': true,
        'data': {
          'items': [
            {'id': 'a', 'text': 'Seen'},
          ],
        },
      });

      expect(list.hiddenCount, 0);
      expect(list.items.single.isHidden, isFalse);
    });

    test('access says whether reasons are revealed', () {
      expect(
        AskBackAccess.fromJson({'reasonsRevealed': false}).reasonsRevealed,
        isFalse,
      );
      expect(AskBackAccess.fromJson({}).reasonsRevealed, isTrue);
    });
  });

  group('results screen', () {
    testWidgets('results screen no longer shows the unlock bar', (
      tester,
    ) async {
      await openResults(tester, revealed: false);

      expect(find.text('See what they\nreally think'), findsNothing);
      expect(find.byKey(const ValueKey('unlock-now')), findsNothing);
      expect(find.textContaining('really think'), findsNothing);
    });

    testWidgets('a paid plan or a bought card has no unlock bar', (
      tester,
    ) async {
      await openResults(tester, revealed: true);

      expect(find.byKey(const ValueKey('unlock-now')), findsNothing);
      expect(find.textContaining('really think'), findsNothing);
    });
  });
}
