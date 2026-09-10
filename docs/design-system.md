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
- Expose drag affordances only while layout edit mode is active.
- Expand Quick Settings from its invoking Dock control and collapse it back to
  the same target. Opening uses `Easing.OutCubic`; closing uses `Easing.InCubic`.

## Motion and performance

- Animate opacity, color, position, and bounded progress changes.
- Limit large translucent surface animation to bounded open and close motion;
  never animate one continuously or continuously sample idle data.
- The central radio pulse travels from the core to the radar's second grid ring
  while its matching Quick Settings page is visible. It scales with the radar,
  stops with the modal, and never samples system state on a timer.
- Connection radar sweeps use small cached Canvas surfaces and run only while
  their radio and matching Quick Settings page are active. Target positions
  are deterministic so service refreshes do not make cards or blips jump.
- Radar blips and their bubble connectors always use `Theme.accent`; connection
  state remains visible through each bubble's text and surface treatment.
- Use Quickshell service bindings for system changes. Aside from bounded visual
  feedback, the clock and active media progress are the only time-based updates.
