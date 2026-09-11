---
name: flexi-board-integrate
description: >-
  Use when adding FlexiBoard to a Flutter app, creating a kanban or
  multi-board, wiring FlexiBoardController vs host-owned workspace,
  custom cardBuilder tiles, onDrop/onCardMoved, or applying moves.
  Also use when the user mentions flexi_board, FlexiBoard, drag-and-drop
  boards, or board cards.
license: MIT
metadata:
  version: "0.4.1"
---

# Integrate FlexiBoard

Mechanism-first multi-board drag-and-drop. Flutter-only. Do not add
Provider, Riverpod, GetIt, or a design system to use this package.

Import: `package:flexi_board/flexi_board.dart`

Must provide **either** `controller` **or** `workspace`. If both are
passed, `controller` wins and `workspace` is ignored.

## Guidelines

* Own card payload as generic `T`. The package never inspects `data`.
* Treat `FlexiBoardWorkspace` as immutable. Apply drops with
  `workspace.applyMove(move)` or `controller.moveCard(move)`.
* Dispose `FlexiBoardController` in `State.dispose`.
* Place `FlexiBoard` under a `MaterialApp` (needs `Overlay` + `Theme`).
* Customize UI with builders (`cardBuilder`, `columnHeaderBuilder`,
  …). Do not wrap cards in `LongPressDraggable` / `DragTarget`.
* Host-owned state: apply the move in `onDrop` when `details.accepted`
  (or in `onCardMoved`). Do not mutate column lists in place.
* Controller mode already applies accepted moves. Still listen with
  `onCardMoved` if the host needs side effects.
* Do not invent `FlexiBoardProvider`, JSON codecs, or required
  state-management packages. There are none.

For layouts, physics, and `columnListWrapper`, use **flexi-board-layouts**.
For WIP, freeze/pickup gates, and undo, use **flexi-board-policies**.
API cheat sheet: [references/api.md](references/api.md)

## Quick start (controller)

```dart
final controller = FlexiBoardController<String>(
  initial: FlexiBoardWorkspace(
    boards: [
      FlexiBoardBoard(
        id: 'main',
        title: 'Main',
        columns: [
          FlexiBoardColumn(
            id: 'todo',
            title: 'Todo',
            cards: [
              FlexiBoardCard(id: '1', data: 'Ship flexi_board'),
            ],
          ),
          FlexiBoardColumn(id: 'done', title: 'Done'),
        ],
      ),
    ],
  ),
);

FlexiBoard<String>(
  controller: controller,
  layout: FlexiBoardLayout.single,
);
```

Single-board helper: `workspaceFromColumns(boardId:, boardTitle:, columns:)`.

## Host-owned workspace (any state management)

```dart
FlexiBoard<Task>(
  workspace: myWorkspace,
  layout: FlexiBoardLayout.tabs,
  cardBuilder: (context, card, details) => MyTaskTile(task: card.data),
  onDrag: (details) {
    // started | updated | cancelled
  },
  onDrop: (details) {
    if (!details.accepted || details.move == null) return;
    setState(() => myWorkspace = myWorkspace.applyMove(details.move!));
  },
);
```

`onCardMoved` fires only for accepted moves. Prefer `onDrop` when the
host must also handle cancelled / rejected drops.

## Custom cards

```dart
cardBuilder: (context, card, details) {
  // details.isDragging — overlay feedback
  // details.isGhost — placeholder in the source/target slot
  return MyTile(data: card.data);
}
```

Omit builders to use the default Material chrome (`DefaultBoardCard`,
headers, tabs). Style defaults with `FlexiBoardTheme` / `fromContext`.

## Controller mutations

Use these instead of editing lists:

* `addCard(boardId:, columnId:, card:, index:)`
* `removeCard(cardId)`
* `moveCard(move)` / `reorderColumn(reorder)`
* `setWorkspace(next, recordUndo: true)`
* `setActiveBoard(boardId)`
* `undo()` / `redo()` (`canUndo` / `canRedo`)

## Anti-patterns

* Adding Riverpod/Provider *in order to use* FlexiBoard
* Passing `workspace:` while also mutating through a controller
* Applying `details.move` when `details.accepted` is false
* Wrapping the whole board in `RefreshIndicator` — use
  `columnListWrapper` (see **flexi-board-layouts**)
* Blocking pickup with `canAcceptDrop` — that is target-side; use
  `canStartDrag` (see **flexi-board-policies**)
