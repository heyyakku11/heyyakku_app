import 'package:flutter/material.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/data/models/poll/poll_reason.dart';
import 'package:yakku/presentation/widgets/ask_back_button.dart';

/// Every anonymous reason voters gave for one option of a card (owner view).
///
/// Opened by tapping an option row on the results screen, only when that
/// option has at least one reason.
class OptionReasonsScreen extends StatefulWidget {
  const OptionReasonsScreen({
    super.key,
    required this.label,
    required this.percent,
    required this.fraction,
    required this.votes,
    required this.count,
    required this.loadReasons,
    required this.onReport,
  });

  final String label;
  final int percent;
  final double fraction;

  /// Everyone who picked this option, with or without a reason.
  final int votes;

  /// Reasons the results screen knew about when it opened this screen.
  final int count;
  final Future<PollReasonList> Function() loadReasons;

  /// Asks why and reports a reason. Returns the report, or null when the owner
  /// backed out or it failed.
  final Future<ReasonReportResult?> Function(String reasonId) onReport;

  @override
  State<OptionReasonsScreen> createState() => _OptionReasonsScreenState();
}

class _OptionReasonsScreenState extends State<OptionReasonsScreen> {
  bool _loading = true;
  bool _failed = false;
  List<PollReason> _reasons = const [];

  /// Reasons an admin blocked after a report; their text is never sent.
  int _blocked = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final list = await widget.loadReasons();
      if (!mounted) return;
      setState(() {
        _reasons = list.items;
        _blocked = list.blockedCount;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  Future<void> _report(PollReason reason) async {
    final result = await widget.onReport(reason.id);
    if (result == null || !mounted) return;
    // The reason stays on screen, marked as reported, until an admin decides.
    setState(() {
      _reasons = [
        for (final item in _reasons)
          item.id == reason.id
              ? item.copyWith(reportState: result.state)
              : item,
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    // Voters who picked this option and wrote nothing. A blocked reason has
    // no text left, so it would look like one of them; it is counted apart.
    final withoutReason = widget.votes - widget.count - _blocked;
    return _DetailScaffold(
      palette: _DetailPalette.reasons,
      headline: '\u201C${widget.label}\u201D',
      percent: widget.percent,
      fraction: widget.fraction,
      panelIcon: Icons.chat_bubble_outline_rounded,
      panelTitle: 'Anonymous reasons',
      panelCount: widget.count,
      loading: _loading,
      failed: _failed,
      onRetry: _load,
      failedMessage: "Couldn't load the reasons.",
      emptyMessage: 'No reasons to show.',
      isEmpty: _reasons.isEmpty,
      withoutReason: withoutReason > 0
          ? (withoutReason == 1
                ? '1 friend picked this without a reason'
                : '$withoutReason friends picked this without a reason')
          : null,
      removed: _blocked,
      children: [
        for (final reason in _reasons)
          _ReasonCard(reason: reason, onReport: () => _report(reason)),
      ],
    );
  }
}

/// Every answer voters wrote in as their own option ("Something else"), each
/// with the reason they gave, if any (owner view).
class CustomAnswersScreen extends StatefulWidget {
  const CustomAnswersScreen({
    super.key,
    required this.percent,
    required this.fraction,
    required this.count,
    required this.loadAnswers,
    required this.onReport,
  });

  final int percent;
  final double fraction;
  final int count;
  final Future<PollCustomAnswerList> Function() loadAnswers;

  /// Asks why and reports an answer's reason. Returns the report, or null when
  /// the owner backed out or it failed.
  final Future<ReasonReportResult?> Function(String reasonId) onReport;

  @override
  State<CustomAnswersScreen> createState() => _CustomAnswersScreenState();
}

class _CustomAnswersScreenState extends State<CustomAnswersScreen> {
  bool _loading = true;
  bool _failed = false;
  List<PollCustomAnswer> _answers = const [];

  /// Reasons an admin blocked after a report; their text is never sent.
  int _blocked = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final list = await widget.loadAnswers();
      if (!mounted) return;
      setState(() {
        _answers = list.items;
        _blocked = list.blockedCount;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  Future<void> _report(PollCustomAnswer answer) async {
    final result = await widget.onReport(answer.id);
    if (result == null || !mounted) return;
    // The reason stays on screen, marked as reported, until an admin decides.
    setState(() {
      _answers = [
        for (final item in _answers)
          item.id == answer.id
              ? item.copyWith(reportState: result.state)
              : item,
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return _DetailScaffold(
      palette: _DetailPalette.custom,
      headline: 'Something else.',
      percent: widget.percent,
      fraction: widget.fraction,
      panelIcon: Icons.edit_outlined,
      panelTitle: 'Options others added',
      panelCount: widget.count,
      loading: _loading,
      failed: _failed,
      onRetry: _load,
      failedMessage: "Couldn't load the answers.",
      emptyMessage: 'No answers to show.',
      isEmpty: _answers.isEmpty,
      removed: _blocked,
      children: [
        for (final answer in _answers)
          _CustomAnswerCard(answer: answer, onReport: () => _report(answer)),
      ],
    );
  }
}

/// The colours of one detail screen: a reasons screen is raspberry, a
/// "Something else" screen is purple.
class _DetailPalette {
  const _DetailPalette({
    required this.header,
    required this.headerEdge,
    required this.panel,
    required this.panelBorder,
    required this.accent,
    required this.chip,
  });

  final Color header;

  /// The darker lower edge of the header, like a pressable key.
  final Color headerEdge;
  final Color panel;
  final Color panelBorder;

  /// Icon tile, count, labels and the highlighted card border.
  final Color accent;

  /// Fill of the Ask back pill.
  final Color chip;

  static const reasons = _DetailPalette(
    header: Color(0xFFD02E62),
    headerEdge: Color(0xFFA5204C),
    panel: Color(0xFFFFE6EC),
    panelBorder: Color(0xFFFBD3DF),
    accent: YakkuPalette.primary,
    chip: YakkuPalette.pillPink,
  );

  static const custom = _DetailPalette(
    header: Color(0xFF5B3FC4),
    headerEdge: Color(0xFF45309C),
    panel: Color(0xFFEFE9FF),
    panelBorder: Color(0xFFDDD2FB),
    accent: Color(0xFF5B3FC4),
    chip: Color(0xFFECE3FF),
  );
}

/// Shared layout: back arrow, a coloured "NN% said" header, then a tinted panel
/// that holds the list.
class _DetailScaffold extends StatelessWidget {
  const _DetailScaffold({
    required this.palette,
    required this.headline,
    required this.percent,
    required this.fraction,
    required this.panelIcon,
    required this.panelTitle,
    required this.panelCount,
    required this.loading,
    required this.failed,
    required this.onRetry,
    required this.failedMessage,
    required this.emptyMessage,
    required this.isEmpty,
    required this.children,
    this.withoutReason,
    this.removed = 0,
  });

  final _DetailPalette palette;
  final String headline;
  final int percent;
  final double fraction;
  final IconData panelIcon;
  final String panelTitle;
  final int panelCount;
  final bool loading;
  final bool failed;
  final VoidCallback onRetry;
  final String failedMessage;
  final String emptyMessage;
  final bool isEmpty;
  final List<Widget> children;

  /// "2 friends picked this without a reason"; null hides the pill.
  final String? withoutReason;

  /// Reasons removed for breaking the rules; 0 hides the line.
  final int removed;

  /// "Both open" for two, otherwise "All 6 open".
  String get _subtitle {
    if (panelCount <= 1) return 'Open';
    if (panelCount == 2) return 'Both open';
    return 'All $panelCount open';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YakkuPalette.cream,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 52,
              child: Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: YakkuPalette.textPrimary,
                    size: 18,
                  ),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Header(
                      palette: palette,
                      headline: headline,
                      percent: percent,
                      fraction: fraction,
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
                      decoration: BoxDecoration(
                        color: palette.panel,
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(color: palette.panelBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _PanelHeader(
                            palette: palette,
                            icon: panelIcon,
                            title: panelTitle,
                            subtitle: _subtitle,
                            count: panelCount,
                          ),
                          const SizedBox(height: 12),
                          ..._body(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _body() {
    if (loading) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 28),
          child: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ),
        ),
      ];
    }
    if (failed) {
      return [
        Center(
          child: Column(
            children: [
              Text(
                failedMessage,
                style: const TextStyle(
                  color: YakkuPalette.textSecondary,
                  fontSize: 13,
                ),
              ),
              TextButton(onPressed: onRetry, child: const Text('Try again')),
            ],
          ),
        ),
      ];
    }
    return [
      if (isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Center(
            child: Text(
              emptyMessage,
              style: const TextStyle(
                color: YakkuPalette.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
        )
      else
        for (final child in children) ...[child, const SizedBox(height: 10)],
      if (withoutReason != null)
        _DashedBox(
          color: palette.accent.withValues(alpha: 0.35),
          radius: 14,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                const Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 14,
                  color: YakkuPalette.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    withoutReason!,
                    style: const TextStyle(
                      color: YakkuPalette.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      if (removed > 0)
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 10, 4, 2),
          child: Text(
            removed == 1
                ? '1 reason removed for breaking the rules'
                : '$removed reasons removed for breaking the rules',
            style: const TextStyle(
              color: YakkuPalette.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
    ];
  }
}

/// "31% said" with the option's text underneath and a share bar, on a card
/// with a darker lower edge.
class _Header extends StatelessWidget {
  const _Header({
    required this.palette,
    required this.headline,
    required this.percent,
    required this.fraction,
  });

  final _DetailPalette palette;
  final String headline;
  final int percent;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 5),
      decoration: BoxDecoration(
        color: palette.headerEdge,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        decoration: BoxDecoration(
          color: palette.header,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(
                text: '$percent%',
                children: const [
                  TextSpan(
                    text: ' said',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              style: const TextStyle(
                color: YakkuPalette.white,
                fontSize: 40,
                height: 1,
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              headline,
              style: const TextStyle(
                color: YakkuPalette.white,
                fontSize: 22,
                height: 1.15,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: LinearProgressIndicator(
                value: fraction.clamp(0.0, 1.0),
                minHeight: 7,
                backgroundColor: YakkuPalette.white.withValues(alpha: 0.25),
                color: YakkuPalette.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({
    required this.palette,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.count,
  });

  final _DetailPalette palette;
  final IconData icon;
  final String title;
  final String subtitle;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: palette.accent,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, size: 19, color: YakkuPalette.white),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: YakkuPalette.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  color: YakkuPalette.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Text(
            '$count',
            style: TextStyle(
              color: palette.accent,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// e.g. "28 Oct 2026 \u00B7 3:42 PM", in the viewer's local time.
String? _when(DateTime? value) {
  if (value == null) return null;
  final local = value.toLocal();
  final hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final period = local.hour >= 12 ? 'PM' : 'AM';
  return '${local.day} ${_months[local.month - 1]} ${local.year} '
      '\u00B7 $hour12:$minute $period';
}

/// The small flag at a card's lower right. Tapping it asks to report the reason.
class _FlagButton extends StatelessWidget {
  const _FlagButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      tooltip: 'Report',
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      padding: EdgeInsets.zero,
      icon: const Icon(
        Icons.flag_outlined,
        size: 18,
        color: YakkuPalette.textSecondary,
      ),
    );
  }
}

/// Grey "Reported · under review" pill that replaces the flag once a reason is
/// reported and until an admin decides.
class _ReportedPill extends StatelessWidget {
  const _ReportedPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const ShapeDecoration(
        color: Color(0xFFF1ECEE),
        shape: StadiumBorder(),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flag_outlined, size: 14, color: YakkuPalette.textSecondary),
          SizedBox(width: 6),
          Text(
            'Reported \u00B7 under review',
            style: TextStyle(
              color: YakkuPalette.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// Lower row of a card with a reason: Ask back for a registered voter,
/// "Someone you may know did not sign up" for a guest. At the end, the report
/// flag, or "Reported · under review" once it is reported. A reason an admin
/// dismissed shows neither: it cannot be reported again.
class _ReasonFooter extends StatelessWidget {
  const _ReasonFooter({
    required this.voteId,
    required this.canAskBack,
    required this.state,
    required this.palette,
    required this.onReport,
  });

  final String voteId;
  final bool canAskBack;
  final ReasonReportState state;
  final _DetailPalette palette;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (canAskBack)
          // The reason's id is the vote's id.
          AskBackButton(
            voteId: voteId,
            background: palette.chip,
            foreground: palette.accent,
            compact: true,
          )
        else
          const Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Someone you may know did not sign up',
                style: TextStyle(
                  color: YakkuPalette.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        if (state == ReasonReportState.pending) ...[
          const SizedBox(width: 8),
          const _ReportedPill(),
          const SizedBox(width: 8),
        ],
        if (canAskBack) const Spacer(),
        if (state == ReasonReportState.none) _FlagButton(onTap: onReport),
      ],
    );
  }
}

/// One anonymous reason: the quote, then Ask back (or why there is none) and a flag.
class _ReasonCard extends StatelessWidget {
  const _ReasonCard({required this.reason, required this.onReport});

  final PollReason reason;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    final when = _when(reason.createdAt);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 6, 6),
      decoration: BoxDecoration(
        color: YakkuPalette.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              reason.text,
              style: const TextStyle(
                color: YakkuPalette.textPrimary,
                fontSize: 15,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (when != null) ...[
            const SizedBox(height: 4),
            Text(
              when,
              style: const TextStyle(
                color: YakkuPalette.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 8),
          _ReasonFooter(
            voteId: reason.id,
            canAskBack: reason.canAskBack,
            state: reason.reportState,
            palette: _DetailPalette.reasons,
            onReport: onReport,
          ),
        ],
      ),
    );
  }
}

/// One written-in answer: the answer as a title, then either the reason given
/// (with Ask back, or why there is none) or "No reason added". A card with a
/// reason has the accent border.
class _CustomAnswerCard extends StatelessWidget {
  const _CustomAnswerCard({required this.answer, required this.onReport});

  final PollCustomAnswer answer;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    const palette = _DetailPalette.custom;
    final when = _when(answer.createdAt);
    final reason = answer.reason;
    final hasReason = reason != null;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 6, 6),
      decoration: BoxDecoration(
        color: YakkuPalette.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: hasReason ? palette.accent : palette.panelBorder,
          width: hasReason ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              answer.answer,
              style: const TextStyle(
                color: YakkuPalette.textPrimary,
                fontSize: 20,
                height: 1.2,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.4,
              ),
            ),
          ),
          const SizedBox(height: 10),
          const _DottedLine(),
          const SizedBox(height: 10),
          if (hasReason) ...[
            Text(
              'THEIR REASON',
              style: TextStyle(
                color: palette.accent,
                fontSize: 11,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                reason,
                style: const TextStyle(
                  color: YakkuPalette.textPrimary,
                  fontSize: 14,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (when != null) ...[
              const SizedBox(height: 4),
              Text(
                when,
                style: const TextStyle(
                  color: YakkuPalette.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            const SizedBox(height: 8),
            _ReasonFooter(
              voteId: answer.id,
              canAskBack: answer.canAskBack,
              state: answer.reportState,
              palette: palette,
              onReport: onReport,
            ),
          ] else ...[
            const Text(
              'No reason added',
              style: TextStyle(
                color: YakkuPalette.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (when != null) ...[
              const SizedBox(height: 4),
              Text(
                when,
                style: const TextStyle(
                  color: YakkuPalette.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

/// A thin dotted divider.
class _DottedLine extends StatelessWidget {
  const _DottedLine();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1,
      width: double.infinity,
      child: CustomPaint(
        painter: _DashPainter(
          color: YakkuPalette.textSecondary.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}

class _DashPainter extends CustomPainter {
  const _DashPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 4) {
      canvas.drawLine(Offset(x, 0.5), Offset(x + 2, 0.5), paint);
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => old.color != color;
}

/// A rounded box with a dashed outline.
class _DashedBox extends StatelessWidget {
  const _DashedBox({
    required this.color,
    required this.radius,
    required this.child,
  });

  final Color color;
  final double radius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _DashedBorderPainter(color: color, radius: radius),
      child: child,
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(radius),
        ).deflate(0.6),
      );
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + 5), paint);
        distance += 9;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color || old.radius != radius;
}
