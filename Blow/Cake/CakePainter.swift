import SwiftUI

/// The cake itself. Redrawn only when the cake, its size or its lettering changes.
struct CakeCanvas: View, Equatable {
    let layout: CakeLayout
    let style: CakeStyle
    let text: String
    var textEdit: TextEdit = TextEdit()
    var topper: CakeTopper = .none
    /// 0 while the candles are unlit: no warm pool under the cake.
    var light: Double = 1

    var body: some View {
        Canvas { ctx, _ in
            var painter = CakePainter(layout: layout, text: text, style: style)
            painter.light = light
            painter.textEdit = textEdit
            painter.draw(style, topper: topper, in: ctx)
        }
        .allowsHitTesting(false)
    }
}

/// Decoration that sits in FRONT of the candles — drawn as a second canvas on top
/// of them so pearls overlap the candle bases and the crown reads with real depth.
struct CakeFrontDecor: View, Equatable {
    let layout: CakeLayout
    let style: CakeStyle

    var body: some View {
        Canvas { ctx, _ in
            var painter = CakePainter(layout: layout, text: "", style: style)
            painter.drawFrontDecor(in: ctx)
        }
        .allowsHitTesting(false)
    }
}

/// The mutable geometry of one tier. `CakePainter` keeps a stack of these so a
/// multi-tier cake can reuse every cake-drawing function, once per tier.
struct TierGeometry {
    let cx: CGFloat, rx: CGFloat, ry: CGFloat
    let top: CGFloat, bottom: CGFloat
    let w: CGFloat, h: CGFloat, u: CGFloat
}

/// Draws one cake, its stand and the things lying around it. Every measurement hangs off the
/// layout, so the same drawing serves the stage, the setup preview and the thumbnails.
///
/// The cake is a cylinder seen from slightly above. Two helpers place things on it:
/// `side(theta, v)` on the wall and `crown(r, phi)` on the top.
struct CakePainter {
    let layout: CakeLayout
    let text: String
    let style: CakeStyle
    /// Candlelight strength. Zero before the candles are lit or after they go out.
    var light: Double = 1
    /// Optional user edits to the message's position / size / colour.
    var textEdit: TextEdit = TextEdit()

    var cx: CGFloat, rx: CGFloat, ry: CGFloat
    var top: CGFloat, bottom: CGFloat
    var w: CGFloat, h: CGFloat
    /// One point at the size the art was designed for (a 260pt cake).
    var u: CGFloat
    /// Base icing colour of a style's top face — used to re-lay a clean platform
    /// on covered lower tiers so a cut-off motif never shows in the exposed rim.
    func topFill(for style: CakeStyle) -> Color {
        switch style {
        case .wildflower: return Color(hex: 0xFBF2E2)
        case .cherry: return Color(hex: 0xFCE1E2)
        case .noir: return Color(hex: 0x4A2B1D)
        case .starry: return Color(hex: 0x17308A)
        case .roseWindow: return Color(hex: 0xFFF9EC)
        case .berry: return Color(hex: 0xFFF6E9)
        case .azure: return Color(hex: 0x7FB0E8)
        case .christmasTree: return Color(hex: 0x2E6B45)
        case .halloween: return Color(hex: 0xA94A0C)
        case .comingOfAgeGirl: return Color(hex: 0xFFFDFB)
        case .comingOfAgeBoy: return Color(hex: 0xF4F7FD)
        }
    }

    init(layout: CakeLayout, text: String, style: CakeStyle = .wildflower) {
        self.layout = layout
        self.text = text.trimmingCharacters(in: .whitespaces)
        self.style = style
        cx = layout.centerX
        rx = layout.topRadiusX
        ry = layout.topRadiusY
        top = layout.topY
        bottom = layout.bottomY
        w = layout.cakeWidth
        h = layout.sideHeight
        u = layout.cakeWidth / 260
    }

    /// Apply the geometry of tier `index` to this painter's mutable frame.
    private mutating func useTier(_ index: Int) {
        guard layout.tiers > 1 else { return }
        cx = layout.centerX
        w = layout.tierWidth(index)
        rx = w / 2
        ry = w * 0.125
        top = layout.tierTop(index)
        bottom = layout.tierBottom(index)
        // Each tier is a scaled copy: a shorter upper tier keeps the same proportions
        // as the one beneath, which is what makes a stack read with correct perspective.
        h = layout.tierHeight(index)
        u = w / 260
    }

    /// When drawing upper tiers we suppress the plate; `sharedStand` reads this.
    var drawStand = true
    /// Lettering belongs only on the top tier; `lettering` reads this.
    private var drawLettering = true
    /// Large one-off motifs (the tailored shirt front, for instance) belong on
    /// the crown only. Supporting tiers keep the colour and finish but not the
    /// motif, so a stack reads as one cake instead of three costume changes.
    var isCrownTier: Bool { drawLettering }
    /// Which tier is currently being painted (0 = bottom). Decoration functions
    /// derive their own seed / angle / density from this so stacked tiers never
    /// look like identical resized copies.
    private var tierIndex = 0
    /// Angular phase applied only while painting decoration on a stacked tier.
    /// Kept at zero for lettering / candles / toppers so they stay put.
    private var decorPhase: CGFloat = 0

    /// Per-tier angular offset for crown decoration, in radians. Rotating each
    /// tier's ornament ring breaks the "same pattern repeated" look while the
    /// cake body itself stays perfectly symmetrical.
    private var tierPhase: CGFloat {
        let phases: [CGFloat] = [0, 0.46, -0.33, 0.79]
        return phases[tierIndex % phases.count]
    }
    /// Derive a decoration seed from a base value and the current tier so the
    /// same random pattern is never reused on two tiers.
    func tierSeed(_ base: UInt64) -> UInt64 {
        base &+ UInt64(tierIndex &+ 1) &* 0x9E3779B97F4A7C15
    }

    mutating func draw(_ style: CakeStyle, topper: CakeTopper = .none, in ctx: GraphicsContext) {
        let count = layout.tiers
        // Bottom to top: every tier is painted with the SAME recipe, so colour and
        // finish never change between layers. Only the plate (bottom tier), the
        // lettering (top tier) and the ornament phase differ. Each tier's bottom
        // now lands exactly on the tier below's top face, so that light top face
        // shows as a clean platform around the tier above — no board, no shadow.
        if count > 1 {
            for i in 0..<count {
                useTier(i)
                tierIndex = i
                drawStand = (i == 0)
                drawLettering = (i == count - 1)
                decorPhase = i == 0 ? 0 : tierPhase
                paintBody(style, in: ctx)
                decorPhase = 0
                // This tier's top face is about to be covered by the one above,
                // leaving only a narrow rim showing. Re-lay clean icing over that
                // face so the visible rim is a smooth platform, not a motif cut
                // in half by the upper tier (the arrows in the reference notes).
                if i < count - 1 { finishCoveredTop(for: style, in: ctx) }
            }
        } else {
            tierIndex = 0
            drawStand = true
            drawLettering = true
            decorPhase = 0
            paintBody(style, in: ctx)
        }
        // restore the top tier's geometry for the crown details
        useTier(count - 1)
        tierIndex = count - 1
        drawStand = true
        drawLettering = true
        decorPhase = 0
        if topper != .none { drawTopper(topper, in: ctx) }
        if light > 0.01 { candleFootprints(ctx) }
    }

    private func paintBody(_ style: CakeStyle, in ctx: GraphicsContext) {
        switch style {
        case .wildflower: wildflower(ctx)
        case .cherry: cherryVintage(ctx)
        case .noir: noir(ctx)
        case .starry: starryNight(ctx)
        case .roseWindow: roseWindow(ctx)
        case .berry: berryCream(ctx)
        case .azure: azureWave(ctx)
        case .christmasTree: christmasTree(ctx)
        case .halloween: halloween(ctx)
        case .comingOfAgeGirl: comingOfAge(ctx, girl: true)
        case .comingOfAgeBoy:  comingOfAge(ctx, girl: false)
        }
    }

    /// A foreground layer drawn AFTER the candles: a few tiny sugar pearls threaded
    /// between them, so candles sit *among* the decoration rather than floating.
    /// No mounds at the candle feet — those read as stray yellow balls on every cake.
    mutating func drawFrontDecor(in ctx: GraphicsContext) {
        useTier(layout.tiers - 1)
        tierIndex = layout.tiers - 1
        decorPhase = 0
        // Coming-of-age: the bow sits in front of the number candles so "18"
        // reads as standing behind it, as on the reference cakes.
        if style == .comingOfAgeGirl || style == .comingOfAgeBoy {
            comingOfAgeBow(ctx, girl: style == .comingOfAgeGirl)
            return
        }
        let slots = layout.slots
        guard !slots.isEmpty else { return }
        let accent = Color(hex: 0xF3E7D5)

        var rng = SeededRandom(seed: UInt64(300 + slots.count * 7))
        // Little opaque sugar pearls in the gaps. They are always white/cream, never
        // the gold lettering tone that made three conspicuous spheres on every cake.
        let gaps = slots.count <= 3 ? 4 : (slots.count <= 7 ? 5 : 7)
        for k in 0..<gaps {
            let phi = (-0.85 + 1.7 * CGFloat(k) / CGFloat(max(1, gaps - 1))) as CGFloat
            let p = crown(0.78, phi)
            guard slots.allSatisfy({ hypot($0.x - p.x, $0.y - p.y) > w * 0.075 }) else { continue }
            let r = w * rng.range(0.008, 0.012)
            ctx.fill(ellipse(p, r, r), with: .radialGradient(
                Gradient(colors: [.white, accent]),
                center: CGPoint(x: p.x - r * 0.3, y: p.y - r * 0.3), startRadius: 0, endRadius: r * 1.4))
        }
    }

    /// Where each candle is pushed into the cake: a little shadow, a little reflected light.
    private func candleFootprints(_ ctx: GraphicsContext) {
        var c = ctx
        c.clip(to: Path(ellipseIn: topRect))
        for slot in layout.slots {
            let p = CGPoint(x: slot.x, y: slot.y)
            if light > 0.01 {
                pool(c, at: CGPoint(x: p.x, y: p.y + slot.width * 0.1), rx: slot.width * 1.7, ry: slot.width * 0.6,
                     colors: [Theme.glow.opacity(0.35 * light), .clear], lighter: true)
            }
            pool(c, at: CGPoint(x: p.x + slot.width * 0.15, y: p.y), rx: slot.width * 0.95, ry: slot.width * 0.34,
                 colors: [.black.opacity(0.55), .clear])
        }
    }

    // MARK: - geometry

    /// A point on the wall. theta: 0 faces the viewer, ±π/2 are the edges. v: 0 top … 1 bottom.
    /// The wall motif stays anchored to the cake geometry: the per-tier ornament phase
    /// must NOT slide it aside (that leaves a bare strip on one edge — it belongs to
    /// the crown only, see `crown`). To keep stacked tiers from looking like identical
    /// resized copies, a tiny per-tier warp redistributes the pattern along the wall:
    /// `warp(±π/2)=0`, so the edges stay put and the covering never opens a gap.
    private var wallWarp: CGFloat {
        let amps: [CGFloat] = [0, 0.16, -0.13]
        return amps[min(tierIndex, amps.count - 1)]
    }
    func side(_ theta: CGFloat, _ v: CGFloat) -> CGPoint {
        let t = theta + wallWarp * sin(2 * theta)
        return CGPoint(x: cx + rx * sin(t), y: top + h * v + ry * cos(t))
    }

    /// A point on the top. r: 0 centre … 1 rim. phi: 0 toward the viewer, π/2 right, π the back.
    func crown(_ r: CGFloat, _ phi: CGFloat) -> CGPoint {
        CGPoint(x: cx + rx * r * sin(phi + decorPhase), y: top + ry * r * cos(phi + decorPhase))
    }

    /// A point on the wall in surface units of one cake-width: sx along the wall, sy down it.
    func surf(_ sx: CGFloat, _ sy: CGFloat) -> CGPoint {
        side(sx * w / rx, sy * w / h)
    }

    var sidePath: Path {
        var p = Path()
        p.addRect(CGRect(x: cx - rx, y: top, width: rx * 2, height: h))
        p.addEllipse(in: CGRect(x: cx - rx, y: bottom - ry, width: rx * 2, height: ry * 2))
        return p
    }

    var topRect: CGRect { CGRect(x: cx - rx, y: top - ry, width: rx * 2, height: ry * 2) }

    /// A structural line running around the wall at height v. It is part of the
    /// cake's geometry (piping, rims, shading), so it must NOT rotate with the
    /// per-tier ornament phase — only the flowers and sugar work do that.
    func band(_ v: CGFloat, from a: CGFloat = -.pi / 2, to b: CGFloat = .pi / 2) -> Path {
        var p = Path()
        let steps = 28
        for i in 0...steps {
            let theta = a + (b - a) * CGFloat(i) / CGFloat(steps)
            let pt = CGPoint(x: cx + rx * sin(theta), y: top + h * v + ry * cos(theta))
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        return p
    }

    func ellipse(_ c: CGPoint, _ a: CGFloat, _ b: CGFloat) -> Path {
        Path(ellipseIn: CGRect(x: c.x - a, y: c.y - b, width: a * 2, height: b * 2))
    }

    /// True where the lettering goes, so decorations can stay out of its way.
    func inLettering(_ theta: CGFloat, _ v: CGFloat, at line: CGFloat) -> Bool {
        guard !text.isEmpty else { return false }
        let reach = min(0.9, CGFloat(text.count) * 0.036 + 0.12)
        return abs(theta) < reach && abs(v - line) < 0.105
    }

    // MARK: - light

    /// A soft pool of colour lying flat on something.
    func pool(_ ctx: GraphicsContext, at c: CGPoint, rx a: CGFloat, ry b: CGFloat, colors: [Color], lighter: Bool = false) {
        guard a > 1, b > 0.5 else { return }
        var g = ctx
        if lighter { g.blendMode = .plusLighter }
        g.translateBy(x: c.x, y: c.y)
        g.scaleBy(x: 1, y: b / a)
        g.fill(Path(ellipseIn: CGRect(x: -a, y: -a, width: a * 2, height: a * 2)),
               with: .radialGradient(Gradient(colors: colors), center: .zero, startRadius: 0, endRadius: a))
    }

    /// Candlelight on the table, and the shadow of whatever stands on it at y.
    func table(_ ctx: GraphicsContext, at y: CGFloat, footprint: CGFloat, tint: Color = Theme.ember) {
        let room = max(0, layout.size.height - y - 1)
        // Only a lit cake throws warm light onto the table. Unlit, just the shadow remains.
        if light > 0.01 {
            pool(ctx, at: CGPoint(x: cx, y: y), rx: w * 0.76, ry: min(w * 0.15, room),
                 colors: [tint.opacity(0.20 * light), tint.opacity(0.07 * light), .clear])
        }
        pool(ctx, at: CGPoint(x: cx, y: y + w * 0.012), rx: footprint * 1.25, ry: min(footprint * 0.26, room),
             colors: [.black.opacity(0.75), .black.opacity(0.35), .clear])
    }

    func fillSide(_ ctx: GraphicsContext, edge: Color, centre: Color) {
        let g = Gradient(stops: [.init(color: edge, location: 0), .init(color: centre, location: 0.36),
                                 .init(color: centre, location: 0.60), .init(color: edge, location: 1)])
        ctx.fill(sidePath, with: .linearGradient(g, startPoint: CGPoint(x: cx - rx, y: 0), endPoint: CGPoint(x: cx + rx, y: 0)))
    }

    /// Light falls from the candles above: bright under the rim, dim toward the foot and the edges.
    func shadeSide(_ ctx: GraphicsContext, strength: Double = 1) {
        // A stack must read as one cake: all tiers get the same modelling light,
        // even though single cakes keep their own per-style strength.
        let s = layout.tiers > 1 ? 0.85 : strength
        var c = ctx
        c.clip(to: sidePath)
        let box = CGRect(x: cx - rx, y: top, width: rx * 2, height: h + ry)
        c.fill(Path(box), with: .linearGradient(
            Gradient(stops: [.init(color: .white.opacity(0.10 * s), location: 0),
                             .init(color: .clear, location: 0.3),
                             .init(color: .black.opacity(0.26 * s), location: 1)]),
            startPoint: CGPoint(x: cx, y: top), endPoint: CGPoint(x: cx, y: bottom + ry)))
        c.fill(Path(box), with: .linearGradient(
            Gradient(stops: [.init(color: .black.opacity(0.42 * s), location: 0),
                             .init(color: .clear, location: 0.24), .init(color: .clear, location: 0.78),
                             .init(color: .black.opacity(0.36 * s), location: 1)]),
            startPoint: CGPoint(x: cx - rx, y: 0), endPoint: CGPoint(x: cx + rx, y: 0)))
        // Only the bottom tier sits on a plate, so only it gets a foot shadow.
        // Upper tiers end cleanly at their light board — no dark seam line.
        if drawStand {
            var edge = c
            edge.addFilter(.blur(radius: 3 * u))
            edge.stroke(band(1.0), with: .color(.black.opacity(0.35 * s)), lineWidth: 5 * u)
        }
    }

    func fillTop(_ ctx: GraphicsContext, _ color: Color, sheen: Double = 0.2) {
        ctx.fill(Path(ellipseIn: topRect), with: .color(color))
        var c = ctx
        c.clip(to: Path(ellipseIn: topRect))
        pool(c, at: CGPoint(x: cx, y: top - ry * 0.1), rx: rx * 0.9, ry: ry * 0.9,
             colors: [.white.opacity(sheen), .clear])
        c.stroke(Path(ellipseIn: topRect.insetBy(dx: -1, dy: -1)), with: .color(.black.opacity(0.10)), lineWidth: 3 * u)
    }

    /// Re-lay a clean top face on a tier whose centre will be hidden by the tier
    /// above. Only a rim stays visible, so it reads as a smooth icing platform;
    /// the full motif is reserved for the crown tier where it can be seen whole.
    func finishCoveredTop(for style: CakeStyle, in ctx: GraphicsContext) {
        let base = topFill(for: style)
        ctx.fill(Path(ellipseIn: topRect), with: .color(base))
        var c = ctx
        c.clip(to: Path(ellipseIn: topRect))
        pool(c, at: CGPoint(x: cx, y: top - ry * 0.1), rx: rx * 0.9, ry: ry * 0.9,
             colors: [.white.opacity(0.12), .clear])
        c.stroke(Path(ellipseIn: topRect.insetBy(dx: -1, dy: -1)), with: .color(.black.opacity(0.10)), lineWidth: 3 * u)
    }

    // MARK: - topper

    /// An optional little arrangement laid over the crown, on top of the cake's own
    /// decoration. Kept to the middle ring so it never collides with the candles.
    func drawTopper(_ topper: CakeTopper, in ctx: GraphicsContext) {
        var rng = SeededRandom(seed: 913)
        let slots = layout.slots
        func clear(_ p: CGPoint) -> Bool {
            slots.allSatisfy { hypot($0.x - p.x, $0.y - p.y) > w * 0.11 }
        }
        func spot(_ r: CGFloat, _ deg: CGFloat) -> CGPoint { crown(r, deg) }
        switch topper {
        case .none: break
        case .berries:
            // Retired: the ring of six red berries read as stray fruit on every
            // cake. Kept as a case only so old saved data still decodes; it now
            // draws nothing. Existing presets silently fall back to a clean crown.
            break
        case .blossoms:
            for k in 0..<6 {
                let p = spot(0.48, (CGFloat(k) * 60 + 15) * .pi / 180)
                guard clear(p) else { continue }
                daisy(ctx, at: p, size: w * 0.11, angle: rng.range(0, 3),
                      petals: k % 2 == 0 ? Color(hex: 0xFFF6EF) : Color(hex: 0xF7D3DE))
            }
        case .goldLeaf:
            for _ in 0..<16 {
                let p = spot(rng.range(0.25, 0.85), rng.range(0, 2 * .pi))
                guard clear(p) else { continue }
                goldFlake(ctx, at: p, size: rng.range(3, 8) * u, facing: 1, rng: &rng)
            }
        case .stars:
            for k in 0..<5 {
                let p = spot(0.48, (CGFloat(k) * 72 + 20) * .pi / 180)
                guard clear(p) else { continue }
                star(ctx, at: CGPoint(x: p.x, y: p.y - w * 0.05), radius: w * 0.05,
                     color: Color(hex: 0xFFD75E))
            }
        }
    }

    // MARK: - lettering

    /// Piped around the wall, letter by letter, so the words bend with the cake.
    /// `relief` (0…1) adds an offset dark under-layer and a soft top highlight so the
    /// writing reads as piped icing standing proud of the surface rather than flat print.
    func lettering(_ ctx: GraphicsContext, at v: CGFloat, font: Font, color: Color,
                   shadow: Color = .black.opacity(0.25), spacing: CGFloat = 0,
                   uppercase: Bool = false, relief: Double = 0.45) {
        guard !text.isEmpty, drawLettering else { return }
        let raw = uppercase ? text.uppercased() : text
        let chars = Array(raw)
        // Three resolved copies: a shaded underside, the main face, and a faint top gloss.
        // Resolving once per style keeps this cheap and avoids re-resolving inside the loop.
        let sideTone = color.opacity(0.42)
        let main = chars.map { ctx.resolve(Text(String($0)).font(font).foregroundColor(color)) }
        let under = relief > 0.05 ? chars.map { ctx.resolve(Text(String($0)).font(font).foregroundColor(sideTone)) } : []
        let gloss = relief > 0.4 ? chars.map { ctx.resolve(Text(String($0)).font(font).foregroundColor(Color.white.opacity(0.20 * relief))) } : []
        let widths = main.map { $0.measure(in: CGSize(width: 2000, height: 2000)).width + spacing }
        let total = widths.reduce(0, +)
        guard total > 0 else { return }
        // keep the words inside the visible wall; squeeze rather than crop for long names
        let fit = min(1, rx * 1.66 / total)
        var x = -total * fit / 2
        let depth = relief * 1.4 * u / max(fit, 0.01)
        let lift = relief * 0.6 * u / max(fit, 0.01)
        for i in chars.indices {
            let width = widths[i]
            let theta = (x + width * fit / 2) / rx
            x += width * fit
            // Lettering is anchored to the cake, not to the rotating ornament
            // ring: otherwise the words tilt and drift away from the candles.
            let p = CGPoint(x: cx + rx * sin(theta), y: top + h * v + ry * cos(theta))
            var c = ctx
            c.translateBy(x: p.x, y: p.y)
            c.rotate(by: .radians(Double(atan(-(ry / rx) * tan(theta)))))
            c.scaleBy(x: fit * cos(theta), y: fit)
            if relief > 0.05, i < under.count {
                var shadowPass = c
                shadowPass.translateBy(x: depth, y: depth)
                shadowPass.draw(under[i], at: .zero, anchor: .center)
            }
            c.addFilter(.shadow(color: shadow, radius: (0.4 + relief) * u, x: 0, y: (0.5 + relief) * u))
            c.draw(main[i], at: .zero, anchor: .center)
            if relief > 0.4, i < gloss.count {
                var hi = c
                hi.translateBy(x: -lift * 0.5, y: -lift)
                hi.blendMode = .plusLighter
                hi.draw(gloss[i], at: .zero, anchor: .center)
            }
        }
    }

    /// The single entry point that applies a cake's own lettering design, with any
    /// user edits (position / size / colour) layered on top of the style default.
    func styledLettering(_ ctx: GraphicsContext) {
        let s = textEdit.applied(to: style.lettering)
        lettering(ctx, at: s.v, font: s.font(width: w), color: s.color,
                  shadow: s.shadow, spacing: w * s.spacing, uppercase: s.uppercase, relief: s.relief)
    }

    func script(_ scale: CGFloat = 1) -> Font {
        .system(size: w * 0.074 * scale, weight: .medium, design: .serif).italic()
    }

    // MARK: - stands

    struct Stand {
        var light: Color
        var dark: Color
        var accent: Color? = nil
        var scalloped = false
    }

    /// One flat plate silhouette for every cake: a shallow, rimmed dish resting directly
    /// on the table — no stem, no foot. The material and rim pattern change per cake,
    /// so the whole shelf reads as one collection of plates rather than miscellaneous stands.
    func sharedStand(_ ctx: GraphicsContext, scalloped: Bool = false) {
        // Upper tiers have no plate. Their contact shadow is laid down by
        // `draw()` before the tier is painted — drawing it here as well would
        // stack two dark discs on every seam.
        guard drawStand else { return }
        flatPlate(ctx, Stand(light: style.standLight, dark: style.standDark,
                             accent: style.standAccent, scalloped: scalloped))
    }

    /// A slim rectangular board instead of a round plate — used by the wave cake.
    /// Drawn as a flat parallelogrammic slab, with no circular silhouette anywhere.
    func flatBoard(_ ctx: GraphicsContext) {
        let y = bottom + ry * 1.05
        let h = w * 0.052
        let inset = rx * 1.24
        table(ctx, at: y + h, footprint: inset * 0.95)
        let rect = CGRect(x: cx - inset, y: y, width: inset * 2, height: h)
        ctx.fill(Path(roundedRect: rect.offsetBy(dx: 0, dy: h * 0.45), cornerRadius: h * 0.35),
                 with: .color(style.standDark))
        ctx.fill(Path(roundedRect: rect, cornerRadius: h * 0.35),
                 with: .linearGradient(
                    Gradient(stops: [.init(color: style.standDark, location: 0),
                                     .init(color: style.standLight, location: 0.45),
                                     .init(color: style.standDark, location: 1)]),
                    startPoint: CGPoint(x: rect.minX, y: rect.minY),
                    endPoint: CGPoint(x: rect.maxX, y: rect.maxY)))
        ctx.stroke(Path(roundedRect: rect.insetBy(dx: h * 0.18, dy: h * 0.18), cornerRadius: h * 0.2),
                   with: .color(style.standAccent ?? .white.opacity(0.4)), lineWidth: 0.8 * u)
        var soft = ctx
        soft.clip(to: Path(roundedRect: rect, cornerRadius: h * 0.35))
        soft.addFilter(.blur(radius: 3 * u))
        soft.fill(ellipse(CGPoint(x: cx, y: bottom + ry * 0.12), rx * 1.02, ry * 0.95),
                  with: .color(.black.opacity(0.38)))
    }

    /// A vintage square china tray with a rolled gold edge — distinct from the
    /// scalloped round dish used by the berry cake.
    func squarePlate(_ ctx: GraphicsContext) {
        let y = bottom + w * 0.022
        let half = rx * 1.30, depth = w * 0.052, corner = w * 0.11
        table(ctx, at: y + depth * 1.1, footprint: half * 0.94)
        let rect = CGRect(x: cx - half, y: y, width: half * 2, height: depth)
        ctx.fill(Path(roundedRect: rect.offsetBy(dx: 0, dy: depth * 0.65), cornerRadius: corner),
                 with: .color(style.standDark))
        ctx.fill(Path(roundedRect: rect, cornerRadius: corner),
                 with: .linearGradient(
                    Gradient(stops: [.init(color: style.standDark, location: 0),
                                     .init(color: style.standLight, location: 0.35),
                                     .init(color: style.standLight, location: 0.6),
                                     .init(color: style.standDark, location: 1)]),
                    startPoint: CGPoint(x: rect.minX, y: rect.minY),
                    endPoint: CGPoint(x: rect.maxX, y: rect.maxY)))
        let gold = style.standAccent ?? Color(hex: 0xCBA96A)
        ctx.stroke(Path(roundedRect: rect.insetBy(dx: w * 0.012, dy: w * 0.006), cornerRadius: corner * 0.85),
                   with: .color(gold), lineWidth: 1.5 * u)
        ctx.stroke(Path(roundedRect: rect.insetBy(dx: w * 0.028, dy: w * 0.014), cornerRadius: corner * 0.7),
                   with: .color(gold.opacity(0.45)), lineWidth: 0.8 * u)
        var soft = ctx
        soft.clip(to: Path(roundedRect: rect, cornerRadius: corner))
        soft.addFilter(.blur(radius: 4 * u))
        soft.fill(ellipse(CGPoint(x: cx, y: bottom + ry * 0.12), rx * 1.02, ry),
                  with: .color(.black.opacity(0.40)))
    }

    /// A shallow flat cake plate: a dark underside, a broad rim with a material-specific
    /// finish, and the cake's own soft shadow pooled in the middle.
    func flatPlate(_ ctx: GraphicsContext, _ s: Stand) {
        let plateY = bottom + w * 0.030
        let prx = rx * 1.26, pry = ry * 1.32, thick = w * 0.020
        let finish = style.plateFinish

        table(ctx, at: plateY + pry * 0.6, footprint: prx * 0.96)

        let metal = Gradient(stops: [.init(color: s.dark, location: 0),
                                     .init(color: s.light, location: 0.30),
                                     .init(color: s.light, location: 0.52),
                                     .init(color: s.dark, location: 1)])
        func across(_ half: CGFloat) -> GraphicsContext.Shading {
            .linearGradient(metal, startPoint: CGPoint(x: cx - half, y: 0),
                            endPoint: CGPoint(x: cx + half, y: 0))
        }

        // underside / thickness of the dish
        ctx.fill(ellipse(CGPoint(x: cx, y: plateY + thick), prx, pry), with: .color(s.dark))
        var body = Path()
        body.addRect(CGRect(x: cx - prx, y: plateY, width: prx * 2, height: thick))
        body.addEllipse(in: CGRect(x: cx - prx, y: plateY + thick - pry, width: prx * 2, height: pry * 2))
        ctx.fill(body, with: across(prx))

        // scalloped or fluted rim, drawn as small lobes around the near edge
        if s.scalloped || finish == .scallop {
            for k in 0..<27 {
                let phi = (CGFloat(k) / 26 - 0.5) * .pi * 0.97
                let p = CGPoint(x: cx + prx * sin(phi), y: plateY + pry * cos(phi) + thick * 0.5)
                ctx.fill(ellipse(p, thick * 1.5 * max(0.35, cos(phi)), thick * 1.25), with: across(prx))
            }
        }

        // the flat face of the plate
        ctx.fill(ellipse(CGPoint(x: cx, y: plateY), prx, pry), with: across(prx))
        ctx.fill(ellipse(CGPoint(x: cx, y: plateY - pry * 0.04), prx * 0.94, pry * 0.86),
                 with: .linearGradient(Gradient(colors: [s.light, s.dark.opacity(0.92)]),
                                       startPoint: CGPoint(x: cx, y: plateY - pry),
                                       endPoint: CGPoint(x: cx, y: plateY + pry)))

        // material / pattern on the rim
        switch finish {
        case .gold, .roseGold:
            let gold = s.accent ?? Color(hex: 0xE8C46A)
            ctx.stroke(ellipse(CGPoint(x: cx, y: plateY), prx * 0.97, pry * 0.94),
                       with: .color(gold), lineWidth: 1.8 * u)
            ctx.stroke(ellipse(CGPoint(x: cx, y: plateY), prx * 0.88, pry * 0.84),
                       with: .color(gold.opacity(0.55)), lineWidth: 0.9 * u)
            for k in 0..<36 {
                let phi = CGFloat(k) / 36 * 2 * .pi
                let p = CGPoint(x: cx + prx * 0.92 * sin(phi), y: plateY + pry * 0.92 * cos(phi))
                ctx.fill(ellipse(p, 1.1 * u, 1.1 * u), with: .color(gold.opacity(0.8)))
            }
        case .mirrored, .slate:
            ctx.stroke(ellipse(CGPoint(x: cx, y: plateY), prx * 0.95, pry * 0.92),
                       with: .color(s.accent ?? .white.opacity(0.5)), lineWidth: 1.2 * u)
            // a faint radial sheen across the dish
            var sheen = ctx
            sheen.clip(to: ellipse(CGPoint(x: cx, y: plateY), prx * 0.94, pry * 0.86))
            pool(sheen, at: CGPoint(x: cx - prx * 0.4, y: plateY - pry * 0.3),
                 rx: prx * 0.8, ry: pry * 0.8, colors: [.white.opacity(0.22), .clear], lighter: true)
        case .marble:
            ctx.stroke(ellipse(CGPoint(x: cx, y: plateY), prx * 0.95, pry * 0.92),
                       with: .color(s.accent ?? Color(hex: 0xD9B25A)), lineWidth: 1.4 * u)
            var veins = ctx
            veins.clip(to: ellipse(CGPoint(x: cx, y: plateY), prx * 0.93, pry * 0.85))
            var rng = SeededRandom(seed: 88)
            for _ in 0..<12 {
                let phi = rng.range(0, 2 * .pi), d = rng.range(0.2, 0.85)
                let p = CGPoint(x: cx + prx * d * sin(phi), y: plateY + pry * d * cos(phi))
                var v = Path()
                v.move(to: p)
                v.addCurve(to: CGPoint(x: p.x + rng.range(-20, 20) * u, y: p.y + rng.range(6, 18) * u),
                           control1: CGPoint(x: p.x + rng.range(-8, 8) * u, y: p.y + 4 * u),
                           control2: CGPoint(x: p.x + rng.range(-12, 12) * u, y: p.y + 10 * u))
                veins.stroke(v, with: .color(s.dark.opacity(0.28)), lineWidth: 0.8 * u)
            }
        case .wood:
            ctx.stroke(ellipse(CGPoint(x: cx, y: plateY), prx * 0.95, pry * 0.92),
                       with: .color(s.accent ?? Color(hex: 0xD9B25A)), lineWidth: 1.2 * u)
            var grain = ctx
            grain.clip(to: ellipse(CGPoint(x: cx, y: plateY), prx * 0.93, pry * 0.85))
            for k in 1...5 {
                let f = 0.35 + CGFloat(k) * 0.12
                grain.stroke(ellipse(CGPoint(x: cx, y: plateY), prx * f, pry * f),
                             with: .color(s.dark.opacity(0.20)), lineWidth: 0.7 * u)
            }
        case .porcelain, .scallop:
            ctx.stroke(ellipse(CGPoint(x: cx, y: plateY), prx * 0.96, pry * 0.93),
                       with: .color(s.accent ?? Color(hex: 0xD9B25A)), lineWidth: 1.5 * u)
            ctx.stroke(ellipse(CGPoint(x: cx, y: plateY), prx * 0.86, pry * 0.82),
                       with: .color(s.dark.opacity(0.25)), lineWidth: 0.8 * u)
        }

        // the cake's own shadow on the plate
        var soft = ctx
        soft.clip(to: ellipse(CGPoint(x: cx, y: plateY), prx * 0.94, pry * 0.86))
        soft.addFilter(.blur(radius: 4 * u))
        soft.fill(ellipse(CGPoint(x: cx, y: bottom + ry * 0.12), rx * 1.04, ry * 1.06),
                  with: .color(.black.opacity(0.4)))
    }

    /// A footed cake stand: plate, stem, foot.
    func pedestal(_ ctx: GraphicsContext, _ s: Stand) {
        let plateY = bottom + w * 0.012
        let prx = rx * 1.22, pry = ry * 1.22, thick = w * 0.022
        let footY = bottom + w * 0.262
        let frx = w * 0.20, fry = w * 0.042
        table(ctx, at: footY + fry * 0.4, footprint: frx)

        let metal = Gradient(stops: [.init(color: s.dark, location: 0), .init(color: s.light, location: 0.34),
                                     .init(color: s.light, location: 0.46), .init(color: s.dark, location: 1)])
        func across(_ half: CGFloat) -> GraphicsContext.Shading {
            .linearGradient(metal, startPoint: CGPoint(x: cx - half, y: 0), endPoint: CGPoint(x: cx + half, y: 0))
        }

        // foot
        let foot = CGPoint(x: cx, y: footY)
        ctx.fill(ellipse(CGPoint(x: cx, y: footY + w * 0.012), frx, fry), with: .color(s.dark))
        ctx.fill(ellipse(foot, frx, fry), with: across(frx))
        ctx.stroke(ellipse(foot, frx * 0.72, fry * 0.72), with: .color(.black.opacity(0.12)), lineWidth: u)

        // stem
        let y0 = plateY + pry * 0.5, y1 = plateY + (footY - plateY) * 0.52, y2 = footY - fry * 0.25
        let a = w * 0.10, b = w * 0.034, c = frx * 0.74
        var stem = Path()
        stem.move(to: CGPoint(x: cx - a, y: y0))
        stem.addCurve(to: CGPoint(x: cx - b, y: y1), control1: CGPoint(x: cx - a * 0.6, y: y0 + (y1 - y0) * 0.75),
                      control2: CGPoint(x: cx - b, y: y1 - (y1 - y0) * 0.35))
        stem.addCurve(to: CGPoint(x: cx - c, y: y2), control1: CGPoint(x: cx - b, y: y1 + (y2 - y1) * 0.55),
                      control2: CGPoint(x: cx - c * 0.55, y: y2 - (y2 - y1) * 0.1))
        stem.addQuadCurve(to: CGPoint(x: cx + c, y: y2), control: CGPoint(x: cx, y: y2 + fry * 0.7))
        stem.addCurve(to: CGPoint(x: cx + b, y: y1), control1: CGPoint(x: cx + c * 0.55, y: y2 - (y2 - y1) * 0.1),
                      control2: CGPoint(x: cx + b, y: y1 + (y2 - y1) * 0.55))
        stem.addCurve(to: CGPoint(x: cx + a, y: y0), control1: CGPoint(x: cx + b, y: y1 - (y1 - y0) * 0.35),
                      control2: CGPoint(x: cx + a * 0.6, y: y0 + (y1 - y0) * 0.75))
        stem.closeSubpath()
        ctx.fill(stem, with: across(c))
        var shade = ctx
        shade.clip(to: stem)
        shade.fill(Path(CGRect(x: cx - c, y: y0, width: c * 2, height: (y1 - y0) * 0.6)),
                   with: .linearGradient(Gradient(colors: [.black.opacity(0.45), .clear]),
                                         startPoint: CGPoint(x: cx, y: y0), endPoint: CGPoint(x: cx, y: y0 + (y1 - y0) * 0.6)))
        // the knop at the waist
        ctx.fill(ellipse(CGPoint(x: cx, y: y1), b * 1.7, b * 0.62), with: across(b * 1.7))
        if let accent = s.accent {
            ctx.stroke(ellipse(CGPoint(x: cx, y: y1), b * 1.7, b * 0.62), with: .color(accent.opacity(0.8)), lineWidth: 0.8 * u)
            ctx.stroke(ellipse(foot, frx, fry), with: .color(accent.opacity(0.7)), lineWidth: 0.9 * u)
        }

        // plate
        let plate = CGPoint(x: cx, y: plateY)
        ctx.fill(ellipse(CGPoint(x: cx, y: plateY + thick), prx * 0.98, pry), with: .color(s.dark))
        if s.scalloped {
            for k in 0..<23 {
                let phi = (CGFloat(k) / 22 - 0.5) * .pi * 0.96
                let p = CGPoint(x: cx + prx * sin(phi), y: plateY + pry * cos(phi) + thick * 0.55)
                ctx.fill(ellipse(p, thick * 1.25 * max(0.35, cos(phi)), thick * 1.1), with: across(prx))
            }
        }
        ctx.fill(ellipse(plate, prx, pry), with: across(prx))
        ctx.fill(ellipse(plate, prx * 0.93, pry * 0.90),
                 with: .linearGradient(Gradient(colors: [s.light, s.dark.opacity(0.9)]),
                                       startPoint: CGPoint(x: cx, y: plateY - pry), endPoint: CGPoint(x: cx, y: plateY + pry * 1.4)))
        if let accent = s.accent {
            ctx.stroke(ellipse(plate, prx - 0.6 * u, pry - 0.4 * u), with: .color(accent), lineWidth: 1.4 * u)
        }
        // the cake's own shadow on the plate
        var soft = ctx
        soft.clip(to: ellipse(plate, prx * 0.93, pry * 0.90))
        soft.addFilter(.blur(radius: 4 * u))
        soft.fill(ellipse(CGPoint(x: cx, y: bottom + ry * 0.12), rx * 1.04, ry * 1.06), with: .color(.black.opacity(0.4)))
    }

    /// A slice of tree trunk, bark still on.
    func woodSlab(_ ctx: GraphicsContext) {
        let y = bottom + w * 0.012
        let srx = rx * 1.30, sry = ry * 1.30, thick = w * 0.075
        table(ctx, at: y + thick + sry * 0.55, footprint: srx * 0.9)

        var bark = Path()
        bark.addRect(CGRect(x: cx - srx, y: y, width: srx * 2, height: thick))
        bark.addEllipse(in: CGRect(x: cx - srx, y: y + thick - sry, width: srx * 2, height: sry * 2))
        ctx.fill(bark, with: .linearGradient(
            Gradient(colors: [Color(hex: 0x21150E), Color(hex: 0x6A4A31), Color(hex: 0x4A3222), Color(hex: 0x1C120C)]),
            startPoint: CGPoint(x: cx - srx, y: 0), endPoint: CGPoint(x: cx + srx, y: 0)))
        var g = ctx
        g.clip(to: bark)
        var rng = SeededRandom(seed: 5)
        for _ in 0..<70 {
            let phi = rng.range(-1.5, 1.5)
            let x = cx + srx * sin(phi)
            let y0 = y + sry * cos(phi) + rng.range(0, thick * 0.7)
            var p = Path()
            p.move(to: CGPoint(x: x, y: y0))
            p.addLine(to: CGPoint(x: x + rng.range(-1.5, 1.5) * u, y: y0 + rng.range(0.2, 0.6) * thick))
            g.stroke(p, with: .color(rng.unit() < 0.5 ? .black.opacity(0.35) : Color(hex: 0x9B7450, opacity: 0.35)),
                     lineWidth: rng.range(0.8, 2.2) * u)
        }
        let face = CGPoint(x: cx, y: y)
        ctx.fill(ellipse(face, srx, sry), with: .color(Color(hex: 0x3A2618)))
        ctx.fill(ellipse(face, srx * 0.965, sry * 0.94),
                 with: .radialGradient(Gradient(colors: [Color(hex: 0xE9C897), Color(hex: 0xD2A66E), Color(hex: 0xB98852)]),
                                       center: face, startRadius: 0, endRadius: srx))
        for k in 1...6 {
            let f = 0.3 + CGFloat(k) * 0.105
            ctx.stroke(ellipse(CGPoint(x: cx + CGFloat(k % 2) * 2 * u, y: y), srx * f, sry * f * 0.97),
                       with: .color(Color(hex: 0x9A6E3F, opacity: 0.35)), lineWidth: (k % 3 == 0 ? 1.4 : 0.7) * u)
        }
        var soft = ctx
        soft.clip(to: ellipse(face, srx * 0.965, sry * 0.94))
        soft.addFilter(.blur(radius: 4 * u))
        soft.fill(ellipse(CGPoint(x: cx, y: bottom + ry * 0.12), rx * 1.04, ry * 1.06), with: .color(.black.opacity(0.4)))
    }

    // MARK: - piping

    /// A row of piped shells running around the wall at height v.
    func shells(_ ctx: GraphicsContext, at v: CGFloat, count: Int, size: CGFloat, light: Color, dark: Color, drop: CGFloat = 0) {
        let thetas = (0..<count).map { (CGFloat($0) / CGFloat(count - 1) - 0.5) * .pi * 0.98 }
        for theta in thetas.sorted(by: { abs($0) > abs($1) }) {
            let p = side(theta, v)
            let sw = size * max(0.32, cos(theta))
            let c = CGPoint(x: p.x, y: p.y + drop)
            ctx.fill(ellipse(CGPoint(x: c.x, y: c.y + size * 0.10), sw * 0.56, size * 0.50), with: .color(dark.opacity(0.9)))
            ctx.fill(ellipse(c, sw * 0.52, size * 0.48),
                     with: .radialGradient(Gradient(colors: [light, light, dark]),
                                           center: CGPoint(x: c.x - sw * 0.12, y: c.y - size * 0.16),
                                           startRadius: 0, endRadius: size * 0.62))
            var ridge = Path()
            ridge.addArc(center: CGPoint(x: c.x, y: c.y + size * 0.32), radius: sw * 0.34,
                         startAngle: .degrees(200), endAngle: .degrees(340), clockwise: false)
            ctx.stroke(ridge, with: .color(dark.opacity(0.55)), lineWidth: 0.9 * u)
            ctx.fill(ellipse(c, sw * 0.56, size * 0.52), with: .color(.black.opacity(0.36 * Double(1 - cos(theta)))))
        }
    }

    /// One piped swirl sitting on the top.
    func rosette(_ ctx: GraphicsContext, at p: CGPoint, size s: CGFloat, light: Color, dark: Color, peak: Bool = false) {
        ctx.fill(ellipse(CGPoint(x: p.x, y: p.y + s * 0.10), s * 0.52, s * 0.30), with: .color(dark.opacity(0.85)))
        let body = CGPoint(x: p.x, y: p.y - s * 0.10)
        ctx.fill(ellipse(body, s * 0.50, s * 0.36),
                 with: .radialGradient(Gradient(colors: [light, light, dark]),
                                       center: CGPoint(x: body.x - s * 0.12, y: body.y - s * 0.14), startRadius: 0, endRadius: s * 0.6))
        var swirl = Path()
        for i in 0...22 {
            let t = CGFloat(i) / 22
            let a = t * 3.6 * .pi
            let r = s * 0.40 * (1 - t * 0.85)
            let q = CGPoint(x: body.x + r * cos(a), y: body.y - s * 0.16 * t + r * 0.62 * sin(a))
            if i == 0 { swirl.move(to: q) } else { swirl.addLine(to: q) }
        }
        ctx.stroke(swirl, with: .color(dark.opacity(0.6)), lineWidth: s * 0.05)
        if peak {
            var tip = Path()
            tip.move(to: CGPoint(x: body.x - s * 0.16, y: body.y - s * 0.20))
            tip.addQuadCurve(to: CGPoint(x: body.x + s * 0.03, y: body.y - s * 0.58), control: CGPoint(x: body.x - s * 0.02, y: body.y - s * 0.34))
            tip.addQuadCurve(to: CGPoint(x: body.x + s * 0.16, y: body.y - s * 0.20), control: CGPoint(x: body.x + s * 0.10, y: body.y - s * 0.36))
            tip.closeSubpath()
            ctx.fill(tip, with: .color(light))
        }
    }

    /// Glaze poured over the edge and left to run.
    func drips(_ ctx: GraphicsContext, color: Color, shine: Color, seed: UInt64, count: Int, reach: ClosedRange<CGFloat>) {
        ctx.fill(Path(ellipseIn: topRect.offsetBy(dx: 0, dy: ry * 0.24)), with: .color(color))
        var rng = SeededRandom(seed: seed)
        for k in 0..<count {
            let theta = (CGFloat(k) + 0.5 + rng.range(-0.25, 0.25)) / CGFloat(count) * 3.0 - 1.5
            let facing = max(0.28, cos(theta))
            let dw = w * 0.044 * facing
            let x = cx + rx * sin(theta) * 0.985
            let y0 = top + ry * cos(theta) + ry * 0.1
            let y1 = y0 + h * rng.range(reach.lowerBound, reach.upperBound) * (0.55 + 0.45 * cos(theta))
            var p = Path()
            p.addRoundedRect(in: CGRect(x: x - dw / 2, y: y0 - dw, width: dw, height: y1 - y0 + dw), cornerSize: CGSize(width: dw / 2, height: dw / 2))
            p.addEllipse(in: CGRect(x: x - dw * 0.62, y: y1 - dw * 0.95, width: dw * 1.24, height: dw * 1.3))
            ctx.fill(p, with: .color(color))
            var gloss = Path()
            gloss.move(to: CGPoint(x: x - dw * 0.22, y: y0 + dw * 0.4))
            gloss.addLine(to: CGPoint(x: x - dw * 0.22, y: y1 - dw * 0.9))
            ctx.stroke(gloss, with: .color(shine), style: StrokeStyle(lineWidth: dw * 0.16, lineCap: .round))
            ctx.fill(ellipse(CGPoint(x: x - dw * 0.2, y: y1 - dw * 0.45), dw * 0.16, dw * 0.2), with: .color(shine))
        }
    }

    /// A glossy ganache poured over the top and left to run down the wall. Unlike `drips`,
    /// the hem here is one continuous wavy sheet, so the chocolate reads as one heavy pour
    /// rather than a row of separate ribbons.
    func ganache(_ ctx: GraphicsContext, color: Color, shine: Color, seed: UInt64) {
        let cover = topRect.offsetBy(dx: 0, dy: ry * 0.20)
        ctx.fill(Path(ellipseIn: cover), with: .color(color))
        // the poured top pools a little darker toward the far rim and catches a soft sheen
        var topShade = ctx
        topShade.clip(to: Path(ellipseIn: cover))
        pool(topShade, at: CGPoint(x: cx + rx * 0.18, y: top + ry * 0.32), rx: rx * 0.95, ry: ry * 0.9,
             colors: [.black.opacity(0.16), .clear])
        pool(topShade, at: CGPoint(x: cx - rx * 0.30, y: top - ry * 0.22), rx: rx * 0.75, ry: ry * 0.7,
             colors: [shine, .clear], lighter: true)

        // A continuous hem of glaze. Runs taper to a soft rounded drop grown from the
        // sheet itself (not a bead stuck on afterwards), which is how real ganache sets.
        var rng = SeededRandom(seed: seed)
        struct Run { let t: CGFloat; let len: CGFloat; let wid: CGFloat }
        var runs: [Run] = []
        let n = 19
        for k in 0..<n {
            let t = -1.47 + (CGFloat(k) + 0.5) / CGFloat(n) * 2.94 + rng.range(-0.05, 0.05)
            let long = rng.unit() < 0.34
            let len = long ? rng.range(0.26, 0.46) : rng.range(0.05, 0.19)
            let wid = long ? rng.range(0.028, 0.046) : rng.range(0.045, 0.085)
            runs.append(Run(t: t, len: len, wid: wid))
        }
        func hem(_ t: CGFloat) -> CGFloat {
            var v: CGFloat = 0.045
            for p in runs {
                let d = (t - p.t) / p.wid
                v += p.len * exp(-d * d)
            }
            v += 0.012 * (1 + sin(t * 8.1 + 0.6))   // gentle uneven pour between runs
            return min(1.0, v)
        }

        // the sheet: top edge along the rim, lower edge following the wavy hem
        let steps = 360
        var sheet = Path()
        for i in 0...steps {
            let t = -1.55 + 3.10 * CGFloat(i) / CGFloat(steps)
            let p = side(t, hem(t))
            if i == 0 { sheet.move(to: p) } else { sheet.addLine(to: p) }
        }
        for i in (0...steps).reversed() {
            let t = -1.55 + 3.10 * CGFloat(i) / CGFloat(steps)
            sheet.addLine(to: side(t, -0.04))
        }
        sheet.closeSubpath()
        ctx.fill(sheet, with: .color(color))

        // a thin darker line just under the lip gives the glaze thickness
        var lip = ctx
        lip.clip(to: sheet)
        var lipPath = Path()
        for i in 0...steps {
            let t = -1.55 + 3.10 * CGFloat(i) / CGFloat(steps)
            let p = side(t, hem(t) - 0.03)
            if i == 0 { lipPath.move(to: p) } else { lipPath.addLine(to: p) }
        }
        lip.stroke(lipPath, with: .color(.black.opacity(0.20)),
                   style: StrokeStyle(lineWidth: 2.2 * u, lineCap: .round))

        // soft vertical shading within each long run: bright on one flank, dark on the other
        var shade = ctx
        shade.clip(to: sheet)
        for p in runs where p.len > 0.22 {
            let x = cx + rx * sin(p.t)
            let halfW = w * p.wid * max(0.4, cos(p.t))
            let yTop = top + ry * cos(p.t)
            let yBot = side(p.t, hem(p.t)).y
            // use a GraphicsContext shading (CGPoint endpoints) rather than a ShapeStyle
            let grad = Gradient(colors: [.white.opacity(0.13), .clear, .black.opacity(0.14)])
            let cg = GraphicsContext.Shading.linearGradient(grad,
                startPoint: CGPoint(x: x - halfW, y: yTop), endPoint: CGPoint(x: x + halfW, y: yBot))
            shade.fill(Path(CGRect(x: x - halfW, y: yTop, width: halfW * 2, height: max(0, yBot - yTop))), with: cg)
        }

        // the wet highlight on the top lip, following the curve, no bright vertical strips
        ctx.stroke(band(0, from: -1.5, to: 1.5), with: .color(shine.opacity(0.40)), lineWidth: 1.6 * u)
        ctx.stroke(band(0.03, from: -1.45, to: 1.45), with: .color(.black.opacity(0.10)), lineWidth: 0.9 * u)
    }

    /// A shattered square of dark chocolate lying on the crown.
    func chocolateShard(_ ctx: GraphicsContext, at p: CGPoint, size s: CGFloat, angle: CGFloat) {
        var c = ctx
        c.translateBy(x: p.x, y: p.y)
        c.rotate(by: .radians(Double(angle)))
        var shard = Path()
        shard.move(to: CGPoint(x: -s * 0.5, y: -s * 0.46))
        shard.addLine(to: CGPoint(x: s * 0.42, y: -s * 0.5))
        shard.addLine(to: CGPoint(x: s * 0.5, y: s * 0.28))
        shard.addLine(to: CGPoint(x: -s * 0.28, y: s * 0.5))
        shard.closeSubpath()
        c.fill(shard, with: .linearGradient(Gradient(colors: [Color(hex: 0x5A321E), Color(hex: 0x2C1409)]),
                                            startPoint: CGPoint(x: -s * 0.4, y: -s * 0.4), endPoint: CGPoint(x: s * 0.4, y: s * 0.4)))
        c.stroke(shard, with: .color(Color(hex: 0x8A5A34, opacity: 0.6)), lineWidth: 0.7 * u)
        c.fill(ellipse(CGPoint(x: -s * 0.12, y: -s * 0.16), s * 0.16, s * 0.09), with: .color(.white.opacity(0.22)))
    }

    func sprinkle(_ ctx: GraphicsContext, at p: CGPoint, length: CGFloat, angle: CGFloat, facing: CGFloat, color: Color) {
        var c = ctx
        c.translateBy(x: p.x, y: p.y)
        c.scaleBy(x: max(0.3, facing), y: 1)
        c.rotate(by: .radians(Double(angle)))
        let r = CGRect(x: -length / 2, y: -length * 0.15, width: length, height: length * 0.30)
        c.fill(Path(roundedRect: r, cornerRadius: length * 0.15), with: .color(color))
        c.fill(Path(roundedRect: r.insetBy(dx: length * 0.14, dy: length * 0.09).offsetBy(dx: 0, dy: -length * 0.05), cornerRadius: length * 0.05),
               with: .color(.white.opacity(0.4)))
    }

    // MARK: - fruit

    func cherry(_ ctx: GraphicsContext, at p: CGPoint, r: CGFloat, stem: CGFloat = 1) {
        var s = Path()
        s.move(to: CGPoint(x: p.x, y: p.y - r * 0.8))
        s.addQuadCurve(to: CGPoint(x: p.x + r * 1.1 * stem, y: p.y - r * 2.7), control: CGPoint(x: p.x - r * 0.1 * stem, y: p.y - r * 2.2))
        ctx.stroke(s, with: .color(Color(hex: 0x6E4A22)), style: StrokeStyle(lineWidth: r * 0.15, lineCap: .round))
        ctx.fill(ellipse(CGPoint(x: p.x, y: p.y + r * 0.2), r * 1.0, r * 0.9), with: .color(.black.opacity(0.25)))
        ctx.fill(ellipse(p, r, r * 0.96),
                 with: .radialGradient(Gradient(colors: [Color(hex: 0xF4544F), Color(hex: 0xC3122A), Color(hex: 0x6E0717)]),
                                       center: CGPoint(x: p.x - r * 0.3, y: p.y - r * 0.35), startRadius: 0, endRadius: r * 1.35))
        var c = ctx
        c.translateBy(x: p.x - r * 0.36, y: p.y - r * 0.42)
        c.rotate(by: .degrees(-35))
        c.fill(ellipse(.zero, r * 0.24, r * 0.13), with: .color(.white.opacity(0.85)))
    }

    /// A tight cluster of drupelets: blackberries, raspberries.
    func berry(_ ctx: GraphicsContext, at p: CGPoint, r: CGFloat, light: Color, dark: Color, seed: UInt64) {
        ctx.fill(ellipse(CGPoint(x: p.x, y: p.y + r * 0.25), r * 1.05, r * 0.85), with: .color(.black.opacity(0.3)))
        ctx.fill(ellipse(p, r, r * 0.95), with: .color(dark))
        var rng = SeededRandom(seed: seed)
        for ring in 0..<3 {
            let n = [9, 6, 1][ring]
            let d = [r * 0.70, r * 0.36, 0][ring]
            for k in 0..<n {
                let a = CGFloat(k) / CGFloat(n) * 2 * .pi + rng.range(0, 0.5)
                let q = CGPoint(x: p.x + d * cos(a), y: p.y + d * sin(a) * 0.92)
                let br = r * 0.30
                ctx.fill(ellipse(q, br, br),
                         with: .radialGradient(Gradient(colors: [light, dark]), center: CGPoint(x: q.x - br * 0.3, y: q.y - br * 0.4),
                                               startRadius: 0, endRadius: br * 1.2))
                ctx.fill(ellipse(CGPoint(x: q.x - br * 0.3, y: q.y - br * 0.35), br * 0.22, br * 0.16), with: .color(.white.opacity(0.55)))
            }
        }
    }

    /// Half a fig, cut side facing out.
    func fig(_ ctx: GraphicsContext, at p: CGPoint, size s: CGFloat, tilt: CGFloat) {
        var c = ctx
        c.translateBy(x: p.x, y: p.y)
        c.rotate(by: .radians(Double(tilt)))
        func drop(_ k: CGFloat) -> Path {
            var d = Path()
            d.move(to: CGPoint(x: 0, y: -s * 0.56 * k))
            d.addCurve(to: CGPoint(x: s * 0.44 * k, y: s * 0.16 * k), control1: CGPoint(x: s * 0.10 * k, y: -s * 0.36 * k), control2: CGPoint(x: s * 0.44 * k, y: -s * 0.16 * k))
            d.addCurve(to: CGPoint(x: 0, y: s * 0.50 * k), control1: CGPoint(x: s * 0.44 * k, y: s * 0.40 * k), control2: CGPoint(x: s * 0.22 * k, y: s * 0.50 * k))
            d.addCurve(to: CGPoint(x: -s * 0.44 * k, y: s * 0.16 * k), control1: CGPoint(x: -s * 0.22 * k, y: s * 0.50 * k), control2: CGPoint(x: -s * 0.44 * k, y: s * 0.40 * k))
            d.addCurve(to: CGPoint(x: 0, y: -s * 0.56 * k), control1: CGPoint(x: -s * 0.44 * k, y: -s * 0.16 * k), control2: CGPoint(x: -s * 0.10 * k, y: -s * 0.36 * k))
            return d
        }
        c.fill(drop(1).offsetBy(dx: 0, dy: s * 0.06), with: .color(.black.opacity(0.35)))
        c.fill(drop(1), with: .color(Color(hex: 0x3A1A33)))
        c.fill(drop(0.88), with: .color(Color(hex: 0xEBC4AE)))
        c.fill(drop(0.72).offsetBy(dx: 0, dy: s * 0.04),
               with: .radialGradient(Gradient(colors: [Color(hex: 0xE0647A), Color(hex: 0xA8283F), Color(hex: 0x7C1B33)]),
                                     center: CGPoint(x: 0, y: s * 0.10), startRadius: 0, endRadius: s * 0.42))
        var rng = SeededRandom(seed: UInt64(abs(p.x * 7 + p.y)) + 3)
        for _ in 0..<26 {
            let a = rng.range(0, 2 * .pi), d = rng.range(0.04, 0.26) * s
            let q = CGPoint(x: d * cos(a) * 0.9, y: s * 0.10 + d * sin(a))
            c.fill(ellipse(q, s * 0.016, s * 0.022), with: .color(Color(hex: 0xF7DFA8, opacity: 0.9)))
        }
    }

    // MARK: - flowers and leaves

    func leaf(_ ctx: GraphicsContext, at p: CGPoint, length l: CGFloat, angle: CGFloat, color: Color, width: CGFloat = 0.36) {
        var c = ctx
        c.translateBy(x: p.x, y: p.y)
        c.rotate(by: .radians(Double(angle)))
        var path = Path()
        path.move(to: .zero)
        path.addQuadCurve(to: CGPoint(x: 0, y: -l), control: CGPoint(x: l * width, y: -l * 0.45))
        path.addQuadCurve(to: .zero, control: CGPoint(x: -l * width, y: -l * 0.45))
        c.fill(path, with: .color(color))
        var rib = Path()
        rib.move(to: .zero)
        rib.addLine(to: CGPoint(x: 0, y: -l * 0.9))
        c.stroke(rib, with: .color(.black.opacity(0.22)), lineWidth: max(0.5, l * 0.03))
        var lit = Path()
        lit.move(to: CGPoint(x: 0, y: -l * 0.08))
        lit.addQuadCurve(to: CGPoint(x: 0, y: -l * 0.92), control: CGPoint(x: l * width * 0.7, y: -l * 0.45))
        c.stroke(lit, with: .color(.white.opacity(0.16)), lineWidth: max(0.5, l * 0.05))
    }

    func fern(_ ctx: GraphicsContext, at p: CGPoint, length l: CGFloat, angle: CGFloat, color: Color) {
        var c = ctx
        c.translateBy(x: p.x, y: p.y)
        c.rotate(by: .radians(Double(angle)))
        var stem = Path()
        stem.move(to: .zero)
        stem.addQuadCurve(to: CGPoint(x: l * 0.08, y: -l), control: CGPoint(x: -l * 0.06, y: -l * 0.5))
        c.stroke(stem, with: .color(color), style: StrokeStyle(lineWidth: max(0.6, l * 0.025), lineCap: .round))
        for i in 1...7 {
            let t = CGFloat(i) / 8
            let q = CGPoint(x: l * (0.08 * t * t - 0.03 * t), y: -l * t)
            let size = l * 0.26 * (1 - t * 0.7)
            leaf(c, at: q, length: size, angle: 1.05, color: color, width: 0.3)
            leaf(c, at: q, length: size, angle: -1.05, color: color, width: 0.3)
        }
    }

    func lavender(_ ctx: GraphicsContext, at p: CGPoint, length l: CGFloat, angle: CGFloat) {
        var c = ctx
        c.translateBy(x: p.x, y: p.y)
        c.rotate(by: .radians(Double(angle)))
        var stem = Path()
        stem.move(to: .zero)
        stem.addLine(to: CGPoint(x: 0, y: -l))
        c.stroke(stem, with: .color(Color(hex: 0x6F8A5A)), lineWidth: max(0.6, l * 0.025))
        for i in 0..<8 {
            let y = -l * (0.42 + CGFloat(i) * 0.075)
            let s = l * 0.075 * (1 - CGFloat(i) * 0.05)
            let tone = i % 2 == 0 ? Color(hex: 0x8468C4) : Color(hex: 0xA590DC)
            c.fill(ellipse(CGPoint(x: -s * 0.8, y: y), s * 0.75, s), with: .color(tone))
            c.fill(ellipse(CGPoint(x: s * 0.8, y: y - s * 0.5), s * 0.75, s), with: .color(tone))
        }
    }

    private func petal(_ c: GraphicsContext, toward a: CGFloat, distance d: CGFloat, radii: CGSize, light: Color, deep: Color) {
        var g = c
        g.rotate(by: .radians(Double(a)))
        g.translateBy(x: 0, y: -d)
        let r = CGRect(x: -radii.width, y: -radii.height, width: radii.width * 2, height: radii.height * 2)
        g.fill(Path(ellipseIn: r), with: .radialGradient(Gradient(colors: [deep, light]), center: CGPoint(x: 0, y: radii.height * 0.9),
                                                         startRadius: 0, endRadius: radii.height * 1.9))
        g.stroke(Path(ellipseIn: r), with: .color(deep.opacity(0.35)), lineWidth: 0.5 * u)
    }

    struct Pansy {
        var upper: Color, wing: Color, lip: Color
        static let violet = Pansy(upper: Color(hex: 0x4E2F86), wing: Color(hex: 0x8B6BC9), lip: Color(hex: 0xF4CF57))
        static let sun = Pansy(upper: Color(hex: 0xE9A53A), wing: Color(hex: 0xF7D668), lip: Color(hex: 0xFBE9A0))
        static let rose = Pansy(upper: Color(hex: 0xB03A6A), wing: Color(hex: 0xE58FB0), lip: Color(hex: 0xFBE3D6))
    }

    /// squash < 1 lays the flower back, the way it looks pressed flat or seen from the side.
    func pansy(_ ctx: GraphicsContext, at p: CGPoint, size s: CGFloat, angle: CGFloat = 0, squash: CGSize = CGSize(width: 1, height: 1), _ k: Pansy = .violet) {
        var c = ctx
        c.translateBy(x: p.x, y: p.y)
        c.scaleBy(x: squash.width, y: squash.height)
        c.rotate(by: .radians(Double(angle)))
        let dark = Color(hex: 0x2B1650)
        petal(c, toward: -0.62, distance: s * 0.24, radii: CGSize(width: s * 0.27, height: s * 0.27), light: k.upper, deep: dark)
        petal(c, toward: 0.62, distance: s * 0.24, radii: CGSize(width: s * 0.27, height: s * 0.27), light: k.upper, deep: dark)
        petal(c, toward: -1.9, distance: s * 0.21, radii: CGSize(width: s * 0.24, height: s * 0.25), light: k.wing, deep: dark)
        petal(c, toward: 1.9, distance: s * 0.21, radii: CGSize(width: s * 0.24, height: s * 0.25), light: k.wing, deep: dark)
        petal(c, toward: .pi, distance: s * 0.20, radii: CGSize(width: s * 0.31, height: s * 0.27), light: k.lip, deep: dark)
        for a in [-2.6, -2.9, CGFloat.pi, 2.9, 2.6, -1.9, 1.9] as [CGFloat] {
            var line = Path()
            line.move(to: .zero)
            line.addLine(to: CGPoint(x: sin(a) * s * 0.2, y: -cos(a) * s * 0.2))
            c.stroke(line, with: .color(dark.opacity(0.75)), lineWidth: max(0.5, s * 0.022))
        }
        c.fill(ellipse(.zero, s * 0.055, s * 0.055), with: .color(Color(hex: 0xF7B500)))
    }

    func daisy(_ ctx: GraphicsContext, at p: CGPoint, size s: CGFloat, angle: CGFloat = 0, squash: CGSize = CGSize(width: 1, height: 1),
               petals: Color = Color(hex: 0xFFFDF6)) {
        var c = ctx
        c.translateBy(x: p.x, y: p.y)
        c.scaleBy(x: squash.width, y: squash.height)
        c.rotate(by: .radians(Double(angle)))
        for i in 0..<14 {
            var g = c
            g.rotate(by: .radians(Double(i) / 14 * 2 * .pi))
            let r = CGRect(x: -s * 0.065, y: -s * 0.5, width: s * 0.13, height: s * 0.40)
            g.fill(Path(ellipseIn: r), with: .linearGradient(Gradient(colors: [petals, Color(hex: 0xDCD3C2)]),
                                                             startPoint: CGPoint(x: 0, y: -s * 0.5), endPoint: CGPoint(x: 0, y: -s * 0.08)))
        }
        c.fill(ellipse(.zero, s * 0.15, s * 0.15),
               with: .radialGradient(Gradient(colors: [Color(hex: 0xFFE066), Color(hex: 0xE39A1B)]), center: CGPoint(x: -s * 0.04, y: -s * 0.05),
                                     startRadius: 0, endRadius: s * 0.19))
    }

    func cornflower(_ ctx: GraphicsContext, at p: CGPoint, size s: CGFloat, angle: CGFloat = 0, squash: CGSize = CGSize(width: 1, height: 1)) {
        var c = ctx
        c.translateBy(x: p.x, y: p.y)
        c.scaleBy(x: squash.width, y: squash.height)
        c.rotate(by: .radians(Double(angle)))
        for i in 0..<10 {
            var g = c
            g.rotate(by: .radians(Double(i) / 10 * 2 * .pi))
            var f = Path()
            f.move(to: CGPoint(x: 0, y: -s * 0.08))
            f.addLine(to: CGPoint(x: -s * 0.13, y: -s * 0.46))
            f.addLine(to: CGPoint(x: -s * 0.05, y: -s * 0.40))
            f.addLine(to: CGPoint(x: 0, y: -s * 0.50))
            f.addLine(to: CGPoint(x: s * 0.05, y: -s * 0.40))
            f.addLine(to: CGPoint(x: s * 0.13, y: -s * 0.46))
            f.closeSubpath()
            g.fill(f, with: .linearGradient(Gradient(colors: [Color(hex: 0x7C9BFF), Color(hex: 0x3653C9)]),
                                            startPoint: CGPoint(x: 0, y: -s * 0.5), endPoint: CGPoint(x: 0, y: -s * 0.08)))
        }
        c.fill(ellipse(.zero, s * 0.11, s * 0.11), with: .color(Color(hex: 0x2B1E66)))
        for i in 0..<6 {
            let a = CGFloat(i) / 6 * 2 * .pi
            c.fill(ellipse(CGPoint(x: cos(a) * s * 0.06, y: sin(a) * s * 0.06), s * 0.022, s * 0.022), with: .color(Color(hex: 0xC9B8FF)))
        }
    }

    /// A small five-petalled thing: forget-me-nots, blossom, filler flowers.
    func bud(_ ctx: GraphicsContext, at p: CGPoint, size s: CGFloat, color: Color, squash: CGSize = CGSize(width: 1, height: 1)) {
        var c = ctx
        c.translateBy(x: p.x, y: p.y)
        c.scaleBy(x: squash.width, y: squash.height)
        for i in 0..<5 {
            let a = CGFloat(i) / 5 * 2 * .pi - .pi / 2
            let q = CGPoint(x: cos(a) * s * 0.26, y: sin(a) * s * 0.26)
            c.fill(ellipse(q, s * 0.24, s * 0.24), with: .color(color))
            c.stroke(ellipse(q, s * 0.24, s * 0.24), with: .color(.black.opacity(0.10)), lineWidth: 0.4 * u)
        }
        c.fill(ellipse(.zero, s * 0.13, s * 0.13), with: .color(Color(hex: 0xF7C531)))
    }
}
