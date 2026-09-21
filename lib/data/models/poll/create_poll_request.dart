import 'package:yakku/data/models/poll/create_poll_option_request.dart';

class CreatePollRequest {
  final String question;
  final String? categoryId;
  final String optionType;
  final List<CreatePollOptionRequest> options;
  final int selectedOptionIndex;
  final DateTime? expiresAt;

  const CreatePollRequest({
    required this.question,
    required this.optionType,
    required this.options,
    required this.selectedOptionIndex,
    this.categoryId,
    this.expiresAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'question': question,
      if (categoryId != null) 'categoryId': categoryId,
      'optionType': optionType,
      'options': options.map((option) => option.toJson()).toList(),
      'selectedOptionIndex': selectedOptionIndex,
      if (expiresAt != null) 'expiresAt': expiresAt!.toUtc().toIso8601String(),
    };
  }
}
