import '../models/card.dart';
import '../models/column.dart';
import '../models/move.dart';
import '../models/workspace.dart';

/// Drop acceptance and WIP helpers.
class BoardFlowPolicies<T> {
  const BoardFlowPolicies({
    this.wipEnabled = true,
    this.allowColumnReorder = true,
    this.canAcceptDrop,
  });

  final bool wipEnabled;
  final bool allowColumnReorder;

  /// Host override. When null, WIP rules apply when [wipEnabled] is true.
  final bool Function(BoardFlowMove<T> move, BoardFlowWorkspace<T> workspace)?
      canAcceptDrop;

  static BoardFlowPolicies<T> of<T>() => BoardFlowPolicies<T>();

  bool accepts(BoardFlowMove<T> move, BoardFlowWorkspace<T> workspace) {
    if (canAcceptDrop != null) {
      return canAcceptDrop!(move, workspace);
    }
    if (!wipEnabled) return true;
    return !wouldExceedWip(move, workspace);
  }

  bool wouldExceedWip(BoardFlowMove<T> move, BoardFlowWorkspace<T> workspace) {
    if (move.isSameColumn) return false;
    final board = workspace.boardById(move.toBoardId);
    final column = board?.columnById(move.toColumnId);
    if (column == null) return false;
    return isAtCapacity(column);
  }

  bool isAtCapacity(BoardFlowColumn<T> column) {
    final limit = column.wipLimit;
    if (limit == null) return false;
    return column.cards.length >= limit;
  }

  bool isApproachingCapacity(BoardFlowColumn<T> column) {
    final limit = column.wipLimit;
    if (limit == null || limit <= 0) return false;
    return column.cards.length >= (limit - 1) && column.cards.length < limit;
  }
}

/// Simple WIP helpers used by default UI.
bool cardBelongsToSwimlane<T>(
  BoardFlowCard<T> card,
  bool Function(BoardFlowCard<T>) filter,
) =>
    filter(card);
