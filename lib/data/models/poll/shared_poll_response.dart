import 'package:yakku/data/models/poll/poll_option_response.dart';

class SharedPollCategoryResponse {
  final String id;
  final String name;

  const SharedPollCategoryResponse({required this.id, required this.name});

  factory SharedPollCategoryResponse.fromJson(Map<String, dynamic> json) {
    return SharedPollCategoryResponse(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
    );
  }
}

class SharedPollResponse {
  final String question;
  final String optionType;
  final List<PollOptionResponse> options;
  final SharedPollCategoryResponse? category;
  final DateTime? expiresAt;
  final String status;
  final bool isAcceptingVotes;

  const SharedPollResponse({
    required this.question,
    required this.optionType,
    required this.options,
    required this.status,
    required this.isAcceptingVotes,
    this.category,
    this.expiresAt,
  });

  factory SharedPollResponse.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'] as List<dynamic>? ?? const [];
    final rawCategory = json['category'];
    return SharedPollResponse(
      question: json['question'] as String? ?? '',
      optionType: json['optionType'] as String? ?? '',
      options: rawOptions
          .whereType<Map>()
          .map(
            (item) =>
                PollOptionResponse.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(growable: false),
      category: rawCategory is Map
          ? SharedPollCategoryResponse.fromJson(
              Map<String, dynamic>.from(rawCategory),
            )
          : null,
      expiresAt: _parseDate(json['expiresAt']),
      status: json['status'] as String? ?? '',
      isAcceptingVotes: json['isAcceptingVotes'] as bool? ?? false,
    );
  }
}

DateTime? _parseDate(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value);
}
