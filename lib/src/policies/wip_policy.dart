import '../models/card.dart';
import '../models/column.dart';
import '../models/move.dart';
import '../models/workspace.dart';

/// Drop acceptance, drag-start gates, and WIP helpers.
class FlexiBoardPolicies<T> {
  const FlexiBoardPolicies({
    this.wipEnabled = true,
    this.allowColumnReorder = true,
    this.canStartDrag,
    this.canAcceptDrop,
  });

  final bool wipEnabled;
  final bool allowColumnReorder;

  /// Source-side gate evaluated before a drag session starts.
  ///
  /// When null, every card may be picked up. Use this for freeze / permission
  /// rules — not [canAcceptDrop], which only rejects the target after lift.
  final bool Function(
    FlexiBoardCard<T> card,
    FlexiBoardWorkspace<T> workspace,
  )? canStartDrag;

  /// Host override. When null, WIP rules apply when [wipEnabled] is true.
  final bool Function(FlexiBoardMove<T> move, FlexiBoardWorkspace<T> workspace)?
      canAcceptDrop;

  static FlexiBoardPolicies<T> of<T>() => FlexiBoardPolicies<T>();

  /// Whether [card] may begin a drag in [workspace]. Defaults to true.
  bool allowsStartDrag(
    FlexiBoardCard<T> card,
    FlexiBoardWorkspace<T> workspace,
  ) {
    if (canStartDrag == null) return true;
    return canStartDrag!(card, workspace);
  }

  bool accepts(FlexiBoardMove<T> move, FlexiBoardWorkspace<T> workspace) {
    if (canAcceptDrop != null) {
      return canAcceptDrop!(move, workspace);
    }
    if (!wipEnabled) return true;
    return !wouldExceedWip(move, workspace);
  }

  bool wouldExceedWip(FlexiBoardMove<T> move, FlexiBoardWorkspace<T> workspace) {
    if (move.isSameColumn) return false;
    final board = workspace.boardById(move.toBoardId);
    final column = board?.columnById(move.toColumnId);
    if (column == null) return false;
    return isAtCapacity(column);
  }

  bool isAtCapacity(FlexiBoardColumn<T> column) {
    final limit = column.wipLimit;
    if (limit == null) return false;
    return column.cards.length >= limit;
  }

  bool isApproachingCapacity(FlexiBoardColumn<T> column) {
    final limit = column.wipLimit;
    if (limit == null || limit <= 0) return false;
    return column.cards.length >= (limit - 1) && column.cards.length < limit;
  }
}

/// Simple WIP helpers used by default UI.
bool cardBelongsToSwimlane<T>(
  FlexiBoardCard<T> card,
  bool Function(FlexiBoardCard<T>) filter,
) =>
    filter(card);
