import 'package:yakku/data/models/checks/check_response.dart';

/// One just-for-fun card type from `GET /api/v1/fun-cards/types`: a preview of its cards the caller has not
/// made yet (the API sends at most 4) and how many there are in all.
class FunCardType {
  const FunCardType({
    required this.name,
    required this.totalCount,
    required this.cards,
    this.typeId,
  });

  /// Null only for a card without a stored type; such a group has no "see all" list.
  final String? typeId;
  final String name;

  /// All cards of this type the caller can still make; [cards] may hold fewer.
  final int totalCount;
  final List<CheckResponse> cards;

  factory FunCardType.fromJson(Map<String, dynamic> json) {
    final rawCards = json['cards'] as List<dynamic>? ?? const [];
    final cards = [
      for (final card in rawCards.whereType<Map>())
        CheckResponse.fromJson(Map<String, dynamic>.from(card)),
    ];
    return FunCardType(
      typeId: json['typeId']?.toString(),
      name: json['name']?.toString() ?? '',
      totalCount: (json['totalCount'] as num?)?.toInt() ?? cards.length,
      cards: cards,
    );
  }
}
