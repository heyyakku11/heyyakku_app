import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:yakku/core/network/api_exception.dart';
import 'package:yakku/core/network/dio_error_mapper.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/data/models/personality/personality_card.dart';
import 'package:yakku/presentation/app_scope.dart';
import 'package:yakku/presentation/screens/personality/personality_share_screen.dart';
import 'package:yakku/presentation/widgets/app_toast.dart';

/// Two steps: (1) the user claims 3 traits that describe themselves, then (2)
/// they share their card so friends can vote on it.
///
/// Pops `true` when the self-assessment was submitted, so the caller can
/// refresh the card.
class PersonalityClaimScreen extends StatefulWidget {
  const PersonalityClaimScreen({
    super.key,
    required this.card,
    required this.traits,
  });

  final PersonalityCard card;

  /// The predefined traits; loaded here when empty.
  final List<PersonalityTrait> traits;

  @override
  State<PersonalityClaimScreen> createState() => _PersonalityClaimScreenState();
}

class _PersonalityClaimScreenState extends State<PersonalityClaimScreen>
    with SingleTickerProviderStateMixin {
  /// Drives the sticker's skew-shake when a disabled "Ask now" is tapped.
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
  );

  static const _picks = 3;

  late List<PersonalityTrait> _traits = widget.traits;
  late String _shareCode = widget.card.shareCode;

  /// Trait ids in the order they were picked.
  late final List<String> _selected = [
    for (final trait in widget.card.selfTraits) trait.id,
  ];

  /// True once the self-assessment is accepted by the server (or already was).
  late bool _claimed = widget.card.status != PersonalityCardStatus.draft;
  bool _submitting = false;
  bool _loadingTraits = false;
  bool _traitsFailed = false;

  bool get _complete => _selected.length == _picks;

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  /// Tapping "Ask now" before 3 traits are picked: shake the "You guess
  /// first!" sticker to point at what is missing.
  void _nudge() {
    if (_complete || _submitting) return;
    HapticFeedback.warningNotification();
    _shake.forward(from: 0);
  }

  @override
  void initState() {
    super.initState();
    if (_traits.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadTraits());
    }
  }

  Future<void> _loadTraits() async {
    setState(() {
      _loadingTraits = true;
      _traitsFailed = false;
    });
    try {
      final traits = await AppScope.of(
        context,
      ).userRemote.getPersonalityTraits();
      if (!mounted) return;
      setState(() {
        _traits = traits;
        _traitsFailed = traits.isEmpty;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _traitsFailed = true);
    } finally {
      if (mounted) setState(() => _loadingTraits = false);
    }
  }

  void _toggle(PersonalityTrait trait) {
    if (_claimed || _submitting) return;
    HapticFeedback.selectionClick();
    setState(() {
      if (_selected.contains(trait.id)) {
        _selected.remove(trait.id);
      } else if (_selected.length < _picks) {
        _selected.add(trait.id);
      }
    });
  }

  /// "Ask now": claims the traits first (once), then opens the share sheet.
  Future<void> _askNow() async {
    if (_submitting || !_complete) return;

    if (!_claimed) {
      setState(() => _submitting = true);
      try {
        final result = await AppScope.of(
          context,
        ).userRemote.submitSelfAssessment(List.of(_selected));
        if (!mounted) return;
        setState(() {
          _claimed = true;
          if (result.shareCode.isNotEmpty) _shareCode = result.shareCode;
        });
      } catch (error) {
        if (!mounted) return;
        setState(() => _submitting = false);
        AppToast.show(_errorMessage(error));
        return;
      }
      if (!mounted) return;
      setState(() => _submitting = false);
    }

    await _share();
  }

  /// Step 2: the share screen with the card preview and destinations.
  Future<void> _share() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => PersonalityShareScreen(
          shareCode: _shareCode,
          traits: [for (final trait in _traits) trait.name],
        ),
      ),
    );
  }

  String _errorMessage(Object error) {
    final api = DioErrorMapper.map(
      error,
      fallback: 'Could not save your guess. Please try again.',
    );
    return switch (api.kind) {
      ApiErrorKind.connection ||
      ApiErrorKind.timeout => 'No connection. Check your network and retry.',
      ApiErrorKind.conflict => 'You have already made your guess.',
      _ => api.message,
    };
  }

  void _close() => Navigator.of(context).pop(_claimed);

  @override
  Widget build(BuildContext context) {
    final step2 = _claimed || _complete;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: Scaffold(
        backgroundColor: YakkuPalette.pinkTintSoft,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: _submitting ? null : _close,
                  tooltip: 'Close',
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                  icon: const Icon(
                    Icons.close_rounded,
                    color: YakkuPalette.Ink,
                  ),
                ),
                _Stepper(step2: step2),
                const SizedBox(height: 18),
                const _WhoTag(),
                const SizedBox(height: 12),
                const Text(
                  'Describe me in 3 words',
                  style: TextStyle(
                    color: YakkuPalette.Ink,
                    fontSize: 32,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.2,
                  ),
                ),
                const SizedBox(height: 18),
                _buildStickerRow(step2),
                const SizedBox(height: 22),
                Expanded(child: SingleChildScrollView(child: _buildTraits())),
                const _OnlyYouSee(),
                const SizedBox(height: 12),
                _buildAskNow(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStickerRow(bool step2) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedBuilder(
          animation: _shake,
          builder: (context, child) {
            // A damped swing: rotates one way, then the other around its own
            // centre (so it stays in place), settling back to its tilt.
            final decay = 1 - Curves.easeOut.transform(_shake.value);
            final wave = math.sin(_shake.value * math.pi * 6) * decay;
            return Transform.rotate(angle: wave * 0.16, child: child);
          },
          child: Transform.rotate(
            angle: -0.07,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: YakkuPalette.Gold,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: YakkuPalette.Ink, width: 1.5),
                boxShadow: const [
                  BoxShadow(color: YakkuPalette.Ink, offset: Offset(0, 3)),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Text(
                  step2 ? 'Your guess' : 'You guess first!',
                  style: const TextStyle(
                    fontFamily: 'Pacifico',
                    color: YakkuPalette.Ink,
                    fontSize: 26,
                    height: 1.2,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        const Padding(padding: EdgeInsets.only(top: 6), child: _CurvedArrow()),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.only(top: 22),
          child: Text(
            '${_selected.length} of $_picks',
            style: TextStyle(
              color: _complete ? YakkuPalette.Ink : YakkuPalette.Raspberry,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTraits() {
    if (_loadingTraits) {
      return const Padding(
        padding: EdgeInsets.only(top: 40),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_traitsFailed) {
      return Padding(
        padding: const EdgeInsets.only(top: 24),
        child: Column(
          children: [
            const Text(
              'Could not load the traits.',
              style: TextStyle(
                color: YakkuPalette.Ink,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextButton(onPressed: _loadTraits, child: const Text('Try again')),
          ],
        ),
      );
    }
    return Wrap(
      spacing: 10,
      runSpacing: 14,
      children: [
        for (final trait in _traits)
          _TraitChip(
            label: trait.name,
            selected: _selected.contains(trait.id),
            onTap: () => _toggle(trait),
          ),
      ],
    );
  }

  Widget _buildAskNow() {
    final enabled = _complete && !_submitting;
    // A disabled button swallows taps, so listen above it and shake instead.
    return GestureDetector(
      onTap: enabled ? null : _nudge,
      behavior: HitTestBehavior.opaque,
      child: AbsorbPointer(absorbing: !enabled, child: _askNowButton(enabled)),
    );
  }

  Widget _askNowButton(bool enabled) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: FilledButton(
        onPressed: enabled ? _askNow : null,
        style: FilledButton.styleFrom(
          backgroundColor: YakkuPalette.Raspberry,
          disabledBackgroundColor: YakkuPalette.Raspberry.withValues(
            alpha: 0.18,
          ),
          foregroundColor: YakkuPalette.white,
          disabledForegroundColor: YakkuPalette.Raspberry.withValues(
            alpha: 0.45,
          ),
          shape: const StadiumBorder(),
        ),
        child: _submitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: YakkuPalette.white,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.ios_share_rounded, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Ask now',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
      ),
    );
  }
}

/// A hand-drawn style arrow: it leaves the sticker, curves over and points
/// down at the traits.
class _CurvedArrow extends StatelessWidget {
  const _CurvedArrow();

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(
      size: Size(40, 34),
      painter: _CurvedArrowPainter(YakkuPalette.Ink),
    );
  }
}

class _CurvedArrowPainter extends CustomPainter {
  const _CurvedArrowPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Designed on a 40 x 34 canvas and scaled to the actual size.
    final sx = size.width / 40;
    final sy = size.height / 34;
    Offset o(double x, double y) => Offset(x * sx, y * sy);

    final shaft = Path()
      ..moveTo(o(3, 8).dx, o(3, 8).dy)
      ..cubicTo(
        o(14, 2).dx,
        o(14, 2).dy,
        o(30, 3).dx,
        o(30, 3).dy,
        o(33, 24).dx,
        o(33, 24).dy,
      );
    canvas.drawPath(shaft, paint);

    // Open arrowhead at the tip.
    final head = Path()
      ..moveTo(o(26, 18).dx, o(26, 18).dy)
      ..lineTo(o(33, 25).dx, o(33, 25).dy)
      ..lineTo(o(38, 16).dx, o(38, 16).dy);
    canvas.drawPath(head, paint);
  }

  @override
  bool shouldRepaint(_CurvedArrowPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.step2});

  final bool step2;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StepDot(number: 1, label: 'Your guess', active: !step2, done: step2),
        Expanded(
          child: Container(
            height: 1.5,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            color: step2
                ? YakkuPalette.Ink
                : YakkuPalette.Raspberry.withValues(alpha: 0.2),
          ),
        ),
        _StepDot(number: 2, label: 'Ask now', active: step2, done: false),
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({
    required this.number,
    required this.label,
    required this.active,
    required this.done,
  });

  final int number;
  final String label;
  final bool active;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final Color fill = done
        ? YakkuPalette.Ink
        : active
        ? YakkuPalette.Raspberry
        : YakkuPalette.white;
    final Color text = done || active ? YakkuPalette.white : YakkuPalette.Ink;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
          child: done
              ? const FaIcon(
                  FontAwesomeIcons.check,
                  size: 11,
                  color: YakkuPalette.white,
                )
              : Text(
                  '$number',
                  style: TextStyle(
                    color: text,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: active ? YakkuPalette.Ink : YakkuPalette.textSecondary,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _WhoTag extends StatelessWidget {
  const _WhoTag();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        color: YakkuPalette.white,
        borderRadius: BorderRadius.all(Radius.circular(999)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Text(
          'WHO YOU ARE',
          style: TextStyle(
            color: YakkuPalette.Raspberry,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}

class _TraitChip extends StatelessWidget {
  const _TraitChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            color: selected ? YakkuPalette.Ink : YakkuPalette.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: YakkuPalette.Ink, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: selected ? YakkuPalette.Raspberry : YakkuPalette.Ink,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                const FaIcon(
                  FontAwesomeIcons.check,
                  size: 12,
                  color: YakkuPalette.white,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(
                  color: selected ? YakkuPalette.white : YakkuPalette.Ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnlyYouSee extends StatelessWidget {
  const _OnlyYouSee();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline_rounded, size: 14, color: YakkuPalette.Ink),
          SizedBox(width: 6),
          Text(
            'Only you see your guess.',
            style: TextStyle(
              color: YakkuPalette.Ink,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
