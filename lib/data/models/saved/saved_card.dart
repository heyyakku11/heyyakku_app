import 'package:yakku/data/models/checks/check_response.dart';
import 'package:yakku/data/models/poll/poll_response.dart';

/// Which kind of card a saved card is, as the API writes it.
enum SavedCardType {
  poll('poll'),
  funCard('fun_card');

  const SavedCardType(this.apiValue);

  /// The value used in the saved-cards routes and responses.
  final String apiValue;

  static SavedCardType? fromApi(String? value) {
    for (final type in values) {
      if (type.apiValue == value) return type;
    }
    return null;
  }
}

/// One entry of `GET /api/v1/saved-cards`: a saved poll or a saved fun card. [type] says which of [poll] and
/// [funCard] is filled.
class SavedCardItem {
  const SavedCardItem({
    required this.type,
    required this.cardId,
    this.savedAt,
    this.poll,
    this.funCard,
  });

  final SavedCardType type;
  final String cardId;
  final DateTime? savedAt;
  final PollResponse? poll;
  final CheckResponse? funCard;

  /// Null for an entry of a kind this app version does not know, or without its card.
  static SavedCardItem? tryParse(Map<String, dynamic> json) {
    final type = SavedCardType.fromApi(json['cardType']?.toString());
    if (type == null) return null;
    final rawPoll = json['poll'];
    final rawFun = json['funCard'];
    final poll = type == SavedCardType.poll && rawPoll is Map
        ? PollResponse.fromJson(Map<String, dynamic>.from(rawPoll))
        : null;
    final fun = type == SavedCardType.funCard && rawFun is Map
        ? CheckResponse.fromJson(Map<String, dynamic>.from(rawFun))
        : null;
    if (poll == null && fun == null) return null;
    return SavedCardItem(
      type: type,
      cardId: json['cardId']?.toString() ?? '',
      savedAt: DateTime.tryParse(json['savedAt']?.toString() ?? ''),
      poll: poll,
      funCard: fun,
    );
  }
}

/// One page of the saved cards, polls and fun cards together, newest saved first.
class SavedCardsPage {
  const SavedCardsPage({
    required this.items,
    this.nextCursor,
    this.hasMore = false,
  });

  final List<SavedCardItem> items;
  final String? nextCursor;
  final bool hasMore;
}
