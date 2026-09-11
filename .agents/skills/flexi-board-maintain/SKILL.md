---
name: flexi-board-maintain
description: >-
  Use when changing flexi_board itself: public API, physics, policies,
  layouts, exports, tests, changelog, or published skills. Not for app
  code that only consumes the package.
---

# Maintain FlexiBoard

Follow `AGENTS.md` at the repo root.

## Checklist for a behavior change

1. Write or update tests in `test/` first when practical.
2. Keep models immutable; put drag feel in `FlexiBoardPhysics`.
3. Export new public types from `lib/flexi_board.dart`.
4. Run `flutter analyze` and `flutter test`.
5. Update `README.md` + `CHANGELOG.md`.
6. If consumers would generate different code, update `skills/` and
   `skills/flexi-board-integrate/references/api.md`.
7. Sync `metadata.version` in edited `SKILL.md` files with `pubspec.yaml`.

## Do not

* Add a state-management or DI package to `pubspec.yaml`
* Put consumer integration guides in `.agents/skills/` (those belong in
  `skills/` so `dart run skills@ get` can install them)
* Skip widget tests when changing `FlexiBoard` callbacks or layouts
