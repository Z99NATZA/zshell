# Runtime Integration

The MVP runs directly from the repository and is designed to replace Waybar.
Repository commands do not modify Hyprland startup automatically.

## Requirements

- Hyprland on Wayland
- Quickshell `0.3.1` or newer
- Qt Multimedia and Qt Quick Dialogs QML modules for Video playback and file
  selection (`qml6-module-qtmultimedia` and `qml6-module-qtquick-dialogs` on
  Ubuntu)
- NetworkManager and BlueZ for system controls
- PipeWire for reactive output volume control
- `pw-record` from PipeWire tools for default-output spectrum capture
- A C++20 compiler for building the repository-owned spectrum helper
- An MPRIS-compatible player for the media card
- `hypr-power-menu` on `PATH` for the dock power button
- JetBrains Mono Nerd Font for shell icons

Ubuntu packages Quickshell through the DankLinux PPA. Follow the current
[official installation guide](https://quickshell.org/docs/v0.3.1/guide/install-setup/)
rather than copying package commands into this repository.

## Commands

```bash
make build
make check
make run
```

`make build` compiles `native/spectrum.cpp` into the ignored
`.build/zshell-spectrum` executable. `make check` and `make run` rebuild it only
when the source is newer. The check target runs the helper's silence and 440 Hz
FFT self-test before the repository checks.

`make run` then invokes `qs -p <repository>`, which gives the project a stable
shell ID and state directory through the pragmas in `shell.qml`. The runner owns
that Quickshell child process: interrupting `make run`, including Kitty's
`Super+\\` mapping to `Ctrl+C`, terminates the child before the runner exits.

The root configuration opts into `QApplication` mode so StatusNotifier items
can display their platform menus. Changing this pragma requires a full
Quickshell process restart; configuration hot reload is not sufficient.

## Machine boundary

Repository implementation does not authorize any of these operations:

- installing or removing packages;
- linking files under `~/.config/quickshell`;
- editing `~/.config/hypr/hyprland.conf`;
- stopping Waybar or enabling zshell at login.

Those changes require an explicitly agreed machine-integration scope. During
normal use, run either zshell or Waybar rather than both. The zshell Dock sits
directly on the bottom edge with a transparent background and no outer margins.
It still reserves its 44-pixel height so normal windows never overlap it.

## Failure behavior

- Missing Quickshell stops `scripts/run.sh` with a direct requirement message.
- Missing NetworkManager, BlueZ, or MPRIS data hides or disables only the
  affected controls; the shell remains usable.
- Missing PipeWire output data disables the volume control.
- Missing spectrum build output, `pw-record`, or default-output monitor data
  hides only the expanded Music ring; metadata, progress, artwork, and transport
  controls remain available. `make build` itself fails directly when no C++20
  compiler exists.
- Missing Qt Multimedia or Qt Quick Dialogs prevents the configuration from
  loading because Video owns direct QML imports for playback and file selection.
- An unavailable, invalid, audio-only, zero-duration, or longer-than-30-second
  Video source remains uncommitted; the card reports the failure and restores
  its last valid preview when one exists.
- The power button resolves `hypr-power-menu` through the user's Bash login
  environment, so commands installed in `~/.local/bin` remain available even
  when the Quickshell process starts with a system-only `PATH`.
- Missing `hypr-power-menu` leaves the power button visible, but the action
  exits without opening a menu.
- Layout writes are atomic. A write error is reported by Quickshell and does not
  replace the previous state file.
