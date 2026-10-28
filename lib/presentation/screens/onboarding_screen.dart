import 'package:flutter/material.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/presentation/app_scope.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool _entering = false;

  @override
  void initState() {
    super.initState();
    // Warm the home feed while the user is still on onboarding.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AppScope.of(context).checkApi.preloadHome(loggedIn: false);
    });
  }

  Future<void> _continueAsGuest() async {
    if (_entering) return;
    setState(() => _entering = true);
    final scope = AppScope.of(context);
    await scope.authController.enterAsGuest();
    scope.guestSession.ensureGuestProfileInBackground();
    if (mounted) setState(() => _entering = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YakkuPalette.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Wordmark(),
              const SizedBox(height: 28),
              const SizedBox(height: 340, child: _PreviewStack()),
              const SizedBox(height: 28),
              const Text(
                "Ask what you're really thinking.",
                style: TextStyle(
                  color: YakkuPalette.textPrimary,
                  fontSize: 38,
                  height: 1.05,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Your friends answer honestly. Nobody knows who said what.',
                style: TextStyle(
                  color: YakkuPalette.textSecondary,
                  fontSize: 16,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _entering ? null : _continueAsGuest,
                  style: FilledButton.styleFrom(
                    backgroundColor: YakkuPalette.primary,
                    disabledBackgroundColor: YakkuPalette.primary.withValues(
                      alpha: 0.6,
                    ),
                    foregroundColor: YakkuPalette.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  child: _entering
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: YakkuPalette.white,
                          ),
                        )
                      : const Text(
                          'Ask my friends',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
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
          fontSize: 34,
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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final cardWidth = width * 0.74;

        return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 0,
                  top: height * 0.03,
                  child: _FallIn(
                    progress: _falls[0].value,
                    opacity: _fades[0].value,
                    child: Transform.rotate(
                      angle: -0.12,
                      child: _PreviewCard(
                        width: cardWidth,
                        color: YakkuPalette.accentPurple,
                        textColor: YakkuPalette.textPrimary,
                        question: 'Am I the dramatic friend?',
                        showStats: false,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  top: height * 0.28,
                  child: _FallIn(
                    progress: _falls[1].value,
                    opacity: _fades[1].value,
                    child: Transform.rotate(
                      angle: 0.09,
                      child: _PreviewCard(
                        width: cardWidth,
                        color: YakkuPalette.accentYellow,
                        textColor: YakkuPalette.textPrimary,
                        question: 'Should I text him first?',
                        showStats: false,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: width * 0.05,
                  top: height * 0.56,
                  child: _FallIn(
                    progress: _falls[2].value,
                    opacity: _fades[2].value,
                    child: Transform.rotate(
                      angle: -0.07,
                      child: _PreviewCard(
                        width: cardWidth,
                        color: YakkuPalette.primary,
                        textColor: YakkuPalette.white,
                        question:
                            'Do people like me, or just like having me around?',
                        lightChips: true,
                        showStats: true,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
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
    required this.textColor,
    required this.question,
    required this.showStats,
    this.lightChips = false,
  });

  final double width;
  final Color color;
  final Color textColor;
  final String question;
  final bool showStats;
  final bool lightChips;

  @override
  Widget build(BuildContext context) {
    final chipColor = lightChips
        ? YakkuPalette.white.withValues(alpha: 0.22)
        : YakkuPalette.white.withValues(alpha: 0.72);
    final chipText = lightChips
        ? YakkuPalette.white
        : YakkuPalette.textSecondary;

    return Container(
      width: width,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: YakkuPalette.shadowInk10,
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: TextStyle(
              color: textColor,
              fontSize: 23,
              height: 1.2,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          if (showStats) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                _Chip(
                  label: '128 votes',
                  color: chipColor,
                  textColor: chipText,
                ),
                const SizedBox(width: 8),
                _Chip(
                  label: 'Anonymous',
                  color: chipColor,
                  textColor: chipText,
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
