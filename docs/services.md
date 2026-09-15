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

`AudioSpectrum.qml` is one shell-wide adapter shared by every Music card. While
at least one Music card is expanded, the widget is enabled, and the selected
MPRIS player is playing, it starts the repository-owned
`.build/zshell-spectrum` helper and consumes 32 normalized frequency bands at
approximately 30 frames per second.

```text
default PipeWire sink
        |
pw-record stereo f32 PCM
        |
C++ Hann window + 2048-point FFT + 32 logarithmic bands
        |
semicolon-delimited 0-1000 frames
        |
AudioSpectrum attack/release smoothing -> Music cards
```

`native/spectrum.cpp` owns `pw-record` as a child process, averages its stereo
PCM to mono, covers 50 Hz through 12 kHz, and emits one newline-terminated frame
after every 1600 new samples. It handles termination and a closed output pipe by
stopping and reaping the capture child. The executable and its self-test are
built by `make build`; generated output stays under the ignored `.build/`
directory.

The adapter accepts only frames containing exactly 32 values, then applies fast
attack and slower release smoothing. Each expanded Music card registers a
request with the adapter, so multiple monitors still share one helper. Capture
stops when the last card collapses, or on pause, widget disable, or player
removal. A short local decay returns existing bands to zero before dropping the
ready state.
Missing build output, missing `pw-record`, unavailable monitor data, or malformed
frames leave the visualizer absent without changing Music metadata or transport
controls. The captured signal is the mixed default output rather than an audio
stream selected through MPRIS, so concurrent application audio contributes to
the same spectrum.
