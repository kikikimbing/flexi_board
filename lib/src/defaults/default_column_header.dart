import 'package:flutter/material.dart';

import '../models/column.dart';
import '../policies/wip_policy.dart';
import 'board_flow_theme.dart';

/// Default column header when [columnHeaderBuilder] is omitted.
class DefaultColumnHeader<T> extends StatelessWidget {
  const DefaultColumnHeader({
    super.key,
    required this.column,
    required this.theme,
    this.policies,
  });

  final BoardFlowColumn<T> column;
  final BoardFlowTheme theme;
  final BoardFlowPolicies<T>? policies;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final limit = column.wipLimit;
    Color? badgeColor;
    if (limit != null && policies != null) {
      if (column.isOverWipLimit || policies!.isAtCapacity(column)) {
        badgeColor = theme.wipExceededColor ?? scheme.error;
      } else if (policies!.isApproachingCapacity(column)) {
        badgeColor = theme.wipWarningColor ?? scheme.tertiary;
      }
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      decoration: BoxDecoration(
        color: theme.columnHeaderColor ?? scheme.surfaceContainer,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(theme.columnBorderRadius),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              column.title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: badgeColor?.withValues(alpha: 0.15) ??
                  scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              limit == null
                  ? '${column.cardCount}'
                  : '${column.cardCount}/$limit',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: badgeColor ?? scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
