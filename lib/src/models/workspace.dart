import 'board.dart';
import 'card.dart';
import 'column.dart';
import 'move.dart';

/// Root workspace holding one or more boards.
class BoardFlowWorkspace<T> {
  const BoardFlowWorkspace({
    required this.boards,
    this.activeBoardId,
  });

  final List<BoardFlowBoard<T>> boards;
  final String? activeBoardId;

  BoardFlowBoard<T>? boardById(String id) {
    for (final board in boards) {
      if (board.id == id) return board;
    }
    return null;
  }

  String get resolvedActiveBoardId {
    if (activeBoardId != null && boardById(activeBoardId!) != null) {
      return activeBoardId!;
    }
    if (boards.isEmpty) {
      throw StateError('BoardFlowWorkspace has no boards');
    }
    return boards.first.id;
  }

  BoardFlowBoard<T> get activeBoard {
    final board = boardById(resolvedActiveBoardId);
    if (board == null) {
      throw StateError('Active board not found: $resolvedActiveBoardId');
    }
    return board;
  }

  BoardFlowWorkspace<T> copyWith({
    List<BoardFlowBoard<T>>? boards,
    String? activeBoardId,
  }) {
    return BoardFlowWorkspace<T>(
      boards: boards ?? this.boards,
      activeBoardId: activeBoardId ?? this.activeBoardId,
    );
  }

  /// Applies a card move immutably. Returns the same instance if no-op.
  BoardFlowWorkspace<T> applyMove(BoardFlowMove<T> move) {
    if (move.fromBoardId == move.toBoardId &&
        move.fromColumnId == move.toColumnId &&
        move.fromIndex == move.toIndex) {
      return this;
    }

    final fromBoard = boardById(move.fromBoardId);
    final toBoard = boardById(move.toBoardId);
    if (fromBoard == null || toBoard == null) return this;

    if (move.fromBoardId == move.toBoardId) {
      return _applySameBoardMove(fromBoard, move);
    }
    return _applyCrossBoardMove(fromBoard, toBoard, move);
  }

  BoardFlowWorkspace<T> applyColumnReorder(BoardFlowColumnReorder reorder) {
    final board = boardById(reorder.boardId);
    if (board == null) return this;
    if (reorder.fromIndex < 0 ||
        reorder.fromIndex >= board.columns.length ||
        reorder.toIndex < 0 ||
        reorder.toIndex >= board.columns.length ||
        reorder.fromIndex == reorder.toIndex) {
      return this;
    }

    final columns = List<BoardFlowColumn<T>>.of(board.columns);
    final column = columns.removeAt(reorder.fromIndex);
    columns.insert(reorder.toIndex, column);

    return copyWith(
      boards: boards
          .map(
            (b) => b.id == board.id ? b.copyWith(columns: columns) : b,
          )
          .toList(growable: false),
    );
  }

  BoardFlowWorkspace<T> _applySameBoardMove(
    BoardFlowBoard<T> board,
    BoardFlowMove<T> move,
  ) {
    final columns = board.columns
        .map((c) => c.copyWith(cards: List<BoardFlowCard<T>>.of(c.cards)))
        .toList(growable: false);

    final fromColIndex =
        columns.indexWhere((c) => c.id == move.fromColumnId);
    final toColIndex = columns.indexWhere((c) => c.id == move.toColumnId);
    if (fromColIndex < 0 || toColIndex < 0) return this;

    final fromCards = List<BoardFlowCard<T>>.of(columns[fromColIndex].cards);
    if (move.fromIndex < 0 || move.fromIndex >= fromCards.length) return this;

    final card = fromCards.removeAt(move.fromIndex);
    final relocated = card.copyWith(
      boardId: move.toBoardId,
      columnId: move.toColumnId,
    );

    if (move.fromColumnId == move.toColumnId) {
      var insertAt = move.toIndex;
      if (insertAt > fromCards.length) insertAt = fromCards.length;
      fromCards.insert(insertAt, relocated);
      columns[fromColIndex] = columns[fromColIndex].copyWith(cards: fromCards);
    } else {
      columns[fromColIndex] = columns[fromColIndex].copyWith(cards: fromCards);
      final toCards = List<BoardFlowCard<T>>.of(columns[toColIndex].cards);
      var insertAt = move.toIndex;
      if (insertAt > toCards.length) insertAt = toCards.length;
      toCards.insert(insertAt, relocated);
      columns[toColIndex] = columns[toColIndex].copyWith(cards: toCards);
    }

    final updatedBoard = board.copyWith(columns: columns);
    return copyWith(
      boards: boards
          .map((b) => b.id == board.id ? updatedBoard : b)
          .toList(growable: false),
    );
  }

  BoardFlowWorkspace<T> _applyCrossBoardMove(
    BoardFlowBoard<T> fromBoard,
    BoardFlowBoard<T> toBoard,
    BoardFlowMove<T> move,
  ) {
    final fromColumns = fromBoard.columns
        .map((c) => c.copyWith(cards: List<BoardFlowCard<T>>.of(c.cards)))
        .toList(growable: false);
    final toColumns = toBoard.columns
        .map((c) => c.copyWith(cards: List<BoardFlowCard<T>>.of(c.cards)))
        .toList(growable: false);

    final fromColIndex =
        fromColumns.indexWhere((c) => c.id == move.fromColumnId);
    final toColIndex = toColumns.indexWhere((c) => c.id == move.toColumnId);
    if (fromColIndex < 0 || toColIndex < 0) return this;

    final fromCards =
        List<BoardFlowCard<T>>.of(fromColumns[fromColIndex].cards);
    if (move.fromIndex < 0 || move.fromIndex >= fromCards.length) return this;

    final card = fromCards.removeAt(move.fromIndex);
    fromColumns[fromColIndex] =
        fromColumns[fromColIndex].copyWith(cards: fromCards);

    final relocated = card.copyWith(
      boardId: move.toBoardId,
      columnId: move.toColumnId,
    );
    final toCards = List<BoardFlowCard<T>>.of(toColumns[toColIndex].cards);
    var insertAt = move.toIndex;
    if (insertAt > toCards.length) insertAt = toCards.length;
    toCards.insert(insertAt, relocated);
    toColumns[toColIndex] = toColumns[toColIndex].copyWith(cards: toCards);

    final updatedFrom = fromBoard.copyWith(columns: fromColumns);
    final updatedTo = toBoard.copyWith(columns: toColumns);

    return copyWith(
      boards: boards
          .map((b) {
            if (b.id == fromBoard.id) return updatedFrom;
            if (b.id == toBoard.id) return updatedTo;
            return b;
          })
          .toList(growable: false),
    );
  }
}
