import 'column.dart';
import 'swimlane.dart';

/// A single board containing columns (and optional swimlanes).
class BoardFlowBoard<T> {
  const BoardFlowBoard({
    required this.id,
    required this.title,
    this.columns = const [],
    this.swimlanes = const [],
  });

  final String id;
  final String title;
  final List<BoardFlowColumn<T>> columns;
  final List<BoardFlowSwimlane<T>> swimlanes;

  BoardFlowColumn<T>? columnById(String columnId) {
    for (final column in columns) {
      if (column.id == columnId) return column;
    }
    return null;
  }

  BoardFlowBoard<T> copyWith({
    String? id,
    String? title,
    List<BoardFlowColumn<T>>? columns,
    List<BoardFlowSwimlane<T>>? swimlanes,
  }) {
    return BoardFlowBoard<T>(
      id: id ?? this.id,
      title: title ?? this.title,
      columns: columns ?? this.columns,
      swimlanes: swimlanes ?? this.swimlanes,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is BoardFlowBoard<T> &&
        other.id == id &&
        other.title == title &&
        _listEquals(other.columns, columns) &&
        _listEquals(other.swimlanes, swimlanes);
  }

  @override
  int get hashCode => Object.hash(
        id,
        title,
        Object.hashAll(columns),
        Object.hashAll(swimlanes),
      );
}

bool _listEquals<E>(List<E> a, List<E> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
