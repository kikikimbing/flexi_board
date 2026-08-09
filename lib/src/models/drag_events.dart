import 'package:flutter/painting.dart';

import 'card.dart';
import 'move.dart';

enum BoardFlowDragPhase {
  /// Long-press succeeded and the drag overlay is active.
  started,

  /// Pointer moved; hover target may have changed.
  updated,

  /// Drag ended without an accepted drop (cancel / rejected / no-op).
  cancelled,
}

/// Payload for [BoardFlow.onDrag].
class BoardFlowDragDetails<T> {
  const BoardFlowDragDetails({
    required this.phase,
    required this.card,
    required this.boardId,
    required this.columnId,
    required this.index,
    required this.globalPosition,
    this.hoverBoardId,
    this.hoverColumnId,
    this.hoverIndex,
    this.rejected = false,
  });

  final BoardFlowDragPhase phase;
  final BoardFlowCard<T> card;

  /// Origin of the drag.
  final String boardId;
  final String columnId;
  final int index;
  final Offset globalPosition;

  /// Current hover target while dragging (set on [BoardFlowDragPhase.updated]).
  final String? hoverBoardId;
  final String? hoverColumnId;
  final int? hoverIndex;
  final bool rejected;
}

/// Payload for [BoardFlow.onDrop].
class BoardFlowDropDetails<T> {
  const BoardFlowDropDetails({
    required this.card,
    required this.accepted,
    this.move,
  });

  final BoardFlowCard<T> card;

  /// True when the drop produced an applied / notified move.
  final bool accepted;

  /// Non-null when [accepted] is true.
  final BoardFlowMove<T>? move;
}

typedef BoardFlowDragCallback<T> = void Function(BoardFlowDragDetails<T> details);
typedef BoardFlowDropCallback<T> = void Function(BoardFlowDropDetails<T> details);
