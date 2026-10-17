import 'package:flutter/material.dart';
import 'package:yakku/core/theme/yakku_palette.dart';
import 'package:yakku/core/utils/hex_color.dart';
import 'package:yakku/data/models/checks/user_check_response.dart';

/// Results of a check the user made: votes per option and custom answers.
class CheckResultsScreen extends StatelessWidget {
  const CheckResultsScreen({super.key, required this.userCheck});

  final UserCheckResponse userCheck;

  static const _ink = Color(0xFF21191D);

  @override
  Widget build(BuildContext context) {
    final background = parseHexColor(
      userCheck.backgroundColor,
      fallback: YakkuPalette.cream,
    );
    final total = userCheck.totalVotes ?? 0;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        foregroundColor: _ink,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        children: [
          Text(
            userCheck.title,
            style: const TextStyle(
              color: _ink,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            userCheck.question,
            style: const TextStyle(
              color: _ink,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            total == 1 ? '1 answer' : '$total answers',
            style: const TextStyle(color: _ink),
          ),
          const SizedBox(height: 20),
          for (final option in userCheck.options) ...[
            _ResultBar(
              label: option.text,
              votes: option.votes ?? 0,
              total: total,
              mine: option.id == userCheck.myVoteOptionId,
            ),
            const SizedBox(height: 10),
          ],
          if ((userCheck.customAnswerVotes ?? 0) > 0)
            _ResultBar(
              label: 'Friends added their own',
              votes: userCheck.customAnswerVotes!,
              total: total,
              mine: false,
            ),
          if (userCheck.myCustomAnswer != null) ...[
            const SizedBox(height: 16),
            Text(
              'Your answer: ${userCheck.myCustomAnswer}',
              style: const TextStyle(color: _ink, fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }
}

class _ResultBar extends StatelessWidget {
  const _ResultBar({
    required this.label,
    required this.votes,
    required this.total,
    required this.mine,
  });

  final String label;
  final int votes;
  final int total;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final fraction = total == 0 ? 0.0 : votes / total;
    final percent = (fraction * 100).round();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: mine
            ? Border.all(color: YakkuPalette.primary, width: 1.5)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: CheckResultsScreen._ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '$percent%',
                style: const TextStyle(
                  color: CheckResultsScreen._ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 6,
              color: YakkuPalette.primary,
              backgroundColor: const Color(0xFFF1E7EA),
            ),
          ),
        ],
      ),
    );
  }
}
