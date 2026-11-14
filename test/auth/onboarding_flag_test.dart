import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yakku/core/auth/user_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('onboarding flag defaults to false and stays true after logout', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = UserPreferences();

    expect(await prefs.getHasCompletedOnboarding(), isFalse);

    await prefs.setHasCompletedOnboarding(true);
    await prefs.setIsUserLogged(true);
    await prefs.clearAuth();

    expect(await prefs.getIsUserLogged(), isFalse);
    expect(await prefs.getHasCompletedOnboarding(), isTrue);
  });
}
