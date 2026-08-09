import 'package:flutter/painting.dart';

import 'card.dart';
import 'move.dart';

enum FlexiBoardDragPhase {
  /// Long-press succeeded and the drag overlay is active.
  started,

  /// Pointer moved; hover target may have changed.
  updated,

  /// Drag ended without an accepted drop (cancel / rejected / no-op).
  cancelled,
}

/// Payload for [FlexiBoard.onDrag].
class FlexiBoardDragDetails<T> {
  const FlexiBoardDragDetails({
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

  final FlexiBoardDragPhase phase;
  final FlexiBoardCard<T> card;

  /// Origin of the drag.
  final String boardId;
  final String columnId;
  final int index;
  final Offset globalPosition;

  /// Current hover target while dragging (set on [FlexiBoardDragPhase.updated]).
  final String? hoverBoardId;
  final String? hoverColumnId;
  final int? hoverIndex;
  final bool rejected;
}

/// Payload for [FlexiBoard.onDrop].
class FlexiBoardDropDetails<T> {
  const FlexiBoardDropDetails({
    required this.card,
    required this.accepted,
    this.move,
  });

  final FlexiBoardCard<T> card;

  /// True when the drop produced an applied / notified move.
  final bool accepted;

  /// Non-null when [accepted] is true.
  final FlexiBoardMove<T>? move;
}

typedef FlexiBoardDragCallback<T> = void Function(FlexiBoardDragDetails<T> details);
typedef FlexiBoardDropCallback<T> = void Function(FlexiBoardDropDetails<T> details);
