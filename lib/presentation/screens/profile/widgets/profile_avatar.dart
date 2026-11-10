import 'package:flutter/material.dart';
import 'package:yakku/core/theme/yakku_palette.dart';

/// The profile picture: a coloured circle with two eyes.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key, required this.color, this.size = 96});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final eye = size * 0.085;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 2; i++) ...[
            if (i > 0) SizedBox(width: size * 0.15),
            Container(
              width: eye,
              height: eye,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: YakkuPalette.Ink,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
