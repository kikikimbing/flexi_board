import 'package:flutter/foundation.dart';

import '../models/board.dart';
import '../models/card.dart';
import '../models/column.dart';
import '../models/move.dart';
import '../models/workspace.dart';
import '../policies/undo_stack.dart';
import '../policies/wip_policy.dart';

/// Optional convenience controller — hosts may ignore this and own state themselves.
class FlexiBoardController<T> extends ChangeNotifier {
  FlexiBoardController({
    required FlexiBoardWorkspace<T> initial,
    FlexiBoardPolicies<T>? policies,
    int maxUndoSteps = 50,
  })  : _workspace = initial,
        policies = policies ?? FlexiBoardPolicies<T>(),
        _undo = UndoStack<T>(maxSteps: maxUndoSteps);

  FlexiBoardWorkspace<T> _workspace;
  final FlexiBoardPolicies<T> policies;
  final UndoStack<T> _undo;

  FlexiBoardWorkspace<T> get workspace => _workspace;
  List<FlexiBoardBoard<T>> get boards => _workspace.boards;
  String get activeBoardId => _workspace.resolvedActiveBoardId;
  bool get canUndo => _undo.canUndo;
  bool get canRedo => _undo.canRedo;

  void setWorkspace(FlexiBoardWorkspace<T> workspace, {bool recordUndo = false}) {
    if (recordUndo) {
      _undo.push(_workspace);
    }
    _workspace = workspace;
    notifyListeners();
  }

  void setActiveBoard(String boardId) {
    if (_workspace.activeBoardId == boardId) return;
    _workspace = _workspace.copyWith(activeBoardId: boardId);
    notifyListeners();
  }

  bool moveCard(FlexiBoardMove<T> move) {
    if (!policies.accepts(move, _workspace)) return false;
    final next = _workspace.applyMove(move);
    if (identical(next, _workspace) || next == _workspace) {
      // Still notify if structure equal but apply returned new — check card positions.
      if (!_didMove(move)) return false;
    }
    _undo.push(_workspace);
    _workspace = next;
    notifyListeners();
    return true;
  }

  bool _didMove(FlexiBoardMove<T> move) {
    return !(move.fromBoardId == move.toBoardId &&
        move.fromColumnId == move.toColumnId &&
        move.fromIndex == move.toIndex);
  }

  bool reorderColumn(FlexiBoardColumnReorder reorder) {
    if (!policies.allowColumnReorder) return false;
    final next = _workspace.applyColumnReorder(reorder);
    if (identical(next, _workspace)) return false;
    _undo.push(_workspace);
    _workspace = next;
    notifyListeners();
    return true;
  }

  void addCard({
    required String boardId,
    required String columnId,
    required FlexiBoardCard<T> card,
    int? index,
  }) {
    final board = _workspace.boardById(boardId);
    if (board == null) return;
    final columns = board.columns.map((c) {
      if (c.id != columnId) return c;
      final cards = List<FlexiBoardCard<T>>.of(c.cards);
      final insertAt = (index ?? cards.length).clamp(0, cards.length);
      cards.insert(
        insertAt,
        card.copyWith(boardId: boardId, columnId: columnId),
      );
      return c.copyWith(cards: cards);
    }).toList(growable: false);

    _undo.push(_workspace);
    _workspace = _workspace.copyWith(
      boards: _workspace.boards
          .map((b) => b.id == boardId ? b.copyWith(columns: columns) : b)
          .toList(growable: false),
    );
    notifyListeners();
  }

  void removeCard(String cardId) {
    FlexiBoardWorkspace<T>? next;
    for (final board in _workspace.boards) {
      for (final column in board.columns) {
        final index = column.cards.indexWhere((c) => c.id == cardId);
        if (index < 0) continue;
        final cards = List<FlexiBoardCard<T>>.of(column.cards)..removeAt(index);
        final columns = board.columns
            .map((c) => c.id == column.id ? c.copyWith(cards: cards) : c)
            .toList(growable: false);
        next = _workspace.copyWith(
          boards: _workspace.boards
              .map((b) => b.id == board.id ? b.copyWith(columns: columns) : b)
              .toList(growable: false),
        );
        break;
      }
      if (next != null) break;
    }
    if (next == null) return;
    _undo.push(_workspace);
    _workspace = next;
    notifyListeners();
  }

  void undo() {
    final previous = _undo.undo(_workspace);
    if (previous == null) return;
    _workspace = previous;
    notifyListeners();
  }

  void redo() {
    final next = _undo.redo(_workspace);
    if (next == null) return;
    _workspace = next;
    notifyListeners();
  }
}

/// Helper to build a simple single-board workspace.
FlexiBoardWorkspace<T> workspaceFromColumns<T>({
  required String boardId,
  required String boardTitle,
  required List<FlexiBoardColumn<T>> columns,
}) {
  return FlexiBoardWorkspace<T>(
    boards: [
      FlexiBoardBoard<T>(
        id: boardId,
        title: boardTitle,
        columns: columns,
      ),
    ],
    activeBoardId: boardId,
  );
}
