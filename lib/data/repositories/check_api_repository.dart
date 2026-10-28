import 'package:flutter/foundation.dart';
import 'package:yakku/data/datasources/check_remote_data_source.dart';
import 'package:yakku/data/models/checks/check_response.dart';
import 'package:yakku/data/models/checks/make_check_request.dart';
import 'package:yakku/data/models/checks/user_check_response.dart';

/// This week's checks plus the caller's made checks, loaded together.
class HomeChecks {
  const HomeChecks({required this.checks, required this.myChecks});

  final List<CheckResponse> checks;
  final List<UserCheckResponse> myChecks;
}

/// Notifies listeners when the caller's made checks change (e.g. after make).
class CheckApiRepository extends ChangeNotifier {
  CheckApiRepository(this._remote);

  final CheckRemoteDataSource _remote;

  Future<List<CheckResponse>> getChecks() => _remote.getChecks();

  Future<UserCheckResponse> makeCheck(MakeCheckRequest request) async {
    final made = await _remote.makeCheck(request);
    notifyListeners();
    return made;
  }

  Future<List<UserCheckResponse>> getMyChecks() => _remote.getMyChecks();

  Future<void> closeMyCheck(String id) async {
    await _remote.closeMyCheck(id);
    notifyListeners();
  }

  /// Deleting frees the underlying check, so it can be made again.
  Future<void> deleteMyCheck(String id) async {
    await _remote.deleteMyCheck(id);
    notifyListeners();
  }

  static const _preloadMaxAge = Duration(minutes: 2);

  Future<HomeChecks>? _preloaded;
  DateTime? _preloadedAt;
  bool? _preloadedLoggedIn;

  /// Starts loading the home data early (e.g. on the onboarding screen) so the
  /// home screen can show it immediately. Failures are ignored: the home
  /// screen falls back to a normal load.
  void preloadHome({required bool loggedIn}) {
    final future = _fetchHome(loggedIn: loggedIn);
    future.ignore();
    _preloaded = future;
    _preloadedAt = DateTime.now();
    _preloadedLoggedIn = loggedIn;
  }

  /// Loads the home data, using a fresh matching preload once if there is one.
  Future<HomeChecks> loadHome({required bool loggedIn}) async {
    final preloaded = _preloaded;
    final fresh =
        preloaded != null &&
        _preloadedLoggedIn == loggedIn &&
        DateTime.now().difference(_preloadedAt!) < _preloadMaxAge;
    _preloaded = null;
    if (fresh) {
      try {
        return await preloaded;
      } catch (_) {
        // Preload failed (e.g. no guest token yet); fetch again below.
      }
    }
    return _fetchHome(loggedIn: loggedIn);
  }

  /// Loads the home data in parallel. Guests have no made checks; a failure
  /// of the "mine" call is not fatal for the feed.
  Future<HomeChecks> _fetchHome({required bool loggedIn}) async {
    final checksFuture = _remote.getChecks();
    final mineFuture = loggedIn
        ? _remote.getMyChecks().catchError((_) => <UserCheckResponse>[])
        : Future.value(const <UserCheckResponse>[]);
    return HomeChecks(checks: await checksFuture, myChecks: await mineFuture);
  }
}
