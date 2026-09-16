# Qt Multimedia Hot Reload Lessons

## 2026-09-16 - Active media teardown crashed during a QML generation reload

Context:
- The Video desktop widget used Qt Multimedia to loop a local preview while
  Quickshell watched the repository for configuration changes.

Failed approach:
- The active `MediaPlayer` retained its source, `VideoOutput`, and `AudioOutput`
  until normal child-object destruction during a hot reload.

Problem observed:
- Reloading the configuration while playback was active produced a segmentation
  fault inside `libffmpegmediaplugin.so`. Quickshell's first automatic restart
  then encountered the same test hook and exited again.

Root cause:
- The old QML generation discarded an active FFmpeg playback graph while the
  backend still owned attached outputs and posted work.

Lesson:
- Before a Video component is destroyed, stop its validation and fallback
  timers, detach both media outputs, stop playback, and clear the source. Defer
  source rejection to the next event-loop turn instead of tearing down a source
  directly from duration, track, status, or error callbacks.
