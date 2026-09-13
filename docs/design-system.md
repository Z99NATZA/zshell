# Design System

zshell uses a quiet, compact interface where hierarchy comes from spacing,
color, and motion rather than decoration or repeated labels.

## Baseline

| Token | Value |
| --- | --- |
| Corner radius | `6px` |
| Interaction duration | `180ms` |
| Modal open duration | `280ms` |
| Modal close duration | `220ms` |
| Radio pulse duration | `1800ms` |
| Radar sweep duration | `4800ms` |
| Radar entrance duration | `440ms` |
| Bubble entrance duration | `280ms` after its first sweep encounter |
| Motion easing | `Easing.OutCubic` |
| Workspace icon | `Theme.workspaceIcon` |
| UI font | `JetBrainsMono Nerd Font` |
| Text font | `JetBrains Mono` |

## Color roles

`theme/Theme.qml` owns every color. Components use semantic roles such as
`surface`, `border`, `text`, `textMuted`, `accent`, and `danger`; raw colors are
not allowed outside the theme owner.

The persisted component opacity applies to all surface and border roles. It
does not reduce the opacity of foreground text, icons, or media artwork.
Quick Settings and the Clock and Music panels use the same `surfaceRaised`
opacity in both minimal and expanded modes.

Connection bubbles use dedicated glass surface roles. Their base alpha is
`54%` in the gray theme and `62%` in the light theme, multiplied by the shared
component opacity. Raised bubbles use `68%` and `76%` respectively. A subtle
vertical sheen and shade preserve the bubble edge while allowing radar lines
to remain visible through the body. Six Canvas profiles use a related
tall-center silhouette with distinct upper-lobe rhythms. Rounded sides flow into
long, gently curved bases rather than repeated lower scallops. The
collision-safe radar slot selects the profile, so up to six visible targets have
distinct clouds. Each profile is one unified path, avoiding darker seams where
lobes would otherwise overlap. The `184x80` surface normalizes each silhouette's
vertical range into a safe Canvas inset and uses rounded stroke joins. This lets
every cloud fill the available space while preserving its full crown and base
without texture-edge clipping.

The default variant is One Half Gray. One Half Light demonstrates that visual
components remain independent from a specific palette. Theme selection is
persisted with the layout state.

Change the leading workspace glyph in `Theme.workspaceIcon`. Dock layout code
does not own the icon value.

## Interface rules

- Omit a title or label when the value and icon already explain the component.
- Keep persistent chrome compact; reveal detail on demand.
- Prefer borders and surface contrast over heavy shadows.
- Reserve fully round shapes for indicators and progress details.
- Avoid large-area blur. The MVP uses no blur.
- Hide absent content instead of rendering an empty placeholder card.
- Minimal widgets stay visually quiet; hover cursors communicate their drag and
  resize affordances without a visible outer border.
- Resize handles remain visually transparent and communicate direction only
  through the platform horizontal, vertical, or diagonal cursor. Their `12px`
  edge and `24px` corner targets make floating desktop panels easier to grab.
- Expanded desktop panels place Title, Pin, and Close within the modal padding,
  without a separate header strip or divider. Minimal and expanded panels share
  the Quick Settings modal radius. Body layout reflows from actual width and
  height; panel resize never scales a rendered snapshot.
- Quick Settings and the Clock and Music surfaces keep a transparent outer
  border in both minimal and expanded modes. Borders inside those surfaces keep
  their semantic theme colors.
- Expand Quick Settings from its invoking Dock control and collapse it back to
  the same target. Opening uses `Easing.OutCubic`; closing uses `Easing.InCubic`.

## Motion and performance

- Animate opacity, color, position, and bounded progress changes.
- Animate minimal-to-expanded geometry from the widget's current center and
  restore the separately persisted minimal rectangle on collapse.
- Limit large translucent surface animation to bounded open and close motion;
  never animate one continuously or continuously sample idle data.
- The central radio pulse travels from the core to the radar's second grid ring
  while its matching Quick Settings page is visible. It scales with the radar,
  stops with the modal, and never samples system state on a timer.
- Connection radar sweeps use small cached Canvas surfaces and run only while
  their radio and matching Quick Settings page are active. Target positions
  are deterministic so service refreshes do not make cards or blips jump. Blips
  use a continuous `20%` to `47%` radial range spanning the first four grid
  lines counted from the outside, with added center clearance below the radio
  orb where bubbles extend upward. The sweep keeps a crisp leading line and a
  broad `70deg` sector whose opacity eases smoothly to zero at the trailing
  edge. It completes every rotation in `4800ms`; live discovery never changes
  that angular speed.
- Radar entrance motion scales from `88%` through a `103.5%` overshoot and back
  to full size while fading in, beginning alongside the panel open transition.
  The center orb shares that transform. Each blip and bubble stays hidden until
  the sweep line first crosses its target. The blip fades and scales into view;
  the bubble eases from `86%` to full size over `280ms` without overshoot or
  rebound. Each connection key keeps that reveal state for the current page
  entrance. A delegate recreated by a Wi-Fi or Bluetooth scan appears settled
  instead of replaying visible entrance motion. Newly discovered keys wait for
  their own first encounter. Bubble drift starts on the next event-loop turn
  after entrance motion settles, allowing its offset behavior to engage before
  the first waypoint changes. Closing the panel or leaving a connection page
  stops its running entrance and pending reveal immediately.
- Connection bubbles use softened glass cloud surfaces and move between random
  two-dimensional waypoints within a `10px` radius. Curved tethers keep their
  endpoints on deterministic blips, prefer a length of four large spacing
  units, use half that length in the lower radar half, and carry small animated
  accent pulses. Side bubbles follow their own radar bearing with lower-half
  angles reflected upward; targets in the central `12%` horizontal band retain
  vertical tethers. Connectors use an elliptical boundary approximation to
  meet the nearest cloud edge, and page-edge clamping adjusts only the affected
  tether. A pair of fading ripples marks each sweep encounter and explicit
  selection.
- Radar blips and their bubble connectors always use `Theme.accent`; connection
  state remains visible through each bubble's text and surface treatment.
- Use Quickshell service bindings for system changes. Aside from bounded visual
  feedback, the clock and active media progress are the only time-based updates.
