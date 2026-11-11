import 'package:flutter/material.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/data/models/home/mirror_check.dart';
import 'package:yakku/data/repositories/check_api_repository.dart';
import 'package:yakku/presentation/app_scope.dart';
import 'package:yakku/presentation/screens/home/widgets/sub_mirror_check_card.dart';
import 'package:yakku/presentation/screens/home/widgets/write_own_question_cta.dart';

/// Opens the full list of active just-for-fun cards.
void openFunCards(BuildContext context, List<MirrorCheck> initial) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => FunCardsScreen(initial: initial)),
  );
}

/// Every active just-for-fun card the caller has not made yet, in a grid. Shows what the home feed
/// already had straight away, then refreshes (and again when a card is made).
class FunCardsScreen extends StatefulWidget {
  const FunCardsScreen({super.key, required this.initial});

  final List<MirrorCheck> initial;

  @override
  State<FunCardsScreen> createState() => _FunCardsScreenState();
}

class _FunCardsScreenState extends State<FunCardsScreen> {
  late List<MirrorCheck> _cards = widget.initial;
  CheckApiRepository? _api;
  bool _failed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final api = AppScope.of(context).checkApi;
    if (!identical(_api, api)) {
      _api?.removeListener(_reload);
      _api = api..addListener(_reload);
      _reload();
    }
  }

  @override
  void dispose() {
    _api?.removeListener(_reload);
    super.dispose();
  }

  Future<void> _reload() async {
    final api = _api;
    if (api == null) return;
    try {
      final cards = await api.getFunCards();
      if (!mounted) return;
      setState(() {
        _cards = [
          for (final card in cards)
            if (!card.used) MirrorCheck.fromCheck(card, isFun: true),
        ];
        _failed = false;
      });
    } catch (_) {
      if (!mounted) return;
      // Keep showing what we have; only say so when there is nothing to show.
      setState(() => _failed = _cards.isEmpty);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YakkuPalette.cream,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _reload,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 20, 8),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'Back',
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      ),
                      const SizedBox(width: 4),
                      const Expanded(child: SectionTag('Just for fun')),
                    ],
                  ),
                ),
              ),
              if (_cards.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        _failed
                            ? 'Could not load the cards. Pull down to retry.'
                            : 'You have made every card for now. Check back soon.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: YakkuPalette.Ink,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                  sliver: SliverGrid.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.02,
                        ),
                    itemCount: _cards.length,
                    itemBuilder: (context, index) => SubMirrorCheckCard(
                      check: _cards[index],
                      showTitle: false,
                      compact: true,
                    ),
                  ),
                ),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 12, 20, 28),
                  child: WriteOwnQuestionCta(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
