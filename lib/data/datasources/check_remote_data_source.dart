import 'package:yakku/data/models/checks/check_response.dart';
import 'package:yakku/data/models/checks/fun_card_type.dart';
import 'package:yakku/data/models/checks/make_check_request.dart';
import 'package:yakku/data/models/checks/user_check_response.dart';
import 'package:yakku/data/models/poll/poll_reason.dart';

abstract class CheckRemoteDataSource {
  /// Active checks for the current week (public).
  Future<List<CheckResponse>> getChecks();

  /// Every just-for-fun card type with a preview of its cards (at most 4 each) and the total per type (public).
  Future<List<FunCardType>> getFunCardTypes();

  /// All the cards of one type the caller has not made yet: the "see all" list (public).
  Future<List<CheckResponse>> getFunCardsOfType(String typeId);

  /// Saves a fun card to the caller's saved list (login required). Idempotent.
  Future<void> saveFunCard(String id);

  /// Removes a fun card from the caller's saved list (login required). Idempotent.
  Future<void> unsaveFunCard(String id);

  /// Makes a check, or a just-for-fun card when [MakeCheckRequest.fun], with the caller's own answer (login required).
  Future<UserCheckResponse> makeCheck(MakeCheckRequest request);

  /// The caller's made checks (login required).
  Future<List<UserCheckResponse>> getMyChecks();

  /// Closes one of the caller's made checks so it stops taking answers.
  Future<void> closeMyCheck(String id);

  /// Opens one of the caller's closed made cards again. A card made from a fun card gets 24 more hours.
  Future<void> reshareMyCheck(String id);

  /// Permanently deletes one of the caller's made checks.
  Future<void> deleteMyCheck(String id);

  /// The reasons voters gave for one option of the caller's made check.
  Future<List<PollReason>> getCheckOptionReasons(String id, String optionId);

  /// The custom answers voters wrote in on the caller's made check, with reasons.
  Future<List<PollCustomAnswer>> getCheckCustomAnswers(String id);

  /// Reports a reason as abuse: it is removed and logged.
  Future<ReasonReportResult> reportCheckReason(String id, String reasonId);
}
