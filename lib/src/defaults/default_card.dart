import 'package:flutter/material.dart';

import '../models/card.dart';
import 'board_flow_theme.dart';

/// Default card chrome when [cardBuilder] is omitted.
class DefaultBoardCard<T> extends StatelessWidget {
  const DefaultBoardCard({
    super.key,
    required this.card,
    required this.theme,
    this.isDragging = false,
    this.isSelected = false,
  });

  final BoardFlowCard<T> card;
  final BoardFlowTheme theme;
  final bool isDragging;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final text = '${card.data}';
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: theme.cardBackgroundColor ?? scheme.surface,
      elevation: isDragging ? 6 : theme.cardElevation,
      borderRadius: BorderRadius.circular(theme.cardBorderRadius),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(theme.cardBorderRadius),
          border: Border.all(
            color: isSelected
                ? scheme.primary
                : (theme.cardBorderColor ?? scheme.outlineVariant),
          ),
        ),
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}
