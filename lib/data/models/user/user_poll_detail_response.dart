class UserPollDetailOptionResponse {
  final String id;
  final String? text;
  final String? imageId;
  final String? secureUrl;
  final int sortOrder;
  final int voteCount;
  final double percentage;

  const UserPollDetailOptionResponse({
    required this.id,
    required this.sortOrder,
    required this.voteCount,
    required this.percentage,
    this.text,
    this.imageId,
    this.secureUrl,
  });

  factory UserPollDetailOptionResponse.fromJson(Map<String, dynamic> json) {
    return UserPollDetailOptionResponse(
      id: json['id']?.toString() ?? '',
      text: json['text'] as String?,
      imageId: json['imageId']?.toString(),
      secureUrl: json['secureUrl'] as String?,
      sortOrder: _asInt(json['sortOrder']),
      voteCount: _asInt(json['voteCount']),
      percentage: _asDouble(json['percentage']),
    );
  }
}

class YouVsCrowdResponse {
  final String? yourOptionId;
  final String? yourOptionText;
  final double? yourOptionPercentage;
  final String? crowdLeadingOptionId;
  final String? crowdLeadingOptionText;
  final double? crowdLeadingPercentage;
  final bool? agreesWithCrowd;

  const YouVsCrowdResponse({
    this.yourOptionId,
    this.yourOptionText,
    this.yourOptionPercentage,
    this.crowdLeadingOptionId,
    this.crowdLeadingOptionText,
    this.crowdLeadingPercentage,
    this.agreesWithCrowd,
  });

  factory YouVsCrowdResponse.fromJson(Map<String, dynamic> json) {
    return YouVsCrowdResponse(
      yourOptionId: json['yourOptionId']?.toString(),
      yourOptionText: json['yourOptionText'] as String?,
      yourOptionPercentage: _asNullableDouble(json['yourOptionPercentage']),
      crowdLeadingOptionId: json['crowdLeadingOptionId']?.toString(),
      crowdLeadingOptionText: json['crowdLeadingOptionText'] as String?,
      crowdLeadingPercentage: _asNullableDouble(json['crowdLeadingPercentage']),
      agreesWithCrowd: json['agreesWithCrowd'] as bool?,
    );
  }
}

class UserPollDetailResponse {
  final String pollId;
  final String question;
  final String status;
  final String shareToken;
  final String optionType;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final int totalVoteCount;
  final List<UserPollDetailOptionResponse> pollOptions;
  final YouVsCrowdResponse youVsCrowd;

  const UserPollDetailResponse({
    required this.pollId,
    required this.question,
    required this.status,
    required this.shareToken,
    required this.optionType,
    required this.createdAt,
    required this.totalVoteCount,
    required this.pollOptions,
    required this.youVsCrowd,
    this.expiresAt,
  });

  factory UserPollDetailResponse.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['pollOptions'] as List<dynamic>? ?? const [];
    final rawYouVsCrowd = json['youVsCrowd'];
    return UserPollDetailResponse(
      pollId: json['pollId']?.toString() ?? '',
      question: json['question'] as String? ?? '',
      status: json['status'] as String? ?? '',
      shareToken: json['shareToken'] as String? ?? '',
      optionType: json['optionType'] as String? ?? 'text',
      expiresAt: _parseDate(json['expiresAt']),
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now().toUtc(),
      totalVoteCount: _asInt(json['totalVoteCount']),
      pollOptions: rawOptions
          .whereType<Map>()
          .map(
            (item) => UserPollDetailOptionResponse.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(growable: false),
      youVsCrowd: rawYouVsCrowd is Map
          ? YouVsCrowdResponse.fromJson(Map<String, dynamic>.from(rawYouVsCrowd))
          : const YouVsCrowdResponse(),
    );
  }
}

DateTime? _parseDate(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value);
}

int _asInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

double _asDouble(dynamic value, {double fallback = 0}) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

double? _asNullableDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}
