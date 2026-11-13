import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:yakku/core/router/app_routes.dart';
import 'package:yakku/core/theme/yakku_palette.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

/// 0..1 progress of [t] between [a] and [b], clamped.
double _ramp(double t, double a, double b) =>
    ((t - a) / (b - a)).clamp(0.0, 1.0);

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  static const _slideCount = 3;
  static const _stepLabels = ['Ask', 'Guess', 'Share', 'Compare'];
  static const _pageDuration = Duration(milliseconds: 320);
  static const _stepDuration = Duration(milliseconds: 2500); // 2.5s

  final _pageController = PageController();
  // Drives the slide 2 demo: one 0..1 run per sub tab, then on to the next tab.
  late final AnimationController _stepController;
  int _page = 0;
  int _step = 0;

  @override
  void initState() {
    super.initState();
    _stepController = AnimationController(vsync: this, duration: _stepDuration)
      ..addStatusListener((status) {
        if (status != AnimationStatus.completed || !mounted || _page != 1) {
          return;
        }
        setState(() => _step = (_step + 1) % _stepLabels.length);
        _stepController.forward(from: 0);
      });
  }

  @override
  void dispose() {
    _stepController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _page = page;
      if (page == 1) _step = 0;
    });
    if (page == 1) {
      _stepController.forward(from: 0);
    } else {
      _stepController.stop();
    }
  }

  void _selectStep(int step) {
    setState(() => _step = step);
    _stepController.forward(from: 0);
  }

  String get _buttonLabel => switch (_page) {
    0 => 'Start asking',
    1 => 'Next',
    _ => 'Get started',
  };

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: _pageDuration,
      curve: Curves.easeOutCubic,
    );
  }

  void _onPrimaryPressed() {
    switch (_page) {
      case 0:
        _goToPage(1);
      case 1:
        // The sub tabs are changed by tapping them; Next leaves the slide.
        _goToPage(2);
      default:
        _openSignUp();
    }
  }

  // Replaces the route (not a push) so sign-up has nothing to go back to.
  void _openSignUp() => context.go(AppRoutes.signUp);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YakkuPalette.cream,
      body: SafeArea(child: _buildCarousel()),
    );
  }

  Widget _buildCarousel() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _Wordmark(),
              TextButton(
                onPressed: _openSignUp,
                style: TextButton.styleFrom(
                  foregroundColor: YakkuPalette.textSecondary,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: const Size(0, 32),
                ),
                child: const Text(
                  'Skip',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: PageView(
              controller: _pageController,
              // Slides only advance from the button, not by swiping.
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: _onPageChanged,
              children: [
                const _SlideAsk(),
                _SlideHowItWorks(
                  step: _step,
                  labels: _stepLabels,
                  progress: _stepController,
                  onStepSelected: _selectStep,
                ),
                const _SlideCommunity(),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _PageDots(count: _slideCount, index: _page, onSelected: _goToPage),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: _onPrimaryPressed,
              style: FilledButton.styleFrom(
                backgroundColor: YakkuPalette.Ink,
                foregroundColor: YakkuPalette.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
              ),
              child: Text(
                _buttonLabel,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({
    required this.count,
    required this.index,
    required this.onSelected,
  });

  final int count;
  final int index;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          GestureDetector(
            onTap: () => onSelected(i),
            behavior: HitTestBehavior.opaque,
            // Padding enlarges the tap target around the small dot.
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: i == index ? 24 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: i == index
                      ? YakkuPalette.primary
                      : YakkuPalette.stepInactive,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Headline extends StatelessWidget {
  const _Headline({required this.spans});

  final List<InlineSpan> spans;

  static const style = TextStyle(
    color: YakkuPalette.textPrimary,
    fontSize: 36,
    height: 1.05,
    fontWeight: FontWeight.w800,
    letterSpacing: -1,
  );

  @override
  Widget build(BuildContext context) {
    return Text.rich(TextSpan(style: style, children: spans));
  }
}

class _SlideAsk extends StatelessWidget {
  const _SlideAsk();

  static const _style = TextStyle(
    color: YakkuPalette.Ink,
    fontSize: 46,
    height: 1.04,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.6,
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(child: _PreviewStack()),
        const SizedBox(height: 20),
        Text.rich(
          TextSpan(
            style: _style,
            children: [
              const TextSpan(text: 'Ask anything.\nGet '),
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: YakkuPalette.Ink,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      'honest',
                      style: TextStyle(
                        color: YakkuPalette.Gold,
                        fontSize: 46,
                        height: 1.04,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.6,
                      ),
                    ),
                  ),
                ),
              ),
              const TextSpan(text: '\nanswers.'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Everything private. Everything anonymous.',
          style: TextStyle(
            color: YakkuPalette.Ink,
            fontSize: 16,
            height: 1.2,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _SlideHowItWorks extends StatelessWidget {
  const _SlideHowItWorks({
    required this.step,
    required this.labels,
    required this.progress,
    required this.onStepSelected,
  });

  final int step;
  final List<String> labels;
  final Animation<double> progress;
  final ValueChanged<int> onStepSelected;

  static const _titles = [
    'Ask anything.',
    'Pick your guess.',
    'Share it. Friends answer anonymously.',
    'See if they agree.',
  ];

  // Each step fades in at its start and out at its end, so steps cross-fade.
  static double _stepOpacity(double t) =>
      _ramp(t, 0, 0.08) * (1 - _ramp(t, 0.92, 1));

  // Vertical proportions of the three sections, fixed for every step.
  static const _tabsFlex = 1;
  static const _contentFlex = 10;
  static const _textFlex = 2;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section 1: step tabs.
        Expanded(
          flex: _tabsFlex,
          child: Align(
            alignment: Alignment.centerLeft,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var i = 0; i < labels.length; i++) ...[
                    _StepTab(
                      label: '${i + 1} ${labels[i]}',
                      selected: i == step,
                      onTap: () => onStepSelected(i),
                    ),
                    if (i < labels.length - 1) const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
          ),
        ),
        // Section 2: step content.
        Expanded(
          flex: _contentFlex,
          child: AnimatedBuilder(
            animation: progress,
            builder: (context, _) {
              final t = progress.value;
              return Opacity(
                opacity: _stepOpacity(t),
                child: SizedBox(
                  width: double.infinity,
                  child: switch (step) {
                    0 => _VibeCheckCard(key: const ValueKey('ask-step'), t: t),
                    1 => _VibeCheckCard(
                      key: const ValueKey('guess-step'),
                      guessed: true,
                      t: t,
                    ),
                    2 => _ShareStepCard(
                      key: const ValueKey('share-step'),
                      t: t,
                    ),
                    _ => _CompareStepCard(
                      key: const ValueKey('compare-step'),
                      t: t,
                    ),
                  },
                ),
              );
            },
          ),
        ),
        // Section 3: step headline.
        Expanded(
          flex: _textFlex,
          child: AnimatedBuilder(
            animation: progress,
            builder: (context, child) =>
                Opacity(opacity: _stepOpacity(progress.value), child: child),
            child: Align(
              alignment: Alignment.topCenter,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.bottomLeft,
                child: SizedBox(
                  width: 340,
                  child: _Headline(spans: [TextSpan(text: _titles[step])]),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StepTab extends StatelessWidget {
  const _StepTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? YakkuPalette.Ink : YakkuPalette.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? YakkuPalette.Ink : YakkuPalette.roseBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? YakkuPalette.white : YakkuPalette.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

/// Vibe-check poll card used by slide 2. Step 1 ("Ask") shows it tilted;
/// step 2 ("Guess", [guessed]) shows it straight with the first option picked.
class _VibeCheckCard extends StatelessWidget {
  const _VibeCheckCard({super.key, this.guessed = false, this.t = 1});

  final bool guessed;

  /// Progress through the 5s step (0..1). On the Guess step a tap lands on the
  /// first option at ~30% and it turns selected at ~38%.
  final double t;

  static const _options = [
    ('Fully chill', 0.012),
    ('Chaotic', -0.008),
    ('Both, honestly', 0.014),
  ];

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: FittedBox(
        fit: BoxFit.contain,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCard(),
            if (guessed) ...[
              const SizedBox(height: 14),
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 14,
                    color: YakkuPalette.Ink,
                  ),
                  SizedBox(width: 5),
                  Text(
                    'Only you see your guess',
                    style: TextStyle(
                      color: YakkuPalette.Ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCard() {
    return Transform.rotate(
      angle: guessed ? 0 : -0.04,
      child: Container(
        width: 330,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
        decoration: BoxDecoration(
          color: YakkuPalette.accentPurple,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: YakkuPalette.Ink, width: 1.5),
          boxShadow: const [
            BoxShadow(color: YakkuPalette.Ink, offset: Offset(0, 6)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'VIBE CHECK',
              style: TextStyle(
                color: YakkuPalette.purpleInk,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Am I chill or chaotic?',
              style: TextStyle(
                color: YakkuPalette.Ink,
                fontSize: 28,
                height: 1.1,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.7,
              ),
            ),
            const SizedBox(height: 14),
            for (var i = 0; i < _options.length; i++) ...[
              _optionPill(_options[i].$1, _options[i].$2, i),
              if (i < _options.length - 1) const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }

  Widget _optionPill(String label, double angle, int index) {
    final selected = guessed && index == 0 && t >= 0.38;
    final tap = guessed && index == 0 ? _ramp(t, 0.28, 0.38) : 0.0;
    return Transform.rotate(
      angle: guessed ? 0 : angle,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _optionBox(label, selected),
          if (tap > 0)
            // Gold tap marker that presses onto the option, then fades.
            Positioned(
              left: 52,
              top: 0,
              bottom: 0,
              child: Center(
                child: Opacity(
                  opacity: (tap * (1 - _ramp(t, 0.75, 0.9))).clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: 1.4 - 0.4 * tap,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: YakkuPalette.Gold.withValues(alpha: 0.85),
                        shape: BoxShape.circle,
                        border: Border.all(color: YakkuPalette.Ink, width: 1),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _optionBox(String label, bool selected) {
    return Transform.rotate(
      angle: 0,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: selected ? YakkuPalette.Ink : YakkuPalette.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? YakkuPalette.white : YakkuPalette.bodyInk,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_rounded,
                size: 18,
                color: YakkuPalette.white,
              ),
          ],
        ),
      ),
    );
  }
}

/// Step 3 ("Share") of slide 2: the poll card, a Share button and the three
/// share targets. Laid out on a fixed canvas and scaled down to fit.
class _ShareStepCard extends StatelessWidget {
  const _ShareStepCard({super.key, this.t = 1});

  /// Progress through the 5s step: the Share button lands first, then the
  /// Instagram, WhatsApp and Snapchat tiles pop in one after another.
  final double t;

  static const _canvasWidth = 330.0;
  static const _canvasHeight = 440.0;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.contain,
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: _canvasWidth,
        height: _canvasHeight,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: 10,
              child: Center(
                child: Transform.rotate(angle: -0.04, child: _miniCard()),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 270,
              child: Center(
                child: Opacity(
                  opacity: _ramp(t, 0.08, 0.2),
                  child: Container(
                    width: 190,
                    height: 50,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: YakkuPalette.primary,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: YakkuPalette.Ink, width: 2),
                      boxShadow: const [
                        BoxShadow(
                          color: YakkuPalette.Ink,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.ios_share_rounded,
                          size: 20,
                          color: YakkuPalette.white,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Share',
                          style: TextStyle(
                            color: YakkuPalette.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              top: 320,
              width: _canvasWidth,
              height: 40,
              child: CustomPaint(
                painter: _ShareArrowsPainter(
                  _ramp(t, 0.3, 0.4),
                  _ramp(t, 0.45, 0.55),
                  _ramp(t, 0.6, 0.7),
                ),
              ),
            ),
            Positioned(
              left: 32,
              top: 360,
              child: _Pop(
                value: _ramp(t, 0.3, 0.42),
                child: const _ShareTile(
                  angle: -0.14,
                  gradient: LinearGradient(
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                    colors: [
                      YakkuPalette.instagramOrange,
                      YakkuPalette.instagramPink,
                      YakkuPalette.instagramPurple,
                    ],
                  ),
                  icon: FontAwesomeIcons.instagram,
                  iconColor: YakkuPalette.white,
                ),
              ),
            ),
            Positioned(
              left: 134,
              top: 360,
              child: _Pop(
                value: _ramp(t, 0.45, 0.57),
                child: const _ShareTile(
                  angle: 0.03,
                  color: YakkuPalette.whatsappGreen,
                  icon: FontAwesomeIcons.whatsapp,
                  iconColor: YakkuPalette.white,
                ),
              ),
            ),
            Positioned(
              left: 236,
              top: 360,
              child: _Pop(
                value: _ramp(t, 0.6, 0.72),
                child: const _ShareTile(
                  angle: 0.14,
                  color: YakkuPalette.snapchatYellow,
                  icon: FontAwesomeIcons.snapchat,
                  iconColor: YakkuPalette.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniCard() {
    return Container(
      width: 230,
      height: 230,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: YakkuPalette.accentPurple,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: YakkuPalette.Ink, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: YakkuPalette.shadowInk10,
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Yakku.',
                style: TextStyle(
                  color: YakkuPalette.Ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'Vibe Check',
                style: TextStyle(
                  color: YakkuPalette.Ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Am I chill or chaotic?',
            style: TextStyle(
              color: YakkuPalette.Ink,
              fontSize: 20,
              height: 1.1,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 10),
          for (final label in const [
            'Fully chill',
            'Chaotic',
            'Both, honestly',
          ]) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: YakkuPalette.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              // Options are blurred: the recipient can't peek before answering.
              child: ImageFiltered(
                imageFilter: ui.ImageFilter.blur(sigmaX: 2.5, sigmaY: 2.5),
                child: Text(
                  label,
                  style: const TextStyle(
                    color: YakkuPalette.Ink,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
          ],
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Expanded(
                child: Text(
                  "Tap to answer. They\nwon't know it was you.",
                  style: TextStyle(
                    color: YakkuPalette.Ink,
                    fontSize: 10,
                    height: 1,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Transform.rotate(
                angle: 0.07,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: YakkuPalette.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: YakkuPalette.Ink, width: 1.2),
                    boxShadow: const [
                      BoxShadow(color: YakkuPalette.Ink, offset: Offset(0, 2)),
                    ],
                  ),
                  child: const Text(
                    "What's my\naura?",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Pacifico',
                      color: YakkuPalette.purpleInk,
                      fontSize: 10,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Scales and fades [child] in as [value] goes 0..1.
class _Pop extends StatelessWidget {
  const _Pop({required this.value, required this.child});

  final double value;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: value,
      child: Transform.scale(
        scale: 0.6 + 0.4 * Curves.easeOutBack.transform(value),
        child: child,
      ),
    );
  }
}

class _ShareTile extends StatelessWidget {
  const _ShareTile({
    required this.angle,
    required this.icon,
    required this.iconColor,
    this.color,
    this.gradient,
  });

  final double angle;
  final FaIconData icon;
  final Color iconColor;
  final Color? color;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        width: 55,
        height: 55,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: YakkuPalette.Ink, width: 2),
          boxShadow: const [
            BoxShadow(color: YakkuPalette.Ink, offset: Offset(0, 4)),
          ],
        ),
        child: FaIcon(icon, size: 30, color: iconColor),
      ),
    );
  }
}

class _ShareArrowsPainter extends CustomPainter {
  const _ShareArrowsPainter(this.left, this.centre, this.right);

  /// 0..1 draw progress of each arrow.
  final double left;
  final double centre;
  final double right;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = YakkuPalette.Ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final h = size.height;
    final mid = size.width / 2;
    // Left and right arcs leave the button sideways, then curve down onto the
    // tiles; the centre arrow goes straight down.
    const startInset = 60.0;
    final leftPath = Path()
      ..moveTo(mid - startInset, 0)
      ..cubicTo(mid - startInset - 40, 0, 62, h * 0.25, 62, h - 4);
    final centrePath = Path()
      ..moveTo(mid, 0)
      ..lineTo(mid, h - 4);
    final rightPath = Path()
      ..moveTo(mid + startInset, 0)
      ..cubicTo(
        mid + startInset + 40,
        0,
        size.width - 62,
        h * 0.25,
        size.width - 62,
        h - 4,
      );

    final arrows = [
      (leftPath, left, 62.0),
      (centrePath, centre, mid),
      (rightPath, right, size.width - 62),
    ];
    for (final (path, progress, x) in arrows) {
      if (progress <= 0) continue;
      // Draw the path partially, then the arrow head once it has arrived.
      for (final metric in path.computeMetrics()) {
        canvas.drawPath(metric.extractPath(0, metric.length * progress), paint);
      }
      if (progress >= 1) {
        canvas.drawLine(Offset(x, h - 4), Offset(x - 6, h - 13), paint);
        canvas.drawLine(Offset(x, h - 4), Offset(x + 6, h - 13), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ShareArrowsPainter old) =>
      old.left != left || old.centre != centre || old.right != right;
}

/// Step 4 ("Compare") of slide 2: your answer vs. your circle, then the vote
/// breakdown. Laid out on a fixed canvas and scaled down to fit.
class _CompareStepCard extends StatelessWidget {
  const _CompareStepCard({super.key, this.t = 1});

  /// Progress through the 5s step: the vote bars fill one by one, then the
  /// "Plot twist." sticker lands.
  final double t;

  static const _canvasWidth = 330.0;
  static const _canvasHeight = 400.0;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.contain,
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: _canvasWidth,
        height: _canvasHeight,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(left: 0, right: 0, top: 22, child: _versusPanel()),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: Center(
                child: Opacity(
                  opacity: _ramp(t, 0.75, 0.82),
                  child: Transform.rotate(
                    angle: 0.1,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: YakkuPalette.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: YakkuPalette.Ink, width: 1.5),
                      ),
                      child: const Text(
                        'Plot twist.',
                        style: TextStyle(
                          fontFamily: 'Pacifico',
                          color: YakkuPalette.primary,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 218,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'How they voted',
                        style: TextStyle(
                          color: YakkuPalette.Ink,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Tap to see why',
                        style: TextStyle(
                          color: YakkuPalette.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _VoteRow(
                    label: 'Chaotic',
                    percent: 63,
                    comments: 5,
                    highlighted: true,
                    fill: _ramp(t, 0.12, 0.35),
                  ),
                  const SizedBox(height: 8),
                  _VoteRow(
                    label: 'Fully chill',
                    percent: 22,
                    comments: 2,
                    isYou: true,
                    fill: _ramp(t, 0.35, 0.5),
                  ),
                  const SizedBox(height: 8),
                  _VoteRow(
                    label: 'Both, honestly',
                    percent: 15,
                    comments: 1,
                    fill: _ramp(t, 0.5, 0.62),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _versusPanel() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      decoration: BoxDecoration(
        color: YakkuPalette.Ink,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 104,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Row(
                  children: [
                    Expanded(
                      child: _VersusTile(
                        color: YakkuPalette.primaryBright,
                        title: 'You',
                        titleColor: YakkuPalette.Ink,
                        answer: 'Fully chill',
                      ),
                    ),
                    SizedBox(width: 6),
                    Expanded(
                      child: _VersusTile(
                        color: YakkuPalette.white,
                        title: 'Your circle',
                        titleColor: YakkuPalette.textSecondary,
                        answer: 'Chaotic',
                        percent: '63%',
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: YakkuPalette.Ink,
                    shape: BoxShape.circle,
                    border: Border.all(color: YakkuPalette.white, width: 2),
                  ),
                  child: const Text(
                    'vs',
                    style: TextStyle(
                      color: YakkuPalette.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'You said chill. They said chaos.',
            style: TextStyle(
              color: YakkuPalette.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _VersusTile extends StatelessWidget {
  const _VersusTile({
    required this.color,
    required this.title,
    required this.titleColor,
    required this.answer,
    this.percent,
  });

  final Color color;
  final String title;
  final Color titleColor;
  final String answer;
  final String? percent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: titleColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (percent != null)
                Text(
                  percent!,
                  style: const TextStyle(
                    color: YakkuPalette.primary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          ),
          Text(
            answer,
            style: const TextStyle(
              color: YakkuPalette.Ink,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _VoteRow extends StatelessWidget {
  const _VoteRow({
    required this.label,
    required this.percent,
    required this.comments,
    this.highlighted = false,
    this.isYou = false,
    this.fill = 1,
  });

  /// 0..1: how far the bar, percentage and comment badge have appeared.
  final double fill;

  final String label;
  final int percent;
  final int comments;
  final bool highlighted;
  final bool isYou;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: YakkuPalette.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: YakkuPalette.shadowInk08,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      // Border is painted over the fill bar so the bar can't cover or clip it.
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: highlighted ? YakkuPalette.primary : YakkuPalette.roseBorder,
          width: highlighted ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: percent / 100 * fill,
              child: ColoredBox(
                color: highlighted ? YakkuPalette.Blush : YakkuPalette.hairline,
              ),
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: YakkuPalette.Ink,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (isYou) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: YakkuPalette.primary),
                      ),
                      child: const Text(
                        'You',
                        style: TextStyle(
                          color: YakkuPalette.primary,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (fill > 0)
                    Text(
                      '${(percent * fill).round()}%',
                      style: const TextStyle(
                        color: YakkuPalette.Ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  const SizedBox(width: 8),
                  if (fill >= 1)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: YakkuPalette.pinkMist,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: YakkuPalette.pinkWash),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const FaIcon(
                            FontAwesomeIcons.comment,
                            size: 14,
                            color: YakkuPalette.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$comments',
                            style: const TextStyle(
                              color: YakkuPalette.primary,
                              fontSize: 11.5,
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

class _SlideCommunity extends StatelessWidget {
  const _SlideCommunity();

  static const _headline = TextStyle(
    color: YakkuPalette.Ink,
    fontSize: 40,
    height: 1.04,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.4,
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            clipBehavior: Clip.none,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Transform.rotate(
                  angle: -0.05,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                    decoration: BoxDecoration(
                      color: YakkuPalette.Ink,
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: const [
                        BoxShadow(
                          color: YakkuPalette.primary,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _Chip(
                              label: 'community',
                              color: YakkuPalette.Gold,
                              textColor: YakkuPalette.Ink,
                            ),
                            Transform.rotate(
                              angle: 0.07,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: YakkuPalette.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: YakkuPalette.Ink,
                                    width: 1.5,
                                  ),
                                ),
                                child: const Text(
                                  'No judgement.',
                                  style: TextStyle(
                                    fontFamily: 'Pacifico',
                                    color: YakkuPalette.primary,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'My best friend tries to flirt with my girlfriend. '
                          'Do I say something?',
                          style: TextStyle(
                            color: YakkuPalette.white,
                            fontSize: 22,
                            height: 1.15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const _Chip(
                          label: '38 answers',
                          color: YakkuPalette.white,
                          textColor: YakkuPalette.Ink,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const _AnswerBubble(
                  angle: 0.01,
                  text: 'Talk to him alone first. Not in front of her.',
                ),
                const SizedBox(height: 15),
                const _AnswerBubble(
                  angle: -0.04,
                  text: 'Ask her how she feels before you say anything to him.',
                ),
                const SizedBox(height: 20),
                const Text(
                  "Ask the community\nwhat you can't ask\nyour friends.",
                  style: _headline,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AnswerBubble extends StatelessWidget {
  const _AnswerBubble({required this.text, required this.angle});

  final String text;
  final double angle;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        margin: const EdgeInsets.only(left: 16, right: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: YakkuPalette.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: YakkuPalette.Ink, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: YakkuPalette.accentGreen,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'been there',
                style: TextStyle(
                  color: YakkuPalette.forestGreen,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              text,
              style: const TextStyle(
                color: YakkuPalette.Ink,
                fontSize: 15,
                height: 1.25,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    return const Text.rich(
      TextSpan(
        text: 'Yakku',
        style: TextStyle(
          color: YakkuPalette.textPrimary,
          fontSize: 28,
          height: 1,
          fontWeight: FontWeight.w800,
          letterSpacing: -1,
        ),
        children: [
          TextSpan(
            text: '.',
            style: TextStyle(color: YakkuPalette.primary),
          ),
        ],
      ),
    );
  }
}

class _PreviewStack extends StatefulWidget {
  const _PreviewStack();

  @override
  State<_PreviewStack> createState() => _PreviewStackState();
}

class _PreviewStackState extends State<_PreviewStack>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<Animation<double>> _falls;
  late final List<Animation<double>> _fades;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    // Staggered intervals: card 1 → 2 → 3, top-to-bottom fall.
    const intervals = <(double, double)>[
      (0.00, 0.42),
      (0.22, 0.64),
      (0.44, 0.86),
    ];

    _falls = [
      for (final (begin, end) in intervals)
        CurvedAnimation(
          parent: _controller,
          curve: Interval(begin, end, curve: Curves.easeOutCubic),
        ),
    ];
    _fades = [
      for (final (begin, end) in intervals)
        CurvedAnimation(
          parent: _controller,
          curve: Interval(begin, end, curve: Curves.easeOut),
        ),
    ];

    _runLoop();
  }

  Future<void> _runLoop() async {
    while (mounted) {
      await _controller.forward(from: 0);
      if (!mounted) return;
      await Future<void>.delayed(const Duration(seconds: 2));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // The cards are laid out on a fixed design canvas and scaled down to fit.
  static const _canvasWidth = 372.0;
  static const _canvasHeight = 362.0;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.contain,
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: _canvasWidth,
        height: _canvasHeight,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 10,
                  top: 0,
                  child: _FallIn(
                    progress: _falls[0].value,
                    opacity: _fades[0].value,
                    child: const _PreviewCard(
                      width: 278,
                      color: YakkuPalette.accentPurple,
                      label: 'friends',
                      labelColor: YakkuPalette.primary,
                      labelTextColor: YakkuPalette.white,
                      question: 'Would you trust me with a secret?',
                      questionColor: YakkuPalette.Ink,
                    ),
                  ),
                ),
                Positioned(
                  left: 99,
                  top: 102,
                  child: _FallIn(
                    progress: _falls[1].value,
                    opacity: _fades[1].value,
                    child: const _PreviewCard(
                      width: 273,
                      color: YakkuPalette.Ink,
                      label: 'community',
                      labelColor: YakkuPalette.Gold,
                      labelTextColor: YakkuPalette.Ink,
                      question: 'Moved cities alone. Did it get easier?',
                      questionColor: YakkuPalette.white,
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  top: 230,
                  child: _FallIn(
                    progress: _falls[2].value,
                    opacity: _fades[2].value,
                    child: const _PreviewCard(
                      width: 362,
                      color: YakkuPalette.primary,
                      question: 'Be honest. Am I hard to get close to?',
                      questionColor: YakkuPalette.white,
                      showStats: true,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FallIn extends StatelessWidget {
  const _FallIn({
    required this.progress,
    required this.opacity,
    required this.child,
  });

  final double progress;
  final double opacity;
  final Widget child;

  static const _fallDistance = 72.0;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, (1 - progress) * -_fallDistance),
        child: child,
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.width,
    required this.color,
    required this.question,
    required this.questionColor,
    this.label,
    this.labelColor,
    this.labelTextColor,
    this.showStats = false,
  });

  final double width;
  final Color color;
  final String question;
  final Color questionColor;
  final String? label;
  final Color? labelColor;
  final Color? labelTextColor;
  final bool showStats;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: YakkuPalette.Ink, width: 2),
        boxShadow: const [
          BoxShadow(color: YakkuPalette.Ink, offset: Offset(0, 7)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: labelColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                label!,
                style: TextStyle(
                  color: labelTextColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],
          Text(
            question,
            style: TextStyle(
              color: questionColor,
              fontSize: 24,
              height: 1.12,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
            ),
          ),
          if (showStats) ...[
            const SizedBox(height: 14),
            const Row(
              children: [
                _Chip(
                  label: '24 answers',
                  color: YakkuPalette.white,
                  textColor: YakkuPalette.Ink,
                ),
                SizedBox(width: 8),
                _Chip(
                  label: 'anonymous',
                  color: YakkuPalette.Ink,
                  textColor: YakkuPalette.white,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.color,
    required this.textColor,
  });

  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
