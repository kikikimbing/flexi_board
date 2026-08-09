# board_flow

Plug-and-play **multi-board drag-and-drop** for Flutter.

- **Mechanism first** — drag physics, placeholders, edge auto-scroll, typed move events
- **1..N boards** — single board, tab switcher (hover-to-switch while dragging), or side-by-side
- **Fully customizable cards** via builders — or use the built-in default UI
- **Flutter-only** — no Provider, Riverpod, GetIt, or design-system lock-in
- **Optional** WIP limits, undo/redo controller, swimlanes

## Install

```yaml
dependencies:
  board_flow:
    path: ../ # or pub version when published
```

## Quick start (defaults)

```dart
final controller = BoardFlowController<String>(
  initial: BoardFlowWorkspace(
    boards: [
      BoardFlowBoard(
        id: 'main',
        title: 'Main',
        columns: [
          BoardFlowColumn(
            id: 'todo',
            title: 'Todo',
            cards: [
              BoardFlowCard(id: '1', data: 'Ship board_flow'),
            ],
          ),
          BoardFlowColumn(id: 'done', title: 'Done'),
        ],
      ),
    ],
  ),
);

BoardFlow<String>(
  controller: controller,
  layout: BoardFlowLayout.single,
);
```

## Custom cards + any state management

Own the workspace yourself and apply moves in `onDrop` or `onCardMoved`:

```dart
BoardFlow<Task>(
  workspace: myWorkspace,
  layout: BoardFlowLayout.tabs,
  cardBuilder: (context, card, details) => MyTaskTile(task: card.data),
  onDrag: (details) {
    // started | updated | cancelled
  },
  onDrop: (details) {
    if (!details.accepted || details.move == null) return;
    setState(() => myWorkspace = myWorkspace.applyMove(details.move!));
  },
  // Or keep using onCardMoved for accepted moves only:
  // onCardMoved: (move) => setState(() => myWorkspace = myWorkspace.applyMove(move)),
);
```

## Layouts

| Layout | Behavior |
|---|---|
| `BoardFlowLayout.single` | One board canvas |
| `BoardFlowLayout.tabs` | Tab strip; drag over a tab to switch boards, then drop |
| `BoardFlowLayout.sideBySide` | Multiple boards visible; drag across boards |

## Snappy cross-board drag

Use `BoardFlowPhysics.snappy` so entering another board snaps the hover (and floating card) to the nearest column slot:

```dart
BoardFlow(
  physics: BoardFlowPhysics.snappy,
  layout: BoardFlowLayout.sideBySide,
  ...
);
```

## Policies

```dart
BoardFlow(
  policies: BoardFlowPolicies(
    wipEnabled: true,
    allowColumnReorder: true,
    canAcceptDrop: (move, workspace) => true,
  ),
  ...
);
```

Set `wipLimit` on a column to enforce capacity when WIP is enabled.

## Example

```bash
cd example && flutter run
```

Long-press a card to drag. Use the app bar menu to switch layouts and toggle custom cards.
