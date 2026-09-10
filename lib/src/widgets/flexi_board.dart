import 'dart:async';

import 'package:flutter/material.dart';

import '../controller/flexi_board_controller.dart';
import '../defaults/flexi_board_theme.dart';
import '../defaults/default_card.dart';
import '../models/drag_events.dart';
import '../models/move.dart';
import '../models/workspace.dart';
import '../physics/flexi_board_physics.dart';
import '../physics/drag_session.dart';
import '../policies/wip_policy.dart';
import 'board_canvas.dart';
import 'flexi_board_scope.dart';
import 'board_tab_strip.dart';
import 'paged_board_canvas.dart';
import 'side_by_side_layout.dart';

/// Plug-and-play multi-board drag-and-drop surface.
///
/// Hosts own data (or pass [controller]). Cards are fully customizable via
/// builders; when omitted, default Material chrome is used.
class FlexiBoard<T> extends StatefulWidget {
  const FlexiBoard({
    super.key,
    this.workspace,
    this.controller,
    this.layout = FlexiBoardLayout.single,
    this.activeBoardId,
    this.activeColumnId,
    this.physics = FlexiBoardPhysics.standard,
    this.policies,
    this.theme,
    this.cardBuilder,
    this.columnHeaderBuilder,
    this.columnFooterBuilder,
    this.boardTabBuilder,
    this.emptyColumnBuilder,
    this.swimlaneHeaderBuilder,
    this.onDrag,
    this.onDrop,
    this.onCardMoved,
    this.onColumnReordered,
    this.onActiveBoardChanged,
    this.onActiveColumnChanged,
  }) : assert(
          workspace != null || controller != null,
          'Provide workspace or controller',
        );

  /// Controlled data. Ignored when [controller] is non-null.
  final FlexiBoardWorkspace<T>? workspace;

  /// Optional convenience state owner with undo/redo.
  final FlexiBoardController<T>? controller;

  final FlexiBoardLayout layout;
  final String? activeBoardId;

  /// Initial / controlled column id for [FlexiBoardLayout.paged].
  final String? activeColumnId;

  final FlexiBoardPhysics physics;
  final FlexiBoardPolicies<T>? policies;
  final FlexiBoardTheme? theme;

  final FlexiBoardCardBuilder<T>? cardBuilder;
  final FlexiBoardColumnHeaderBuilder<T>? columnHeaderBuilder;
  final FlexiBoardColumnFooterBuilder<T>? columnFooterBuilder;
  final FlexiBoardBoardTabBuilder<T>? boardTabBuilder;
  final FlexiBoardEmptyColumnBuilder<T>? emptyColumnBuilder;
  final FlexiBoardSwimlaneHeaderBuilder<T>? swimlaneHeaderBuilder;

  /// Drag lifecycle: [FlexiBoardDragPhase.started] / [FlexiBoardDragPhase.updated].
  final FlexiBoardDragCallback<T>? onDrag;

  /// Drop result: accepted move or cancelled / rejected / no-op.
  final FlexiBoardDropCallback<T>? onDrop;

  /// Fired only when a drop is accepted (same move as [onDrop] when accepted).
  final ValueChanged<FlexiBoardMove<T>>? onCardMoved;
  final ValueChanged<FlexiBoardColumnReorder>? onColumnReordered;
  final ValueChanged<String>? onActiveBoardChanged;

  /// Fired when the paged layout changes the visible column (swipe or edge page).
  final ValueChanged<String>? onActiveColumnChanged;

  @override
  State<FlexiBoard<T>> createState() => _FlexiBoardState<T>();
}

class _FlexiBoardState<T> extends State<FlexiBoard<T>> {
  final DragSession _dragSession = DragSession();
  final DropRegistry<T> _dropRegistry = DropRegistry<T>();
  final TabHitRegistry _tabRegistry = TabHitRegistry();
  final LayerLink _overlayLink = LayerLink();

  OverlayEntry? _overlayEntry;
  Timer? _tabSwitchTimer;
  String? _pendingTabBoardId;
  String? _hoveredTabBoardId;
  String? _localActiveBoardId;

  bool _wasDragging = false;
  String? _lastHoverBoardId;
  String? _lastHoverColumnId;
  int? _lastHoverIndex;

  FlexiBoardWorkspace<T> get _workspace {
    if (widget.controller != null) return widget.controller!.workspace;
    return widget.workspace!;
  }

  String get _activeBoardId {
    return _localActiveBoardId ??
        widget.activeBoardId ??
        _workspace.resolvedActiveBoardId;
  }

  FlexiBoardPolicies<T> get _policies =>
      widget.policies ??
      widget.controller?.policies ??
      FlexiBoardPolicies<T>();

  @override
  void initState() {
    super.initState();
    _dragSession.addListener(_onDragSessionChanged);
    widget.controller?.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(covariant FlexiBoard<T> oldWidget) {
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
      if (!_wasDragging) {
        _wasDragging = true;
        _lastHoverBoardId = _dragSession.hoverBoardId;
        _lastHoverColumnId = _dragSession.hoverColumnId;
        _lastHoverIndex = _dragSession.hoverIndex;
        _emitDrag(FlexiBoardDragPhase.started);
      } else {
        final hoverChanged = _dragSession.hoverBoardId != _lastHoverBoardId ||
            _dragSession.hoverColumnId != _lastHoverColumnId ||
            _dragSession.hoverIndex != _lastHoverIndex;
        if (hoverChanged) {
          _lastHoverBoardId = _dragSession.hoverBoardId;
          _lastHoverColumnId = _dragSession.hoverColumnId;
          _lastHoverIndex = _dragSession.hoverIndex;
          _emitDrag(FlexiBoardDragPhase.updated);
        }
      }
      _ensureOverlay();
      _overlayEntry?.markNeedsBuild();
    } else {
      _wasDragging = false;
      _lastHoverBoardId = null;
      _lastHoverColumnId = null;
      _lastHoverIndex = null;
      _removeOverlay();
      _tabSwitchTimer?.cancel();
      _pendingTabBoardId = null;
      if (_hoveredTabBoardId != null) {
        setState(() => _hoveredTabBoardId = null);
      }
    }
  }

  void _emitDrag(FlexiBoardDragPhase phase) {
    final callback = widget.onDrag;
    if (callback == null) return;
    final cardId = _dragSession.cardId;
    if (cardId == null ||
        _dragSession.fromBoardId == null ||
        _dragSession.fromColumnId == null ||
        _dragSession.fromIndex == null ||
        _dragSession.globalPosition == null) {
      return;
    }
    final card = findCardInWorkspace<T>(_workspace.boards, cardId);
    if (card == null) return;
    callback(
      FlexiBoardDragDetails<T>(
        phase: phase,
        card: card,
        boardId: _dragSession.fromBoardId!,
        columnId: _dragSession.fromColumnId!,
        index: _dragSession.fromIndex!,
        globalPosition: _dragSession.globalPosition!,
        hoverBoardId: _dragSession.hoverBoardId,
        hoverColumnId: _dragSession.hoverColumnId,
        hoverIndex: _dragSession.hoverIndex,
        rejected: _dragSession.rejected,
      ),
    );
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

    final card =
        findCardInWorkspace<T>(_workspace.boards, _dragSession.cardId!);
    if (card == null) return const SizedBox.shrink();

    final theme = widget.theme ?? FlexiBoardTheme.fromContext(context);
    final size = _dragSession.feedbackSize ?? const Size(260, 64);
    final details = const FlexiBoardCardDragDetails(
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
    final left =
        useSnap ? _dragSession.snapAnchor!.dx : pos.dx - size.width / 2;
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
    if (widget.layout != FlexiBoardLayout.tabs) return;

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
    final cardId = _dragSession.cardId;
    final fromBoardId = _dragSession.fromBoardId;
    final fromColumnId = _dragSession.fromColumnId;
    final fromIndex = _dragSession.fromIndex;
    final pos = _dragSession.globalPosition ?? Offset.zero;
    final card = cardId == null
        ? null
        : findCardInWorkspace<T>(_workspace.boards, cardId);
    final move = buildMoveFromSession<T>(
      workspace: _workspace,
      session: _dragSession,
    );
    _dragSession.end();

    if (card == null) return;

    final accepted = move != null &&
        _policies.accepts(move, _workspace) &&
        !(move.fromBoardId == move.toBoardId &&
            move.fromColumnId == move.toColumnId &&
            move.fromIndex == move.toIndex);

    if (!accepted) {
      widget.onDrag?.call(
        FlexiBoardDragDetails<T>(
          phase: FlexiBoardDragPhase.cancelled,
          card: card,
          boardId: fromBoardId ?? move?.fromBoardId ?? '',
          columnId: fromColumnId ?? move?.fromColumnId ?? '',
          index: fromIndex ?? move?.fromIndex ?? 0,
          globalPosition: pos,
        ),
      );
      widget.onDrop?.call(
        FlexiBoardDropDetails<T>(
          card: card,
          accepted: false,
          move: null,
        ),
      );
      return;
    }

    if (widget.controller != null) {
      widget.controller!.moveCard(move);
    }
    widget.onDrop?.call(
      FlexiBoardDropDetails<T>(
        card: card,
        accepted: true,
        move: move,
      ),
    );
    widget.onCardMoved?.call(move);
  }

  void _cancelDrag() {
    _dropRegistry.stopAll();
    final cardId = _dragSession.cardId;
    final card = cardId == null
        ? null
        : findCardInWorkspace<T>(_workspace.boards, cardId);
    final fromBoardId = _dragSession.fromBoardId;
    final fromColumnId = _dragSession.fromColumnId;
    final fromIndex = _dragSession.fromIndex;
    final pos = _dragSession.globalPosition ?? Offset.zero;
    _dragSession.end();

    if (card == null ||
        fromBoardId == null ||
        fromColumnId == null ||
        fromIndex == null) {
      return;
    }

    widget.onDrag?.call(
      FlexiBoardDragDetails<T>(
        phase: FlexiBoardDragPhase.cancelled,
        card: card,
        boardId: fromBoardId,
        columnId: fromColumnId,
        index: fromIndex,
        globalPosition: pos,
      ),
    );
    widget.onDrop?.call(
      FlexiBoardDropDetails<T>(
        card: card,
        accepted: false,
        move: null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme ?? FlexiBoardTheme.fromContext(context);

    final body = FlexiBoardScope<T>(
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
        _cancelDrag();
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
      case FlexiBoardLayout.sideBySide:
        return SideBySideLayout<T>(
          boards: boards,
          dropRegistry: _dropRegistry,
        );
      case FlexiBoardLayout.tabs:
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
      case FlexiBoardLayout.paged:
        final board = boards.length == 1
            ? boards.first
            : (_workspace.boardById(_activeBoardId) ?? boards.first);
        return PagedBoardCanvas<T>(
          boardId: board.id,
          columns: board.columns,
          dropRegistry: _dropRegistry,
          activeColumnId: widget.activeColumnId,
          onActiveColumnChanged: widget.onActiveColumnChanged,
        );
      case FlexiBoardLayout.single:
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
