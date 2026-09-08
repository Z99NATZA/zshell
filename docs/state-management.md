# State Management

zshell separates ephemeral interaction state from user choices that must survive
a process restart.

| Owner | Lifetime | Values |
| --- | --- | --- |
| `UiState.qml` | Current process | Panel visibility and edit mode |
| `LayoutState.qml` | Across restarts | Card positions and theme name |

`LayoutState` uses Quickshell `FileView` with `JsonAdapter`. Updates are written
atomically to `~/.local/state/zshell/layout.json`; external file changes are
reloaded.

Default positions remain in code and are used until the state file supplies a
saved value. Components clamp positions to the current screen bounds before
rendering.

System state such as workspaces, networks, Bluetooth devices, and media players
is never copied into local storage. The owning Quickshell integration remains
the source of truth.
