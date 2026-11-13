import 'package:yakku/data/models/poll/poll_reason.dart';
import 'package:flutter/foundation.dart';
import 'package:yakku/data/datasources/check_remote_data_source.dart';
import 'package:yakku/data/models/checks/check_response.dart';
import 'package:yakku/data/models/checks/fun_card_type.dart';
import 'package:yakku/data/models/checks/make_check_request.dart';
import 'package:yakku/data/models/checks/user_check_response.dart';

/// This week's checks plus the caller's made checks, loaded together.
class HomeChecks {
  const HomeChecks({
    required this.checks,
    required this.myChecks,
    this.funTypes = const [],
  });

  final List<CheckResponse> checks;

  /// Fun card types, each with a preview of its cards (no live date).
  final List<FunCardType> funTypes;
  final List<UserCheckResponse> myChecks;
}

/// Notifies listeners when the caller's made checks change (e.g. after make).
class CheckApiRepository extends ChangeNotifier {
  CheckApiRepository(this._remote);

  final CheckRemoteDataSource _remote;

  Future<List<CheckResponse>> getChecks() => _remote.getChecks();

  Future<List<CheckResponse>> getFunCardsOfType(String typeId) =>
      _remote.getFunCardsOfType(typeId);

  // Saved state changed in this session. A fun card shown again (a re-opened preview, a refreshed list) reads
  // this first, so it never shows a stale server value. Saving does not notify: nothing else needs to reload.
  final Map<String, bool> _savedOverrides = {};

  /// Bumps whenever a fun card is saved or unsaved, so the saved-cards list can refresh itself.
  final ValueNotifier<int> savedChanges = ValueNotifier<int>(0);

  /// Whether the caller has saved the fun card [id]; [fromServer] is what the list said when it was loaded.
  bool isFunCardSaved(String id, {required bool fromServer}) =>
      _savedOverrides[id] ?? fromServer;

  /// Saves ([saved] true) or unsaves a fun card. Throws when the request fails, and then the state is unchanged.
  Future<void> setFunCardSaved(String id, {required bool saved}) async {
    if (saved) {
      await _remote.saveFunCard(id);
    } else {
      await _remote.unsaveFunCard(id);
    }
    _savedOverrides[id] = saved;
    savedChanges.value++;
  }

  Future<UserCheckResponse> makeCheck(MakeCheckRequest request) async {
    final made = await _remote.makeCheck(request);
    notifyListeners();
    return made;
  }

  Future<List<UserCheckResponse>> getMyChecks() => _remote.getMyChecks();

  Future<List<PollReason>> getOptionReasons(String id, String optionId) =>
      _remote.getCheckOptionReasons(id, optionId);

  Future<List<PollCustomAnswer>> getCustomAnswers(String id) =>
      _remote.getCheckCustomAnswers(id);

  /// Reporting changes the check's reason counts, so listeners reload.
  Future<ReasonReportResult> reportReason(String id, String reasonId) async {
    final result = await _remote.reportCheckReason(id, reasonId);
    notifyListeners();
    return result;
  }

  Future<void> closeMyCheck(String id) async {
    await _remote.closeMyCheck(id);
    notifyListeners();
  }

  /// Opens a closed made card again (a fun card gets 24 more hours); listeners reload.
  Future<void> reshareMyCheck(String id) async {
    await _remote.reshareMyCheck(id);
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
        // Preload failed (e.g. the session is not ready yet); fetch again below.
      }
    }
    return _fetchHome(loggedIn: loggedIn);
  }

  /// Loads the home data in parallel. A failure
  /// of the "mine" call is not fatal for the feed.
  Future<HomeChecks> _fetchHome({required bool loggedIn}) async {
    final checksFuture = _remote.getChecks();
    final mineFuture = loggedIn
        ? _remote.getMyChecks().catchError((_) => <UserCheckResponse>[])
        : Future.value(const <UserCheckResponse>[]);
    // The fun cards are extra: the feed still loads without them.
    final funFuture = _remote.getFunCardTypes().catchError(
      (_) => <FunCardType>[],
    );
    return HomeChecks(
      checks: await checksFuture,
      myChecks: await mineFuture,
      funTypes: await funFuture,
    );
  }
}
