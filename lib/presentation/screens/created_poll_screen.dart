import 'dart:math' as math;

import 'package:flutter/material.dart';
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

  List<String> get _categoryLabels => [
    for (final name in categories)
      if (name.trim().isNotEmpty) name.trim(),
  ];

  @override
  Widget build(BuildContext context) {
    final options = [...poll.options]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final optionTexts = [
      for (final option in options)
        if ((option.text ?? '').trim().isNotEmpty) option.text!.trim(),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Poll created')),
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
                      expiresAt: poll.expiresAt,
                      voteCount: poll.totalVoteCount,
                      showAddOption: true,
                      expandOptions: true,
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: () => Navigator.of(context).maybePop(),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                ),
                child: const Text('Done'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
