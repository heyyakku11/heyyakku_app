import 'dart:math';

import 'package:flutter/material.dart';
import 'package:yakku/core/network/dio_error_mapper.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/data/models/home/ask_friends_check.dart';
import 'package:yakku/presentation/app_scope.dart';
import 'package:yakku/presentation/screens/created_poll_screen.dart';
import 'package:yakku/presentation/widgets/app_alert.dart';

class CheckDetailScreen extends StatefulWidget {
  const CheckDetailScreen({super.key, required this.check});

  final AskFriendsCheck check;

  @override
  State<CheckDetailScreen> createState() => _CheckDetailScreenState();
}

class _CheckDetailScreenState extends State<CheckDetailScreen>
    with TickerProviderStateMixin {
  int? _selectedIndex;
  bool _sending = false;
  bool _showSelectionHint = false;

  late final AnimationController _optionsEntrance;
  late final AnimationController _hintAnimation;

  AskFriendsCheck get check => widget.check;

  /// Real poll answers only — "Friends add one" is UI chrome, not an option.
  List<AskFriendsOption> get _answerOptions => [
    for (final option in check.options)
      if (!option.outlined && option.label.trim().isNotEmpty) option,
  ];

  @override
  void initState() {
    super.initState();
    _optionsEntrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..forward();

    _hintAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void dispose() {
    _optionsEntrance.dispose();
    _hintAnimation.dispose();
    super.dispose();
  }

  Future<void> _playSelectionHint() async {
    if (_selectedIndex != null) return;

    setState(() => _showSelectionHint = true);
    await _hintAnimation.forward();
    await Future<void>.delayed(const Duration(milliseconds: 600));
    await _hintAnimation.reverse();
    if (mounted) setState(() => _showSelectionHint = false);
  }

  Animation<double> _stagger(int index, int count) {
    final safeCount = count < 1 ? 1 : count;
    final slot = 0.55;
    final start = (index / safeCount) * (1 - slot);
    final end = (start + slot).clamp(0.0, 1.0);
    return CurvedAnimation(
      parent: _optionsEntrance,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
  }

  Future<void> _send() async {
    final selected = _selectedIndex;
    if (selected == null || _sending) return;

    final answers = _answerOptions;
    if (selected < 0 || selected >= answers.length) return;

    final question = check.question.trim().isNotEmpty
        ? check.question.trim()
        : check.title.trim();
    final options = [for (final option in answers) option.label.trim()];

    setState(() => _sending = true);
    try {
      final poll = await AppScope.of(context).pollApi.createTextPoll(
        question: question,
        options: options,
        selectedOptionIndex: selected,
      );
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => CreatedPollScreen(poll: poll),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      final message = DioErrorMapper.map(
        error,
        fallback: 'Could not send this check. Please try again.',
      ).message;
      await showAppAlert(context, title: "Couldn't send", message: message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasSelection = _selectedIndex != null;

    return Scaffold(
      backgroundColor: check.backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: check.foregroundColor,
                      size: 20,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(22, 4, 22, 16),
                    children: [
                      _Header(check: check),
                      const SizedBox(height: 22),
                      Text(
                        check.title,
                        style: TextStyle(
                          color: check.foregroundColor,
                          fontSize: 36,
                          height: 1.05,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                        ),
                      ),
                      if (check.question.isNotEmpty &&
                          check.question != check.title) ...[
                        const SizedBox(height: 10),
                        Text(
                          check.question,
                          style: TextStyle(
                            color: check.foregroundColor,
                            fontSize: 26,
                            height: 1.25,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                      const SizedBox(height: 28),
                      ..._buildAnimatedOptions(),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 10, 22, 16),
                  child: hasSelection
                      ? _AskMyFriendsFooter(
                          sending: _sending,
                          onTap: _sending ? null : _send,
                        )
                      : _PickYourAnswerFooter(
                          onTap: _playSelectionHint,
                          bounceAnimation: _showSelectionHint
                              ? _hintAnimation
                              : null,
                        ),
                ),
              ],
            ),
            if (_showSelectionHint)
              _AnimatedPointingFinger(animation: _hintAnimation),
          ],
        ),
      ),
    );
  }

  String _letterFor(AskFriendsOption option, int index) {
    final letter = option.letter;
    if (letter != null && letter.isNotEmpty) return letter;
    return String.fromCharCode(65 + index);
  }

  List<Widget> _buildAnimatedOptions() {
    final answers = _answerOptions;
    // Answers + friends-add row, staggered over 1800ms.
    final itemCount = answers.length + 1;

    return [
      for (var index = 0; index < answers.length; index++) ...[
        _OptionEntranceSlide(
          animation: _stagger(index, itemCount),
          child: _AnswerRow(
            check: check,
            option: answers[index],
            letter: _letterFor(answers[index], index),
            selected: _selectedIndex == index,
            onTap: () => setState(() => _selectedIndex = index),
            showGlow: _showSelectionHint,
          ),
        ),
        const SizedBox(height: 14),
      ],
      _OptionEntranceSlide(
        animation: _stagger(answers.length, itemCount),
        child: _FriendsCanAddOwnButton(check: check),
      ),
    ];
  }
}

/// Starts hidden, then slides in top-to-bottom as [animation] progresses.
class _OptionEntranceSlide extends StatelessWidget {
  const _OptionEntranceSlide({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  static const _slideDistance = 48.0;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final t = animation.value;
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - t) * -_slideDistance),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// Shown when no answer is selected.
class _PickYourAnswerFooter extends StatefulWidget {
  const _PickYourAnswerFooter({required this.onTap, this.bounceAnimation});

  final VoidCallback onTap;
  final Animation<double>? bounceAnimation;

  @override
  State<_PickYourAnswerFooter> createState() => _PickYourAnswerFooterState();
}

class _PickYourAnswerFooterState extends State<_PickYourAnswerFooter> {
  static const _ink = Color(0xFF1B1418);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(28),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: _ink, width: 1.6),
                boxShadow: const [
                  BoxShadow(color: _ink, offset: Offset(0, 4), blurRadius: 0),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedBuilder(
                      animation:
                          widget.bounceAnimation ?? AlwaysStoppedAnimation(0),
                      builder: (context, child) {
                        final bounceValue = widget.bounceAnimation?.value ?? 0;
                        // Bounce up and down: 0 to -8 pixels
                        final bounceOffset = sin((bounceValue - 0.5) * pi) * 8;

                        return Transform.translate(
                          offset: Offset(0, bounceOffset),
                          child: child,
                        );
                      },
                      child: const Icon(
                        Icons.arrow_upward_rounded,
                        size: 18,
                        color: _ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const _PrivacyCaption(label: 'Your pick stays secret'),
      ],
    );
  }
}

/// Shown after an answer is selected.
class _AskMyFriendsFooter extends StatelessWidget {
  const _AskMyFriendsFooter({required this.sending, required this.onTap});

  final bool sending;
  final VoidCallback? onTap;

  static const _ink = Color(0xFF1B1418);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(28),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: _ink,
                borderRadius: BorderRadius.circular(28),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (sending)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    else ...[
                      const Icon(
                        Icons.ios_share,
                        size: 18,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Ask my friends',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const _PrivacyCaption(label: 'Only you know your pick'),
      ],
    );
  }
}

class _PrivacyCaption extends StatelessWidget {
  const _PrivacyCaption({required this.label});

  final String label;

  static const _ink = Color(0xFF1B1418);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.lock_outline_rounded,
          size: 14,
          color: _ink.withValues(alpha: 0.75),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: _ink.withValues(alpha: 0.75),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.check});

  final AskFriendsCheck check;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (check.eyebrow != null)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: check.accentColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          check.eyebrow!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (check.meta != null) ...[
                const SizedBox(height: 8),
                Text(
                  check.meta!,
                  style: TextStyle(
                    color: check.foregroundColor.withValues(alpha: 0.55),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (check.sticker != null)
          Transform.rotate(
            angle: -0.08,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.black),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                child: Text(
                  check.sticker!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Pacifico',
                    color: check.accentColor,
                    fontSize: 20,
                    height: 1.15,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _AnswerRow extends StatelessWidget {
  const _AnswerRow({
    required this.check,
    required this.option,
    required this.letter,
    required this.selected,
    required this.onTap,
    this.showGlow = false,
  });

  final AskFriendsCheck check;
  final AskFriendsOption option;
  final String letter;
  final bool selected;
  final VoidCallback? onTap;
  final bool showGlow;

  static const _radius = 18.0;
  static const _ink = Color(0xFF1B1418);
  static const _glowRed = Color(0xFFD32F2F);

  @override
  Widget build(BuildContext context) {
    final accent = check.accentColor;
    final background = selected ? _ink : Colors.white;
    final foreground = selected ? Colors.white : _ink;
    final badgeColor = selected
        ? YakkuPalette.primary
        : accent.withValues(alpha: 0.22);
    final shadowColor = selected ? YakkuPalette.primary : _ink;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_radius),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(_radius),
            border: Border.all(color: _ink, width: 1.6),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                offset: const Offset(3, 3),
                blurRadius: 0,
              ),
              if (showGlow)
                BoxShadow(
                  color: _glowRed.withValues(alpha: 0.6),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 16, 10),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: badgeColor,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    letter,
                    style: TextStyle(
                      color: selected ? Colors.white : _ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    option.label,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (selected)
                  const Icon(Icons.check, color: Colors.white, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Default chrome on every check detail — not part of poll options.
class _FriendsCanAddOwnButton extends StatelessWidget {
  const _FriendsCanAddOwnButton({required this.check});

  final AskFriendsCheck check;

  static const _radius = 18.0;

  @override
  Widget build(BuildContext context) {
    final tones = _tonesFromBackground(check.backgroundColor);

    return CustomPaint(
      painter: _DashedBorderPainter(color: tones.border, radius: _radius),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tones.fill,
          borderRadius: BorderRadius.circular(_radius),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: tones.border,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, size: 16, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  'Friends can add their own',
                  style: TextStyle(
                    color: tones.border,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Fill / border / text follow the check card background family.
  static ({Color fill, Color border}) _tonesFromBackground(Color background) {
    final hsl = HSLColor.fromColor(background);
    final fill = hsl
        .withLightness((hsl.lightness - 0.04).clamp(0.0, 1.0))
        .toColor();
    final border = hsl
        .withSaturation((hsl.saturation + 0.10).clamp(0.0, 1.0))
        .withLightness((hsl.lightness - 0.04).clamp(0.5, 0.7))
        .toColor();
    return (fill: fill, border: border);
  }
}

/// Animated pointing finger that guides user to select an option.
/// Animated index finger that moves from button to poll options.
class _AnimatedPointingFinger extends StatelessWidget {
  const _AnimatedPointingFinger({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final t = animation.value;

        // Ease in-out scale animation (breathing effect)
        final scale = 0.9 + (sin((t - 0.5) * pi) * 0.15).abs();

        return Positioned(
          top: 320,
          right: 16,
          child: Transform.scale(
            scale: scale,
            child: const Text('👆', style: TextStyle(fontSize: 44)),
          ),
        );
      },
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)),
      );
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + 6;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance += 10;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}
