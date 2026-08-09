import 'package:flutter/widgets.dart';

import '../defaults/board_flow_theme.dart';
import '../models/board.dart';
import '../models/card.dart';
import '../models/column.dart';
import '../models/move.dart';
import '../models/workspace.dart';
import '../physics/board_flow_physics.dart';
import '../physics/drag_session.dart';
import '../policies/wip_policy.dart';

typedef BoardFlowCardBuilder<T> = Widget Function(
  BuildContext context,
  BoardFlowCard<T> card,
  BoardFlowCardDragDetails details,
);

typedef BoardFlowColumnHeaderBuilder<T> = Widget Function(
  BuildContext context,
  BoardFlowColumn<T> column,
);

typedef BoardFlowColumnFooterBuilder<T> = Widget Function(
  BuildContext context,
  BoardFlowColumn<T> column,
);

typedef BoardFlowBoardTabBuilder<T> = Widget Function(
  BuildContext context,
  BoardFlowBoard<T> board,
  bool selected,
  bool dragHover,
);

typedef BoardFlowEmptyColumnBuilder<T> = Widget Function(
  BuildContext context,
  BoardFlowColumn<T> column,
);

typedef BoardFlowSwimlaneHeaderBuilder<T> = Widget Function(
  BuildContext context,
  String swimlaneId,
  String title,
);

class BoardFlowCardDragDetails {
  const BoardFlowCardDragDetails({
    required this.isDragging,
    required this.isGhost,
  });

  final bool isDragging;
  final bool isGhost;
}

enum BoardFlowLayout {
  /// Shows only the active board (or the sole board).
  single,

  /// Tab strip + one visible board; drag over tabs to switch.
  tabs,

  /// Multiple boards visible horizontally for cross-board drops.
  sideBySide,
}

class BoardFlowScope<T> extends InheritedWidget {
  const BoardFlowScope({
    super.key,
    required this.workspace,
    required this.physics,
    required this.policies,
    required this.theme,
    required this.dragSession,
    required this.layout,
    required this.onCardMoved,
    required this.onColumnReordered,
    required this.onActiveBoardChanged,
    required this.cardBuilder,
    required this.columnHeaderBuilder,
    required this.columnFooterBuilder,
    required this.boardTabBuilder,
    required this.emptyColumnBuilder,
    required this.swimlaneHeaderBuilder,
    required this.requestActiveBoard,
    required super.child,
  });

  final BoardFlowWorkspace<T> workspace;
  final BoardFlowPhysics physics;
  final BoardFlowPolicies<T> policies;
  final BoardFlowTheme theme;
  final DragSession dragSession;
  final BoardFlowLayout layout;
  final ValueChanged<BoardFlowMove<T>>? onCardMoved;
  final ValueChanged<BoardFlowColumnReorder>? onColumnReordered;
  final ValueChanged<String>? onActiveBoardChanged;
  final BoardFlowCardBuilder<T>? cardBuilder;
  final BoardFlowColumnHeaderBuilder<T>? columnHeaderBuilder;
  final BoardFlowColumnFooterBuilder<T>? columnFooterBuilder;
  final BoardFlowBoardTabBuilder<T>? boardTabBuilder;
  final BoardFlowEmptyColumnBuilder<T>? emptyColumnBuilder;
  final BoardFlowSwimlaneHeaderBuilder<T>? swimlaneHeaderBuilder;
  final ValueChanged<String> requestActiveBoard;

  static BoardFlowScope<T> of<T>(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<BoardFlowScope<T>>();
    assert(scope != null, 'BoardFlowScope<$T> not found in context');
    return scope!;
  }

  static BoardFlowScope<T>? maybeOf<T>(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<BoardFlowScope<T>>();
  }

  @override
  bool updateShouldNotify(BoardFlowScope<T> oldWidget) {
    return workspace != oldWidget.workspace ||
        physics != oldWidget.physics ||
        policies != oldWidget.policies ||
        theme != oldWidget.theme ||
        layout != oldWidget.layout ||
        dragSession != oldWidget.dragSession;
  }
}
