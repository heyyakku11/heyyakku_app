import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yakku/presentation/widgets/story_card.dart';

void main() {
  void useStorySurface(WidgetTester tester) {
    tester.view.physicalSize = StoryCard.size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('shows the question and every option text', (
    tester,
  ) async {
    useStorySurface(tester);
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: StoryCard(
            question: 'Pizza or tacos?',
            options: ['Pizza', 'Tacos', '  ', 'Burgers'],
          ),
        ),
      ),
    );

    expect(find.text('Pizza or tacos?'), findsOneWidget);
    expect(find.text('Pizza'), findsOneWidget);
    expect(find.text('Tacos'), findsOneWidget);
    expect(find.text('Burgers'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('limits to four options', (tester) async {
    useStorySurface(tester);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: StoryCard(
            question: 'Q?',
            options: List.generate(8, (i) => 'Option $i'),
          ),
        ),
      ),
    );

    expect(find.textContaining('Option '), findsNWidgets(4));
  });
}
