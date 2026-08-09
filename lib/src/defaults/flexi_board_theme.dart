import 'package:flutter/material.dart';

/// Visual tokens for default board chrome.
class FlexiBoardTheme {
  const FlexiBoardTheme({
    this.boardBackgroundColor,
    this.columnBackgroundColor,
    this.columnHeaderColor,
    this.cardBackgroundColor,
    this.cardBorderColor,
    this.placeholderColor,
    this.rejectedColor,
    this.wipWarningColor,
    this.wipExceededColor,
    this.tabSelectedColor,
    this.tabUnselectedColor,
    this.columnBorderRadius = 12,
    this.cardBorderRadius = 10,
    this.cardElevation = 1,
  });

  final Color? boardBackgroundColor;
  final Color? columnBackgroundColor;
  final Color? columnHeaderColor;
  final Color? cardBackgroundColor;
  final Color? cardBorderColor;
  final Color? placeholderColor;
  final Color? rejectedColor;
  final Color? wipWarningColor;
  final Color? wipExceededColor;
  final Color? tabSelectedColor;
  final Color? tabUnselectedColor;
  final double columnBorderRadius;
  final double cardBorderRadius;
  final double cardElevation;

  factory FlexiBoardTheme.fromContext(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FlexiBoardTheme(
      boardBackgroundColor: scheme.surfaceContainerLowest,
      columnBackgroundColor: scheme.surfaceContainerLow,
      columnHeaderColor: scheme.surfaceContainer,
      cardBackgroundColor: scheme.surface,
      cardBorderColor: scheme.outlineVariant,
      placeholderColor: scheme.primary.withValues(alpha: 0.18),
      rejectedColor: scheme.error.withValues(alpha: 0.2),
      wipWarningColor: scheme.tertiary,
      wipExceededColor: scheme.error,
      tabSelectedColor: scheme.primaryContainer,
      tabUnselectedColor: scheme.surfaceContainerHigh,
    );
  }

  FlexiBoardTheme copyWith({
    Color? boardBackgroundColor,
    Color? columnBackgroundColor,
    Color? columnHeaderColor,
    Color? cardBackgroundColor,
    Color? cardBorderColor,
    Color? placeholderColor,
    Color? rejectedColor,
    Color? wipWarningColor,
    Color? wipExceededColor,
    Color? tabSelectedColor,
    Color? tabUnselectedColor,
    double? columnBorderRadius,
    double? cardBorderRadius,
    double? cardElevation,
  }) {
    return FlexiBoardTheme(
      boardBackgroundColor: boardBackgroundColor ?? this.boardBackgroundColor,
      columnBackgroundColor:
          columnBackgroundColor ?? this.columnBackgroundColor,
      columnHeaderColor: columnHeaderColor ?? this.columnHeaderColor,
      cardBackgroundColor: cardBackgroundColor ?? this.cardBackgroundColor,
      cardBorderColor: cardBorderColor ?? this.cardBorderColor,
      placeholderColor: placeholderColor ?? this.placeholderColor,
      rejectedColor: rejectedColor ?? this.rejectedColor,
      wipWarningColor: wipWarningColor ?? this.wipWarningColor,
      wipExceededColor: wipExceededColor ?? this.wipExceededColor,
      tabSelectedColor: tabSelectedColor ?? this.tabSelectedColor,
      tabUnselectedColor: tabUnselectedColor ?? this.tabUnselectedColor,
      columnBorderRadius: columnBorderRadius ?? this.columnBorderRadius,
      cardBorderRadius: cardBorderRadius ?? this.cardBorderRadius,
      cardElevation: cardElevation ?? this.cardElevation,
    );
  }
}
