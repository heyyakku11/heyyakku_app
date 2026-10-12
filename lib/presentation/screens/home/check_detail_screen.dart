import 'package:flutter/material.dart';
import 'package:yakku/core/network/dio_error_mapper.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/data/models/home/home_feed_card.dart';
import 'package:yakku/presentation/app_scope.dart';
import 'package:yakku/presentation/screens/created_poll_screen.dart';

class CheckDetailScreen extends StatefulWidget {
  const CheckDetailScreen({super.key, required this.card});

  final HomeFeedCard card;

  @override
  State<CheckDetailScreen> createState() => _CheckDetailScreenState();
}

class _CheckDetailScreenState extends State<CheckDetailScreen> {
  int? _selectedIndex;
  bool _sending = false;

  HomeFeedCard get card => widget.card;

  List<int> get _answerIndexes {
    return [
      for (var index = 0; index < card.options.length; index++)
        if (!card.options[index].outlined) index,
    ];
  }

  Future<void> _send() async {
    final selected = _selectedIndex;
    if (selected == null || _sending) return;

    final answers = _answerIndexes;
    final selectedOptionIndex = answers.indexOf(selected);
    if (selectedOptionIndex < 0) return;

    final question = card.question.trim().isNotEmpty
        ? card.question.trim()
        : card.title.trim();
    final options = [
      for (final index in answers) card.options[index].label.trim(),
    ];

    setState(() => _sending = true);
    try {
      final poll = await AppScope.of(context).pollApi.createTextPoll(
        question: question,
        options: options,
        selectedOptionIndex: selectedOptionIndex,
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
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSend = _selectedIndex != null && !_sending;

    return Scaffold(
      backgroundColor: card.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(Icons.arrow_back, color: card.foregroundColor),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 4, 22, 16),
                children: [
                  _Header(card: card),
                  const SizedBox(height: 22),
                  Text(
                    card.title,
                    style: TextStyle(
                      color: card.foregroundColor,
                      fontSize: 34,
                      height: 1.05,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                    ),
                  ),
                  if (card.question.isNotEmpty &&
                      card.question != card.title) ...[
                    const SizedBox(height: 10),
                    Text(
                      card.question,
                      style: TextStyle(
                        color: card.foregroundColor,
                        fontSize: 22,
                        height: 1.25,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Text(
                        'TAP YOUR ANSWER',
                        style: TextStyle(
                          color: card.foregroundColor.withValues(alpha: 0.45),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.lock_outline,
                        size: 14,
                        color: card.foregroundColor.withValues(alpha: 0.45),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Only you see it',
                        style: TextStyle(
                          color: card.foregroundColor.withValues(alpha: 0.45),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  for (var index = 0; index < card.options.length; index++) ...[
                    _AnswerRow(
                      card: card,
                      option: card.options[index],
                      letter: _letterFor(index),
                      selected: _selectedIndex == index,
                      onTap: card.options[index].outlined
                          ? null
                          : () => setState(() => _selectedIndex = index),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton.icon(
                  onPressed: canSend ? _send : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1B1418),
                    disabledBackgroundColor: const Color(
                      0xFF1B1418,
                    ).withValues(alpha: 0.35),
                    foregroundColor: Colors.white,
                    disabledForegroundColor: Colors.white.withValues(
                      alpha: 0.7,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  icon: _sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.ios_share, size: 18),
                  label: const Text(
                    'Send to friends',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _letterFor(int index) {
    final letter = card.options[index].letter;
    if (letter != null && letter.isNotEmpty) return letter;
    return String.fromCharCode(65 + index);
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.card});

  final HomeFeedCard card;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (card.eyebrow != null)
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
                          color: card.accentColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          card.eyebrow!,
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
              if (card.meta != null) ...[
                const SizedBox(height: 8),
                Text(
                  card.meta!,
                  style: TextStyle(
                    color: card.foregroundColor.withValues(alpha: 0.55),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (card.sticker != null)
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
                  card.sticker!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Pacifico',
                    color: card.accentColor,
                    fontSize: 15,
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
    required this.card,
    required this.option,
    required this.letter,
    required this.selected,
    required this.onTap,
  });

  final HomeFeedCard card;
  final HomeFeedOption option;
  final String letter;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final outlined = option.outlined;
    final background = selected
        ? const Color(0xFF1B1418)
        : outlined
        ? Colors.transparent
        : Colors.white;
    final foreground = selected ? Colors.white : card.foregroundColor;
    final badgeColor = selected
        ? YakkuPalette.primary
        : card.accentColor.withValues(alpha: 0.18);

    final row = Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 14, 8),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: outlined ? Colors.transparent : badgeColor,
              shape: BoxShape.circle,
              border: outlined
                  ? Border.all(
                      color: card.foregroundColor.withValues(alpha: 0.35),
                    )
                  : null,
            ),
            child: Text(
              letter,
              style: TextStyle(
                color: selected
                    ? Colors.white
                    : outlined
                    ? card.foregroundColor.withValues(alpha: 0.7)
                    : card.foregroundColor,
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
          if (selected) const Icon(Icons.check, color: Colors.white, size: 20),
        ],
      ),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: outlined
            ? CustomPaint(
                painter: _DashedBorderPainter(
                  color: card.foregroundColor.withValues(alpha: 0.35),
                  radius: 16,
                ),
                child: row,
              )
            : DecoratedBox(
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: row,
              ),
      ),
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
