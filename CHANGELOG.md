## 0.3.0

* Add `FlexiBoardPolicies.canStartDrag` so hosts can block pickup (freeze /
  permission) before a drag session starts — no lift-then-bounce when the
  card must not move. `canAcceptDrop` remains the target-side gate.

## 0.2.0

* Add `FlexiBoardLayout.paged`: PageView of columns with side peek and edge
  auto-page while dragging (CRM BoardView-style interaction).
* Add `activeColumnId` / `onActiveColumnChanged` for paged layout control.
* Add physics tunables: `pageSideMargin`, `pageEdgeExtent`, `pageChangeDuration`.
* `BoardColumnView.expandHorizontally` for full-width page slots.

## 0.1.0

* Initial FlexiBoard (`flexi_board`) release: multi-board DnD, default UI, WIP, undo, swimlanes.
