import 'package:flutter/material.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/presentation/widgets/app_toast.dart';

/// What can be bought to read every reason and ask anyone back.
enum YakkuPlanChoice {
  card(
    title: 'This card',
    short: 'Card',
    detail: 'One card',
    price: '\u20B949',
    fill: YakkuPalette.white,
  ),
  lite(
    title: 'Yakku Lite',
    short: 'Lite',
    detail: '3 cards \u00B7 7 days',
    price: '\u20B999',
    fill: YakkuPalette.pillPink,
    badge: 'Popular',
  ),
  love(
    title: 'Yakku Love',
    short: 'Love',
    detail: 'Unlimited \u00B7 30 days',
    price: '\u20B9299',
    fill: YakkuPalette.butter,
    badge: 'Unlimited',
  );

  const YakkuPlanChoice({
    required this.title,
    required this.short,
    required this.detail,
    required this.price,
    required this.fill,
    this.badge,
  });

  final String title;

  /// The column heading of the comparison table.
  final String short;
  final String detail;
  final String price;
  final Color fill;
  final String? badge;

  /// The text of the buy button: "Get Yakku Lite \u00B7 \u20B999".
  String get buttonLabel =>
      'Get ${this == card ? 'this card' : title} \u00B7 $price';
}

/// Opens the plans sheet. Returns true when the user got a plan or the card,
/// so the caller can reload what it shows.
///
/// There is no payment flow in the app yet: choosing a plan only says so. When
/// payments exist, this is the one place to start them from [YakkuPlanChoice].
Future<bool> showYakkuPlans(BuildContext context) async {
  final choice = await showModalBottomSheet<YakkuPlanChoice>(
    context: context,
    backgroundColor: YakkuPalette.cream,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    builder: (_) => const YakkuPlansSheet(),
  );
  if (choice == null) return false;
  AppToast.show(
    "Payments aren't live yet. We'll let you know when ${choice.title} is ready.",
  );
  return false;
}

/// "See what they really think": the three ways to read every reason, side by
/// side, with a buy button for the one picked.
class YakkuPlansSheet extends StatefulWidget {
  const YakkuPlansSheet({super.key, this.initial = YakkuPlanChoice.lite});

  final YakkuPlanChoice initial;

  @override
  State<YakkuPlansSheet> createState() => _YakkuPlansSheetState();
}

class _YakkuPlansSheetState extends State<YakkuPlansSheet> {
  static const _ink = YakkuPalette.textPrimary;
  static const _night = Color(0xFF211A1D);

  late YakkuPlanChoice _picked = widget.initial;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: YakkuPalette.sheetHandle,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'See what they really think',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 24,
                      height: 1.15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  color: _ink,
                  tooltip: 'Close',
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Same height for all three cards; the sheet scrolls, so the row
            // has no height of its own to stretch to.
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final plan in YakkuPlanChoice.values) ...[
                    if (plan != YakkuPlanChoice.values.first)
                      const SizedBox(width: 8),
                    Expanded(
                      child: _PlanCard(
                        plan: plan,
                        selected: plan == _picked,
                        onTap: () => setState(() => _picked = plan),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            _ComparisonTable(picked: _picked),
            const SizedBox(height: 16),
            const Text(
              "See what they won't say to your face",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _ink,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(_picked),
              style: FilledButton.styleFrom(
                backgroundColor: YakkuPalette.primary,
                foregroundColor: YakkuPalette.white,
                minimumSize: const Size.fromHeight(58),
                shape: const StadiumBorder(),
              ),
              child: Text(
                _picked.buttonLabel,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "One-time payment. Doesn't renew.",
              textAlign: TextAlign.center,
              style: TextStyle(color: YakkuPalette.textSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.selected,
    required this.onTap,
  });

  final YakkuPlanChoice plan;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final badge = plan.badge;
    final dark = plan == YakkuPlanChoice.love;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: plan.fill,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: selected
                    ? _YakkuPlansSheetState._night
                    : YakkuPalette.roseBorder,
                width: selected ? 2 : 1.2,
              ),
            ),
            child: InkWell(
              key: ValueKey('plan-${plan.name}'),
              customBorder: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 14, 10, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            plan.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: YakkuPalette.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        _Radio(selected: selected, dark: dark),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      plan.detail,
                      style: const TextStyle(
                        color: YakkuPalette.textSecondary,
                        fontSize: 12,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      plan.price,
                      style: TextStyle(
                        color: plan == YakkuPlanChoice.lite
                            ? YakkuPalette.primary
                            : YakkuPalette.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (badge != null)
            Positioned(
              top: -10,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: dark
                      ? _YakkuPlansSheetState._night
                      : YakkuPalette.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    color: dark ? YakkuPalette.Gold : YakkuPalette.white,
                    fontSize: 11,
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

/// The round tick box on a plan card.
class _Radio extends StatelessWidget {
  const _Radio({required this.selected, required this.dark});

  final bool selected;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected
            ? _YakkuPlansSheetState._night
            : (dark ? YakkuPalette.butter : YakkuPalette.white),
        border: selected
            ? null
            : Border.all(color: YakkuPalette.roseBorder, width: 1.2),
      ),
      child: selected
          ? const Icon(Icons.check_rounded, size: 15, color: YakkuPalette.white)
          : null,
    );
  }
}

/// One row of the comparison: what it is, and what each plan gets.
class _Feature {
  const _Feature({
    required this.icon,
    required this.tint,
    required this.ink,
    required this.title,
    this.subtitle,
    required this.values,
  });

  final IconData icon;
  final Color tint;
  final Color ink;
  final String title;
  final String? subtitle;

  /// Per plan, in [YakkuPlanChoice.values] order. A null main text is a tick.
  final List<({String? main, String? note})> values;
}

class _ComparisonTable extends StatelessWidget {
  const _ComparisonTable({required this.picked});

  final YakkuPlanChoice picked;

  static const _rowHeight = 64.0;
  static const _headHeight = 46.0;

  static const _features = <_Feature>[
    _Feature(
      icon: Icons.reply_rounded,
      tint: Color(0xFFFFEFC2),
      ink: Color(0xFF8A6A12),
      title: 'Ask back everyone',
      values: [
        (main: '1 time', note: 'each'),
        (main: '3 times', note: 'each'),
        (main: 'Unlimited', note: null),
      ],
    ),
    _Feature(
      icon: Icons.chat_bubble_outline_rounded,
      tint: YakkuPalette.pillPink,
      ink: YakkuPalette.primary,
      title: 'Every reason',
      values: [
        (main: null, note: null),
        (main: null, note: null),
        (main: null, note: null),
      ],
    ),
    _Feature(
      icon: Icons.edit_outlined,
      tint: YakkuPalette.accentPurple,
      ink: YakkuPalette.purpleInk,
      title: 'Options',
      subtitle: 'others added',
      values: [
        (main: null, note: null),
        (main: null, note: null),
        (main: null, note: null),
      ],
    ),
    _Feature(
      icon: Icons.copy_rounded,
      tint: YakkuPalette.mint,
      ink: YakkuPalette.forestGreen,
      title: 'Cards',
      subtitle: 'unlocked',
      values: [
        (main: '1', note: 'this one'),
        (main: '3', note: 'in 7 days'),
        (main: 'Unlimited', note: 'in 30 days'),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: YakkuPalette.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: YakkuPalette.roseBorder, width: 1.2),
      ),
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      // Every row is a fixed height, so the table has one too; the selected
      // column stretches to it.
      child: SizedBox(
        height: _headHeight + _rowHeight * _features.length,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 11, child: _labels()),
            for (var i = 0; i < YakkuPlanChoice.values.length; i++)
              Expanded(flex: 6, child: _column(YakkuPlanChoice.values[i], i)),
          ],
        ),
      ),
    );
  }

  Widget _labels() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(
          height: _headHeight,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.only(left: 4),
              child: Text(
                'WHAT YOU GET',
                style: TextStyle(
                  color: YakkuPalette.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ),
        ),
        for (final feature in _features)
          Container(
            height: _rowHeight,
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: YakkuPalette.roseBorder)),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: feature.tint,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(feature.icon, size: 18, color: feature.ink),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feature.title,
                        style: const TextStyle(
                          color: YakkuPalette.textPrimary,
                          fontSize: 14,
                          height: 1.2,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (feature.subtitle != null)
                        Text(
                          feature.subtitle!,
                          style: const TextStyle(
                            color: YakkuPalette.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _column(YakkuPlanChoice plan, int index) {
    final selected = plan == picked;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: selected ? 1 : 0),
      decoration: BoxDecoration(
        color: selected ? _YakkuPlansSheetState._night : null,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          SizedBox(
            height: _headHeight,
            child: Center(
              child: Text(
                plan.short,
                style: TextStyle(
                  color: selected
                      ? YakkuPalette.Gold
                      : YakkuPalette.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          for (final feature in _features)
            Container(
              height: _rowHeight,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: selected
                        ? const Color(0x33FFFFFF)
                        : YakkuPalette.roseBorder,
                  ),
                ),
              ),
              child: _value(feature, feature.values[index], selected),
            ),
        ],
      ),
    );
  }

  Widget _value(
    _Feature feature,
    ({String? main, String? note}) value,
    bool selected,
  ) {
    final main = value.main;
    if (main == null) {
      return Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? YakkuPalette.Gold : feature.tint,
        ),
        child: Icon(
          Icons.check_rounded,
          size: 18,
          color: selected ? _YakkuPlansSheetState._night : feature.ink,
        ),
      );
    }
    final big = main.length > 6;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          main,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected
                ? YakkuPalette.Gold
                : (feature.title == 'Cards'
                      ? YakkuPalette.forestGreen
                      : YakkuPalette.textPrimary),
            fontSize: big ? 12 : 14,
            height: 1.2,
            fontWeight: FontWeight.w900,
          ),
        ),
        if (value.note != null)
          Text(
            value.note!,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? YakkuPalette.white : YakkuPalette.textSecondary,
              fontSize: 10,
              height: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
  }
}
