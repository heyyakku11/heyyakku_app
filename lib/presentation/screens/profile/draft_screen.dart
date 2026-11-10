import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/data/models/poll/draft_poll.dart';
import 'package:yakku/presentation/app_scope.dart';
import 'package:yakku/presentation/screens/profile/draft_detail_screen.dart';
import 'package:yakku/presentation/screens/profile/draft_progress.dart';
import 'package:yakku/presentation/widgets/guess_flow_widgets.dart';

/// Cards the user started but has not shared yet, newest first. Each shows how
/// far along it is and what the next step is; tapping one opens its details.
class DraftScreen extends StatelessWidget {
  const DraftScreen({super.key});

  static const draftColor = Color(0xFFEAF6C6);

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context).draftPolls;

    return Scaffold(
      backgroundColor: YakkuPalette.cream,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: store,
          builder: (context, _) {
            final drafts = store.drafts;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  tooltip: 'Back',
                  icon: const FaIcon(
                    FontAwesomeIcons.chevronLeft,
                    size: 16,
                    color: YakkuPalette.Ink,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 6),
                  child: Text(
                    'Drafts',
                    style: TextStyle(
                      color: YakkuPalette.Ink,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 14),
                  child: Text(
                    'Cards you started but haven’t shared yet. Pick up '
                    'where you left off.',
                    style: TextStyle(
                      color: YakkuPalette.textSecondary,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ),
                Expanded(
                  child: !store.isReady
                      ? const Center(child: CircularProgressIndicator())
                      : drafts.isEmpty
                      ? const Center(
                          child: Text(
                            'No drafts',
                            style: TextStyle(color: YakkuPalette.textSecondary),
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          children: [
                            for (final draft in drafts) ...[
                              _DraftTile(
                                draft: draft,
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        DraftDetailScreen(draftId: draft.id),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                            ],
                            const SizedBox(height: 4),
                            const Center(
                              child: Text(
                                'Close a card before sharing and it’s saved here.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: YakkuPalette.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DraftTile extends StatelessWidget {
  const _DraftTile({required this.draft, required this.onTap});

  final DraftPoll draft;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final progress = DraftProgress(draft);
    final question = progress.hasQuestion ? progress.question : 'Untitled draft';

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: CustomPaint(
        foregroundPainter: DashedBorderPainter(
          color: YakkuPalette.Ink,
          radius: 18,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: DraftScreen.draftColor,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'YOUR QUESTION',
                    style: TextStyle(
                      color: Color(0xFF4C6B1D),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    progress.ago,
                    style: const TextStyle(
                      color: YakkuPalette.textSecondary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                question,
                style: const TextStyle(
                  color: YakkuPalette.Ink,
                  fontSize: 19,
                  height: 1.15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  for (var i = 0; i < 3; i++) ...[
                    Container(
                      width: 22,
                      height: 5,
                      decoration: BoxDecoration(
                        color: i < progress.stepsDone
                            ? YakkuPalette.Ink
                            : YakkuPalette.Ink.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Next: ${progress.nextStep}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: YakkuPalette.Ink,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
