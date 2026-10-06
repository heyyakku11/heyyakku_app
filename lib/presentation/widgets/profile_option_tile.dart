import 'package:flutter/material.dart';

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
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Widget? trailing;
  final bool showChevron;
  final bool showDivider;

  static const double iconSize = 22;
  static const double _gap = 10;
  static const EdgeInsets padding = EdgeInsets.all(10);

  /// Lines up the divider with the label, past the icon and the gap.
  static const double dividerIndent = 10 + iconSize + _gap;

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
                Icon(icon, size: iconSize, color: iconColor),
                const SizedBox(width: _gap),
                Expanded(
                  child: Text(label, style: const TextStyle(fontSize: 16)),
                ),
                if (trailing != null)
                  trailing!
                else if (showChevron)
                  const Icon(Icons.arrow_forward_ios_outlined, size: 18),
              ],
            ),
          ),
        ),
        if (showDivider) const Divider(indent: dividerIndent),
      ],
    );
  }
}
