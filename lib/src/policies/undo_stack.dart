import '../models/move.dart';
import '../models/workspace.dart';

/// Immutable undo/redo stack of workspace snapshots.
class UndoStack<T> {
  UndoStack({this.maxSteps = 50});

  final int maxSteps;
  final List<BoardFlowWorkspace<T>> _undo = [];
  final List<BoardFlowWorkspace<T>> _redo = [];

  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;

  void push(BoardFlowWorkspace<T> previous) {
    _undo.add(previous);
    if (_undo.length > maxSteps) {
      _undo.removeAt(0);
    }
    _redo.clear();
  }

  BoardFlowWorkspace<T>? undo(BoardFlowWorkspace<T> current) {
    if (_undo.isEmpty) return null;
    _redo.add(current);
    return _undo.removeLast();
  }

  BoardFlowWorkspace<T>? redo(BoardFlowWorkspace<T> current) {
    if (_redo.isEmpty) return null;
    _undo.add(current);
    return _redo.removeLast();
  }

  void clear() {
    _undo.clear();
    _redo.clear();
  }
}

/// Records move history for debugging / analytics.
class MoveHistory<T> {
  final List<BoardFlowMove<T>> moves = [];

  void add(BoardFlowMove<T> move) => moves.add(move);

  void clear() => moves.clear();
}
