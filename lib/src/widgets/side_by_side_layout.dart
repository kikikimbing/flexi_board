import 'package:flutter/material.dart';

import '../models/board.dart';
import 'board_canvas.dart';
import 'board_flow_scope.dart';

class SideBySideLayout<T> extends StatelessWidget {
  const SideBySideLayout({
    super.key,
    required this.boards,
    required this.dropRegistry,
  });

  final List<BoardFlowBoard<T>> boards;
  final DropRegistry<T> dropRegistry;

  @override
  Widget build(BuildContext context) {
    final scope = BoardFlowScope.of<T>(context);
    final theme = scope.theme;
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        for (var i = 0; i < boards.length; i++) ...[
          if (i > 0)
            VerticalDivider(
              width: 1,
              color: scheme.outlineVariant,
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  color: theme.columnHeaderColor ?? scheme.surfaceContainer,
                  child: Text(
                    boards[i].title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                Expanded(
                  child: BoardCanvas<T>(
                    boardId: boards[i].id,
                    columns: boards[i].columns,
                    swimlanes: boards[i].swimlanes,
                    dropRegistry: dropRegistry,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
