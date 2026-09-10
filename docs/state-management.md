# State Management

zshell separates ephemeral interaction state from user choices that must survive
a process restart.

| Owner | Lifetime | Values |
| --- | --- | --- |
| `UiState.qml` | Current process | Modal visibility, Dock animation target, selected connection mode, and edit mode |
| `LayoutState.qml` | Across restarts | Card and Quick Settings positions, theme, component opacity, and language indicator visibility |

`LayoutState` uses Quickshell `FileView` with `JsonAdapter`. Updates are written
atomically to `~/.local/state/zshell/layout.json`; external file changes are
reloaded.

Default positions remain in code and are used until the state file supplies a
saved value. Components clamp positions to the current screen bounds before
rendering.

`quickSettingsX` and `quickSettingsY` store the last committed modal position.
They default to the lower-right placement above the Dock. The Dock animation
target remains ephemeral because it is recalculated from the invoking control.

`componentOpacity` defaults to `1` and is clamped to the `0`–`1` range by the
theme. Quick Settings changes it in 10% steps; the value controls component
surfaces and borders without fading foreground content.

`QuickSettingsPanel` owns its transient Pin state. Pin changes only the current
open panel's click-through mask and resets whenever the panel closes, so it is
not stored in `UiState` or `LayoutState`.

`showLanguageLeft` and `showLanguageRight` default to true. They are persisted
now so a future settings UI can control each side without changing dock layout.

System state such as workspaces, networks, Bluetooth devices, and media players
is never copied into local storage. The owning Quickshell integration remains
the source of truth.
