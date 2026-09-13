# Runtime Integration

The MVP runs directly from the repository and is designed to replace Waybar.
Repository commands do not modify Hyprland startup automatically.

## Requirements

- Hyprland on Wayland
- Quickshell `0.3.1` or newer
- NetworkManager and BlueZ for system controls
- PipeWire for reactive output volume control
- An MPRIS-compatible player for the media card
- `hypr-power-menu` on `PATH` for the dock power button
- JetBrains Mono Nerd Font for shell icons

Ubuntu packages Quickshell through the DankLinux PPA. Follow the current
[official installation guide](https://quickshell.org/docs/v0.3.1/guide/install-setup/)
rather than copying package commands into this repository.

## Commands

```bash
make check
make run
```

`make run` invokes `qs -p <repository>`, which gives the project a stable shell
ID and state directory through the pragmas in `shell.qml`. The runner owns that
Quickshell child process: interrupting `make run`, including Kitty's
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
- Missing `hypr-power-menu` leaves the power button visible, but the action
  exits without opening a menu.
- Layout writes are atomic. A write error is reported by Quickshell and does not
  replace the previous state file.
