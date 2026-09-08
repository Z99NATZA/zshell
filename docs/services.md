# Services

## Keyboard layout

`KeyboardLayout.qml` owns the current keyboard label used by both sides of the
dock.

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
