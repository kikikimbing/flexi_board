import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:board_flow/board_flow.dart';

void main() {
  testWidgets('renders default cards for a single board', (tester) async {
    final controller = BoardFlowController<String>(
      initial: BoardFlowWorkspace<String>(
        boards: [
          BoardFlowBoard<String>(
            id: 'b1',
            title: 'Main',
            columns: [
              BoardFlowColumn<String>(
                id: 'todo',
                title: 'Todo',
                cards: const [
                  BoardFlowCard(id: 'c1', data: 'Hello card'),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BoardFlow<String>(
            controller: controller,
            layout: BoardFlowLayout.single,
          ),
        ),
      ),
    );

    expect(find.text('Hello card'), findsOneWidget);
    expect(find.text('Todo'), findsOneWidget);
  });

  testWidgets('custom cardBuilder overrides default UI', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BoardFlow<String>(
            workspace: BoardFlowWorkspace<String>(
              boards: [
                BoardFlowBoard<String>(
                  id: 'b1',
                  title: 'Main',
                  columns: [
                    BoardFlowColumn<String>(
                      id: 'todo',
                      title: 'Todo',
                      cards: const [
                        BoardFlowCard(id: 'c1', data: 'X'),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            cardBuilder: (context, card, details) {
              return Text('custom:${card.data}');
            },
          ),
        ),
      ),
    );

    expect(find.text('custom:X'), findsOneWidget);
    expect(find.text('X'), findsNothing);
  });

  testWidgets('tabs layout shows board titles', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BoardFlow<String>(
            workspace: BoardFlowWorkspace<String>(
              activeBoardId: 'a',
              boards: const [
                BoardFlowBoard(
                  id: 'a',
                  title: 'Alpha',
                  columns: [
                    BoardFlowColumn(
                      id: 'c',
                      title: 'Col A',
                      cards: [
                        BoardFlowCard(id: '1', data: 'Alpha card'),
                      ],
                    ),
                  ],
                ),
                BoardFlowBoard(
                  id: 'b',
                  title: 'Beta',
                  columns: [
                    BoardFlowColumn(
                      id: 'c',
                      title: 'Col B',
                      cards: [
                        BoardFlowCard(id: '2', data: 'Beta card'),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            layout: BoardFlowLayout.tabs,
          ),
        ),
      ),
    );

    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Beta'), findsOneWidget);
    expect(find.text('Alpha card'), findsOneWidget);
    expect(find.text('Beta card'), findsNothing);

    await tester.tap(find.text('Beta'));
    await tester.pumpAndSettle();

    expect(find.text('Beta card'), findsOneWidget);
    expect(find.text('Alpha card'), findsNothing);
  });

  testWidgets('custom boardTabBuilder still switches boards on tap', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BoardFlow<String>(
            workspace: BoardFlowWorkspace<String>(
              activeBoardId: 'a',
              boards: const [
                BoardFlowBoard(
                  id: 'a',
                  title: 'Alpha',
                  columns: [
                    BoardFlowColumn(
                      id: 'c',
                      title: 'Col',
                      cards: [BoardFlowCard(id: '1', data: 'A')],
                    ),
                  ],
                ),
                BoardFlowBoard(
                  id: 'b',
                  title: 'Beta',
                  columns: [
                    BoardFlowColumn(
                      id: 'c',
                      title: 'Col',
                      cards: [BoardFlowCard(id: '2', data: 'B')],
                    ),
                  ],
                ),
              ],
            ),
            layout: BoardFlowLayout.tabs,
            boardTabBuilder: (context, board, selected, dragHover) {
              return Text(board.title);
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Beta'));
    await tester.pumpAndSettle();
    expect(find.text('B'), findsOneWidget);
  });

  test('drag and drop detail types expose phase and acceptance', () {
    const card = BoardFlowCard<String>(id: 'c1', data: 'Task');
    const drag = BoardFlowDragDetails<String>(
      phase: BoardFlowDragPhase.started,
      card: card,
      boardId: 'b1',
      columnId: 'todo',
      index: 0,
      globalPosition: Offset.zero,
    );
    expect(drag.phase, BoardFlowDragPhase.started);

    const drop = BoardFlowDropDetails<String>(
      card: card,
      accepted: false,
    );
    expect(drop.accepted, isFalse);
    expect(drop.move, isNull);
  });
}
