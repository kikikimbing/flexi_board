---
name: flexi-board-layouts
description: >-
  Use when choosing or wiring FlexiBoardLayout (single, tabs, sideBySide,
  paged), FlexiBoardPhysics, snappy cross-board drag, stay-in-place source
  cards, columnListWrapper for pull-to-refresh or infinite scroll, paged
  activeColumnId, or tab hover-to-switch while dragging.
license: MIT
metadata:
  version: "0.4.1"
---

# FlexiBoard layouts and physics

## Pick a layout

| Layout | When to use |
|---|---|
| `FlexiBoardLayout.single` | One board, horizontal column canvas |
| `FlexiBoardLayout.tabs` | 1..N boards; one visible; drag over a tab to switch, then drop |
| `FlexiBoardLayout.sideBySide` | Several boards on screen; drag across boards |
| `FlexiBoardLayout.paged` | One **column** per page (BoardView-style), side peek, edge-page while dragging |

Do not invent extra layout enums. There are only these four.

## Tabs

```dart
FlexiBoard<T>(
  controller: controller,
  layout: FlexiBoardLayout.tabs,
  activeBoardId: id,                 // optional controlled id
  onActiveBoardChanged: (id) { ... },
)
```

Hover-to-switch delay is `FlexiBoardPhysics.tabHoverSwitchDelay`.

## Side-by-side + snappy cross-board

```dart
FlexiBoard<T>(
  physics: FlexiBoardPhysics.snappy,
  layout: FlexiBoardLayout.sideBySide,
)
```

`snappy` sets `snapOnBoardEnter` and `snapFeedbackToPlaceholder` so entering
another board snaps hover (and the floating card) to the nearest slot.

## Paged columns

Requires column identity, not board identity:

```dart
FlexiBoard<T>(
  layout: FlexiBoardLayout.paged,
  activeColumnId: currentColumnId,
  onActiveColumnChanged: (columnId) {
    setState(() => currentColumnId = columnId);
  },
  physics: const FlexiBoardPhysics(
    pageSideMargin: 16,
    pageEdgeExtent: 80,
    pageChangeDuration: Duration(milliseconds: 400),
  ),
)
```

* `pageSideMargin` — side peek / viewport fraction
* `pageEdgeExtent` — drag-near-edge distance that changes page
* `pageChangeDuration` — animated page change

Do not use `activeBoardId` to control paged columns.

## Stay-in-place source card

Default drag **removes** the source and shows a placeholder ghost.

```dart
FlexiBoard(
  physics: const FlexiBoardPhysics(keepSourceCardVisible: true),
)
```

This is a **physics** flag, not a widget named parameter and not
`LongPressDraggable`.

## Column list wrapper (refresh / load-more)

Wrap **each column’s vertical ListView**, not the board or horizontal pager:

```dart
FlexiBoard(
  columnListWrapper: (context, column, list) {
    return RefreshIndicator(
      onRefresh: () => onRefresh(column.id),
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          // load more when near the end
          return false;
        },
        child: list,
      ),
    );
  },
)
```

Always return a widget that **contains** `list`. Do not replace it with a
new `ListView` of cards.

## Other physics knobs

`longPressDelay`, `columnWidth`, `cardSpacing`, `columnSpacing`,
edge auto-scroll extents/speeds, `animationDuration` / `animationCurve`.

Start from `FlexiBoardPhysics.standard` or `snappy`, then copyWith /
construct only the fields you need.

## Anti-patterns

* `PageView` of whole boards to fake `paged` — `paged` pages **columns**
* RefreshIndicator around `FlexiBoard` instead of `columnListWrapper`
* `keepSourceCardVisible` on `FlexiBoard` (it lives on `FlexiBoardPhysics`)
* Assuming tabs show all boards at once — that is `sideBySide`
