# Conventions

## QML

- Use `PascalCase.qml` for components and singletons.
- Use `camelCase` for properties, signals, IDs, and functions.
- Use `import qs.<directory>` for project modules.
- Keep system access in Quickshell integrations or focused services.
- Components render state and emit or invoke direct user actions.
- Avoid imperative synchronization when a property binding expresses the same
  behavior safely.

## Formatting

Code uses tabs with width 4. Markdown uses four-space indentation where nested
content needs indentation. `.editorconfig` is authoritative.

## Extending safely

1. Add behavior to its current owner.
2. Extract a shared component only after a second real use appears.
3. Add a semantic token only for a repeated visual role.
4. Document a new subsystem only when no current document owns it.
5. Run `make check` and inspect the diff before committing.
