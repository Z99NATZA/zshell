# Folder Structure

```text
shell.qml                   per-screen composition entry point
components/                 windows and reusable visual controls
state/                      runtime and persisted shell state
theme/                      semantic design tokens
scripts/                    run and focused verification commands
docs/                       current behavior by owner
docs/lessons-learned/       reusable warnings from concrete failures
```

Keep QML files close to their owner. Add a subdirectory only when a group has a
clear shared responsibility; do not create empty architectural layers.

Runtime-generated data never belongs in the repository. Quickshell writes
zshell state under `~/.local/state/zshell/` because `shell.qml` declares a
stable state directory.
