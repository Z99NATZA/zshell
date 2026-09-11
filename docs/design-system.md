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
| Active scan sweep duration | `2600ms` |
| Radar entrance duration | `440ms` |
| Bubble entrance duration | `470ms` plus stagger |
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
`surfaceModal` applies an additional opacity reduction to large Clock and Music
panels so their footprint remains as light as the compact Dock surfaces.

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
  orb where bubbles extend upward.
- Radar entrance motion scales from `88%` through a `103.5%` overshoot and back
  to full size while fading in. The center orb shares that transform. Bubbles
  follow after a `360ms` lead with a `55ms` per-item stagger, overshoot to
  `110%`, rebound to `96%`, and settle at full size. Existing connection keys
  animate once per page entrance; ordinary service refreshes do not replay
  them, while newly discovered keys still receive an entrance.
- Connection bubbles use softened surfaces and move between random
  two-dimensional waypoints within a `10px` radius. Curved tethers keep their
  endpoints on deterministic blips, prefer a length of four large spacing
  units, use half that length in the lower radar half, and carry small animated
  accent pulses. Side bubbles follow their own radar bearing with lower-half
  angles reflected upward; targets in the central `12%` horizontal band retain
  vertical tethers. Connectors begin at the nearest card edge, and page-edge
  clamping adjusts only the affected tether. A pair of fading ripples marks each
  sweep encounter and explicit selection.
- Radar blips and their bubble connectors always use `Theme.accent`; connection
  state remains visible through each bubble's text and surface treatment.
- Use Quickshell service bindings for system changes. Aside from bounded visual
  feedback, the clock and active media progress are the only time-based updates.
