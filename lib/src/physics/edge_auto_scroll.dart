import 'dart:async';

import 'package:flutter/widgets.dart';

import 'flexi_board_physics.dart';

/// Scrolls a [ScrollController] when the pointer is near an edge.
class EdgeAutoScroller {
  EdgeAutoScroller({
    required this.controller,
    required this.physics,
    this.axis = Axis.horizontal,
  });

  final ScrollController controller;
  final FlexiBoardPhysics physics;
  final Axis axis;

  Timer? _timer;
  double _speed = 0;

  void updatePointer({
    required Offset globalPosition,
    required Rect viewportGlobal,
  }) {
    if (!controller.hasClients) return;

    final local = axis == Axis.horizontal
        ? globalPosition.dx - viewportGlobal.left
        : globalPosition.dy - viewportGlobal.top;
    final extent =
        axis == Axis.horizontal ? viewportGlobal.width : viewportGlobal.height;

    double speed = 0;
    if (local < physics.farScrollExtent) {
      if (local < physics.edgeScrollExtent) {
        speed = -physics.edgeScrollSpeed;
      } else if (local < physics.midScrollExtent) {
        speed = -physics.midScrollSpeed;
      } else {
        speed = -physics.farScrollSpeed;
      }
    } else if (local > extent - physics.farScrollExtent) {
      final fromEnd = extent - local;
      if (fromEnd < physics.edgeScrollExtent) {
        speed = physics.edgeScrollSpeed;
      } else if (fromEnd < physics.midScrollExtent) {
        speed = physics.midScrollSpeed;
      } else {
        speed = physics.farScrollSpeed;
      }
    }

    _speed = speed;
    if (_speed == 0) {
      stop();
    } else {
      _ensureTimer();
    }
  }

  void _ensureTimer() {
    _timer ??= Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!controller.hasClients || _speed == 0) {
        stop();
        return;
      }
      final next = (controller.offset + _speed).clamp(
        controller.position.minScrollExtent,
        controller.position.maxScrollExtent,
      );
      if (next != controller.offset) {
        controller.jumpTo(next);
      }
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _speed = 0;
  }

  void dispose() => stop();
}

/// Computes insert index from a Y position within a card list.
int computeInsertIndex({
  required double localY,
  required List<double> itemCenters,
  required int itemCount,
  int? draggingFromIndex,
  bool sameColumn = false,
}) {
  if (itemCount == 0) return 0;
  if (itemCenters.isEmpty) return itemCount;

  for (var i = 0; i < itemCenters.length; i++) {
    if (localY < itemCenters[i]) {
      var index = i;
      if (sameColumn &&
          draggingFromIndex != null &&
          draggingFromIndex < index) {
        index -= 1;
      }
      return index.clamp(0, itemCount - (sameColumn ? 1 : 0));
    }
  }

  if (sameColumn && draggingFromIndex != null) {
    return (itemCount - 1).clamp(0, itemCount - 1);
  }
  return itemCount;
}
