import 'package:yakku/data/models/poll/create_poll_option_request.dart';

class CreatePollRequest {
  final String question;
  final List<String> categoryIds;
  final String optionType;
  final List<CreatePollOptionRequest> options;
  final int selectedOptionIndex;
  final DateTime? expiresAt;
  final bool allowComments;

  const CreatePollRequest({
    required this.question,
    required this.optionType,
    required this.options,
    required this.selectedOptionIndex,
    this.categoryIds = const [],
    this.expiresAt,
    this.allowComments = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'question': question,
      if (categoryIds.isNotEmpty) 'categoryIds': categoryIds,
      'optionType': optionType,
      'options': options.map((option) => option.toJson()).toList(),
      'selectedOptionIndex': selectedOptionIndex,
      if (expiresAt != null) 'expiresAt': expiresAt!.toUtc().toIso8601String(),
      'allowComments': allowComments,
    };
  }
}
