# zshell

```text
- Date format Y-m-d
- Project created at 2026-09-08
- README.md updated at 2026-09-08
- Developed on Ubuntu
```

zshell is a quiet, responsive desktop shell for Hyprland. It provides a
floating dock, workspace controls, quick settings, and draggable desktop cards.

## Requirements

```text
Required
- Ubuntu with Hyprland on Wayland
- Quickshell 0.3.1 or newer

Used by shell components
- NetworkManager: Wi-Fi status and controls
- BlueZ: Bluetooth status and controls
- MPRIS-compatible player: media card
- JetBrains Mono Nerd Font: interface icons
```

## Installation

```bash
# Ubuntu: install the latest stable Quickshell release
sudo add-apt-repository ppa:avengemedia/danklinux
sudo apt update
sudo apt install quickshell

# Verify
qs --version
```

For other distributions, use the
[official Quickshell installation guide](https://quickshell.org/docs/v0.3.1/guide/install-setup/).

## Run | [More...](docs/runtime-integration.md)

```bash
# Open the project
cd ~/my_code/zshell

# Check the project
make check

# Run
make run

# Stop
# Press Ctrl+C in this terminal
```

```text
- The project runs directly from this repository.
- Files do not need to be copied into ~/.config during development.
- Startup integration is not enabled by the MVP.
- The current Waybar and Hyprland startup configuration remain unchanged.
```

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
