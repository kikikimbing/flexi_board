import 'dart:async';

import 'package:flutter/material.dart';

import '../controller/board_flow_controller.dart';
import '../defaults/board_flow_theme.dart';
import '../defaults/default_card.dart';
import '../models/move.dart';
import '../models/workspace.dart';
import '../physics/board_flow_physics.dart';
import '../physics/drag_session.dart';
import '../policies/wip_policy.dart';
import 'board_canvas.dart';
import 'board_flow_scope.dart';
import 'board_tab_strip.dart';
import 'side_by_side_layout.dart';

/// Plug-and-play multi-board drag-and-drop surface.
///
/// Hosts own data (or pass [controller]). Cards are fully customizable via
/// builders; when omitted, default Material chrome is used.
class BoardFlow<T> extends StatefulWidget {
  const BoardFlow({
    super.key,
    this.workspace,
    this.controller,
    this.layout = BoardFlowLayout.single,
    this.activeBoardId,
    this.physics = BoardFlowPhysics.standard,
    this.policies,
    this.theme,
    this.cardBuilder,
    this.columnHeaderBuilder,
    this.columnFooterBuilder,
    this.boardTabBuilder,
    this.emptyColumnBuilder,
    this.swimlaneHeaderBuilder,
    this.onCardMoved,
    this.onColumnReordered,
    this.onActiveBoardChanged,
  }) : assert(
          workspace != null || controller != null,
          'Provide workspace or controller',
        );

  /// Controlled data. Ignored when [controller] is non-null.
  final BoardFlowWorkspace<T>? workspace;

  /// Optional convenience state owner with undo/redo.
  final BoardFlowController<T>? controller;

  final BoardFlowLayout layout;
  final String? activeBoardId;
  final BoardFlowPhysics physics;
  final BoardFlowPolicies<T>? policies;
  final BoardFlowTheme? theme;

  final BoardFlowCardBuilder<T>? cardBuilder;
  final BoardFlowColumnHeaderBuilder<T>? columnHeaderBuilder;
  final BoardFlowColumnFooterBuilder<T>? columnFooterBuilder;
  final BoardFlowBoardTabBuilder<T>? boardTabBuilder;
  final BoardFlowEmptyColumnBuilder<T>? emptyColumnBuilder;
  final BoardFlowSwimlaneHeaderBuilder<T>? swimlaneHeaderBuilder;

  final ValueChanged<BoardFlowMove<T>>? onCardMoved;
  final ValueChanged<BoardFlowColumnReorder>? onColumnReordered;
  final ValueChanged<String>? onActiveBoardChanged;

  @override
  State<BoardFlow<T>> createState() => _BoardFlowState<T>();
}

class _BoardFlowState<T> extends State<BoardFlow<T>> {
  final DragSession _dragSession = DragSession();
  final DropRegistry<T> _dropRegistry = DropRegistry<T>();
  final TabHitRegistry _tabRegistry = TabHitRegistry();
  final LayerLink _overlayLink = LayerLink();

  OverlayEntry? _overlayEntry;
  Timer? _tabSwitchTimer;
  String? _pendingTabBoardId;
  String? _hoveredTabBoardId;
  String? _localActiveBoardId;

  BoardFlowWorkspace<T> get _workspace {
    if (widget.controller != null) return widget.controller!.workspace;
    return widget.workspace!;
  }

  String get _activeBoardId {
    return _localActiveBoardId ??
        widget.activeBoardId ??
        _workspace.resolvedActiveBoardId;
  }

  BoardFlowPolicies<T> get _policies =>
      widget.policies ??
      widget.controller?.policies ??
      BoardFlowPolicies<T>();

  @override
  void initState() {
    super.initState();
    _dragSession.addListener(_onDragSessionChanged);
    widget.controller?.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(covariant BoardFlow<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_onControllerChanged);
      widget.controller?.addListener(_onControllerChanged);
    }
    if (widget.activeBoardId != null &&
        widget.activeBoardId != oldWidget.activeBoardId) {
      _localActiveBoardId = widget.activeBoardId;
    }
  }

  @override
  void dispose() {
    _tabSwitchTimer?.cancel();
    _removeOverlay();
    _dragSession.removeListener(_onDragSessionChanged);
    widget.controller?.removeListener(_onControllerChanged);
    _dragSession.dispose();
    _dropRegistry.clear();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  void _onDragSessionChanged() {
    if (_dragSession.active) {
      _ensureOverlay();
      _overlayEntry?.markNeedsBuild();
    } else {
      _removeOverlay();
      _tabSwitchTimer?.cancel();
      _pendingTabBoardId = null;
      if (_hoveredTabBoardId != null) {
        setState(() => _hoveredTabBoardId = null);
      }
    }
  }

  void _ensureOverlay() {
    if (_overlayEntry != null) return;
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;
    _overlayEntry = OverlayEntry(builder: _buildDragFeedback);
    overlay.insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Widget _buildDragFeedback(BuildContext context) {
    final pos = _dragSession.globalPosition;
    if (pos == null || _dragSession.cardId == null) {
      return const SizedBox.shrink();
    }

    final card = findCardInWorkspace<T>(_workspace.boards, _dragSession.cardId!);
    if (card == null) return const SizedBox.shrink();

    final theme = widget.theme ?? BoardFlowTheme.fromContext(context);
    final size = _dragSession.feedbackSize ?? const Size(260, 64);
    final details = const BoardFlowCardDragDetails(
      isDragging: true,
      isGhost: false,
    );

    final child = widget.cardBuilder?.call(context, card, details) ??
        DefaultBoardCard<T>(
          card: card,
          theme: theme,
          isDragging: true,
        );

    final useSnap = widget.physics.snapFeedbackToPlaceholder &&
        _dragSession.snapAnchor != null &&
        _dragSession.snappedToForeignBoard;
    final left = useSnap
        ? _dragSession.snapAnchor!.dx
        : pos.dx - size.width / 2;
    final top = useSnap ? _dragSession.snapAnchor!.dy : pos.dy - 20;

    return Positioned(
      left: left,
      top: top,
      width: size.width,
      child: IgnorePointer(
        child: Opacity(
          opacity: _dragSession.rejected ? 0.45 : 0.95,
          child: Material(
            elevation: useSnap ? 10 : 8,
            shadowColor: useSnap
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.35)
                : Colors.black,
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            child: child,
          ),
        ),
      ),
    );
  }

  void _requestActiveBoard(String boardId) {
    setState(() => _localActiveBoardId = boardId);
    widget.controller?.setActiveBoard(boardId);
    widget.onActiveBoardChanged?.call(boardId);
    if (_dragSession.active && widget.physics.snapOnBoardEnter) {
      // After the new board paints, snap to its nearest/first column.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_dragSession.active) return;
        final pos = _dragSession.globalPosition;
        if (pos != null) {
          _dropRegistry.handlePointer(pos);
        }
      });
    }
  }

  void _handlePointerMove(Offset global) {
    if (!_dragSession.active) return;
    _dragSession.updatePosition(global);
    _dropRegistry.handlePointer(global);
    _handleTabHover(global);
  }

  void _handleTabHover(Offset global) {
    if (widget.layout != BoardFlowLayout.tabs) return;

    final boardId = _tabRegistry.boardIdAt(global);
    if (boardId != _hoveredTabBoardId) {
      setState(() => _hoveredTabBoardId = boardId);
    }

    if (boardId == null) {
      _tabSwitchTimer?.cancel();
      _pendingTabBoardId = null;
      return;
    }

    if (boardId == _activeBoardId) {
      _tabSwitchTimer?.cancel();
      _pendingTabBoardId = null;
      return;
    }

    if (_pendingTabBoardId != boardId) {
      _tabSwitchTimer?.cancel();
      _pendingTabBoardId = boardId;
      _tabSwitchTimer = Timer(widget.physics.tabHoverSwitchDelay, () {
        if (!mounted || !_dragSession.active) return;
        if (_pendingTabBoardId == boardId) {
          _requestActiveBoard(boardId);
        }
      });
    }
  }

  void _commitDrop() {
    _dropRegistry.stopAll();
    final move = buildMoveFromSession<T>(
      workspace: _workspace,
      session: _dragSession,
    );
    _dragSession.end();

    if (move == null) return;
    if (!_policies.accepts(move, _workspace)) return;
    if (move.fromBoardId == move.toBoardId &&
        move.fromColumnId == move.toColumnId &&
        move.fromIndex == move.toIndex) {
      return;
    }

    if (widget.controller != null) {
      widget.controller!.moveCard(move);
    }
    widget.onCardMoved?.call(move);
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme ?? BoardFlowTheme.fromContext(context);

    Widget body = BoardFlowScope<T>(
      workspace: _workspace,
      physics: widget.physics,
      policies: _policies,
      theme: theme,
      dragSession: _dragSession,
      layout: widget.layout,
      onCardMoved: (move) {
        if (widget.controller != null) {
          widget.controller!.moveCard(move);
        }
        widget.onCardMoved?.call(move);
      },
      onColumnReordered: (reorder) {
        if (widget.controller != null) {
          widget.controller!.reorderColumn(reorder);
        }
        widget.onColumnReordered?.call(reorder);
      },
      onActiveBoardChanged: widget.onActiveBoardChanged,
      cardBuilder: widget.cardBuilder,
      columnHeaderBuilder: widget.columnHeaderBuilder,
      columnFooterBuilder: widget.columnFooterBuilder,
      boardTabBuilder: widget.boardTabBuilder,
      emptyColumnBuilder: widget.emptyColumnBuilder,
      swimlaneHeaderBuilder: widget.swimlaneHeaderBuilder,
      requestActiveBoard: _requestActiveBoard,
      child: _buildLayout(context),
    );

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerMove: (event) {
        if (!_dragSession.active) return;
        if (_dragSession.pointerId != null &&
            event.pointer != _dragSession.pointerId) {
          return;
        }
        _handlePointerMove(event.position);
      },
      onPointerUp: (event) {
        if (!_dragSession.active) return;
        if (_dragSession.pointerId != null &&
            event.pointer != _dragSession.pointerId) {
          return;
        }
        _handlePointerMove(event.position);
        _commitDrop();
      },
      onPointerCancel: (event) {
        if (!_dragSession.active) return;
        if (_dragSession.pointerId != null &&
            event.pointer != _dragSession.pointerId) {
          return;
        }
        _dragSession.end();
        _dropRegistry.stopAll();
      },
      child: CompositedTransformTarget(
        link: _overlayLink,
        child: body,
      ),
    );
  }

  Widget _buildLayout(BuildContext context) {
    final boards = _workspace.boards;
    if (boards.isEmpty) {
      return const Center(child: Text('No boards'));
    }

    switch (widget.layout) {
      case BoardFlowLayout.sideBySide:
        return SideBySideLayout<T>(
          boards: boards,
          dropRegistry: _dropRegistry,
        );
      case BoardFlowLayout.tabs:
        final activeId = _activeBoardId;
        final board = _workspace.boardById(activeId) ?? boards.first;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BoardTabStripHit<T>(
              boards: boards,
              activeBoardId: board.id,
              registry: _tabRegistry,
              hoveredBoardId: _hoveredTabBoardId,
            ),
            Expanded(
              child: BoardCanvas<T>(
                boardId: board.id,
                columns: board.columns,
                swimlanes: board.swimlanes,
                dropRegistry: _dropRegistry,
              ),
            ),
          ],
        );
      case BoardFlowLayout.single:
        final board = boards.length == 1
            ? boards.first
            : (_workspace.boardById(_activeBoardId) ?? boards.first);
        return BoardCanvas<T>(
          boardId: board.id,
          columns: board.columns,
          swimlanes: board.swimlanes,
          dropRegistry: _dropRegistry,
        );
    }
  }
}
