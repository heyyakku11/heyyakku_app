import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:yakku/core/theme/yakku_palette.dart';

class ProfileOptionTile extends StatelessWidget {
  const ProfileOptionTile({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.iconColor,
    this.trailing,
    this.showChevron = true,
    this.showDivider = false,
    this.badgeCount,
    this.highlightBadge = false,
  });

  final FaIconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Widget? trailing;
  final bool showChevron;
  final bool showDivider;
  final int? badgeCount;

  /// Fills the badge with the brand colour, for counts that need attention.
  final bool highlightBadge;

  static const double iconSize = 22;
  static const double _gap = 12;
  static const EdgeInsets padding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 16,
  );

  /// Lines up the divider with the label, past the icon and the gap.
  static const double dividerIndent = 16 + iconSize + _gap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: padding,
            child: Row(
              children: [
                SizedBox(
                  width: iconSize,
                  child: Center(
                    child: FaIcon(icon, size: 18, color: iconColor),
                  ),
                ),
                const SizedBox(width: _gap),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (badgeCount != null && badgeCount! > 0) ...[
                  _CountBadge(count: badgeCount!, highlighted: highlightBadge),
                  const SizedBox(width: 8),
                ],
                if (trailing != null)
                  trailing!
                else if (showChevron)
                  FaIcon(
                    FontAwesomeIcons.chevronRight,
                    size: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              ],
            ),
          ),
        ),
        if (showDivider)
          const Divider(height: 1, thickness: 1, indent: dividerIndent),
      ],
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count, required this.highlighted});

  final int count;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: highlighted ? YakkuPalette.primary : YakkuPalette.chipSand,
        borderRadius: const BorderRadius.all(Radius.circular(999)),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          color: highlighted ? YakkuPalette.white : YakkuPalette.textPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
