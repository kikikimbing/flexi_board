/// Multi-board drag-and-drop for Flutter — mechanism first, optional default UI.
library;

export 'src/controller/board_flow_controller.dart';
export 'src/defaults/board_flow_theme.dart';
export 'src/defaults/default_card.dart';
export 'src/defaults/default_column_header.dart';
export 'src/defaults/default_tab.dart';
export 'src/models/board.dart';
export 'src/models/card.dart';
export 'src/models/column.dart';
export 'src/models/move.dart';
export 'src/models/swimlane.dart';
export 'src/models/workspace.dart';
export 'src/physics/board_flow_physics.dart';
export 'src/physics/drag_session.dart';
export 'src/physics/edge_auto_scroll.dart' show computeInsertIndex;
export 'src/policies/undo_stack.dart';
export 'src/policies/wip_policy.dart';
export 'src/widgets/board_flow.dart';
export 'src/widgets/board_flow_scope.dart';
