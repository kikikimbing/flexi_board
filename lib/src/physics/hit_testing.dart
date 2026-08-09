import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Finds a descendant render object of type [T] under [globalPosition].
T? hitTestDescendant<T extends RenderObject>({
  required BuildContext context,
  required Offset globalPosition,
}) {
  final box = context.findRenderObject();
  if (box is! RenderBox) return null;

  final result = BoxHitTestResult();
  final local = box.globalToLocal(globalPosition);
  if (!box.hitTest(result, position: local)) return null;

  for (final entry in result.path) {
    final target = entry.target;
    if (target is T) return target;
  }
  return null;
}

Rect? globalRectOf(BuildContext context) {
  final box = context.findRenderObject();
  if (box is! RenderBox || !box.hasSize || !box.attached) return null;
  final topLeft = box.localToGlobal(Offset.zero);
  return topLeft & box.size;
}
