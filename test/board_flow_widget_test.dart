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
                    BoardFlowColumn(id: 'c', title: 'Col'),
                  ],
                ),
                BoardFlowBoard(
                  id: 'b',
                  title: 'Beta',
                  columns: [
                    BoardFlowColumn(id: 'c', title: 'Col'),
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
  });
}
