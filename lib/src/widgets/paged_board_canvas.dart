import 'package:flutter/material.dart';

import '../models/column.dart';
import '../physics/hit_testing.dart';
import 'board_canvas.dart';
import 'board_column.dart';
import 'flexi_board_scope.dart';

/// PageView of columns — one primary column per page with optional side peek.
///
/// While dragging, moving the pointer near the left/right edge of the viewport
/// animates to the previous/next column (CRM BoardView-style interaction).
class PagedBoardCanvas<T> extends StatefulWidget {
  const PagedBoardCanvas({
    super.key,
    required this.boardId,
    required this.columns,
    this.dropRegistry,
    this.activeColumnId,
    this.onActiveColumnChanged,
  });

  final String boardId;
  final List<FlexiBoardColumn<T>> columns;
  final DropRegistry<T>? dropRegistry;
  final String? activeColumnId;
  final ValueChanged<String>? onActiveColumnChanged;

  @override
  State<PagedBoardCanvas<T>> createState() => PagedBoardCanvasState<T>();
}

class PagedBoardCanvasState<T> extends State<PagedBoardCanvas<T>> {
  final _pageViewKey = GlobalKey();
  PageController? _pageController;
  final Map<String, GlobalKey<BoardColumnViewState<T>>> _columnKeys = {};

  bool _pageAnimating = false;
  int _currentPage = 0;

  PageController get _controller {
    final controller = _pageController;
    if (controller == null) {
      throw StateError('PageController not ready');
    }
    return controller;
  }

  @override
  void initState() {
    super.initState();
    _currentPage = _indexForColumnId(widget.activeColumnId);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = FlexiBoardScope.of<T>(context);
    final fraction = _viewportFraction(context, scope.physics.pageSideMargin);
    _pageController ??= PageController(
      initialPage: _currentPage,
      viewportFraction: fraction,
    );
    widget.dropRegistry?.registerBoard(
      widget.boardId,
      handlePointer,
      stopScrolling,
    );
  }

  @override
  void didUpdateWidget(covariant PagedBoardCanvas<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activeColumnId != null &&
        widget.activeColumnId != oldWidget.activeColumnId) {
      final index = _indexForColumnId(widget.activeColumnId);
      if (index != _currentPage && (_pageController?.hasClients ?? false)) {
        _animateToPage(index);
      }
    }
    if (widget.columns.length != oldWidget.columns.length &&
        widget.columns.isNotEmpty &&
        _currentPage >= widget.columns.length) {
      _currentPage = widget.columns.length - 1;
      if (_pageController?.hasClients ?? false) {
        _controller.jumpToPage(_currentPage);
      }
    }
  }

  @override
  void dispose() {
    widget.dropRegistry?.unregisterBoard(
      widget.boardId,
      handler: handlePointer,
      stopScrolling: stopScrolling,
    );
    _pageController?.dispose();
    super.dispose();
  }

  double _viewportFraction(BuildContext context, double sideMargin) {
    final width = MediaQuery.sizeOf(context).width;
    if (width <= 0) return 1;
    final fraction = 1 - (2 * sideMargin / width);
    if (fraction <= 0.5) return 0.85;
    if (fraction > 1) return 1;
    return fraction;
  }

  int _indexForColumnId(String? columnId) {
    if (columnId == null || widget.columns.isEmpty) return 0;
    final index = widget.columns.indexWhere((c) => c.id == columnId);
    return index < 0 ? 0 : index;
  }

  GlobalKey<BoardColumnViewState<T>> _columnKey(String id) =>
      _columnKeys.putIfAbsent(id, GlobalKey<BoardColumnViewState<T>>.new);

  void handlePointer(Offset global) {
    if (!mounted) return;
    final scope = FlexiBoardScope.of<T>(context);
    final session = scope.dragSession;
    if (!session.active) return;

    for (final column in widget.columns) {
      final key = _columnKey(column.id);
      final ctx = key.currentContext;
      if (ctx == null) continue;
      final columnRect = globalRectOf(ctx);
      if (columnRect == null || !columnRect.contains(global)) continue;
      key.currentState?.handleHover(global);
      _maybeEdgePage(global, scope.physics.pageEdgeExtent);
      return;
    }

    final pageContext = _pageViewKey.currentContext;
    final boardRect =
        pageContext == null ? null : globalRectOf(pageContext);
    if (boardRect != null && boardRect.contains(global)) {
      final nearest = _nearestVisibleColumnKey();
      nearest?.currentState?.handleHover(global, forceInside: true);
      _maybeEdgePage(global, scope.physics.pageEdgeExtent);
    }
  }

  GlobalKey<BoardColumnViewState<T>>? _nearestVisibleColumnKey() {
    if (widget.columns.isEmpty) return null;
    final safeIndex = _currentPage.clamp(0, widget.columns.length - 1);
    return _columnKey(widget.columns[safeIndex].id);
  }

  void _maybeEdgePage(Offset global, double edgeExtent) {
    final controller = _pageController;
    if (_pageAnimating || controller == null || !controller.hasClients) {
      return;
    }
    final render =
        _pageViewKey.currentContext?.findRenderObject() as RenderBox?;
    if (render == null) return;
    final position = render.localToGlobal(Offset.zero);
    final left = position.dx;
    final right = left + render.size.width;

    if (global.dx < left + edgeExtent) {
      if (_currentPage > 0) {
        _animateToPage(_currentPage - 1);
      }
    } else if (global.dx > right - edgeExtent) {
      if (_currentPage < widget.columns.length - 1) {
        _animateToPage(_currentPage + 1);
      }
    }
  }

  Future<void> _animateToPage(int page) async {
    final controller = _pageController;
    if (_pageAnimating || page == _currentPage || controller == null) {
      return;
    }
    if (!controller.hasClients) return;
    final scope = FlexiBoardScope.of<T>(context);
    _pageAnimating = true;
    try {
      await controller.animateToPage(
        page,
        duration: scope.physics.pageChangeDuration,
        curve: scope.physics.animationCurve,
      );
    } finally {
      if (mounted) {
        _pageAnimating = false;
      }
    }
  }

  void stopScrolling() {
    if (!mounted) return;
    for (final key in _columnKeys.values) {
      key.currentState?.stopScrolling();
    }
  }

  void _onPageChanged(int index) {
    _currentPage = index;
    if (index < 0 || index >= widget.columns.length) return;
    widget.onActiveColumnChanged?.call(widget.columns[index].id);
  }

  @override
  Widget build(BuildContext context) {
    final scope = FlexiBoardScope.of<T>(context);
    final theme = scope.theme;
    final scheme = Theme.of(context).colorScheme;
    final controller = _pageController;
    if (controller == null) {
      return const SizedBox.shrink();
    }

    if (widget.columns.isEmpty) {
      return const Center(child: Text('No columns'));
    }

    return ColoredBox(
      color: theme.boardBackgroundColor ?? scheme.surfaceContainerLowest,
      child: PageView.builder(
        key: _pageViewKey,
        controller: controller,
        allowImplicitScrolling: true,
        itemCount: widget.columns.length,
        onPageChanged: _onPageChanged,
        itemBuilder: (context, index) {
          final column = widget.columns[index];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: BoardColumnView<T>(
              key: _columnKey(column.id),
              boardId: widget.boardId,
              column: column,
              cards: column.cards,
              columnIndex: index,
              expandHorizontally: true,
            ),
          );
        },
      ),
    );
  }
}
