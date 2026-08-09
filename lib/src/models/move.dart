import 'card.dart';

/// Describes a completed (or proposed) card move within or across boards.
class FlexiBoardMove<T> {
  const FlexiBoardMove({
    required this.card,
    required this.fromBoardId,
    required this.toBoardId,
    required this.fromColumnId,
    required this.toColumnId,
    required this.fromIndex,
    required this.toIndex,
  });

  final FlexiBoardCard<T> card;
  final String fromBoardId;
  final String toBoardId;
  final String fromColumnId;
  final String toColumnId;
  final int fromIndex;
  final int toIndex;

  bool get isCrossBoard => fromBoardId != toBoardId;
  bool get isSameColumn =>
      fromBoardId == toBoardId && fromColumnId == toColumnId;

  @override
  bool operator ==(Object other) {
    return other is FlexiBoardMove<T> &&
        other.card == card &&
        other.fromBoardId == fromBoardId &&
        other.toBoardId == toBoardId &&
        other.fromColumnId == fromColumnId &&
        other.toColumnId == toColumnId &&
        other.fromIndex == fromIndex &&
        other.toIndex == toIndex;
  }

  @override
  int get hashCode => Object.hash(
        card,
        fromBoardId,
        toBoardId,
        fromColumnId,
        toColumnId,
        fromIndex,
        toIndex,
      );
}

/// Column reorder within a board.
class FlexiBoardColumnReorder {
  const FlexiBoardColumnReorder({
    required this.boardId,
    required this.fromIndex,
    required this.toIndex,
  });

  final String boardId;
  final int fromIndex;
  final int toIndex;
}
