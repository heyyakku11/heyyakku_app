import 'package:flutter/material.dart';
import 'package:yakku/core/network/dio_error_mapper.dart';
import 'package:yakku/data/models/checks/user_check_response.dart';
import 'package:yakku/data/models/home/mirror_check.dart';
import 'package:yakku/data/models/personality/personality_card.dart';
import 'package:yakku/data/repositories/check_api_repository.dart';
import 'package:yakku/presentation/app_scope.dart';
import 'package:yakku/presentation/screens/home/home_feed_dummy.dart';
import 'package:yakku/presentation/screens/home/widgets/home_feed_body.dart';
import 'package:yakku/presentation/screens/home/widgets/home_feed_tabs.dart';
import 'package:yakku/presentation/screens/home/widgets/personality_card_tile.dart';
import 'package:yakku/presentation/screens/personality/personality_claim_screen.dart';
import 'package:yakku/presentation/screens/personality/personality_share_screen.dart';
import 'package:yakku/presentation/widgets/app_toast.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CheckApiRepository? _checkApi;
  bool? _wasLoggedIn;

  List<MirrorCheck> _checks = const [];
  List<UserCheckResponse> _myChecks = const [];
  bool _loading = true;
  String? _error;
  PersonalityCard? _personalityCard;
  List<PersonalityTrait> _traits = const [];
  HomeFeedTab _tab = HomeFeedTab.friends;
  final PageController _pageController = PageController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = AppScope.of(context);

    if (!identical(_checkApi, scope.checkApi)) {
      _checkApi?.removeListener(_load);
      _checkApi = scope.checkApi..addListener(_load);
    }

    // Reload when the user signs in or out (their made checks change).
    final loggedIn = scope.authController.isLoggedIn;
    if (_wasLoggedIn != loggedIn) {
      _wasLoggedIn = loggedIn;
      _load();
      _loadPersonality();
    }
  }

  @override
  void dispose() {
    _checkApi?.removeListener(_load);
    _pageController.dispose();
    super.dispose();
  }

  /// Tapping a tab slides the content across with the same easing as the pill.
  void _selectTab(HomeFeedTab tab) {
    if (tab == _tab) return;
    setState(() => _tab = tab);
    _pageController.animateToPage(
      tab.index,
      duration: HomeFeedTabs.slideDuration,
      curve: HomeFeedTabs.slideCurve,
    );
  }

  /// Loads the user's personality card and the trait list. A failure only
  /// hides the card; the rest of the feed is unaffected.
  Future<void> _loadPersonality() async {
    final scope = AppScope.of(context);
    if (!scope.authController.isLoggedIn) {
      if (_personalityCard != null) setState(() => _personalityCard = null);
      return;
    }

    try {
      final results = await Future.wait([
        scope.userRemote.getMyPersonalityCard(),
        scope.userRemote.getPersonalityTraits().catchError(
          (_) => const <PersonalityTrait>[],
        ),
      ]);
      if (!mounted) return;
      setState(() {
        _personalityCard = results[0] as PersonalityCard;
        _traits = results[1] as List<PersonalityTrait>;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _personalityCard = null);
    }
  }

  /// "Ask now" on the personality card, by where the card is:
  /// - draft: the user has not made their own guess yet, so the claim screen
  ///   (step 1: pick 3 traits, then share);
  /// - collecting: the guess is already in, so go straight to the share screen.
  Future<void> _onPersonalityAsk() async {
    final card = _personalityCard;
    if (card == null) return;
    switch (card.status) {
      case PersonalityCardStatus.draft:
        await _openClaim(card);
      case PersonalityCardStatus.collecting:
        await Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (_) => PersonalityShareScreen(
              shareCode: card.shareCode,
              traits: [for (final trait in _traits) trait.name],
            ),
          ),
        );
      case PersonalityCardStatus.completed:
        AppToast.show('Results are coming soon');
    }
  }

  /// Opens the claim screen; reloads the card when the user's guess was
  /// submitted there.
  Future<void> _openClaim(PersonalityCard card) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PersonalityClaimScreen(card: card, traits: _traits),
        fullscreenDialog: true,
      ),
    );
    if (changed == true) await _loadPersonality();
  }

  Future<void> _refresh() => Future.wait([_load(), _loadPersonality()]);

  Future<void> _load() async {
    final api = _checkApi;
    if (api == null) return;

    try {
      final data = await api.loadHome(loggedIn: _wasLoggedIn ?? false);
      if (!mounted) return;
      setState(() {
        _checks = [
          for (final check in data.checks) MirrorCheck.fromCheck(check),
        ];
        _myChecks = data.myChecks;
        _error = null;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = DioErrorMapper.map(
          error,
          fallback: 'Could not load checks. Pull down to retry.',
        ).message;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const HomeBrandHeader(),
            HomeFeedTabs(value: _tab, onChanged: _selectTab),
            Expanded(
              child: PageView(
                controller: _pageController,
                // Swiping changes the tab too, and the pill follows.
                onPageChanged: (index) =>
                    setState(() => _tab = HomeFeedTab.values[index]),
                children: [
                  KeepAlivePage(
                    child: RefreshIndicator(
                      onRefresh: _refresh,
                      child: _loading
                          ? const Center(child: CircularProgressIndicator())
                          : HomeFeedBody(
                              mirrorChecks: _checks,
                              myChecks: _myChecks,
                              questionsWorthAsking: questionsWorthAsking,
                              errorMessage: _checks.isEmpty ? _error : null,
                              leading: _personalityCard == null
                                  ? null
                                  : PersonalityCardTile(
                                      card: _personalityCard!,
                                      traits: _traits,
                                      onPressed: _onPersonalityAsk,
                                    ),
                            ),
                    ),
                  ),
                  // Community is intentionally empty for now.
                  const KeepAlivePage(child: SizedBox.expand()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
