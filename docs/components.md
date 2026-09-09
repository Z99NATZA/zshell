# Components

## At a glance

| Component | Responsibility |
| --- | --- |
| `Dock` | Workspace actions, edit mode, audio, time, language, and power |
| `QuickSettingsPanel` | Wi-Fi, Bluetooth, theme, and layout controls |
| `ConnectionCard` | Shared network and Bluetooth device action card |
| `DesktopSurface` | Desktop-layer composition and click-through regions |
| `ClockCard` | Reactive time and persisted drag position |
| `MusicCard` | Current MPRIS metadata, progress, and transport controls |
| `LanguageIndicator` | Fixed-width current keyboard label |
| `ActionButton` | Shared compact hover, active, and disabled behavior |
| `ShellSurface` | Shared surface, border, radius, and color transitions |

## Boundaries

- Visual components consume semantic theme roles; they do not define palettes.
- Quick Settings presents Wi-Fi networks or Bluetooth devices around a central
  radio control. Its bottom switch changes modes without closing the panel.
- Quick Settings is modal while open. Clicking outside it or pressing Escape
  dismisses it; clicks inside it never fall through to another window.
- Drag the Quick Settings header, including its surrounding padding and gaps,
  to move the panel. Header controls keep their own click targets. The committed
  position is restored across restarts and clamped to the current screen.
- Quick Settings expands from the Dock control that opened it and collapses
  back to that control when dismissed. It has no dedicated close button.
- Quick Settings adjusts every component surface from fully transparent to
  opaque in 10% steps. Text, icons, and media artwork remain opaque.
- `ActionButton` owns reusable control feedback. Feature components own layout.
- The workspace switcher starts with the configurable `Theme.workspaceIcon`.
  Its numbers have no shared container, and the active workspace uses a
  high-contrast circular indicator.
- Both language indicators consume the same `KeyboardLayout.code`; neither
  starts its own process.
- The dock volume button toggles mute on click and changes volume by 5% per
  mouse-wheel step.
- Dock Wi-Fi and Bluetooth labels are capped at 12 characters. Bluetooth shows
  the first connected device and reserves space for `+N` when more are active;
  Quick Settings keeps the full names.
- The Dock is the sole Power entry point. Its button delegates to
  `hypr-power-menu`; it never runs a session or machine power action directly.
- Desktop cards report committed positions. `LayoutState` owns persistence.
- The system panel connects only to remembered Wi-Fi networks. Networks that
  require new credentials are visible but disabled.
- The central Bluetooth control enables the default adapter or toggles
  discovery. Device cards pair unpaired devices, connect paired devices, cancel
  pairing in progress, and disconnect connected devices.
- Quick Settings shows at most six Wi-Fi networks or Bluetooth devices at once.
  Bluetooth cards include battery percentage when the device reports it.

## Input behavior

The desktop surface accepts pointer input only over the active media card or,
while edit mode is enabled, the draggable cards. Every other pixel is click
through. This prevents an invisible full-screen shell surface from blocking
desktop and application input.
