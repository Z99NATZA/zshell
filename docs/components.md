# Components

## At a glance

| Component | Responsibility |
| --- | --- |
| `Dock` | Workspace actions, system tray, audio, time, language, and power |
| `QuickSettingsPanel` | Wi-Fi, Bluetooth, theme, and desktop widget controls |
| `ConnectionCard` | Shared selectable network and Bluetooth target bubble |
| `ConnectionInspector` | On-demand connection details and explicit primary action |
| `RadarField` | Theme-native connection grid, sweep, and target blips |
| `RadioOrb` | Shared animated Wi-Fi and Bluetooth radio control |
| `ResizeHandle` | Invisible edge and corner geometry-resize input |
| `PanelShadow` | Shared contact shadow behind top-level floating surfaces |
| `FloatingPanel` | Shared focus, chrome, drag, resize, and inspector slots for desktop widgets |
| `WidgetVisibilityCard` | Shared Clock and Music visibility switch row |
| `DesktopSurface` | Desktop-layer composition and click-through regions |
| `ClockCard` | Minimal clock and expanded floating time panel |
| `MusicCard` | Minimal MPRIS controls and expanded now-playing panel |
| `LanguageIndicator` | Current keyboard label and layout-selection drop-up |
| `SystemTrayButton` | StatusNotifier icon and pointer actions |
| `ActionButton` | Shared compact hover, active, and disabled behavior |
| `ShellSurface` | Shared surface, border, radius, and color transitions |

## Boundaries

- Visual components consume semantic theme roles; they do not define palettes.
- Quick Settings, Clock, and Music use the shared `PanelShadow` behind their
  outer surfaces. Three low-opacity solid underlays create edge separation
  without an outer border, blur texture, or active-state emphasis. Internal
  cards and controls do not receive panel shadows.
- Quick Settings uses a `960x680` modal and presents Wi-Fi networks or
  Bluetooth devices as persistent bubbles over their targets on a circular
  radar. Its bottom switch changes modes without closing the panel.
- Every visible connection has a stable pseudo-random radar blip derived from
  its identity. Collision-safe angular slots and a broad continuous radial
  range distribute targets between the first four grid lines counted from the
  outside, rather than collecting around one ring. Lower targets retain extra
  center clearance for their upward-extending bubbles, while other targets may
  sit near the radar edge. Every bubble overlays the radar and moves through
  random waypoints within `10px` of its stable base position. A curved animated
  tether uses a preferred length of four large spacing units, reduced by `50%`
  for targets in the lower radar half. Side bubbles fan outward at the bearing
  of their own blip, with lower-half bearings reflected upward to keep cards
  inside the connection area. Targets within the radar's central `12%`
  horizontal band keep vertical tethers and centered bubbles. The connector
  begins at the nearest card edge and compensates for bubble movement so its
  endpoint remains attached to the blip. Page-edge clamping redirects only the
  affected tether. Six translucent cloud silhouettes share a tall-center visual
  family while varying the rhythm and balance of their upper lobes. Rounded
  sides flow into long, gently curved bases instead of repeated lower scallops.
  The target's collision-safe radar slot selects a unique silhouette while up to
  six bubbles are visible. Each cloud is drawn as one path with a vertical glass
  sheen, so radar lines remain visible behind it without overlap-darkened seams.
  The `184x80` card normalizes each silhouette's own vertical range into an
  internal Canvas inset. Every cloud uses the available space while its crown
  and base remain fully visible instead of clipping at the texture edge.
  Every cloud centers its connection icon, name, and status in a vertical
  stack.
  Connected, selected, and swept bubbles receive a brighter surface or accent
  edge without making idle clouds opaque. The sweep briefly raises the matching
  bubble and launches two fading ripples from its blip without changing the
  underlying target position.
- Opening Quick Settings or switching between Wi-Fi and Bluetooth gives the
  active radar a scale-and-opacity overshoot. Each blip and bubble remains
  hidden until the sweep line first crosses its target. The blip then fades and
  scales into view while the bubble eases once from `86%` to full size without
  a rebound. Connection keys are claimed once per page entrance after that
  first sweep encounter. A delegate recreated by a scan appears settled when
  its key was already revealed instead of replaying the entrance. A newly
  discovered key waits for its own first sweep encounter.
  Radar entrance starts with the panel open transition instead of waiting for
  it to finish. Bubble drift and connector repainting begin after panel and
  bubble entrance motion settles. Closing or leaving the page immediately
  stops pending entrance timers and animations.
- Clicking a connection bubble selects its radar target and opens the detail
  inspector; it never changes connection state directly. The radar shifts left
  while the inspector slides in from the right. A second click, the close
  control, an empty radar click, or Escape clears the selection.
- The inspector exposes signal and security for Wi-Fi or address, trust, and
  available battery data for Bluetooth. Connect, disconnect, pair, and cancel
  pairing are explicit inspector actions. Connecting and disconnecting use the
  backend state to show a pulsing progress label and reject repeated clicks;
  pairing remains cancellable. Wi-Fi profiles requiring credentials remain
  selectable for detail but cannot connect in this first version.
- The central Wi-Fi and Bluetooth controls are passive indicators with no
  status row or scan action. They gently pulse only while their radio is active
  and matching Quick Settings page is visible. A page-specific header control
  owns radio power, while background discovery is represented by radar motion.
  The sweep keeps the same angular speed during live Wi-Fi and Bluetooth
  discovery.
- Quick Settings opens unpinned as a modal. Clicking outside dismisses it. The
  header Pin control keeps it open and restricts its input region to the panel,
  allowing outside clicks to reach other windows. Pin remains temporary: the
  explicit Close control or Escape closes the panel and resets Pin. When the
  connection inspector is open, the first Escape closes only the inspector.
- Drag the Quick Settings header, including its surrounding padding and gaps,
  to move the panel. Header controls keep their own click targets. The committed
  position is restored across restarts and clamped to the current screen.
- Resize Quick Settings from any edge or corner. Invisible handles expose only
  directional cursors, enforce an `860x620` minimum when the screen permits,
  and persist committed size with position. The radar responds between `400px`
  and `620px` while the header and footer retain their fixed heights.
- Quick Settings expands from the Dock control that opened it and collapses
  back to that control when dismissed. Its header Close control and Escape use
  the same close path.
- Quick Settings adjusts every component surface from fully transparent to
  opaque in 10% steps. Its own surface and the Clock and Music surfaces use the
  same selected opacity in both minimal and expanded modes. Text, icons, and
  media artwork remain opaque.
- The Quick Settings footer includes a `Widgets` page beside Wi-Fi and
  Bluetooth. It toggles persisted Clock visibility and whether Music may appear
  when media is available. The Dock time control opens this page directly.
- `ActionButton` owns reusable control feedback. Pressing an enabled button
  briefly scales it to `96%`. Compact icon-only instances use circular hover,
  pressed, and active surfaces that switch directly to the shared soft color
  without interpolation; controls containing text retain the standard rounded
  rectangle and color transition. A busy button blocks repeated activation,
  keeps full opacity, uses the busy cursor, and pulses its content. Feature
  components own layout and decide when an operation is busy.
- The workspace switcher starts with the configurable `Theme.workspaceIcon`.
  Clicking the icon opens the same Rofi application launcher as the Hyprland
  `Super+I` binding. Its numbers have no shared container, and the active
  workspace uses a high-contrast circular indicator.
- Both language indicators consume the same `KeyboardLayout` state. Clicking
  either label opens a focus-grabbing drop-up above the Dock, marks the active
  layout, and dismisses the menu after selection or an outside click.
- The dock volume button toggles mute on click and changes volume by 5% per
  mouse-wheel step.
- The Dock renders one compact button for each StatusNotifier tray item and
  uses a circular interaction surface and leaves no empty tray placeholder
  when no items are registered. Its interaction surface switches directly to
  the shared soft color without interpolation. Left click activates the item,
  right click opens its menu, middle click invokes its secondary action, and
  wheel input is forwarded to the item. Menu-only items open their menu on left
  click.
  Hovering for 500ms opens a non-focusable tooltip above the icon. The tooltip
  prefers the item's tooltip title, falls back to its application title or ID,
  keeps that title on one line, and shows up to three description lines. If an
  item unregisters, its delegate rejects further input and immediately
  dismisses its hover timer and tooltip before the model removes the delegate.
- Dock Wi-Fi and Bluetooth labels are capped at 12 characters. Bluetooth shows
  the first connected device and reserves space for `+N` when more are active;
  Quick Settings keeps the full names.
- The Dock is the sole Power entry point. Its button delegates to
  `hypr-power-menu`; it never runs a session or machine power action directly.
- Clock and Music start as minimal desktop widgets. A single click activates the
  widget and raises its stack order. Double-clicking empty widget space expands
  it into a floating panel through true geometry resize. Expansion keeps the
  minimal panel's left and top edges fixed and grows right and down whenever
  both dimensions fit. An axis reverses independently when its preferred side
  lacks room, so a bottom-left widget grows right and up. Expanded panels stay
  open when focus moves or the user clicks outside. The header Collapse control
  or Escape returns the panel to minimal mode. Music transport controls retain
  their single-click actions and do not toggle panel mode.
- Expanded Clock and Music headers provide separate Collapse and Close actions.
  Collapse restores the persisted minimal rectangle. Close first restores that
  rectangle and then hides the widget by turning off its persisted Widgets-page
  visibility switch; the switch is the path for showing it again.
- Clock and Music use the same `Theme.radius * 3` corner radius as Quick
  Settings in both modes. Their expanded mode is one uninterrupted translucent
  surface: Title, Collapse, and Close sit inside its padding without a separate
  header fill or divider, and the surrounding top region remains the drag
  target.
- `FloatingPanel` provides an optional header-action row and right-side
  inspector loader. Clock and Music do not populate the inspector yet, so
  property interfaces can be added without changing drag, focus, or resize
  ownership.
- Minimal and expanded Clock and Music panels both use true geometry resize
  from every edge and corner. Input-only handles use a `12px` edge area and a
  larger `24px` corner area, and become available after the panel is activated.
  Dragging and resizing commit the geometry for the current mode.
- Desktop cards report committed geometry. `LayoutState` owns persistence and
  stores minimal and expanded rectangles separately.
- Hiding an expanded desktop card restores its minimal geometry. Showing it
  again restores the last committed minimal rectangle, raises it above normal
  applications and the other desktop card, and leaves focus with Quick
  Settings. Music still requires an available MPRIS player.
- The system panel connects only to remembered Wi-Fi networks. Networks that
  require new credentials remain selectable, but their inspector action is
  disabled.
- Opening the Wi-Fi page enables Quickshell's live scanner so available access
  points populate the radar. The scanner stops when the page or panel closes;
  saved and connected networks remain available through NetworkManager.
- Opening the Bluetooth page starts a 15-second BlueZ discovery session. While
  the page remains open, Quick Settings waits 30 seconds after each owned
  session and then starts another one. Leaving the page or closing the panel
  cancels the cycle, and discovery started elsewhere is never stopped. The
  selected device inspector pairs unpaired devices, connects paired devices,
  cancels pairing in progress, or disconnects connected devices.
- Quick Settings shows at most six Wi-Fi networks or Bluetooth devices at once.
  Connected entries rank first, followed by saved Wi-Fi or paired Bluetooth
  entries; remaining Wi-Fi entries rank by signal. The footer reports the full
  discovered count when the radar is capped. Bluetooth cards include battery
  percentage when the device reports it.

## Input behavior

The desktop surface accepts pointer input only over visible Clock and Music
panels. Transparent outside regions always pass input through while an expanded
panel stays open. Minimal widgets start on the desktop layer. Clicking either
minimal widget promotes the shared surface above the other zshell panels, just
as activating an expanded widget does. Re-enabling a minimal widget promotes
the shared surface to the top layer above normal applications while Quick
Settings keeps focus on the overlay layer. Opening Quick Settings from another
component clears the previous promotion and returns inactive minimal widgets to
the desktop layer; an inactive expanded widget remains above normal windows.
Within the desktop surface, the last activated Clock or Music panel has the
highest item stack value.

Pressing a Clock or Music drag area temporarily expands the desktop surface's
input mask to the full screen until release or cancellation. This preserves the
pointer grab during fast movement; normal outside click-through resumes as soon
as the drag ends.
