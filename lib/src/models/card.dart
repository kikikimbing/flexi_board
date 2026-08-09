/// A card on a board column.
///
/// [T] is arbitrary host data. The package never inspects it.
class BoardFlowCard<T> {
  const BoardFlowCard({
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

  BoardFlowCard<T> copyWith({
    String? id,
    T? data,
    String? columnId,
    String? boardId,
  }) {
    return BoardFlowCard<T>(
      id: id ?? this.id,
      data: data ?? this.data,
      columnId: columnId ?? this.columnId,
      boardId: boardId ?? this.boardId,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is BoardFlowCard<T> &&
        other.id == id &&
        other.data == data &&
        other.columnId == columnId &&
        other.boardId == boardId;
  }

  @override
  int get hashCode => Object.hash(id, data, columnId, boardId);
}
