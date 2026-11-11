/// Body of `POST /api/v1/checks/make`. Send exactly one of
/// [checkOptionId] or [customAnswer].
class MakeCheckRequest {
  const MakeCheckRequest({
    required this.checkId,
    this.checkOptionId,
    this.reason,
    this.customAnswer,
    this.fun = false,
  });

  /// True when the card is a just-for-fun card: it is made through
  /// `POST /api/v1/fun-cards/make`. Not part of the request body.
  final bool fun;

  final String checkId;
  final String? checkOptionId;
  final String? reason;
  final String? customAnswer;

  Map<String, dynamic> toJson() {
    return {
      'checkId': checkId,
      if (checkOptionId != null) 'checkOptionId': checkOptionId,
      if (reason != null) 'reason': reason,
      if (customAnswer != null) 'customAnswer': customAnswer,
    };
  }
}
