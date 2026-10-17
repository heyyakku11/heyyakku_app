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

  /// Loads the home data in parallel. Guests have no made checks; a failure
  /// of the "mine" call is not fatal for the feed.
  Future<HomeChecks> loadHome({required bool loggedIn}) async {
    final checksFuture = _remote.getChecks();
    final mineFuture = loggedIn
        ? _remote.getMyChecks().catchError((_) => <UserCheckResponse>[])
        : Future.value(const <UserCheckResponse>[]);
    return HomeChecks(checks: await checksFuture, myChecks: await mineFuture);
  }
}
