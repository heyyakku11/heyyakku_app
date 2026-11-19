import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/data/models/plans/yakku_plan.dart';
import 'package:yakku/data/models/user/user_profile_response.dart';

/// Soft pink upsell card: current plan badge, feature pills, higher-tier
/// mini-cards, and a "See plans" CTA. Returns nothing useful as a child when
/// [upgradePlans] is empty — callers should omit the widget entirely.
class ProfilePlanCard extends StatelessWidget {
  const ProfilePlanCard({
    super.key,
    required this.currentPlan,
    required this.upgradePlans,
    required this.onSeePlans,
  });

  final UserPlanResponse? currentPlan;
  final List<YakkuPlan> upgradePlans;
  final VoidCallback onSeePlans;

  @override
  Widget build(BuildContext context) {
    if (upgradePlans.isEmpty) return const SizedBox.shrink();

    final badge = planBadgeLabel(
      code: currentPlan?.code,
      name: currentPlan?.name,
      isExpired: currentPlan?.isExpired ?? false,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: YakkuPalette.pinkMist,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: YakkuPalette.white,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text(
                'YOUR PLAN · $badge',
                style: const TextStyle(
                  color: YakkuPalette.Raspberry,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.35,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'See what they won’t say to your face',
            style: TextStyle(
              color: YakkuPalette.Ink,
              fontSize: 24,
              height: 1.15,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 12),
          // Same Font Awesome icons as the results screen / ask-back UI.
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FeaturePill(
                icon: FontAwesomeIcons.comment,
                label: 'Every reason',
              ),
              _FeaturePill(
                icon: FontAwesomeIcons.arrowRotateLeft,
                label: 'Ask back everyone',
              ),
              _FeaturePill(
                icon: FontAwesomeIcons.penToSquare,
                label: 'Options others added',
              ),
            ],
          ),
          const SizedBox(height: 18),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < upgradePlans.length; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  Expanded(child: _PlanMiniCard(plan: upgradePlans[i])),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: onSeePlans,
              style: FilledButton.styleFrom(
                backgroundColor: YakkuPalette.Raspberry,
                foregroundColor: YakkuPalette.white,
                shape: const StadiumBorder(),
              ),
              child: const Text(
                'See plans',
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// White feature chip: raspberry Font Awesome icon + label (results-screen icons).
class _FeaturePill extends StatelessWidget {
  const _FeaturePill({required this.icon, required this.label});

  final FaIconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: YakkuPalette.white,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 12, 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(icon, size: 14, color: YakkuPalette.Raspberry),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: YakkuPalette.Ink,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanMiniCard extends StatelessWidget {
  const _PlanMiniCard({required this.plan});

  final YakkuPlan plan;

  @override
  Widget build(BuildContext context) {
    final isLove = plan.isLove;
    final fill = isLove ? YakkuPalette.butter : YakkuPalette.white;
    final border = isLove
        ? const Color(0xFFE8C44A)
        : YakkuPalette.Raspberry.withValues(alpha: 0.55);
    final badgeLabel = isLove ? 'Unlimited' : 'Popular';
    final badgeBg = isLove ? YakkuPalette.Ink : YakkuPalette.Raspberry;
    final badgeFg = isLove ? YakkuPalette.Gold : YakkuPalette.white;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border, width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              child: Text(
                badgeLabel,
                style: TextStyle(
                  color: badgeFg,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            plan.name,
            style: const TextStyle(
              color: YakkuPalette.Ink,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            plan.detailLine,
            style: const TextStyle(
              color: YakkuPalette.textSecondary,
              fontSize: 12,
              height: 1.3,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          const SizedBox(height: 10),
          Text(
            plan.formattedPrice,
            style: const TextStyle(
              color: YakkuPalette.Ink,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.6,
            ),
          ),
        ],
      ),
    );
  }
}
