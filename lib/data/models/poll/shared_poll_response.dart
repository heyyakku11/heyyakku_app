import 'package:yakku/data/models/poll/poll_option_response.dart';

/// Placeholder model for a future share-token poll endpoint.
class SharedPollResponse {
  final String question;
  final String contentType;
  final List<PollOptionResponse> options;
  final DateTime? expiresAt;
  final String status;
  final String visibility;
  final bool isAcceptingVotes;

  const SharedPollResponse({
    required this.question,
    required this.contentType,
    required this.options,
    required this.status,
    required this.visibility,
    required this.isAcceptingVotes,
    this.expiresAt,
  });

  factory SharedPollResponse.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'] as List<dynamic>? ?? const [];
    return SharedPollResponse(
      question: json['question'] as String? ?? '',
      contentType: json['contentType'] as String? ?? 'question',
      options: rawOptions
          .whereType<Map>()
          .map(
            (item) =>
                PollOptionResponse.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(growable: false),
      expiresAt: _parseDate(json['expiresAt']),
      status: json['status'] as String? ?? '',
      visibility: json['visibility'] as String? ?? '',
      isAcceptingVotes: json['isAcceptingVotes'] as bool? ?? false,
    );
  }
}

DateTime? _parseDate(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value);
}
