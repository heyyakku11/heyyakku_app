import 'package:flutter/material.dart';
import 'package:yakku/core/theme/yakku_palette.dart';

class AnonymousAvatar extends StatelessWidget {
  const AnonymousAvatar({
    super.key,
    this.seed = 0,
    this.size = 40,
  });

  final int seed;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = <Color>[
      YakkuPalette.ink,
      YakkuPalette.teal,
      YakkuPalette.coral,
      const Color(0xFF3D5A80),
      const Color(0xFF2A9D8F),
      const Color(0xFF7C6A0A),
    ];
    final color = colors[seed.abs() % colors.length];

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: color.withValues(alpha: 0.16),
      child: Icon(
        Icons.person_outline_rounded,
        size: size * 0.52,
        color: color,
      ),
    );
  }
}
