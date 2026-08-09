import 'package:flutter/material.dart';

import '../models/board.dart';
import 'flexi_board_theme.dart';

/// Default board tab when [boardTabBuilder] is omitted.
class DefaultBoardTab<T> extends StatelessWidget {
  const DefaultBoardTab({
    super.key,
    required this.board,
    required this.selected,
    required this.theme,
    this.dragHover = false,
    this.onTap,
  });

  final FlexiBoardBoard<T> board;
  final bool selected;
  final bool dragHover;
  final FlexiBoardTheme theme;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = selected
        ? (theme.tabSelectedColor ?? scheme.primaryContainer)
        : (theme.tabUnselectedColor ?? scheme.surfaceContainerHigh);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: dragHover ? scheme.primary.withValues(alpha: 0.2) : bg,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Text(
              board.title,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
