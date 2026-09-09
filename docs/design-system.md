# Design System

zshell uses a quiet, compact interface where hierarchy comes from spacing,
color, and motion rather than decoration or repeated labels.

## Baseline

| Token | Value |
| --- | --- |
| Corner radius | `6px` |
| Interaction duration | `180ms` |
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
- Reveal transient panels with a short fade and vertical settle, both using the
  shared interaction duration.

## Motion and performance

- Animate opacity, color, position, and bounded progress changes.
- Do not animate large translucent surfaces or continuously sample idle data.
- Use Quickshell service bindings for system changes. The clock and active media
  progress are the only time-based updates in the MVP.
