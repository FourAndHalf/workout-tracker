# Fitness Tracker — Agent Rules

## Primary Directive

All work on this project **must** follow the phased implementation plan defined in
[`plans/implementation-plan.html`](plans/implementation-plan.html).

## Task Lifecycle

1. **Before starting work**, open `plans/implementation-plan.html` and identify the next unchecked
   task. Work on tasks **in order** within each phase, and complete all tasks in a phase before
   moving to the next.

2. **A task is considered complete** only when **both** conditions are met:
   - The functional code is implemented and works correctly.
   - Relevant tests are written and passing (unit, widget, or integration as appropriate).

3. **When a task is fully complete**, update `plans/implementation-plan.html`:
   - Check the corresponding checkbox.
   - The task text will automatically render with ~~strikethrough~~ styling via the HTML/CSS.
   - Do **not** delete tasks from the plan — they serve as a historical record.

4. **Never skip a task** without explicit user approval. If a task is blocked, surface the blocker
   to the user rather than jumping ahead.

## Testing Requirements

- Every new Dart file under `lib/` with logic (models, repositories, services, providers) **must**
  have a corresponding test file under `test/`.
- Widget-heavy features **must** have at least one widget test verifying core rendering and
  interaction.
- Before marking any phase complete, run:
  ```bash
  flutter analyze
  flutter test
  ```
  Both must pass with zero errors.

## Code Quality

- Follow Dart/Flutter conventions and effective Dart guidelines.
- Use the project's established architecture (feature-based folders, Riverpod for state, Drift for
  DB, GoRouter for navigation).
- Preserve all existing comments and docstrings unrelated to current changes.
- Keep commits focused — one task per commit when practical.

## Plan Integrity

- Do **not** modify the structure or content of tasks in the plan unless the user explicitly
  requests changes.
- If the plan needs updating (new tasks, reordering, scope changes), discuss with the user first,
  then update the HTML file accordingly.
