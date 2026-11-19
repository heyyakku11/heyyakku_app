import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yakku/data/models/personality/personality_card.dart';
import 'package:yakku/presentation/screens/home/widgets/personality_card_tile.dart';

PersonalityCard card({
  required PersonalityCardStatus status,
  List<PersonalityTrait> selfTraits = const [],
}) {
  return PersonalityCard(
    shareCode: 'abc',
    status: status,
    selfTraits: selfTraits,
    totalVotes: status == PersonalityCardStatus.completed ? 5 : 1,
    requiredVotes: 5,
  );
}

Future<void> pumpTile(
  WidgetTester tester, {
  required PersonalityCard card,
  List<String> topTraits = const [],
  VoidCallback? onPressed,
}) async {
  tester.view.physicalSize = const Size(800, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: PersonalityCardTile(
          card: card,
          traits: const [
            PersonalityTrait(id: '1', name: 'Kind'),
            PersonalityTrait(id: '2', name: 'Funny'),
            PersonalityTrait(id: '3', name: 'Brave'),
          ],
          topTraits: topTraits,
          onPressed: onPressed ?? () {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('draft keeps ask-now promo', (tester) async {
    await pumpTile(tester, card: card(status: PersonalityCardStatus.draft));

    expect(find.text('Describe me in 3 words'), findsOneWidget);
    expect(find.text('Ask now'), findsOneWidget);
    expect(find.text('YOUR FRIENDS SAY YOU’RE'), findsNothing);
  });

  testWidgets('completed shows friends-say sticker card', (tester) async {
    var tapped = false;
    await pumpTile(
      tester,
      card: card(status: PersonalityCardStatus.completed),
      topTraits: const ['Honest', 'Good listener', 'Practical'],
      onPressed: () => tapped = true,
    );

    expect(find.text('YOUR FRIENDS SAY YOU’RE'), findsOneWidget);
    expect(find.text('honest'), findsOneWidget);
    expect(find.text('good listener'), findsOneWidget);
    expect(find.text('practical'), findsOneWidget);
    expect(find.text('Ask now'), findsNothing);
    expect(find.text('See results'), findsNothing);

    await tester.tap(find.text('YOUR FRIENDS SAY YOU’RE'));
    expect(tapped, isTrue);
  });
}
