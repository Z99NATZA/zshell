# zshell

zshell is a quiet, responsive desktop shell for Hyprland. The MVP provides a
floating dock, workspace navigation, a compact system panel, and draggable
clock and media cards without replacing the current Waybar setup.

## At a glance

| Area | Current behavior |
| --- | --- |
| Runtime | Quickshell 0.3.1 or newer on Wayland |
| Visual system | Semantic One Half Gray tokens, 6 px radius, 180 ms motion |
| Integrations | Hyprland, NetworkManager, BlueZ, and MPRIS |
| Layout | Clock and media positions persist in the zshell state directory |
| Safety | Manual launch only; Waybar and Hyprland configuration remain unchanged |

## Run the MVP

Install Quickshell 0.3.1 or newer, then run:

```bash
make run
```

The project can run directly from its repository. It does not need to be copied
into `~/.config` during development.

Run repository checks with:

```bash
make check
```

See [Runtime integration](docs/runtime-integration.md) before enabling startup
or replacing any existing desktop component.

## Interaction

- Select a workspace from the center dock island.
- Select Wi-Fi or Bluetooth status to open the system panel.
- Select the cross-arrows control to enter layout edit mode.
- Drag the clock or media card while edit mode is active.
- Select the palette control in the system panel to switch theme variants.

## Documentation

[Architecture](docs/architecture.md) is the entry point. Each document owns one
current subsystem and is intentionally short enough to scan.
