import 'package:yakku/domain/entities/poll_option.dart';
import 'package:yakku/domain/enums/poll_status.dart';

class Poll {
  const Poll({
    required this.id,
    required this.creatorId,
    required this.question,
    required this.options,
    required this.createdAt,
    this.status = PollStatus.active,
    this.expiresAt,
    this.allowMultipleAnswers = false,
    this.isAnonymous = true,
    this.selectedOptionIds = const {},
  });

  final String id;
  final String creatorId;
  final String question;
  final List<PollOption> options;
  final PollStatus status;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final bool allowMultipleAnswers;
  final bool isAnonymous;
  final Set<String> selectedOptionIds;

  int get totalVotes =>
      options.fold(0, (sum, option) => sum + option.voteCount);

  bool get hasVoted => selectedOptionIds.isNotEmpty;

  int percentageFor(PollOption option) {
    if (totalVotes == 0) return 0;
    return ((option.voteCount / totalVotes) * 100).round();
  }

  Poll copyWith({
    String? id,
    String? creatorId,
    String? question,
    List<PollOption>? options,
    PollStatus? status,
    DateTime? expiresAt,
    DateTime? createdAt,
    bool? allowMultipleAnswers,
    bool? isAnonymous,
    Set<String>? selectedOptionIds,
  }) {
    return Poll(
      id: id ?? this.id,
      creatorId: creatorId ?? this.creatorId,
      question: question ?? this.question,
      options: options ?? this.options,
      status: status ?? this.status,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
      allowMultipleAnswers: allowMultipleAnswers ?? this.allowMultipleAnswers,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      selectedOptionIds: selectedOptionIds ?? this.selectedOptionIds,
    );
  }
}
