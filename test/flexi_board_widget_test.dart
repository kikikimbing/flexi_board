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

  testWidgets('custom boardTabBuilder still switches boards on tap',
      (tester) async {
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

  testWidgets(
      'paged layout shows one column at a time and reports page changes',
      (tester) async {
    String? activeColumn;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FlexiBoard<String>(
            workspace: FlexiBoardWorkspace<String>(
              boards: [
                FlexiBoardBoard<String>(
                  id: 'b1',
                  title: 'Main',
                  columns: const [
                    FlexiBoardColumn(
                      id: 'todo',
                      title: 'Todo',
                      cards: [
                        FlexiBoardCard(id: 'c1', data: 'Todo card'),
                      ],
                    ),
                    FlexiBoardColumn(
                      id: 'done',
                      title: 'Done',
                      cards: [
                        FlexiBoardCard(id: 'c2', data: 'Done card'),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            layout: FlexiBoardLayout.paged,
            activeColumnId: 'todo',
            onActiveColumnChanged: (id) => activeColumn = id,
          ),
        ),
      ),
    );

    expect(find.text('Todo card'), findsOneWidget);

    await tester.drag(find.byType(PageView), const Offset(-400, 0));
    await tester.pumpAndSettle();

    expect(find.text('Done card').hitTestable(), findsOneWidget);
    expect(activeColumn, 'done');
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

  testWidgets('canStartDrag false prevents drag start (no lift)', (tester) async {
    var started = false;
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
                        FlexiBoardCard(id: 'c1', data: 'Frozen'),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            policies: FlexiBoardPolicies<String>(
              canStartDrag: (card, workspace) => false,
            ),
            physics: const FlexiBoardPhysics(
              longPressDelay: Duration(milliseconds: 50),
            ),
            onDrag: (details) {
              if (details.phase == FlexiBoardDragPhase.started) {
                started = true;
              }
            },
          ),
        ),
      ),
    );

    final gesture = await tester.startGesture(tester.getCenter(find.text('Frozen')));
    await tester.pump(const Duration(milliseconds: 80));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(started, isFalse);
  });

  testWidgets('canStartDrag true still allows drag start', (tester) async {
    var started = false;
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
                        FlexiBoardCard(id: 'c1', data: 'Movable'),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            policies: FlexiBoardPolicies<String>(
              canStartDrag: (card, workspace) => true,
            ),
            physics: const FlexiBoardPhysics(
              longPressDelay: Duration(milliseconds: 50),
            ),
            onDrag: (details) {
              if (details.phase == FlexiBoardDragPhase.started) {
                started = true;
              }
            },
          ),
        ),
      ),
    );

    final gesture = await tester.startGesture(tester.getCenter(find.text('Movable')));
    await tester.pump(const Duration(milliseconds: 80));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(started, isTrue);
  });
}
