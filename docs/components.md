# Components

## At a glance

| Component | Responsibility |
| --- | --- |
| `Dock` | Workspace actions, edit mode, system status, and panel toggle |
| `QuickSettingsPanel` | Wi-Fi, Bluetooth, theme, and layout controls |
| `DesktopSurface` | Desktop-layer composition and click-through regions |
| `ClockCard` | Reactive time and persisted drag position |
| `MusicCard` | Current MPRIS metadata, progress, and transport controls |
| `ActionButton` | Shared compact hover, active, and disabled behavior |
| `ShellSurface` | Shared surface, border, radius, and color transitions |

## Boundaries

- Visual components consume semantic theme roles; they do not define palettes.
- `ActionButton` owns reusable control feedback. Feature components own layout.
- Desktop cards report committed positions. `LayoutState` owns persistence.
- The system panel connects only to remembered Wi-Fi networks. Networks that
  require new credentials are visible but disabled in the MVP.
- Bluetooth controls toggle the default adapter and can disconnect devices that
  are currently connected. Discovery, pairing, and reconnecting devices remain
  the responsibility of a dedicated Bluetooth settings application in the MVP.

## Input behavior

The desktop surface accepts pointer input only over the active media card or,
while edit mode is enabled, the draggable cards. Every other pixel is click
through. This prevents an invisible full-screen shell surface from blocking
desktop and application input.
