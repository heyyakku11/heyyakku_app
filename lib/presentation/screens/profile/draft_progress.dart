import 'package:yakku/core/constants/app_limits.dart';
import 'package:yakku/data/models/poll/draft_poll.dart';

/// Where a draft is in making a card: write the question, add the options,
/// then make your own guess. A draft is saved before the guess, so that step
/// is always still to do.
class DraftProgress {
  DraftProgress(DraftPoll draft)
    : question = draft.question.trim(),
      options = [
        for (final option in draft.options)
          if (option.trim().isNotEmpty) option.trim(),
      ],
      updatedAt = draft.updatedAt;

  final String question;
  final List<String> options;
  final DateTime updatedAt;

  bool get hasQuestion => question.isNotEmpty;
  bool get hasOptions => options.length >= AppLimits.minOptions;
  int get optionsMissing => (AppLimits.minOptions - options.length).clamp(0, AppLimits.minOptions);

  /// Steps done, out of three.
  int get stepsDone => (hasQuestion ? 1 : 0) + (hasOptions ? 1 : 0);

  /// Ready for "make your guess".
  bool get readyToGuess => hasQuestion && hasOptions;

  /// What is left, shown under the card ("Next: ...").
  String get nextStep {
    if (!hasQuestion) return 'write your question';
    if (!hasOptions) {
      final n = optionsMissing;
      return 'add $n more ${n == 1 ? 'option' : 'options'}';
    }
    return 'make your guess';
  }

  /// The button that moves the draft forward.
  String get primaryLabel {
    if (!hasQuestion) return 'Write your question';
    if (!hasOptions) return 'Add options';
    return 'Make your guess';
  }

  /// "2h ago", "Yesterday", "3d ago".
  String get ago {
    final d = DateTime.now().difference(updatedAt);
    if (d.inMinutes < 1) return 'Just now';
    if (d.inHours < 1) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    if (d.inDays == 1) return 'Yesterday';
    return '${d.inDays}d ago';
  }
}
