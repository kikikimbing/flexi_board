import 'package:flutter/material.dart';

import '../defaults/default_card.dart';
import '../models/card.dart';
import 'flexi_board_scope.dart';

class BoardCardSlot<T> extends StatefulWidget {
  const BoardCardSlot({
    super.key,
    required this.boardId,
    required this.columnId,
    required this.index,
    required this.card,
  });

  final String boardId;
  final String columnId;
  final int index;
  final FlexiBoardCard<T> card;

  @override
  State<BoardCardSlot<T>> createState() => _BoardCardSlotState<T>();
}

class _BoardCardSlotState<T> extends State<BoardCardSlot<T>> {
  int? _pointer;
  bool _dragging = false;
  bool _cancelled = false;
  Offset? _startPosition;
  final GlobalKey _key = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final scope = FlexiBoardScope.of<T>(context);
    final session = scope.dragSession;
    final isGhost = session.active && session.cardId == widget.card.id;
    final details = FlexiBoardCardDragDetails(
      isDragging: isGhost,
      isGhost: isGhost,
    );

    final child = scope.cardBuilder?.call(context, widget.card, details) ??
        DefaultBoardCard<T>(
          card: widget.card,
          theme: scope.theme,
          isDragging: isGhost,
        );

    return Listener(
      onPointerDown: (event) {
        _pointer = event.pointer;
        _startPosition = event.position;
        _dragging = false;
        _cancelled = false;
        final pointer = event.pointer;
        final position = event.position;
        Future<void>.delayed(scope.physics.longPressDelay, () {
          if (!mounted ||
              _pointer != pointer ||
              _cancelled ||
              _startPosition == null) {
            return;
          }
          if (scope.dragSession.active) return;
          if (!scope.policies.allowsStartDrag(widget.card, scope.workspace)) {
            _cancelled = true;
            _pointer = null;
            _startPosition = null;
            return;
          }
          final box = _key.currentContext?.findRenderObject() as RenderBox?;
          final size = box?.size ?? const Size(240, 64);
          setState(() => _dragging = true);
          scope.dragSession.start(
            cardId: widget.card.id,
            boardId: widget.boardId,
            columnId: widget.columnId,
            index: widget.index,
            globalPosition: position,
            pointerId: pointer,
            feedbackSize: size,
          );
        });
      },
      onPointerMove: (event) {
        if (_pointer != event.pointer) return;
        if (_dragging) return;
        if (_startPosition != null) {
          final distance = (event.position - _startPosition!).distance;
          if (distance > 18) {
            _cancelled = true;
            _pointer = null;
            _startPosition = null;
          }
        }
      },
      onPointerUp: (event) {
        if (_pointer != event.pointer) return;
        if (!_dragging) {
          _cancelled = true;
        }
        _pointer = null;
        _startPosition = null;
        if (_dragging && mounted) {
          setState(() => _dragging = false);
        }
      },
      onPointerCancel: (event) {
        if (_pointer != event.pointer) return;
        _cancelled = true;
        _pointer = null;
        _startPosition = null;
        if (_dragging && mounted) {
          setState(() => _dragging = false);
        }
      },
      child: KeyedSubtree(key: _key, child: child),
    );
  }
}
