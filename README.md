# sonic screwdriver eyecandy

A rebuilt Swift desktop app for psychedelic visuals and experimental music performance.

Current rebuilt features:

- 284 procedural psychedelic video presets: 220 generated family presets plus 64 named Jeff Minter-inspired signature presets.
- 150+ video performance presets, including 128 new named psychedelic show presets that vary visual engines, Minter modes, demoscene layers, chroma/luma video modes, frame rates, and recording resolutions.
- Dropdown inspector navigation for presets, sequencer, synth, drums, keyboard, light synth, feedback/camera, performance, broadcast, and output.
- New default `Studio` dashboard that brings transport, quantized scene launch, live scene deck recall, bus mixer, and visual output safety into one performance view.
- Inspector workflow improvements: quick panel jump buttons, compact live status strip, searchable visual presets, and an always-visible AppKit-backed vertical scrollbar for long control panels.
- Audio-reactive analyzer visualizer modes: Spectrum Tunnel, Oscilloscope Garden, Chroma Vectorscope, Spectral Particles, and Hyper Analyzer.
- Expanded analyzer modes: Feedback Waveform, Spectral Lattice, and Phase Bloom for MilkDrop-style wave/mesh/bloom responses.
- Live analyzer metrics for bass, mid, high, transient/flux, spectral centroid, and stereo balance drive the visualizer layers instead of relying only on beat timing.
- SwiftUI TimelineView/Canvas renderer with beat-reactive symmetry, tunnels, rings, demoscene scan lines, and modulation.
- Jeff Minter-inspired neon grid, orbiting light-synth, and arcade vortex overlays.
- Modernized Minter core modes inspired by Psychedelia, Colourspace, VLM/Neon, Tempest/TxK-style vector webs, Space Giraffe, Polybius tunnels, Gridrunner lattices, Neon Loopz, and LlamaTron trails.
- Holographic scan-volume, chroma-depth, interference, Pepper Ghost stage, light-field volume, CGH speckle, and realistic-stack overlays.
- 80s/90s demoscene overlays: Amiga copper bars, VGA plasma, rotozoomer, vector balls, star tunnel, sine scroller, chunky VGA, and Mega Demo mode.
- Advanced light-synth panel with XY macro pad, photon director, flash safety, prism splits, phosphor persistence, and Trip Max/Safe Cruise performance buttons.
- Experimental video modes: Colourspace, Neon Pulse, slit-scan, feedback ghosts, chromatic aberration, datamosh blocks, VHS melt, pixel-sort trails, codec tearing, RGB delay, halftone posterization, optical-flow smear, recursive mirror feedback, liquid lens, kaleido feedback, solarized contours, phosphor burn, tunnel fold, chroma light leaks, and stacked demoscene processing.
- Expanded chroma/luma processor modes: Luma Key Bloom, Chroma Invert, Edge Trace, Oscillator Bank, Vector Scope, and Scan Gate with key threshold, edge gain, color warp, and oscillator-rate controls.
- Expanded visual engines: reaction-diffusion, kaleidoscope maze, moire field, slit-scan ribbons, and cellular automata.
- Light-synth modes: Hyper Prism, Lissajous Laser, Recursive Bloom, Acid Scope, Photon Storm, Neural Mandala, and Everything.
- Minter/laser colourspaces: Colourspace, Yak Neon, Phosphor, and Laserium palettes.
- Full performance controls: eight-slot scene deck, palette modes, blend/key styles, blackout, freeze frame, strobe gate, strobe safety, and MP4 parity.
- A/B scene morphing: pick two saved scene slots, crossfade continuous parameters, and generate an eight-scene performance deck for live sets.
- Quantized scene launch: trigger scene recalls immediately, on the next beat, next bar, or every four bars, with queued-launch HUD feedback.
- Beat-synced multitap delay FX with per-tap beat offset, level, feedback, and visual spread.
- Golden Phi tempo mode: sets 161.8 BPM, phi-derived swing, a 13-step loop, and golden-ratio delay taps for audio/visual echoes.
- Expanded sequencer and synths: groove templates, scale-aware acid/lead generators, mutation/humanize tools, lane probability, velocity, ratchets, per-lane lengths, audible clap sequencing, granular/wavetable/FM/ring/phase/reese/bitcrush instruments, and granular oscillator controls.
- Advanced composition tools: style-based full composition generator, Euclidean drum generator, counter-melody builder, live-key capture into the lead lane, pattern rotation, mirroring, inversion, density/variation macros, and expanded scale modes.
- Scrollable synth panel with quick voice presets and per-voice randomization for fast live sound design.
- Music-reactive visual multitap delay: delayed audio taps create matching delayed visual ghost rings and rays in live view and MP4 export.
- Expansive visual engine selector: Light Tunnel, Vector Field, Metaballs, Terrain Grid, Oscilloscope Ribbons, Fractal Lightning, Particle Nebula, Shape Constellation, Liquid Cells, and Engine Autopilot.
- Fractal Trees engine for branching organic light forms.
- Every preset change hard-cuts the screen and procedurally regenerates a new visual scene/profile instead of only recoloring the previous design.
- Named Jeff Minter-inspired signature presets with tuned Minter modes, palettes, engines, light-synth modes, demoscene layers, and holographic layers.
- Stereoscopic output modes: red/cyan anaglyph, side-by-side, top/bottom, line interlace, and depth ghost with stereo depth control.
- AVAudioEngine procedural synth output with stereo master drive, width control, safety limiter, and live peak/gain-reduction meters.
- Production-style bus mixer for bass, lead, drums, live keys, and FX return with per-bus level, pan, send, mute, and solo controls.
- Visual output mastering controls for lower default brightness, plus live `Visual Gain` and `Visual Soft Clip` controls to keep neon palettes vivid without blowing out the frame.
- Expanded synth instruments: Acid Saw, Sub Square, Super Saw, FM Bell, Glass Pad, Noise Organ, Sync Lead, Formant Vox, Buchla Complex, Mellotron Tape, Solina Stringer, Synclavier Digital, and Vector Morph.
- 16-step bass, lead, kick, snare, hat, and clap pattern editing.
- Analog bass and lead voice controls.
- Drum preset library.
- 20 drum presets, including psychedelic techno, electro, dub, jungle, garage, glitch, and polyrhythm patterns.
- 48-key live synth keyboard.
- Autopilot scene morphing and routable modulation slots.
- MP4 recording/export through AVAssetWriter.
- MP4 resolution presets from 360p preview through 480p, 720p, 1080p, 1440p, square, social portrait, vertical, ultrawide, 4K, and vertical 4K output.
- Video performance presets pair visual engines, Minter modes, demoscene modes, palettes, post-processing, frame rate, and output resolution.
- YouTube/Facebook/custom RTMP broadcast panel using `ffmpeg` to loop the latest MP4 recording to an RTMP/RTMPS ingest URL.
- True live RTMP output that streams generated frames directly to `ffmpeg` over raw-video stdin instead of looping a recorded MP4.
- Facebook Live safe setup: RTMPS port 443, 720p30, H.264 Main profile, 2-second keyframes, AAC-LC stereo, yuv420p/BT.709, stream URL normalization, and expanded ffmpeg connection diagnostics.
- Broadcast stereo desktop-mix audio through a named AVFoundation audio device such as `BlackHole 2ch`, with silent fallback, Facebook-safe AAC settings, and ffmpeg error reporting in app status.
- Camera input overlay for optical video feedback with selectable AVFoundation camera source, refresh, mirror, luma/chroma, and depth controls.
- Procedural video feedback simulator with Optical Tunnel, Prism Hall, Luma Bloom Memory, Chroma Warp Field, Scanline Memory, Mirror Labyrinth, and Feedback Lab modes, including decay, zoom, twist, displacement, prism split, and audio-reactive controls in live view and MP4 export.

Run locally:

```sh
swift run
```

Smoke-test MP4 recording:

```sh
swift run eyecandy --record-smoke
```

Recordings are written to `recordings/`.

Package an arm64 release:

```sh
scripts/package-arm64.sh
```

The release package is written to `dist/eyecandy-arm64-YYYYMMDD/` and zipped as
`dist/eyecandy-arm64-YYYYMMDD.zip`. The packaging script rebuilds the app,
recreates the dated package directory from scratch, copies the current
`README.md` and `USER_MANUAL.md` into `docs/`, ad-hoc signs the app bundle, and
removes stale numbered duplicate package folders such as
`eyecandy-arm64-package 2`.

Windows build setup must run on Windows because Swift depends on Visual Studio
C++ tools and the Windows SDK there. On a Windows machine, install the build
dependencies with:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/windows-bootstrap.ps1
```

After restarting the terminal, create a Windows release zip with:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/package-windows.ps1
```

Broadcasting:

1. Choose True Live Output or Loop Latest MP4 from the Broadcast panel.
2. Open the Broadcast panel.
3. Choose YouTube Live, Facebook Live, or Custom RTMP.
4. Paste the ingest URL and stream key from the service.
5. Start Broadcast.

The app keeps the stream key in memory only. Starting a broadcast sends the selected recording to the configured third-party RTMP service.
