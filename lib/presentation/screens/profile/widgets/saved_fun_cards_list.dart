import 'package:flutter/material.dart';
import 'package:yakku/core/network/dio_error_mapper.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/data/models/checks/check_response.dart';
import 'package:yakku/data/models/home/mirror_check.dart';
import 'package:yakku/data/repositories/check_api_repository.dart';
import 'package:yakku/presentation/app_scope.dart';
import 'package:yakku/presentation/screens/home/widgets/sub_mirror_check_card.dart';

/// The fun cards the user saved, in a two-column grid. Opening a card's preview and tapping Saved again removes
/// it; the list follows that change by itself.
class SavedFunCardsList extends StatefulWidget {
  const SavedFunCardsList({
    super.key,
    required this.loadCards,
    required this.onBrowse,
  });

  /// Loads the saved fun cards (the saved-cards list, narrowed to fun cards).
  final Future<List<CheckResponse>> Function() loadCards;

  /// Tapped from the empty state to go and find cards to save.
  final VoidCallback onBrowse;

  @override
  State<SavedFunCardsList> createState() => _SavedFunCardsListState();
}

class _SavedFunCardsListState extends State<SavedFunCardsList> {
  List<MirrorCheck> _cards = const [];
  bool _loading = true;
  String? _error;
  CheckApiRepository? _api;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final api = AppScope.of(context).checkApi;
    if (!identical(_api, api)) {
      _api?.savedChanges.removeListener(_load);
      _api = api..savedChanges.addListener(_load);
      _load();
    }
  }

  @override
  void dispose() {
    _api?.savedChanges.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final api = _api;
    if (api == null) return;
    try {
      final saved = await widget.loadCards();
      if (!mounted) return;
      setState(() {
        // Cards the user has already made are not offered again, the same as on Home.
        _cards = [
          for (final card in saved)
            if (!card.used) MirrorCheck.fromCheck(card, isFun: true),
        ];
        _error = null;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = DioErrorMapper.map(
          error,
          fallback: 'Could not load your saved cards',
        ).message;
        _loading = false;
      });
    }
  }

  Future<void> _refresh() async {
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null && _cards.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            TextButton(onPressed: _refresh, child: const Text('Try again')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: _cards.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [_EmptyState(onBrowse: widget.onBrowse)],
            )
          : GridView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onBrowse});

  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 56, 28, 28),
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: YakkuPalette.pinkWash,
            ),
            child: const Icon(
              Icons.bookmark_border_rounded,
              size: 34,
              color: YakkuPalette.Raspberry,
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'No saved cards yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: YakkuPalette.Ink,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Tap a fun card on Home to preview it, then tap Save. It waits here until you are ready to ask.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: YakkuPalette.textSecondary,
              fontSize: 14.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: onBrowse,
            style: FilledButton.styleFrom(
              backgroundColor: YakkuPalette.Ink,
              foregroundColor: YakkuPalette.white,
              minimumSize: const Size(0, 52),
              padding: const EdgeInsets.symmetric(horizontal: 30),
              shape: const StadiumBorder(),
            ),
            child: const Text(
              'Browse cards',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
