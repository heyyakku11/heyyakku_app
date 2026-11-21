import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/data/models/plans/yakku_plan.dart';
import 'package:yakku/data/models/user/user_profile_response.dart';

/// You-tab plan surface.
///
/// - Active Lite / Love: status card (days left + unlock counter).
/// - Otherwise: soft pink upsell with higher-tier mini-cards (hidden when
///   [upgradePlans] is empty).
class ProfilePlanCard extends StatelessWidget {
  const ProfilePlanCard({
    super.key,
    required this.currentPlan,
    required this.upgradePlans,
    required this.onSeePlans,
    this.onKeepLove,
    this.onGetLove,
    this.lovePlan,
  });

  final UserPlanResponse? currentPlan;
  final List<YakkuPlan> upgradePlans;
  final VoidCallback onSeePlans;

  /// Renew / keep Love (Love status card CTA).
  final VoidCallback? onKeepLove;

  /// Upsell to Love from Lite.
  final VoidCallback? onGetLove;

  /// Catalog Love row for CTA price; falls back to a generic label.
  final YakkuPlan? lovePlan;

  @override
  Widget build(BuildContext context) {
    final effective = effectivePlanCode(
      code: currentPlan?.code,
      isExpired: currentPlan?.isExpired ?? false,
    );
    final activePaid = currentPlan != null &&
        !(currentPlan!.isExpired) &&
        (effective == YakkuPlan.liteCode || effective == YakkuPlan.loveCode);

    if (activePaid) {
      return _ActivePlanStatusCard(
        plan: currentPlan!,
        lovePlan: lovePlan,
        onKeepLove: onKeepLove ?? onSeePlans,
        onGetLove: onGetLove ?? onSeePlans,
      );
    }

    if (upgradePlans.isEmpty) return const SizedBox.shrink();
    return _FreeUpsellPlanCard(
      currentPlan: currentPlan,
      upgradePlans: upgradePlans,
      onSeePlans: onSeePlans,
    );
  }
}

class _ActivePlanStatusCard extends StatelessWidget {
  const _ActivePlanStatusCard({
    required this.plan,
    required this.lovePlan,
    required this.onKeepLove,
    required this.onGetLove,
  });

  final UserPlanResponse plan;
  final YakkuPlan? lovePlan;
  final VoidCallback onKeepLove;
  final VoidCallback onGetLove;

  bool get _isLove =>
      effectivePlanCode(code: plan.code, isExpired: plan.isExpired) ==
      YakkuPlan.loveCode;

  @override
  Widget build(BuildContext context) {
    final badgeName = (plan.name.trim().isNotEmpty
            ? plan.name
            : (_isLove ? 'Yakku Love' : 'Yakku Lite'))
        .toUpperCase();
    final days = plan.daysLeft;
    final daysLabel = days == null
        ? null
        : days <= 0
            ? 'Expires today'
            : days == 1
                ? '1 day left'
                : '$days days left';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: YakkuPalette.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: YakkuPalette.Raspberry.withValues(alpha: 0.55),
          width: 1.4,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: YakkuPalette.Raspberry,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Text(
                    'YOUR PLAN · $badgeName',
                    style: const TextStyle(
                      color: YakkuPalette.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.35,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              if (daysLabel != null)
                Text(
                  daysLabel,
                  style: TextStyle(
                    color: _isLove
                        ? YakkuPalette.Raspberry
                        : YakkuPalette.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          if (_isLove) _LoveUnlockBlock(unlocked: plan.cardsUnlocked)
          else
            _LiteUnlockBlock(
              unlocked: plan.cardsUnlocked,
              tickets: plan.unlockTickets ?? 3,
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: _isLove ? onKeepLove : onGetLove,
              style: OutlinedButton.styleFrom(
                foregroundColor: YakkuPalette.Raspberry,
                side: const BorderSide(
                  color: YakkuPalette.Raspberry,
                  width: 1.6,
                ),
                shape: const StadiumBorder(),
              ),
              child: Text(
                _isLove
                    ? 'Keep Yakku Love · ${lovePlan?.formattedPrice ?? '₹299'}'
                    : 'Get unlimited with Yakku Love',
                style: const TextStyle(
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

class _LoveUnlockBlock extends StatelessWidget {
  const _LoveUnlockBlock({required this.unlocked});

  final int unlocked;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '$unlocked',
                style: const TextStyle(
                  color: YakkuPalette.Ink,
                  fontSize: 34,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.8,
                ),
              ),
              const TextSpan(
                text: '  cards unlocked so far',
                style: TextStyle(
                  color: YakkuPalette.Ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: const LinearProgressIndicator(
            value: 1,
            minHeight: 8,
            backgroundColor: YakkuPalette.pinkMist,
            color: YakkuPalette.Blush,
          ),
        ),
      ],
    );
  }
}

class _LiteUnlockBlock extends StatelessWidget {
  const _LiteUnlockBlock({
    required this.unlocked,
    required this.tickets,
  });

  final int unlocked;
  final int tickets;

  @override
  Widget build(BuildContext context) {
    final total = tickets <= 0 ? 3 : tickets;
    final remaining = (total - unlocked).clamp(0, total);
    final filled = remaining;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '$remaining',
                style: const TextStyle(
                  color: YakkuPalette.Ink,
                  fontSize: 34,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.8,
                ),
              ),
              TextSpan(
                text: ' of $total cards left to unlock',
                style: const TextStyle(
                  color: YakkuPalette.Ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            for (var i = 0; i < total; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: i < filled
                        ? YakkuPalette.Blush
                        : YakkuPalette.pinkMist,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'New cards stay locked till you get more.',
          style: TextStyle(
            color: YakkuPalette.textSecondary,
            fontSize: 13,
            height: 1.35,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _FreeUpsellPlanCard extends StatelessWidget {
  const _FreeUpsellPlanCard({
    required this.currentPlan,
    required this.upgradePlans,
    required this.onSeePlans,
  });

  final UserPlanResponse? currentPlan;
  final List<YakkuPlan> upgradePlans;
  final VoidCallback onSeePlans;

  @override
  Widget build(BuildContext context) {
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
