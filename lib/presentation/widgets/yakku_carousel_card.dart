import 'package:flutter/material.dart';
import 'package:yakku/core/constants/app_radii.dart';

class YakkuCarouselCard extends StatelessWidget {
  const YakkuCarouselCard({
    super.key,
    required this.question,
    required this.options,
    this.gradientIndex = 0,
    this.category,
    this.categories = const [],
    this.voteCount,
    this.allowComments,
    this.expiresAt,
    this.showAddOption = false,
    this.expandOptions = false,
    this.onMakeItYours,
  });

  final String question;
  final List<String> options;
  final int gradientIndex;
  final String? category;
  final List<String> categories;
  final int? voteCount;
  final bool? allowComments;
  final DateTime? expiresAt;
  final bool showAddOption;
  final bool expandOptions;
  final VoidCallback? onMakeItYours;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tone = _CarouselTone.of(gradientIndex);
    final categoryLabel = category?.trim() ?? '';
    final categoryLabels = [
      for (final name in categories)
        if (name.trim().isNotEmpty) name.trim(),
    ];
    final showDetails =
        allowComments != null || expiresAt != null || categoryLabels.isNotEmpty;

    final optionList = Column(
      children: [
        for (final option in options)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _OptionRow(text: option, tone: tone),
          ),
        if (showAddOption) _AddOptionRow(tone: tone),
      ],
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: tone.gradient,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (categoryLabel.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: tone.foreground.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(AppRadii.full),
                    ),
                    child: Text(
                      '#${categoryLabel.toUpperCase()}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: tone.foreground,
                      ),
                    ),
                  ),
                const Spacer(),
                if (voteCount != null) ...[
                  Icon(Icons.people_alt_outlined, size: 15, color: tone.muted),
                  const SizedBox(width: 5),
                  Text(
                    voteCount == 1 ? '1 vote' : '$voteCount votes',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: tone.muted,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 18),
            Text(
              question,
              maxLines: expandOptions ? 3 : 4,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                height: 1.1,
                letterSpacing: -0.5,
                color: tone.foreground,
              ),
            ),
            const SizedBox(height: 20),
            if (expandOptions) Expanded(child: optionList) else optionList,
            if (showDetails) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (allowComments != null)
                    _DetailChip(
                      tone: tone,
                      icon: allowComments!
                          ? Icons.chat_bubble_outline
                          : Icons.speaker_notes_off_outlined,
                      label: allowComments! ? 'Comments on' : 'Comments off',
                    ),
                  if (expiresAt != null)
                    _DetailChip(
                      tone: tone,
                      icon: Icons.schedule,
                      label: _expiryLabel(expiresAt!),
                    ),
                  for (final name in categoryLabels)
                    _DetailChip(
                      tone: tone,
                      label: '#${name.toUpperCase()}',
                    ),
                ],
              ),
            ],
            if (onMakeItYours != null) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tone.buttonFill,
                    foregroundColor: tone.buttonForeground,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: onMakeItYours,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Make it yours',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 16),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline_rounded, size: 14, color: tone.footer),
                const SizedBox(width: 5),
                Text(
                  'Anonymous voting',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: tone.footer,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({required this.text, required this.tone});

  final String text;
  final _CarouselTone tone;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tone.optionFill,
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: tone.optionBorder, width: 1.5),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _capitalizeOption(text),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: tone.optionForeground,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 13,
              color: tone.chevron,
            ),
          ],
        ),
      ),
    );
  }
}

String _capitalizeOption(String value) {
  final text = value.trim();
  if (text.isEmpty) return text;
  return text[0].toUpperCase() + text.substring(1);
}

String _expiryLabel(DateTime expiresAt) {
  final remaining = expiresAt.toLocal().difference(DateTime.now());
  if (!remaining.isNegative && remaining > Duration.zero) {
    final days = (remaining.inMinutes / (60 * 24)).ceil();
    if (days <= 1) return 'Expires in 1 day';
    return 'Expires in $days days';
  }
  return 'Expired';
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({required this.tone, required this.label, this.icon});

  final _CarouselTone tone;
  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tone.foreground.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadii.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: tone.foreground),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
              color: tone.foreground,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddOptionRow extends StatelessWidget {
  const _AddOptionRow({required this.tone});

  final _CarouselTone tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: tone.addFill,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: tone.addBorder),
      ),
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_rounded, size: 19, color: tone.foreground),
          const SizedBox(width: 6),
          Text(
            'Add your own',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: tone.foreground,
            ),
          ),
        ],
      ),
    );
  }
}

class _CarouselTone {
  const _CarouselTone({required this.gradient});

  final LinearGradient gradient;
  final Color foreground = Colors.black;
  final Color muted = const Color(0xA6000000);
  final Color footer = const Color(0xA6000000);
  final Color optionFill = const Color(0xD1FFFFFF);
  final Color optionForeground = Colors.black;
  final Color optionBorder = const Color(0x40000000);
  final Color chevron = Colors.black54;
  final Color addFill = const Color(0x33FFFFFF);
  final Color addBorder = const Color(0x2E000000);
  final Color buttonFill = Colors.black;
  final Color buttonForeground = Colors.white;

  static const _gradients = [
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFD6A5), Color(0xFFFF9F9F), Color(0xFFFFC6FF)],
    ),
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFB8E7FF), Color(0xFFCDB4FF), Color(0xFFFFC6FF)],
    ),
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFB7F8DB), Color(0xFF8FD3F4), Color(0xFFA78BFA)],
    ),
  ];

  static _CarouselTone of(int index) {
    return _CarouselTone(gradient: _gradients[index % _gradients.length]);
  }
}
