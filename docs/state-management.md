# State Management

zshell separates ephemeral interaction state from user choices that must survive
a process restart.

| Owner | Lifetime | Values |
| --- | --- | --- |
| `UiState.qml` | Current process | Panel visibility, selected connection mode, and edit mode |
| `LayoutState.qml` | Across restarts | Card positions, theme, component opacity, and language indicator visibility |

`LayoutState` uses Quickshell `FileView` with `JsonAdapter`. Updates are written
atomically to `~/.local/state/zshell/layout.json`; external file changes are
reloaded.

Default positions remain in code and are used until the state file supplies a
saved value. Components clamp positions to the current screen bounds before
rendering.

`componentOpacity` defaults to `1` and is clamped to the `0`–`1` range by the
theme. Quick Settings changes it in 10% steps; the value controls component
surfaces and borders without fading foreground content.

`showLanguageLeft` and `showLanguageRight` default to true. They are persisted
now so a future settings UI can control each side without changing dock layout.

System state such as workspaces, networks, Bluetooth devices, and media players
is never copied into local storage. The owning Quickshell integration remains
the source of truth.
