# Agent Work Priority

Read this document before starting any scoped agent task in this repository.

## Active scope

No repository priority is active. Use the user's clearly agreed authorization
scope for the next task.

## Required read order

1. `docs/agent-work-priority.md`
2. Add only the current-behavior documents that own the active scope.
3. Read matching lessons only when debugging or reworking a known failure mode.

## Required outcome

No outcome is pending. Replace this section when a new priority becomes active,
then reset it after that priority is complete.

## Authorization and verification

- Persistent changes require the applicable standalone authorization command:
  `ok impl`, `ok refine`, `ok fix`, or `ok update`. Use only the agreed scope.
- Focused checks and fixes caused by authorized changes are included.
- Reuse valid results. Do not weaken checks or fix unrelated behavior.
- Report pre-existing, skipped, unrelated, or blocked checks with the reason.
- Project authorization does not implicitly permit package installation,
  `~/.config` changes, desktop restarts, or replacement of Waybar.

## Git operations

- Authorized implementation may use necessary local Git operations, including
  staging and committing the agreed changes.
- Inspect staged changes and do not stage unrelated files.
- Use `<type>: <message>` or `<type>(<scope>): <message>`.
- Use a scope only when the whole commit belongs to one specific subsystem.
  Omit the scope for changes spanning multiple subsystems.
- Never push, open pull requests, publish releases, upload artifacts, rewrite
  history, or discard user changes without separate explicit authorization.

## Documentation rules

- Write all project documentation in clear English for human readers first.
- Lead with the outcome. Keep paragraphs short and make the main facts visible
  without requiring a complete linear read.
- Use one document per owner. Update the owning document instead of repeating a
  fact or creating a status note.
- Treat code, checks, and runtime configuration as the source of truth.
- Record current behavior, ownership, boundaries, limits, failure handling, and
  operating commands. Do not record roadmaps, journals, open questions, or
  delivery status in current-behavior documents.
- Use tables for repeated mappings and diagrams only when they clarify a real
  relationship. Preserve exact contracts, paths, commands, and safety limits.
- Put concrete failed approaches in `docs/lessons-learned/` only when they carry
  a reusable warning.
- Before finishing, verify document links and paths, then run `git diff --check`.

## Notes

- Reset Active scope and Required outcome after completing a priority.
- `docs/architecture.md` is an index, not a duplicate behavior source.
- Alias of agent-work-priority.md = priority | pri
