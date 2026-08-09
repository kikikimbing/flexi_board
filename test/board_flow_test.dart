import 'package:board_flow/board_flow.dart';
import 'package:flutter_test/flutter_test.dart';

BoardFlowWorkspace<String> sampleWorkspace() {
  return BoardFlowWorkspace<String>(
    activeBoardId: 'b1',
    boards: [
      BoardFlowBoard<String>(
        id: 'b1',
        title: 'Product',
        columns: [
          BoardFlowColumn<String>(
            id: 'todo',
            title: 'Todo',
            cards: const [
              BoardFlowCard(id: 'c1', data: 'Task 1'),
              BoardFlowCard(id: 'c2', data: 'Task 2'),
            ],
          ),
          BoardFlowColumn<String>(
            id: 'doing',
            title: 'Doing',
            wipLimit: 1,
            cards: const [
              BoardFlowCard(id: 'c3', data: 'Task 3'),
            ],
          ),
          const BoardFlowColumn<String>(
            id: 'done',
            title: 'Done',
          ),
        ],
      ),
      BoardFlowBoard<String>(
        id: 'b2',
        title: 'Marketing',
        columns: [
          BoardFlowColumn<String>(
            id: 'ideas',
            title: 'Ideas',
            cards: const [
              BoardFlowCard(id: 'm1', data: 'Campaign'),
            ],
          ),
          const BoardFlowColumn<String>(
            id: 'shipped',
            title: 'Shipped',
          ),
        ],
      ),
    ],
  );
}

void main() {
  group('BoardFlowWorkspace.applyMove', () {
    test('reorders within the same column', () {
      final ws = sampleWorkspace();
      final move = BoardFlowMove<String>(
        card: ws.boards.first.columns.first.cards.first,
        fromBoardId: 'b1',
        toBoardId: 'b1',
        fromColumnId: 'todo',
        toColumnId: 'todo',
        fromIndex: 0,
        toIndex: 1,
      );
      final next = ws.applyMove(move);
      expect(next.boards.first.columns.first.cards.map((c) => c.id), ['c2', 'c1']);
    });

    test('moves across columns on the same board', () {
      final ws = sampleWorkspace();
      final move = BoardFlowMove<String>(
        card: ws.boards.first.columns.first.cards.first,
        fromBoardId: 'b1',
        toBoardId: 'b1',
        fromColumnId: 'todo',
        toColumnId: 'done',
        fromIndex: 0,
        toIndex: 0,
      );
      final next = ws.applyMove(move);
      expect(next.boards.first.columnById('todo')!.cards.map((c) => c.id), ['c2']);
      expect(next.boards.first.columnById('done')!.cards.map((c) => c.id), ['c1']);
    });

    test('moves across boards', () {
      final ws = sampleWorkspace();
      final move = BoardFlowMove<String>(
        card: ws.boards.first.columns.first.cards.first,
        fromBoardId: 'b1',
        toBoardId: 'b2',
        fromColumnId: 'todo',
        toColumnId: 'ideas',
        fromIndex: 0,
        toIndex: 1,
      );
      final next = ws.applyMove(move);
      expect(next.boardById('b1')!.columnById('todo')!.cards.map((c) => c.id), ['c2']);
      expect(
        next.boardById('b2')!.columnById('ideas')!.cards.map((c) => c.id),
        ['m1', 'c1'],
      );
    });
  });

  group('WIP policy', () {
    test('rejects drop into full column', () {
      final ws = sampleWorkspace();
      final policies = BoardFlowPolicies<String>();
      final move = BoardFlowMove<String>(
        card: ws.boards.first.columns.first.cards.first,
        fromBoardId: 'b1',
        toBoardId: 'b1',
        fromColumnId: 'todo',
        toColumnId: 'doing',
        fromIndex: 0,
        toIndex: 0,
      );
      expect(policies.accepts(move, ws), isFalse);
    });

    test('allows same-column reorder even at WIP', () {
      final ws = sampleWorkspace();
      final policies = BoardFlowPolicies<String>();
      final move = BoardFlowMove<String>(
        card: ws.boards.first.columnById('doing')!.cards.first,
        fromBoardId: 'b1',
        toBoardId: 'b1',
        fromColumnId: 'doing',
        toColumnId: 'doing',
        fromIndex: 0,
        toIndex: 0,
      );
      expect(policies.accepts(move, ws), isTrue);
    });
  });

  group('BoardFlowController', () {
    test('undo and redo restore workspace', () {
      final controller = BoardFlowController<String>(
        initial: sampleWorkspace(),
      );
      final move = BoardFlowMove<String>(
        card: controller.workspace.boards.first.columns.first.cards.first,
        fromBoardId: 'b1',
        toBoardId: 'b1',
        fromColumnId: 'todo',
        toColumnId: 'done',
        fromIndex: 0,
        toIndex: 0,
      );
      expect(controller.moveCard(move), isTrue);
      expect(controller.canUndo, isTrue);
      controller.undo();
      expect(
        controller.workspace.boardById('b1')!.columnById('todo')!.cards.length,
        2,
      );
      controller.redo();
      expect(
        controller.workspace.boardById('b1')!.columnById('done')!.cards.map((c) => c.id),
        ['c1'],
      );
    });

    test('column reorder', () {
      final controller = BoardFlowController<String>(
        initial: sampleWorkspace(),
      );
      expect(
        controller.reorderColumn(
          const BoardFlowColumnReorder(
            boardId: 'b1',
            fromIndex: 0,
            toIndex: 2,
          ),
        ),
        isTrue,
      );
      expect(
        controller.workspace.boardById('b1')!.columns.map((c) => c.id),
        ['doing', 'done', 'todo'],
      );
    });
  });

  group('computeInsertIndex', () {
    test('returns 0 for empty list', () {
      expect(
        computeInsertIndex(
          localY: 10,
          itemCenters: const [],
          itemCount: 0,
        ),
        0,
      );
    });

    test('inserts before first center', () {
      expect(
        computeInsertIndex(
          localY: 5,
          itemCenters: const [20, 40, 60],
          itemCount: 3,
        ),
        0,
      );
    });

    test('adjusts for same-column drag', () {
      expect(
        computeInsertIndex(
          localY: 50,
          itemCenters: const [20, 40, 60],
          itemCount: 3,
          draggingFromIndex: 0,
          sameColumn: true,
        ),
        1,
      );
    });
  });
}
