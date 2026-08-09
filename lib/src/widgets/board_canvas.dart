import 'package:flutter/material.dart';

import '../models/card.dart';
import '../models/column.dart';
import '../models/move.dart';
import '../models/swimlane.dart';
import '../physics/edge_auto_scroll.dart';
import '../physics/hit_testing.dart';
import 'board_column.dart';
import 'board_flow_scope.dart';

/// Horizontal scrollable columns for one board.
class BoardCanvas<T> extends StatefulWidget {
  const BoardCanvas({
    super.key,
    required this.boardId,
    required this.columns,
    this.swimlanes = const [],
    this.dropRegistry,
  });

  final String boardId;
  final List<BoardFlowColumn<T>> columns;
  final List<BoardFlowSwimlane<T>> swimlanes;
  final DropRegistry<T>? dropRegistry;

  @override
  State<BoardCanvas<T>> createState() => BoardCanvasState<T>();
}

class BoardCanvasState<T> extends State<BoardCanvas<T>> {
  final ScrollController _scrollController = ScrollController();
  EdgeAutoScroller? _scroller;
  final Map<String, GlobalKey<BoardColumnViewState<T>>> _columnKeys = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = BoardFlowScope.of<T>(context);
    _scroller?.dispose();
    _scroller = EdgeAutoScroller(
      controller: _scrollController,
      physics: scope.physics,
      axis: Axis.horizontal,
    );
    widget.dropRegistry?.registerBoard(
      widget.boardId,
      handlePointer,
      stopScrolling,
    );
  }

  @override
  void dispose() {
    _scroller?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  GlobalKey<BoardColumnViewState<T>> _columnKey(String id) =>
      _columnKeys.putIfAbsent(id, GlobalKey<BoardColumnViewState<T>>.new);

  void handlePointer(Offset global) {
    final scope = BoardFlowScope.of<T>(context);
    final session = scope.dragSession;
    if (!session.active) return;

    final boardRect = globalRectOf(context);
    if (boardRect != null) {
      _scroller?.updatePointer(globalPosition: global, viewportGlobal: boardRect);
    }

    // Direct hit on a column.
    for (final column in widget.columns) {
      final key = _columnKey(column.id);
      final ctx = key.currentContext;
      if (ctx == null) continue;
      final columnRect = globalRectOf(ctx);
      if (columnRect == null || !columnRect.contains(global)) continue;
      final enteringBoard = session.hoverBoardId != widget.boardId;
      key.currentState?.handleHover(
        global,
        forceTopSlot: scope.physics.snapOnBoardEnter && enteringBoard,
      );
      return;
    }

    // Pointer inside this board but not over a column — snap to nearest column.
    final insideBoard = boardRect != null && boardRect.contains(global);
    final enteringForeign = scope.physics.snapOnBoardEnter &&
        insideBoard &&
        session.hoverBoardId != widget.boardId;
    if (!enteringForeign && !insideBoard) return;
    if (!scope.physics.snapOnBoardEnter && !insideBoard) return;
    if (!insideBoard) return;

    final nearest = _nearestColumnKey(global);
    if (nearest == null) return;
    final enteringBoard = session.hoverBoardId != widget.boardId;
    nearest.currentState?.handleHover(
      global,
      forceTopSlot: scope.physics.snapOnBoardEnter && enteringBoard,
      forceInside: true,
    );
  }

  GlobalKey<BoardColumnViewState<T>>? _nearestColumnKey(Offset global) {
    GlobalKey<BoardColumnViewState<T>>? best;
    var bestDist = double.infinity;
    for (final column in widget.columns) {
      final key = _columnKey(column.id);
      final ctx = key.currentContext;
      if (ctx == null) continue;
      final rect = globalRectOf(ctx);
      if (rect == null) continue;
      final cx = rect.center.dx;
      final cy = rect.center.dy;
      final dist = (Offset(cx, cy) - global).distance;
      if (dist < bestDist) {
        bestDist = dist;
        best = key;
      }
    }
    return best;
  }

  void stopScrolling() {
    _scroller?.stop();
    for (final key in _columnKeys.values) {
      key.currentState?.stopScrolling();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scope = BoardFlowScope.of<T>(context);
    final theme = scope.theme;
    final scheme = Theme.of(context).colorScheme;

    if (widget.swimlanes.isEmpty) {
      return _buildColumnRow(
        context,
        widget.columns,
        useScrollController: true,
      );
    }

    return ColoredBox(
      color: theme.boardBackgroundColor ?? scheme.surfaceContainerLowest,
      child: ListView.builder(
        itemCount: widget.swimlanes.length,
        itemBuilder: (context, laneIndex) {
          final lane = widget.swimlanes[laneIndex];
          if (lane.collapsed) {
            return _swimlaneHeader(context, lane);
          }
          final filteredColumns = widget.columns
              .map(
                (column) => column.copyWith(
                  cards:
                      column.cards.where(lane.filter).toList(growable: false),
                ),
              )
              .toList(growable: false);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _swimlaneHeader(context, lane),
              SizedBox(
                height: 420,
                child: _buildColumnRow(
                  context,
                  filteredColumns,
                  useScrollController: false,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _swimlaneHeader(BuildContext context, BoardFlowSwimlane<T> lane) {
    final scope = BoardFlowScope.of<T>(context);
    return scope.swimlaneHeaderBuilder?.call(context, lane.id, lane.title) ??
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: Text(
            lane.title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        );
  }

  Widget _buildColumnRow(
    BuildContext context,
    List<BoardFlowColumn<T>> columns, {
    required bool useScrollController,
  }) {
    final scope = BoardFlowScope.of<T>(context);
    final theme = scope.theme;
    final scheme = Theme.of(context).colorScheme;

    return ColoredBox(
      color: theme.boardBackgroundColor ?? scheme.surfaceContainerLowest,
      child: ListView.builder(
        controller: useScrollController ? _scrollController : null,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(12),
        itemCount: columns.length,
        itemBuilder: (context, index) {
          final column = columns[index];
          return BoardColumnView<T>(
            key: useScrollController ? _columnKey(column.id) : null,
            boardId: widget.boardId,
            column: column,
            cards: column.cards,
            columnIndex: index,
          );
        },
      ),
    );
  }
}

/// Maps board ids to pointer handlers while dragging.
class DropRegistry<T> {
  final Map<String, void Function(Offset)> _handlers = {};
  final Map<String, VoidCallback> _stoppers = {};

  void registerBoard(
    String boardId,
    void Function(Offset) handler,
    VoidCallback stopScrolling,
  ) {
    _handlers[boardId] = handler;
    _stoppers[boardId] = stopScrolling;
  }

  void handlePointer(Offset global) {
    for (final handler in _handlers.values) {
      handler(global);
    }
  }

  void stopAll() {
    for (final stop in _stoppers.values) {
      stop();
    }
  }

  void clear() {
    _handlers.clear();
    _stoppers.clear();
  }
}

BoardFlowCard<T>? findCardInWorkspace<T>(
  Iterable boards,
  String cardId,
) {
  for (final board in boards) {
    for (final column in board.columns) {
      for (final card in column.cards) {
        if (card.id == cardId) return card as BoardFlowCard<T>;
      }
    }
  }
  return null;
}

BoardFlowMove<T>? buildMoveFromSession<T>({
  required dynamic workspace,
  required dynamic session,
}) {
  if (!session.active ||
      session.cardId == null ||
      session.fromBoardId == null ||
      session.fromColumnId == null ||
      session.fromIndex == null ||
      session.hoverBoardId == null ||
      session.hoverColumnId == null ||
      session.hoverIndex == null) {
    return null;
  }
  final card =
      findCardInWorkspace<T>(workspace.boards, session.cardId as String);
  if (card == null) return null;
  return BoardFlowMove<T>(
    card: card,
    fromBoardId: session.fromBoardId as String,
    toBoardId: session.hoverBoardId as String,
    fromColumnId: session.fromColumnId as String,
    toColumnId: session.hoverColumnId as String,
    fromIndex: session.fromIndex as int,
    toIndex: session.hoverIndex as int,
  );
}
