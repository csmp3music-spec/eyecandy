# eyecandy

Native macOS Swift arm64 video-feedback instrument for high-definition psychedelic visuals.

## What it does

- Renders recursive video feedback in real time with a Metal pipeline.
- Ships 100 presets across 10 effect families inspired by CRT feedback, hall-of-mirrors optics, prisms, kaleidoscopes, plasma tunnels, raster/twister demoscene motifs, xor/moire interference, fractal bloom, and parallel-universe portal views.
- Exposes granular controls for feedback, geometry, color, texture, audio, and capture in a collapsible inspector so the canvas stays dominant.
- Records the generated output directly to MP4.
- Procedurally generates a matching soundtrack with mute, deeper synth controls, and optional audio-reactive visual sync.
- Includes a Jeff Minter-inspired color-space mode, fullscreen mode, and a live-output window for a projector or second monitor.

## Build

```bash
swift build
swift run
```

To build a distributable arm64 app bundle:

```bash
./tools/package_app.sh
open dist/eyecandy.app
```

## Controls

- `Prev` / `Next`: step through the preset library.
- `Random`: generate an experimental variation around a preset.
- `Mute`: toggle the procedural soundtrack.
- `Live Output`: open a clean output window for a projector or second display.
- `Fullscreen`: toggle the performance window fullscreen state.
- `Record MP4`: export the current visual stream.
- `Show Controls` / `Hide Controls`: collapse the inspector.

## Preset Families

- `True Feedback`
- `Hall of Mirrors`
- `Prism Simulator`
- `Chroma + Luma`
- `Kaleidoscope`
- `Plasma Tunnel`
- `Raster + Rotozoom`
- `XOR + Moire`
- `Fractal Bloom`
- `Parallel Universe`
