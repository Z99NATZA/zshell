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

## Music spectrum

`CavaSpectrum.qml` owns frequency capture for one expanded Music card. While
that card has playing media, it starts CAVA with the repository-owned
`services/cava.conf` and consumes 32 mono frequency bands from newline-delimited
ASCII output at 30 frames per second.

```text
default output monitor -> CAVA -> raw ASCII frames -> smoothed 0.0-1.0 bands
```

CAVA uses the PulseAudio-compatible default-output monitor so it works through
`pipewire-pulse` on the target PipeWire desktop. The captured signal is the
mixed default output, not an audio stream selected through MPRIS. Concurrent
application audio therefore contributes to the same spectrum.

The adapter applies fast attack and slower release smoothing, and exposes the
first six bands as a bass average for artwork feedback. Capture stops on pause,
collapse, close, or player removal. A short local decay returns existing bands
to zero; the adapter then drops its ready state. Missing CAVA, an unavailable
output monitor, or malformed frames leave the visualizer absent without
changing Music metadata or transport controls.
