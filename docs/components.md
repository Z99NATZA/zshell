# Components

## At a glance

| Component | Responsibility |
| --- | --- |
| `Dock` | Workspace actions, edit mode, audio, time, language, and power |
| `QuickSettingsPanel` | Wi-Fi, Bluetooth, theme, and layout controls |
| `ConnectionCard` | Shared selectable network and Bluetooth target bubble |
| `ConnectionInspector` | On-demand connection details and explicit primary action |
| `RadarField` | Theme-native connection grid, sweep, and target blips |
| `RadioOrb` | Shared animated Wi-Fi and Bluetooth radio control |
| `FloatingPanel` | Shared focus, chrome, drag, resize, and inspector slots for desktop widgets |
| `DesktopSurface` | Desktop-layer composition and click-through regions |
| `ClockCard` | Minimal clock and expanded floating time panel |
| `MusicCard` | Minimal MPRIS controls and expanded now-playing panel |
| `LanguageIndicator` | Fixed-width current keyboard label |
| `ActionButton` | Shared compact hover, active, and disabled behavior |
| `ShellSurface` | Shared surface, border, radius, and color transitions |

## Boundaries

- Visual components consume semantic theme roles; they do not define palettes.
- Quick Settings uses a `960x680` modal and presents Wi-Fi networks or
  Bluetooth devices as persistent bubbles over their targets on a circular
  radar. Its bottom switch changes modes without closing the panel.
- Every visible connection has a stable pseudo-random radar blip derived from
  its identity. Collision-safe angular slots keep bubbles apart, and a short
  accent connector ties each bubble to its blip. The sweep briefly raises the
  matching bubble but never hides or moves it.
- Clicking a connection bubble selects its radar target and opens the detail
  inspector; it never changes connection state directly. The radar shifts left
  while the inspector slides in from the right. A second click, the close
  control, an empty radar click, or Escape clears the selection.
- The inspector exposes signal and security for Wi-Fi or address, trust, and
  available battery data for Bluetooth. Connect, disconnect, pair, and cancel
  pairing are explicit inspector actions. Wi-Fi profiles requiring credentials
  remain selectable for detail but cannot connect in this first version.
- The central radio control responds to hover and press, and gently pulses only
  while its radio is active and its Quick Settings page is visible. Bluetooth
  discovery adds a small orbiting activity marker.
- Quick Settings opens unpinned as a modal. Clicking outside dismisses it. The
  header Pin control keeps it open and restricts its input region to the panel,
  allowing outside clicks to reach other windows. Pin remains temporary: the
  explicit Close control or Escape closes the panel and resets Pin. When the
  connection inspector is open, the first Escape closes only the inspector.
- Drag the Quick Settings header, including its surrounding padding and gaps,
  to move the panel. Header controls keep their own click targets. The committed
  position is restored across restarts and clamped to the current screen.
- Quick Settings expands from the Dock control that opened it and collapses
  back to that control when dismissed. Its header Close control and Escape use
  the same close path.
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
- Clock and Music start as minimal desktop widgets. A single click activates the
  widget and raises its stack order. Double-clicking empty widget space expands
  it into a floating panel; double-clicking again, the header Close control, or
  Escape returns it to minimal mode. Music transport controls retain their
  single-click actions and do not toggle panel mode.
- `FloatingPanel` provides an optional header-action row and right-side
  inspector loader. Clock and Music do not populate the inspector yet, so
  property interfaces can be added without changing drag, focus, or resize
  ownership.
- Minimal and expanded Clock and Music panels both use true geometry resize
  from every edge and corner. Handles are input-only and become available after
  the panel is activated. Dragging and resizing commit the geometry for the
  current mode.
- Desktop cards report committed geometry. `LayoutState` owns persistence and
  stores minimal and expanded rectangles separately.
- The system panel connects only to remembered Wi-Fi networks. Networks that
  require new credentials remain selectable, but their inspector action is
  disabled.
- The central Bluetooth control enables the default adapter or toggles
  discovery. The selected device inspector pairs unpaired devices, connects
  paired devices, cancels pairing in progress, or disconnects connected devices.
- Quick Settings shows at most six Wi-Fi networks or Bluetooth devices at once.
  Bluetooth cards include battery percentage when the device reports it.

## Input behavior

The desktop surface accepts pointer input only over visible Clock and Music
panels. Every other pixel is click through. Minimal widgets stay on the desktop
layer. Activating an expanded desktop panel temporarily raises their shared
surface above normal windows; it remains raised while either desktop panel is
expanded. Activating Quick Settings raises its own window instead. Within the
desktop surface, the last activated Clock or Music panel has the highest item
stack value.
