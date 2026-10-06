import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:yakku/core/constants/api_constants.dart';
import 'package:yakku/core/constants/app_radii.dart';
import 'package:yakku/core/constants/app_spacing.dart';
import 'package:yakku/data/models/poll/poll_response.dart';
import 'package:yakku/presentation/widgets/yakku_carousel_card.dart';

class CreatedPollScreen extends StatelessWidget {
  const CreatedPollScreen({
    super.key,
    required this.poll,
    this.categories = const [],
  });

  final PollResponse poll;
  final List<String> categories;

  List<String> get _categoryLabels {
    final fromPoll = [
      for (final name in poll.categories)
        if (name.trim().isNotEmpty) name.trim(),
    ];
    if (fromPoll.isNotEmpty) return fromPoll;
    return [
      for (final name in categories)
        if (name.trim().isNotEmpty) name.trim(),
    ];
  }

  String get _publicUrl {
    final token = poll.shareToken.trim();
    if (token.isEmpty) return '';
    return ApiConstants.publicPollUrl(token);
  }

  Future<void> _copyLink(BuildContext context, String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Link copied')));
  }

  Future<void> _shareLink(BuildContext context, String url) async {
    final box = context.findRenderObject() as RenderBox?;
    final origin = box != null && box.hasSize
        ? box.localToGlobal(Offset.zero) & box.size
        : null;
    try {
      await SharePlus.instance.share(
        ShareParams(text: url, sharePositionOrigin: origin),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Could not share poll')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = _publicUrl;
    final canShare = url.isNotEmpty;
    final options = [...poll.options]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final optionTexts = [
      for (final option in options)
        if ((option.text ?? '').trim().isNotEmpty) option.text!.trim(),
    ];
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.sm),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Share poll')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final cardWidth = constraints.maxWidth;
                  const minCardHeight = 480.0;
                  final cardHeight = math.max(minCardHeight, cardWidth * 1.2);
                  return SizedBox(
                    width: cardWidth,
                    height: cardHeight,
                    child: YakkuCarouselCard(
                      question: poll.question,
                      options: optionTexts,
                      categories: _categoryLabels,
                      allowComments: poll.allowComments,
                      expiresAt: poll.expiresAt,
                      voteCount: poll.totalVoteCount,
                      showAddOption: true,
                      expandOptions: true,
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OutlinedButton.icon(
                    onPressed: canShare ? () => _copyLink(context, url) : null,
                    style: OutlinedButton.styleFrom(shape: buttonShape),
                    icon: const Icon(Icons.link),
                    label: const Text('Copy link'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  FilledButton.icon(
                    onPressed: canShare ? () => _shareLink(context, url) : null,
                    style: FilledButton.styleFrom(shape: buttonShape),
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
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
