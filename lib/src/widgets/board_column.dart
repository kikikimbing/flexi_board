import 'package:flutter/material.dart';

import '../defaults/default_column_header.dart';
import '../models/card.dart';
import '../models/column.dart';
import '../models/move.dart';
import '../physics/edge_auto_scroll.dart';
import '../physics/hit_testing.dart';
import 'board_card_slot.dart';
import 'board_flow_scope.dart';

class BoardColumnView<T> extends StatefulWidget {
  const BoardColumnView({
    super.key,
    required this.boardId,
    required this.column,
    required this.cards,
    this.columnIndex = 0,
    this.swimlaneId,
  });

  final String boardId;
  final BoardFlowColumn<T> column;
  final List<BoardFlowCard<T>> cards;
  final int columnIndex;
  final String? swimlaneId;

  @override
  BoardColumnViewState<T> createState() => BoardColumnViewState<T>();
}

class BoardColumnViewState<T> extends State<BoardColumnView<T>> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _listKey = GlobalKey();
  EdgeAutoScroller? _scroller;
  final Map<int, GlobalKey> _itemKeys = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = BoardFlowScope.of<T>(context);
    _scroller?.dispose();
    _scroller = EdgeAutoScroller(
      controller: _scrollController,
      physics: scope.physics,
      axis: Axis.vertical,
    );
  }

  @override
  void dispose() {
    _scroller?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  GlobalKey _keyFor(int index) =>
      _itemKeys.putIfAbsent(index, GlobalKey.new);

  List<double> _itemCenters(BuildContext listContext) {
    final listBox = listContext.findRenderObject() as RenderBox?;
    if (listBox == null) return const [];
    final centers = <double>[];
    for (var i = 0; i < widget.cards.length; i++) {
      final box = _keyFor(i).currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) continue;
      final topLeft = box.localToGlobal(Offset.zero, ancestor: listBox);
      centers.add(topLeft.dy + box.size.height / 2);
    }
    return centers;
  }

  BoardFlowCard<T>? _findCard(BoardFlowScope<T> scope, String cardId) {
    for (final board in scope.workspace.boards) {
      for (final column in board.columns) {
        for (final card in column.cards) {
          if (card.id == cardId) return card;
        }
      }
    }
    return null;
  }

  /// Called by [BoardCanvas] when the pointer is over this column.
  void handleHover(
    Offset global, {
    bool forceTopSlot = false,
    bool forceInside = false,
  }) {
    final scope = BoardFlowScope.of<T>(context);
    final session = scope.dragSession;
    if (!session.active || session.cardId == null) return;

    final rect = globalRectOf(context);
    if (rect != null) {
      _scroller?.updatePointer(globalPosition: global, viewportGlobal: rect);
    }

    final listContext = _listKey.currentContext;
    int index;
    Offset? snapAnchor;

    if (listContext == null || forceTopSlot) {
      index = 0;
      if (rect != null) {
        // Just below the header area inside the column.
        snapAnchor = Offset(rect.left + 8, rect.top + 52);
      }
    } else {
      final listBox = listContext.findRenderObject() as RenderBox?;
      if (listBox == null) return;

      final local = forceInside
          ? Offset(listBox.size.width / 2, 0)
          : listBox.globalToLocal(global);
      final sameColumn = session.fromBoardId == widget.boardId &&
          session.fromColumnId == widget.column.id;
      final centers = _itemCenters(listContext);
      index = forceTopSlot
          ? 0
          : computeInsertIndex(
              localY: local.dy,
              itemCenters: centers,
              itemCount: widget.cards.length,
              draggingFromIndex: session.fromIndex,
              sameColumn: sameColumn,
            );

      final listOrigin = listBox.localToGlobal(Offset.zero);
      var anchorY = listOrigin.dy;
      if (index > 0 && index <= centers.length) {
        // Place snap just above the item that will shift down, or at end.
        if (index < centers.length) {
          anchorY = listOrigin.dy + centers[index] - 28;
        } else if (centers.isNotEmpty) {
          anchorY = listOrigin.dy + centers.last + 28;
        }
      }
      snapAnchor = Offset(listOrigin.dx, anchorY);
    }

    final realCard = _findCard(scope, session.cardId!);
    var rejected = false;
    if (realCard != null) {
      final move = BoardFlowMove<T>(
        card: realCard,
        fromBoardId: session.fromBoardId!,
        toBoardId: widget.boardId,
        fromColumnId: session.fromColumnId!,
        toColumnId: widget.column.id,
        fromIndex: session.fromIndex!,
        toIndex: index,
      );
      rejected = !scope.policies.accepts(move, scope.workspace);
    }

    final crossBoard = session.fromBoardId != null &&
        session.fromBoardId != widget.boardId;
    final useSnap = scope.physics.snapFeedbackToPlaceholder &&
        (crossBoard || session.snappedToForeignBoard);

    session.updateHover(
      boardId: widget.boardId,
      columnId: widget.column.id,
      index: index,
      rejected: rejected,
      snapAnchor: useSnap ? snapAnchor : null,
      clearSnapAnchor: !useSnap,
    );
  }

  void stopScrolling() => _scroller?.stop();

  void _startColumnReorder(BoardFlowScope<T> scope) {
    // Simple adjacent-forward reorder on long-press for discoverability.
    // Hosts can also call controller.reorderColumn directly.
    final board = scope.workspace.boardById(widget.boardId);
    if (board == null) return;
    final from = widget.columnIndex;
    if (from < 0 || from >= board.columns.length - 1) return;
    scope.onColumnReordered?.call(
      BoardFlowColumnReorder(
        boardId: widget.boardId,
        fromIndex: from,
        toIndex: from + 1,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scope = BoardFlowScope.of<T>(context);
    final theme = scope.theme;
    final session = scope.dragSession;
    final scheme = Theme.of(context).colorScheme;

    final header = scope.columnHeaderBuilder?.call(context, widget.column) ??
        DefaultColumnHeader<T>(
          column: widget.column,
          theme: theme,
          policies: scope.policies,
        );

    final footer = scope.columnFooterBuilder?.call(context, widget.column);

    return AnimatedBuilder(
      animation: session,
      builder: (context, _) {
        final showPlaceholder = session.active &&
            session.hoverBoardId == widget.boardId &&
            session.hoverColumnId == widget.column.id &&
            session.hoverIndex != null;

        return Container(
          width: scope.physics.columnWidth,
          margin: EdgeInsets.only(right: scope.physics.columnSpacing),
          decoration: BoxDecoration(
            color: theme.columnBackgroundColor ?? scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(theme.columnBorderRadius),
            border: session.active &&
                    session.hoverColumnId == widget.column.id &&
                    session.hoverBoardId == widget.boardId
                ? Border.all(
                    color: session.rejected
                        ? scheme.error
                        : scheme.primary,
                    width: 1.5,
                  )
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                onLongPress: scope.policies.allowColumnReorder
                    ? () => _startColumnReorder(scope)
                    : null,
                child: header,
              ),
              Expanded(
                child: ListView(
                  key: _listKey,
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                  children: _buildChildren(
                    context,
                    showPlaceholder,
                    session.hoverIndex ?? 0,
                    session.rejected,
                  ),
                ),
              ),
              ?footer,
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildChildren(
    BuildContext context,
    bool showPlaceholder,
    int placeholderIndex,
    bool rejected,
  ) {
    final scope = BoardFlowScope.of<T>(context);
    final theme = scope.theme;
    final scheme = Theme.of(context).colorScheme;
    final children = <Widget>[];

    if (widget.cards.isEmpty && !showPlaceholder) {
      children.add(
        scope.emptyColumnBuilder?.call(context, widget.column) ??
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Drop cards here',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ),
      );
      return children;
    }

    void addPlaceholder() {
      children.add(
        Container(
          height: scope.dragSession.feedbackSize?.height ?? 56,
          margin: EdgeInsets.only(bottom: scope.physics.cardSpacing),
          decoration: BoxDecoration(
            color: rejected
                ? (theme.rejectedColor ??
                    scheme.error.withValues(alpha: 0.2))
                : (theme.placeholderColor ??
                    scheme.primary.withValues(alpha: 0.18)),
            borderRadius: BorderRadius.circular(theme.cardBorderRadius),
          ),
        ),
      );
    }

    for (var i = 0; i < widget.cards.length; i++) {
      if (showPlaceholder && placeholderIndex == i) {
        addPlaceholder();
      }
      final card = widget.cards[i];
      children.add(
        Padding(
          key: _keyFor(i),
          padding: EdgeInsets.only(bottom: scope.physics.cardSpacing),
          child: BoardCardSlot<T>(
            boardId: widget.boardId,
            columnId: widget.column.id,
            index: i,
            card: card,
          ),
        ),
      );
    }

    if (showPlaceholder && placeholderIndex >= widget.cards.length) {
      addPlaceholder();
    }

    return children;
  }
}
