# State Management

zshell separates ephemeral interaction state from user choices that must survive
a process restart.

| Owner | Lifetime | Values |
| --- | --- | --- |
| `UiState.qml` | Current process | Modal visibility, active component and stack order, Dock animation target, and selected connection mode |
| `LayoutState.qml` | Across restarts | Minimal and expanded card geometry, card visibility, Quick Settings position, theme, component opacity, and language indicator visibility |

`LayoutState` uses Quickshell `FileView` with `JsonAdapter`. Updates are written
atomically to `~/.local/state/zshell/layout.json`; external file changes are
reloaded.

Default positions remain in code and are used until the state file supplies a
saved value. Components clamp positions to the current screen bounds before
rendering.

`clockX`, `clockY`, `clockWidth`, and `clockHeight` store the minimal Clock
rectangle. The matching `clockExpanded*` values store its expanded rectangle.
Music uses the same split through `music*` and `musicExpanded*`. Panels always
start minimal after a process restart; only their two geometry sets persist.

`showClock` and `showMusic` default to true and are controlled from the Quick
Settings Widgets page. Disabling either value hides the card across restarts.
Music visibility remains conditional on an available MPRIS player even when
`showMusic` is enabled.

`quickSettingsX` and `quickSettingsY` store the last committed modal position.
They default to the lower-right placement above the Dock. The Dock animation
target remains ephemeral because it is recalculated from the invoking control.

`componentOpacity` defaults to `1` and is clamped to the `0`–`1` range by the
theme. Quick Settings changes it in 10% steps; the value controls component
surfaces and borders without fading foreground content.

`QuickSettingsPanel` owns its transient Pin state. Pin changes only the current
open panel's click-through mask and resets whenever the panel closes, so it is
not stored in `UiState` or `LayoutState`.

Each expanded `FloatingPanel` also owns transient Pin state. Pin prevents an
outside click or focus change from restoring minimal mode, but it does not alter
the persisted geometry or stack counters. Explicit Close and Escape reset it.

`UiState.activeComponent` and the three component stack counters coordinate
focus across Clock, Music, and Quick Settings. Activating a component advances
the process-local serial and assigns it the newest stack value. Stack order is
intentionally not persisted, so each session starts from a deterministic base.

`showLanguageLeft` and `showLanguageRight` default to true. They are persisted
now so a future settings UI can control each side without changing dock layout.

System state such as workspaces, networks, Bluetooth devices, and media players
is never copied into local storage. The owning Quickshell integration remains
the source of truth.
