import 'package:flutter/material.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/presentation/widgets/skeleton.dart';

/// What the You tab shows until the profile first loads: a round avatar, the name and the "Edit name and avatar"
/// line, the personality card, and the white list of options with an icon, a label and a badge on each row.
class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});

  static const _rows = 5;

  @override
  Widget build(BuildContext context) {
    return SkeletonPulse(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const SkeletonBox.circle(size: 96),
            const SizedBox(height: 14),
            const SkeletonBox(width: 150, height: 26, radius: 13),
            const SizedBox(height: 14),
            const SkeletonBox(width: 150, height: 14, radius: 7),
            const SizedBox(height: 24),
            const SkeletonBox(height: 190, radius: 28),
            const SizedBox(height: 16),
            DecoratedBox(
              decoration: BoxDecoration(
                color: YakkuPalette.white,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < _rows; i++)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        border: i < _rows - 1
                            ? const Border(
                                bottom: BorderSide(
                                  color: YakkuPalette.roseBorder,
                                ),
                              )
                            : null,
                      ),
                      child: const Row(
                        children: [
                          SkeletonBox.circle(size: 22),
                          SizedBox(width: 14),
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: SkeletonBox(
                                width: 120,
                                height: 14,
                                radius: 7,
                              ),
                            ),
                          ),
                          SkeletonBox(width: 22, height: 14, radius: 7),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
