import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:yakku/core/constants/app_limits.dart';
import 'package:yakku/core/share/share_payload.dart';
import 'package:yakku/core/share/share_platform_adapter.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/presentation/screens/share/share_destinations.dart';

/// Shown after the user opens Instagram to post the card to their Story:
/// confirms it was sent, says when it closes and when results show, and offers
/// the other ways to share. "Done" goes back to the feed.
class StorySharedScreen extends StatefulWidget {
  const StorySharedScreen({
    super.key,
    required this.buildPayload,
    this.minVotes = AppLimits.minVotesToReveal,
    this.closesIn = const Duration(hours: 24),
  });

  /// Builds what the other destinations share.
  final SharePayload Function() buildPayload;

  /// Votes needed before results show.
  final int minVotes;

  /// How long the card stays open for votes.
  final Duration closesIn;

  @override
  State<StorySharedScreen> createState() => _StorySharedScreenState();
}

class _StorySharedScreenState extends State<StorySharedScreen> {
  static const _green = Color(0xFF1F5A3A);
  static const _greenTint = Color(0xFFDDF3E4);

  SharePlatformAdapter? _busy;

  int get _votes => widget.minVotes > 0
      ? widget.minVotes
      : AppLimits.minVotesToReveal;

  String get _closesLabel {
    final hours = widget.closesIn.inHours;
    return hours >= 1 ? '${hours}h' : '${widget.closesIn.inMinutes}m';
  }

  String get _closesText {
    final hours = widget.closesIn.inHours;
    if (hours >= 1) return 'Closes in $hours ${hours == 1 ? 'hour' : 'hours'}';
    final minutes = widget.closesIn.inMinutes;
    return 'Closes in $minutes ${minutes == 1 ? 'minute' : 'minutes'}';
  }

  Future<void> _share(SharePlatformAdapter adapter) async {
    if (_busy != null) return;
    setState(() => _busy = adapter);
    try {
      await runShare(adapter, widget.buildPayload);
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  void _done() => Navigator.of(context).popUntil((route) => route.isFirst);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YakkuPalette.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 36, 22, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 66,
                height: 66,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _greenTint,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const FaIcon(
                  FontAwesomeIcons.check,
                  size: 22,
                  color: _green,
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'Sent. Votes are on the way.',
                style: TextStyle(
                  color: YakkuPalette.Ink,
                  fontSize: 38,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.4,
                ),
              ),
              const SizedBox(height: 20),
              _ClosesCard(
                label: _closesLabel,
                title: _closesText,
                body: 'Keep sharing. Results show only after $_votes votes.',
              ),
              const SizedBox(height: 14),
              const _SharedRow(label: 'Instagram Story'),
              const SizedBox(height: 28),
              const Center(
                child: Text(
                  'Share with more friends',
                  style: TextStyle(
                    color: YakkuPalette.Ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ShareDestinationRow(
                busy: _busy,
                onTap: _busy == null ? _share : null,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 58,
                child: FilledButton(
                  onPressed: _done,
                  style: FilledButton.styleFrom(
                    backgroundColor: YakkuPalette.Raspberry,
                    foregroundColor: YakkuPalette.white,
                    shape: const StadiumBorder(),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The dark card: a gold "24h" ring, when the card closes, and the vote note.
class _ClosesCard extends StatelessWidget {
  const _ClosesCard({
    required this.label,
    required this.title,
    required this.body,
  });

  final String label;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: YakkuPalette.Ink,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: YakkuPalette.Gold, width: 3),
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: YakkuPalette.Gold,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: YakkuPalette.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  body,
                  style: TextStyle(
                    color: YakkuPalette.white.withValues(alpha: 0.75),
                    fontSize: 12.5,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "✓ Instagram Story  [Shared]"
class _SharedRow extends StatelessWidget {
  const _SharedRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
      decoration: BoxDecoration(
        color: YakkuPalette.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: YakkuPalette.roseBorder),
      ),
      child: Row(
        children: [
          const FaIcon(
            FontAwesomeIcons.check,
            size: 13,
            color: _StorySharedScreenState._green,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: YakkuPalette.Ink,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _StorySharedScreenState._greenTint,
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'Shared',
              style: TextStyle(
                color: _StorySharedScreenState._green,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
