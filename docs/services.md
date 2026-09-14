# Services

## Keyboard layout

`KeyboardLayout.qml` owns the current keyboard label and configured layout list
used by both sides of the dock.

```text
startup or activelayout event
              |
      hyprctl devices -j
              |
        main keyboard
              |
          EN / TH
```

The service queries once at startup and again only after Hyprland emits an
`activelayout` event. It does not poll. Re-querying the device list keeps the
label tied to the current main keyboard when devices reconnect.

`layoutAliases` maps full keymap names to short labels. An unknown name falls
back to its first two characters; a missing or invalid response displays `--`.
The service parses the main keyboard's configured layout identifiers and maps
known identifiers to user-facing names. Selecting a layout runs
`hyprctl switchxkblayout <main-keyboard> <index>`; the resulting
`activelayout` event refreshes the shared state and both Dock indicators.

## Audio output

`AudioOutput.qml` binds the current PipeWire default output. It exposes the
volume label and icon used by the dock, and owns mute and volume changes.

Volume changes are clamped to 0–100%. A default-output change rebinds the
service without starting a process or polling.
