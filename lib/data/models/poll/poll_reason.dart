import 'package:yakku/data/models/auth/api_response.dart';

/// Where a reason stands with moderation, as the owner sees it.
enum ReasonReportState {
  /// Never reported.
  none,

  /// Reported and waiting for an admin. Still shown, flagged.
  pending,

  /// An admin dismissed the report. Shown as normal; it cannot be reported again.
  rejected;

  static ReasonReportState parse(Object? value) {
    switch ('$value'.toLowerCase()) {
      case 'pending':
        return ReasonReportState.pending;
      case 'rejected':
        return ReasonReportState.rejected;
    }
    return ReasonReportState.none;
  }
}

/// The longest reason text the API accepts with a report.
const int reasonReportMaxLength = 300;

/// The reasons for one option, plus how many an admin blocked after a report.
class PollReasonList {
  const PollReasonList({required this.items, this.blockedCount = 0});

  /// Reasons still visible. A reported one waiting for an admin is included, flagged.
  final List<PollReason> items;

  /// Reasons an admin approved a report on. Their text is never sent.
  final int blockedCount;
}

/// The custom answers, plus how many reasons on them an admin blocked.
class PollCustomAnswerList {
  const PollCustomAnswerList({required this.items, this.blockedCount = 0});

  final List<PollCustomAnswer> items;
  final int blockedCount;
}

int _asInt(Object? v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;

/// Reads the reasons out of a reasons response body.
PollReasonList parseReasons(Map<String, dynamic>? body) {
  if (body == null) throw StateError('Empty reasons response');
  final apiResponse = ApiResponse<PollReasonList>.fromJson(body, (json) {
    final map = json is Map ? Map<String, dynamic>.from(json) : const {};
    final items = map['items'];
    return PollReasonList(
      items: [
        if (items is List)
          for (final item in items.whereType<Map>())
            PollReason.fromJson(Map<String, dynamic>.from(item)),
      ],
      blockedCount: _asInt(map['blockedCount']),
    );
  });
  if (!apiResponse.success) {
    throw StateError(apiResponse.message ?? 'Could not load the reasons');
  }
  return apiResponse.data ?? const PollReasonList(items: []);
}

/// A custom answer a voter wrote in ("their own option"), with their reason if any.
class PollCustomAnswer {
  const PollCustomAnswer({
    required this.id,
    required this.answer,
    this.reason,
    this.createdAt,
    this.canAskBack = false,
    this.reportState = ReasonReportState.none,
  });

  /// The vote id; also the id to report when [reason] is set.
  final String id;
  final String answer;
  final String? reason;
  final DateTime? createdAt;

  /// Only a registered user can be chatted back to.
  final bool canAskBack;

  /// How the answer's [reason] stands with moderation.
  final ReasonReportState reportState;

  PollCustomAnswer copyWith({ReasonReportState? reportState}) =>
      PollCustomAnswer(
        id: id,
        answer: answer,
        reason: reason,
        createdAt: createdAt,
        canAskBack: canAskBack,
        reportState: reportState ?? this.reportState,
      );

  factory PollCustomAnswer.fromJson(Map<String, dynamic> json) {
    final created = json['createdAt'];
    final reason = json['reason']?.toString();
    return PollCustomAnswer(
      id: json['id']?.toString() ?? '',
      answer: json['answer']?.toString() ?? '',
      reason: reason == null || reason.trim().isEmpty ? null : reason,
      createdAt: created is String ? DateTime.tryParse(created) : null,
      canAskBack: json['canAskBack'] as bool? ?? false,
      reportState: ReasonReportState.parse(json['reasonReportStatus']),
    );
  }
}

/// Reads the custom answers out of a response body.
PollCustomAnswerList parseCustomAnswers(Map<String, dynamic>? body) {
  if (body == null) throw StateError('Empty custom answers response');
  final apiResponse = ApiResponse<PollCustomAnswerList>.fromJson(body, (json) {
    final map = json is Map ? Map<String, dynamic>.from(json) : const {};
    final items = map['items'];
    return PollCustomAnswerList(
      items: [
        if (items is List)
          for (final item in items.whereType<Map>())
            PollCustomAnswer.fromJson(Map<String, dynamic>.from(item)),
      ],
      blockedCount: _asInt(map['blockedCount']),
    );
  });
  if (!apiResponse.success) {
    throw StateError(apiResponse.message ?? 'Could not load the answers');
  }
  return apiResponse.data ?? const PollCustomAnswerList(items: []);
}

/// What a report returns: its status, and the reason counts, which a pending
/// report does not change.
class ReasonReportResult {
  const ReasonReportResult({
    required this.state,
    required this.optionWhyCount,
    required this.totalWhyCount,
  });

  /// [ReasonReportState.pending] for a new report; rejected when an admin had
  /// already dismissed this reason's report.
  final ReasonReportState state;

  /// Reasons counted for the option the reported reason belonged to.
  final int optionWhyCount;
  final int totalWhyCount;
}

/// Reads the report response body.
ReasonReportResult parseReportResult(Map<String, dynamic>? body) {
  if (body == null) throw StateError('Empty report response');
  final apiResponse = ApiResponse<ReasonReportResult>.fromJson(body, (json) {
    final map = json is Map ? Map<String, dynamic>.from(json) : const {};
    return ReasonReportResult(
      state: ReasonReportState.parse(map['status']),
      optionWhyCount: _asInt(map['optionWhyCount']),
      totalWhyCount: _asInt(map['totalWhyCount']),
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
  const PollReason({
    required this.id,
    required this.text,
    this.createdAt,
    this.canAskBack = false,
    this.reportState = ReasonReportState.none,
  });

  final String id;
  final String text;
  final DateTime? createdAt;

  /// Only a registered user can be chatted back to.
  final bool canAskBack;

  /// Pending while an admin has not decided on a report of this reason.
  final ReasonReportState reportState;

  PollReason copyWith({ReasonReportState? reportState}) => PollReason(
    id: id,
    text: text,
    createdAt: createdAt,
    canAskBack: canAskBack,
    reportState: reportState ?? this.reportState,
  );

  factory PollReason.fromJson(Map<String, dynamic> json) {
    final created = json['createdAt'];
    return PollReason(
      id: json['id']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      createdAt: created is String ? DateTime.tryParse(created) : null,
      canAskBack: json['canAskBack'] as bool? ?? false,
      reportState: ReasonReportState.parse(json['reportStatus']),
    );
  }
}
