# Panel Shadow Rendering Lessons

## 2026-09-13 - Auxiliary shadow surfaces exposed their bounds

Context:
- Clock, Music, and Quick Settings needed subtle separation where their dark
  surfaces overlap.

Failed approach:
- Full-panel Canvas shadows and broad transparent outline-ring items surrounded
  each panel with auxiliary rendering bounds.

Problem observed:
- The Canvas bounds appeared as a translucent rectangle after geometry changes.
  The outline-ring replacement then exposed bright green transparency artifacts
  around the panel on the target layer-shell runtime.

Root cause:
- Auxiliary transparent rendering areas around these layer-shell children did
  not composite reliably on the target runtime.

Lesson:
- Keep panel shadows to a small number of ordinary solid rounded underlays that
  sit behind the opaque panel. Do not use full-panel Canvas effects or broad
  transparent ring fields for top-level layer-shell shadows in this project.
