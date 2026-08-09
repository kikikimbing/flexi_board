import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flexi_board/flexi_board.dart';

void main() {
  testWidgets('renders default cards for a single board', (tester) async {
    final controller = FlexiBoardController<String>(
      initial: FlexiBoardWorkspace<String>(
        boards: [
          FlexiBoardBoard<String>(
            id: 'b1',
            title: 'Main',
            columns: [
              FlexiBoardColumn<String>(
                id: 'todo',
                title: 'Todo',
                cards: const [
                  FlexiBoardCard(id: 'c1', data: 'Hello card'),
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
          body: FlexiBoard<String>(
            controller: controller,
            layout: FlexiBoardLayout.single,
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
          body: FlexiBoard<String>(
            workspace: FlexiBoardWorkspace<String>(
              boards: [
                FlexiBoardBoard<String>(
                  id: 'b1',
                  title: 'Main',
                  columns: [
                    FlexiBoardColumn<String>(
                      id: 'todo',
                      title: 'Todo',
                      cards: const [
                        FlexiBoardCard(id: 'c1', data: 'X'),
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
          body: FlexiBoard<String>(
            workspace: FlexiBoardWorkspace<String>(
              activeBoardId: 'a',
              boards: const [
                FlexiBoardBoard(
                  id: 'a',
                  title: 'Alpha',
                  columns: [
                    FlexiBoardColumn(
                      id: 'c',
                      title: 'Col A',
                      cards: [
                        FlexiBoardCard(id: '1', data: 'Alpha card'),
                      ],
                    ),
                  ],
                ),
                FlexiBoardBoard(
                  id: 'b',
                  title: 'Beta',
                  columns: [
                    FlexiBoardColumn(
                      id: 'c',
                      title: 'Col B',
                      cards: [
                        FlexiBoardCard(id: '2', data: 'Beta card'),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            layout: FlexiBoardLayout.tabs,
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
          body: FlexiBoard<String>(
            workspace: FlexiBoardWorkspace<String>(
              activeBoardId: 'a',
              boards: const [
                FlexiBoardBoard(
                  id: 'a',
                  title: 'Alpha',
                  columns: [
                    FlexiBoardColumn(
                      id: 'c',
                      title: 'Col',
                      cards: [FlexiBoardCard(id: '1', data: 'A')],
                    ),
                  ],
                ),
                FlexiBoardBoard(
                  id: 'b',
                  title: 'Beta',
                  columns: [
                    FlexiBoardColumn(
                      id: 'c',
                      title: 'Col',
                      cards: [FlexiBoardCard(id: '2', data: 'B')],
                    ),
                  ],
                ),
              ],
            ),
            layout: FlexiBoardLayout.tabs,
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
    const card = FlexiBoardCard<String>(id: 'c1', data: 'Task');
    const drag = FlexiBoardDragDetails<String>(
      phase: FlexiBoardDragPhase.started,
      card: card,
      boardId: 'b1',
      columnId: 'todo',
      index: 0,
      globalPosition: Offset.zero,
    );
    expect(drag.phase, FlexiBoardDragPhase.started);

    const drop = FlexiBoardDropDetails<String>(
      card: card,
      accepted: false,
    );
    expect(drop.accepted, isFalse);
    expect(drop.move, isNull);
  });
}
