import 'card.dart';

/// Horizontal grouping of cards via a filter.
class BoardFlowSwimlane<T> {
  const BoardFlowSwimlane({
    required this.id,
    required this.title,
    required this.filter,
    this.collapsed = false,
  });

  final String id;
  final String title;
  final bool Function(BoardFlowCard<T> card) filter;
  final bool collapsed;

  BoardFlowSwimlane<T> copyWith({
    String? id,
    String? title,
    bool Function(BoardFlowCard<T> card)? filter,
    bool? collapsed,
  }) {
    return BoardFlowSwimlane<T>(
      id: id ?? this.id,
      title: title ?? this.title,
      filter: filter ?? this.filter,
      collapsed: collapsed ?? this.collapsed,
    );
  }
}
