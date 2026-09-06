import AppKit
import SwiftUI

struct RendererView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
            Canvas { context, size in
                model.tickPerformanceClock()
                model.tickLightSynthDirector(time: timeline.date.timeIntervalSinceReferenceDate)
                drawFrame(context: &context, size: size, time: timeline.date.timeIntervalSinceReferenceDate)
            }
            .background(.black)
            .overlay(alignment: .topLeading) {
                HStack(spacing: 8) {
                    Text(model.selectedPreset.name)
                    Text("\(Int(model.sequencer.bpm)) BPM")
                    if let active = model.activeSceneSlot {
                        Text("S\(active + 1)")
                    }
                    if let queued = model.queuedSceneSlot {
                        Text("Q\(queued + 1)")
                    }
                    if model.autopilotEnabled { Text("AUTO") }
                    if model.modSlots.contains(where: \.enabled) { Text("MOD") }
                    Text("LIGHT")
                    if model.demosceneEffectMode != .off { Text("DEMO") }
                    if model.minterEffectMode != .off { Text("MINTER") }
                    if model.holographicMode != .off { Text("HOLO") }
                    if model.feedbackSimulatorMode != .off { Text("FDBK") }
                }
                .font(.caption.weight(.semibold))
                .padding(8)
                .background(.black.opacity(0.48), in: Capsule())
                .padding(12)
            }
        }
    }

    private func drawFrame(context: inout GraphicsContext, size: CGSize, time: TimeInterval) {
        if model.blackout {
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.black))
            return
        }

        let time = model.freezeFrame ? floor(time) : time
        let preset = model.selectedPreset
        let beat = model.beatPhase

        context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.black))
        if time - model.sceneCutTime < 0.08 {
            return
        }

        drawSelectedVisualEngine(context: &context, size: size, time: time, preset: preset, beat: beat, stereoOffset: 0)
        drawStereoLayer(context: &context, size: size, time: time, preset: preset, beat: beat)
        drawPulseRings(context: &context, size: size, time: time, preset: preset, beat: beat)
        drawGridGlitch(context: &context, size: size, time: time, preset: preset)
        drawDemosceneLayer(context: &context, size: size, time: time, preset: preset, beat: beat)
        drawAdvancedLightSynthLayer(context: &context, size: size, time: time, preset: preset, beat: beat)
        drawAudioAnalyzerLayer(context: &context, size: size, time: time, preset: preset, beat: beat)
        drawVisualDelayTaps(context: &context, size: size, time: time, preset: preset)
        drawMinterLayer(context: &context, size: size, time: time, preset: preset, beat: beat)
        drawHolographicLayer(context: &context, size: size, time: time, preset: preset, beat: beat)
        drawPaletteAndGate(context: &context, size: size, time: time, preset: preset)
        drawExperimentalVideoMode(context: &context, size: size, time: time, preset: preset, beat: beat)
        drawFeedbackSimulatorLayer(context: &context, size: size, time: time, preset: preset, beat: beat)
        drawCameraFeedbackOverlay(context: &context, size: size, time: time)
    }

    private func drawSelectedVisualEngine(context: inout GraphicsContext, size: CGSize, time: TimeInterval, preset: VisualPreset, beat: Double, stereoOffset: Double) {
        let mode = resolvedVisualEngine(time: time)
        switch mode {
        case .lightTunnel, .engineAutopilot:
            drawLightTunnel(context: &context, size: size, time: time, preset: preset, beat: beat, stereoOffset: stereoOffset)
        case .vectorField:
            drawVectorFieldEngine(context: &context, size: size, time: time, preset: preset, stereoOffset: stereoOffset)
        case .metaballs:
            drawMetaballsEngine(context: &context, size: size, time: time, preset: preset, stereoOffset: stereoOffset)
        case .terrainGrid:
            drawTerrainGridEngine(context: &context, size: size, time: time, preset: preset, stereoOffset: stereoOffset)
        case .oscilloscopeRibbons:
            drawOscilloscopeRibbonsEngine(context: &context, size: size, time: time, preset: preset, stereoOffset: stereoOffset)
        case .fractalLightning:
            drawFractalLightningEngine(context: &context, size: size, time: time, preset: preset, stereoOffset: stereoOffset)
        case .fractalTrees:
            drawFractalTreesEngine(context: &context, size: size, time: time, preset: preset, stereoOffset: stereoOffset)
        case .particleNebula:
            drawParticleNebulaEngine(context: &context, size: size, time: time, preset: preset, stereoOffset: stereoOffset)
        case .shapeConstellation:
            drawShapeConstellationEngine(context: &context, size: size, time: time, preset: preset, stereoOffset: stereoOffset)
        case .liquidCells:
            drawLiquidCellsEngine(context: &context, size: size, time: time, preset: preset, stereoOffset: stereoOffset)
        case .reactionDiffusion:
            drawReactionDiffusionEngine(context: &context, size: size, time: time, preset: preset, stereoOffset: stereoOffset)
        case .kaleidoscopeMaze:
            drawKaleidoscopeMazeEngine(context: &context, size: size, time: time, preset: preset, beat: beat, stereoOffset: stereoOffset)
        case .moireField:
            drawMoireFieldEngine(context: &context, size: size, time: time, preset: preset, stereoOffset: stereoOffset)
        case .slitScanRibbons:
            drawSlitScanRibbonsEngine(context: &context, size: size, time: time, preset: preset, stereoOffset: stereoOffset)
        case .cellularAutomata:
            drawCellularAutomataEngine(context: &context, size: size, time: time, preset: preset, stereoOffset: stereoOffset)
        }
    }

    private func resolvedVisualEngine(time: TimeInterval) -> VisualEngineMode {
        guard model.visualEngineMode == .engineAutopilot else { return model.visualEngineMode }
        let engines: [VisualEngineMode] = [.lightTunnel, .vectorField, .metaballs, .terrainGrid, .oscilloscopeRibbons, .fractalLightning, .fractalTrees, .particleNebula, .shapeConstellation, .liquidCells, .reactionDiffusion, .kaleidoscopeMaze, .moireField, .slitScanRibbons, .cellularAutomata]
        return engines[Int(time / 12.0) % engines.count]
    }

    private func drawStereoLayer(context: inout GraphicsContext, size: CGSize, time: TimeInterval, preset: VisualPreset, beat: Double) {
        guard model.stereoscopicMode != .off else { return }
        let depth = 8.0 + model.stereoDepth * 42.0
        switch model.stereoscopicMode {
        case .off:
            return
        case .anaglyph:
            drawSelectedVisualEngine(context: &context, size: size, time: time + 0.06, preset: preset, beat: beat, stereoOffset: -depth)
            drawSelectedVisualEngine(context: &context, size: size, time: time - 0.06, preset: preset, beat: beat, stereoOffset: depth)
        case .sideBySide:
            let divider = CGRect(x: size.width / 2 - 1, y: 0, width: 2, height: size.height)
            context.fill(Path(divider), with: .color(.white.opacity(0.18)))
            drawSelectedVisualEngine(context: &context, size: CGSize(width: size.width / 2, height: size.height), time: time + 0.04, preset: preset, beat: beat, stereoOffset: -depth * 0.35)
            var translated = context
            translated.translateBy(x: size.width / 2, y: 0)
            drawSelectedVisualEngine(context: &translated, size: CGSize(width: size.width / 2, height: size.height), time: time - 0.04, preset: preset, beat: beat, stereoOffset: depth * 0.35)
        case .topBottom:
            let divider = CGRect(x: 0, y: size.height / 2 - 1, width: size.width, height: 2)
            context.fill(Path(divider), with: .color(.white.opacity(0.18)))
            drawSelectedVisualEngine(context: &context, size: CGSize(width: size.width, height: size.height / 2), time: time + 0.04, preset: preset, beat: beat, stereoOffset: -depth * 0.25)
            var translated = context
            translated.translateBy(x: 0, y: size.height / 2)
            drawSelectedVisualEngine(context: &translated, size: CGSize(width: size.width, height: size.height / 2), time: time - 0.04, preset: preset, beat: beat, stereoOffset: depth * 0.25)
        case .lineInterlace:
            for row in stride(from: 0.0, to: size.height, by: 6.0) {
                context.fill(Path(CGRect(x: 0, y: row, width: size.width, height: 2)), with: .color(.cyan.opacity(0.10 + model.stereoDepth * 0.18)))
            }
            drawSelectedVisualEngine(context: &context, size: size, time: time - 0.03, preset: preset, beat: beat, stereoOffset: depth * 0.45)
        case .depthGhost:
            drawSelectedVisualEngine(context: &context, size: size, time: time - 0.11, preset: preset, beat: beat, stereoOffset: depth)
        }
    }

    private func drawLightTunnel(context: inout GraphicsContext, size: CGSize, time: TimeInterval, preset: VisualPreset, beat: Double, stereoOffset: Double) {
        let center = CGPoint(x: size.width / 2 + stereoOffset, y: size.height / 2)
        let shortest = min(size.width, size.height)
        let mod = modulation(time: time, beat: beat)
        let trailCount = Int(24 + preset.density * 90)
        let symmetry = max(1, preset.symmetry)
        let warp = preset.warp + mod.warp
        let hueMix = mod.hue
        let zoom = 0.72 + preset.feedback * 0.45 + mod.zoom

        for i in 0..<trailCount {
            let t = Double(i) / Double(max(1, trailCount - 1))
            let radius = shortest * (0.04 + t * 0.48 * zoom)
            let spin = time * (0.12 + preset.warp * 0.35) + t * Double.pi * 5.0 + beat * Double.pi * 2.0
            let alpha = max(0.05, 0.86 - t * 0.72)
            let lineWidth = 1.0 + (1.0 - t) * 4.5 * model.exposure
            let color = blendedColor(preset: preset, t: t + hueMix).opacity(alpha)

            for spoke in 0..<symmetry {
                let angle = spin + Double(spoke) / Double(symmetry) * Double.pi * 2.0
                var path = Path()
                let points = 44
                for p in 0..<points {
                    let u = Double(p) / Double(points - 1)
                    let wave = sin(u * Double.pi * (2.0 + preset.density * 8.0) + time * (1.5 + warp * 5.0))
                    let wobble = cos(u * 7.0 + time * 0.8 + Double(i)) * warp * 22.0
                    let r = radius * (0.65 + u * 0.8) + wave * warp * 36.0
                    let a = angle + u * (0.7 + warp) + wobble / max(120.0, shortest)
                    let point = CGPoint(x: center.x + cos(a) * r, y: center.y + sin(a) * r)
                    if p == 0 { path.move(to: point) } else { path.addLine(to: point) }
                }
                context.stroke(path, with: .color(color), lineWidth: lineWidth)
            }
        }
    }

    private func drawVectorFieldEngine(context: inout GraphicsContext, size: CGSize, time: TimeInterval, preset: VisualPreset, stereoOffset: Double) {
        let cols = 28
        let rows = 18
        let cellW = size.width / Double(cols)
        let cellH = size.height / Double(rows)
        for y in 0..<rows {
            for x in 0..<cols {
                let nx = Double(x) / Double(cols) - 0.5
                let ny = Double(y) / Double(rows) - 0.5
                let angle = atan2(ny, nx) + sin(nx * 8 + time) + cos(ny * 7 - time * 1.3)
                let length = 8.0 + preset.warp * 38.0 + musicEnergy(at: time) * 22.0
                let origin = CGPoint(x: Double(x) * cellW + cellW / 2 + stereoOffset, y: Double(y) * cellH + cellH / 2)
                var path = Path()
                path.move(to: CGPoint(x: origin.x - cos(angle) * length * 0.45, y: origin.y - sin(angle) * length * 0.45))
                path.addLine(to: CGPoint(x: origin.x + cos(angle) * length, y: origin.y + sin(angle) * length))
                context.stroke(path, with: .color(blendedColor(preset: preset, t: nx + ny + time * 0.04).opacity(0.18 + model.exposure * 0.20)), lineWidth: 1.2)
            }
        }
    }

    private func drawMetaballsEngine(context: inout GraphicsContext, size: CGSize, time: TimeInterval, preset: VisualPreset, stereoOffset: Double) {
        let cols = 44
        let rows = 28
        let cellW = size.width / Double(cols)
        let cellH = size.height / Double(rows)
        var centers: [CGPoint] = []
        for index in 0..<7 {
            let i = Double(index)
            let xMotion = Darwin.sin(time * (0.17 + i * 0.03) + i) * 0.38
            let yMotion = Darwin.cos(time * (0.13 + i * 0.04) + i * 1.7) * 0.35
            centers.append(CGPoint(x: size.width * (0.5 + xMotion) + stereoOffset, y: size.height * (0.5 + yMotion)))
        }
        for y in 0..<rows {
            for x in 0..<cols {
                let point = CGPoint(x: Double(x) * cellW, y: Double(y) * cellH)
                var field = 0.0
                for center in centers {
                    let dx = Double(point.x - center.x)
                    let dy = Double(point.y - center.y)
                    field += 9500.0 / Swift.max(120.0, dx * dx + dy * dy)
                }
                if field > 0.42 {
                    let alpha = min(0.34, (field - 0.42) * 0.22)
                    context.fill(Path(CGRect(x: point.x, y: point.y, width: cellW + 1, height: cellH + 1)), with: .color(blendedColor(preset: preset, t: field + time * 0.05).opacity(alpha)))
                }
            }
        }
    }

    private func drawTerrainGridEngine(context: inout GraphicsContext, size: CGSize, time: TimeInterval, preset: VisualPreset, stereoOffset: Double) {
        let horizon = size.height * 0.58
        let rows = 24
        for row in 0..<rows {
            let depth = Double(row) / Double(rows)
            let y = horizon + pow(depth, 2.1) * size.height * 0.55
            var path = Path()
            for col in 0...64 {
                let xNorm = Double(col) / 64.0 * 2.0 - 1.0
                let perspective = 1.0 + depth * 4.0
                let wave = sin(xNorm * 7.0 + time * 1.7 + depth * 9.0) * 24.0 * depth
                let x = size.width / 2 + xNorm * size.width * 0.62 / perspective + stereoOffset * depth
                let point = CGPoint(x: x, y: y + wave)
                if col == 0 { path.move(to: point) } else { path.addLine(to: point) }
            }
            context.stroke(path, with: .color(blendedColor(preset: preset, t: depth + time * 0.02).opacity(0.12 + depth * 0.42)), lineWidth: 1.0 + depth * 2.0)
        }
        for col in -14...14 {
            var path = Path()
            for row in 0...rows {
                let depth = Double(row) / Double(rows)
                let perspective = 1.0 + depth * 4.0
                let x = size.width / 2 + Double(col) * size.width * 0.055 / perspective + stereoOffset * depth
                let y = horizon + pow(depth, 2.1) * size.height * 0.55
                if row == 0 { path.move(to: CGPoint(x: x, y: y)) } else { path.addLine(to: CGPoint(x: x, y: y)) }
            }
            context.stroke(path, with: .color(preset.colorC.opacity(0.12)), lineWidth: 1)
        }
    }

    private func drawOscilloscopeRibbonsEngine(context: inout GraphicsContext, size: CGSize, time: TimeInterval, preset: VisualPreset, stereoOffset: Double) {
        for ribbon in 0..<7 {
            let yBase = size.height * (0.18 + Double(ribbon) * 0.105)
            var path = Path()
            for pointIndex in 0..<180 {
                let u = Double(pointIndex) / 179.0
                let amp = 24.0 + Double(ribbon) * 9.0 + musicEnergy(at: time - Double(ribbon) * 0.08) * 62.0
                let y = yBase + sin(u * Double.pi * (4.0 + Double(ribbon)) + time * (2.0 + Double(ribbon) * 0.3)) * amp
                let x = u * size.width + stereoOffset * sin(u * Double.pi)
                if pointIndex == 0 { path.move(to: CGPoint(x: x, y: y)) } else { path.addLine(to: CGPoint(x: x, y: y)) }
            }
            context.stroke(path, with: .color(blendedColor(preset: preset, t: Double(ribbon) / 7.0 + time * 0.04).opacity(0.32)), lineWidth: 2.0 + Double(ribbon) * 0.35)
        }
    }

    private func drawFractalLightningEngine(context: inout GraphicsContext, size: CGSize, time: TimeInterval, preset: VisualPreset, stereoOffset: Double) {
        let bolts = 11
        let center = CGPoint(x: size.width / 2 + stereoOffset, y: size.height / 2)
        for bolt in 0..<bolts {
            let angle = Double(bolt) / Double(bolts) * Double.pi * 2.0 + time * 0.23
            var path = Path()
            path.move(to: center)
            var point = center
            for segment in 1...18 {
                let distance = min(size.width, size.height) * Double(segment) / 20.0
                let jitter = sin(time * 8.0 + Double(segment * bolt)) * 28.0
                point = CGPoint(x: center.x + cos(angle) * distance + cos(angle + .pi / 2) * jitter, y: center.y + sin(angle) * distance + sin(angle + .pi / 2) * jitter)
                path.addLine(to: point)
            }
            context.stroke(path, with: .color(blendedColor(preset: preset, t: Double(bolt) / Double(bolts) + time * 0.05).opacity(0.18 + model.lightSynthIntensity * 0.28)), lineWidth: 1.0 + model.lightSynthIntensity * 3.0)
        }
    }

    private func drawFractalTreesEngine(context: inout GraphicsContext, size: CGSize, time: TimeInterval, preset: VisualPreset, stereoOffset: Double) {
        let trunks = 5
        for trunk in 0..<trunks {
            let x = size.width * (Double(trunk) + 0.5) / Double(trunks) + stereoOffset * 0.4
            let base = CGPoint(x: x, y: size.height * 0.92)
            let length = size.height * (0.12 + 0.035 * Double((model.sceneSeed + trunk) % 5))
            let sway = sin(time * 0.8 + Double(trunk) + Double(model.sceneSeed % 11)) * 0.18
            drawTreeBranch(
                context: &context,
                preset: preset,
                start: base,
                angle: -.pi / 2 + sway,
                length: length,
                depth: 7,
                hueOffset: Double(trunk) / Double(trunks),
                time: time
            )
        }
    }

    private func drawTreeBranch(context: inout GraphicsContext, preset: VisualPreset, start: CGPoint, angle: Double, length: Double, depth: Int, hueOffset: Double, time: TimeInterval) {
        guard depth > 0, length > 2 else { return }
        let end = CGPoint(x: start.x + cos(angle) * length, y: start.y + sin(angle) * length)
        var path = Path()
        path.move(to: start)
        path.addLine(to: end)
        let alpha = 0.06 + Double(depth) * 0.045 * model.lightSynthIntensity
        context.stroke(path, with: .color(blendedColor(preset: preset, t: hueOffset + Double(depth) * 0.07 + time * 0.025).opacity(alpha)), lineWidth: max(0.6, Double(depth) * 0.75))

        let fork = 0.34 + Double((model.sceneSeed + depth) % 8) * 0.025
        let pulse = sin(time * 1.1 + Double(depth)) * 0.12
        drawTreeBranch(context: &context, preset: preset, start: end, angle: angle - fork + pulse, length: length * 0.72, depth: depth - 1, hueOffset: hueOffset + 0.04, time: time)
        drawTreeBranch(context: &context, preset: preset, start: end, angle: angle + fork - pulse, length: length * 0.70, depth: depth - 1, hueOffset: hueOffset + 0.09, time: time)
        if depth % 2 == 0 {
            drawTreeBranch(context: &context, preset: preset, start: end, angle: angle + pulse * 0.5, length: length * 0.54, depth: depth - 2, hueOffset: hueOffset + 0.16, time: time)
        }
    }

    private func drawParticleNebulaEngine(context: inout GraphicsContext, size: CGSize, time: TimeInterval, preset: VisualPreset, stereoOffset: Double) {
        let count = 260
        let center = CGPoint(x: size.width / 2 + stereoOffset, y: size.height / 2)
        for particle in 0..<count {
            let seed = Double((particle * 9283) % 12011) / 12011.0
            let spiral = seed * Double.pi * 18.0 + time * (0.18 + seed * 0.5)
            let radius = pow(seed, 0.72) * min(size.width, size.height) * 0.55
            let point = CGPoint(x: center.x + cos(spiral) * radius * (0.55 + model.macroX), y: center.y + sin(spiral * 1.17) * radius * (0.45 + model.macroY))
            let diameter = 1.2 + (1.0 - seed) * 7.0 * model.lightSynthIntensity
            context.fill(Path(ellipseIn: CGRect(x: point.x - diameter / 2, y: point.y - diameter / 2, width: diameter, height: diameter)), with: .color(blendedColor(preset: preset, t: seed + time * 0.03).opacity(0.12 + (1.0 - seed) * 0.42)))
        }
    }

    private func drawShapeConstellationEngine(context: inout GraphicsContext, size: CGSize, time: TimeInterval, preset: VisualPreset, stereoOffset: Double) {
        let center = CGPoint(x: size.width / 2 + stereoOffset, y: size.height / 2)
        let count = 32
        var points: [CGPoint] = []
        for index in 0..<count {
            let t = Double(index) / Double(count)
            let radius = min(size.width, size.height) * (0.16 + 0.34 * sin(t * Double.pi * 3.0 + time * 0.4) * sin(t * Double.pi * 3.0 + time * 0.4))
            points.append(CGPoint(x: center.x + cos(t * Double.pi * 2.0 + time * 0.3) * radius, y: center.y + sin(t * Double.pi * 2.0 - time * 0.22) * radius))
        }
        for i in points.indices {
            for j in (i + 1)..<points.count where abs(j - i) == 5 || (i + j) % 11 == 0 {
                var path = Path()
                path.move(to: points[i])
                path.addLine(to: points[j])
                context.stroke(path, with: .color(blendedColor(preset: preset, t: Double(i + j) / Double(count * 2)).opacity(0.08 + model.lightSynthIntensity * 0.12)), lineWidth: 1)
            }
        }
        for point in points {
            context.fill(Path(ellipseIn: CGRect(x: point.x - 4, y: point.y - 4, width: 8, height: 8)), with: .color(preset.colorA.opacity(0.42)))
        }
    }

    private func drawLiquidCellsEngine(context: inout GraphicsContext, size: CGSize, time: TimeInterval, preset: VisualPreset, stereoOffset: Double) {
        let cols = 24
        let rows = 16
        let cellW = size.width / Double(cols)
        let cellH = size.height / Double(rows)
        for y in 0..<rows {
            for x in 0..<cols {
                let value = sin(Double(x) * 0.65 + time * 1.4) + cos(Double(y) * 0.72 - time * 1.1) + sin(Double(x + y) * 0.31 + time * 0.8)
                let inset = 3.0 + (value + 3.0) * 2.2
                let rect = CGRect(x: Double(x) * cellW + inset + stereoOffset * 0.08, y: Double(y) * cellH + inset, width: max(2, cellW - inset * 2), height: max(2, cellH - inset * 2))
                context.fill(Path(roundedRect: rect, cornerRadius: min(rect.width, rect.height) * 0.45), with: .color(blendedColor(preset: preset, t: value * 0.18 + time * 0.04).opacity(0.08 + max(0, value) * 0.08)))
            }
        }
    }

    private func drawReactionDiffusionEngine(context: inout GraphicsContext, size: CGSize, time: TimeInterval, preset: VisualPreset, stereoOffset: Double) {
        let cols = 54
        let rows = 34
        let cellW = size.width / Double(cols)
        let cellH = size.height / Double(rows)
        for y in 0..<rows {
            for x in 0..<cols {
                let nx = Double(x) / Double(cols)
                let ny = Double(y) / Double(rows)
                let feed = 0.035 + model.macroX * 0.035
                let kill = 0.045 + model.macroY * 0.035
                let u = sin((nx * 18.0 + time * 0.65) + sin(ny * 11.0 - time * 0.42))
                let v = cos((ny * 20.0 - time * 0.55) + cos(nx * 13.0 + time * 0.31))
                let reaction = abs(sin((u * v + feed - kill) * 18.0 + time * 0.85))
                guard reaction > 0.48 else { continue }
                let rect = CGRect(x: Double(x) * cellW + stereoOffset * 0.12, y: Double(y) * cellH, width: cellW + 1, height: cellH + 1)
                context.fill(Path(rect), with: .color(blendedColor(preset: preset, t: reaction + time * 0.03).opacity((reaction - 0.35) * 0.24)))
            }
        }
    }

    private func drawKaleidoscopeMazeEngine(context: inout GraphicsContext, size: CGSize, time: TimeInterval, preset: VisualPreset, beat: Double, stereoOffset: Double) {
        let center = CGPoint(x: size.width / 2 + stereoOffset, y: size.height / 2)
        let symmetry = max(6, preset.symmetry * 2)
        let rings = 14 + Int(model.macroY * 18)
        for ring in 1...rings {
            let radius = min(size.width, size.height) * Double(ring) / Double(rings) * 0.54
            for spoke in 0..<symmetry {
                let phase = Double(spoke) / Double(symmetry)
                let a0 = phase * Double.pi * 2.0 + time * 0.13 + Double(ring % 3) * 0.16
                let a1 = a0 + Double.pi / Double(symmetry) * (1.0 + sin(time + Double(ring)) * 0.7)
                var path = Path()
                path.move(to: CGPoint(x: center.x + cos(a0) * radius, y: center.y + sin(a0) * radius))
                path.addLine(to: CGPoint(x: center.x + cos(a1) * radius * (0.76 + beat * 0.18), y: center.y + sin(a1) * radius * (0.76 + beat * 0.18)))
                context.stroke(path, with: .color(blendedColor(preset: preset, t: phase + Double(ring) * 0.07 + time * 0.03).opacity(0.10 + model.lightSynthIntensity * 0.22)), lineWidth: 1.0 + model.exposure * 1.8)
            }
        }
    }

    private func drawMoireFieldEngine(context: inout GraphicsContext, size: CGSize, time: TimeInterval, preset: VisualPreset, stereoOffset: Double) {
        let centers = [
            CGPoint(x: size.width * (0.36 + sin(time * 0.17) * 0.12) + stereoOffset, y: size.height * 0.50),
            CGPoint(x: size.width * (0.64 + cos(time * 0.13) * 0.12) + stereoOffset, y: size.height * (0.50 + sin(time * 0.11) * 0.18))
        ]
        for (centerIndex, center) in centers.enumerated() {
            for ring in 0..<42 {
                let radius = Double(ring) * min(size.width, size.height) / 70.0 + sin(time * 1.2 + Double(ring)) * 4.0
                let rect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
                context.stroke(Path(ellipseIn: rect), with: .color(blendedColor(preset: preset, t: Double(ring) * 0.025 + Double(centerIndex) * 0.3 + time * 0.02).opacity(0.045 + model.lightSynthIntensity * 0.055)), lineWidth: 1.0)
            }
        }
    }

    private func drawSlitScanRibbonsEngine(context: inout GraphicsContext, size: CGSize, time: TimeInterval, preset: VisualPreset, stereoOffset: Double) {
        let strips = 44
        let stripW = size.width / Double(strips)
        for strip in 0..<strips {
            let t = Double(strip) / Double(strips)
            let delay = t * (0.9 + model.macroX * 2.4)
            var path = Path()
            for pointIndex in 0...80 {
                let y = Double(pointIndex) / 80.0 * size.height
                let wave = sin(y * 0.028 + time * 2.0 - delay * 3.0) * (18.0 + model.macroY * 70.0)
                let x = Double(strip) * stripW + stripW / 2 + wave + stereoOffset * t
                if pointIndex == 0 { path.move(to: CGPoint(x: x, y: y)) } else { path.addLine(to: CGPoint(x: x, y: y)) }
            }
            context.stroke(path, with: .color(blendedColor(preset: preset, t: t + time * 0.04).opacity(0.12 + model.exposure * 0.16)), lineWidth: max(1.0, stripW * 0.42))
        }
    }

    private func drawCellularAutomataEngine(context: inout GraphicsContext, size: CGSize, time: TimeInterval, preset: VisualPreset, stereoOffset: Double) {
        let cols = 48
        let rows = 30
        let generation = Int(time * (4.0 + model.macroY * 18.0))
        let cellW = size.width / Double(cols)
        let cellH = size.height / Double(rows)
        for y in 0..<rows {
            for x in 0..<cols {
                let seed = (x * 73) ^ (y * 151) ^ (generation * 313) ^ model.sceneSeed
                let neighbors = ((seed >> 1) ^ (seed >> 4) ^ (seed >> 7)) & 7
                let alive = neighbors == 3 || (neighbors == 2 && ((seed >> 3) & 1) == 1)
                guard alive else { continue }
                let rectX = CGFloat(Double(x) * cellW + 1.0 + stereoOffset * 0.06)
                let rectY = CGFloat(Double(y) * cellH + 1.0)
                let rect = CGRect(x: rectX, y: rectY, width: CGFloat(cellW - 1.0), height: CGFloat(cellH - 1.0))
                context.fill(Path(rect), with: .color(blendedColor(preset: preset, t: Double(neighbors) / 8.0 + time * 0.02).opacity(0.14 + model.lightSynthIntensity * 0.24)))
            }
        }
    }

    private func drawPulseRings(context: inout GraphicsContext, size: CGSize, time: TimeInterval, preset: VisualPreset, beat: Double) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let shortest = min(size.width, size.height)
        for ring in 0..<8 {
            let phase = (Double(ring) / 8.0 + beat).truncatingRemainder(dividingBy: 1)
            let rect = CGRect(
                x: center.x - shortest * phase * 0.62,
                y: center.y - shortest * phase * 0.62,
                width: shortest * phase * 1.24,
                height: shortest * phase * 1.24
            )
            context.stroke(
                Path(ellipseIn: rect),
                with: .color(blendedColor(preset: preset, t: phase).opacity((1.0 - phase) * model.bloom)),
                lineWidth: 1.0 + model.bloom * 5.0
            )
        }
    }

    private func drawGridGlitch(context: inout GraphicsContext, size: CGSize, time: TimeInterval, preset: VisualPreset) {
        guard preset.family == .demoscene || preset.family == .laser || preset.strobe > 0.18 else { return }
        let rows = 18
        for row in 0..<rows {
            let y = size.height * Double(row) / Double(rows)
            let offset = sin(time * 2.0 + Double(row)) * preset.warp * 18.0
            var path = Path()
            path.move(to: CGPoint(x: offset, y: y))
            path.addLine(to: CGPoint(x: size.width + offset, y: y + sin(time + Double(row)) * 8.0))
            context.stroke(path, with: .color(preset.colorC.opacity(0.12 + preset.strobe)), lineWidth: 1)
        }
    }

    private func drawDemosceneLayer(context: inout GraphicsContext, size: CGSize, time: TimeInterval, preset: VisualPreset, beat: Double) {
        let mode = model.demosceneEffectMode
        guard mode != .off || preset.family == .demoscene else { return }

        if mode == .copperBars || mode == .megaDemo || preset.family == .demoscene {
            drawCopperBars(context: &context, size: size, time: time, preset: preset)
        }
        if mode == .plasma || mode == .megaDemo {
            drawPlasma(context: &context, size: size, time: time, preset: preset)
        }
        if mode == .rotoZoom || mode == .megaDemo {
            drawRotoZoom(context: &context, size: size, time: time, preset: preset)
        }
        if mode == .vectorBalls || mode == .megaDemo {
            drawVectorBalls(context: &context, size: size, time: time, preset: preset)
        }
        if mode == .starTunnel || mode == .megaDemo {
            drawStarTunnel(context: &context, size: size, time: time, preset: preset)
        }
        if mode == .sineScroller || mode == .megaDemo {
            drawSineScroller(context: &context, size: size, time: time, preset: preset, beat: beat)
        }
        if mode == .chunkyVGA || mode == .megaDemo {
            drawChunkyVGA(context: &context, size: size, time: time, preset: preset)
        }
        if mode == .moireTunnel || mode == .megaDemo {
            drawDemoMoireTunnel(context: &context, size: size, time: time, preset: preset)
        }
        if mode == .bitplaneStorm || mode == .megaDemo {
            drawBitplaneStorm(context: &context, size: size, time: time, preset: preset)
        }
        if mode == .rasterInterference || mode == .megaDemo {
            drawRasterInterference(context: &context, size: size, time: time, preset: preset)
        }
        if mode == .shadeBobs || mode == .megaDemo {
            drawShadeBobs(context: &context, size: size, time: time, preset: preset)
        }
        if mode == .twister || mode == .megaDemo {
            drawTwister(context: &context, size: size, time: time, preset: preset)
        }
        if mode == .mandelZoom || mode == .megaDemo {
            drawMandelZoom(context: &context, size: size, time: time, preset: preset)
        }
        if mode == .voxelLandscape || mode == .megaDemo {
            drawVoxelLandscape(context: &context, size: size, time: time, preset: preset)
        }
    }

    private func drawAdvancedLightSynthLayer(context: inout GraphicsContext, size: CGSize, time: TimeInterval, preset: VisualPreset, beat: Double) {
        let mode = model.lightSynthMode
        let intensity = model.flashSafety ? min(model.lightSynthIntensity, 0.82) : model.lightSynthIntensity

        if mode == .lissajousLaser || mode == .acidScope || mode == .everything {
            drawLissajousLaser(context: &context, size: size, time: time, preset: preset, intensity: intensity)
        }
        if mode == .hyperPrism || mode == .everything {
            drawHyperPrism(context: &context, size: size, time: time, preset: preset, intensity: intensity, beat: beat)
        }
        if mode == .recursiveBloom || mode == .everything {
            drawRecursiveBloom(context: &context, size: size, time: time, preset: preset, intensity: intensity)
        }
        if mode == .photonStorm || mode == .everything {
            drawPhotonStorm(context: &context, size: size, time: time, preset: preset, intensity: intensity)
        }
        if mode == .neuralMandala || mode == .everything {
            drawNeuralMandala(context: &context, size: size, time: time, preset: preset, intensity: intensity)
        }
    }

    private func drawAudioAnalyzerLayer(context: inout GraphicsContext, size: CGSize, time: TimeInterval, preset: VisualPreset, beat: Double) {
        guard model.audioVisualizerMode != .off, model.audioVisualizerIntensity > 0.01 else { return }
        let intensity = model.flashSafety ? min(model.audioVisualizerIntensity, 0.88) : model.audioVisualizerIntensity
        switch model.audioVisualizerMode {
        case .off:
            return
        case .spectrumTunnel:
            drawSpectrumTunnel(context: &context, size: size, time: time, preset: preset, intensity: intensity)
        case .oscilloscopeGarden:
            drawOscilloscopeGarden(context: &context, size: size, time: time, preset: preset, intensity: intensity, beat: beat)
        case .chromaVectorscope:
            drawChromaVectorscope(context: &context, size: size, time: time, preset: preset, intensity: intensity)
        case .spectralParticles:
            drawSpectralParticles(context: &context, size: size, time: time, preset: preset, intensity: intensity)
        case .feedbackWaveform:
            drawFeedbackWaveformVisualizer(context: &context, size: size, time: time, preset: preset, intensity: intensity, beat: beat)
        case .spectralLattice:
            drawSpectralLatticeVisualizer(context: &context, size: size, time: time, preset: preset, intensity: intensity)
        case .phaseBloom:
            drawPhaseBloomVisualizer(context: &context, size: size, time: time, preset: preset, intensity: intensity, beat: beat)
        case .hyperAnalyzer:
            drawSpectrumTunnel(context: &context, size: size, time: time, preset: preset, intensity: intensity * 0.72)
            drawOscilloscopeGarden(context: &context, size: size, time: time, preset: preset, intensity: intensity * 0.58, beat: beat)
            drawChromaVectorscope(context: &context, size: size, time: time, preset: preset, intensity: intensity * 0.74)
            drawSpectralParticles(context: &context, size: size, time: time, preset: preset, intensity: intensity * 0.62)
            drawFeedbackWaveformVisualizer(context: &context, size: size, time: time, preset: preset, intensity: intensity * 0.44, beat: beat)
            drawSpectralLatticeVisualizer(context: &context, size: size, time: time, preset: preset, intensity: intensity * 0.42)
            drawPhaseBloomVisualizer(context: &context, size: size, time: time, preset: preset, intensity: intensity * 0.36, beat: beat)
        }
    }

    private func drawSpectrumTunnel(context: inout GraphicsContext, size: CGSize, time: TimeInterval, preset: VisualPreset, intensity: Double) {
        let center = CGPoint(x: size.width * (0.5 + model.audioMeter.stereoBalance * 0.06), y: size.height / 2)
        let shortest = min(size.width, size.height)
        let bins = 28 + Int(model.audioVisualizerDetail * 44)
        let bassKick = model.audioMeter.bass + model.audioMeter.transient * 0.55
        let baseRadius = shortest * (0.08 + bassKick * 0.08)
        let spin = time * (0.08 + model.audioMeter.spectralCentroid * 0.22)

        for bin in 0..<bins {
            let amount = Double(bin) / Double(bins)
            let value = spectrumBin(bin, count: bins, time: time)
            let angle = amount * Double.pi * 2.0 + spin
            let inner = baseRadius + shortest * 0.025 * sin(time * 1.7 + amount * 18.0)
            let outer = inner + shortest * (0.08 + value * (0.22 + model.audioVisualizerDetail * 0.18))
            let start = CGPoint(x: center.x + cos(angle) * inner, y: center.y + sin(angle) * inner)
            let end = CGPoint(x: center.x + cos(angle) * outer, y: center.y + sin(angle) * outer)
            var bar = Path()
            bar.move(to: start)
            bar.addLine(to: end)
            context.stroke(
                bar,
                with: .color(blendedColor(preset: preset, t: amount + model.audioMeter.spectralCentroid * 0.35 + time * 0.015).opacity((0.08 + value * 0.34) * intensity)),
                lineWidth: 1.0 + value * (5.0 + intensity * 6.0)
            )
        }

        let rings = 5 + Int(model.audioVisualizerPersistence * 7)
        for ring in 0..<rings {
            let phase = (Double(ring) / Double(max(1, rings)) + time * (0.04 + model.audioMeter.spectralFlux * 0.08)).truncatingRemainder(dividingBy: 1)
            let radius = shortest * (0.10 + phase * (0.34 + model.audioMeter.bass * 0.16))
            let rect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
            context.stroke(
                Path(ellipseIn: rect),
                with: .color(blendedColor(preset: preset, t: phase + 0.2).opacity((1.0 - phase) * intensity * (0.09 + model.audioMeter.transient * 0.20))),
                lineWidth: 0.8 + model.audioMeter.bass * 5.0
            )
        }
    }

    private func drawOscilloscopeGarden(context: inout GraphicsContext, size: CGSize, time: TimeInterval, preset: VisualPreset, intensity: Double, beat: Double) {
        let lanes = 5 + Int(model.audioVisualizerDetail * 5)
        let bass = model.audioMeter.bass
        let mid = model.audioMeter.mid
        let treble = model.audioMeter.treble
        let points = 160

        for lane in 0..<lanes {
            let laneT = Double(lane) / Double(max(1, lanes - 1))
            let baseline = size.height * (0.16 + laneT * 0.68)
            let amp = size.height * (0.025 + intensity * 0.055 + bass * 0.055 + treble * 0.030)
            var ribbon = Path()
            for point in 0...points {
                let u = Double(point) / Double(points)
                let carrier = sin(u * Double.pi * (4.0 + laneT * 12.0 + model.audioVisualizerDetail * 8.0) + time * (1.0 + laneT + mid * 4.0))
                let fold = sin(u * Double.pi * (13.0 + model.audioMeter.spectralCentroid * 18.0) - time * (0.7 + treble * 5.0))
                let beatBend = sin(beat * Double.pi * 2.0 + laneT * 4.0) * bass
                let x = u * size.width
                let y = baseline + (carrier * 0.72 + fold * 0.28 + beatBend * 0.32) * amp
                if point == 0 { ribbon.move(to: CGPoint(x: x, y: y)) } else { ribbon.addLine(to: CGPoint(x: x, y: y)) }
            }
            context.stroke(
                ribbon,
                with: .color(blendedColor(preset: preset, t: laneT + time * 0.03).opacity(0.08 + intensity * (0.10 + mid * 0.18))),
                lineWidth: 0.8 + intensity * 2.2 + treble * 2.5
            )
        }
    }

    private func drawChromaVectorscope(context: inout GraphicsContext, size: CGSize, time: TimeInterval, preset: VisualPreset, intensity: Double) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let radius = min(size.width, size.height) * (0.16 + model.audioMeter.mid * 0.16 + model.macroY * 0.12)
        let loops = 2 + Int(model.audioVisualizerDetail * 5)
        let points = 360
        let balance = model.audioMeter.stereoBalance
        let centroid = model.audioMeter.spectralCentroid

        for loop in 0..<loops {
            let loopT = Double(loop) / Double(max(1, loops))
            var path = Path()
            let ax = 2.0 + Double(loop % 3) + model.audioMeter.bass * 4.0
            let ay = 3.0 + Double((loop + 1) % 4) + model.audioMeter.treble * 5.0
            let phase = time * (0.18 + centroid * 0.8) + loopT * Double.pi + balance * 0.7
            for index in 0...points {
                let u = Double(index) / Double(points) * Double.pi * 2.0
                let x = sin(ax * u + phase) + sin((ax + ay) * 0.5 * u - time * 0.35) * 0.26
                let y = sin(ay * u - phase * 1.2) + cos((ay + 1.0) * u + time * 0.22) * 0.20
                let point = CGPoint(
                    x: center.x + x * radius * (0.72 + loopT * 0.28) + balance * size.width * 0.06,
                    y: center.y + y * radius * (0.55 + loopT * 0.22)
                )
                if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
            }
            context.stroke(
                path,
                with: .color(blendedColor(preset: preset, t: loopT + centroid + time * 0.02).opacity(intensity * (0.10 + model.audioMeter.spectralFlux * 0.22))),
                lineWidth: 0.7 + intensity * 2.2 + model.audioMeter.transient * 2.8
            )
        }
    }

    private func drawSpectralParticles(context: inout GraphicsContext, size: CGSize, time: TimeInterval, preset: VisualPreset, intensity: Double) {
        let count = 70 + Int(model.audioVisualizerDetail * 130)
        let bass = model.audioMeter.bass
        let mid = model.audioMeter.mid
        let treble = model.audioMeter.treble
        let flux = model.audioMeter.spectralFlux

        for index in 0..<count {
            let seed = Double((index * 37 + model.sceneSeed * 13) % 997) / 997.0
            let lane = Double((index * 71 + model.sceneSeed * 5) % 991) / 991.0
            let orbit = 0.08 + pow(seed, 0.65) * 0.62 + bass * 0.10
            let angle = time * (0.06 + lane * 0.18 + flux * 0.42) + seed * Double.pi * 8.0 + mid * 0.8
            let x = size.width * (0.5 + cos(angle) * orbit * (0.58 + model.macroX * 0.35))
            let y = size.height * (0.5 + sin(angle * (0.7 + lane * 0.6)) * orbit * (0.42 + model.macroY * 0.30))
            let diameter = 1.4 + treble * 7.0 + flux * 6.0 + (index % 5 == 0 ? bass * 8.0 : 0)
            let alpha = intensity * (0.035 + spectrumBin(index, count: count, time: time) * 0.20)
            context.fill(
                Path(ellipseIn: CGRect(x: x - diameter / 2, y: y - diameter / 2, width: diameter, height: diameter)),
                with: .color(blendedColor(preset: preset, t: seed + time * 0.015 + model.audioMeter.spectralCentroid).opacity(alpha))
            )
        }
    }

    private func drawFeedbackWaveformVisualizer(context: inout GraphicsContext, size: CGSize, time: TimeInterval, preset: VisualPreset, intensity: Double, beat: Double) {
        let center = CGPoint(x: size.width * (0.5 + model.audioMeter.stereoBalance * 0.05), y: size.height / 2)
        let traces = 5 + Int(model.audioVisualizerPersistence * 9)
        let points = 220
        let shortest = min(size.width, size.height)

        for trace in 0..<traces {
            let echo = Double(trace) / Double(max(1, traces - 1))
            let decay = pow(1.0 - echo, 1.4)
            let radius = shortest * (0.09 + echo * (0.34 + model.audioMeter.bass * 0.12))
            let phase = time * (0.45 + model.audioMeter.spectralFlux * 1.1) - echo * 1.7
            var path = Path()
            for pointIndex in 0...points {
                let u = Double(pointIndex) / Double(points) * Double.pi * 2.0
                let carrier = sin(u * (2.0 + model.audioMeter.mid * 7.0) + phase)
                let mod = sin(u * (7.0 + model.audioVisualizerDetail * 9.0) - time * (1.1 + model.audioMeter.treble * 4.0))
                let wobble = 1.0 + (carrier * 0.16 + mod * 0.07 + sin(beat * Double.pi * 2.0 + echo * 4.0) * model.audioMeter.bass * 0.10) * intensity
                let angle = u + echo * 0.38 + time * 0.035
                let p = CGPoint(x: center.x + cos(angle) * radius * wobble, y: center.y + sin(angle) * radius * wobble * (0.62 + model.macroY * 0.32))
                if pointIndex == 0 {
                    path.move(to: p)
                } else {
                    path.addLine(to: p)
                }
            }
            context.stroke(path, with: .color(blendedColor(preset: preset, t: echo + time * 0.02).opacity(decay * intensity * (0.07 + model.audioMeter.spectralFlux * 0.20))), lineWidth: 0.8 + decay * (2.4 + model.audioMeter.transient * 4.0))
        }
    }

    private func drawSpectralLatticeVisualizer(context: inout GraphicsContext, size: CGSize, time: TimeInterval, preset: VisualPreset, intensity: Double) {
        let cols = 10 + Int(model.audioVisualizerDetail * 18)
        let rows = 7 + Int(model.audioVisualizerDetail * 12)
        let cellW = size.width / Double(cols)
        let cellH = size.height / Double(rows)
        let depth = 14.0 + intensity * 38.0 + model.audioMeter.bass * 34.0

        for row in 0...rows {
            var path = Path()
            for col in 0...cols {
                let nx = Double(col) / Double(cols)
                let ny = Double(row) / Double(rows)
                let bin = spectrumBin(col + row * cols, count: max(1, cols * rows), time: time)
                let warp = sin(nx * 12.0 + ny * 7.0 + time * (0.7 + model.audioMeter.spectralCentroid)) * depth * bin
                let x = nx * size.width + sin(ny * 9.0 + time) * model.audioMeter.stereoBalance * 18.0
                let y = ny * size.height + warp
                if col == 0 { path.move(to: CGPoint(x: x, y: y)) } else { path.addLine(to: CGPoint(x: x, y: y)) }
            }
            context.stroke(path, with: .color(blendedColor(preset: preset, t: Double(row) / Double(max(1, rows)) + time * 0.018).opacity(0.035 + intensity * 0.11)), lineWidth: 0.8 + model.audioMeter.treble * 2.6)
        }

        for col in 0...cols {
            var path = Path()
            for row in 0...rows {
                let nx = Double(col) / Double(cols)
                let ny = Double(row) / Double(rows)
                let bin = spectrumBin(row + col * rows, count: max(1, cols * rows), time: time + 0.31)
                let warp = cos(ny * 11.0 - nx * 6.0 - time * (0.8 + model.audioMeter.spectralFlux)) * depth * bin
                let x = nx * size.width + warp
                let y = ny * size.height + cos(nx * 8.0 - time) * model.audioMeter.stereoBalance * 14.0
                if row == 0 { path.move(to: CGPoint(x: x, y: y)) } else { path.addLine(to: CGPoint(x: x, y: y)) }
            }
            context.stroke(path, with: .color(blendedColor(preset: preset, t: Double(col) / Double(max(1, cols)) + 0.33 + time * 0.018).opacity(0.025 + intensity * 0.09)), lineWidth: 0.7 + model.audioMeter.mid * 2.2)
        }

        for row in 0..<rows {
            for col in 0..<cols where (row + col) % 3 == 0 {
                let value = spectrumBin(col + row * cols, count: max(1, cols * rows), time: time)
                guard value > 0.18 else { continue }
                let x = Double(col) * cellW + cellW * 0.5
                let y = Double(row) * cellH + cellH * 0.5
                let radius = (1.4 + value * 6.5 + model.audioMeter.transient * 8.0) * intensity
                context.fill(Path(ellipseIn: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)), with: .color(blendedColor(preset: preset, t: value + time * 0.02).opacity(0.05 + value * intensity * 0.22)))
            }
        }
    }

    private func drawPhaseBloomVisualizer(context: inout GraphicsContext, size: CGSize, time: TimeInterval, preset: VisualPreset, intensity: Double, beat: Double) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let petals = 9 + Int(model.audioVisualizerDetail * 23)
        let shortest = min(size.width, size.height)
        for petal in 0..<petals {
            let t = Double(petal) / Double(petals)
            let phase = time * (0.12 + model.audioMeter.spectralCentroid * 0.36) + t * Double.pi * 2.0
            let phaseOffset = sin(time * 0.6 + t * 13.0) * model.audioMeter.stereoBalance * 0.45
            let radius = shortest * (0.10 + 0.38 * abs(sin(phase + beat * Double.pi)))
            let width = shortest * (0.06 + model.audioMeter.bass * 0.11 + intensity * 0.07)
            let height = shortest * (0.18 + model.audioMeter.treble * 0.20 + intensity * 0.14)
            let x = center.x + cos(phase + phaseOffset) * radius * 0.48
            let y = center.y + sin(phase * (0.72 + model.macroY * 0.42)) * radius * 0.35
            let rect = CGRect(x: x - width / 2, y: y - height / 2, width: width, height: height)
            var layer = context
            layer.opacity = intensity * (0.035 + model.audioMeter.spectralFlux * 0.16 + model.audioMeter.transient * 0.08)
            layer.translateBy(x: x, y: y)
            layer.rotate(by: .radians(phase + Double.pi * 0.5))
            layer.translateBy(x: -x, y: -y)
            layer.fill(Path(ellipseIn: rect), with: .color(blendedColor(preset: preset, t: t + time * 0.035)))
        }
    }

    private func drawVisualDelayTaps(context: inout GraphicsContext, size: CGSize, time: TimeInterval, preset: VisualPreset) {
        let settings = model.delaySettings
        guard settings.enabled, settings.visualDelayEnabled else { return }
        let secondsPerBeat = 60.0 / max(40.0, model.sequencer.bpm)
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let shortest = min(size.width, size.height)

        for tap in settings.taps where tap.enabled {
            let delayedTime = time - tap.beatOffset * secondsPerBeat
            let energy = musicEnergy(at: delayedTime)
            let opacity = settings.visualEchoOpacity * tap.level * (0.35 + energy * 0.85)
            let spread = 0.12 + tap.visualSpread * 0.62
            let ringCount = 3 + Int(tap.visualSpread * 5)

            for ring in 0..<ringCount {
                let phase = (delayedTime * 0.18 + Double(ring) / Double(ringCount)).truncatingRemainder(dividingBy: 1)
                let radius = shortest * (0.06 + phase * spread)
                let wobble = sin(delayedTime * 2.0 + Double(ring)) * shortest * 0.025 * tap.visualSpread
                let rect = CGRect(
                    x: center.x - radius + wobble,
                    y: center.y - radius * 0.64 - wobble,
                    width: radius * 2.0,
                    height: radius * 1.28
                )
                context.stroke(
                    Path(ellipseIn: rect),
                    with: .color(blendedColor(preset: preset, t: phase + tap.beatOffset).opacity(opacity * (1.0 - phase * 0.55))),
                    lineWidth: 1.0 + energy * 4.0
                )
            }

            let rays = 8 + Int(tap.visualSpread * 18)
            for ray in 0..<rays {
                let amount = Double(ray) / Double(rays)
                let angle = delayedTime * (0.4 + tap.visualSpread) + amount * Double.pi * 2.0
                let length = shortest * (0.18 + tap.visualSpread * 0.42 + energy * 0.18)
                let startRadius = shortest * 0.04
                let cosine = Darwin.cos(angle)
                let sine = Darwin.sin(angle)
                let startPoint = CGPoint(x: center.x + cosine * startRadius, y: center.y + sine * startRadius)
                let endPoint = CGPoint(x: center.x + cosine * length, y: center.y + sine * length)
                var path = Path()
                path.move(to: startPoint)
                path.addLine(to: endPoint)
                context.stroke(path, with: .color(blendedColor(preset: preset, t: amount + delayedTime * 0.03).opacity(opacity * 0.42)), lineWidth: 0.8 + tap.level * 3.0)
            }
        }
    }

    private func musicEnergy(at time: TimeInterval) -> Double {
        let secondsPerStep = 60.0 / max(40.0, model.sequencer.bpm) / 4.0
        let position = swungStepPosition(time: max(0, time), secondsPerStep: secondsPerStep, swing: model.sequencer.swing)
        let step = Int(floor(position)) % max(1, model.sequencer.patternLength)
        var energy = 0.05
        if model.sequencer.kick.steps[step] { energy += 0.45 }
        if model.sequencer.snare.steps[step] { energy += 0.25 }
        if model.sequencer.hat.steps[step] { energy += 0.12 }
        if model.sequencer.bass.steps[step] { energy += 0.22 }
        if model.sequencer.lead.steps[step] { energy += 0.18 }
        energy += Double(model.liveNotes.count) * 0.08
        return min(1.0, energy)
    }

    private func spectrumBin(_ index: Int, count: Int, time: TimeInterval) -> Double {
        let position = Double(index) / Double(max(1, count - 1))
        let bassWeight = exp(-pow((position - 0.12) / 0.18, 2.0))
        let midWeight = exp(-pow((position - 0.48) / 0.24, 2.0))
        let trebleWeight = exp(-pow((position - 0.82) / 0.18, 2.0))
        let shimmer = 0.5 + 0.5 * sin(time * (1.7 + position * 4.0) + Double(index * 11 + model.sceneSeed) * 0.17)
        let value = model.audioMeter.bass * bassWeight
            + model.audioMeter.mid * midWeight
            + model.audioMeter.treble * trebleWeight
            + model.audioMeter.spectralFlux * shimmer * 0.38
            + model.audioMeter.transient * (index % 7 == 0 ? 0.32 : 0.0)
        return min(1.0, max(0.0, value))
    }

    private func swungStepPosition(time: Double, secondsPerStep: Double, swing: Double) -> Double {
        let raw = time / secondsPerStep
        let pair = floor(raw / 2.0)
        let phase = raw - pair * 2.0
        let shift = min(0.65, max(0, swing)) * 0.5
        if phase < 1.0 + shift {
            return pair * 2.0 + phase / (1.0 + shift)
        }
        return pair * 2.0 + 1.0 + (phase - 1.0 - shift) / max(0.2, 1.0 - shift)
    }

    private func drawPaletteAndGate(context: inout GraphicsContext, size: CGSize, time: TimeInterval, preset: VisualPreset) {
        let palette = paletteColor(time: time, preset: preset)
        let blendAlpha: Double
        switch model.blendMode {
        case .additive:
            blendAlpha = 0.04
        case .screen:
            blendAlpha = 0.075
        case .softKey:
            blendAlpha = 0.10
        case .hardKey:
            blendAlpha = 0.14
        case .difference:
            blendAlpha = 0.09
        }

        context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(palette.opacity(blendAlpha * model.lightSynthIntensity)))

        guard model.strobeEnabled else { return }
        let cappedRate = model.flashSafety ? min(model.strobeRate, 10.0) : model.strobeRate
        let phase = (time * cappedRate).truncatingRemainder(dividingBy: 1)
        if phase < 0.08 {
            let alpha = model.flashSafety ? 0.22 : 0.55
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.white.opacity(alpha * model.lightSynthIntensity)))
        }
    }

    private func paletteColor(time: TimeInterval, preset: VisualPreset) -> Color {
        switch model.paletteMode {
        case .neon:
            return blendedColor(preset: preset, t: time * 0.04)
        case .colourspace:
            return Color.hsba(time * 0.045 + model.macroX * 0.25, 0.92, 1.0)
        case .yakNeon:
            return Color.hsba(0.80 + sin(time * 0.21) * 0.18, 1.0, 1.0)
        case .phosphor:
            return Color(red: 0.25 + 0.25 * sin(time * 0.33), green: 1.0, blue: 0.30 + 0.30 * model.macroY)
        case .laserium:
            return Color.hsba(0.58 + sin(time * 0.17) * 0.16, 0.82, 1.0)
        case .acid:
            return Color.hsba(0.23 + sin(time * 0.3) * 0.08, 1.0, 1.0)
        case .ultraviolet:
            return Color(red: 0.45, green: 0.12, blue: 1.0)
        case .infrared:
            return Color(red: 1.0, green: 0.08, blue: 0.03)
        case .ice:
            return Color(red: 0.55, green: 0.95, blue: 1.0)
        case .monochrome:
            return .white
        case .rainbow:
            return Color.hsba(time * 0.07, 0.9, 1.0)
        case .amber:
            return Color(red: 1.0, green: 0.62, blue: 0.12)
        }
    }

    private func drawLissajousLaser(context: inout GraphicsContext, size: CGSize, time: TimeInterval, preset: VisualPreset, intensity: Double) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let radius = min(size.width, size.height) * (0.18 + model.macroY * 0.34)
        let splits = max(1, model.prismSplits)

        for split in 0..<splits {
            let offset = Double(split) - Double(splits - 1) / 2.0
            var path = Path()
            let points = 420
            let ax = 2.0 + floor(model.macroX * 7.0)
            let ay = 3.0 + floor(model.macroY * 8.0)
            let phase = time * (0.7 + model.macroX * 1.6) + offset * 0.09
            for pointIndex in 0..<points {
                let u = Double(pointIndex) / Double(points - 1) * Double.pi * 2.0
                let x = sin(ax * u + phase) + 0.32 * sin((ax + ay) * u * 0.5 - time)
                let y = sin(ay * u + phase * 1.37) + 0.28 * cos((ay + 1.0) * u + time * 0.6)
                let p = CGPoint(
                    x: center.x + x * radius + offset * 3.5,
                    y: center.y + y * radius * 0.72 - offset * 2.5
                )
                if pointIndex == 0 { path.move(to: p) } else { path.addLine(to: p) }
            }
            context.stroke(path, with: .color(blendedColor(preset: preset, t: Double(split) / Double(splits) + time * 0.03).opacity(0.12 + intensity * 0.45)), lineWidth: 0.7 + intensity * 2.8)
        }
    }

    private func drawHyperPrism(context: inout GraphicsContext, size: CGSize, time: TimeInterval, preset: VisualPreset, intensity: Double, beat: Double) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let rays = 18 + Int(model.macroX * 40)
        let length = hypot(size.width, size.height) * (0.32 + model.macroY * 0.44)
        for ray in 0..<rays {
            let t = Double(ray) / Double(rays)
            let angle = t * Double.pi * 2.0 + time * (0.12 + model.macroX * 0.35) + sin(beat * Double.pi * 2.0 + t * 9.0) * 0.08
            let inner = min(size.width, size.height) * (0.035 + 0.08 * sin(time + t * 6.0))
            var path = Path()
            path.move(to: CGPoint(x: center.x + cos(angle) * inner, y: center.y + sin(angle) * inner))
            path.addLine(to: CGPoint(x: center.x + cos(angle) * length, y: center.y + sin(angle) * length))
            context.stroke(path, with: .color(blendedColor(preset: preset, t: t + time * 0.05).opacity(0.05 + intensity * 0.23)), lineWidth: 1.0 + intensity * 3.0)
        }
    }

    private func drawRecursiveBloom(context: inout GraphicsContext, size: CGSize, time: TimeInterval, preset: VisualPreset, intensity: Double) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let shells = 18
        for shell in 0..<shells {
            let t = Double(shell) / Double(shells)
            let scale = pow(t, 1.22)
            let radius = min(size.width, size.height) * (0.04 + scale * (0.58 + model.macroY * 0.2))
            let sides = 5 + Int(model.macroX * 8)
            let rotation = time * (0.22 + model.macroY * 0.24) + t * Double.pi
            var path = Path()
            for side in 0...sides {
                let angle = rotation + Double(side) / Double(sides) * Double.pi * 2.0
                let wobble = 1.0 + sin(time * 1.5 + Double(side) + t * 8.0) * 0.12
                let point = CGPoint(x: center.x + cos(angle) * radius * wobble, y: center.y + sin(angle) * radius * wobble)
                if side == 0 { path.move(to: point) } else { path.addLine(to: point) }
            }
            context.stroke(path, with: .color(blendedColor(preset: preset, t: t - time * 0.035).opacity((1.0 - t) * (0.08 + intensity * 0.24) * model.phosphorPersistence)), lineWidth: 1.0 + (1.0 - t) * 6.0)
        }
    }

    private func drawPhotonStorm(context: inout GraphicsContext, size: CGSize, time: TimeInterval, preset: VisualPreset, intensity: Double) {
        let center = CGPoint(x: size.width * model.macroX, y: size.height * (1.0 - model.macroY))
        let count = 120 + Int(intensity * 220)
        for particle in 0..<count {
            let seed = Double((particle * 6187) % 7919) / 7919.0
            let phase = (seed + time * (0.03 + model.macroX * 0.10)).truncatingRemainder(dividingBy: 1)
            let angle = seed * Double.pi * 16.0 + time * (0.4 + model.macroY)
            let distance = pow(phase, 1.8) * hypot(size.width, size.height) * 0.62
            let p1 = CGPoint(x: center.x + cos(angle) * distance, y: center.y + sin(angle) * distance)
            let tailDistance = Swift.max(0.0, distance - 18.0 - phase * 90.0)
            let p0 = CGPoint(x: center.x + cos(angle) * tailDistance, y: center.y + sin(angle) * tailDistance)
            var path = Path()
            path.move(to: p0)
            path.addLine(to: p1)
            context.stroke(path, with: .color(blendedColor(preset: preset, t: seed + time * 0.04).opacity(phase * intensity * 0.38)), lineWidth: 0.8 + phase * 2.6)
        }
    }

    private func drawNeuralMandala(context: inout GraphicsContext, size: CGSize, time: TimeInterval, preset: VisualPreset, intensity: Double) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let nodes = 28
        var points: [CGPoint] = []
        let base = min(size.width, size.height) * (0.18 + model.macroY * 0.24)
        for index in 0..<nodes {
            let t = Double(index) / Double(nodes)
            let angle = t * Double.pi * 2.0
            let r = base * (0.72 + 0.28 * sin(time * 1.4 + t * 18.0))
            points.append(CGPoint(x: center.x + cos(angle) * r, y: center.y + sin(angle) * r))
        }

        for i in points.indices {
            for j in (i + 1)..<points.count where (j - i) % 5 == 0 || (j + i) % 9 == 0 {
                var path = Path()
                path.move(to: points[i])
                path.addLine(to: points[j])
                let t = Double((i + j) % points.count) / Double(points.count)
                context.stroke(path, with: .color(blendedColor(preset: preset, t: t + time * 0.02).opacity(0.025 + intensity * 0.075)), lineWidth: 0.8)
            }
        }

        for (index, point) in points.enumerated() {
            let d = 5.0 + intensity * 9.0 * (0.6 + 0.4 * sin(time * 3.0 + Double(index)))
            context.fill(Path(ellipseIn: CGRect(x: point.x - d / 2, y: point.y - d / 2, width: d, height: d)), with: .color(blendedColor(preset: preset, t: Double(index) / Double(nodes)).opacity(0.22 + intensity * 0.32)))
        }
    }

    private func drawCopperBars(context: inout GraphicsContext, size: CGSize, time: TimeInterval, preset: VisualPreset) {
        let bars = 18
        let height = size.height / 22.0
        for bar in 0..<bars {
            let phase = Double(bar) / Double(bars)
            let y = (sin(time * 1.3 + phase * Double.pi * 2.0) * 0.42 + 0.5) * size.height
            let width = size.width * (0.62 + 0.32 * sin(time * 0.9 + phase * 6.0))
            let x = (size.width - width) / 2.0
            let rect = CGRect(x: x, y: y - height / 2, width: width, height: height)
            context.fill(Path(roundedRect: rect, cornerRadius: height * 0.45), with: .linearGradient(
                Gradient(colors: [
                    blendedColor(preset: preset, t: phase).opacity(0.05),
                    blendedColor(preset: preset, t: phase + 0.15).opacity(0.34 * model.demosceneIntensity),
                    .white.opacity(0.30 * model.demosceneIntensity),
                    blendedColor(preset: preset, t: phase + 0.35).opacity(0.28 * model.demosceneIntensity),
                    blendedColor(preset: preset, t: phase).opacity(0.04)
                ]),
                startPoint: CGPoint(x: x, y: y - height / 2),
                endPoint: CGPoint(x: x, y: y + height / 2)
            ))
        }
    }

    private func drawPlasma(context: inout GraphicsContext, size: CGSize, time: TimeInterval, preset: VisualPreset) {
        let columns = 34
        let rows = 22
        let cellW = size.width / Double(columns)
        let cellH = size.height / Double(rows)
        for y in 0..<rows {
            for x in 0..<columns {
                let nx = Double(x) / Double(columns) - 0.5
                let ny = Double(y) / Double(rows) - 0.5
                let radial = sqrt(nx * nx + ny * ny)
                let value = sin(nx * 16.0 + time * 1.7)
                    + sin(ny * 13.0 + time * 2.1)
                    + sin((nx + ny) * 11.0 + time * 1.1)
                    + sin(radial * 32.0 - time * 3.0)
                let hue = value * 0.08 + time * 0.035
                let rect = CGRect(x: Double(x) * cellW, y: Double(y) * cellH, width: cellW + 1, height: cellH + 1)
                context.fill(Path(rect), with: .color(Color.hsba(hue, 0.9, 1.0).opacity(0.055 + model.demosceneIntensity * 0.12)))
            }
        }
    }

    private func drawRotoZoom(context: inout GraphicsContext, size: CGSize, time: TimeInterval, preset: VisualPreset) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let count = 12
        for index in 0..<count {
            let t = Double(index) / Double(count)
            let side = min(size.width, size.height) * (0.16 + t * 0.76)
            var path = Path()
            let rotation = time * (0.45 + preset.warp * 0.45) + t * Double.pi
            for corner in 0..<4 {
                let angle = rotation + Double(corner) * Double.pi / 2.0 + Double.pi / 4.0
                let point = CGPoint(x: center.x + cos(angle) * side, y: center.y + sin(angle) * side)
                if corner == 0 { path.move(to: point) } else { path.addLine(to: point) }
            }
            path.closeSubpath()
            context.stroke(path, with: .color(blendedColor(preset: preset, t: t + time * 0.05).opacity((1.0 - t) * 0.25 * model.demosceneIntensity)), lineWidth: 1.5 + (1.0 - t) * 4.0)
        }
    }

    private func drawVectorBalls(context: inout GraphicsContext, size: CGSize, time: TimeInterval, preset: VisualPreset) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let radius = min(size.width, size.height) * 0.23
        let latitudes = 9
        let longitudes = 18
        for lat in 0..<latitudes {
            let theta = (Double(lat) / Double(latitudes - 1) - 0.5) * Double.pi
            for lon in 0..<longitudes {
                let phi = Double(lon) / Double(longitudes) * Double.pi * 2.0
                var x = cos(theta) * cos(phi)
                let y = sin(theta)
                var z = cos(theta) * sin(phi)
                let rot = time * 0.9
                let rx = x * cos(rot) - z * sin(rot)
                let rz = x * sin(rot) + z * cos(rot)
                x = rx
                z = rz
                let perspective = 1.5 / (2.1 - z)
                let point = CGPoint(x: center.x + x * radius * perspective, y: center.y + y * radius * perspective)
                let diameter = (3.0 + 9.0 * perspective) * model.demosceneIntensity
                context.fill(
                    Path(ellipseIn: CGRect(x: point.x - diameter / 2, y: point.y - diameter / 2, width: diameter, height: diameter)),
                    with: .color(blendedColor(preset: preset, t: Double(lon) / Double(longitudes) + time * 0.04).opacity(0.22 + 0.42 * perspective))
                )
            }
        }
    }

    private func drawStarTunnel(context: inout GraphicsContext, size: CGSize, time: TimeInterval, preset: VisualPreset) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let count = 96
        for star in 0..<count {
            let seed = Double((star * 73) % 997) / 997.0
            let angle = seed * Double.pi * 2.0 + sin(seed * 17.0) * 0.4
            let travel = (time * (0.18 + model.demosceneIntensity * 0.42) + seed).truncatingRemainder(dividingBy: 1)
            let r1 = pow(travel, 1.8) * min(size.width, size.height) * 0.72
            let r0 = max(0, r1 - 24.0 - travel * 90.0)
            var path = Path()
            path.move(to: CGPoint(x: center.x + cos(angle) * r0, y: center.y + sin(angle) * r0))
            path.addLine(to: CGPoint(x: center.x + cos(angle) * r1, y: center.y + sin(angle) * r1))
            context.stroke(path, with: .color(blendedColor(preset: preset, t: seed + time * 0.02).opacity(travel * 0.55)), lineWidth: 1 + travel * 3)
        }
    }

    private func drawSineScroller(context: inout GraphicsContext, size: CGSize, time: TimeInterval, preset: VisualPreset, beat: Double) {
        let message = "  SONIC SCREWDRIVER EYECANDY  -  AMIGA COPPER  VGA PLASMA  ROTOZOOM  VECTOR BALLS  STAR TUNNEL  "
        let glyphs = Array(message)
        let spacing = 18.0
        let travel = (time * 90.0).truncatingRemainder(dividingBy: Double(glyphs.count) * spacing)
        for index in glyphs.indices {
            let x = size.width - travel + Double(index) * spacing
            guard x > -40, x < size.width + 40 else { continue }
            let y = size.height * 0.78 + sin(Double(index) * 0.55 + time * 4.0) * 34.0
            let text = Text(String(glyphs[index]))
                .font(.system(size: 22, weight: .black, design: .monospaced))
            var resolved = context.resolve(text)
            resolved.shading = .color(blendedColor(preset: preset, t: Double(index) / Double(glyphs.count) + beat))
            context.draw(resolved, at: CGPoint(x: x, y: y))
        }
    }

    private func drawChunkyVGA(context: inout GraphicsContext, size: CGSize, time: TimeInterval, preset: VisualPreset) {
        let block = 26.0
        let columns = Int(size.width / block) + 1
        let rows = Int(size.height / block) + 1
        for y in 0..<rows {
            for x in 0..<columns where (x + y) % 3 == 0 {
                let v = sin(Double(x) * 0.7 + time * 2.0) + cos(Double(y) * 0.8 - time * 2.4)
                let alpha = max(0, v) * 0.055 * model.demosceneIntensity
                let rect = CGRect(x: Double(x) * block, y: Double(y) * block, width: block, height: block)
                context.fill(Path(rect), with: .color(blendedColor(preset: preset, t: v * 0.2 + time * 0.02).opacity(alpha)))
            }
        }
    }

    private func drawDemoMoireTunnel(context: inout GraphicsContext, size: CGSize, time: TimeInterval, preset: VisualPreset) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        for ring in 0..<36 {
            let phase = (Double(ring) / 36.0 + time * 0.08).truncatingRemainder(dividingBy: 1)
            let radius = pow(phase, 1.45) * min(size.width, size.height) * 0.72
            let wobble = sin(time * 2.4 + Double(ring) * 0.8) * 18.0
            let rect = CGRect(x: center.x - radius - wobble, y: center.y - radius * 0.62 + wobble, width: radius * 2, height: radius * 1.24)
            context.stroke(Path(ellipseIn: rect), with: .color(blendedColor(preset: preset, t: phase + time * 0.04).opacity((1.0 - phase) * 0.18 * model.demosceneIntensity)), lineWidth: 1.0 + model.demosceneIntensity * 3.0)
        }
    }

    private func drawBitplaneStorm(context: inout GraphicsContext, size: CGSize, time: TimeInterval, preset: VisualPreset) {
        let block = 18.0
        let columns = Int(size.width / block) + 1
        let rows = Int(size.height / block) + 1
        let plane = Int(time * 9.0) & 7
        for y in 0..<rows {
            for x in 0..<columns {
                let mask = ((x * 13) ^ (y * 29) ^ (plane * 47)) & 15
                guard mask == 0 || mask == 7 else { continue }
                let rect = CGRect(x: Double(x) * block, y: Double(y) * block, width: block, height: block)
                context.fill(Path(rect), with: .color(blendedColor(preset: preset, t: Double(mask) * 0.08 + time * 0.05).opacity(0.045 + model.demosceneIntensity * 0.10)))
            }
        }
    }

    private func drawRasterInterference(context: inout GraphicsContext, size: CGSize, time: TimeInterval, preset: VisualPreset) {
        for row in stride(from: 0.0, to: size.height, by: 5.0) {
            let phase = row / max(1, size.height)
            let offset = sin(row * 0.06 + time * 4.0) * 42.0 * model.demosceneIntensity
            var path = Path()
            path.move(to: CGPoint(x: offset, y: row))
            path.addLine(to: CGPoint(x: size.width + offset, y: row + sin(time + phase * 12.0) * 8.0))
            context.stroke(path, with: .color(blendedColor(preset: preset, t: phase + time * 0.03).opacity(0.035 + model.demosceneIntensity * 0.075)), lineWidth: 1.0)
        }
    }

    private func drawShadeBobs(context: inout GraphicsContext, size: CGSize, time: TimeInterval, preset: VisualPreset) {
        for bob in 0..<18 {
            let t = Double(bob) / 18.0
            let x = size.width * (0.5 + sin(time * (0.31 + t) + t * 9.0) * 0.42)
            let y = size.height * (0.5 + cos(time * (0.37 + t * 0.7) + t * 7.0) * 0.36)
            let radius = 18.0 + model.demosceneIntensity * 46.0
            context.fill(Path(ellipseIn: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)), with: .color(blendedColor(preset: preset, t: t + time * 0.04).opacity(0.035 + model.demosceneIntensity * 0.070)))
        }
    }

    private func drawTwister(context: inout GraphicsContext, size: CGSize, time: TimeInterval, preset: VisualPreset) {
        let centerX = size.width / 2
        for slice in 0..<76 {
            let t = Double(slice) / 75.0
            let y = size.height * t
            let phase = time * 2.4 + t * Double.pi * 5.0
            let left = centerX + sin(phase) * size.width * 0.22
            let right = centerX + cos(phase) * size.width * 0.22
            var path = Path()
            path.move(to: CGPoint(x: left, y: y))
            path.addLine(to: CGPoint(x: right, y: y + size.height / 76.0))
            context.stroke(path, with: .color(blendedColor(preset: preset, t: t + time * 0.03).opacity(0.10 + model.demosceneIntensity * 0.22)), lineWidth: 2.0 + model.demosceneIntensity * 4.0)
        }
    }

    private func drawMandelZoom(context: inout GraphicsContext, size: CGSize, time: TimeInterval, preset: VisualPreset) {
        let cols = 44
        let rows = 28
        let cellW = size.width / Double(cols)
        let cellH = size.height / Double(rows)
        let zoom = 0.65 + 0.35 * sin(time * 0.27)
        for y in 0..<rows {
            for x in 0..<cols {
                let cx = (Double(x) / Double(cols) - 0.62) * zoom - 0.45
                let cy = (Double(y) / Double(rows) - 0.5) * zoom
                var zx = 0.0
                var zy = 0.0
                var iter = 0
                while zx * zx + zy * zy < 4.0 && iter < 12 {
                    let next = zx * zx - zy * zy + cx
                    zy = 2.0 * zx * zy + cy
                    zx = next
                    iter += 1
                }
                guard iter < 12 else { continue }
                let alpha = Double(iter) / 12.0 * (0.05 + model.demosceneIntensity * 0.13)
                context.fill(Path(CGRect(x: Double(x) * cellW, y: Double(y) * cellH, width: cellW + 1, height: cellH + 1)), with: .color(blendedColor(preset: preset, t: Double(iter) / 12.0 + time * 0.03).opacity(alpha)))
            }
        }
    }

    private func drawVoxelLandscape(context: inout GraphicsContext, size: CGSize, time: TimeInterval, preset: VisualPreset) {
        let horizon = size.height * 0.44
        for row in 0..<42 {
            let depth = Double(row) / 42.0
            var path = Path()
            for col in 0...72 {
                let xNorm = Double(col) / 72.0 * 2.0 - 1.0
                let terrain = sin(xNorm * 8.0 + time * 1.2 + depth * 4.0) + cos(xNorm * 3.0 - time * 0.8)
                let x = size.width / 2 + xNorm * size.width * (0.35 + depth * 0.48)
                let y = horizon + depth * depth * size.height * 0.72 - terrain * (18.0 + depth * 62.0)
                if col == 0 { path.move(to: CGPoint(x: x, y: y)) } else { path.addLine(to: CGPoint(x: x, y: y)) }
            }
            context.stroke(path, with: .color(blendedColor(preset: preset, t: depth + time * 0.03).opacity(0.055 + depth * model.demosceneIntensity * 0.20)), lineWidth: 1.0 + depth * 2.0)
        }
    }

    private func drawMinterLayer(context: inout GraphicsContext, size: CGSize, time: TimeInterval, preset: VisualPreset, beat: Double) {
        guard model.minterEffectMode != .off || preset.family == .minter else { return }
        switch model.minterEffectMode {
        case .psychedeliaGrid:
            drawPsychedeliaGrid(context: &context, size: size, time: time, preset: preset, beat: beat)
            return
        case .colourspaceFlow:
            drawColourspaceFlow(context: &context, size: size, time: time, preset: preset, beat: beat)
            return
        case .vlmNeon:
            drawVLMNeon(context: &context, size: size, time: time, preset: preset, beat: beat)
            return
        case .tempestWeb:
            drawTempestWeb(context: &context, size: size, time: time, preset: preset, beat: beat)
            return
        case .polybiusTunnel:
            drawPolybiusTunnel(context: &context, size: size, time: time, preset: preset, beat: beat)
            return
        case .gridrunnerLattice:
            drawGridrunnerLattice(context: &context, size: size, time: time, preset: preset, beat: beat)
            return
        case .spaceGiraffeWeb:
            drawTempestWeb(context: &context, size: size, time: time, preset: preset, beat: beat)
            drawPolybiusTunnel(context: &context, size: size, time: time * 1.13, preset: preset, beat: beat)
            return
        case .txkVectorBloom:
            drawTempestWeb(context: &context, size: size, time: time * 1.2, preset: preset, beat: beat)
            drawRecursiveBloom(context: &context, size: size, time: time, preset: preset, intensity: model.minterIntensity)
            return
        case .neonLoopz:
            drawColourspaceFlow(context: &context, size: size, time: time * 0.82, preset: preset, beat: beat)
            drawLissajousLaser(context: &context, size: size, time: time, preset: preset, intensity: model.minterIntensity)
            return
        case .llamaTronTrails:
            drawPsychedeliaGrid(context: &context, size: size, time: time, preset: preset, beat: beat)
            drawGridrunnerLattice(context: &context, size: size, time: time, preset: preset, beat: beat)
            return
        case .off, .neonStampede, .yakLaserGrid, .llamaFeedback, .arcadeVortex:
            break
        }
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let intensity = model.minterIntensity
        let count = 16 + Int(intensity * 20)

        for index in 0..<count {
            let t = Double(index) / Double(max(1, count - 1))
            let y = size.height * t
            let wobble = sin(time * 2.7 + t * 14.0) * 28.0 * intensity
            var horizontal = Path()
            horizontal.move(to: CGPoint(x: 0, y: y + wobble))
            horizontal.addLine(to: CGPoint(x: size.width, y: y - wobble))
            context.stroke(horizontal, with: .color(blendedColor(preset: preset, t: t + beat).opacity(0.12 + intensity * 0.20)), lineWidth: 1 + intensity * 2)

            var vertical = Path()
            let x = size.width * t
            vertical.move(to: CGPoint(x: x - wobble, y: 0))
            vertical.addLine(to: CGPoint(x: x + wobble, y: size.height))
            context.stroke(vertical, with: .color(blendedColor(preset: preset, t: t + 0.33).opacity(0.10 + intensity * 0.18)), lineWidth: 1)
        }

        let orbiters = 14 + Int(intensity * 18)
        for orbiter in 0..<orbiters {
            let phase = Double(orbiter) / Double(orbiters)
            let orbit = min(size.width, size.height) * (0.11 + phase * 0.38)
            let angle = time * (0.8 + phase * 1.4) + phase * Double.pi * 8.0 + beat
            let point = CGPoint(
                x: center.x + cos(angle) * orbit,
                y: center.y + sin(angle * 1.31) * orbit * 0.72
            )
            let diameter = 6.0 + intensity * 18.0 * (1.0 - phase * 0.4)
            context.fill(
                Path(ellipseIn: CGRect(x: point.x - diameter / 2, y: point.y - diameter / 2, width: diameter, height: diameter)),
                with: .color(blendedColor(preset: preset, t: phase + time * 0.04).opacity(0.20 + intensity * 0.38))
            )
        }
    }

    private func drawPsychedeliaGrid(context: inout GraphicsContext, size: CGSize, time: TimeInterval, preset: VisualPreset, beat: Double) {
        let cols = 24
        let rows = 16
        let cellW = size.width / Double(cols)
        let cellH = size.height / Double(rows)
        for y in 0..<rows {
            for x in 0..<cols {
                let dx = Double(x) - Double(cols) * model.macroX
                let dy = Double(y) - Double(rows) * (1.0 - model.macroY)
                let wave = sin(hypot(dx, dy) * 0.9 - time * 4.0 + beat * Double.pi * 2.0)
                guard wave > 0.18 else { continue }
                let inset = (1.0 - wave) * min(cellW, cellH) * 0.36
                let rect = CGRect(x: Double(x) * cellW + inset, y: Double(y) * cellH + inset, width: cellW - inset * 2, height: cellH - inset * 2)
                context.fill(Path(rect), with: .color(blendedColor(preset: preset, t: wave + time * 0.06).opacity(0.10 + model.minterIntensity * 0.32)))
            }
        }
    }

    private func drawColourspaceFlow(context: inout GraphicsContext, size: CGSize, time: TimeInterval, preset: VisualPreset, beat: Double) {
        for band in 0..<32 {
            let t = Double(band) / 32.0
            var path = Path()
            for pointIndex in 0...90 {
                let u = Double(pointIndex) / 90.0
                let x = u * size.width
                let y = size.height * (0.18 + t * 0.64) + sin(u * 10.0 + time * (1.0 + t) + beat * 3.0) * (16.0 + model.macroY * 70.0)
                if pointIndex == 0 { path.move(to: CGPoint(x: x, y: y)) } else { path.addLine(to: CGPoint(x: x, y: y)) }
            }
            context.stroke(path, with: .color(Color.hsba(t + time * 0.035, 0.95, 1.0).opacity(0.08 + model.minterIntensity * 0.17)), lineWidth: 1.0 + model.minterIntensity * 3.0)
        }
    }

    private func drawVLMNeon(context: inout GraphicsContext, size: CGSize, time: TimeInterval, preset: VisualPreset, beat: Double) {
        drawHyperPrism(context: &context, size: size, time: time, preset: preset, intensity: model.minterIntensity, beat: beat)
        drawLissajousLaser(context: &context, size: size, time: time * 0.72, preset: preset, intensity: min(1.0, model.minterIntensity + 0.18))
        drawNeuralMandala(context: &context, size: size, time: time, preset: preset, intensity: model.minterIntensity)
    }

    private func drawTempestWeb(context: inout GraphicsContext, size: CGSize, time: TimeInterval, preset: VisualPreset, beat: Double) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let lanes = 18
        let depth = 18
        for lane in 0..<lanes {
            let angle = Double(lane) / Double(lanes) * Double.pi * 2.0 + time * 0.08
            var spoke = Path()
            spoke.move(to: center)
            spoke.addLine(to: CGPoint(x: center.x + CGFloat(cos(angle)) * size.width, y: center.y + CGFloat(sin(angle)) * size.height))
            context.stroke(spoke, with: .color(blendedColor(preset: preset, t: Double(lane) / Double(lanes) + time * 0.02).opacity(0.10 + model.minterIntensity * 0.16)), lineWidth: 1.0)
            for ring in 1..<depth {
                let r = min(size.width, size.height) * Double(ring) / Double(depth) * (0.08 + beat * 0.04)
                let p = CGPoint(x: center.x + cos(angle) * r, y: center.y + sin(angle) * r)
                context.fill(Path(ellipseIn: CGRect(x: p.x - 3, y: p.y - 3, width: 6, height: 6)), with: .color(blendedColor(preset: preset, t: Double(ring) / Double(depth)).opacity(0.18 + model.minterIntensity * 0.26)))
            }
        }
    }

    private func drawPolybiusTunnel(context: inout GraphicsContext, size: CGSize, time: TimeInterval, preset: VisualPreset, beat: Double) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        for gate in 0..<28 {
            let phase = (Double(gate) / 28.0 + time * (0.12 + model.macroY * 0.22)).truncatingRemainder(dividingBy: 1)
            let scale = pow(phase, 1.9)
            let w = size.width * scale * 1.35
            let h = size.height * scale * 1.05
            let rect = CGRect(x: center.x - w / 2, y: center.y - h / 2, width: w, height: h)
            context.stroke(Path(roundedRect: rect, cornerRadius: 4), with: .color(blendedColor(preset: preset, t: phase + beat).opacity((1.0 - phase) * (0.12 + model.minterIntensity * 0.28))), lineWidth: 1.0 + (1.0 - phase) * 7.0)
        }
    }

    private func drawGridrunnerLattice(context: inout GraphicsContext, size: CGSize, time: TimeInterval, preset: VisualPreset, beat: Double) {
        let spacing = 34.0 - model.minterIntensity * 12.0
        for x in stride(from: -size.height, through: size.width + size.height, by: spacing) {
            var path = Path()
            path.move(to: CGPoint(x: x + sin(time + x * 0.01) * 12.0, y: 0))
            path.addLine(to: CGPoint(x: x + size.height * 0.55, y: size.height))
            context.stroke(path, with: .color(preset.colorA.opacity(0.08 + model.minterIntensity * 0.15)), lineWidth: 1)
        }
        for y in stride(from: 0.0, through: size.height + size.width, by: spacing) {
            var path = Path()
            path.move(to: CGPoint(x: 0, y: y + sin(time * 1.4 + y * 0.01) * 12.0))
            path.addLine(to: CGPoint(x: size.width, y: y - size.width * 0.45))
            context.stroke(path, with: .color(preset.colorB.opacity(0.08 + model.minterIntensity * 0.15)), lineWidth: 1)
        }
    }

    private func drawHolographicLayer(context: inout GraphicsContext, size: CGSize, time: TimeInterval, preset: VisualPreset, beat: Double) {
        guard model.holographicMode != .off || preset.family == .holographic else { return }
        let mode: HolographicMode = model.holographicMode == .off ? .ghostPrism : model.holographicMode
        let depth = model.hologramDepth
        let center = CGPoint(x: size.width / 2, y: size.height / 2)

        let scanLines = mode == .realisticStack ? 72 : 54
        for line in 0..<scanLines {
            let y = size.height * Double(line) / Double(scanLines)
            let wave = sin(time * 6.0 + Double(line) * 0.34) * depth * (mode == .realisticStack ? 12.0 : 8.0)
            var scan = Path()
            scan.move(to: CGPoint(x: 0, y: y + wave))
            scan.addLine(to: CGPoint(x: size.width, y: y - wave))
            context.stroke(scan, with: .color(Color.cyan.opacity(0.018 + depth * 0.050)), lineWidth: 0.8)
        }

        for shell in 0..<10 {
            let phase = (Double(shell) / 10.0 + beat).truncatingRemainder(dividingBy: 1)
            let inset = min(size.width, size.height) * (0.05 + phase * 0.44)
            let rect = CGRect(x: center.x - inset, y: center.y - inset * 0.58, width: inset * 2.0, height: inset * 1.16)
            context.stroke(
                Path(ellipseIn: rect),
                with: .color(Color(red: 0.48, green: 0.95, blue: 1.0).opacity((1.0 - phase) * (0.14 + depth * 0.18))),
                lineWidth: 1 + depth * 3
            )
        }

        if mode == .pepperGhost || mode == .realisticStack {
            drawPepperGhostStage(context: &context, size: size, time: time, preset: preset, beat: beat, depth: depth)
        }

        if mode == .lightField || mode == .realisticStack {
            drawLightFieldVolume(context: &context, size: size, time: time, preset: preset, beat: beat, depth: depth)
        }

        if mode == .cghSpeckle || mode == .realisticStack || mode == .interference {
            drawCGHSpeckle(context: &context, size: size, time: time, preset: preset, depth: depth)
        }

        if mode == .chromaDepth || mode == .interference || mode == .realisticStack {
            for band in 0..<18 {
                let y = size.height * Double(band) / 18.0
                let offset = sin(time * 2.0 + Double(band) * 0.8) * depth * 42.0
                var red = Path()
                red.move(to: CGPoint(x: offset, y: y))
                red.addLine(to: CGPoint(x: size.width + offset, y: y + 22))
                context.stroke(red, with: .color(.pink.opacity(0.08 + depth * 0.10)), lineWidth: 1.5)

                var blue = Path()
                blue.move(to: CGPoint(x: -offset, y: y + 6))
                blue.addLine(to: CGPoint(x: size.width - offset, y: y - 14))
                context.stroke(blue, with: .color(.cyan.opacity(0.08 + depth * 0.10)), lineWidth: 1.5)
            }
        }
    }

    private func drawPepperGhostStage(context: inout GraphicsContext, size: CGSize, time: TimeInterval, preset: VisualPreset, beat: Double, depth: Double) {
        let shortest = min(size.width, size.height)
        let topInset = max(20, size.width * (0.22 - depth * 0.04))
        let bottomInset = max(12, size.width * (0.10 - depth * 0.025))
        let topY = size.height * 0.18
        let bottomY = size.height * 0.84

        var plane = Path()
        plane.move(to: CGPoint(x: topInset, y: topY))
        plane.addLine(to: CGPoint(x: size.width - topInset, y: topY + shortest * 0.035))
        plane.addLine(to: CGPoint(x: size.width - bottomInset, y: bottomY))
        plane.addLine(to: CGPoint(x: bottomInset, y: bottomY - shortest * 0.045))
        plane.closeSubpath()
        context.fill(plane, with: .color(Color(red: 0.10, green: 0.95, blue: 1.0).opacity(0.018 + depth * 0.035)))
        context.stroke(plane, with: .color(Color(red: 0.64, green: 1.0, blue: 0.94).opacity(0.10 + depth * 0.18)), lineWidth: 1.0 + depth * 2.2)

        let center = CGPoint(x: size.width * (0.50 + sin(time * 0.19) * 0.035), y: size.height * (0.55 + cos(time * 0.13) * 0.03))
        let layers = modeSensitiveLayerCount(base: 5, depth: depth)
        for echo in 0..<layers {
            let t = Double(echo) / Double(max(1, layers - 1))
            let lift = shortest * (0.18 + t * 0.12 + beat * 0.04)
            let drift = sin(time * 0.6 + t * 4.7) * shortest * depth * (0.03 + t * 0.02)
            let width = shortest * (0.20 + t * 0.06)
            let height = shortest * (0.38 - t * 0.05)
            let x = center.x + drift + (t - 0.5) * shortest * depth * 0.12
            let y = center.y - lift * 0.35 + t * shortest * 0.05
            let alpha = (1.0 - t * 0.72) * (0.070 + depth * 0.12)

            let body = CGRect(x: x - width / 2, y: y - height / 2, width: width, height: height)
            context.stroke(Path(ellipseIn: body), with: .color(Color(red: 0.35, green: 1.0, blue: 0.88).opacity(alpha)), lineWidth: 0.9 + depth * 2.2)
            context.stroke(Path(ellipseIn: body.insetBy(dx: width * 0.18, dy: height * 0.20)), with: .color(preset.colorC.opacity(alpha * 0.55)), lineWidth: 0.7 + depth * 1.4)

            var spine = Path()
            spine.move(to: CGPoint(x: x, y: body.minY + height * 0.18))
            spine.addCurve(
                to: CGPoint(x: x + sin(time + t * 3.0) * width * 0.16, y: body.maxY - height * 0.16),
                control1: CGPoint(x: x - width * 0.20, y: y - height * 0.10),
                control2: CGPoint(x: x + width * 0.24, y: y + height * 0.20)
            )
            context.stroke(spine, with: .color(Color.white.opacity(alpha * 0.62)), lineWidth: 0.55 + depth)
        }

        let shadow = CGRect(x: center.x - shortest * 0.24, y: size.height * 0.82, width: shortest * 0.48, height: shortest * 0.055)
        context.fill(Path(ellipseIn: shadow), with: .color(Color.black.opacity(0.18 + depth * 0.18)))

        for glint in 0..<10 {
            let t = Double(glint) / 9.0
            let x = bottomInset + (size.width - bottomInset * 2.0) * t
            let y = bottomY - shortest * 0.03 + sin(time * 1.4 + t * 8.0) * shortest * 0.012
            var ray = Path()
            ray.move(to: CGPoint(x: x, y: y))
            ray.addLine(to: CGPoint(x: x + shortest * (0.035 + depth * 0.05), y: y - shortest * (0.08 + depth * 0.04)))
            context.stroke(ray, with: .color(Color.white.opacity(0.035 + depth * 0.085)), lineWidth: 0.7 + depth * 1.2)
        }
    }

    private func drawLightFieldVolume(context: inout GraphicsContext, size: CGSize, time: TimeInterval, preset: VisualPreset, beat: Double, depth: Double) {
        let shortest = min(size.width, size.height)
        let center = CGPoint(x: size.width * (0.50 + sin(time * 0.07) * 0.04), y: size.height * (0.50 + cos(time * 0.09) * 0.04))
        let slices = 22
        for slice in 0..<slices {
            let t = Double(slice) / Double(max(1, slices - 1))
            let z = (t - 0.5) * 2.0
            let parallax = z * shortest * depth * 0.18
            let wobble = sin(time * 0.45 + t * 9.0)
            let w = shortest * (0.18 + t * 0.42)
            let h = shortest * (0.10 + t * 0.22)
            let rect = CGRect(
                x: center.x - w / 2 + parallax * 0.55 + wobble * depth * 18.0,
                y: center.y - h / 2 + parallax * 0.18 + cos(time * 0.37 + t * 6.0) * depth * 16.0,
                width: w,
                height: h
            )
            let alpha = (1.0 - abs(z) * 0.58) * (0.020 + depth * 0.070)
            context.stroke(Path(ellipseIn: rect), with: .color(blendedColor(preset: preset, t: t + time * 0.025).opacity(alpha)), lineWidth: 0.8 + depth * 1.8)

            if slice % 2 == 0 {
                var cross = Path()
                cross.move(to: CGPoint(x: rect.minX, y: rect.midY))
                cross.addLine(to: CGPoint(x: rect.maxX, y: rect.midY + sin(time + t * 7.0) * h * 0.22))
                context.stroke(cross, with: .color(Color.cyan.opacity(alpha * 0.85)), lineWidth: 0.5 + depth)
            }

            for voxel in 0..<7 {
                let seedA = Double((slice * 73 + voxel * 41 + model.sceneSeed * 17) % 997) / 997.0
                let seedB = Double((slice * 29 + voxel * 67 + model.sceneSeed * 23) % 991) / 991.0
                let angle = seedA * .pi * 2.0 + time * (0.18 + seedB * 0.22)
                let radius = seedB * 0.48
                let x = rect.midX + cos(angle) * rect.width * radius
                let y = rect.midY + sin(angle * 1.7) * rect.height * radius
                let d = shortest * (0.0035 + seedA * 0.0045) * (0.7 + depth)
                context.fill(Path(ellipseIn: CGRect(x: x - d / 2, y: y - d / 2, width: d, height: d)), with: .color(Color.white.opacity(alpha * (1.6 + seedB))))
            }
        }

        for ray in 0..<28 {
            let t = Double(ray) / 28.0
            let angle = t * .pi * 2.0 + sin(time * 0.19) * 0.35
            let inner = shortest * (0.08 + beat * 0.08)
            let outer = shortest * (0.32 + depth * 0.28 + 0.05 * sin(time + t * 11.0))
            var path = Path()
            path.move(to: CGPoint(x: center.x + cos(angle) * inner, y: center.y + sin(angle) * inner * 0.58))
            path.addLine(to: CGPoint(x: center.x + cos(angle) * outer, y: center.y + sin(angle) * outer * 0.58))
            context.stroke(path, with: .color(preset.colorB.opacity(0.018 + depth * 0.045)), lineWidth: 0.6 + depth * 1.3)
        }
    }

    private func drawCGHSpeckle(context: inout GraphicsContext, size: CGSize, time: TimeInterval, preset: VisualPreset, depth: Double) {
        let grains = 150 + Int(depth * 180)
        for grain in 0..<grains {
            let sx = Double((grain * 37 + model.sceneSeed * 11) % 997) / 997.0
            let sy = Double((grain * 61 + model.sceneSeed * 19) % 991) / 991.0
            let x = sx * size.width
            let y = sy * size.height
            let carrier = sin(x * 0.018 + y * 0.013 + time * 1.6 + Double(grain % 17))
            let shimmer = 0.5 + 0.5 * sin(time * (0.68 + Double(grain % 13) * 0.033) + Double(grain) * 1.913)
            let alpha = (0.010 + carrier * carrier * 0.034 + shimmer * 0.026) * depth
            let diameter = 0.75 + sx * (1.7 + depth * 1.6)
            let color = grain % 5 == 0 ? blendedColor(preset: preset, t: sx + time * 0.01) : Color(red: 0.78, green: 1.0, blue: 0.96)
            context.fill(Path(ellipseIn: CGRect(x: x - diameter / 2, y: y - diameter / 2, width: diameter, height: diameter)), with: .color(color.opacity(alpha)))
        }

        let rows = 18
        for row in 0..<rows {
            let t = Double(row) / Double(rows)
            var fringe = Path()
            fringe.move(to: CGPoint(x: 0, y: size.height * t))
            let step = max(10.0, size.width / 96.0)
            for x in stride(from: 0.0, through: size.width, by: step) {
                let phase = x * 0.018 + t * 19.0 + time * (0.55 + depth)
                let y = size.height * t + sin(phase) * (8.0 + depth * 28.0) + cos(phase * 0.43) * depth * 18.0
                fringe.addLine(to: CGPoint(x: x, y: y))
            }
            context.stroke(fringe, with: .color(Color(red: 0.55, green: 1.0, blue: 0.92).opacity(0.018 + depth * 0.052)), lineWidth: 0.55 + depth * 1.15)
        }
    }

    private func modeSensitiveLayerCount(base: Int, depth: Double) -> Int {
        max(base, base + Int(depth * 4.0))
    }

    private func drawExperimentalVideoMode(context: inout GraphicsContext, size: CGSize, time: TimeInterval, preset: VisualPreset, beat: Double) {
        let intensity = model.flashSafety ? min(model.experimentalVideoIntensity, 0.82) : model.experimentalVideoIntensity
        guard model.experimentalVideoMode != .clean, intensity > 0.01 else { return }

        switch model.experimentalVideoMode {
        case .clean:
            return
        case .colourspace:
            for band in 0..<48 {
                let t = Double(band) / 48.0
                let rect = CGRect(x: 0, y: size.height * t, width: size.width, height: size.height / 36.0)
                context.fill(Path(rect), with: .color(Color.hsba(t + time * 0.06 + beat * 0.08, 0.95, 1.0).opacity(0.025 + intensity * 0.055)))
            }
        case .neonPulse:
            let center = CGPoint(x: size.width * model.macroX, y: size.height * (1.0 - model.macroY))
            for ring in 0..<18 {
                let phase = (Double(ring) / 18.0 + beat).truncatingRemainder(dividingBy: 1)
                let radius = min(size.width, size.height) * (0.04 + phase * 0.64)
                context.stroke(Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)), with: .color(Color.hsba(phase + time * 0.08, 1.0, 1.0).opacity((1.0 - phase) * intensity * 0.18)), lineWidth: 1.0 + intensity * 5.0)
            }
        case .slitScan:
            for strip in stride(from: 0.0, to: size.width, by: 18.0) {
                let offset = sin(strip * 0.025 + time * 2.6) * 22.0 * intensity
                let rect = CGRect(x: strip + offset, y: 0, width: 10, height: size.height)
                context.fill(Path(rect), with: .color(blendedColor(preset: preset, t: strip / max(1, size.width) + time * 0.03).opacity(0.025 + intensity * 0.045)))
            }
        case .videoFeedback:
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            for echo in 1...10 {
                let phase = Double(echo) / 10.0
                let inset = min(size.width, size.height) * phase * 0.035 * intensity
                let rect = CGRect(x: inset, y: inset, width: size.width - inset * 2, height: size.height - inset * 2)
                context.stroke(Path(roundedRect: rect, cornerRadius: 0), with: .color(blendedColor(preset: preset, t: phase + time * 0.04).opacity((1.0 - phase) * intensity * 0.10)), lineWidth: 2)
                context.stroke(Path(ellipseIn: CGRect(x: center.x - inset * 2, y: center.y - inset, width: inset * 4, height: inset * 2)), with: .color(preset.colorC.opacity((1.0 - phase) * intensity * 0.08)), lineWidth: 1)
            }
        case .chromaticAberration:
            for line in stride(from: 0.0, to: size.height, by: 9.0) {
                let shift = sin(line * 0.05 + time * 4.0) * 28.0 * intensity
                var red = Path()
                red.move(to: CGPoint(x: shift, y: line))
                red.addLine(to: CGPoint(x: size.width + shift, y: line))
                context.stroke(red, with: .color(.pink.opacity(0.045 + intensity * 0.07)), lineWidth: 2)
                var blue = Path()
                blue.move(to: CGPoint(x: -shift, y: line + 3))
                blue.addLine(to: CGPoint(x: size.width - shift, y: line + 3))
                context.stroke(blue, with: .color(.cyan.opacity(0.045 + intensity * 0.07)), lineWidth: 2)
            }
        case .datamoshBlocks:
            let block = 32.0
            let cols = Int(size.width / block) + 1
            let rows = Int(size.height / block) + 1
            let frame = Int(time * 12.0)
            for y in 0..<rows {
                for x in 0..<cols where (((x * 19) ^ (y * 41) ^ frame) & 15) == 0 {
                    let rect = CGRect(x: Double(x) * block + sin(time + Double(y)) * 18.0 * intensity, y: Double(y) * block, width: block * 1.6, height: block)
                    context.fill(Path(rect), with: .color(blendedColor(preset: preset, t: Double(x + y) * 0.05 + time * 0.04).opacity(0.05 + intensity * 0.13)))
                }
            }
        case .vhsMelt:
            for row in stride(from: 0.0, to: size.height, by: 4.0) {
                let wave = sin(row * 0.035 + time * 3.7) + sin(row * 0.011 - time * 1.8)
                var path = Path()
                path.move(to: CGPoint(x: wave * 18.0 * intensity, y: row))
                path.addLine(to: CGPoint(x: size.width + wave * 18.0 * intensity, y: row))
                context.stroke(path, with: .color(.white.opacity(0.012 + intensity * 0.025)), lineWidth: 1)
            }
        case .demosceneStack:
            drawDemoMoireTunnel(context: &context, size: size, time: time, preset: preset)
            drawRasterInterference(context: &context, size: size, time: time, preset: preset)
            drawBitplaneStorm(context: &context, size: size, time: time, preset: preset)
        case .lumaKeyBloom:
            drawLumaKeyBloom(context: &context, size: size, time: time, preset: preset, beat: beat, intensity: intensity)
        case .chromaInvert:
            drawChromaInvert(context: &context, size: size, time: time, preset: preset, intensity: intensity)
        case .edgeTrace:
            drawEdgeTrace(context: &context, size: size, time: time, preset: preset, beat: beat, intensity: intensity)
        case .oscillatorBank:
            drawVideoOscillatorBank(context: &context, size: size, time: time, preset: preset, beat: beat, intensity: intensity)
        case .vectorScope:
            drawVectorScope(context: &context, size: size, time: time, preset: preset, beat: beat, intensity: intensity)
        case .scanGate:
            drawScanGate(context: &context, size: size, time: time, preset: preset, beat: beat, intensity: intensity)
        case .pixelSortTrails:
            drawPixelSortTrails(context: &context, size: size, time: time, preset: preset, beat: beat, intensity: intensity)
        case .codecTear:
            drawCodecTear(context: &context, size: size, time: time, preset: preset, intensity: intensity)
        case .rgbDelay:
            drawRGBDelay(context: &context, size: size, time: time, preset: preset, beat: beat, intensity: intensity)
        case .halftonePosterize:
            drawHalftonePosterize(context: &context, size: size, time: time, preset: preset, beat: beat, intensity: intensity)
        case .opticalFlowSmear:
            drawOpticalFlowSmear(context: &context, size: size, time: time, preset: preset, beat: beat, intensity: intensity)
        case .recursiveMirror:
            drawRecursiveMirror(context: &context, size: size, time: time, preset: preset, beat: beat, intensity: intensity)
        case .liquidLens:
            drawLiquidLens(context: &context, size: size, time: time, preset: preset, beat: beat, intensity: intensity)
        case .kaleidoFeedback:
            drawKaleidoFeedback(context: &context, size: size, time: time, preset: preset, beat: beat, intensity: intensity)
        case .solarizedContours:
            drawSolarizedContours(context: &context, size: size, time: time, preset: preset, beat: beat, intensity: intensity)
        case .phosphorBurn:
            drawPhosphorBurn(context: &context, size: size, time: time, preset: preset, intensity: intensity)
        case .tunnelFold:
            drawTunnelFold(context: &context, size: size, time: time, preset: preset, beat: beat, intensity: intensity)
        case .chromaLightLeaks:
            drawChromaLightLeaks(context: &context, size: size, time: time, preset: preset, beat: beat, intensity: intensity)
        }
    }

    private func drawLumaKeyBloom(context: inout GraphicsContext, size: CGSize, time: TimeInterval, preset: VisualPreset, beat: Double, intensity: Double) {
        let threshold = model.videoKeyThreshold
        let cells = 18 + Int(model.videoEdgeGain * 18)
        let cellW = size.width / Double(cells)
        let cellH = size.height / Double(cells)
        for y in 0..<cells {
            for x in 0..<cells {
                let nx = Double(x) / Double(cells) - 0.5
                let ny = Double(y) / Double(cells) - 0.5
                let radial = 1.0 - min(1.0, hypot(nx, ny) * 1.65)
                let signal = 0.5
                    + 0.28 * sin(nx * 14.0 + time * (1.2 + model.videoOscillatorRate * 4.0))
                    + 0.22 * cos(ny * 12.0 - time * 1.7)
                    + 0.18 * sin((nx + ny) * 18.0 + beat * Double.pi * 2.0)
                    + radial * 0.32
                guard signal > threshold else { continue }
                let key = min(1.0, (signal - threshold) / max(0.08, 1.0 - threshold))
                let inset = (1.0 - key) * min(cellW, cellH) * 0.42
                let rect = CGRect(x: Double(x) * cellW + inset, y: Double(y) * cellH + inset, width: cellW - inset * 2, height: cellH - inset * 2)
                context.fill(Path(roundedRect: rect, cornerRadius: 2), with: .color(blendedColor(preset: preset, t: signal + time * 0.04).opacity(key * intensity * 0.24)))
            }
        }
    }

    private func drawChromaInvert(context: inout GraphicsContext, size: CGSize, time: TimeInterval, preset: VisualPreset, intensity: Double) {
        let bands = 14 + Int(model.videoColorWarp * 26)
        for band in 0..<bands {
            let t = Double(band) / Double(max(1, bands - 1))
            let y = size.height * t
            let height = size.height / Double(bands) * (1.2 + model.videoEdgeGain)
            let hue = 1.0 - (t + time * (0.025 + model.videoOscillatorRate * 0.07)).truncatingRemainder(dividingBy: 1)
            let offset = sin(time * 1.8 + t * 19.0) * size.width * 0.05 * model.videoColorWarp
            let rect = CGRect(x: offset, y: y - height * 0.5, width: size.width, height: height)
            context.fill(Path(rect), with: .color(Color.hsba(hue, 0.95, 1.0).opacity((0.035 + intensity * 0.10) * model.videoColorWarp)))
        }
        for column in stride(from: 0.0, to: size.width, by: 23.0) {
            let x = column + sin(column * 0.04 + time * 2.1) * 18.0 * model.videoColorWarp
            context.fill(Path(CGRect(x: x, y: 0, width: 2.0 + model.videoEdgeGain * 5.0, height: size.height)), with: .color(preset.colorC.opacity(0.025 + intensity * 0.065)))
        }
    }

    private func drawEdgeTrace(context: inout GraphicsContext, size: CGSize, time: TimeInterval, preset: VisualPreset, beat: Double, intensity: Double) {
        let contours = 16 + Int(model.videoEdgeGain * 32)
        let center = CGPoint(x: size.width * model.macroX, y: size.height * (1.0 - model.macroY))
        for contour in 0..<contours {
            let t = Double(contour) / Double(contours)
            let radius = min(size.width, size.height) * (0.06 + t * 0.62)
            var path = Path()
            let points = 110
            for point in 0...points {
                let u = Double(point) / Double(points) * Double.pi * 2.0
                let edge = sin(u * (3.0 + model.videoColorWarp * 9.0) + time * (1.0 + model.videoOscillatorRate * 3.0) + t * 11.0)
                let r = radius * (0.82 + edge * 0.12 + sin(beat * Double.pi * 2.0 + t * 6.0) * 0.045)
                let p = CGPoint(x: center.x + cos(u) * r, y: center.y + sin(u) * r * (0.62 + model.videoKeyThreshold * 0.45))
                if point == 0 { path.move(to: p) } else { path.addLine(to: p) }
            }
            context.stroke(path, with: .color(blendedColor(preset: preset, t: t + time * 0.03).opacity((1.0 - t) * intensity * (0.10 + model.videoEdgeGain * 0.18))), lineWidth: 0.8 + model.videoEdgeGain * 4.5)
        }
    }

    private func drawVideoOscillatorBank(context: inout GraphicsContext, size: CGSize, time: TimeInterval, preset: VisualPreset, beat: Double, intensity: Double) {
        let oscillators = 5 + Int(model.videoColorWarp * 7)
        for oscillator in 0..<oscillators {
            let t = Double(oscillator) / Double(oscillators)
            let frequency = 1.0 + Double(oscillator) * (1.4 + model.videoKeyThreshold * 4.0)
            var path = Path()
            for point in 0...220 {
                let u = Double(point) / 220.0
                let x = u * size.width
                let carrier = sin(u * Double.pi * 2.0 * frequency + time * (0.7 + model.videoOscillatorRate * 5.0))
                let modulator = cos(u * Double.pi * (frequency * 0.37 + 1.0) - time * (1.1 + t))
                let y = size.height * (0.18 + t * 0.64) + (carrier + modulator * 0.45 + sin(beat * Double.pi * 2.0) * 0.25) * size.height * (0.035 + model.videoEdgeGain * 0.055)
                if point == 0 { path.move(to: CGPoint(x: x, y: y)) } else { path.addLine(to: CGPoint(x: x, y: y)) }
            }
            context.stroke(path, with: .color(blendedColor(preset: preset, t: t + time * 0.05).opacity(0.10 + intensity * 0.24)), lineWidth: 1.0 + model.videoEdgeGain * 3.2)
        }
    }

    private func drawVectorScope(context: inout GraphicsContext, size: CGSize, time: TimeInterval, preset: VisualPreset, beat: Double, intensity: Double) {
        let center = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
        let radius = min(size.width, size.height) * (0.18 + model.videoColorWarp * 0.28)
        for trace in 0..<6 {
            let tracePhase = Double(trace) / 6.0
            var path = Path()
            for point in 0...360 {
                let u = Double(point) / 360.0 * Double.pi * 2.0
                let luma = 0.62 + sin(u * (2.0 + tracePhase * 4.0) + time * 1.2 + beat * Double.pi * 2.0) * 0.28
                guard luma > model.videoKeyThreshold * 0.72 else { continue }
                let chroma = 0.62 + cos(u * (3.0 + model.videoOscillatorRate * 4.0) - time * 1.6 + tracePhase) * 0.28
                let p = CGPoint(
                    x: center.x + cos(u + chroma * model.videoColorWarp) * radius * luma,
                    y: center.y + sin(u * (1.0 + model.videoEdgeGain * 0.28)) * radius * chroma
                )
                if point == 0 { path.move(to: p) } else { path.addLine(to: p) }
            }
            context.stroke(path, with: .color(Color.hsba(tracePhase + time * 0.035, 0.9, 1.0).opacity(0.09 + intensity * 0.21)), lineWidth: 1.0 + model.videoEdgeGain * 2.5)
        }
        context.stroke(Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)), with: .color(.white.opacity(0.05 + intensity * 0.08)), lineWidth: 1)
    }

    private func drawScanGate(context: inout GraphicsContext, size: CGSize, time: TimeInterval, preset: VisualPreset, beat: Double, intensity: Double) {
        let spacing = 4.0 + (1.0 - model.videoEdgeGain) * 12.0
        let gateWidth = 0.12 + (1.0 - model.videoKeyThreshold) * 0.42
        for row in stride(from: 0.0, to: size.height, by: spacing) {
            let phase = (row / max(1, size.height) + time * (0.06 + model.videoOscillatorRate * 0.20) + beat * 0.05).truncatingRemainder(dividingBy: 1)
            guard phase < gateWidth else { continue }
            let offset = sin(row * 0.025 + time * 2.4) * 36.0 * model.videoColorWarp
            var path = Path()
            path.move(to: CGPoint(x: offset, y: row))
            path.addLine(to: CGPoint(x: size.width + offset, y: row + sin(time + row * 0.03) * 6.0))
            context.stroke(path, with: .color(blendedColor(preset: preset, t: phase + time * 0.04).opacity(0.045 + intensity * 0.11)), lineWidth: 1.0 + model.videoEdgeGain * 2.8)
        }
    }

    private func drawPixelSortTrails(context: inout GraphicsContext, size: CGSize, time: TimeInterval, preset: VisualPreset, beat: Double, intensity: Double) {
        let rows = 18 + Int(model.videoEdgeGain * 28)
        let laneHeight = size.height / Double(rows)
        let threshold = model.videoKeyThreshold
        for row in 0..<rows {
            let y = Double(row) * laneHeight
            let rowPhase = Double(row) / Double(rows)
            let signal = 0.5 + 0.35 * sin(rowPhase * 15.0 + time * (0.8 + model.videoOscillatorRate * 3.8)) + 0.20 * cos(beat * Double.pi * 2.0 + rowPhase * 9.0)
            guard signal > threshold * 0.82 else { continue }
            let segments = 5 + Int(model.videoColorWarp * 10)
            for segment in 0..<segments {
                let s = Double(segment) / Double(segments)
                let sortLength = size.width * (0.08 + pow(signal, 2.0) * (0.18 + model.videoColorWarp * 0.36))
                let drift = sin(time * (1.2 + s) + rowPhase * 18.0) * size.width * 0.08 * intensity
                let x = (s * size.width + drift + Double(row * 31).truncatingRemainder(dividingBy: max(1.0, size.width))).truncatingRemainder(dividingBy: max(1.0, size.width))
                let rect = CGRect(x: x - sortLength * 0.5, y: y, width: sortLength, height: max(2.0, laneHeight * 0.72))
                context.fill(Path(rect), with: .color(blendedColor(preset: preset, t: signal + s + time * 0.035).opacity(0.035 + intensity * 0.13)))
            }
        }
    }

    private func drawCodecTear(context: inout GraphicsContext, size: CGSize, time: TimeInterval, preset: VisualPreset, intensity: Double) {
        let block = 26.0 + (1.0 - model.videoEdgeGain) * 30.0
        let rows = Int(size.height / block) + 1
        let frame = Int(time * (8.0 + model.videoOscillatorRate * 22.0))
        for row in 0..<rows {
            let y = Double(row) * block
            let hit = (((row * 73) ^ frame) & 7) < 3
            let offset = hit ? sin(time * 2.0 + Double(row) * 1.7) * size.width * (0.03 + model.videoColorWarp * 0.16) : 0
            let alpha = hit ? 0.055 + intensity * 0.16 : 0.012 + intensity * 0.025
            let rect = CGRect(x: offset, y: y, width: size.width * (1.0 + model.videoColorWarp * 0.28), height: block * (0.55 + model.videoEdgeGain * 0.65))
            context.fill(Path(rect), with: .color(blendedColor(preset: preset, t: Double(row) * 0.07 + time * 0.04).opacity(alpha)))
        }

        let macro = max(18.0, block * 0.72)
        let cols = Int(size.width / macro) + 1
        for row in stride(from: 0, to: rows, by: 2) {
            for col in 0..<cols where (((col * 29) &+ (row * 47) &+ frame) % 17) < 3 {
                let x = Double(col) * macro + sin(Double(row) + time) * macro * 0.6
                let y = Double(row) * block
                let w = macro * (1.0 + model.videoColorWarp * 3.0)
                context.fill(Path(CGRect(x: x, y: y, width: w, height: macro * 0.92)), with: .color(blendedColor(preset: preset, t: Double(col + row) * 0.05).opacity(0.07 + intensity * 0.15)))
            }
        }
    }

    private func drawRGBDelay(context: inout GraphicsContext, size: CGSize, time: TimeInterval, preset: VisualPreset, beat: Double, intensity: Double) {
        let center = CGPoint(x: size.width * model.macroX, y: size.height * (1.0 - model.macroY))
        let channels: [(Color, Double, Double)] = [(.red, 0.00, 1.0), (.green, 0.33, -0.7), (.cyan, 0.66, 0.55)]
        for (color, phase, direction) in channels {
            for ring in 0..<16 {
                let t = Double(ring) / 16.0
                let delay = phase + t * 0.05
                let radius = min(size.width, size.height) * (0.05 + t * 0.58 + 0.035 * sin(beat * Double.pi * 2.0 + delay * 5.0))
                let dx = sin(time * (0.7 + model.videoOscillatorRate * 2.4) + delay * 9.0) * 32.0 * model.videoColorWarp * direction
                let dy = cos(time * (0.6 + model.videoOscillatorRate * 2.0) + delay * 7.0) * 24.0 * model.videoColorWarp * direction
                let rect = CGRect(x: center.x + dx - radius, y: center.y + dy - radius, width: radius * 2, height: radius * 2)
                context.stroke(Path(ellipseIn: rect), with: .color(color.opacity((1.0 - t) * (0.035 + intensity * 0.13))), lineWidth: 1.0 + model.videoEdgeGain * 3.0)
            }
        }
    }

    private func drawHalftonePosterize(context: inout GraphicsContext, size: CGSize, time: TimeInterval, preset: VisualPreset, beat: Double, intensity: Double) {
        let cols = 24 + Int(model.videoEdgeGain * 30)
        let rows = max(12, Int(Double(cols) * size.height / max(1.0, size.width)))
        let cellW = size.width / Double(cols)
        let cellH = size.height / Double(rows)
        for y in 0..<rows {
            for x in 0..<cols {
                let nx = Double(x) / Double(cols) - 0.5
                let ny = Double(y) / Double(rows) - 0.5
                let luma = 0.5 + 0.28 * sin(nx * 18.0 + time * (0.9 + model.videoOscillatorRate * 2.8)) + 0.24 * cos(ny * 16.0 - time * 1.4) + 0.16 * sin((nx - ny) * 24.0 + beat * Double.pi * 2.0)
                let quantized = floor(max(0.0, min(1.0, luma)) * 4.0) / 4.0
                guard quantized > model.videoKeyThreshold * 0.52 else { continue }
                let radius = min(cellW, cellH) * (0.12 + quantized * 0.42 * intensity)
                let cx = Double(x) * cellW + cellW * 0.5
                let cy = Double(y) * cellH + cellH * 0.5
                context.fill(Path(ellipseIn: CGRect(x: cx - radius, y: cy - radius, width: radius * 2, height: radius * 2)), with: .color(blendedColor(preset: preset, t: quantized + Double(x + y) * 0.012 + time * 0.025).opacity(0.05 + intensity * 0.16)))
            }
        }
    }

    private func drawOpticalFlowSmear(context: inout GraphicsContext, size: CGSize, time: TimeInterval, preset: VisualPreset, beat: Double, intensity: Double) {
        let center = CGPoint(x: size.width * model.macroX, y: size.height * (1.0 - model.macroY))
        let streaks = 54 + Int(model.videoEdgeGain * 76)
        for streak in 0..<streaks {
            let t = Double(streak) / Double(streaks)
            let angle = t * Double.pi * 2.0 * (2.0 + model.videoColorWarp * 3.0) + sin(time * 0.32 + t * 8.0)
            let distance = min(size.width, size.height) * (0.10 + t * 0.68)
            let vector = CGPoint(x: cos(angle), y: sin(angle))
            let origin = CGPoint(x: center.x + vector.x * distance * (0.35 + 0.65 * sin(t * 11.0 + time)), y: center.y + vector.y * distance)
            let flow = 22.0 + 120.0 * intensity * (0.25 + model.videoColorWarp) * (0.4 + 0.6 * abs(sin(beat * Double.pi * 2.0 + t * 6.0)))
            var path = Path()
            path.move(to: CGPoint(x: origin.x - vector.x * flow * 0.25, y: origin.y - vector.y * flow * 0.25))
            path.addLine(to: CGPoint(x: origin.x + vector.x * flow, y: origin.y + vector.y * flow))
            context.stroke(path, with: .color(blendedColor(preset: preset, t: t + time * 0.04).opacity(0.045 + intensity * 0.15)), lineWidth: 0.8 + model.videoEdgeGain * 3.4)
        }
    }

    private func drawRecursiveMirror(context: inout GraphicsContext, size: CGSize, time: TimeInterval, preset: VisualPreset, beat: Double, intensity: Double) {
        let copies = 8 + Int(model.videoEdgeGain * 12)
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        for copy in 0..<copies {
            let t = Double(copy) / Double(max(1, copies - 1))
            let inset = min(size.width, size.height) * t * (0.018 + intensity * 0.045)
            let wobble = sin(time * (0.8 + model.videoOscillatorRate * 2.0) + t * 9.0) * 12.0 * model.videoColorWarp
            let rect = CGRect(x: inset + wobble, y: inset - wobble, width: size.width - inset * 2, height: size.height - inset * 2)
            let path = Path(roundedRect: rect, cornerRadius: max(0, 12.0 * (1.0 - t)))
            context.stroke(path, with: .color(blendedColor(preset: preset, t: t + time * 0.025).opacity((1.0 - t) * (0.055 + intensity * 0.18))), lineWidth: 1.0 + model.videoEdgeGain * 3.0)
            if copy % 2 == 0 {
                context.stroke(Path(ellipseIn: CGRect(x: center.x - rect.width * 0.25, y: center.y - rect.height * 0.18, width: rect.width * 0.5, height: rect.height * 0.36)), with: .color(preset.colorC.opacity((1.0 - t) * intensity * 0.08)), lineWidth: 1)
            }
        }
    }

    private func drawLiquidLens(context: inout GraphicsContext, size: CGSize, time: TimeInterval, preset: VisualPreset, beat: Double, intensity: Double) {
        let cols = 18 + Int(model.videoEdgeGain * 30)
        let rows = max(10, Int(Double(cols) * size.height / max(1.0, size.width)))
        let cellW = size.width / Double(cols)
        let cellH = size.height / Double(rows)
        for y in 0..<rows {
            for x in 0..<cols {
                let nx = Double(x) / Double(cols) - 0.5
                let ny = Double(y) / Double(rows) - 0.5
                let ripple = sin((nx * nx + ny * ny) * 42.0 - time * (2.0 + model.videoOscillatorRate * 5.0))
                    + sin(nx * 18.0 + time * 1.2)
                    + cos(ny * 16.0 - beat * Double.pi * 2.0)
                let radius = min(cellW, cellH) * (0.16 + abs(ripple) * 0.24 * intensity)
                let warpX = sin(ny * 11.0 + time) * cellW * model.videoColorWarp
                let warpY = cos(nx * 10.0 - time * 0.8) * cellH * model.videoColorWarp
                let rect = CGRect(x: Double(x) * cellW + cellW * 0.5 + warpX - radius, y: Double(y) * cellH + cellH * 0.5 + warpY - radius, width: radius * 2, height: radius * 2)
                context.fill(Path(ellipseIn: rect), with: .color(blendedColor(preset: preset, t: ripple * 0.18 + time * 0.025).opacity(0.035 + intensity * 0.12)))
            }
        }
    }

    private func drawKaleidoFeedback(context: inout GraphicsContext, size: CGSize, time: TimeInterval, preset: VisualPreset, beat: Double, intensity: Double) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let copies = 10 + Int(model.videoEdgeGain * 18)
        let symmetry = max(3, preset.symmetry + Int(model.videoColorWarp * 8))
        for copy in 0..<copies {
            let phase = Double(copy) / Double(copies)
            let radius = min(size.width, size.height) * (0.06 + phase * 0.52)
            for spoke in 0..<symmetry {
                let angle = Double(spoke) / Double(symmetry) * Double.pi * 2.0 + time * (0.05 + model.videoOscillatorRate * 0.22) + phase * 2.0
                let fold = abs(sin(angle * 2.0 + beat * Double.pi * 2.0))
                let p1 = CGPoint(x: center.x + cos(angle) * radius * fold, y: center.y + sin(angle) * radius)
                let p2 = CGPoint(x: center.x + cos(angle + 0.28 + phase) * radius * (1.0 + intensity * 0.25), y: center.y + sin(angle + 0.28 + phase) * radius)
                var path = Path()
                path.move(to: center)
                path.addLine(to: p1)
                path.addLine(to: p2)
                context.stroke(path, with: .color(blendedColor(preset: preset, t: phase + Double(spoke) * 0.03 + time * 0.04).opacity((1.0 - phase) * (0.035 + intensity * 0.11))), lineWidth: 0.8 + model.videoEdgeGain * 2.8)
            }
        }
    }

    private func drawSolarizedContours(context: inout GraphicsContext, size: CGSize, time: TimeInterval, preset: VisualPreset, beat: Double, intensity: Double) {
        let contours = 22 + Int(model.videoEdgeGain * 42)
        let center = CGPoint(x: size.width * model.macroX, y: size.height * (1.0 - model.macroY))
        for contour in 0..<contours {
            let t = Double(contour) / Double(contours)
            let points = 140
            var path = Path()
            for point in 0...points {
                let u = Double(point) / Double(points) * Double.pi * 2.0
                let luma = 0.5 + 0.5 * sin(u * (2.0 + model.videoColorWarp * 8.0) + t * 11.0 + time * (0.7 + model.videoOscillatorRate * 3.0))
                let quantized = floor(luma * 5.0) / 5.0
                let radius = min(size.width, size.height) * (0.08 + t * 0.62) * (0.82 + quantized * 0.18)
                let p = CGPoint(x: center.x + cos(u) * radius, y: center.y + sin(u) * radius * (0.62 + beat * 0.10))
                if point == 0 { path.move(to: p) } else { path.addLine(to: p) }
            }
            let hue = (1.0 - t + time * 0.03).truncatingRemainder(dividingBy: 1)
            context.stroke(path, with: .color(Color.hsba(hue, 0.95, 1.0).opacity((0.04 + intensity * 0.12) * (1.0 - t * 0.45))), lineWidth: 0.9 + model.videoEdgeGain * 3.0)
        }
    }

    private func drawPhosphorBurn(context: inout GraphicsContext, size: CGSize, time: TimeInterval, preset: VisualPreset, intensity: Double) {
        let bands = 26 + Int(model.videoEdgeGain * 42)
        for band in 0..<bands {
            let t = Double(band) / Double(bands)
            let y = size.height * t
            let drift = sin(time * (0.6 + model.videoOscillatorRate * 2.0) + t * 18.0) * size.width * 0.04 * model.videoColorWarp
            let alpha = (0.025 + intensity * 0.10) * pow(1.0 - t * 0.35, 1.8)
            let rect = CGRect(x: drift, y: y, width: size.width, height: max(2.0, size.height / Double(bands) * 0.72))
            context.fill(Path(rect), with: .color(Color.green.opacity(alpha)))
            context.fill(Path(CGRect(x: -drift * 0.5, y: y + 2, width: size.width, height: 1.2)), with: .color(preset.colorC.opacity(alpha * 0.65)))
        }
    }

    private func drawTunnelFold(context: inout GraphicsContext, size: CGSize, time: TimeInterval, preset: VisualPreset, beat: Double, intensity: Double) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let rings = 18 + Int(model.videoEdgeGain * 28)
        let sides = 5 + Int(model.videoColorWarp * 8)
        for ring in 0..<rings {
            let t = Double(ring) / Double(rings)
            let radius = min(size.width, size.height) * (0.04 + t * 0.68)
            var path = Path()
            for side in 0...sides {
                let u = Double(side) / Double(sides) * Double.pi * 2.0
                let fold = abs(sin(u * 2.0 + time * (0.6 + model.videoOscillatorRate * 2.2) + t * 5.0))
                let r = radius * (0.72 + fold * 0.34 + sin(beat * Double.pi * 2.0 + t * 7.0) * 0.05)
                let p = CGPoint(x: center.x + cos(u + t * 1.5) * r, y: center.y + sin(u + t * 1.5) * r)
                if side == 0 { path.move(to: p) } else { path.addLine(to: p) }
            }
            context.stroke(path, with: .color(blendedColor(preset: preset, t: t + time * 0.035).opacity((1.0 - t) * (0.045 + intensity * 0.15))), lineWidth: 1.0 + model.videoEdgeGain * 3.5)
        }
    }

    private func drawChromaLightLeaks(context: inout GraphicsContext, size: CGSize, time: TimeInterval, preset: VisualPreset, beat: Double, intensity: Double) {
        let leaks = 9 + Int(model.videoColorWarp * 12)
        for leak in 0..<leaks {
            let t = Double(leak) / Double(max(1, leaks - 1))
            let x = size.width * ((sin(time * 0.11 + t * 8.0) * 0.5 + 0.5))
            let y = size.height * ((cos(time * 0.09 + t * 6.0 + beat) * 0.5 + 0.5))
            let radius = min(size.width, size.height) * (0.10 + 0.24 * abs(sin(time * 0.3 + t * 5.0)))
            let rect = CGRect(x: x - radius, y: y - radius, width: radius * 2.4, height: radius * 1.5)
            context.fill(Path(ellipseIn: rect), with: .color(Color.hsba(t + time * 0.04, 0.92, 1.0).opacity(0.035 + intensity * 0.14)))
            context.fill(Path(CGRect(x: x - radius * 1.8, y: y - 2, width: radius * 3.6, height: 4 + model.videoEdgeGain * 10)), with: .color(preset.colorC.opacity(0.025 + intensity * 0.08)))
        }
    }

    private func drawFeedbackSimulatorLayer(context: inout GraphicsContext, size: CGSize, time: TimeInterval, preset: VisualPreset, beat: Double) {
        guard model.feedbackSimulatorMode != .off, model.feedbackSimulatorIntensity > 0.01 else { return }
        let capped = model.flashSafety ? min(model.feedbackSimulatorIntensity, 0.84) : model.feedbackSimulatorIntensity
        let music = musicEnergy(at: time)
        let analyzer = (model.audioMeter.bass + model.audioMeter.mid + model.audioMeter.treble + model.audioMeter.spectralFlux) * 0.25
        let energy = model.feedbackSimulatorAudioReactive ? min(1.0, max(music, analyzer)) : 0.42

        switch model.feedbackSimulatorMode {
        case .off:
            return
        case .opticalTunnel:
            drawFeedbackOpticalTunnel(context: &context, size: size, time: time, preset: preset, beat: beat, intensity: capped, energy: energy)
        case .prismHall:
            drawFeedbackPrismHall(context: &context, size: size, time: time, preset: preset, intensity: capped, energy: energy)
        case .lumaBloomMemory:
            drawFeedbackLumaBloomMemory(context: &context, size: size, time: time, preset: preset, beat: beat, intensity: capped, energy: energy)
        case .chromaWarpField:
            drawFeedbackChromaWarpField(context: &context, size: size, time: time, preset: preset, intensity: capped, energy: energy)
        case .scanlineMemory:
            drawFeedbackScanlineMemory(context: &context, size: size, time: time, preset: preset, intensity: capped, energy: energy)
        case .mirrorLabyrinth:
            drawFeedbackMirrorLabyrinth(context: &context, size: size, time: time, preset: preset, beat: beat, intensity: capped, energy: energy)
        case .feedbackLab:
            drawFeedbackOpticalTunnel(context: &context, size: size, time: time, preset: preset, beat: beat, intensity: capped * 0.72, energy: energy)
            drawFeedbackPrismHall(context: &context, size: size, time: time, preset: preset, intensity: capped * 0.62, energy: energy)
            drawFeedbackLumaBloomMemory(context: &context, size: size, time: time, preset: preset, beat: beat, intensity: capped * 0.58, energy: energy)
            drawFeedbackChromaWarpField(context: &context, size: size, time: time, preset: preset, intensity: capped * 0.54, energy: energy)
            drawFeedbackScanlineMemory(context: &context, size: size, time: time, preset: preset, intensity: capped * 0.48, energy: energy)
            drawFeedbackMirrorLabyrinth(context: &context, size: size, time: time, preset: preset, beat: beat, intensity: capped * 0.50, energy: energy)
        }
    }

    private func drawFeedbackOpticalTunnel(context: inout GraphicsContext, size: CGSize, time: TimeInterval, preset: VisualPreset, beat: Double, intensity: Double, energy: Double) {
        let center = CGPoint(x: size.width * (0.5 + (model.macroX - 0.5) * 0.28), y: size.height * (0.5 + (0.5 - model.macroY) * 0.22))
        let shortest = min(size.width, size.height)
        let echoes = 10 + Int(model.feedbackSimulatorDecay * 22)
        let zoom = 0.018 + model.feedbackSimulatorZoom * 0.060
        for echo in 0..<echoes {
            let t = Double(echo) / Double(max(1, echoes - 1))
            let falloff = pow(1.0 - t, 0.9 + (1.0 - model.feedbackSimulatorDecay) * 1.6)
            let inset = shortest * t * zoom * (1.0 + energy * 0.38)
            let wobble = sin(time * (0.55 + model.videoOscillatorRate * 1.4) + t * 12.0) * shortest * 0.018 * model.feedbackSimulatorDisplacement
            let rect = CGRect(x: inset + wobble, y: inset - wobble * 0.7, width: size.width - inset * 2, height: size.height - inset * 2)
            let rotation = (t - 0.5) * model.feedbackSimulatorTwist * Double.pi * 0.38 + sin(beat * Double.pi * 2.0 + t * 5.0) * 0.018 * energy
            var layer = context
            layer.translateBy(x: center.x, y: center.y)
            layer.rotate(by: .radians(rotation))
            layer.translateBy(x: -center.x, y: -center.y)
            layer.stroke(Path(roundedRect: rect, cornerRadius: 6 + (1.0 - t) * 22), with: .color(blendedColor(preset: preset, t: t + time * 0.025).opacity(falloff * intensity * 0.16)), lineWidth: 0.8 + falloff * (2.2 + energy * 4.0))
            if echo % 3 == 0 {
                let ring = inset * (1.4 + model.feedbackSimulatorZoom)
                layer.stroke(Path(ellipseIn: CGRect(x: center.x - ring, y: center.y - ring * 0.56, width: ring * 2, height: ring * 1.12)), with: .color(preset.colorC.opacity(falloff * intensity * 0.07)), lineWidth: 0.7 + energy * 2.0)
            }
        }
    }

    private func drawFeedbackPrismHall(context: inout GraphicsContext, size: CGSize, time: TimeInterval, preset: VisualPreset, intensity: Double, energy: Double) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let shortest = min(size.width, size.height)
        let echoes = 7 + Int(model.feedbackSimulatorPrism * 13)
        let channels: [(Color, Double, Double)] = [(.red, 0.0, 1.0), (.green, 0.33, -0.6), (.cyan, 0.66, 0.8)]
        for echo in 0..<echoes {
            let t = Double(echo) / Double(max(1, echoes - 1))
            let radius = shortest * (0.08 + t * (0.55 + model.feedbackSimulatorZoom * 0.24))
            let sides = 3 + Int(model.feedbackSimulatorPrism * 7)
            for (color, hueOffset, direction) in channels {
                let split = shortest * model.feedbackSimulatorPrism * 0.020 * direction * (1.0 + t * 3.0)
                let rotation = time * (0.04 + model.feedbackSimulatorTwist * 0.20) * direction + t * Double.pi * 0.7
                var path = Path()
                for side in 0...sides {
                    let u = Double(side) / Double(sides) * Double.pi * 2.0 + rotation
                    let refract = sin(u * 2.0 + time * 1.7 + energy * 3.0) * model.feedbackSimulatorDisplacement * shortest * 0.018
                    let p = CGPoint(x: center.x + cos(u) * (radius + refract) + split, y: center.y + sin(u) * (radius * 0.72 - refract * 0.4))
                    if side == 0 { path.move(to: p) } else { path.addLine(to: p) }
                }
                let alpha = pow(1.0 - t, 1.2) * intensity * (0.08 + model.feedbackSimulatorPrism * 0.11)
                context.stroke(path, with: .color(color.opacity(alpha)), lineWidth: 0.7 + energy * 2.0)
                if echo % 2 == 0 {
                    context.stroke(path, with: .color(blendedColor(preset: preset, t: hueOffset + t + time * 0.02).opacity(alpha * 0.55)), lineWidth: 1.6 + model.feedbackSimulatorPrism * 2.0)
                }
            }
        }
    }

    private func drawFeedbackLumaBloomMemory(context: inout GraphicsContext, size: CGSize, time: TimeInterval, preset: VisualPreset, beat: Double, intensity: Double, energy: Double) {
        let cells = 18 + Int(model.feedbackSimulatorDisplacement * 26)
        let cellW = size.width / Double(cells)
        let cellH = size.height / Double(cells)
        let threshold = model.videoKeyThreshold * 0.72
        for y in 0..<cells {
            for x in 0..<cells {
                let nx = Double(x) / Double(cells) - 0.5
                let ny = Double(y) / Double(cells) - 0.5
                let luma = 0.50
                    + sin(nx * 13.0 + time * (0.8 + model.videoOscillatorRate * 2.6)) * 0.22
                    + cos(ny * 11.0 - time * 1.2) * 0.20
                    + sin((nx * nx + ny * ny) * 38.0 - beat * Double.pi * 2.0) * 0.18
                    + energy * 0.18
                guard luma > threshold else { continue }
                let key = min(1.0, (luma - threshold) / max(0.08, 1.0 - threshold))
                let memory = pow(key, 0.7 + (1.0 - model.feedbackSimulatorDecay) * 1.8)
                let bloom = min(cellW, cellH) * (0.12 + memory * (0.42 + model.feedbackSimulatorZoom * 0.38))
                let cx = Double(x) * cellW + cellW * 0.5 + sin(time + ny * 8.0) * cellW * model.feedbackSimulatorDisplacement * 0.45
                let cy = Double(y) * cellH + cellH * 0.5 + cos(time * 0.8 + nx * 8.0) * cellH * model.feedbackSimulatorDisplacement * 0.45
                context.fill(Path(ellipseIn: CGRect(x: cx - bloom, y: cy - bloom, width: bloom * 2, height: bloom * 2)), with: .color(blendedColor(preset: preset, t: luma + time * 0.026).opacity(memory * intensity * 0.14)))
            }
        }
    }

    private func drawFeedbackChromaWarpField(context: inout GraphicsContext, size: CGSize, time: TimeInterval, preset: VisualPreset, intensity: Double, energy: Double) {
        let rows = 14 + Int(model.feedbackSimulatorDisplacement * 20)
        let cols = 18 + Int(model.feedbackSimulatorDisplacement * 28)
        let amp = min(size.width, size.height) * (0.014 + model.feedbackSimulatorDisplacement * 0.055) * (0.7 + energy)
        for row in 0...rows {
            let ny = Double(row) / Double(max(1, rows))
            var path = Path()
            for col in 0...cols {
                let nx = Double(col) / Double(max(1, cols))
                let field = feedbackNoise(nx * 3.2 + model.macroX, ny * 2.8 + model.macroY, time * (0.18 + model.videoOscillatorRate * 0.4))
                let twist = sin((nx - 0.5) * (ny - 0.5) * 26.0 + time * (0.7 + model.feedbackSimulatorTwist)) * amp * model.feedbackSimulatorTwist
                let x = nx * size.width + field * amp + twist
                let y = ny * size.height + sin(field * Double.pi + time + nx * 7.0) * amp * 0.55
                if col == 0 { path.move(to: CGPoint(x: x, y: y)) } else { path.addLine(to: CGPoint(x: x, y: y)) }
            }
            context.stroke(path, with: .color(blendedColor(preset: preset, t: ny + time * 0.018).opacity(0.035 + intensity * 0.095)), lineWidth: 0.7 + energy * 2.0)
        }
        for col in 0...cols where col % 2 == 0 {
            let nx = Double(col) / Double(max(1, cols))
            var path = Path()
            for row in 0...rows {
                let ny = Double(row) / Double(max(1, rows))
                let field = feedbackNoise(nx * 2.8 - model.macroY, ny * 3.3 + model.macroX, time * (0.16 + model.videoOscillatorRate * 0.36) + 2.1)
                let x = nx * size.width + cos(field * Double.pi * 2.0 + time) * amp * 0.65
                let y = ny * size.height + field * amp
                if row == 0 { path.move(to: CGPoint(x: x, y: y)) } else { path.addLine(to: CGPoint(x: x, y: y)) }
            }
            context.stroke(path, with: .color(preset.colorC.opacity(0.020 + intensity * 0.065)), lineWidth: 0.6 + model.feedbackSimulatorPrism * 1.6)
        }
    }

    private func drawFeedbackScanlineMemory(context: inout GraphicsContext, size: CGSize, time: TimeInterval, preset: VisualPreset, intensity: Double, energy: Double) {
        let spacing = 3.0 + (1.0 - model.feedbackSimulatorDecay) * 9.0
        let driftScale = size.width * (0.012 + model.feedbackSimulatorDisplacement * 0.10)
        var rowIndex = 0
        for row in stride(from: 0.0, to: size.height, by: spacing) {
            let t = row / max(1.0, size.height)
            let decay = pow(1.0 - t * 0.32, 1.0 + (1.0 - model.feedbackSimulatorDecay) * 2.0)
            let drift = sin(row * 0.030 + time * (1.2 + model.videoOscillatorRate * 3.0)) * driftScale
                + sin(time * 0.7 + Double(rowIndex) * 0.43) * driftScale * 0.35 * energy
            var path = Path()
            path.move(to: CGPoint(x: drift, y: row))
            path.addLine(to: CGPoint(x: size.width + drift, y: row + sin(time + t * 10.0) * model.feedbackSimulatorTwist * 8.0))
            context.stroke(path, with: .color(blendedColor(preset: preset, t: t + time * 0.018).opacity(decay * (0.020 + intensity * 0.065))), lineWidth: 0.7 + energy * 1.8)
            if rowIndex % 11 == 0 {
                context.fill(Path(CGRect(x: drift * 0.35, y: row, width: size.width, height: max(1.0, spacing * (1.0 + model.feedbackSimulatorZoom * 2.0)))), with: .color(Color.green.opacity(decay * intensity * 0.025)))
            }
            rowIndex += 1
        }
    }

    private func drawFeedbackMirrorLabyrinth(context: inout GraphicsContext, size: CGSize, time: TimeInterval, preset: VisualPreset, beat: Double, intensity: Double, energy: Double) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let shortest = min(size.width, size.height)
        let symmetry = 5 + Int(model.feedbackSimulatorPrism * 11)
        let depth = 8 + Int(model.feedbackSimulatorDecay * 16)
        for ring in 0..<depth {
            let t = Double(ring) / Double(max(1, depth - 1))
            let radius = shortest * (0.06 + t * (0.54 + model.feedbackSimulatorZoom * 0.18))
            let alpha = pow(1.0 - t, 1.15) * intensity * (0.055 + energy * 0.060)
            for segment in 0..<symmetry {
                let a = Double(segment) / Double(symmetry) * Double.pi * 2.0 + time * (0.025 + model.feedbackSimulatorTwist * 0.16) + t * 0.9
                let b = a + Double.pi * 2.0 / Double(symmetry) * (0.44 + sin(beat * Double.pi * 2.0 + t * 5.0) * 0.08)
                let fold = 0.72 + abs(sin(a * 2.0 + time)) * 0.36
                var shard = Path()
                shard.move(to: center)
                shard.addLine(to: CGPoint(x: center.x + cos(a) * radius, y: center.y + sin(a) * radius * fold))
                shard.addLine(to: CGPoint(x: center.x + cos(b) * radius * (1.0 + model.feedbackSimulatorDisplacement * 0.18), y: center.y + sin(b) * radius * fold))
                shard.closeSubpath()
                context.stroke(shard, with: .color(blendedColor(preset: preset, t: t + Double(segment) * 0.05 + time * 0.02).opacity(alpha)), lineWidth: 0.7 + model.feedbackSimulatorPrism * 2.2)
                if segment % 2 == 0 {
                    context.fill(shard, with: .color(blendedColor(preset: preset, t: 1.0 - t + Double(segment) * 0.03).opacity(alpha * 0.24)))
                }
            }
        }
    }

    private func feedbackNoise(_ x: Double, _ y: Double, _ z: Double) -> Double {
        let a = sin(x * 5.13 + z * 1.70) * 0.50
        let b = cos(y * 6.71 - z * 1.31) * 0.32
        let c = sin((x + y) * 9.23 + sin(z * 0.7) * 2.0) * 0.18
        return a + b + c
    }

    private func drawCameraFeedbackOverlay(context: inout GraphicsContext, size: CGSize, time: TimeInterval) {
        guard model.cameraInputEnabled, let image = model.cameraInput.latestImage else { return }

        let baseOpacity = model.cameraOverlayOpacity
        let feedback = model.cameraFeedbackAmount
        let scale = model.cameraOverlayScale
        let swiftUIImage = Image(decorative: image, scale: 1, orientation: .up)
        let shortest = min(size.width, size.height)
        let echoCount: Int
        switch model.cameraFeedbackMode {
        case .optical, .lumaKey:
            echoCount = 5
        case .echoTunnel, .chromaWash:
            echoCount = 9
        case .slitEcho:
            echoCount = 16
        }

        for echo in 0...echoCount {
            let amount = Double(echo) / Double(max(1, echoCount))
            let modeBoost = model.cameraFeedbackMode == .echoTunnel ? 0.48 : 0.28
            let echoScale = scale + amount * feedback * modeBoost
            let width = size.width * echoScale
            let height = size.height * echoScale
            let driftX = sin(time * 0.7 + amount * 5.0) * shortest * feedback * 0.025 * amount
            let driftY = cos(time * 0.6 + amount * 4.0) * shortest * feedback * 0.020 * amount
            let rect = CGRect(
                x: (size.width - width) / 2 + driftX,
                y: (size.height - height) / 2 + driftY,
                width: width,
                height: height
            )

            var layer = context
            let lumaGate = model.cameraFeedbackMode == .lumaKey ? max(0.05, 1.0 - model.cameraLumaThreshold) : 1.0
            layer.opacity = baseOpacity * lumaGate * pow(max(0.08, 1.0 - amount), 1.45) * (echo == 0 ? 1.0 : feedback)
            layer.blendMode = echo == 0 ? .screen : .plusLighter
            layer.translateBy(x: size.width / 2, y: size.height / 2)
            layer.rotate(by: .radians((amount + 0.12) * model.cameraFeedbackRotation * Double.pi))
            layer.translateBy(x: -size.width / 2, y: -size.height / 2)
            if model.cameraMirror {
                layer.translateBy(x: size.width, y: 0)
                layer.scaleBy(x: -1, y: 1)
            }

            if model.cameraFeedbackMode == .slitEcho {
                let stripeHeight = max(4.0, size.height / Double(echoCount + 1) * 0.72)
                let y = size.height * amount + sin(time * 1.3 + amount * 8.0) * stripeHeight
                layer.clip(to: Path(CGRect(x: 0, y: y, width: size.width, height: stripeHeight)))
            }

            layer.draw(swiftUIImage, in: rect)

            if model.cameraFeedbackMode == .chromaWash {
                let hue = (amount + time * 0.04 + model.cameraChromaShift).truncatingRemainder(dividingBy: 1)
                layer.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color.hsba(hue, 0.9, 1.0).opacity(0.035 + feedback * 0.08)))
            }
        }
    }

    private func modulation(time: TimeInterval, beat: Double) -> (warp: Double, hue: Double, zoom: Double) {
        var warp = 0.0
        var hue = 0.0
        var zoom = 0.0
        for slot in model.modSlots where slot.enabled {
            let value: Double
            switch slot.source {
            case .lfo:
                value = sin(time * slot.rate * Double.pi * 2.0)
            case .triangle:
                value = 2.0 * abs(2.0 * ((time * slot.rate).truncatingRemainder(dividingBy: 1)) - 1.0) - 1.0
            case .beat:
                value = sin(beat * Double.pi * 2.0)
            case .bass:
                value = model.sequencer.bass.steps[Int(beat * Double(model.sequencer.patternLength)) % model.sequencer.patternLength] ? 1.0 : -0.25
            case .noise:
                value = sin(time * 0.37 + sin(time * 0.11) * 5.0)
            }

            switch slot.destination {
            case .warp, .feedback, .strobes:
                warp += value * slot.amount
            case .hue:
                hue += value * slot.amount * 0.1
            case .zoom:
                zoom += value * slot.amount * 0.18
            }
        }
        return (warp, hue, zoom)
    }

    private func blendedColor(preset: VisualPreset, t: Double) -> Color {
        let phase = t.truncatingRemainder(dividingBy: 1)
        let baseColor: Color
        switch model.paletteMode {
        case .colourspace:
            baseColor = Color.hsba(phase + model.macroX * 0.18, 0.95, 1.0)
        case .yakNeon:
            baseColor = Color.hsba(0.74 + phase * 0.34, 1.0, 1.0)
        case .phosphor:
            baseColor = phase < 0.5 ? Color(red: 0.45, green: 1.0, blue: 0.28) : Color(red: 0.05, green: 0.82, blue: 0.64)
        case .laserium:
            baseColor = Color.hsba(0.52 + phase * 0.42, 0.86, 1.0)
        case .neon, .acid, .ultraviolet, .infrared, .ice, .monochrome, .rainbow, .amber:
            if phase < 0.33 {
                baseColor = preset.colorA
            } else if phase < 0.66 {
                baseColor = preset.colorB
            } else {
                baseColor = preset.colorC
            }
        }
        return gradeColor(baseColor)
    }

    private func gradeColor(_ color: Color) -> Color {
        guard let rgb = NSColor(color).usingColorSpace(.extendedSRGB) else { return color }
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        rgb.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        let gain = max(0.25, model.visualOutputGain)
        let softClip = min(0.98, max(0.45, model.visualSoftClip))

        func tone(_ value: CGFloat) -> Double {
            let gained = Double(value) * gain
            guard gained > softClip else { return gained }
            let headroom = max(0.000_1, 1.0 - softClip)
            let overshoot = gained - softClip
            return softClip + (1.0 - exp(-overshoot / headroom)) * headroom
        }

        return Color(
            red: tone(red),
            green: tone(green),
            blue: tone(blue),
            opacity: Double(alpha)
        )
    }
}
