/// A card on a board column.
///
/// [T] is arbitrary host data. The package never inspects it.
class FlexiBoardCard<T> {
  const FlexiBoardCard({
    required this.id,
    required this.data,
    this.columnId,
    this.boardId,
  });

  final String id;
  final T data;

  /// Optional convenience fields; layout is owned by columns.
  final String? columnId;
  final String? boardId;

  FlexiBoardCard<T> copyWith({
    String? id,
    T? data,
    String? columnId,
    String? boardId,
  }) {
    return FlexiBoardCard<T>(
      id: id ?? this.id,
      data: data ?? this.data,
      columnId: columnId ?? this.columnId,
      boardId: boardId ?? this.boardId,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is FlexiBoardCard<T> &&
        other.id == id &&
        other.data == data &&
        other.columnId == columnId &&
        other.boardId == boardId;
  }

  @override
  int get hashCode => Object.hash(id, data, columnId, boardId);
}
