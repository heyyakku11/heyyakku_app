import 'package:flutter/material.dart';
import 'package:yakku/core/network/dio_error_mapper.dart';
import 'package:yakku/data/models/home/mirror_check.dart';
import 'package:yakku/data/repositories/check_api_repository.dart';
import 'package:yakku/presentation/app_scope.dart';
import 'package:yakku/presentation/dashboard.dart';
import 'package:yakku/presentation/screens/home/home_feed_dummy.dart';
import 'package:yakku/presentation/screens/community/community_placeholder.dart';
import 'package:yakku/presentation/screens/home/widgets/home_feed_body.dart';
import 'package:yakku/presentation/screens/home/widgets/home_feed_tabs.dart';
import 'package:yakku/presentation/screens/home/widgets/personality_card_tile.dart';
import 'package:yakku/presentation/screens/personality/personality_navigation.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CheckApiRepository? _checkApi;
  bool? _wasLoggedIn;

  List<MirrorCheck> _checks = const [];
  List<MirrorCheck> _funCards = const [];
  bool _loading = true;
  String? _error;
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
    DashboardTabs.friendsTabActive.value = tab == HomeFeedTab.friends;
    _pageController.animateToPage(
      tab.index,
      duration: HomeFeedTabs.slideDuration,
      curve: HomeFeedTabs.slideCurve,
    );
  }

  /// "Ask now" on the personality card. The card itself comes from the shared
  /// store, so it updates here by itself when it changes anywhere.
  Future<void> _onPersonalityAsk() async {
    final store = AppScope.of(context).personalityCards;
    final card = store.card;
    if (card == null) return;
    await openPersonalityAsk(context, card, store.traits);
  }

  Future<void> _refresh() =>
      Future.wait([_load(), AppScope.of(context).personalityCards.refresh()]);

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
        _funCards = [
          for (final card in data.funCards)
            MirrorCheck.fromCheck(card, isFun: true),
        ];
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
                onPageChanged: (index) {
                  final tab = HomeFeedTab.values[index];
                  setState(() => _tab = tab);
                  DashboardTabs.friendsTabActive.value =
                      tab == HomeFeedTab.friends;
                },
                children: [
                  KeepAlivePage(
                    child: RefreshIndicator(
                      onRefresh: _refresh,
                      child: _loading
                          ? const Center(child: CircularProgressIndicator())
                          : ListenableBuilder(
                              listenable: AppScope.of(context).personalityCards,
                              builder: (context, _) {
                                final store = AppScope.of(
                                  context,
                                ).personalityCards;
                                final card = store.card;
                                return HomeFeedBody(
                                  mirrorChecks: _checks,
                                  funCards: _funCards,
                                  questionsWorthAsking: questionsWorthAsking,
                                  errorMessage: _checks.isEmpty ? _error : null,
                                  leading: card == null
                                      ? null
                                      : PersonalityCardTile(
                                          card: card,
                                          traits: store.traits,
                                          onPressed: _onPersonalityAsk,
                                        ),
                                );
                              },
                            ),
                    ),
                  ),
                  // Community is not open yet: the same preview as its own tab,
                  // without the heading (the home header is already above).
                  const KeepAlivePage(
                    child: CommunityPlaceholder(showTitle: false),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
