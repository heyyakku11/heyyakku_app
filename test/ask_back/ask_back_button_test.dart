import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yakku/presentation/widgets/ask_back_button.dart';

void main() {
  testWidgets('locked ask back shows the padlock', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AskBackButton(voteId: 'v1', locked: true, compact: true),
        ),
      ),
    );

    expect(find.text('Ask back'), findsOneWidget);
    expect(find.byIcon(Icons.reply_rounded), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
  });

  testWidgets('an open or started ask back has no padlock', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AskBackButton(voteId: 'v1', locked: false, compact: true),
        ),
      ),
    );

    expect(find.text('Ask back'), findsOneWidget);
    expect(find.byIcon(Icons.reply_rounded), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline_rounded), findsNothing);
  });

  testWidgets('tapping a locked ask back opens the Yakku plans sheet', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: AskBackButton(voteId: 'v1', locked: true, compact: true),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Ask back'));
    await tester.pumpAndSettle();

    expect(find.text('See what they really think'), findsOneWidget);
    expect(find.text('Get Yakku Lite \u00B7 \u20B999'), findsOneWidget);
  });
}
