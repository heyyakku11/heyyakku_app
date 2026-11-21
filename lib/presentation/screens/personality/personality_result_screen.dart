import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:yakku/core/network/dio_error_mapper.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/data/models/personality/personality_card.dart';
import 'package:yakku/presentation/app_scope.dart';
import 'package:yakku/presentation/screens/personality/personality_share_screen.dart';
import 'package:yakku/presentation/widgets/app_toast.dart';
import 'package:yakku/presentation/widgets/skeleton.dart';

/// Completed personality result: You vs Your circle, what friends picked, and
/// share. Layout matches the product result card (dark versus panel + bars).
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

  Future<void> _shareResult(PersonalityResults results) async {
    final traits = [
      for (final t in results.selfTraits) t.name,
      if (results.selfTraits.isEmpty)
        for (final t in results.crowdTopTraits.take(3)) t.name,
    ];
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => PersonalityShareScreen(
          shareCode: widget.shareCode,
          traits: traits,
        ),
      ),
    );
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
    if (_loading) return const _PersonalityResultSkeleton();
    final results = _results;
    if (results == null) {
      return _ErrorView(message: _error, onRetry: _load);
    }

    final commonIds = {for (final t in results.commonTraits) t.id};
    final matched = results.commonTraits.length;
    final guessed = results.selfTraits.length;
    final bangOn = guessed > 0 && matched >= guessed;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: _WhoYouArePill(),
        ),
        const SizedBox(height: 10),
        const Text(
          'Describe me in 3 words',
          style: TextStyle(
            color: YakkuPalette.Ink,
            fontSize: 30,
            height: 1.05,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.0,
          ),
        ),
        const SizedBox(height: 18),
        _VersusCard(
          mine: [for (final t in results.selfTraits) t.name],
          circle: [
            for (final t in results.crowdTopTraits.take(3)) t.name,
          ],
          friends: results.totalVotes,
          matched: matched,
          guessed: guessed,
          bangOn: bangOn,
          onShare: () => _shareResult(results),
        ),
        if (results.crowdTopTraits.isNotEmpty) ...[
          const SizedBox(height: 28),
          const Text(
            'How people see you',
            style: TextStyle(
              color: YakkuPalette.Ink,
              fontSize: 18,
              height: 1.2,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 12),
          _VoteRingChart(
            traits: results.crowdTopTraits,
            totalVotes: results.totalVotes,
            commonIds: commonIds,
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
            'Results',
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

class _WhoYouArePill extends StatelessWidget {
  const _WhoYouArePill();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: YakkuPalette.Raspberry,
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Text(
          'WHO YOU ARE',
          style: TextStyle(
            color: YakkuPalette.white,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class _PersonalityResultSkeleton extends StatelessWidget {
  const _PersonalityResultSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SkeletonPulse(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 6, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: SkeletonBox(width: 110, height: 28, radius: 999),
            ),
            SizedBox(height: 12),
            SkeletonBox(height: 34, radius: 10),
            SizedBox(height: 20),
            SkeletonBox(height: 220, radius: 28),
            SizedBox(height: 28),
            Align(
              alignment: Alignment.centerLeft,
              child: SkeletonBox(width: 160, height: 16, radius: 8),
            ),
            SizedBox(height: 12),
            SkeletonBox(height: 220, radius: 22),
          ],
        ),
      ),
    );
  }
}

/// Dark You vs Your circle card with Plot twist / Bang on sticker and share.
class _VersusCard extends StatelessWidget {
  const _VersusCard({
    required this.mine,
    required this.circle,
    required this.friends,
    required this.matched,
    required this.guessed,
    required this.bangOn,
    required this.onShare,
  });

  final List<String> mine;
  final List<String> circle;
  final int friends;
  final int matched;
  final int guessed;
  final bool bangOn;
  final VoidCallback onShare;

  static const _night = Color(0xFF1F191C);

  @override
  Widget build(BuildContext context) {
    final matchLabel = guessed <= 0
        ? '$friends ${friends == 1 ? 'friend' : 'friends'}'
        : '$friends ${friends == 1 ? 'friend' : 'friends'} · $matched of $guessed matched';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 14),
          decoration: BoxDecoration(
            color: _night,
            borderRadius: BorderRadius.circular(28),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _SidePanel(
                            color: YakkuPalette.cardPink,
                            tag: 'You',
                            traits: mine,
                            light: false,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _SidePanel(
                            color: YakkuPalette.white,
                            tag: 'Your circle',
                            traits: circle,
                            light: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _night,
                      shape: BoxShape.circle,
                      border: Border.all(color: YakkuPalette.white, width: 2),
                    ),
                    child: const Text(
                      'vs',
                      style: TextStyle(
                        color: YakkuPalette.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 0, 2, 2),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        matchLabel,
                        style: const TextStyle(
                          color: YakkuPalette.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _ShareResultButton(onTap: onShare),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Center(
            child: Transform.rotate(
              angle: -0.05,
              child: _PlotSticker(
                text: bangOn ? 'Bang on.' : 'Plot twist.',
                bangOn: bangOn,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SidePanel extends StatelessWidget {
  const _SidePanel({
    required this.color,
    required this.tag,
    required this.traits,
    required this.light,
  });

  final Color color;
  final String tag;
  final List<String> traits;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final tagColor = light ? YakkuPalette.textSecondary : YakkuPalette.Ink;
    final traitColor = YakkuPalette.Ink;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tag,
              style: TextStyle(
                color: tagColor,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            if (traits.isEmpty)
              Text(
                '—',
                style: TextStyle(
                  color: traitColor.withValues(alpha: 0.45),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              )
            else
              for (var i = 0; i < traits.length; i++) ...[
                if (i > 0) const SizedBox(height: 4),
                Text(
                  traits[i],
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: traitColor,
                    fontSize: 18,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
          ],
        ),
      ),
    );
  }
}

class _PlotSticker extends StatelessWidget {
  const _PlotSticker({required this.text, required this.bangOn});

  final String text;
  final bool bangOn;

  @override
  Widget build(BuildContext context) {
    final background = bangOn ? const Color(0xFFD7F5E3) : YakkuPalette.white;
    final foreground = bangOn
        ? const Color(0xFF1E6B3E)
        : YakkuPalette.Raspberry;
    final border = bangOn
        ? const Color(0xFF1E6B3E)
        : const Color(0xFF1F191C);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border, width: 1.6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: foreground,
          fontSize: 22,
          height: 1.1,
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.w700,
          fontFamilyFallback: const ['cursive'],
        ),
      ),
    );
  }
}

/// Yellow share pill with a 2s attention shake.
class _ShareResultButton extends StatefulWidget {
  const _ShareResultButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_ShareResultButton> createState() => _ShareResultButtonState();
}

class _ShareResultButtonState extends State<_ShareResultButton>
    with SingleTickerProviderStateMixin {
  static const _restTilt = -0.05;
  static const _night = Color(0xFF1F191C);
  static const _yellow = Color(0xFFFFC72C);
  static const _yellowEdge = Color(0xFFD99A00);

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pill = GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: _yellowEdge,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _yellow,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: _night, width: 1.5),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.ios_share_rounded, size: 16, color: _night),
              SizedBox(width: 8),
              Text(
                'Share result',
                style: TextStyle(
                  color: _night,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        const burst = 0.55 / 2.0;
        final t = _controller.value;
        final active = t < burst;
        final local = active ? (t / burst) : 0.0;
        final decay = active ? (1 - Curves.easeOut.transform(local)) : 0.0;
        final wave = math.sin(local * math.pi * 6) * decay;
        return Transform.rotate(
          angle: _restTilt + wave * 0.12,
          child: child,
        );
      },
      child: pill,
    );
  }
}

/// Circular ring chart of how friends' votes were distributed across traits.
class _VoteRingChart extends StatefulWidget {
  const _VoteRingChart({
    required this.traits,
    required this.totalVotes,
    required this.commonIds,
  });

  final List<PersonalityTraitCount> traits;
  final int totalVotes;
  final Set<String> commonIds;

  static const _colors = <Color>[
    YakkuPalette.Raspberry,
    YakkuPalette.Gold,
    YakkuPalette.skyBlue,
    YakkuPalette.mintBright,
    YakkuPalette.violet,
    YakkuPalette.peach,
    YakkuPalette.orchid,
    YakkuPalette.salmon,
  ];

  static const chartSize = 196.0;
  static const stroke = 22.0;
  static const gap = 0.045;

  @override
  State<_VoteRingChart> createState() => _VoteRingChartState();
}

class _VoteRingChartState extends State<_VoteRingChart> {
  int? _selectedIndex;
  Offset? _tooltipAnchor;

  List<_RingSlice> get _slices => [
    for (var i = 0; i < widget.traits.length; i++)
      if (widget.traits[i].votes > 0)
        _RingSlice(
          label: widget.traits[i].name,
          votes: widget.traits[i].votes,
          color: _VoteRingChart._colors[i % _VoteRingChart._colors.length],
          mine: widget.commonIds.contains(widget.traits[i].id),
        ),
  ];

  void _onTapDown(TapDownDetails details) {
    final slices = _slices;
    final index = _hitTestSlice(
      details.localPosition,
      slices,
      size: _VoteRingChart.chartSize,
    );
    setState(() {
      if (index == null) {
        _selectedIndex = null;
        _tooltipAnchor = null;
        return;
      }
      if (_selectedIndex == index) {
        _selectedIndex = null;
        _tooltipAnchor = null;
        return;
      }
      _selectedIndex = index;
      _tooltipAnchor = _sliceAnchor(
        index,
        slices,
        size: _VoteRingChart.chartSize,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final slices = _slices;
    final sum = slices.fold<int>(0, (n, s) => n + s.votes);
    final centerCount = widget.totalVotes > 0 ? widget.totalVotes : sum;
    final selected =
        _selectedIndex != null && _selectedIndex! < slices.length
        ? slices[_selectedIndex!]
        : null;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      decoration: BoxDecoration(
        color: YakkuPalette.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: YakkuPalette.roseBorder),
      ),
      child: Column(
        children: [
          SizedBox(
            height: _VoteRingChart.chartSize,
            width: _VoteRingChart.chartSize,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: _onTapDown,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size.square(_VoteRingChart.chartSize),
                    painter: _RingChartPainter(
                      slices: slices,
                      selectedIndex: _selectedIndex,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$centerCount',
                        style: const TextStyle(
                          color: YakkuPalette.Ink,
                          fontSize: 32,
                          height: 1,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        centerCount == 1 ? 'vote' : 'votes',
                        style: const TextStyle(
                          color: YakkuPalette.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  if (selected != null && _tooltipAnchor != null)
                    Positioned(
                      left: (_tooltipAnchor!.dx - 78).clamp(
                        0.0,
                        _VoteRingChart.chartSize - 156,
                      ),
                      top: (_tooltipAnchor!.dy - 54).clamp(
                        -8.0,
                        _VoteRingChart.chartSize - 52,
                      ),
                      child: _RingTooltip(slice: selected),
                    ),
                ],
              ),
            ),
          ),
          if (slices.isNotEmpty) ...[
            const SizedBox(height: 18),
            for (var i = 0; i < slices.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              _RingLegendRow(
                slice: slices[i],
                total: sum > 0 ? sum : centerCount,
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _RingTooltip extends StatelessWidget {
  const _RingTooltip({required this.slice});

  final _RingSlice slice;

  @override
  Widget build(BuildContext context) {
    final votesLabel = slice.votes == 1 ? '1 vote' : '${slice.votes} votes';
    return Material(
      color: YakkuPalette.transparent,
      child: Container(
        width: 156,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: YakkuPalette.Ink,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: YakkuPalette.Ink.withValues(alpha: 0.18),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: slice.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    slice.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: YakkuPalette.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              votesLabel,
              style: TextStyle(
                color: YakkuPalette.white.withValues(alpha: 0.78),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

int? _hitTestSlice(
  Offset local,
  List<_RingSlice> slices, {
  required double size,
}) {
  final total = slices.fold<int>(0, (n, s) => n + s.votes);
  if (total <= 0) return null;

  final center = Offset(size / 2, size / 2);
  final dx = local.dx - center.dx;
  final dy = local.dy - center.dy;
  final distance = math.sqrt(dx * dx + dy * dy);
  final outer = size / 2;
  final inner = outer - _VoteRingChart.stroke;
  if (distance < inner - 8 || distance > outer + 6) return null;

  var angle = math.atan2(dy, dx);
  angle = (angle + math.pi / 2) % (math.pi * 2);
  if (angle < 0) angle += math.pi * 2;

  var start = 0.0;
  for (var i = 0; i < slices.length; i++) {
    final sweep = (slices[i].votes / total) * math.pi * 2;
    final end = start + sweep;
    if (angle >= start && angle < end) return i;
    start = end;
  }
  return slices.isEmpty ? null : slices.length - 1;
}

Offset _sliceAnchor(
  int index,
  List<_RingSlice> slices, {
  required double size,
}) {
  final total = slices.fold<int>(0, (n, s) => n + s.votes);
  final center = Offset(size / 2, size / 2);
  if (total <= 0 || index < 0 || index >= slices.length) return center;

  var start = -math.pi / 2;
  for (var i = 0; i < index; i++) {
    start += (slices[i].votes / total) * math.pi * 2;
  }
  final sweep = (slices[index].votes / total) * math.pi * 2;
  final mid = start + sweep / 2;
  final radius = size / 2 - _VoteRingChart.stroke / 2;
  return Offset(
    center.dx + math.cos(mid) * radius,
    center.dy + math.sin(mid) * radius,
  );
}

class _RingSlice {
  const _RingSlice({
    required this.label,
    required this.votes,
    required this.color,
    required this.mine,
  });

  final String label;
  final int votes;
  final Color color;
  final bool mine;
}

class _RingLegendRow extends StatelessWidget {
  const _RingLegendRow({required this.slice, required this.total});

  final _RingSlice slice;
  final int total;

  @override
  Widget build(BuildContext context) {
    final percent = total > 0 ? ((slice.votes / total) * 100).round() : 0;
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: slice.color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text.rich(
            TextSpan(
              text: slice.label,
              children: [
                if (slice.mine) ...[
                  const TextSpan(text: '  '),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: YakkuPalette.primaryBright),
                      ),
                      child: const Text(
                        'You',
                        style: TextStyle(
                          color: YakkuPalette.primaryBright,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: YakkuPalette.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          '${slice.votes}',
          style: const TextStyle(
            color: YakkuPalette.Ink,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 40,
          child: Text(
            '$percent%',
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: YakkuPalette.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _RingChartPainter extends CustomPainter {
  _RingChartPainter({required this.slices, this.selectedIndex});

  final List<_RingSlice> slices;
  final int? selectedIndex;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    const stroke = _VoteRingChart.stroke;
    final rect = Rect.fromCircle(center: center, radius: radius - stroke / 2);

    final track = Paint()
      ..color = YakkuPalette.blushFill
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;
    canvas.drawArc(rect, 0, math.pi * 2, false, track);

    final total = slices.fold<int>(0, (n, s) => n + s.votes);
    if (total <= 0) return;

    const gap = _VoteRingChart.gap;
    var start = -math.pi / 2;
    for (var i = 0; i < slices.length; i++) {
      final slice = slices[i];
      final sweep = (slice.votes / total) * math.pi * 2;
      final drawable = math.max(0.0, sweep - gap);
      if (drawable <= 0) {
        start += sweep;
        continue;
      }
      final selected = selectedIndex == i;
      final paint = Paint()
        ..color = slice.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = selected ? stroke + 4 : stroke
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect, start + gap / 2, drawable, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _RingChartPainter oldDelegate) {
    return oldDelegate.slices != slices ||
        oldDelegate.selectedIndex != selectedIndex;
  }
}

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
