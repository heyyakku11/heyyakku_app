import 'package:yakku/data/models/poll/create_poll_option_request.dart';

class CreatePollRequest {
  final String question;
  final String contentType;
  final String? visibility;
  final DateTime? expiresAt;
  final List<CreatePollOptionRequest> options;
  final String? mediaUploadSessionId;

  const CreatePollRequest({
    required this.question,
    required this.contentType,
    required this.options,
    this.visibility,
    this.expiresAt,
    this.mediaUploadSessionId,
  });

  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'contentType': contentType,
      if (visibility != null && visibility!.trim().isNotEmpty)
        'visibility': visibility!.trim(),
      if (expiresAt != null) 'expiresAt': expiresAt!.toUtc().toIso8601String(),
      'options': options.map((option) => option.toJson()).toList(),
      if (mediaUploadSessionId != null && mediaUploadSessionId!.isNotEmpty)
        'mediaUploadSessionId': mediaUploadSessionId,
    };
  }
}
