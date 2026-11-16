import 'package:flutter/material.dart';
import 'package:yakku/core/network/dio_error_mapper.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/data/models/personality/personality_card.dart';
import 'package:yakku/presentation/app_scope.dart';
import 'package:yakku/presentation/widgets/app_toast.dart';

/// The completed personality card's result: who friends say you are, your own
/// guess against theirs, how each trait was voted, and whether the result is
/// shown in the community.
class PersonalityResultScreen extends StatefulWidget {
  const PersonalityResultScreen({super.key, required this.shareCode});

  final String shareCode;

  @override
  State<PersonalityResultScreen> createState() =>
      _PersonalityResultScreenState();
}

class _PersonalityResultScreenState extends State<PersonalityResultScreen> {
  PersonalityResults? _results;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await AppScope.of(
        context,
      ).userRemote.getPersonalityResults(widget.shareCode);
      if (!mounted) return;
      setState(() {
        _results = results;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = DioErrorMapper.map(
          error,
          fallback: 'Could not load your result',
        ).message;
      });
    }
  }

  Future<void> _setSharing(bool value) async {
    final saved = await AppScope.of(
      context,
    ).personalityCards.setCommunitySharing(value);
    if (!saved && mounted) {
      AppToast.show('Could not update community sharing. Try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YakkuPalette.cream,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(onBack: () => Navigator.of(context).maybePop()),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: YakkuPalette.Raspberry),
      );
    }
    final results = _results;
    if (results == null) {
      return _ErrorView(message: _error, onRetry: _load);
    }

    final total = results.totalVotes;
    final commonIds = {for (final t in results.commonTraits) t.id};
    final matched = results.commonTraits.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
      children: [
        _HeroCard(
          traits: [for (final t in results.crowdTopTraits.take(3)) t.name],
          friends: total,
          verdict: _verdict(matched, results.selfTraits.length),
        ),
        const SizedBox(height: 22),
        const _SectionTitle('You vs your friends'),
        const SizedBox(height: 10),
        _VersusPanel(
          mine: results.selfTraits,
          friends: results.crowdTopTraits.take(3).toList(),
          commonIds: commonIds,
          matched: matched,
        ),
        const SizedBox(height: 22),
        const _SectionTitle('How your friends voted'),
        const SizedBox(height: 10),
        for (var i = 0; i < results.crowdTopTraits.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _TraitBarRow(
            trait: results.crowdTopTraits[i],
            total: total,
            top: i == 0,
            mine: commonIds.contains(results.crowdTopTraits[i].id),
          ),
        ],
        const SizedBox(height: 22),
        ListenableBuilder(
          listenable: AppScope.of(context).personalityCards,
          builder: (context, _) {
            final card = AppScope.of(context).personalityCards.card;
            return _CommunityRow(
              value: card?.shareToCommunity ?? results.shareToCommunity,
              onChanged: _setSharing,
            );
          },
        ),
      ],
    );
  }

  /// The sticker on the hero card: how close the guess was.
  static String _verdict(int matched, int guessed) {
    if (guessed > 0 && matched >= guessed) return 'Bang on.';
    if (matched == 0) return 'Plot twist.';
    return 'Close one.';
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: onBack,
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: YakkuPalette.textPrimary,
                size: 18,
              ),
            ),
          ),
          const Text(
            'Your result',
            style: TextStyle(
              color: YakkuPalette.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: YakkuPalette.Ink,
        fontSize: 18,
        height: 1.2,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.4,
      ),
    );
  }
}

/// Raspberry card: the traits friends picked most, as stickers.
class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.traits,
    required this.friends,
    required this.verdict,
  });

  final List<String> traits;
  final int friends;
  final String verdict;

  static const _sticker = [
    (color: YakkuPalette.Gold, angle: -0.05),
    (color: YakkuPalette.pillPink, angle: 0.04),
    (color: YakkuPalette.mint, angle: -0.03),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 22),
      decoration: BoxDecoration(
        color: YakkuPalette.Raspberry,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: YakkuPalette.Ink, width: 1.5),
        boxShadow: const [
          BoxShadow(color: YakkuPalette.Ink, offset: Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: YakkuPalette.Ink,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: Text(
                    'WHO YOU ARE',
                    style: TextStyle(
                      color: YakkuPalette.white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'by $friends ${friends == 1 ? 'friend' : 'friends'}',
                style: TextStyle(
                  color: YakkuPalette.white.withValues(alpha: 0.85),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Transform.rotate(
                angle: 0.05,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: YakkuPalette.Gold,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: YakkuPalette.Ink, width: 1.5),
                  ),
                  child: Text(
                    verdict,
                    style: const TextStyle(
                      color: YakkuPalette.Ink,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Your friends say you’re...',
            style: TextStyle(
              color: YakkuPalette.white,
              fontSize: 22,
              height: 1.1,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.7,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 14,
              children: [
                for (var i = 0; i < traits.length && i < _sticker.length; i++)
                  Transform.rotate(
                    angle: _sticker[i].angle,
                    child: _TraitSticker(
                      label: traits[i],
                      color: _sticker[i].color,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TraitSticker extends StatelessWidget {
  const _TraitSticker({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: YakkuPalette.Ink, width: 1.5),
        boxShadow: const [
          BoxShadow(color: YakkuPalette.Ink, offset: Offset(0, 3)),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: YakkuPalette.Ink,
          fontSize: 17,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.3,
        ),
      ),
    );
  }
}

/// Dark panel: your three guesses on the left, what friends said on the right.
/// A trait on both sides turns gold with a tick.
class _VersusPanel extends StatelessWidget {
  const _VersusPanel({
    required this.mine,
    required this.friends,
    required this.commonIds,
    required this.matched,
  });

  final List<PersonalityTrait> mine;
  final List<PersonalityTraitCount> friends;
  final Set<String> commonIds;
  final int matched;

  @override
  Widget build(BuildContext context) {
    final guessed = mine.length;
    final summary = guessed == 0
        ? 'Friends picked these for you.'
        : matched == 0
        ? 'None of your guesses matched. Interesting.'
        : '$matched of your $guessed '
              '${guessed == 1 ? 'guess' : 'guesses'} matched.';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: YakkuPalette.charcoal,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _VersusColumn(
                  label: 'YOU GUESSED',
                  names: [for (final t in mine) t.name],
                  matchedNames: {
                    for (final t in mine)
                      if (commonIds.contains(t.id)) t.name,
                  },
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(8, 22, 8, 0),
                child: Text(
                  'vs',
                  style: TextStyle(
                    color: YakkuPalette.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Expanded(
                child: _VersusColumn(
                  label: 'FRIENDS SAID',
                  names: [for (final t in friends) t.name],
                  matchedNames: {
                    for (final t in friends)
                      if (commonIds.contains(t.id)) t.name,
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Center(
            child: Text(
              summary,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: YakkuPalette.white70,
                fontSize: 13,
                height: 1.3,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VersusColumn extends StatelessWidget {
  const _VersusColumn({
    required this.label,
    required this.names,
    required this.matchedNames,
  });

  final String label;
  final List<String> names;
  final Set<String> matchedNames;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: YakkuPalette.white70,
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 10),
        for (var i = 0; i < names.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          _VersusChip(
            label: names[i],
            matched: matchedNames.contains(names[i]),
          ),
        ],
        if (names.isEmpty)
          const Text(
            '—',
            style: TextStyle(color: YakkuPalette.white54, fontSize: 16),
          ),
      ],
    );
  }
}

class _VersusChip extends StatelessWidget {
  const _VersusChip({required this.label, required this.matched});

  final String label;
  final bool matched;

  @override
  Widget build(BuildContext context) {
    final ink = matched ? YakkuPalette.Ink : YakkuPalette.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: matched ? YakkuPalette.Gold : YakkuPalette.white20,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: ink,
                fontSize: 14,
                height: 1.15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (matched) ...[
            const SizedBox(width: 6),
            const Icon(
              Icons.check_circle_rounded,
              size: 16,
              color: YakkuPalette.Ink,
            ),
          ],
        ],
      ),
    );
  }
}

/// One ranked trait: a white pill with a bar for the share of friends who
/// picked it. The most-picked one has the raspberry border; your own guesses
/// carry a "You" tag.
class _TraitBarRow extends StatelessWidget {
  const _TraitBarRow({
    required this.trait,
    required this.total,
    required this.top,
    required this.mine,
  });

  final PersonalityTraitCount trait;
  final int total;
  final bool top;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final fraction = total > 0 ? (trait.votes / total).clamp(0.0, 1.0) : 0.0;
    final percent = (fraction * 100).round();

    return Container(
      decoration: BoxDecoration(
        color: YakkuPalette.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: top ? YakkuPalette.Raspberry : YakkuPalette.roseBorder,
          width: top ? 1.8 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: fraction,
                heightFactor: 1,
                child: ColoredBox(
                  color: top ? YakkuPalette.pinkWash : YakkuPalette.pinkMist,
                ),
              ),
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        text: trait.name,
                        children: [
                          if (mine) ...[
                            const TextSpan(text: '  '),
                            WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: YakkuPalette.primaryBright,
                                  ),
                                ),
                                child: const Text(
                                  'You',
                                  style: TextStyle(
                                    color: YakkuPalette.primaryBright,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: YakkuPalette.textPrimary,
                        fontSize: 15,
                        height: 1.2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '$percent%',
                    style: const TextStyle(
                      color: YakkuPalette.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: YakkuPalette.pillPink,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.people_alt_rounded,
                          size: 14,
                          color: YakkuPalette.Raspberry,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${trait.votes}',
                          style: const TextStyle(
                            color: YakkuPalette.Raspberry,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Show in Community": shares the final result, what friends picked, not
/// your own guess.
class _CommunityRow extends StatelessWidget {
  const _CommunityRow({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 10, 12),
      decoration: BoxDecoration(
        color: YakkuPalette.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: YakkuPalette.roseBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Show in Community',
                  style: TextStyle(
                    color: YakkuPalette.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value
                      ? 'Your final result is visible to everyone.'
                      : 'Your result stays private.',
                  style: const TextStyle(
                    color: YakkuPalette.textSecondary,
                    fontSize: 12.5,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: YakkuPalette.Raspberry,
            activeThumbColor: YakkuPalette.white,
            inactiveTrackColor: YakkuPalette.stepInactive,
            inactiveThumbColor: YakkuPalette.white,
            trackOutlineColor: const WidgetStatePropertyAll(
              YakkuPalette.transparent,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message ?? 'Could not load your result',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: YakkuPalette.textSecondary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(
                foregroundColor: YakkuPalette.Ink,
                side: const BorderSide(color: YakkuPalette.Ink, width: 1.2),
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
              ),
              child: const Text(
                'Try again',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
