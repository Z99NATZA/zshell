# zshell

```text
- Date format Y-m-d
- Project created at 2026-09-08
- README.md updated at 2026-09-08
- Developed on Ubuntu
```

zshell is a quiet, responsive desktop shell for Hyprland. It provides a
floating dock, workspace controls, quick settings, and draggable desktop cards
while keeping the current Waybar setup untouched.

## Requirements

- Hyprland on Wayland
- Quickshell `0.3.1` or newer
- NetworkManager and BlueZ
- An MPRIS-compatible media player
- JetBrains Mono Nerd Font

Follow the current
[Quickshell installation guide](https://quickshell.org/docs/v0.3.1/guide/install-setup/)
for your distribution.

## Run | [More...](docs/runtime-integration.md)

```bash
# Verify
make check

# Run from this repository
make run
```

The project runs directly from its repository and does not need to be copied
into `~/.config` during development. Startup integration is intentionally not
enabled by the MVP.

## Interaction

- Select a workspace from the center dock island.
- Select Wi-Fi, Bluetooth, or the clock to open quick settings.
- Select the cross-arrows control to enter layout edit mode.
- Drag the clock or media card while edit mode is active.
- Select the palette control to switch between One Half Gray and One Half Light.

The visual system uses semantic theme tokens, a `6px` corner radius, and `180ms`
interaction motion. Card positions and the selected theme persist across shell
restarts.

## Documentation

- [Architecture](docs/architecture.md)
- [Components](docs/components.md)
- [Design system](docs/design-system.md)
- [Runtime integration](docs/runtime-integration.md)
- [State management](docs/state-management.md)

## MIT [LICENSE](LICENSE)
