import 'card.dart';

/// A column (lane) within a board.
class FlexiBoardColumn<T> {
  const FlexiBoardColumn({
    required this.id,
    required this.title,
    this.cards = const [],
    this.wipLimit,
    this.color,
  });

  final String id;
  final String title;
  final List<FlexiBoardCard<T>> cards;

  /// When set, dropping into this column is rejected if at/over capacity
  /// (unless policies disable WIP checks).
  final int? wipLimit;

  /// Optional accent used by default UI.
  final int? color;

  int get cardCount => cards.length;

  bool get isOverWipLimit {
    final limit = wipLimit;
    if (limit == null) return false;
    return cards.length > limit;
  }

  bool get isAtWipLimit {
    final limit = wipLimit;
    if (limit == null) return false;
    return cards.length >= limit;
  }

  FlexiBoardColumn<T> copyWith({
    String? id,
    String? title,
    List<FlexiBoardCard<T>>? cards,
    int? wipLimit,
    int? color,
    bool clearWipLimit = false,
  }) {
    return FlexiBoardColumn<T>(
      id: id ?? this.id,
      title: title ?? this.title,
      cards: cards ?? this.cards,
      wipLimit: clearWipLimit ? null : (wipLimit ?? this.wipLimit),
      color: color ?? this.color,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is FlexiBoardColumn<T> &&
        other.id == id &&
        other.title == title &&
        other.wipLimit == wipLimit &&
        other.color == color &&
        _listEquals(other.cards, cards);
  }

  @override
  int get hashCode => Object.hash(
        id,
        title,
        wipLimit,
        color,
        Object.hashAll(cards),
      );
}

bool _listEquals<E>(List<E> a, List<E> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
