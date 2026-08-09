import 'card.dart';

/// Horizontal grouping of cards via a filter.
class FlexiBoardSwimlane<T> {
  const FlexiBoardSwimlane({
    required this.id,
    required this.title,
    required this.filter,
    this.collapsed = false,
  });

  final String id;
  final String title;
  final bool Function(FlexiBoardCard<T> card) filter;
  final bool collapsed;

  FlexiBoardSwimlane<T> copyWith({
    String? id,
    String? title,
    bool Function(FlexiBoardCard<T> card)? filter,
    bool? collapsed,
  }) {
    return FlexiBoardSwimlane<T>(
      id: id ?? this.id,
      title: title ?? this.title,
      filter: filter ?? this.filter,
      collapsed: collapsed ?? this.collapsed,
    );
  }
}
