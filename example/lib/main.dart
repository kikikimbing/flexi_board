import 'package:board_flow/board_flow.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const BoardFlowExampleApp());
}

class BoardFlowExampleApp extends StatelessWidget {
  const BoardFlowExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Board Flow Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1F6F5B)),
        useMaterial3: true,
      ),
      home: const ExampleHome(),
    );
  }
}

class ExampleHome extends StatefulWidget {
  const ExampleHome({super.key});

  @override
  State<ExampleHome> createState() => _ExampleHomeState();
}

class _ExampleHomeState extends State<ExampleHome> {
  late final BoardFlowController<Task> _controller;
  BoardFlowLayout _layout = BoardFlowLayout.tabs;
  bool _useCustomCards = false;

  @override
  void initState() {
    super.initState();
    _controller = BoardFlowController<Task>(
      initial: _buildWorkspace(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Board Flow'),
        actions: [
          IconButton(
            tooltip: 'Undo',
            onPressed: _controller.canUndo ? _controller.undo : null,
            icon: const Icon(Icons.undo),
          ),
          IconButton(
            tooltip: 'Redo',
            onPressed: _controller.canRedo ? _controller.redo : null,
            icon: const Icon(Icons.redo),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                switch (value) {
                  case 'single':
                    _layout = BoardFlowLayout.single;
                  case 'tabs':
                    _layout = BoardFlowLayout.tabs;
                  case 'side':
                    _layout = BoardFlowLayout.sideBySide;
                  case 'custom':
                    _useCustomCards = !_useCustomCards;
                }
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'single', child: Text('Layout: single')),
              const PopupMenuItem(value: 'tabs', child: Text('Layout: tabs')),
              const PopupMenuItem(value: 'side', child: Text('Layout: side-by-side')),
              PopupMenuItem(
                value: 'custom',
                child: Text(
                  _useCustomCards ? 'Use default cards' : 'Use custom cards',
                ),
              ),
            ],
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          return BoardFlow<Task>(
            controller: _controller,
            layout: _layout,
            physics: BoardFlowPhysics.snappy,
            cardBuilder: _useCustomCards ? _buildCustomCard : null,
            columnFooterBuilder: (context, column) {
              return TextButton.icon(
                onPressed: () {
                  _controller.addCard(
                    boardId: _controller.activeBoardId,
                    columnId: column.id,
                    card: BoardFlowCard(
                      id: 'new_${DateTime.now().millisecondsSinceEpoch}',
                      data: Task(
                        title: 'New task',
                        priority: Priority.medium,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
              );
            },
            onCardMoved: (move) {
              debugPrint(
                'moved ${move.card.data.title} '
                '${move.fromBoardId}/${move.fromColumnId} -> '
                '${move.toBoardId}/${move.toColumnId} @ ${move.toIndex}',
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildCustomCard(
    BuildContext context,
    BoardFlowCard<Task> card,
    BoardFlowCardDragDetails details,
  ) {
    final color = switch (card.data.priority) {
      Priority.high => Colors.red.shade100,
      Priority.medium => Colors.amber.shade100,
      Priority.low => Colors.green.shade100,
    };
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(10),
      elevation: details.isDragging ? 6 : 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              card.data.title,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              card.data.priority.name.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}

enum Priority { low, medium, high }

class Task {
  Task({required this.title, required this.priority});

  final String title;
  final Priority priority;

  @override
  String toString() => title;
}

BoardFlowWorkspace<Task> _buildWorkspace() {
  return BoardFlowWorkspace<Task>(
    activeBoardId: 'product',
    boards: [
      BoardFlowBoard<Task>(
        id: 'product',
        title: 'Product',
        columns: [
          BoardFlowColumn<Task>(
            id: 'backlog',
            title: 'Backlog',
            cards: [
              BoardFlowCard(
                id: 'p1',
                data: Task(title: 'Research competitors', priority: Priority.low),
              ),
              BoardFlowCard(
                id: 'p2',
                data: Task(title: 'Draft PRD', priority: Priority.medium),
              ),
            ],
          ),
          BoardFlowColumn<Task>(
            id: 'doing',
            title: 'In Progress',
            wipLimit: 2,
            cards: [
              BoardFlowCard(
                id: 'p3',
                data: Task(title: 'Prototype DnD', priority: Priority.high),
              ),
            ],
          ),
          const BoardFlowColumn<Task>(
            id: 'done',
            title: 'Done',
          ),
        ],
      ),
      BoardFlowBoard<Task>(
        id: 'marketing',
        title: 'Marketing',
        columns: [
          BoardFlowColumn<Task>(
            id: 'ideas',
            title: 'Ideas',
            cards: [
              BoardFlowCard(
                id: 'm1',
                data: Task(title: 'Launch thread', priority: Priority.medium),
              ),
            ],
          ),
          const BoardFlowColumn<Task>(
            id: 'scheduled',
            title: 'Scheduled',
            wipLimit: 3,
          ),
        ],
      ),
    ],
  );
}
