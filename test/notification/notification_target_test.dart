import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yakku/core/storage/card_results_celebration_store.dart';
import 'package:yakku/data/models/notification/app_notification.dart';
import 'package:yakku/data/models/personality/personality_card.dart';
import 'package:yakku/presentation/screens/personality/personality_card_progress_screen.dart';
import 'package:yakku/presentation/screens/personality/personality_navigation.dart';
import 'package:yakku/presentation/screens/personality/personality_result_screen.dart';
import 'package:yakku/presentation/screens/personality/personality_share_screen.dart';
import 'package:flutter/material.dart';

PersonalityCard _completedCard() => PersonalityCard(
  shareCode: 'sharecode01',
  status: PersonalityCardStatus.completed,
  selfTraits: const [
    PersonalityTrait(id: '1', name: 'Kind'),
    PersonalityTrait(id: '2', name: 'Funny'),
    PersonalityTrait(id: '3', name: 'Brave'),
  ],
  totalVotes: 5,
  requiredVotes: 5,
);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('NotificationTarget.tryParse personality', () {
    test('cardResults + personality → progress', () {
      final target = NotificationTarget.tryParse({
        'screen': 'cardResults',
        'contentType': 'personality',
        'contentId': 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
      });

      expect(target, isNotNull);
      expect(target!.isPersonality, isTrue);
      expect(target.isPersonalityProgress, isTrue);
      expect(target.isPersonalityReady, isFalse);
      expect(target.isCardShare, isFalse);
      expect(target.screen, 'cardResults');
    });

    test('personalityReady → celebration', () {
      final target = NotificationTarget.tryParse({
        'screen': 'personalityReady',
        'contentType': 'personality',
        'contentId': 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
      });

      expect(target, isNotNull);
      expect(target!.isPersonalityReady, isTrue);
      expect(target.isPersonalityProgress, isFalse);
    });

    test('legacy personalityResults → celebration', () {
      final target = NotificationTarget.tryParse({
        'screen': 'personalityResults',
        'contentType': 'personality',
        'contentId': 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
      });

      expect(target, isNotNull);
      expect(target!.isPersonalityReady, isTrue);
      expect(target.isPersonalityProgress, isFalse);
    });

    test('missing screen + personality defaults to cardResults progress', () {
      final target = NotificationTarget.tryParse({
        'contentType': 'personality',
        'contentId': 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
      });

      expect(target, isNotNull);
      expect(target!.screen, 'cardResults');
      expect(target.isPersonalityProgress, isTrue);
      expect(target.isPersonalityReady, isFalse);
    });

    test('cardShare + personality → share', () {
      final target = NotificationTarget.tryParse({
        'screen': 'cardShare',
        'contentType': 'personality',
        'contentId': 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
      });

      expect(target, isNotNull);
      expect(target!.isCardShare, isTrue);
      expect(target.isPersonality, isTrue);
      expect(target.isPersonalityProgress, isFalse);
    });

    test('poll cardResults is not personality', () {
      final target = NotificationTarget.tryParse({
        'screen': 'cardResults',
        'contentType': 'poll',
        'contentId': 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
      });

      expect(target, isNotNull);
      expect(target!.isPersonality, isFalse);
      expect(target.isCheck, isFalse);
      expect(target.isCardResultsReady, isFalse);
    });

    test('cardResultsReady marks poll/check celebration', () {
      final target = NotificationTarget.tryParse({
        'screen': 'cardResultsReady',
        'contentType': 'poll',
        'contentId': 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
      });

      expect(target, isNotNull);
      expect(target!.isCardResultsReady, isTrue);
      expect(target.isPersonality, isFalse);
    });
  });

  group('openPersonalityFromNotification', () {
    testWidgets('collecting vote tap opens progress, not share first', (
      tester,
    ) async {
      // Preview card chips can overflow in the default test viewport; ignore that
      // so this test can assert navigation routing only.
      final previousOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        final text = details.exceptionAsString();
        if (text.contains('A RenderFlex overflowed')) return;
        previousOnError?.call(details);
      };
      addTearDown(() => FlutterError.onError = previousOnError);

      final card = PersonalityCard(
        shareCode: 'sharecode01',
        status: PersonalityCardStatus.collecting,
        selfTraits: const [
          PersonalityTrait(id: '1', name: 'Kind'),
          PersonalityTrait(id: '2', name: 'Funny'),
          PersonalityTrait(id: '3', name: 'Brave'),
        ],
        totalVotes: 2,
        requiredVotes: 5,
      );
      final target = NotificationTarget(
        screen: 'cardResults',
        contentId: 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
        isPersonality: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: TextButton(
                  onPressed: () {
                    openPersonalityFromNotification(
                      context,
                      target,
                      card,
                      card.selfTraits,
                    );
                  },
                  child: const Text('open'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.byType(PersonalityCardProgressScreen), findsOneWidget);
      expect(find.byType(PersonalityShareScreen), findsNothing);
      expect(find.text('2 of 5 votes'), findsOneWidget);
    });

    testWidgets('personalityReady opens celebration progress screen once', (
      tester,
    ) async {
      final previousOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        final text = details.exceptionAsString();
        if (text.contains('A RenderFlex overflowed')) return;
        previousOnError?.call(details);
      };
      addTearDown(() => FlutterError.onError = previousOnError);

      final store = CardResultsCelebrationStore();
      final card = _completedCard();
      final target = NotificationTarget(
        screen: 'personalityReady',
        contentId: 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
        isPersonality: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: TextButton(
                  onPressed: () async {
                    await openPersonalityFromNotification(
                      context,
                      target,
                      card,
                      card.selfTraits,
                      celebrationStore: store,
                    );
                  },
                  child: const Text('open'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.byType(PersonalityCardProgressScreen), findsOneWidget);
      expect(find.text('Your results are ready'), findsWidgets);
      expect(find.byType(PersonalityResultScreen), findsNothing);

      // Leave celebration, then tap the same ready notification again.
      Navigator.of(tester.element(find.byType(PersonalityCardProgressScreen)))
          .pop();
      await tester.pumpAndSettle();

      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(PersonalityResultScreen), findsOneWidget);
      expect(find.byType(PersonalityCardProgressScreen), findsNothing);
    });

    testWidgets('completed vote tap opens result screen, not celebration', (
      tester,
    ) async {
      final card = _completedCard();
      final target = NotificationTarget(
        screen: 'cardResults',
        contentId: 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
        isPersonality: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: TextButton(
                  onPressed: () async {
                    await openPersonalityFromNotification(
                      context,
                      target,
                      card,
                      card.selfTraits,
                    );
                  },
                  child: const Text('open'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('open'));
      // Build the pushed result route; avoid settle — load needs AppScope.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(PersonalityResultScreen), findsOneWidget);
      expect(find.byType(PersonalityCardProgressScreen), findsNothing);
    });
  });
}
