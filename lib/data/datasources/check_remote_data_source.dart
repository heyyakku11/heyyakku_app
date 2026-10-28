import 'package:yakku/data/models/checks/check_response.dart';
import 'package:yakku/data/models/checks/make_check_request.dart';
import 'package:yakku/data/models/checks/user_check_response.dart';

abstract class CheckRemoteDataSource {
  /// Active checks for the current week (public).
  Future<List<CheckResponse>> getChecks();

  /// Makes a check with the caller's own answer (login required).
  Future<UserCheckResponse> makeCheck(MakeCheckRequest request);

  /// The caller's made checks (login required).
  Future<List<UserCheckResponse>> getMyChecks();

  /// Closes one of the caller's made checks so it stops taking answers.
  Future<void> closeMyCheck(String id);

  /// Permanently deletes one of the caller's made checks.
  Future<void> deleteMyCheck(String id);
}
