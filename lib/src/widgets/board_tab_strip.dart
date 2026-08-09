import 'package:flutter/material.dart';

import '../defaults/default_tab.dart';
import '../models/board.dart';
import 'board_flow_scope.dart';

/// Global keys used by BoardFlow to detect tab hover while dragging.
class TabHitRegistry {
  final Map<String, GlobalKey> keys = {};

  GlobalKey keyFor(String boardId) =>
      keys.putIfAbsent(boardId, GlobalKey.new);

  String? boardIdAt(Offset global) {
    for (final entry in keys.entries) {
      final ctx = entry.value.currentContext;
      if (ctx == null) continue;
      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize || !box.attached) continue;
      final rect = box.localToGlobal(Offset.zero) & box.size;
      if (rect.contains(global)) return entry.key;
    }
    return null;
  }
}

/// Tab strip that registers hit targets.
class BoardTabStripHit<T> extends StatelessWidget {
  const BoardTabStripHit({
    super.key,
    required this.boards,
    required this.activeBoardId,
    required this.registry,
    this.hoveredBoardId,
  });

  final List<BoardFlowBoard<T>> boards;
  final String activeBoardId;
  final TabHitRegistry registry;
  final String? hoveredBoardId;

  @override
  Widget build(BuildContext context) {
    final scope = BoardFlowScope.of<T>(context);

    return SizedBox(
      height: 52,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
        itemCount: boards.length,
        itemBuilder: (context, index) {
          final board = boards[index];
          final selected = board.id == activeBoardId;
          final dragHover = board.id == hoveredBoardId;

          final tab = scope.boardTabBuilder?.call(
                context,
                board,
                selected,
                dragHover,
              ) ??
              DefaultBoardTab<T>(
                board: board,
                selected: selected,
                dragHover: dragHover,
                theme: scope.theme,
              );

          // Always own selection taps so custom tab builders stay visual-only.
          return KeyedSubtree(
            key: registry.keyFor(board.id),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => scope.requestActiveBoard(board.id),
              child: tab,
            ),
          );
        },
      ),
    );
  }
}
