import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yakku/core/payments/payment_confirm_result.dart';
import 'package:yakku/data/models/payments/payment_models.dart';
import 'package:yakku/presentation/payments/payment_flow_surfaces.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpHost(WidgetTester tester, Widget home) {
    return tester.pumpWidget(MaterialApp(home: home));
  }

  testWidgets('progress dialog announces message and dismisses safely',
      (tester) async {
    late VoidCallback dismiss;
    await pumpHost(
      tester,
      Builder(
        builder: (context) {
          return Scaffold(
            body: TextButton(
              onPressed: () {
                dismiss = showPaymentProgressDialog(
                  context,
                  message: 'Confirming payment…',
                );
              },
              child: const Text('Go'),
            ),
          );
        },
      ),
    );

    await tester.tap(find.text('Go'));
    await tester.pump();
    expect(find.text('Confirming payment…'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.liveRegion == true &&
            widget.properties.label == 'Confirming payment…',
      ),
      findsWidgets,
    );

    dismiss();
    await tester.pumpAndSettle();
    expect(find.text('Confirming payment…'), findsNothing);
    expect(find.text('Go'), findsOneWidget);
  });

  testWidgets('success outcome dialog shows title and OK', (tester) async {
    await pumpHost(
      tester,
      Builder(
        builder: (context) {
          return Scaffold(
            body: TextButton(
              onPressed: () {
                presentPaymentConfirmOutcome(
                  context,
                  const PaymentConfirmFulfilled(
                    orderId: 'ord-1',
                    purchaseType: PaymentPurchaseTypes.userPlan,
                    planCode: 'yakku_lite',
                  ),
                );
              },
              child: const Text('Show'),
            ),
          );
        },
      ),
    );

    await tester.tap(find.text('Show'));
    await tester.pumpAndSettle();

    expect(find.text('Payment successful'), findsOneWidget);
    expect(find.textContaining('confirmed'), findsOneWidget);
    expect(find.text('OK'), findsOneWidget);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('Payment successful'), findsNothing);
  });

  testWidgets('pending outcome offers Check again', (tester) async {
    var retry = false;
    await pumpHost(
      tester,
      Builder(
        builder: (context) {
          return Scaffold(
            body: TextButton(
              onPressed: () async {
                retry = await presentPaymentConfirmOutcome(
                  context,
                  const PaymentConfirmPending(orderId: 'ord-pending'),
                );
              },
              child: const Text('Show'),
            ),
          );
        },
      ),
    );

    await tester.tap(find.text('Show'));
    await tester.pumpAndSettle();

    expect(find.text('Payment processing'), findsOneWidget);
    expect(find.text('Check again'), findsOneWidget);
    expect(find.text('Close'), findsOneWidget);

    await tester.tap(find.text('Check again'));
    await tester.pumpAndSettle();
    expect(retry, isTrue);
  });

  testWidgets('failure outcome has no retry action', (tester) async {
    var retry = true;
    await pumpHost(
      tester,
      Builder(
        builder: (context) {
          return Scaffold(
            body: TextButton(
              onPressed: () async {
                retry = await presentPaymentConfirmOutcome(
                  context,
                  const PaymentConfirmFailed(
                    message: 'Verification rejected.',
                    orderId: 'ord-fail',
                  ),
                );
              },
              child: const Text('Show'),
            ),
          );
        },
      ),
    );

    await tester.tap(find.text('Show'));
    await tester.pumpAndSettle();

    expect(find.text('Payment not confirmed'), findsOneWidget);
    expect(find.text('Verification rejected.'), findsOneWidget);
    expect(find.text('Check again'), findsNothing);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(retry, isFalse);
  });
}
