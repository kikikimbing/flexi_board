import 'package:flutter/widgets.dart';

import '../defaults/flexi_board_theme.dart';
import '../models/board.dart';
import '../models/card.dart';
import '../models/column.dart';
import '../models/move.dart';
import '../models/workspace.dart';
import '../physics/flexi_board_physics.dart';
import '../physics/drag_session.dart';
import '../policies/wip_policy.dart';

typedef FlexiBoardCardBuilder<T> = Widget Function(
  BuildContext context,
  FlexiBoardCard<T> card,
  FlexiBoardCardDragDetails details,
);

typedef FlexiBoardColumnHeaderBuilder<T> = Widget Function(
  BuildContext context,
  FlexiBoardColumn<T> column,
);

typedef FlexiBoardColumnFooterBuilder<T> = Widget Function(
  BuildContext context,
  FlexiBoardColumn<T> column,
);

/// Wraps a column’s vertical card [list] (the same ListView used for cards
/// and placeholders). Use for pull-to-refresh, infinite scroll, etc.
typedef FlexiBoardColumnListWrapper<T> = Widget Function(
  BuildContext context,
  FlexiBoardColumn<T> column,
  Widget list,
);

typedef FlexiBoardBoardTabBuilder<T> = Widget Function(
  BuildContext context,
  FlexiBoardBoard<T> board,
  bool selected,
  bool dragHover,
);

typedef FlexiBoardEmptyColumnBuilder<T> = Widget Function(
  BuildContext context,
  FlexiBoardColumn<T> column,
);

typedef FlexiBoardSwimlaneHeaderBuilder<T> = Widget Function(
  BuildContext context,
  String swimlaneId,
  String title,
);

class FlexiBoardCardDragDetails {
  const FlexiBoardCardDragDetails({
    required this.isDragging,
    required this.isGhost,
  });

  final bool isDragging;
  final bool isGhost;
}

enum FlexiBoardLayout {
  /// Shows only the active board (or the sole board) as a horizontal canvas.
  single,

  /// Tab strip + one visible board; drag over tabs to switch.
  tabs,

  /// Multiple boards visible horizontally for cross-board drops.
  sideBySide,

  /// One column per PageView page with side peek; drag near edges to page.
  paged,
}

class FlexiBoardScope<T> extends InheritedWidget {
  const FlexiBoardScope({
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
    required this.columnListWrapper,
    required this.boardTabBuilder,
    required this.emptyColumnBuilder,
    required this.swimlaneHeaderBuilder,
    required this.requestActiveBoard,
    required super.child,
  });

  final FlexiBoardWorkspace<T> workspace;
  final FlexiBoardPhysics physics;
  final FlexiBoardPolicies<T> policies;
  final FlexiBoardTheme theme;
  final DragSession dragSession;
  final FlexiBoardLayout layout;
  final ValueChanged<FlexiBoardMove<T>>? onCardMoved;
  final ValueChanged<FlexiBoardColumnReorder>? onColumnReordered;
  final ValueChanged<String>? onActiveBoardChanged;
  final FlexiBoardCardBuilder<T>? cardBuilder;
  final FlexiBoardColumnHeaderBuilder<T>? columnHeaderBuilder;
  final FlexiBoardColumnFooterBuilder<T>? columnFooterBuilder;
  final FlexiBoardColumnListWrapper<T>? columnListWrapper;
  final FlexiBoardBoardTabBuilder<T>? boardTabBuilder;
  final FlexiBoardEmptyColumnBuilder<T>? emptyColumnBuilder;
  final FlexiBoardSwimlaneHeaderBuilder<T>? swimlaneHeaderBuilder;
  final ValueChanged<String> requestActiveBoard;

  static FlexiBoardScope<T> of<T>(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<FlexiBoardScope<T>>();
    assert(scope != null, 'FlexiBoardScope<$T> not found in context');
    return scope!;
  }

  static FlexiBoardScope<T>? maybeOf<T>(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<FlexiBoardScope<T>>();
  }

  @override
  bool updateShouldNotify(FlexiBoardScope<T> oldWidget) {
    return workspace != oldWidget.workspace ||
        physics != oldWidget.physics ||
        policies != oldWidget.policies ||
        theme != oldWidget.theme ||
        layout != oldWidget.layout ||
        dragSession != oldWidget.dragSession;
  }
}
