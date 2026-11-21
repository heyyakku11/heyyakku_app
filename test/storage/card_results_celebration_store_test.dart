import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yakku/core/storage/card_results_celebration_store.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('claimFirstWatch is true once per content id', () async {
    final store = CardResultsCelebrationStore();
    const id = 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee';

    expect(await store.claimFirstWatch(id), isTrue);
    expect(await store.hasSeen(id), isTrue);
    expect(await store.claimFirstWatch(id), isFalse);
  });

  test('different cards celebrate independently', () async {
    final store = CardResultsCelebrationStore();

    expect(await store.claimFirstWatch('card-a'), isTrue);
    expect(await store.claimFirstWatch('card-b'), isTrue);
    expect(await store.claimFirstWatch('card-a'), isFalse);
  });
}
