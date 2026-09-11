---
name: flexi-board-policies
description: >-
  Use when configuring FlexiBoardPolicies: WIP limits, canStartDrag to
  freeze or lock cards before pickup, canAcceptDrop target gates,
  allowColumnReorder, undo/redo on FlexiBoardController, or rejected
  drops. Also use when cards bounce back, cannot be lifted, or a column
  should refuse more cards.
license: MIT
metadata:
  version: "0.4.1"
---

# FlexiBoard policies, WIP, and undo

Pass `FlexiBoardPolicies<T>` on `FlexiBoard` and/or
`FlexiBoardController`. Widget `policies` override the controller’s.

## Two gates (do not mix them)

| Callback | When | Use for |
|---|---|---|
| `canStartDrag(card, workspace)` | **Before** lift | Freeze, permissions, locked cards. No bounce-back. |
| `canAcceptDrop(move, workspace)` | Hover / drop | WIP, illegal columns, cross-board rules |

Default `canStartDrag` is “allow all”. Default `canAcceptDrop` is WIP
when `wipEnabled` is true.

```dart
FlexiBoard(
  policies: FlexiBoardPolicies(
    wipEnabled: true,
    allowColumnReorder: true,
    canStartDrag: (card, workspace) => card.id != 'locked',
    canAcceptDrop: (move, workspace) => true,
  ),
)
```

If `canAcceptDrop` is set, it **replaces** the built-in WIP check. Re-apply
WIP yourself if you still want it:

```dart
canAcceptDrop: (move, workspace) {
  final policies = FlexiBoardPolicies<Task>(wipEnabled: true);
  if (policies.wouldExceedWip(move, workspace)) return false;
  return move.toColumnId != 'closed';
}
```

## WIP limits

Set `wipLimit` on `FlexiBoardColumn`. Same-column reorder never exceeds WIP.
Cross-column drops into a full column are rejected when `wipEnabled` is true.

```dart
FlexiBoardColumn(id: 'doing', title: 'Doing', wipLimit: 3, cards: [...]),
```

Helpers: `wouldExceedWip`, `isAtCapacity`, `isApproachingCapacity`.
Default chrome uses warning/exceeded colors from `FlexiBoardTheme`.

`wipEnabled: false` disables the built-in capacity check (custom
`canAcceptDrop` still runs if provided).

## Undo / redo

Only `FlexiBoardController` records undo. Host-owned `workspace` must
implement its own stack.

```dart
controller.undo();
controller.redo();
controller.canUndo;
controller.canRedo;
```

`moveCard` / `reorderColumn` / `addCard` / `removeCard` push undo.
`setWorkspace(next, recordUndo: true)` to record a host-built snapshot.
Default `maxUndoSteps` is 50.

Column reorder requires `allowColumnReorder: true` (default). Listen with
`onColumnReordered`.

## Drop callbacks vs policies

Rejected / cancelled drops: `onDrop` with `accepted: false` and `move == null`;
`onDrag` with `FlexiBoardDragPhase.cancelled`. `onCardMoved` does **not** fire.

Controller mode: accepted drops call `controller.moveCard` which also
runs `policies.accepts`.

## Anti-patterns

* Using `canAcceptDrop` to prevent pickup (card lifts, then bounces)
* Mutating `workspace` inside `canStartDrag` / `canAcceptDrop`
* Expecting undo without a `FlexiBoardController`
* Setting `wipLimit` but also `canAcceptDrop: (...) => true` (that skips WIP)
