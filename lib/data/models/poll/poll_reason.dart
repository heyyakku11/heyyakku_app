import 'package:yakku/data/models/auth/api_response.dart';

/// Reads the reasons list out of a reasons response body.
List<PollReason> parseReasons(Map<String, dynamic>? body) {
  if (body == null) throw StateError('Empty reasons response');
  final apiResponse = ApiResponse<List<PollReason>>.fromJson(body, (json) {
    if (json is! List) return <PollReason>[];
    return [
      for (final item in json.whereType<Map>())
        PollReason.fromJson(Map<String, dynamic>.from(item)),
    ];
  });
  if (!apiResponse.success) {
    throw StateError(apiResponse.message ?? 'Could not load the reasons');
  }
  return apiResponse.data ?? const <PollReason>[];
}

/// A custom answer a voter wrote in ("their own option"), with their reason if any.
class PollCustomAnswer {
  const PollCustomAnswer({
    required this.id,
    required this.answer,
    this.reason,
    this.createdAt,
  });

  /// The vote id; also the id to report when [reason] is set.
  final String id;
  final String answer;
  final String? reason;
  final DateTime? createdAt;

  PollCustomAnswer withoutReason() =>
      PollCustomAnswer(id: id, answer: answer, createdAt: createdAt);

  factory PollCustomAnswer.fromJson(Map<String, dynamic> json) {
    final created = json['createdAt'];
    final reason = json['reason']?.toString();
    return PollCustomAnswer(
      id: json['id']?.toString() ?? '',
      answer: json['answer']?.toString() ?? '',
      reason: reason == null || reason.trim().isEmpty ? null : reason,
      createdAt: created is String ? DateTime.tryParse(created) : null,
    );
  }
}

/// Reads the custom answers list out of a response body.
List<PollCustomAnswer> parseCustomAnswers(Map<String, dynamic>? body) {
  if (body == null) throw StateError('Empty custom answers response');
  final apiResponse = ApiResponse<List<PollCustomAnswer>>.fromJson(body, (
    json,
  ) {
    if (json is! List) return <PollCustomAnswer>[];
    return [
      for (final item in json.whereType<Map>())
        PollCustomAnswer.fromJson(Map<String, dynamic>.from(item)),
    ];
  });
  if (!apiResponse.success) {
    throw StateError(apiResponse.message ?? 'Could not load the answers');
  }
  return apiResponse.data ?? const <PollCustomAnswer>[];
}

/// What a report returns: the reason counts as they are now.
class ReasonReportResult {
  const ReasonReportResult({
    required this.optionWhyCount,
    required this.totalWhyCount,
  });

  /// Reasons still counted for the option the reported reason belonged to.
  final int optionWhyCount;
  final int totalWhyCount;
}

/// Reads the report response body.
ReasonReportResult parseReportResult(Map<String, dynamic>? body) {
  if (body == null) throw StateError('Empty report response');
  final apiResponse = ApiResponse<ReasonReportResult>.fromJson(body, (json) {
    final map = json is Map ? Map<String, dynamic>.from(json) : const {};
    int asInt(Object? v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;
    return ReasonReportResult(
      optionWhyCount: asInt(map['optionWhyCount']),
      totalWhyCount: asInt(map['totalWhyCount']),
    );
  });
  final data = apiResponse.data;
  if (!apiResponse.success || data == null) {
    throw StateError(apiResponse.message ?? 'Could not report this reason');
  }
  return data;
}

/// One anonymous reason a voter gave for an option (owner view).
class PollReason {
  const PollReason({required this.id, required this.text, this.createdAt});

  final String id;
  final String text;
  final DateTime? createdAt;

  factory PollReason.fromJson(Map<String, dynamic> json) {
    final created = json['createdAt'];
    return PollReason(
      id: json['id']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      createdAt: created is String ? DateTime.tryParse(created) : null,
    );
  }
}
