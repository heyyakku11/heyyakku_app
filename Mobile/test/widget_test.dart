import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yakku/main.dart';
import 'package:yakku/presentation/screens/create_poll_screen.dart';
import 'package:yakku/presentation/screens/profile_screen.dart';
import 'package:yakku/presentation/screens/setting_screen.dart';

void main() {
  testWidgets('Onboarding opens Profile as the main screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Get Started'), findsOneWidget);

    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Anonymous User'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    expect(find.byType(CreatePollScreen), findsNothing);
  });

  testWidgets('Create poll validates and posts locally', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.byType(CreatePollScreen), findsOneWidget);
    expect(find.text('something else'), findsNothing);
    expect(find.text('Settings'), findsNothing);
    expect(find.text('Anonymous'), findsNothing);
    expect(find.text('Poll duration'), findsNothing);

    await tester.tap(find.text('Post Poll'));
    await tester.pumpAndSettle();
    expect(find.text('Ask a question first.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Ask your question...'),
      'Is the prototype working?',
    );
    await tester.enterText(find.widgetWithText(TextField, 'Option 1'), 'Yes');
    await tester.enterText(find.widgetWithText(TextField, 'Option 2'), 'No');
    await tester.ensureVisible(find.text('Post Poll'));
    await tester.tap(find.text('Post Poll'));
    await tester.pumpAndSettle();

    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(find.text('Is the prototype working?'), findsOneWidget);
    expect(find.text('Poll posted anonymously'), findsOneWidget);

    await tester.tap(find.text('Is the prototype working?'));
    await tester.pumpAndSettle();
    expect(find.text('something else'), findsOneWidget);
  });

  testWidgets('Voting and settings theme tiles are reachable', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    expect(find.text('Anonymous User'), findsOneWidget);

    await tester.tap(find.text('What is the best way to learn programming?'));
    await tester.pumpAndSettle();
    expect(find.textContaining('%'), findsWidgets);

    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    expect(find.byType(SettingScreen), findsOneWidget);
    expect(find.text('ACCOUNT'), findsOneWidget);
    expect(find.text('OTHER'), findsOneWidget);
  });
}
