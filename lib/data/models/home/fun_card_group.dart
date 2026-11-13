import 'package:yakku/data/models/home/mirror_check.dart';

/// A fun card type as the home feed shows it: a heading, a preview row of cards, and the number behind "See all".
class FunCardGroup {
  const FunCardGroup({
    required this.name,
    required this.totalCount,
    required this.cards,
    this.typeId,
  });

  final String? typeId;
  final String name;

  /// All cards of this type still to make; [cards] holds a preview (at most 4).
  final int totalCount;
  final List<MirrorCheck> cards;
}
