import 'package:flutter/foundation.dart';
import 'package:yakku/core/auth/auth_controller.dart';
import 'package:yakku/data/datasources/user_remote_data_source.dart';
import 'package:yakku/data/models/personality/personality_card.dart';

/// The signed-in user's personality card, held in one place and announced to
/// every screen that shows it (home, profile, community, my cards).
///
/// Screens listen to this instead of loading the card themselves, so a change
/// (the user makes their own guess and the card goes from draft to collecting,
/// a friend votes, the card completes) shows up everywhere at once.
class PersonalityCardStore extends ChangeNotifier {
  PersonalityCardStore({
    required UserRemoteDataSource remote,
    required AuthController auth,
  }) : _remote = remote,
       _auth = auth {
    _wasLoggedIn = auth.isLoggedIn;
    auth.addListener(_onAuthChanged);
    if (_wasLoggedIn) refresh();
  }

  final UserRemoteDataSource _remote;
  final AuthController _auth;

  PersonalityCard? _card;
  List<PersonalityTrait> _traits = const [];
  List<String> _topTraits = const [];
  bool _loaded = false;
  bool _wasLoggedIn = false;
  Future<void>? _inFlight;
  bool _disposed = false;

  /// Null until loaded, and when signed out.
  PersonalityCard? get card => _card;

  /// The predefined traits friends pick from.
  List<PersonalityTrait> get traits => _traits;

  /// What friends picked most (names), once the card is completed.
  List<String> get topTraits => _topTraits;

  /// True once the card has been fetched at least once.
  bool get loaded => _loaded;

  void _onAuthChanged() {
    final loggedIn = _auth.isLoggedIn;
    if (loggedIn == _wasLoggedIn) return;
    _wasLoggedIn = loggedIn;
    if (loggedIn) {
      refresh();
    } else {
      _clear();
    }
  }

  void _clear() {
    _card = null;
    _topTraits = const [];
    _loaded = false;
    _notify();
  }

  /// Loads the latest card. Calls made while one is running share its result.
  /// A failure keeps what is already shown.
  Future<void> refresh() {
    if (!_auth.isLoggedIn) {
      if (_card != null) _clear();
      return Future.value();
    }
    return _inFlight ??= _load().whenComplete(() => _inFlight = null);
  }

  Future<void> _load() async {
    try {
      final card = await _remote.getMyPersonalityCard();

      var traits = _traits;
      if (traits.isEmpty) {
        try {
          traits = await _remote.getPersonalityTraits();
        } catch (_) {}
      }

      var top = const <String>[];
      if (card.isCompleted) {
        try {
          final results = await _remote.getPersonalityResults(card.shareCode);
          top = [
            for (final trait in results.crowdTopTraits.take(3)) trait.name,
          ];
        } catch (_) {
          top = _topTraits;
        }
      }

      _card = card;
      _traits = traits;
      _topTraits = top;
      _loaded = true;
      _notify();
    } catch (_) {
      // Keep the card already shown; the next refresh tries again.
    }
  }

  /// The user's own guess was accepted: the card goes from draft to collecting
  /// straight away on every screen, then the real card is fetched.
  void applySelfAssessment(PersonalitySelfAssessment result) {
    final current = _card;
    if (current != null) {
      _card = current.copyWith(
        status: result.status,
        shareCode: result.shareCode.isNotEmpty ? result.shareCode : null,
      );
      _notify();
    }
    refresh();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }
}
