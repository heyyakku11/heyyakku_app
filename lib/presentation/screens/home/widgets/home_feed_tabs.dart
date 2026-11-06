import 'package:flutter/material.dart';
import 'package:yakku/core/theme/yakku_palette.dart';

enum HomeFeedTab { friends, community }

/// The Yakku wordmark that stays above the Friends / Community switch.
class HomeBrandHeader extends StatelessWidget {
  const HomeBrandHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text.rich(
          TextSpan(
            text: 'Yakku',
            style: TextStyle(
              fontSize: 28,
              height: 1,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
              color: YakkuPalette.Ink,
            ),
            children: [
              TextSpan(
                text: '.',
                style: TextStyle(color: YakkuPalette.Raspberry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The two-part switch at the top of Home: Friends and Community. Community
/// carries a "soon" badge until it has content. The white pill slides between
/// the two parts with an eased animation.
class HomeFeedTabs extends StatelessWidget {
  const HomeFeedTabs({super.key, required this.value, required this.onChanged});

  static const slideDuration = Duration(milliseconds: 280);
  static const slideCurve = Curves.easeInOutCubic;

  final HomeFeedTab value;
  final ValueChanged<HomeFeedTab> onChanged;

  @override
  Widget build(BuildContext context) {
    final friends = value == HomeFeedTab.friends;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Container(
        height: 56,
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: YakkuPalette.roseBorder,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              duration: slideDuration,
              curve: slideCurve,
              alignment: friends ? Alignment.centerLeft : Alignment.centerRight,
              child: FractionallySizedBox(
                widthFactor: 0.5,
                heightFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: YakkuPalette.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A21191D),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: _Tab(
                    label: 'Friends',
                    selected: friends,
                    onTap: () => onChanged(HomeFeedTab.friends),
                  ),
                ),
                Expanded(
                  child: _Tab(
                    label: 'Community',
                    badge: 'soon',
                    selected: !friends,
                    onTap: () => onChanged(HomeFeedTab.community),
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

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final String label;
  final String? badge;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedDefaultTextStyle(
                duration: HomeFeedTabs.slideDuration,
                curve: HomeFeedTabs.slideCurve,
                style: TextStyle(
                  color: selected
                      ? YakkuPalette.Ink
                      : YakkuPalette.textSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
                child: Text(label),
              ),
              if (badge != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: YakkuPalette.Gold,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    badge!,
                    style: const TextStyle(
                      color: YakkuPalette.Ink,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Keeps a page mounted while it is off screen, so the Friends feed keeps its
/// scroll position and data when Community is open.
class KeepAlivePage extends StatefulWidget {
  const KeepAlivePage({super.key, required this.child});

  final Widget child;

  @override
  State<KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<KeepAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
