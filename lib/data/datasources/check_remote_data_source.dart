import 'package:yakku/data/models/checks/check_response.dart';
import 'package:yakku/data/models/checks/make_check_request.dart';
import 'package:yakku/data/models/checks/user_check_response.dart';
import 'package:yakku/data/models/poll/poll_reason.dart';

abstract class CheckRemoteDataSource {
  /// Active checks for the current week (public).
  Future<List<CheckResponse>> getChecks();

  /// Active just-for-fun cards (public). They have no live or expiry date.
  Future<List<CheckResponse>> getFunCards();

  /// Makes a check, or a just-for-fun card when [MakeCheckRequest.fun], with the caller's own answer (login required).
  Future<UserCheckResponse> makeCheck(MakeCheckRequest request);

  /// The caller's made checks (login required).
  Future<List<UserCheckResponse>> getMyChecks();

  /// Closes one of the caller's made checks so it stops taking answers.
  Future<void> closeMyCheck(String id);

  /// Permanently deletes one of the caller's made checks.
  Future<void> deleteMyCheck(String id);

  /// The reasons voters gave for one option of the caller's made check.
  Future<List<PollReason>> getCheckOptionReasons(String id, String optionId);

  /// The custom answers voters wrote in on the caller's made check, with reasons.
  Future<List<PollCustomAnswer>> getCheckCustomAnswers(String id);

  /// Reports a reason as abuse: it is removed and logged.
  Future<ReasonReportResult> reportCheckReason(String id, String reasonId);
}
