# FlexiBoard public API (0.4.x)

All of these are exported from `package:flexi_board/flexi_board.dart`.

## Data

| Type | Role |
|---|---|
| `FlexiBoardWorkspace<T>` | Root: `boards`, optional `activeBoardId`. `applyMove`, `applyColumnReorder`, `boardById`, `activeBoard`, `resolvedActiveBoardId`, `copyWith` |
| `FlexiBoardBoard<T>` | `id`, `title`, `columns`, optional `swimlanes`. `columnById` |
| `FlexiBoardColumn<T>` | `id`, `title`, `cards`, optional `wipLimit`, `color` |
| `FlexiBoardCard<T>` | `id`, `data` (`T`), optional `columnId` / `boardId` |
| `FlexiBoardSwimlane<T>` | `id`, `title`, `filter`, `collapsed` |
| `FlexiBoardMove<T>` | `card`, from/to board+column+index. `isCrossBoard`, `isSameColumn` |
| `FlexiBoardColumnReorder` | `boardId`, `fromIndex`, `toIndex` |

`workspaceFromColumns<T>(boardId:, boardTitle:, columns:)` builds a one-board workspace.

## Widget

`FlexiBoard<T>` — required: `workspace` **or** `controller`.

Optional: `layout`, `activeBoardId`, `activeColumnId`, `physics`, `policies`, `theme`, builders (`cardBuilder`, `columnHeaderBuilder`, `columnFooterBuilder`, `columnListWrapper`, `boardTabBuilder`, `emptyColumnBuilder`, `swimlaneHeaderBuilder`), callbacks (`onDrag`, `onDrop`, `onCardMoved`, `onColumnReordered`, `onActiveBoardChanged`, `onActiveColumnChanged`).

`FlexiBoardLayout`: `single` | `tabs` | `sideBySide` | `paged`.

## Controller

`FlexiBoardController<T>` extends `ChangeNotifier`.

Construct with `initial:` workspace, optional `policies`, `maxUndoSteps` (default 50).

Reads: `workspace`, `boards`, `activeBoardId`, `canUndo`, `canRedo`.

## Events

* `FlexiBoardDragPhase`: `started`, `updated`, `cancelled`
* `FlexiBoardDragDetails<T>`: origin ids + hover ids + `rejected`
* `FlexiBoardDropDetails<T>`: `accepted`, optional `move`
* `FlexiBoardCardDragDetails`: `isDragging`, `isGhost`

## Defaults / physics / policies

* `FlexiBoardTheme`, `FlexiBoardPhysics` (`standard`, `snappy`)
* `FlexiBoardPolicies<T>`: `wipEnabled`, `allowColumnReorder`, `canStartDrag`, `canAcceptDrop`
