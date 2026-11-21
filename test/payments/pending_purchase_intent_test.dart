import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yakku/core/payments/pending_purchase_intent.dart';
import 'package:yakku/core/storage/preference_storage_service.dart';

void main() {
  late PendingPurchaseStore store;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = PendingPurchaseStore(storage: PreferenceStorageService());
  });

  test('round-trips a purchase intent', () async {
    await store.save(
      PendingPurchaseIntent(
        planId: 'lite-id',
        planCode: 'yakku_lite',
        planName: 'Yakku Lite',
        savedAt: DateTime.utc(2026, 11, 19, 12),
        contentType: 'poll',
        contentId: 'poll-1',
      ),
    );

    final loaded = await store.read();
    expect(loaded, isNotNull);
    expect(loaded!.planCode, 'yakku_lite');
    expect(loaded.hasCardContext, isTrue);
    expect(loaded.contentId, 'poll-1');
  });

  test('clears expired intents', () async {
    await store.save(
      PendingPurchaseIntent(
        planId: 'lite-id',
        planCode: 'yakku_lite',
        planName: 'Yakku Lite',
        savedAt: DateTime.now().toUtc().subtract(const Duration(hours: 25)),
      ),
    );

    expect(await store.read(), isNull);
  });

  test('clear removes the intent', () async {
    await store.save(
      PendingPurchaseIntent(
        planId: 'love-id',
        planCode: 'yakku_love',
        planName: 'Yakku Love',
        savedAt: DateTime.now().toUtc(),
      ),
    );
    await store.clear();
    expect(await store.read(), isNull);
  });
}
