# sonic screwdriver eyecandy User Manual

Version: rebuilt Swift desktop app
Platform: macOS arm64

## 1. Overview

sonic screwdriver eyecandy is a live psychedelic light synthesizer, experimental music sequencer, procedural visual instrument, MP4 recorder, and RTMP broadcast tool. It is designed as a playable desktop instrument rather than a passive screensaver. The app combines analog-style synth sequencing, drum patterns, multitap audio delay, visual delay, generative light-synth engines, demoscene effects, holographic effects, Jeff Minter-inspired presets, stereoscopic output modes, and recording/export tools.

The main idea is simple:

1. Pick or generate a preset.
2. Shape the visuals with the Light Synth, Performance, Delay FX, and Output panels.
3. Run the sequencer or play the 48-key keyboard.
4. Record the result to MP4.
5. Optionally broadcast the latest recording to YouTube Live, Facebook Live, or a custom RTMP server.

Every preset change hard-cuts the screen and procedurally regenerates a new scene profile. This means the app does not simply recolor the same drawing. Presets can switch visual engines, palettes, blending behavior, holographic layers, demoscene layers, Jeff Minter-style overlays, prism settings, and light-synth behavior.

## 2. Launching The App

From the project folder:

```sh
swift run
```

A release build can be launched from the packaged zip by opening the app bundle or running the included executable.

## 3. Main Screen Layout

The app has two main areas:

- Visual canvas: the large live output area on the left.
- Inspector panel: the control surface on the right.

The inspector uses a dropdown menu instead of horizontal scrolling. Use the Panel menu to switch between:

- Presets
- Sequencer
- Synth
- Delay FX
- Drums
- 48-Key Keyboard
- Light Synth
- Broadcast
- Performance
- Output

The header contains quick controls:

- Start Audio: starts the procedural audio engine.
- Stop: stops audio playback.
- Random Visual: selects a random preset and regenerates the scene.
- Regenerate: keeps the current preset but creates a new procedural scene profile.

## 4. Presets

The Presets panel contains the visual preset browser.

Preset families include:

- Tunnel
- Mandala
- Liquid
- Laser
- Cellular
- Demoscene
- Cosmic
- Minter
- Holographic

Selecting a preset does more than change colors. It performs a hard visual cut and regenerates the scene profile. Depending on the preset and generated seed, the app can change:

- Visual engine
- Light-synth mode
- Palette mode
- Blend/key behavior
- Minter effect mode
- Demoscene mode
- Holographic mode
- Prism split count
- Macro X/Y values
- Light intensity

The Minter family contains named Jeff Minter-inspired signature presets. These presets are tuned toward neon grids, vector energy, arcade light trails, psychedelic feedback, and colour-organ behavior.

## 5. Visual Engines

The Light Synth panel includes a Visual engine selector. These engines produce different visual structures, not just different colors.

### Light Tunnel

A radial tunnel and symmetry renderer with warped line trails. Good for classic psychedelic tunnels and beat-reactive vortexes.

### Vector Field

A field of directional strokes that swirl around attractors. Good for oscilloscope/vector display looks.

### Metaballs

Soft blobby field forms that merge and split. Good for liquid plasma, cellular blobs, and organic light pools.

### Terrain Grid

A perspective grid inspired by arcade landscapes and demoscene vector floors.

### Oscilloscope Ribbons

Multiple waveform-like ribbons across the screen. Good for audio-reactive scope and laser-synth looks.

### Fractal Lightning

Radial branching bolt forms. Good for aggressive electric bursts.

### Fractal Trees

Branching organic tree structures made from recursive light paths. Good for procedural trees, forests, coral-like structures, and organic light forms.

### Particle Nebula

Hundreds of orbiting particles arranged into spiral clouds and nebula-like movement.

### Shape Constellation

Nodes and connecting line geometry. Good for sacred geometry, star maps, and neural diagrams.

### Liquid Cells

Cell-grid blobs and rounded organic forms. Good for animated cell fields and liquid panels.

### Engine Autopilot

Cycles through the visual engines automatically over time.

## 6. Light Synth Panel

The Light Synth panel is the main visual performance surface.

### Mode

Light-synth modes include:

- Hyper Prism
- Lissajous Laser
- Recursive Bloom
- Acid Scope
- Photon Storm
- Neural Mandala
- Everything

These modes add high-energy overlays such as Lissajous curves, prism rays, recursive bloom shells, particle storms, and neural connection webs.

### Modern Minter Core

Minter Mode now includes Psychedelia Grid, Colourspace Flow, VLM Neon, Tempest Web, Polybius Tunnel, Gridrunner Lattice, Space Giraffe Web, TxK Vector Bloom, Neon Loopz, and LlamaTron Trails. These modes use playable light-synth ideas: pulse grids, colourspace cycling, music-reactive neon curves, tunnel gates, web lanes, and lattice motion.

### Experimental Video Modes

Video Mode adds post-processing styles over the live renderer and MP4 export:

- Slit Scan
- Colourspace
- Neon Pulse
- Video Feedback
- Chromatic Aberration
- Datamosh Blocks
- VHS Melt
- Demoscene Stack
- Luma Key Bloom
- Chroma Invert
- Edge Trace
- Oscillator Bank
- Vector Scope
- Scan Gate
- Pixel Sort Trails
- Codec Tear
- RGB Delay
- Halftone Posterize
- Optical Flow Smear
- Recursive Mirror
- Liquid Lens
- Kaleido Feedback
- Solarized Contours
- Phosphor Burn
- Tunnel Fold
- Chroma Light Leaks

The chroma/luma processor controls tune these modes:

- Key Threshold sets the luma cutoff used by keying and scan-gate effects.
- Edge Gain increases contour, trace, and scanline sharpness.
- Color Warp bends chroma phase, hue inversion, and vectorscope spread.
- Oscillator Rate changes video-rate oscillator motion.

The post-2000 glitch modes are playable approximations of underground VJ and glitch workflows: pixel sorting, codec/datamosh tearing, RGB channel delay, zine-style halftone posterization, optical-flow smear trails, recursive screen-mirror feedback, liquid lens displacement, kaleidoscopic feedback, solarized contour tracing, phosphor burn, folded tunnel geometry, and chromatic light leaks.

### Feedback / Camera

The Feedback / Camera panel captures a live camera feed and composites it over the generated visuals. Pointing the camera at the screen creates physical optical feedback. The Camera Source menu chooses a specific AVFoundation video device by stable device ID, and Refresh rescans built-in and external cameras when a USB capture device or webcam is connected during a set. Feedback modes include Optical Screen Loop, Echo Tunnel, Slit Echo, Luma Key Overlay, and Chroma Wash. Camera Opacity, Feedback Depth, Feedback Scale, Feedback Rotation, Luma Threshold, Chroma Shift, and Mirror Camera control how strongly the captured image folds back into the light-synth output.

The Procedural Feedback Simulator creates video-feedback looks without requiring a camera. Modes include Optical Tunnel, Prism Hall, Luma Bloom Memory, Chroma Warp Field, Scanline Memory, Mirror Labyrinth, CRT Camera Loop, Glass Monitor Stack, Tape Head Echo, Surveillance Wall, and Feedback Lab. The realistic modes emulate monitor curvature, phosphor masks, camera-to-screen recursion, glass reflections, tracking noise, tape dropouts, head-switching bands, and multi-monitor surveillance delay. The simulator uses the same controls for decay, recursive zoom, twist, displacement, prism split, and audio-reactive response in both live view and MP4 export.

### Audio Visualizer

The audio visualizer offers Spectrum Tunnel, Oscilloscope Garden, Chroma Vectorscope, Spectral Particles, Feedback Waveform, Spectral Lattice, Phase Bloom, Polyphonic Loom, Sequencer Matrix, Harmonic Orbits, Granular Bloom, and Hyper Analyzer. Polyphonic Loom maps the six sequence lanes into woven wave threads; Sequencer Matrix exposes the active step and pattern velocity; Harmonic Orbits maps the selected scale to rotating pitch nodes; and Granular Bloom uses transient-driven grains. The Synth button configures Polyphonic Loom for a safe, performance-ready synth view. Analyzer modes render in both the live canvas and MP4 exports.

### GPU Effects

Visual Output includes a GPU effects selector. Metal GPU is the normal realtime compositor and adds scanline, ring, feedback, and grain effects on top of the primary visualizer without changing recording output. OpenGL Legacy is a compatibility fallback for older plug-in and display workflows; macOS deprecates OpenGL, so use Metal GPU for current hardware. Canvas Only disables the realtime GPU overlay.

Metal program chooses the realtime shader: Intro Fade creates a looping radial fade-in/out, Dissolve Portal cuts a moving noise field into a glowing portal edge, Psychedelic Plasma creates beat-reactive kaleidoscopic interference, Fractal Bloom adds an orbit-trap fractal field, and Feedback Cathedral builds a recursive architectural tunnel. Metal effect intensity and speed are independent from the base visualizer and are safe to automate during a performance.

### Video Performance Presets

Output includes video performance presets that apply an engine, Minter mode, demoscene layer, palette, experimental video mode, recording resolution, and frame rate together.

Resolution presets include 360p preview, 480p, 720p, 1080p, 1440p, square, social portrait, vertical, ultrawide, 4K, and vertical 4K formats.

The performance bank includes 128 additional named psychedelic show presets that intentionally jump across engines, Minter modes, demoscene layers, chroma/luma modes, output formats, and frame rates. Loading one also moves the macro pad, prism splits, bloom/exposure, holographic layer, and camera-feedback mode so each preset behaves like a full scene rather than a simple recolor.

### Palette

Palette modes include:

- Neon
- Acid
- Ultraviolet
- Infrared
- Ice
- Monochrome
- Rainbow
- Amber
- Colourspace
- Yak Neon
- Phosphor
- Laserium

The palette acts like a video-synth colorizer. It changes the overall color language of the generated light.

### Blend

Blend modes include:

- Additive
- Screen
- Soft Key
- Hard Key
- Difference

These modes affect the feel of compositing and keying. Additive and Screen are good for bright light-synth looks. Soft Key and Hard Key create stronger graphic separation. Difference creates harsher contrast.

### Stereo

Stereoscopic output modes include:

- Off
- Red/Cyan Anaglyph
- Side-by-Side
- Top/Bottom
- Line Interlace
- Depth Ghost

Stereo depth controls the offset or separation amount.

Use Red/Cyan Anaglyph with red/cyan glasses. Side-by-Side and Top/Bottom are useful for external display pipelines that expect paired stereo frames.

### Photon Director

Photon Director automatically moves the XY macro controls. Disable it if you want manual control.

### Flash Safety

Flash Safety limits the intensity and rate of strobing behavior. Keep it enabled for safer performance conditions.

### Blackout

Blackout instantly clears the output to black.

### Freeze Frame

Freeze Frame holds animation time. Some layers still show static geometry with the current seed and profile.

### Strobe Gate

Strobe Gate flashes the output at the configured strobe rate. Flash Safety caps the rate and intensity.

### Intensity

Controls the strength of the advanced light-synth overlays.

### Phosphor Persistence

Controls the lingering glow feel of recursive and scope-like visuals.

### Prism Splits

Controls how many prism-separated traces are used in laser and Lissajous-style effects.

### XY Macro Pad

The XY pad controls broad performance behavior:

- X: warp, prism density, and horizontal energy.
- Y: feedback, vertical energy, and depth.

Dragging the pad disables Photon Director so you can perform manually.

### Trip Max

Sets a very intense high-energy configuration:

- Everything light mode
- High intensity
- Higher phosphor persistence
- More prism splits
- Interference-style holographic mode
- Minter feedback behavior
- Mega Demo mode

### Safe Cruise

Sets a more controlled configuration:

- Lower intensity
- Lower persistence
- Fewer prism splits
- Flash Safety on

## 7. Scene Deck

The Light Synth panel includes an eight-slot Scene Deck.

Each slot can save and recall:

- Current visual preset
- Visual engine
- Light-synth mode
- Palette
- Blend mode
- Macro X/Y
- Intensity
- Phosphor persistence
- Prism split count
- Demoscene mode
- Minter mode
- Holographic mode

Use the scene deck for performance cueing. Save several scenes, then recall them during playback.

## 8. Sequencer Panel

The Sequencer panel controls playback timing and step patterns.

### Play Sequencer

Enables or disables sequencer playback.

### BPM

The BPM stepper and slider control tempo.

### Tempo Mode

Manual preserves normal tap, nudge, half, double, stepper, and slider tempo editing. Golden Phi sets the sequencer to 161.8 BPM, applies golden-ratio swing, changes the active loop to 13 steps, and spaces the multitap delay at phi-related beat offsets.

### Tempo Tools

- Tap: tap repeatedly to set tempo.
- -1: reduce BPM by one.
- +1: increase BPM by one.
- Half: halve the BPM.
- Double: double the BPM.
- Phi: apply Golden Phi tempo mode immediately.

### Swing

Swing shifts alternating steps for a more shuffled feel. Swing affects:

- Audio step timing
- Music-reactive visual energy
- Visual delay tap response

### Groove, Scale, Humanize, and Mutation

Groove selects timing templates such as MPC Shuffle, Broken Beat, Electro Push, Garage Skip, and Dilla Drift. Scale locks generated bass and lead notes to Chromatic, Minor Pentatonic, Dorian, Phrygian, or Whole Tone material. Humanize adds controlled velocity variation during playback, and Mutation controls how aggressively Mutate rewrites steps, notes, velocity, chance, and ratchets.

### Pattern Length

Pattern Length sets how many steps are active, from 4 to 16.

### Step Lanes

Editable lanes include:

- Bass
- Lead
- Kick
- Snare
- Hat
- Clap

Click the step buttons to toggle steps.

Each lane also has Length, Chance, Velocity, and Ratchet controls. Lane Length allows polymeter against the global pattern length. Chance sets probability that an active step will fire. Velocity changes step loudness. Ratchet retriggers a step inside its slot for rolls, trap hats, acid ticks, and fill bursts.

Generator buttons:

- Randomize: creates a broad new pattern.
- Mutate: evolves the current pattern without clearing it.
- Humanize: varies velocities and probabilities.
- Acid Line: creates a scale-aware bassline and sets the bass voice toward acid behavior.
- Lead Arp: creates a scale-aware melodic arp.
- Ratchet Fill: adds hat/snare retriggers for transitions.

## 9. Synth Panel

The Synth panel has two procedural synth voices:

- Analog Bass Line
- Space Lead

Each voice includes:

- Enable toggle
- Instrument selector
- Preset menu
- Randomize Voice
- Level
- Octave
- Cutoff
- Resonance
- Glide
- Accent
- Attack, Decay, and Sustain
- Drive and Wavefold
- Filter Envelope
- LFO Rate and LFO Amount
- Morph
- Unison and Detune
- Sub and Noise
- FM / Ring
- Grain Size and Grain Density
- Bitcrush

Instrument types include Acid Saw, Sub Square, Super Saw, FM Bell, Glass Pad, Noise Organ, Sync Lead, Formant Vox, Wavetable Morph, Granular Cloud, Reese Bass, Phase Distortion, Ring Mod Keys, Karplus Pluck, Bitcrush Lead, and Spectral Drone.

The preset menu provides performance-ready starting points such as Acid Warehouse Bass, Reese Pressure, Granular Halo, Wavetable Glass Lead, Phase Warp Lead, Ring Mod Keys, Karplus Laser Pluck, Bitcrush Siren, Spectral Drone Pad, and Formant Vox Choir. Randomize Voice creates a new synth patch using the same macro control ranges.

The procedural audio engine is intentionally compact, but it is playable and reacts to the sequencer and keyboard.

## 10. Delay FX Panel

Delay FX controls the multitap delay system.

### Multitap Audio Delay

Enables or disables beat-synced audio delay.

### Wet Mix

Controls how much delayed signal is mixed into the output.

### Global Feedback

Controls how much delayed signal feeds back into the delay buffer.

### Multitap Visual Delay

Enables or disables visual echo trails.

### Visual Echo Opacity

Controls the opacity of the delayed visual tap echoes.

### Sync Taps

Sets the delay taps to useful beat-synced offsets.

### Tap Controls

Each tap has:

- Enabled
- Beat offset
- Level
- Feedback
- Visual spread

The same tap offsets drive audio echoes and delayed visual ghost rings/rays. This keeps the audio delay and visual delay rhythmically linked.

## 11. Drums Panel

The Drums panel includes drum-machine preset patterns and direct lane editing.

Included drum presets:

- Four on the Floor
- Broken Ritual
- Motorik Rush
- Triptronics
- Acid Warehouse
- Laser Breakbeat
- DMT Electro
- Cosmic Footwork
- Hypno Dub
- Neon Jungle
- Kraut Pulse
- Rave Polyrhythm
- Glitch Mandala
- Temple Breaks
- Astral Garage
- Feedback Techno
- Trip Hop Engine
- Prism Shuffle
- Vortex Motorik
- Chroma Stutter

Each preset updates the drum lanes.

## 12. 48-Key Keyboard

The Keyboard panel provides a 48-key live synth surface from MIDI note 36 to 83.

Click keys to toggle notes on and off.

Use All Notes Off to clear held notes.

The live keyboard is mixed into the procedural audio output and contributes to visual energy in some modes.

## 13. Performance Panel

The Performance panel contains automation and overlay controls.

### Autopilot Scene Morphing

Autopilot changes presets over time using bar-based timing.

### Scene Morph

Scene Morph turns the Scene Deck into an A/B performance crossfader. Choose a From slot and To slot, then move Morph to interpolate continuous controls such as macro position, intensity, phosphor persistence, prism count, video intensity, key threshold, edge gain, color warp, oscillator rate, and camera-feedback depth. Discrete choices such as palette, blend mode, visual preset, demoscene mode, Minter mode, holographic mode, and video mode switch at the midpoint.

- Save From stores the current look into the selected From slot.
- Save To stores the current look into the selected To slot.
- Generate Deck fills all eight scene slots with randomized performance-ready looks.

### Demoscene Mode

Classic 80s/90s style effects:

- Amiga Copper Bars
- VGA Plasma
- Rotozoomer
- Vector Balls
- Star Tunnel
- Sine Scroller
- Chunky VGA
- Mega Demo

### Minter Mode

Jeff Minter-inspired overlays:

- Neon Stampede
- Yak Laser Grid
- Llama Feedback
- Arcade Vortex

### Holographic Mode

Holographic overlays:

- Ghost Prism
- Scan Volume
- Chroma Depth
- Interference

### Mod Slots

There are three modulation slots.

Sources include:

- LFO Sine
- LFO Triangle
- Beat Phase
- Bass Energy
- Noise Drift

Destinations include:

- Warp
- Hue
- Zoom
- Feedback
- Strobes

Each slot has amount and rate controls.

## 14. Output Panel

The Output panel controls recording, final image behavior, and the synth master output stage.

### Master Level

Controls audio output level.

### Master Drive

Adds pre-limiter saturation for louder, denser synth and drum output.

### Stereo Width

Spreads lead, live keyboard, drum ambience, and delay returns across the stereo field. Lower values keep the synth closer to mono; higher values create a wider broadcast/recording monitor image.

### Limiter Ceiling

Sets the maximum sample level for the master safety limiter. Lower this when feeding a broadcast chain or virtual stereo mix device that clips easily.

### Limiter Release

Controls how quickly the limiter returns to unity gain after loud hits.

### Audio Meter

Shows left/right output peaks, gain reduction, and limiter hit count. Gain reduction means the limiter is actively preventing overload.

### Bloom

Controls glow strength in ring and light effects.

### Exposure

Controls visual brightness and line thickness.

### Record Duration

Sets MP4 recording length.

### Frame Rate

Choose:

- 24 fps
- 30 fps
- 60 fps

### Record MP4

Records the current procedural visual state to MP4. Recordings are saved in:

```text
recordings/
```

The app also provides a smoke-test recorder:

```sh
swift run eyecandy --record-smoke
```

## 15. Broadcast Panel

The Broadcast panel can send the latest MP4 recording to:

- YouTube Live
- Facebook Live
- Custom RTMP

Broadcasting uses ffmpeg and an RTMP or RTMPS ingest URL plus stream key.

Typical workflow:

1. Choose True Live Output for generated frames, or Loop Latest MP4 for file replay.
2. Open the Broadcast panel.
3. Select YouTube Live, Facebook Live, or Custom RTMP.
4. Paste the ingest URL and stream key from the streaming service.
5. Choose bitrate and frame rate.
6. Start Broadcast.
7. Stop Broadcast when finished.

The stream key is held in memory only. True Live Output sends raw generated BGRA frames to `ffmpeg` over stdin and publishes RTMP/RTMPS without reading from an MP4 file. Loop Latest MP4 keeps the previous file-based broadcast path.

Broadcast audio can use Silent mode or Desktop Stereo Mix mode. Desktop Stereo Mix captures a named AVFoundation audio input such as `BlackHole 2ch`; route macOS system output to that virtual/aggregate device to include all desktop audio in the stream. Use List audio devices in the Broadcast panel to see the exact device names ffmpeg can open. Facebook Live uses 30 fps plus AAC stereo at 44.1 kHz / 128 kbps; YouTube/custom targets use AAC stereo at 48 kHz / 192 kbps. If ffmpeg cannot open the selected desktop-mix device, the app status now reports the AVFoundation/audio error instead of silently hiding it.

### Facebook Live Safe Setup

Choose Facebook Live or press Facebook Safe Setup before starting a Facebook broadcast. This forces the safest ingest profile:

- RTMPS ingest on `live-api-s.facebook.com:443/rtmp`
- True Live Output
- 1280 x 720
- 30 fps
- H.264 Main profile
- 2-second keyframes
- yuv420p BT.709 video
- AAC-LC stereo at 44.1 kHz / 128 kbps
- 2500-6000 kbps video bitrate clamp

Use Facebook Live Producer, paste the RTMPS server URL and stream key into the app, start the app broadcast, wait for preview in Facebook, then click Go Live in Facebook. If Facebook reports no audio, confirm macOS is routed into the named desktop stereo mix device and that the same device name appears from List audio devices.

## 16. MP4 Recording Notes

MP4 export is offline-rendered with AVAssetWriter. It does not screen-record the window. This is more reliable because the exporter uses the procedural render path directly.

The exporter includes:

- Current preset
- Visual engine
- Stereo mode
- Demoscene layer
- Minter layer
- Holographic layer
- Light-synth layers
- Chroma/luma processor modes
- Multitap visual delay
- Palette and strobe gates

The MP4 does not currently include the live procedural audio mix. Broadcast uses the latest MP4 with generated silent audio for RTMP compatibility.

## 17. Recommended Performance Workflows

### Fast Live Jam

1. Start Audio.
2. Choose a preset family.
3. Select a preset.
4. Open Light Synth.
5. Hit Trip Max.
6. Drag the XY Macro Pad.
7. Open Delay FX and enable Multitap Visual Delay.
8. Open Sequencer and adjust tempo or tap tempo.

### Controlled Visual Show

1. Choose several presets.
2. For each preset, tune Light Synth and Performance settings.
3. Save each result to a Scene Deck slot.
4. Recall scenes during playback.
5. Use Blackout and Freeze Frame for transitions.

### Stereo Experiment

1. Open Light Synth.
2. Choose Red/Cyan Anaglyph or Depth Ghost.
3. Increase Stereo Depth slowly.
4. Try Particle Nebula, Fractal Trees, or Vector Field.
5. Record a short MP4.

### Jeff Minter-Style Session

1. Choose the Minter preset family.
2. Select one of the named signature presets.
3. Use Minter Mode and Demoscene Mode together.
4. Enable Holographic Interference.
5. Use Trip Max carefully.
6. Adjust Prism Splits and Phosphor Persistence.

### Demoscene Session

1. Open Performance.
2. Set Demoscene Mode to Mega Demo.
3. Choose Terrain Grid, Vector Field, or Oscilloscope Ribbons as the Visual Engine.
4. Increase Demoscene Intensity.
5. Use tempo changes and swing for rhythmic motion.

## 18. Safety Notes

This app can create bright flashing visuals.

Use caution with:

- Strobe Gate
- Trip Max
- High Exposure
- High Bloom
- High Light Synth Intensity
- Flash Safety disabled

For safer use:

- Keep Flash Safety enabled.
- Avoid high strobe rates.
- Reduce exposure and intensity.
- Use Safe Cruise when needed.
- Avoid using intense flashing visuals around people sensitive to flashing lights.

## 19. Troubleshooting

### No audio

Try:

1. Press Start Audio.
2. Check system output volume.
3. Toggle Play Sequencer.
4. Enable Bass or Lead voice.
5. Check Master Level.

### Recording does not appear

Check:

1. Output panel duration is at least 3 seconds.
2. The app has write access to the project folder.
3. Look in the `recordings/` folder.

### Broadcast does not start

Check:

1. ffmpeg is installed.
2. You recorded an MP4 first.
3. The ingest URL is correct.
4. The stream key is present.
5. The streaming service has an active live event waiting for encoder input.

### Visuals are too similar

Use:

1. Regenerate.
2. Change Visual Engine.
3. Select another preset family.
4. Enable Engine Autopilot.
5. Try Fractal Trees, Metaballs, Terrain Grid, or Oscilloscope Ribbons.

### Visuals are too intense

Use:

1. Safe Cruise.
2. Lower Exposure.
3. Lower Bloom.
4. Disable Strobe Gate.
5. Turn Flash Safety on.
6. Lower Light Synth Intensity.

## 20. Keyboard And Mouse Notes

Most interaction is mouse-driven. The XY Macro Pad supports direct dragging. Step sequencer lanes use click toggles. Keyboard notes are toggled by clicking keys in the 48-Key Keyboard panel.

## 21. File Locations

Project:

```text
/Users/atarick/Documents/Airship/eyecandy
```

Recordings:

```text
/Users/atarick/Documents/Airship/eyecandy/recordings
```

Release build:

```text
.build/arm64-apple-macosx/release/eyecandy
```

Manual:

```text
USER_MANUAL.md
```

## 22. Current Limitations

- MP4 recording is visual-only with silent audio for broadcast compatibility.
- RTMP broadcast loops the latest recorded MP4 rather than streaming the live canvas in real time.
- The app is currently macOS-focused.
- Windows/Linux require a portability pass for UI/audio/render layers.

## 23. Best Practices

- Save strong looks into Scene Deck slots.
- Use Regenerate when a preset is good but the current structure is not.
- Use Engine Autopilot for exploration.
- Use Delay FX to connect sound echoes and visual echoes.
- Use Tap Tempo before recording so delay taps and sequencer timing match your intended groove.
- Keep Flash Safety enabled during experiments.
