# FlexiBoard — agent instructions

This repository is the `flexi_board` Flutter package: mechanism-first
multi-board drag-and-drop. README is for humans; this file is for coding
agents working **in this repo**.

Consumer agents integrating the published package should load the skills
in `skills/` (or `dart run skills@ get` after depending on `flexi_board`).

## Commands

From the package root:

```bash
flutter pub get
flutter analyze
flutter test
cd example && flutter pub get && flutter analyze
```

Example app: `cd example && flutter run`. There is no `build_runner`,
l10n, or extra codegen.

## Layout

| Path | What |
|---|---|
| `lib/flexi_board.dart` | **Public API** — export new types here |
| `lib/src/models/` | Immutable workspace / board / column / card / move |
| `lib/src/widgets/` | `FlexiBoard` and canvas/layout widgets |
| `lib/src/controller/` | Optional `ChangeNotifier` + undo |
| `lib/src/physics/` | Drag session, hit testing, edge auto-scroll |
| `lib/src/policies/` | WIP, `canStartDrag` / `canAcceptDrop` |
| `lib/src/defaults/` | Optional Material chrome + `FlexiBoardTheme` |
| `test/` | Model tests + widget tests |
| `example/` | Demo app (path dependency) |
| `skills/` | **Published** package skills for consumers |
| `.agents/skills/` | Maintainer-only skills (not published) |

## Invariants

* Flutter-only. Do not add Provider, Riverpod, GetIt, or a design-system
  dependency to the package.
* Card payload is generic `T`. Never inspect `card.data`.
* Workspace is immutable (`copyWith`, `applyMove`). No in-place list edits
  in models.
* `FlexiBoard` requires `workspace` **or** `controller` (controller wins).
* Pickup blocking is `FlexiBoardPolicies.canStartDrag`. Target rejection
  is `canAcceptDrop`. Do not collapse those.
* Column refresh / infinite scroll is `columnListWrapper` on the vertical
  list, not a wrapper around the whole board.
* Stay-in-place source cards are `FlexiBoardPhysics.keepSourceCardVisible`.

## Changing the public API

1. Export from `lib/flexi_board.dart`.
2. Add/adjust tests in `test/`.
3. Document in `README.md` and `CHANGELOG.md`.
4. Update matching files under `skills/` (and `references/`) so consumer
   agents do not ship stale guidance. Bump the `metadata.version` in each
   edited `SKILL.md` to the package version.
5. Keep skill directory names prefixed with `flexi-board-` (or
   `flexi_board-`). `name:` in frontmatter must match the directory.

Do not exclude `skills/` in `.pubignore`.

## Style

* `flutter_lints` (`analysis_options.yaml`).
* Prefer small, focused types over a god widget.
* Default UI is optional; mechanism (physics, placeholders, events)
  stays usable with custom builders.

## Commits

Conventional, present-tense: `feat:`, `fix:`, `docs:`, `test:`, `refactor:`.
Reference issues when relevant (`#3`).
