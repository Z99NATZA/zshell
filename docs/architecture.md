# Architecture

zshell is a Quickshell configuration that renders a desktop widget workspace, a
floating dock, and an on-demand system panel. Quickshell integrations provide
reactive system state; QML components own presentation and interaction.

## System shape

```text
Hyprland / NetworkManager / BlueZ / MPRIS
                    |
          Quickshell integrations
                    |
       Dock + panel + desktop cards
                    |
       semantic theme and local state
```

| Layer | Owns |
| --- | --- |
| `shell.qml` | Per-screen window composition |
| `components/` | Rendering and direct pointer interaction |
| `services/` | Shared reactive system state, display mapping, and direct actions |
| `state/` | Runtime UI state and persisted user choices |
| `theme/` | Semantic visual and motion tokens |
| `scripts/` | Local run and verification commands |

## Window model

- `Dock` is an above-window layer surface offset above the existing Waybar.
- `QuickSettingsPanel` is created per screen and shown on demand.
- `DesktopSurface` is below normal application windows and uses a click-through
  mask so transparent areas normally never block desktop input. An unpinned
  expanded card temporarily owns a transparent full-screen dismiss region;
  pinning it restores outside click-through. The surface moves above normal
  windows while Clock or Music is expanded, except while Quick Settings owns
  focus.
- Clock and Music share `DesktopSurface`, so their QML stack values provide
  deterministic last-activated ordering. Quick Settings remains a separate
  window; `UiState.activeComponent` switches which shell window occupies the
  above-window layer when their visible regions overlap.
- `FloatingPanel` owns reusable desktop-panel chrome, optional property slots,
  drag interaction, and edge/corner geometry resize. Content components own
  responsive body layout and mode-specific persistence.
- The MVP persists one shared card layout. Per-monitor layouts are outside the
  current behavior.

## Dependency direction

```text
shell -> components -> services/state/theme
components -> Quickshell integrations and services
services -> Quickshell integrations and focused system queries
state -> Quickshell.Io
theme -> persisted theme selection
```

State and theme code do not import visual components.

## Detailed documents

- [Components](components.md)
- [Services](services.md)
- [Design system](design-system.md)
- [State management](state-management.md)
- [Folder structure](folder-structure.md)
- [Runtime integration](runtime-integration.md)
- [Conventions](conventions.md)
