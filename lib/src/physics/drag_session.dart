import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// Active drag state shared across board widgets.
class DragSession extends ChangeNotifier {
  DragSession();

  bool _active = false;
  String? cardId;
  String? fromBoardId;
  String? fromColumnId;
  int? fromIndex;
  String? hoverBoardId;
  String? hoverColumnId;
  int? hoverIndex;
  Offset? globalPosition;
  Size? feedbackSize;
  int? pointerId;
  bool rejected = false;

  /// Global top-left of the live placeholder when snap feedback is active.
  Offset? snapAnchor;

  /// True after hover board differs from the board where the drag started.
  bool snappedToForeignBoard = false;

  bool get active => _active;

  void start({
    required String cardId,
    required String boardId,
    required String columnId,
    required int index,
    required Offset globalPosition,
    required int pointerId,
    Size? feedbackSize,
  }) {
    _active = true;
    this.cardId = cardId;
    fromBoardId = boardId;
    fromColumnId = columnId;
    fromIndex = index;
    hoverBoardId = boardId;
    hoverColumnId = columnId;
    hoverIndex = index;
    this.globalPosition = globalPosition;
    this.pointerId = pointerId;
    this.feedbackSize = feedbackSize;
    rejected = false;
    snapAnchor = null;
    snappedToForeignBoard = false;
    notifyListeners();
  }

  void updatePosition(Offset globalPosition) {
    this.globalPosition = globalPosition;
    notifyListeners();
  }

  void updateHover({
    String? boardId,
    String? columnId,
    int? index,
    bool? rejected,
    Offset? snapAnchor,
    bool clearSnapAnchor = false,
  }) {
    var changed = false;
    if (boardId != null && boardId != hoverBoardId) {
      hoverBoardId = boardId;
      changed = true;
      if (fromBoardId != null && boardId != fromBoardId) {
        snappedToForeignBoard = true;
      } else if (boardId == fromBoardId) {
        snappedToForeignBoard = false;
      }
    }
    if (columnId != null && columnId != hoverColumnId) {
      hoverColumnId = columnId;
      changed = true;
    }
    if (index != null && index != hoverIndex) {
      hoverIndex = index;
      changed = true;
    }
    if (rejected != null && rejected != this.rejected) {
      this.rejected = rejected;
      changed = true;
    }
    if (clearSnapAnchor) {
      if (this.snapAnchor != null) {
        this.snapAnchor = null;
        changed = true;
      }
    } else if (snapAnchor != null && snapAnchor != this.snapAnchor) {
      this.snapAnchor = snapAnchor;
      changed = true;
    }
    if (changed) notifyListeners();
  }

  void end() {
    _active = false;
    cardId = null;
    fromBoardId = null;
    fromColumnId = null;
    fromIndex = null;
    hoverBoardId = null;
    hoverColumnId = null;
    hoverIndex = null;
    globalPosition = null;
    feedbackSize = null;
    pointerId = null;
    rejected = false;
    snapAnchor = null;
    snappedToForeignBoard = false;
    notifyListeners();
  }
}
