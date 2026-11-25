import SwiftUI

// The six cakes. Each was imagined for someone: a gardener, a girl of sixteen, a grown-up who
// likes it dark, a five-year-old, a painter who stayed up with a shepherd, and a priest.

extension CakePainter {

    /// Base icing colours per style, used for the undecorated supporting tiers of
    /// a 2- or 3-layer cake. Only the crown carries that style's flowers or pattern.
    /// Icing colours per style. Kept in sync with the `fillSide` / `fillTop`
    /// colours in each recipe so no supporting surface can drift to a different
    /// shade of the same cake.
    var baseTones: (edge: Color, centre: Color, top: Color) {
        switch style {
        case .wildflower:   return (Color(hex: 0xB98548), Color(hex: 0xDBA965), Color(hex: 0xFBF2E2))
        case .cherry:       return (Color(hex: 0xE3A3B1), Color(hex: 0xF9CFD6), Color(hex: 0xFCE1E2))
        case .noir:         return (Color(hex: 0x170B08), Color(hex: 0x472819), Color(hex: 0x4A2B1D))
        case .starry:       return (Color(hex: 0x14246E), Color(hex: 0x1B3A9A), Color(hex: 0x17308A))
        case .roseWindow:   return (Color(hex: 0xD6C9B2), Color(hex: 0xFCF5E7), Color(hex: 0xFFF9EC))
        case .berry:        return (Color(hex: 0xDCC7B2), Color(hex: 0xFFF6E9), Color(hex: 0xFFF6E9))
        case .azure:        return (Color(hex: 0x3E72BE), Color(hex: 0x7FB0E8), Color(hex: 0x7FB0E8))
        case .christmasTree:return (Color(hex: 0x1C4A30), Color(hex: 0x2E6B45), Color(hex: 0x2E6B45))
        case .halloween:    return (Color(hex: 0x24130D), Color(hex: 0xA94A0C), Color(hex: 0xA94A0C))
        case .comingOfAgeGirl: return (Color(hex: 0xEDE3DC), Color(hex: 0xFFFDFB), Color(hex: 0xFFFDFB))
        case .comingOfAgeBoy:  return (Color(hex: 0xD8DFEC), Color(hex: 0xF4F7FD), Color(hex: 0xF4F7FD))
        }
    }

    // MARK: - Wildflower

    /// Sponge barely covered, flowers pressed into the cream, a crown of whatever was in bloom.
    func wildflower(_ ctx: GraphicsContext) {
        sharedStand(ctx)
        let cream = Color(hex: 0xFBF2E2)
        let sage = Color(hex: 0x7C9A6B), moss = Color(hex: 0x54744A), dusty = Color(hex: 0x8FB09E)
        let blue = Color(hex: 0x8FB4F2), pink = Color(hex: 0xF4B6C6), white = Color(hex: 0xFFFBF2)

        fillSide(ctx, edge: Color(hex: 0xB98548), centre: Color(hex: 0xDBA965))
        var c = ctx
        c.clip(to: sidePath)
        var rng = SeededRandom(seed: tierSeed(11))
        for _ in 0..<320 {
            let p = side(rng.range(-1.5, 1.5), rng.range(0, 1.05))
            c.fill(ellipse(p, rng.range(0.5, 1.4) * u, rng.range(0.4, 1.0) * u), with: .color(Color(hex: 0x8A5A2B, opacity: 0.30)))
        }
        for v in [0.34, 0.68] as [CGFloat] {
            c.stroke(band(v), with: .color(cream), lineWidth: h * 0.065)
            c.stroke(band(v + 0.012), with: .color(Color(hex: 0xB23A55, opacity: 0.55)), lineWidth: h * 0.014)
        }
        // a thin scrape of cream over everything, thicker where the knife lingered
        c.fill(Path(CGRect(x: cx - rx, y: top, width: rx * 2, height: h + ry)), with: .color(cream.opacity(0.58)))
        for _ in 0..<170 {
            let a = rng.range(-1.6, 1.3), v = rng.range(0, 1.04)
            let reach = rng.range(0.25, 1.1), alpha = Double(rng.range(0.25, 0.75)), width = rng.range(1.2, 4.6)
            c.stroke(band(v, from: a, to: a + reach), with: .color(cream.opacity(alpha)),
                     style: StrokeStyle(lineWidth: width * u, lineCap: .round))
        }
        for _ in 0..<70 {
            let lane = Int(rng.unit() * 3)
            let v: CGFloat = lane == 0 ? rng.range(0.04, 0.26) : (lane == 1 ? rng.range(0.42, 0.60) : rng.range(0.78, 1.0))
            let a = rng.range(-1.6, 1.3), reach = rng.range(0.15, 0.6), alpha = Double(rng.range(0.14, 0.38)), width = rng.range(1, 3.2)
            c.stroke(band(v, from: a, to: a + reach), with: .color(Color(hex: 0xA8743A, opacity: alpha)),
                     style: StrokeStyle(lineWidth: width * u, lineCap: .round))
        }

        // pressed into the cream
        func flat(_ theta: CGFloat) -> CGSize { CGSize(width: max(0.3, cos(theta)), height: 1) }
        fern(c, at: side(-0.72, 0.38), length: w * 0.15, angle: -0.45, color: moss)
        lavender(c, at: side(-0.30, 0.37), length: w * 0.15, angle: 0.18)
        leaf(c, at: side(-1.0, 0.44), length: w * 0.07, angle: -2.2, color: sage)
        pansy(c, at: side(-1.02, 0.28), size: w * 0.15, angle: -0.3, squash: flat(-1.02))
        daisy(c, at: side(-1.18, 0.68), size: w * 0.10, squash: flat(-1.18))
        bud(c, at: side(-0.50, 0.14), size: w * 0.045, color: blue, squash: flat(-0.5))
        bud(c, at: side(0.02, 0.13), size: w * 0.04, color: pink)
        bud(c, at: side(0.74, 0.11), size: w * 0.045, color: blue, squash: flat(0.74))
        leaf(c, at: side(0.30, 0.30), length: w * 0.07, angle: -0.9, color: dusty)
        leaf(c, at: side(0.54, 0.30), length: w * 0.07, angle: 0.9, color: sage)
        cornflower(c, at: side(0.42, 0.20), size: w * 0.11, squash: flat(0.42))
        pansy(c, at: side(0.99, 0.27), size: w * 0.13, angle: 0.35, squash: flat(0.99), .sun)
        fern(c, at: side(1.14, 0.78), length: w * 0.16, angle: 0.25, color: moss)
        leaf(c, at: side(0.56, 0.92), length: w * 0.06, angle: -1.2, color: sage)
        leaf(c, at: side(0.86, 0.90), length: w * 0.06, angle: 1.1, color: dusty)
        daisy(c, at: side(0.70, 0.85), size: w * 0.105, angle: 0.2, squash: flat(0.70))
        pansy(c, at: side(0.24, 0.86), size: w * 0.10, angle: -0.2, squash: flat(0.24), .rose)
        bud(c, at: side(-0.14, 0.85), size: w * 0.045, color: blue)
        leaf(c, at: side(-0.38, 0.94), length: w * 0.06, angle: -1.0, color: sage)
        bud(c, at: side(-0.46, 0.86), size: w * 0.04, color: white, squash: flat(-0.46))
        bud(c, at: side(-0.84, 0.82), size: w * 0.045, color: pink, squash: flat(-0.84))

        styledLettering(ctx)
        shadeSide(ctx)

        fillTop(ctx, cream)
        ctx.stroke(band(0), with: .color(.white.opacity(0.5)), lineWidth: 1.5 * u)

        // the crown, back to front
        let up = CGSize(width: 1, height: 0.86)
        func on(_ r: CGFloat, _ deg: CGFloat, lift: CGFloat = 0) -> CGPoint {
            let p = crown(r, deg * .pi / 180)
            return CGPoint(x: p.x, y: p.y - lift)
        }
        fern(ctx, at: on(0.62, -168), length: w * 0.20, angle: -0.5, color: moss)
        fern(ctx, at: on(0.80, -140), length: w * 0.18, angle: -0.95, color: sage)
        lavender(ctx, at: on(0.78, -150), length: w * 0.21, angle: -0.28)
        lavender(ctx, at: on(0.70, -128), length: w * 0.19, angle: 0.05)
        leaf(ctx, at: on(0.66, -160), length: w * 0.10, angle: 0.5, color: dusty)
        cornflower(ctx, at: on(0.66, -155, lift: w * 0.045), size: w * 0.115, squash: up)
        leaf(ctx, at: on(0.96, -118), length: w * 0.10, angle: -1.7, color: moss)
        pansy(ctx, at: on(0.74, -114, lift: w * 0.055), size: w * 0.18, angle: -0.15, squash: up)
        bud(ctx, at: on(0.96, -130, lift: w * 0.02), size: w * 0.05, color: pink)
        bud(ctx, at: on(0.55, -100, lift: w * 0.03), size: w * 0.05, color: blue)
        leaf(ctx, at: on(1.0, -86), length: w * 0.10, angle: -2.2, color: sage)
        daisy(ctx, at: on(0.86, -80, lift: w * 0.04), size: w * 0.135, squash: up)
        pansy(ctx, at: on(0.80, -53, lift: w * 0.04), size: w * 0.125, angle: 0.3, squash: up, .sun)
        leaf(ctx, at: on(1.0, -50), length: w * 0.09, angle: -2.5, color: moss)
        bud(ctx, at: on(0.98, -64, lift: w * 0.012), size: w * 0.045, color: white)
        bud(ctx, at: on(0.97, -36, lift: w * 0.01), size: w * 0.05, color: blue)
        // a little something on the other side
        lavender(ctx, at: on(0.88, 104), length: w * 0.15, angle: 0.5)
        lavender(ctx, at: on(0.82, 132), length: w * 0.17, angle: 0.32)
        fern(ctx, at: on(0.72, 150), length: w * 0.17, angle: -0.6, color: sage)
        leaf(ctx, at: on(0.94, 76), length: w * 0.09, angle: 1.9, color: sage)
        leaf(ctx, at: on(0.98, 118), length: w * 0.10, angle: 2.4, color: dusty)
        daisy(ctx, at: on(0.86, 66, lift: w * 0.03), size: w * 0.10, squash: up)
        daisy(ctx, at: on(0.80, 148, lift: w * 0.035), size: w * 0.12, squash: up)
        cornflower(ctx, at: on(0.74, 128, lift: w * 0.045), size: w * 0.11, squash: up)
        pansy(ctx, at: on(0.84, 108, lift: w * 0.05), size: w * 0.135, angle: 0.25, squash: up, .violet)
        bud(ctx, at: on(0.93, 88, lift: w * 0.015), size: w * 0.045, color: pink)
        bud(ctx, at: on(0.97, 140, lift: w * 0.015), size: w * 0.05, color: blue)
        bud(ctx, at: on(0.96, 58, lift: w * 0.012), size: w * 0.045, color: white)
        bud(ctx, at: on(0.70, 118, lift: w * 0.02), size: w * 0.045, color: pink)

        // and at the foot
        let foot = side(0.86, 1.0)
        leaf(ctx, at: CGPoint(x: foot.x + w * 0.02, y: foot.y + w * 0.03), length: w * 0.09, angle: 1.3, color: moss)
        daisy(ctx, at: CGPoint(x: foot.x + w * 0.01, y: foot.y + w * 0.02), size: w * 0.09, squash: CGSize(width: 1, height: 0.6))
        let heel = side(-0.98, 1.0)
        fern(ctx, at: CGPoint(x: heel.x + w * 0.04, y: heel.y + w * 0.035), length: w * 0.13, angle: -1.35, color: sage)
        pansy(ctx, at: CGPoint(x: heel.x, y: heel.y + w * 0.025), size: w * 0.085, angle: 0.4, squash: CGSize(width: 1, height: 0.62), .rose)
    }

    // MARK: - Cherry Vintage

    /// Piped the way grandmothers piped: swags, shells, and a cherry on every swirl.
    func cherryVintage(_ ctx: GraphicsContext) {
        sharedStand(ctx, scalloped: true)
        let icing = Color(hex: 0xFFFCF7), shade = Color(hex: 0xE4C9C6)
        fillSide(ctx, edge: Color(hex: 0xE3A3B1), centre: Color(hex: 0xF9CFD6))
        var c = ctx
        c.clip(to: sidePath)

        // swags hung from eight points. Each is drawn as a ribbon with two edges and a
        // shaded belly, so the icing reads as cloth draped over the cake, not a drawn line.
        let anchors = (0...7).map { (CGFloat($0) / 7 - 0.5) * 2.9 }
        let hang: CGFloat = 0.13
        for i in 0..<7 {
            for (layer, dip, width) in [(0, CGFloat(0.31), CGFloat(7.5)), (1, CGFloat(0.17), CGFloat(4.5))] as [(Int, CGFloat, CGFloat)] {
                let a = anchors[i], b = anchors[i + 1]
                let facing = max(0.4, cos((a + b) / 2))
                let lw = width * u * (0.55 + 0.45 * facing)
                func centre(_ t: CGFloat) -> CGPoint {
                    side(a + (b - a) * t, hang + dip * 4 * t * (1 - t))
                }
                // the ribbon: top edge left→right, bottom edge right→left
                var ribbon = Path()
                for s in 0...20 {
                    let p = centre(CGFloat(s) / 20)
                    if s == 0 { ribbon.move(to: p) } else { ribbon.addLine(to: p) }
                }
                for s in (0...20).reversed() {
                    let p = centre(CGFloat(s) / 20)
                    ribbon.addLine(to: CGPoint(x: p.x, y: p.y + lw * 0.92))
                }
                ribbon.closeSubpath()
                // soft cast shadow just under the cloth
                var shadow = ctx
                shadow.clip(to: sidePath)
                shadow.addFilter(.blur(radius: 1.6 * u))
                shadow.fill(ribbon.offsetBy(dx: 0, dy: 1.8 * u), with: .color(Color(hex: 0xA86075, opacity: 0.55)))
                // the silk itself: bright at the top edge, falling into shade below
                c.fill(ribbon, with: .linearGradient(
                    Gradient(stops: [.init(color: icing, location: 0), .init(color: icing, location: 0.35),
                                     .init(color: shade, location: 1)]),
                    startPoint: CGPoint(x: cx, y: centre(0.5).y - lw),
                    endPoint: CGPoint(x: cx, y: centre(0.5).y + lw)))
                // little folds: short strokes that follow the droop
                for s in 1..<10 {
                    let t = CGFloat(s) / 10
                    let p = centre(t)
                    var fold = Path()
                    fold.move(to: CGPoint(x: p.x, y: p.y + lw * 0.18))
                    fold.addQuadCurve(to: CGPoint(x: p.x + lw * 0.10 * facing, y: p.y + lw * 0.82),
                                      control: CGPoint(x: p.x - lw * 0.06, y: p.y + lw * 0.5))
                    c.stroke(fold, with: .color(shade.opacity(layer == 0 ? 0.55 : 0.4)), lineWidth: 0.7 * u)
                }
                c.stroke(ribbon, with: .color(.white.opacity(0.5)), lineWidth: 0.6 * u)
                // a pearl bead at the lowest point
                if layer == 0 {
                    let low = centre(0.5)
                    c.fill(ellipse(CGPoint(x: low.x, y: low.y + lw * 1.55), w * 0.011, w * 0.011),
                           with: .radialGradient(Gradient(colors: [.white, shade]),
                                                 center: CGPoint(x: low.x - u, y: low.y - u), startRadius: 0, endRadius: w * 0.013))
                }
            }
        }
        for theta in anchors {
            let facing = max(0.35, cos(theta))
            for (k, r) in [0.013, 0.010, 0.0075].enumerated() {
                let p = side(theta, hang + 0.085 + CGFloat(k) * 0.048)
                c.fill(ellipse(p, w * CGFloat(r) * facing, w * CGFloat(r)),
                       with: .radialGradient(Gradient(colors: [.white, shade]), center: CGPoint(x: p.x - u, y: p.y - u), startRadius: 0, endRadius: w * 0.014))
            }
            let p = side(theta, hang - 0.01)
            c.fill(ellipse(p, w * 0.028 * facing, w * 0.026), with: .color(shade))
            c.fill(ellipse(CGPoint(x: p.x, y: p.y - u), w * 0.024 * facing, w * 0.022), with: .color(icing))
            c.fill(ellipse(CGPoint(x: p.x, y: p.y - u), w * 0.008 * facing, w * 0.008), with: .color(shade))
        }

        styledLettering(ctx)
        shadeSide(ctx)
        shells(ctx, at: 1.0, count: 19, size: w * 0.064, light: icing, dark: shade, drop: -w * 0.014)

        fillTop(ctx, Color(hex: 0xFCE1E2))
        shells(ctx, at: 0.0, count: 23, size: w * 0.048, light: icing, dark: shade, drop: w * 0.004)

        let ring = (0..<10).map { crown(0.80, (CGFloat($0) * 36 + 18) * .pi / 180) }
        for (k, p) in ring.enumerated().sorted(by: { $0.element.y < $1.element.y }) {
            rosette(ctx, at: p, size: w * 0.105, light: icing, dark: shade)
            // a cherry on every swirl, with alternating stems, so the crown reads as a
            // generous heap of fruit rather than a sparse ring
            cherry(ctx, at: CGPoint(x: p.x, y: p.y - w * 0.050), r: w * 0.034, stem: k % 2 == 0 ? 1 : -1)
        }
        // a few more tucked into the middle, kept clear of the candles
        for (r, d) in [(0.34, -120), (0.30, -40), (0.36, 120)] as [(CGFloat, CGFloat)] {
            let p = crown(r, d * .pi / 180)
            cherry(ctx, at: CGPoint(x: p.x, y: p.y - w * 0.02), r: w * 0.030, stem: r > 0.32 ? 1 : -1)
        }
    }

    // MARK: - Noir & Gold

    func goldFlake(_ ctx: GraphicsContext, at p: CGPoint, size s: CGFloat, facing: CGFloat, rng: inout SeededRandom) {
        let tones = [Color(hex: 0xF9DC7E), Color(hex: 0xE7BA4F), Color(hex: 0xC8943A), Color(hex: 0xFFF1B8)]
        var path = Path()
        let turn = rng.range(0, 2 * .pi)
        for k in 0..<5 {
            let a = turn + CGFloat(k) / 5 * 2 * .pi + rng.range(-0.3, 0.3)
            let d = s * rng.range(0.45, 1)
            let q = CGPoint(x: p.x + cos(a) * d * max(0.3, facing), y: p.y + sin(a) * d)
            if k == 0 { path.move(to: q) } else { path.addLine(to: q) }
        }
        path.closeSubpath()
        ctx.fill(path, with: .color(tones[Int(rng.unit() * 3.99)]))
    }

    /// Dark chocolate glaze, gold leaf, figs and blackberries. For the grown-ups.
    func noir(_ ctx: GraphicsContext) {
        let gold = Color(hex: 0xE6BC5C)
        sharedStand(ctx)
        // little fruit resting on the rim of the flat plate, beside the cake.
        // Only the bottom tier owns a plate — upper tiers must not sprout fruit.
        if drawStand {
            let ty = bottom + w * 0.055
            fig(ctx, at: CGPoint(x: cx + rx * 1.02, y: ty), size: w * 0.075, tilt: 0.7)
            berry(ctx, at: CGPoint(x: cx - rx * 0.98, y: ty + w * 0.010), r: w * 0.026, light: Color(hex: 0x5B4A78), dark: Color(hex: 0x120C1C), seed: 4)
            berry(ctx, at: CGPoint(x: cx - rx * 0.86, y: ty + w * 0.016), r: w * 0.022, light: Color(hex: 0xE2526A), dark: Color(hex: 0x7C1027), seed: 9)
        }

        fillSide(ctx, edge: Color(hex: 0x170B08), centre: Color(hex: 0x472819))
        var c = ctx
        c.clip(to: sidePath)
        c.fill(Path(CGRect(x: cx - rx * 0.70, y: top, width: rx * 0.42, height: h + ry)),
               with: .linearGradient(Gradient(colors: [.clear, .white.opacity(0.11), .clear]),
                                     startPoint: CGPoint(x: cx - rx * 0.70, y: 0), endPoint: CGPoint(x: cx - rx * 0.28, y: 0)))

        // gold leaf, torn and pressed on
        var rng = SeededRandom(seed: tierSeed(17))
        for _ in 0..<150 {
            let lower = rng.unit() < 0.5
            let theta: CGFloat = lower ? rng.range(-1.42, -0.25) : rng.range(0.45, 1.42)
            let v: CGFloat = lower ? 1.02 - pow(rng.unit(), 1.6) * 0.42 : rng.range(0.42, 1.0)
            let size = pow(rng.unit(), 2.2) * 6.5 + 0.8
            guard !inLettering(theta, v, at: 0.62) else { continue }
            goldFlake(c, at: side(theta, v), size: size * u, facing: cos(theta), rng: &rng)
        }
        for _ in 0..<60 {
            let theta = rng.range(-1.45, 1.45), v = rng.range(0.86, 1.03)
            c.fill(ellipse(side(theta, v), 0.8 * u, 0.8 * u), with: .color(gold.opacity(0.8)))
        }

        styledLettering(ctx)
        shadeSide(ctx, strength: 0.8)
        ganache(ctx, color: Color(hex: 0x3A2016), shine: .white.opacity(0.24), seed: tierSeed(7))
        fillTop(ctx, Color(hex: 0x4A2B1D), sheen: 0.22)
        var mirror = ctx
        mirror.clip(to: Path(ellipseIn: topRect))
        for slot in layout.slots {
            pool(mirror, at: CGPoint(x: slot.x, y: slot.y + ry * 0.42), rx: slot.width * 1.1, ry: ry * 0.5,
                 colors: [Theme.glow.opacity(0.42), Theme.ember.opacity(0.12), .clear], lighter: true)
        }
        // No gold ring — the reference is a bare milk-chocolate pour. Just a faint
        // specular gleam where the light catches the wet ganache.
        var gloss = Path()
        gloss.addArc(center: .zero, radius: 1, startAngle: .degrees(200), endAngle: .degrees(340), clockwise: false)
        ctx.stroke(gloss.applying(CGAffineTransform(a: rx * 0.88, b: 0, c: 0, d: ry * 0.86, tx: cx, ty: top)),
                   with: .color(.white.opacity(0.16)), style: StrokeStyle(lineWidth: 2.5 * u, lineCap: .round))

        // fruit, back to front
        let black = (Color(hex: 0x5B4A78), Color(hex: 0x120C1C)), red = (Color(hex: 0xE2526A), Color(hex: 0x7C1027))
        func on(_ r: CGFloat, _ deg: CGFloat, lift: CGFloat) -> CGPoint {
            let p = crown(r, deg * .pi / 180)
            return CGPoint(x: p.x, y: p.y - lift)
        }
        fern(ctx, at: on(0.86, -142, lift: 0), length: w * 0.16, angle: -0.85, color: Color(hex: 0x3F5A3C))
        berry(ctx, at: on(0.60, -162, lift: w * 0.025), r: w * 0.036, light: black.0, dark: black.1, seed: 1)
        berry(ctx, at: on(0.82, -150, lift: w * 0.02), r: w * 0.030, light: red.0, dark: red.1, seed: 2)
        fig(ctx, at: on(0.74, -124, lift: w * 0.05), size: w * 0.155, tilt: -0.28)
        berry(ctx, at: on(0.95, -112, lift: w * 0.02), r: w * 0.034, light: black.0, dark: black.1, seed: 3)
        fig(ctx, at: on(0.82, -84, lift: w * 0.04), size: w * 0.130, tilt: 0.3)
        berry(ctx, at: on(0.62, -96, lift: w * 0.018), r: w * 0.028, light: red.0, dark: red.1, seed: 5)
        berry(ctx, at: on(0.90, -60, lift: w * 0.018), r: w * 0.034, light: black.0, dark: black.1, seed: 6)
        berry(ctx, at: on(0.98, -44, lift: w * 0.012), r: w * 0.027, light: red.0, dark: red.1, seed: 7)
        berry(ctx, at: on(0.88, 72, lift: w * 0.018), r: w * 0.033, light: black.0, dark: black.1, seed: 8)
        berry(ctx, at: on(0.95, 90, lift: w * 0.014), r: w * 0.026, light: red.0, dark: red.1, seed: 10)
        chocolateShard(ctx, at: on(0.40, -70, lift: w * 0.02), size: w * 0.13, angle: -0.4)
        chocolateShard(ctx, at: on(0.34, -30, lift: w * 0.03), size: w * 0.10, angle: 0.7)
        chocolateShard(ctx, at: on(0.30, 30, lift: w * 0.02), size: w * 0.09, angle: -0.9)
        for _ in 0..<14 {
            let lucky = rng.unit() < 0.7
            let p = crown(rng.range(0.5, 0.98), (lucky ? rng.range(-150, -40) : rng.range(55, 100)) * .pi / 180)
            goldFlake(ctx, at: CGPoint(x: p.x, y: p.y - rng.range(0, 0.05) * w), size: rng.range(1.2, 4.5) * u, facing: 1, rng: &rng)
        }
    }

    // MARK: - Starry Night

    /// Buttercream laid on with a palette knife, the way a painter would do a night sky.
    /// On the hill, a shepherd keeps a lantern lit.
    func starryNight(_ ctx: GraphicsContext) {
        sharedStand(ctx)
        var air = SeededRandom(seed: tierSeed(21))
        for _ in 0..<40 {
            let p = CGPoint(x: cx + air.range(-0.77, 0.77) * w, y: top + air.range(-0.64, 0.60) * w)
            let r = air.range(0.5, 1.5) * u, alpha = Double(air.range(0.12, 0.5))
            ctx.fill(ellipse(p, r, r), with: .color(Color(hex: 0xFFF1B8, opacity: alpha)))
        }

        ctx.fill(sidePath, with: .linearGradient(
            Gradient(colors: [Color(hex: 0x14246E), Color(hex: 0x1B3A9A), Color(hex: 0x0E1B55)]),
            startPoint: CGPoint(x: cx, y: top), endPoint: CGPoint(x: cx, y: bottom + ry)))
        var c = ctx
        c.clip(to: sidePath)

        // Keep the painted hill at the same place on every tier. `h` does not
        // shrink with the tier width, so deriving this from h/w would slide the
        // landscape upward on small upper tiers.
        let deep: CGFloat = 0.46
        func hill(_ sx: CGFloat) -> CGFloat { deep * (0.70 + 0.065 * sin(3.4 * sx + 0.9) + 0.02 * sin(9 * sx)) }
        let whirls: [(x: CGFloat, y: CGFloat, s: CGFloat, spin: CGFloat)] = [(-0.25, 0.150, 0.13, 1), (0.12, 0.215, 0.085, -1)]
        let stars: [(x: CGFloat, y: CGFloat, k: CGFloat)] = [(-0.66, 0.07, 1.0), (-0.50, 0.27, 0.7), (-0.05, 0.045, 0.85),
                                                             (0.20, 0.05, 0.8), (0.31, 0.275, 0.6), (0.66, 0.23, 0.75), (-0.40, 0.03, 0.55)]
        let moon = CGPoint(x: 0.44, y: 0.105)
        let blues = [0x2B4FB8, 0x3F6FD8, 0x6FA0F0, 0x1B3A9A, 0x2E8FA8, 0x254CA8, 0x8DB6F5].map { Color(hex: $0) }
        let pale = [0xCFE3FF, 0xFFF3B0, 0xF6E08A, 0xEAF2FF].map { Color(hex: $0) }

        // the sky: short strokes that follow the wind
        var rng = SeededRandom(seed: tierSeed(23))
        for _ in 0..<560 {
            var x = rng.range(-0.8, 0.8), y = rng.range(-0.01, 0.345)
            var near: CGFloat = 0
            for s in stars { near = max(near, exp(-((x - s.x) * (x - s.x) + (y - s.y) * (y - s.y)) / 0.004)) }
            near = max(near, exp(-((x - moon.x) * (x - moon.x) + (y - moon.y) * (y - moon.y)) / 0.008))
            var path = Path()
            path.move(to: surf(x, y))
            for _ in 0..<6 {
                var dx: CGFloat = 1, dy: CGFloat = 0.22 * sin(x * 7 + y * 5)
                for v in whirls {
                    let ex = x - v.x, ey = y - v.y
                    let d2 = ex * ex + ey * ey
                    let pull = v.spin * 3.4 * exp(-d2 / (v.s * v.s)) / (sqrt(d2) + 0.02)
                    near = max(near, 0.5 * exp(-d2 / (v.s * v.s * 0.5)))
                    dx += -ey * pull
                    dy += ex * pull
                }
                let n = max(0.001, sqrt(dx * dx + dy * dy))
                x += dx / n * 0.014
                y += dy / n * 0.014
                path.addLine(to: surf(x, y))
            }
            let bright = rng.unit() < 0.08 + near * 0.55
            let tone = bright ? rng.pick(pale) : rng.pick(blues)
            let width = rng.range(1.6, 3.6)
            c.stroke(path, with: .color(tone.opacity(0.92)), style: StrokeStyle(lineWidth: width * u, lineCap: .round, lineJoin: .round))
        }

        // stars: a dab of yellow, and rings of strokes around it
        func halo(_ at: CGPoint, _ k: CGFloat, tones: [Color], rings: Int) {
            for ring in 0..<rings {
                let radius = (0.013 + 0.012 * CGFloat(ring)) * k
                let n = 7 + ring * 3
                for j in 0..<n {
                    let a0 = CGFloat(j) / CGFloat(n) * 2 * .pi + CGFloat(ring) * 0.4
                    var dab = Path()
                    for s in 0...3 {
                        let a = a0 + CGFloat(s) / 3 * (2 * .pi / CGFloat(n)) * 0.62
                        let p = surf(at.x + radius * cos(a), at.y + radius * sin(a))
                        if s == 0 { dab.move(to: p) } else { dab.addLine(to: p) }
                    }
                    c.stroke(dab, with: .color(tones[min(ring, tones.count - 1)]), style: StrokeStyle(lineWidth: 2.3 * u, lineCap: .round))
                }
            }
        }
        let starTones = [Color(hex: 0xFFF7C9), Color(hex: 0xF8DA63), Color(hex: 0xA9CBFF)]
        for s in stars {
            halo(CGPoint(x: s.x, y: s.y), s.k, tones: starTones, rings: 3)
            let p = surf(s.x, s.y)
            c.fill(ellipse(p, w * 0.010 * s.k * max(0.35, cos(s.x * w / rx)), w * 0.010 * s.k), with: .color(Color(hex: 0xFFFBE0)))
        }
        halo(moon, 2.5, tones: [Color(hex: 0xF9C74F), Color(hex: 0xF8DA63), Color(hex: 0xFFF3B0)], rings: 3)
        let m = surf(moon.x, moon.y)
        let mf = max(0.35, cos(moon.x * w / rx))
        c.fill(ellipse(m, w * 0.034 * mf, w * 0.034), with: .color(Color(hex: 0xF9B93B)))
        c.fill(ellipse(CGPoint(x: m.x - w * 0.016 * mf, y: m.y - w * 0.006), w * 0.028 * mf, w * 0.028), with: .color(Color(hex: 0x1F45AA)))

        // the hill
        var land = Path()
        for i in 0...40 {
            let sx = -0.8 + 1.6 * CGFloat(i) / 40
            let p = surf(sx, hill(sx))
            if i == 0 { land.move(to: p) } else { land.addLine(to: p) }
        }
        land.addLine(to: CGPoint(x: cx + rx, y: bottom + ry))
        land.addLine(to: CGPoint(x: cx - rx, y: bottom + ry))
        land.closeSubpath()
        c.fill(land, with: .linearGradient(Gradient(colors: [Color(hex: 0x0C1A45), Color(hex: 0x070D24)]),
                                           startPoint: CGPoint(x: cx, y: top + h * 0.7), endPoint: CGPoint(x: cx, y: bottom + ry)))
        for _ in 0..<90 {
            let sx = rng.range(-0.78, 0.74), down = rng.range(0.004, 0.12), reach = rng.range(0.02, 0.06)
            let tone = rng.unit() < 0.5 ? Color(hex: 0x1A2F70) : Color(hex: 0x12414C)
            var p = Path()
            p.move(to: surf(sx, hill(sx) + down))
            p.addLine(to: surf(sx + reach, hill(sx + reach) + down))
            c.stroke(p, with: .color(tone.opacity(0.75)), style: StrokeStyle(lineWidth: 2 * u, lineCap: .round))
        }

        // the flock, and the one who watches it
        for sx in [-0.60, -0.50, -0.42, -0.31, -0.22, 0.42, 0.50, 0.60] as [CGFloat] {
            let p = surf(sx, hill(sx) + 0.016 + 0.006 * sin(sx * 40))
            let f = max(0.4, cos(sx * w / rx)), s = w * 0.017
            let wool = Color(hex: 0xF3EEDF)
            for leg in [-0.6, 0.5] as [CGFloat] {
                var l = Path()
                l.move(to: CGPoint(x: p.x + leg * s * f, y: p.y))
                l.addLine(to: CGPoint(x: p.x + leg * s * f, y: p.y + s * 1.1))
                c.stroke(l, with: .color(Color(hex: 0x05070F)), lineWidth: 1.3 * u)
            }
            c.fill(ellipse(CGPoint(x: p.x - s * 0.5 * f, y: p.y - s * 0.1), s * 0.75 * f, s * 0.7), with: .color(wool))
            c.fill(ellipse(CGPoint(x: p.x + s * 0.4 * f, y: p.y - s * 0.25), s * 0.8 * f, s * 0.75), with: .color(wool))
            c.fill(ellipse(CGPoint(x: p.x, y: p.y + s * 0.15), s * 0.9 * f, s * 0.6), with: .color(wool))
            let headSide: CGFloat = sx < 0 ? 1 : -1
            c.fill(ellipse(CGPoint(x: p.x + headSide * s * 1.25 * f, y: p.y - s * 0.2), s * 0.42 * f, s * 0.45), with: .color(Color(hex: 0x1A1A22)))
        }
        let herd = surf(0.285, hill(0.285) + 0.010)
        let k = w * 1.5
        pool(c, at: CGPoint(x: herd.x + k * 0.012, y: herd.y - k * 0.008), rx: k * 0.045, ry: k * 0.045,
             colors: [Color(hex: 0xFFB648, opacity: 0.8), Color(hex: 0xFF9A2E, opacity: 0.25), .clear], lighter: true)
        let ink = Color(hex: 0x04060D)
        c.fill(Path(roundedRect: CGRect(x: herd.x - k * 0.005, y: herd.y - k * 0.026, width: k * 0.010, height: k * 0.028), cornerRadius: k * 0.004), with: .color(ink))
        c.fill(ellipse(CGPoint(x: herd.x, y: herd.y - k * 0.031), k * 0.0055, k * 0.0055), with: .color(ink))
        var staff = Path()
        staff.move(to: CGPoint(x: herd.x - k * 0.012, y: herd.y + k * 0.002))
        staff.addLine(to: CGPoint(x: herd.x - k * 0.012, y: herd.y - k * 0.040))
        staff.addQuadCurve(to: CGPoint(x: herd.x - k * 0.005, y: herd.y - k * 0.040), control: CGPoint(x: herd.x - k * 0.0085, y: herd.y - k * 0.049))
        c.stroke(staff, with: .color(ink), style: StrokeStyle(lineWidth: 1.2 * u, lineCap: .round))
        c.fill(ellipse(CGPoint(x: herd.x + k * 0.012, y: herd.y - k * 0.008), 1.8 * u, 2.1 * u), with: .color(Color(hex: 0xFFE2A0)))

        styledLettering(ctx)
        shadeSide(ctx, strength: 0.85)

        // the top: the same sky, seen from above
        fillTop(ctx, Color(hex: 0x17308A), sheen: 0.10)
        var t = ctx
        t.clip(to: Path(ellipseIn: topRect))
        for _ in 0..<110 {
            let r = rng.range(0.12, 0.97), a0 = rng.range(0, 2 * .pi), sweep = rng.range(0.25, 0.8)
            let bright = rng.unit() < 0.14
            let tone = bright ? rng.pick(pale) : rng.pick(blues)
            var p = Path()
            for s in 0...6 {
                let q = crown(r + 0.02 * sin(CGFloat(s)), a0 + sweep * CGFloat(s) / 6)
                if s == 0 { p.move(to: q) } else { p.addLine(to: q) }
            }
            t.stroke(p, with: .color(tone.opacity(0.9)), style: StrokeStyle(lineWidth: 2.4 * u, lineCap: .round, lineJoin: .round))
        }
        for _ in 0..<16 {
            let p = crown(sqrt(rng.unit()) * 0.92, rng.range(0, 2 * .pi))
            let s = rng.range(0.008, 0.016) * w
            var star = Path()
            for k in 0..<8 {
                let a = CGFloat(k) / 8 * 2 * .pi
                let d = k % 2 == 0 ? s : s * 0.36
                let q = CGPoint(x: p.x + cos(a) * d, y: p.y + sin(a) * d * 0.6)
                if k == 0 { star.move(to: q) } else { star.addLine(to: q) }
            }
            star.closeSubpath()
            t.fill(star, with: .color(Color(hex: 0xF8DA63)))
        }
        ctx.stroke(band(0), with: .color(Color(hex: 0x8DB6F5, opacity: 0.55)), lineWidth: 2 * u)
    }

    // MARK: - Rose Window

    /// A white cake with windows in it. The candles do what the sun does in a cathedral.
    func roseWindow(_ ctx: GraphicsContext) {
        let gold = Color(hex: 0xD9B25A), lead = Color(hex: 0x1A130D)
        let sapphire = Color(hex: 0x2A55C8), ruby = Color(hex: 0xC4273A), amber = Color(hex: 0xF2B134)
        let emerald = Color(hex: 0x1F9A6A), violet = Color(hex: 0x7446BD), clear = Color(hex: 0xF7E9B5)
        sharedStand(ctx)

        // coloured light thrown on the table — bottom tier only.
        if drawStand {
            let ty = bottom + w * 0.288
            for (dx, tone) in [(-0.52, ruby), (-0.36, sapphire), (-0.24, amber), (0.25, emerald), (0.38, ruby), (0.53, sapphire)] as [(CGFloat, Color)] {
                pool(ctx, at: CGPoint(x: cx + dx * w, y: ty), rx: w * 0.10, ry: w * 0.026, colors: [tone.opacity(0.55), tone.opacity(0.15), .clear], lighter: true)
            }
        }

        fillSide(ctx, edge: Color(hex: 0xD6C9B2), centre: Color(hex: 0xFCF5E7))
        let apex: CGFloat = 0.09, sill: CGFloat = 0.76, half: CGFloat = 0.172, spring: CGFloat = 0.42
        for i in 0..<7 {
            let tc = (CGFloat(i) - 3) * 0.44
            let facing = cos(tc)
            guard facing > 0.15 else { continue }
            func at(_ a: CGFloat, _ b: CGFloat) -> CGPoint { side(tc + a * half, apex + b * (sill - apex)) }

            var arch = Path()
            arch.move(to: at(-1, 1))
            for k in 0...12 {
                let phi = CGFloat(k) / 12 * .pi / 3
                arch.addLine(to: at(1 - 2 * cos(phi), spring * (1 - 2 * sin(phi) / sqrt(3))))
            }
            for k in (0..<12).reversed() {
                let phi = CGFloat(k) / 12 * .pi / 3
                arch.addLine(to: at(2 * cos(phi) - 1, spring * (1 - 2 * sin(phi) / sqrt(3))))
            }
            arch.addLine(to: at(1, 1))
            arch.closeSubpath()

            var g = ctx
            g.clip(to: arch)
            g.fill(arch, with: .color(lead))
            // lozenge quarries, the way old windows are leaded
            let wa: CGFloat = 0.40, hb: CGFloat = 0.095
            for j in 0...11 {
                for k in -2...2 {
                    let ca = CGFloat(k) * wa * 2 + (j % 2 == 0 ? 0 : wa)
                    let cb = CGFloat(j) * hb
                    var d = Path()
                    d.move(to: at(ca, cb - hb))
                    d.addLine(to: at(ca + wa, cb))
                    d.addLine(to: at(ca, cb + hb))
                    d.addLine(to: at(ca - wa, cb))
                    d.closeSubpath()
                    let ring = Int((abs(ca) / wa).rounded())
                    let tone: Color
                    switch ring {
                    case 0: tone = (j / 2) % 2 == 0 ? amber : clear
                    case 1: tone = (j / 2 + i) % 2 == 0 ? sapphire : ruby
                    case 2: tone = (j / 2 + i) % 2 == 0 ? violet : emerald
                    default: tone = sapphire
                    }
                    g.fill(d, with: .color(tone))
                    g.stroke(d, with: .color(lead), lineWidth: 1.3 * u)
                }
            }
            // a medallion in each
            let mid = at(0, 0.40)
            let mr = half * rx * 0.60
            g.fill(ellipse(mid, mr * facing, mr), with: .color(i % 2 == 0 ? ruby : sapphire))
            for q in 0..<4 {
                let a = CGFloat(q) * .pi / 2 + .pi / 4
                g.fill(ellipse(CGPoint(x: mid.x + cos(a) * mr * 0.42 * facing, y: mid.y + sin(a) * mr * 0.42), mr * 0.30 * facing, mr * 0.30),
                       with: .color(i % 2 == 0 ? clear : amber))
            }
            g.fill(ellipse(mid, mr * 0.2 * facing, mr * 0.2), with: .color(emerald))
            g.stroke(ellipse(mid, mr * facing, mr), with: .color(lead), lineWidth: 1.6 * u)
            // the light behind the glass
            pool(g, at: at(0, 0.5), rx: half * rx * 1.3, ry: (sill - apex) * h * 0.55,
                 colors: [.white.opacity(0.34), .white.opacity(0.08), .clear], lighter: true)

            ctx.stroke(arch, with: .color(lead), style: StrokeStyle(lineWidth: 3.4 * u, lineJoin: .round))
            ctx.stroke(arch, with: .color(gold), style: StrokeStyle(lineWidth: 1.5 * u, lineJoin: .round))
        }
        for i in 0..<6 {
            let tc = (CGFloat(i) - 2.5) * 0.44
            let p = side(tc, 0.155)
            let r = w * 0.011
            ctx.fill(ellipse(p, r * max(0.3, cos(tc)), r), with: .color(gold))
            ctx.fill(ellipse(CGPoint(x: p.x - r * 0.25, y: p.y - r * 0.3), r * 0.3, r * 0.25), with: .color(.white.opacity(0.7)))
        }
        ctx.stroke(band(0.04), with: .color(gold), lineWidth: 1.8 * u)
        ctx.stroke(band(0.81), with: .color(gold), lineWidth: 1.4 * u)

        styledLettering(ctx)
        shadeSide(ctx, strength: 0.9)
        shells(ctx, at: 1.0, count: 33, size: w * 0.034, light: Color(hex: 0xF9E6A6), dark: Color(hex: 0xA97F34), drop: -w * 0.006)

        // on top, the rose itself
        fillTop(ctx, Color(hex: 0xFFF9EC), sheen: 0.12)
        func on(_ r: CGFloat, _ deg: CGFloat) -> CGPoint { crown(r, deg * .pi / 180) }
        func pane(from r0: CGFloat, to r1: CGFloat, bulge: CGFloat, start: CGFloat, sweep: CGFloat) -> Path {
            var p = Path()
            p.move(to: on(r0, start))
            p.addLine(to: on(r0, start + sweep / 2))
            p.addLine(to: on(r0, start + sweep))
            for s in 0...8 {
                let t = CGFloat(s) / 8
                p.addLine(to: on(r1 + bulge * sin(.pi * t), start + sweep * (1 - t)))
            }
            p.closeSubpath()
            return p
        }
        var t = ctx
        t.clip(to: Path(ellipseIn: topRect))
        for k in 0..<12 {
            let p = pane(from: 0.42, to: 0.74, bulge: 0.11, start: CGFloat(k) * 30 + 3, sweep: 24)
            t.fill(p, with: .color(k % 2 == 0 ? sapphire : ruby))
            t.stroke(p, with: .color(lead), lineWidth: 1.3 * u)
            let dot = on(0.91, CGFloat(k) * 30)
            t.fill(ellipse(dot, w * 0.012, w * 0.012 * ry / rx * 1.6), with: .color(amber))
            t.stroke(ellipse(dot, w * 0.012, w * 0.012 * ry / rx * 1.6), with: .color(lead), lineWidth: u)
        }
        for k in 0..<6 {
            let p = pane(from: 0.17, to: 0.32, bulge: 0.06, start: CGFloat(k) * 60 + 5, sweep: 50)
            t.fill(p, with: .color(k % 2 == 0 ? emerald : violet))
            t.stroke(p, with: .color(lead), lineWidth: 1.2 * u)
        }
        for r in [0.965, 0.40, 0.15] as [CGFloat] {
            t.stroke(ellipse(CGPoint(x: cx, y: top), rx * r, ry * r), with: .color(gold), lineWidth: (r > 0.9 ? 2.4 : 1.6) * u)
        }
        t.fill(ellipse(CGPoint(x: cx, y: top), rx * 0.11, ry * 0.11),
               with: .radialGradient(Gradient(colors: [Color(hex: 0xFFF2C2), gold]), center: CGPoint(x: cx - rx * 0.03, y: top - ry * 0.03),
                                     startRadius: 0, endRadius: rx * 0.12))
        pool(t, at: CGPoint(x: cx, y: top), rx: rx * 0.9, ry: ry * 0.9, colors: [.white.opacity(0.22), .clear], lighter: true)
    }

    // MARK: - Berry Buttercream

    /// Tall swirls of buttercream crowded with raspberries, blueberries and mint.
    func berryCream(_ ctx: GraphicsContext) {
        sharedStand(ctx, scalloped: true)
        let cream = Color(hex: 0xFFF6E9), creamShade = Color(hex: 0xEAD8C4)
        fillSide(ctx, edge: Color(hex: 0xDCC7B2), centre: cream)
        var c = ctx
        c.clip(to: sidePath)
        var rng = SeededRandom(seed: tierSeed(71))
        for _ in 0..<120 {
            let theta = rng.range(-1.5, 1.5), v = rng.range(0, 1.03)
            c.stroke(band(v, from: theta, to: theta + rng.range(0.02, 0.06)),
                     with: .color(.white.opacity(Double(rng.range(0.1, 0.3)))),
                     style: StrokeStyle(lineWidth: rng.range(1, 2.4) * u, lineCap: .round))
        }
        styledLettering(ctx)
        shadeSide(ctx, strength: 0.8)
        shells(ctx, at: 1.0, count: 23, size: w * 0.052, light: cream, dark: creamShade, drop: -w * 0.012)

        fillTop(ctx, cream, sheen: 0.22)
        func on(_ r: CGFloat, _ deg: CGFloat, lift: CGFloat = 0) -> CGPoint {
            let p = crown(r, deg * .pi / 180)
            return CGPoint(x: p.x, y: p.y - lift)
        }
        // a ring of tall cream swirls, tucked well inside the rim so the front
        // ones sit ON the top face instead of hanging over the edge
        let ring = (0..<9).map { on(0.55, CGFloat($0) * 40 + 10) }
        let flowerLight = Color(hex: 0xFFE3EC), flowerShade = Color(hex: 0xE9AFC2)
        for (k, p) in ring.enumerated().sorted(by: { $0.element.y < $1.element.y }) {
            // a piped base so the swirl stands off the flat top
            ctx.fill(ellipse(CGPoint(x: p.x, y: p.y + w * 0.016), w * 0.060, w * 0.040), with: .color(flowerShade.opacity(0.7)))
            rosette(ctx, at: CGPoint(x: p.x, y: p.y - w * 0.016), size: w * 0.135, light: flowerLight, dark: flowerShade, peak: true)
            if k % 2 == 0 {
                berry(ctx, at: CGPoint(x: p.x, y: p.y - w * 0.10), r: w * 0.032,
                      light: Color(hex: 0xE4556E), dark: Color(hex: 0x8E1730), seed: UInt64(k + 20))
            } else {
                blueberry(ctx, at: CGPoint(x: p.x, y: p.y - w * 0.085), r: w * 0.028)
            }
        }
        // a little cluster in the middle, kept clear of the candles
        for (r, d, s) in [(0.22, -150, 0.026), (0.18, -95, 0.024), (0.23, -40, 0.026)] as [(CGFloat, CGFloat, CGFloat)] {
            berry(ctx, at: on(r, d, lift: w * 0.02), r: w * s,
                  light: Color(hex: 0xE4556E), dark: Color(hex: 0x8E1730), seed: UInt64(rng.unit() * 100))
        }
        // mint leaves tucked between
        for (r, d) in [(0.40, -128), (0.36, -70), (0.44, -20)] as [(CGFloat, CGFloat)] {
            leaf(ctx, at: on(r, d, lift: w * 0.03), length: w * 0.085, angle: 2.2, color: Color(hex: 0x6E9B5C))
        }
    }

    /// A blueberry: dusty bloom on a deep indigo sphere, with a little crown.
    func blueberry(_ ctx: GraphicsContext, at p: CGPoint, r: CGFloat) {
        ctx.fill(ellipse(CGPoint(x: p.x, y: p.y + r * 0.2), r, r * 0.8), with: .color(.black.opacity(0.28)))
        ctx.fill(ellipse(p, r, r * 0.94),
                 with: .radialGradient(Gradient(colors: [Color(hex: 0x8C8FB8), Color(hex: 0x3B3A73), Color(hex: 0x1E1C46)]),
                                       center: CGPoint(x: p.x - r * 0.3, y: p.y - r * 0.35),
                                       startRadius: 0, endRadius: r * 1.3))
        for k in 0..<5 {
            let a = CGFloat(k) / 5 * 2 * .pi
            ctx.fill(ellipse(CGPoint(x: p.x + cos(a) * r * 0.22, y: p.y - r * 0.6 + sin(a) * r * 0.12),
                             r * 0.14, r * 0.10), with: .color(Color(hex: 0x24224C)))
        }
        ctx.fill(ellipse(CGPoint(x: p.x - r * 0.32, y: p.y - r * 0.36), r * 0.22, r * 0.12),
                 with: .color(.white.opacity(0.3)))
    }

    // MARK: - Azure Wave

    /// Cornflower buttercream combed into waves, piped pearls and little sugar stars.
    func azureWave(_ ctx: GraphicsContext) {
        sharedStand(ctx)
        let blue = Color(hex: 0x7FB0E8), deep = Color(hex: 0x3E72BE), pale = Color(hex: 0xDCEBFB)
        fillSide(ctx, edge: deep, centre: blue)
        var c = ctx
        c.clip(to: sidePath)
        // horizontal combed waves
        for k in 0..<14 {
            let v = CGFloat(k) / 14
            var wave = Path()
            for s in 0...40 {
                let theta = -1.5 + 3.0 * CGFloat(s) / 40
                let p = side(theta, v + 0.012 * sin(theta * 6 + CGFloat(k) * 0.7))
                if s == 0 { wave.move(to: p) } else { wave.addLine(to: p) }
            }
            c.stroke(wave, with: .color(k % 2 == 0 ? pale.opacity(0.55) : deep.opacity(0.25)),
                     style: StrokeStyle(lineWidth: 2 * u, lineCap: .round))
        }
        // a white piped band with a scalloped lower edge
        let bandV: CGFloat = 0.46
        var band = Path()
        for s in 0...40 {
            let theta = -1.5 + 3.0 * CGFloat(s) / 40
            let p = side(theta, bandV + 0.018 * sin(theta * 8))
            if s == 0 { band.move(to: p) } else { band.addLine(to: p) }
        }
        c.stroke(band, with: .color(creamWave), style: StrokeStyle(lineWidth: 5 * u, lineCap: .round))
        styledLettering(ctx)
        shadeSide(ctx, strength: 0.82)
        shells(ctx, at: 1.0, count: 25, size: w * 0.044, light: pale, dark: blue, drop: -w * 0.010)

        fillTop(ctx, blue, sheen: 0.20)
        func on(_ r: CGFloat, _ deg: CGFloat, lift: CGFloat = 0) -> CGPoint {
            let p = crown(r, deg * .pi / 180)
            return CGPoint(x: p.x, y: p.y - lift)
        }
        // piped pearls around the crown
        for k in 0..<14 {
            let p = on(0.86, CGFloat(k) * 360 / 14 + 12)
            rosette(ctx, at: p, size: w * 0.075, light: .white, dark: pale)
        }
        // sugar stars standing among them
        for (r, d, s) in [(0.52, -150, 0.052), (0.40, -100, 0.045), (0.56, -52, 0.050)] as [(CGFloat, CGFloat, CGFloat)] {
            star(ctx, at: on(r, d, lift: w * 0.06), radius: w * s, color: Color(hex: 0xFFD75E))
        }
    }
    private var creamWave: Color { Color(hex: 0xF4F9FF) }

    /// A plump five-point sugar star.
    func star(_ ctx: GraphicsContext, at p: CGPoint, radius r: CGFloat, color: Color) {
        var path = Path()
        for k in 0..<10 {
            let a = CGFloat(k) / 10 * 2 * .pi - .pi / 2
            let d = k % 2 == 0 ? r : r * 0.44
            let q = CGPoint(x: p.x + cos(a) * d, y: p.y + sin(a) * d)
            if k == 0 { path.move(to: q) } else { path.addLine(to: q) }
        }
        path.closeSubpath()
        ctx.fill(path.offsetBy(dx: 0, dy: r * 0.12), with: .color(.black.opacity(0.18)))
        ctx.fill(path, with: .linearGradient(Gradient(colors: [Color(hex: 0xFFF0B0), color]),
                                             startPoint: CGPoint(x: p.x, y: p.y - r),
                                             endPoint: CGPoint(x: p.x, y: p.y + r)))
        ctx.stroke(path, with: .color(Color(hex: 0xE0A93A, opacity: 0.6)), lineWidth: 0.7 * u)
    }

    // MARK: - Christmas Tree

    /// A spiral of piped green buttercream rising to a point, studded with baubles
    /// and a star — the whole cake shaped like a tree.
    func christmasTree(_ ctx: GraphicsContext) {
        sharedStand(ctx)
        let green = Color(hex: 0x2E6B45), deep = Color(hex: 0x1C4A30), lit = Color(hex: 0x4E8B5C)
        let gold = Color(hex: 0xE9C159), red = Color(hex: 0xC6263C)

        fillSide(ctx, edge: deep, centre: green)
        var c = ctx
        c.clip(to: sidePath)
        // garlands: two spiralling rows of needles
        for row in 0..<6 {
            let v = 0.10 + CGFloat(row) * 0.155
            for s in 0...40 {
                let theta = -1.5 + 3.0 * CGFloat(s) / 40
                let p = side(theta, v + 0.018 * sin(theta * 5 + CGFloat(row)))
                if s == 0 { continue }
                let q = side(-1.5 + 3.0 * CGFloat(s - 1) / 40, v + 0.018 * sin((-1.5 + 3.0 * CGFloat(s - 1) / 40) * 5 + CGFloat(row)))
                var seg = Path()
                seg.move(to: q)
                seg.addLine(to: p)
                c.stroke(seg,
                         with: .color(row % 2 == 0 ? lit.opacity(0.75) : deep.opacity(0.7)),
                         style: StrokeStyle(lineWidth: 2.4 * u, lineCap: .round))
            }
        }
        // baubles on the wall
        for row in 0..<5 {
            let v = 0.16 + CGFloat(row) * 0.155
            for k in 0..<5 {
                let theta = -1.25 + CGFloat(k) * 0.62 + (row % 2 == 0 ? 0 : 0.3)
                let p = side(theta, v)
                let r = w * 0.018
                let tone: Color = (row + k) % 3 == 0 ? gold : ((row + k) % 3 == 1 ? red : Color(hex: 0xF3E7C8))
                c.fill(ellipse(CGPoint(x: p.x, y: p.y + r), r * 0.7, r * 0.5), with: .color(.black.opacity(0.3)))
                c.fill(ellipse(p, r, r), with: .radialGradient(Gradient(colors: [.white, tone]),
                       center: CGPoint(x: p.x - r * 0.3, y: p.y - r * 0.3), startRadius: 0, endRadius: r * 1.3))
            }
        }
        styledLettering(ctx)
        shadeSide(ctx, strength: 0.9)

        // A clean iced crown: the piped fir on top read as clutter, so the top is
        // left calm and all the seasonal character lives on the wall instead.
        fillTop(ctx, green, sheen: 0.20)
        // a fine ring of sugar along the rim
        for k in 0..<26 {
            let p = crown(0.94, CGFloat(k) * (360.0 / 26) * .pi / 180)
            ctx.fill(ellipse(p, 1.1 * u, 1.1 * u), with: .color(Color(hex: 0xF3E7C8).opacity(0.55)))
        }

        // A little snowman toward the back-left of the crown, clear of the central
        // candle, so the top isn't bare but nothing collides with the flames.
        let sp = crown(0.56, .pi * 0.78)
        let s = w * 0.082
        let base = CGPoint(x: sp.x, y: sp.y - s * 0.85)
        let head = CGPoint(x: sp.x, y: base.y - s * 1.42)
        func snowball(_ p: CGPoint, _ r: CGFloat) {
            ctx.fill(ellipse(CGPoint(x: p.x, y: p.y + r * 0.28), r * 1.05, r * 0.55), with: .color(.black.opacity(0.28)))
            ctx.fill(ellipse(p, r, r), with: .radialGradient(
                Gradient(colors: [.white, Color(hex: 0xE6EDF2)]),
                center: CGPoint(x: p.x - r * 0.35, y: p.y - r * 0.4), startRadius: 0, endRadius: r * 1.4))
        }
        snowball(base, s)
        snowball(head, s * 0.68)
        let eye = s * 0.075
        for dx in [-1.0, 1.0] as [CGFloat] {
            ctx.fill(ellipse(CGPoint(x: head.x + dx * s * 0.25, y: head.y - s * 0.10), eye, eye), with: .color(Color(hex: 0x1B1B1B)))
        }
        var nose = Path()
        nose.move(to: CGPoint(x: head.x - s * 0.05, y: head.y + s * 0.02))
        nose.addLine(to: CGPoint(x: head.x + s * 0.60, y: head.y + s * 0.12))
        nose.addLine(to: CGPoint(x: head.x - s * 0.05, y: head.y + s * 0.16))
        nose.closeSubpath()
        ctx.fill(nose, with: .color(Color(hex: 0xE8791F)))
        for k in -2...2 {
            ctx.fill(ellipse(CGPoint(x: head.x + CGFloat(k) * s * 0.13, y: head.y + s * 0.31), eye * 0.8, eye * 0.8),
                     with: .color(Color(hex: 0x1B1B1B)))
        }
        ctx.fill(Path(roundedRect: CGRect(x: head.x - s * 0.72, y: base.y - s * 0.35, width: s * 1.44, height: s * 0.30),
                      cornerRadius: s * 0.12), with: .color(red))
        ctx.fill(ellipse(CGPoint(x: head.x, y: head.y - s * 0.62), s * 0.52, s * 0.12), with: .color(Color(hex: 0x181818)))
        ctx.fill(Path(CGRect(x: head.x - s * 0.34, y: head.y - s * 1.30, width: s * 0.68, height: s * 0.70)),
                 with: .color(Color(hex: 0x181818)))
        ctx.fill(Path(CGRect(x: head.x - s * 0.34, y: head.y - s * 0.78, width: s * 0.68, height: s * 0.13)),
                 with: .color(red))

        // ---- More of the season: a fir tree, parcels, holly and snow on the crown ----
        // All of these sit on the back or front rim, clear of the candle row through
        // the middle, so the flames never disappear into the decorations.
        func star(_ c: CGPoint, _ r: CGFloat, _ color: Color) {
            var path = Path()
            for k in 0..<10 {
                let ang = -CGFloat.pi / 2 + CGFloat(k) * CGFloat.pi / 5
                let rad = k % 2 == 0 ? r : r * 0.44
                let pt = CGPoint(x: c.x + cos(ang) * rad, y: c.y + sin(ang) * rad)
                if k == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
            }
            path.closeSubpath()
            ctx.fill(path, with: .radialGradient(Gradient(colors: [.white, color]),
                center: c, startRadius: 0, endRadius: r * 1.25))
        }

        // A small layered fir at the back-left, balancing the snowman on the right.
        func fir(_ p: CGPoint, _ s: CGFloat) {
            let trunkH = s * 0.26
            ctx.fill(Path(CGRect(x: p.x - s * 0.08, y: p.y - trunkH, width: s * 0.16,
                                 height: trunkH + s * 0.14)), with: .color(Color(hex: 0x8B5A2B)))
            for tier in 0..<3 {
                let baseY = p.y - trunkH - s * 0.08 - CGFloat(tier) * s * 0.30
                let halfW = s * (0.48 - CGFloat(tier) * 0.11)
                var t = Path()
                t.move(to: CGPoint(x: p.x, y: baseY - s * 0.44))
                t.addLine(to: CGPoint(x: p.x - halfW, y: baseY))
                t.addQuadCurve(to: CGPoint(x: p.x + halfW, y: baseY),
                               control: CGPoint(x: p.x, y: baseY + s * 0.12))
                t.addLine(to: CGPoint(x: p.x, y: baseY - s * 0.44))
                t.closeSubpath()
                ctx.fill(t, with: .linearGradient(Gradient(colors: [lit, green, deep]),
                    startPoint: CGPoint(x: p.x - halfW, y: baseY - s * 0.4),
                    endPoint: CGPoint(x: p.x + halfW, y: baseY)))
                for k in -1...1 {
                    let dot = CGPoint(x: p.x + CGFloat(k) * halfW * 0.55, y: baseY - s * 0.12)
                    ctx.fill(ellipse(dot, s * 0.032, s * 0.032), with: .color(k == 0 ? gold : Color(hex: 0xFFE9A4)))
                }
            }
            star(CGPoint(x: p.x, y: p.y - trunkH - s * 0.92), s * 0.13, gold)
        }

        // Tiny wrapped parcels with a ribbon cross and a bow.
        func parcel(_ p: CGPoint, _ s: CGFloat, _ ribbon: Color, _ paper: Color) {
            let box = CGRect(x: p.x - s * 0.5, y: p.y - s * 0.34, width: s, height: s * 0.68)
            ctx.fill(Path(box.offsetBy(dx: 0, dy: s * 0.05)), with: .color(.black.opacity(0.22)))
            ctx.fill(Path(box), with: .linearGradient(Gradient(colors: [paper, paper.opacity(0.78)]),
                startPoint: CGPoint(x: box.minX, y: box.minY), endPoint: CGPoint(x: box.maxX, y: box.maxY)))
            ctx.fill(Path(CGRect(x: p.x - s * 0.5, y: p.y - s * 0.46, width: s, height: s * 0.14)),
                     with: .color(paper.opacity(0.9)))
            ctx.fill(Path(CGRect(x: p.x - s * 0.085, y: p.y - s * 0.46, width: s * 0.17, height: s * 1.0)),
                     with: .color(ribbon))
            ctx.fill(Path(CGRect(x: p.x - s * 0.5, y: p.y - s * 0.09, width: s, height: s * 0.12)),
                     with: .color(ribbon))
            for side in [-1.0, 1.0] as [CGFloat] {
                ctx.fill(ellipse(CGPoint(x: p.x + side * s * 0.16, y: p.y - s * 0.55), s * 0.15, s * 0.10),
                         with: .color(ribbon))
            }
        }

        // Holly leaves with three glossy red berries.
        func holly(_ c: CGPoint, _ s: CGFloat) {
            for side in [-1.0, 1.0] as [CGFloat] {
                var leaf = Path()
                leaf.move(to: c)
                leaf.addQuadCurve(to: CGPoint(x: c.x + side * s, y: c.y - s * 0.26),
                                  control: CGPoint(x: c.x + side * s * 0.5, y: c.y - s * 0.7))
                leaf.addQuadCurve(to: c,
                                  control: CGPoint(x: c.x + side * s * 0.74, y: c.y + s * 0.24))
                ctx.fill(leaf, with: .linearGradient(Gradient(colors: [lit, deep]),
                    startPoint: c, endPoint: CGPoint(x: c.x + side * s, y: c.y - s * 0.2)))
            }
            for (dx, dy) in [(-0.20, -0.02), (0.20, -0.02), (0, -0.26)] as [(CGFloat, CGFloat)] {
                let b = CGPoint(x: c.x + dx * s, y: c.y + dy * s)
                ctx.fill(ellipse(b, s * 0.16, s * 0.16), with: .radialGradient(
                    Gradient(colors: [Color(hex: 0xFF8A8A), red]),
                    center: CGPoint(x: b.x - s * 0.05, y: b.y - s * 0.05),
                    startRadius: 0, endRadius: s * 0.22))
            }
        }

        fir(crown(0.68, .pi * 1.26), w * 0.17)
        parcel(crown(0.80, .pi * 0.94), w * 0.085, red, Color(hex: 0xF3E7C8))
        parcel(crown(0.82, .pi * 1.06), w * 0.075, gold, Color(hex: 0xF6EFE2))
        holly(crown(0.90, .pi * 0.14), w * 0.075)
        holly(crown(0.90, .pi * 0.86), w * 0.075)

        // Scattered sugar "snow" specks catch the light across the crown.
        var snowRng = SeededRandom(seed: tierSeed(1215))
        for _ in 0..<26 {
            let r = snowRng.range(0.22, 0.92), phi = snowRng.range(0, 2 * .pi)
            let p = crown(r, phi)
            let rr = w * snowRng.range(0.004, 0.009)
            ctx.fill(ellipse(p, rr, rr), with: .color(.white.opacity(snowRng.range(0.35, 0.75))))
        }
    }

    // MARK: - Halloween

    /// A midnight-chocolate cake under a burnt-orange ganache, cobwebs on the wall,
    /// and a little midnight scene on the crown: a carved pumpkin, ghosts, a tombstone
    /// and a spider. Dense and moody rather than a scatter of random sweets.
    func halloween(_ ctx: GraphicsContext) {
        sharedStand(ctx)
        let orange = Color(hex: 0xE8791F), orangeDeep = Color(hex: 0xA94A0C), orangeLit = Color(hex: 0xFFB65C)
        let cocoa = Color(hex: 0x3A2118), cream = Color(hex: 0xF6E6C8)
        let purple = Color(hex: 0x5E3478), web = Color(hex: 0xD8C7A8)

        fillSide(ctx, edge: Color(hex: 0x24130D), centre: cocoa)
        var c = ctx
        c.clip(to: sidePath)
        var rng = SeededRandom(seed: tierSeed(404))
        for _ in 0..<180 {
            let p = side(rng.range(-1.5, 1.5), rng.range(0, 1.03))
            c.fill(ellipse(p, rng.range(0.5, 1.3) * u, rng.range(0.4, 1.0) * u), with: .color(.black.opacity(0.28)))
        }
        // cobweb strands strung across the upper wall
        for anchor in [-1.35, -0.45, 0.45, 1.35] as [CGFloat] {
            for j in 0..<5 {
                let v0: CGFloat = 0.06 + CGFloat(j) * 0.03
                let v1: CGFloat = 0.30 + CGFloat(j) * 0.06
                var strand = Path()
                strand.move(to: side(anchor, v0))
                strand.addQuadCurve(to: side(anchor + (anchor < 0 ? 0.55 : -0.55), v1),
                                    control: side(anchor + (anchor < 0 ? 0.30 : -0.30), (v0 + v1) / 2 + 0.03))
                c.stroke(strand, with: .color(web.opacity(0.20)), lineWidth: 0.8 * u)
            }
        }
        styledLettering(ctx)
        shadeSide(ctx, strength: 0.9)
        ganache(ctx, color: orange, shine: orangeLit.opacity(0.5), seed: tierSeed(40))
        fillTop(ctx, orangeDeep, sheen: 0.16)

        func on(_ r: CGFloat, _ deg: CGFloat, lift: CGFloat = 0) -> CGPoint {
            let p = crown(r, deg * .pi / 180); return CGPoint(x: p.x, y: p.y - lift)
        }

        // carved jack-o'-lantern, the centrepiece, seated on the top
        func pumpkin(_ p: CGPoint, _ s: CGFloat, carved: Bool = false) {
            ctx.fill(ellipse(CGPoint(x: p.x, y: p.y + s * 0.22), s * 1.02, s * 0.5), with: .color(.black.opacity(0.3)))
            for dx in [-0.46, 0, 0.46] as [CGFloat] {
                ctx.fill(ellipse(CGPoint(x: p.x + dx * s, y: p.y), s * 0.46, s * 0.92),
                         with: .radialGradient(Gradient(colors: [orangeLit, orange, orangeDeep]),
                            center: CGPoint(x: p.x + dx * s - s * 0.16, y: p.y - s * 0.32), startRadius: 0, endRadius: s * 1.15))
            }
            ctx.fill(Path(CGRect(x: p.x - s * 0.07, y: p.y - s * 1.16, width: s * 0.14, height: s * 0.35)),
                     with: .color(greenStem))
            if carved {
                // glowing triangular eyes and a jagged grin
                let glow = Color(hex: 0xFFE08A)
                for sgn in [-1.0, 1.0] as [CGFloat] {
                    var eye = Path()
                    eye.move(to: CGPoint(x: p.x + sgn * s * 0.42, y: p.y - s * 0.22))
                    eye.addLine(to: CGPoint(x: p.x + sgn * s * 0.12, y: p.y - s * 0.02))
                    eye.addLine(to: CGPoint(x: p.x + sgn * s * 0.46, y: p.y + s * 0.02))
                    eye.closeSubpath()
                    ctx.fill(eye, with: .color(glow))
                }
                var mouth = Path()
                mouth.move(to: CGPoint(x: p.x - s * 0.52, y: p.y + s * 0.30))
                for k in 0...6 {
                    let x = p.x - s * 0.52 + s * 1.04 * CGFloat(k) / 6
                    mouth.addLine(to: CGPoint(x: x, y: p.y + s * (k % 2 == 0 ? 0.30 : 0.48)))
                }
                mouth.addLine(to: CGPoint(x: p.x + s * 0.40, y: p.y + s * 0.62))
                mouth.addLine(to: CGPoint(x: p.x - s * 0.40, y: p.y + s * 0.62))
                mouth.closeSubpath()
                ctx.fill(mouth, with: .color(glow))
            }
        }
        // a large carved pumpkin as the focal point, with a small one for scale
        pumpkin(on(0.34, -102, lift: w * 0.05), w * 0.19, carved: true)
        pumpkin(on(0.62, -52, lift: w * 0.02), w * 0.10, carved: false)

        // two little ghosts, with soft shading and tiny arms
        func ghost(_ p: CGPoint, _ s: CGFloat) {
            ctx.fill(ellipse(CGPoint(x: p.x, y: p.y + s * 0.34), s * 0.62, s * 0.28), with: .color(.black.opacity(0.28)))
            var body = Path()
            body.addArc(center: CGPoint(x: p.x, y: p.y - s * 0.10), radius: s * 0.56,
                        startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
            body.addLine(to: CGPoint(x: p.x + s * 0.56, y: p.y + s * 0.46))
            for k in 0..<4 {
                let x = p.x + s * 0.56 - CGFloat(k) * s * 0.28 - s * 0.14
                body.addQuadCurve(to: CGPoint(x: x - s * 0.14, y: p.y + s * 0.46),
                                  control: CGPoint(x: x, y: p.y + s * 0.66))
            }
            body.closeSubpath()
            ctx.fill(body, with: .radialGradient(Gradient(colors: [.white, cream, Color(hex: 0xCDBCA0)]),
                    center: CGPoint(x: p.x - s * 0.18, y: p.y - s * 0.28), startRadius: 0, endRadius: s * 1.25))
            ctx.fill(ellipse(CGPoint(x: p.x - s * 0.20, y: p.y - s * 0.10), s * 0.10, s * 0.14), with: .color(.black))
            ctx.fill(ellipse(CGPoint(x: p.x + s * 0.20, y: p.y - s * 0.10), s * 0.10, s * 0.14), with: .color(.black))
            ctx.fill(ellipse(CGPoint(x: p.x, y: p.y + s * 0.14), s * 0.11, s * 0.08), with: .color(.black.opacity(0.8)))
        }
        ghost(on(0.70, -158, lift: w * 0.13), w * 0.135)
        ghost(on(0.80, -18, lift: w * 0.03), w * 0.085)

        // a crooked tombstone at the back
        func tomb(_ p: CGPoint, _ s: CGFloat) {
            ctx.fill(Path(CGRect(x: p.x - s * 0.42, y: p.y - s * 0.62, width: s * 0.84, height: s * 0.70)),
                     with: .color(Color(hex: 0x8A857E)))
            ctx.fill(ellipse(CGPoint(x: p.x, y: p.y - s * 0.62), s * 0.42, s * 0.24),
                     with: .color(Color(hex: 0x8A857E)))
            ctx.fill(Path(CGRect(x: p.x - s * 0.42, y: p.y + s * 0.05, width: s * 0.84, height: s * 0.05)),
                     with: .color(.black.opacity(0.25)))
            for row in 0..<2 {
                ctx.fill(Path(CGRect(x: p.x - s * 0.18, y: p.y - s * 0.38 + CGFloat(row) * s * 0.18,
                                     width: s * 0.36, height: s * 0.05)), with: .color(Color(hex: 0x5F5A55)))
            }
        }
        tomb(on(0.64, 152, lift: w * 0.02), w * 0.235)

        // a spider dangling at the front with legs
        let sp = on(0.93, 68, lift: w * 0.14)
        var thread = Path(); thread.move(to: CGPoint(x: sp.x, y: sp.y - w * 0.16)); thread.addLine(to: sp)
        ctx.stroke(thread, with: .color(web.opacity(0.5)), lineWidth: 0.7 * u)
        let sr = w * 0.035
        ctx.fill(ellipse(sp, sr, sr * 0.85), with: .color(Color(hex: 0x201820)))
        ctx.fill(ellipse(CGPoint(x: sp.x - sr * 0.32, y: sp.y - sr * 0.2), sr * 0.12, sr * 0.12), with: .color(orangeLit))
        ctx.fill(ellipse(CGPoint(x: sp.x + sr * 0.32, y: sp.y - sr * 0.2), sr * 0.12, sr * 0.12), with: .color(orangeLit))
        for side in [-1.0, 1.0] as [CGFloat] {
            for k in 0..<4 {
                var leg = Path()
                leg.move(to: CGPoint(x: sp.x + side * sr * 0.6, y: sp.y))
                leg.addQuadCurve(to: CGPoint(x: sp.x + side * sr * (1.6 + CGFloat(k) * 0.25),
                                             y: sp.y - sr * 0.8 + CGFloat(k) * sr * 0.5),
                                 control: CGPoint(x: sp.x + side * sr * 1.5, y: sp.y - sr * 1.1 + CGFloat(k) * sr * 0.2))
                ctx.stroke(leg, with: .color(Color(hex: 0x201820)), style: StrokeStyle(lineWidth: 1.1 * u, lineCap: .round))
            }
        }

        // purple candy eyes peeking from the sugar around the base
        for (r, d) in [(0.88, -118), (0.93, 22), (0.86, 128), (0.95, -34)] as [(CGFloat, CGFloat)] {
            let p = on(r, d, lift: w * 0.02), rr = w * 0.028
            ctx.fill(ellipse(p, rr, rr), with: .radialGradient(Gradient(colors: [.white, purple]),
                    center: CGPoint(x: p.x - rr * 0.3, y: p.y - rr * 0.3), startRadius: 0, endRadius: rr * 1.4))
            ctx.fill(ellipse(p, rr * 0.42, rr * 0.5), with: .color(.black))
        }
    }
    private var greenStem: Color { Color(hex: 0x4E7A38) }

    // MARK: - Coming of Age (18)

    /// A clean white eighteenth cake. The whole feature is a large satin bow laid
    /// across the front of the crown, with a full metallic sheen, rolled loops, a
    /// wrapped knot and two trailing tails — pink for her, tailored navy for him.
    /// The "18" is a fixed number candle supplied by the model, never drawn here.
    /// A clean white eighteenth cake, built from the reference photograph:
    /// upright folded satin loops with white polka dots tied at the centre,
    /// embossed pink lettering on the wall, pearl piping, and a freestanding
    /// pink "18" on the board beside the cake.
    func comingOfAge(_ ctx: GraphicsContext, girl: Bool) {
        sharedStand(ctx, scalloped: girl)
        let white = Color(hex: 0xFFFDFB), whiteShade = Color(hex: 0xEDE3DC)
        let accent = girl ? Color(hex: 0xE58DAC) : Color(hex: 0x34518F)

        fillSide(ctx, edge: whiteShade, centre: white)
        var c = ctx
        c.clip(to: sidePath)
        var rng = SeededRandom(seed: tierSeed(girl ? 1801 : 1802))
        for _ in 0..<130 {
            let theta = rng.range(-1.5, 1.5), v = rng.range(0, 1.03)
            c.stroke(band(v, from: theta, to: theta + rng.range(0.01, 0.05)),
                     with: .color(.white.opacity(Double(rng.range(0.12, 0.34)))),
                     style: StrokeStyle(lineWidth: rng.range(1, 2.4) * u, lineCap: .round))
        }
        // Lady's cake: tonal cream polka dots pressed into the buttercream. They use
        // the cake's own cream and pale-pink palette and follow the wall's curve, so
        // the wall reads as a soft pattern rather than stuck-on decoration. The
        // lettering is drawn afterwards and stays crisp on top of them.
        if girl {
            let dotCream = Color(hex: 0xECDCC9)
            let dotPink  = Color(hex: 0xF2D8E1)
            let rows: [CGFloat] = [0.16, 0.34, 0.52, 0.70]
            let cols = 9
            for (row, v) in rows.enumerated() {
                for k in 0..<cols {
                    let theta = -1.34 + 2.68 * (CGFloat(k) + (row % 2 == 0 ? 0 : 0.5)) / CGFloat(cols)
                    let p = side(theta, v)
                    let squash = max(0.34, cos(theta))
                    let r = w * 0.021
                    let tint = (k + row) % 2 == 0 ? dotCream : dotPink
                    c.fill(ellipse(p, r * squash, r), with: .color(tint.opacity(0.92)))
                }
            }
        }
        let bandV: CGFloat = 0.90
        c.fill(Path(CGRect(x: cx - rx, y: top + h * bandV, width: rx * 2, height: h * (1 - bandV) + ry)),
               with: .color(accent.opacity(0.10)))
        c.stroke(band(bandV), with: .color(accent.opacity(0.45)), lineWidth: 1.2 * u)
        styledLettering(ctx)
        shadeSide(ctx, strength: 0.62)
        // The base reads as a tailored satin band instead of a pearl chain.
        if girl {
            shells(ctx, at: 1.0, count: 26, size: w * 0.042, light: white, dark: whiteShade, drop: -w * 0.010)
        } else {
            var rc = ctx
            rc.clip(to: sidePath)
            let ribbonV: CGFloat = 0.84
            rc.stroke(band(ribbonV), with: .linearGradient(
                Gradient(stops: [.init(color: Color(hex: 0x0F2A63), location: 0),
                                 .init(color: Color(hex: 0x1E3F8C), location: 0.45),
                                 .init(color: Color(hex: 0x0F2A63), location: 1)]),
                startPoint: CGPoint(x: cx, y: top + h * ribbonV - h * 0.08),
                endPoint: CGPoint(x: cx, y: top + h * ribbonV + h * 0.08)),
                       lineWidth: h * 0.15)
            rc.stroke(band(ribbonV - 0.082),
                      with: .color(Color(hex: 0xD9B25C).opacity(0.85)), lineWidth: 1.6 * u)
        }
        fillTop(ctx, white, sheen: 0.20)

        if !girl && isCrownTier {
        // ---- Gentleman cake: tailored shirt front with lapels and buttons ----
        // Only the crown wears the shirt; lower tiers keep the same white icing
        // and navy satin band so every layer belongs to the same cake.
        let blueDeep = Color(hex: 0x0F2A63)
        let blueMid  = Color(hex: 0x1E3F8C)
        let blueLit  = Color(hex: 0x3E66C6)

        // The front of the cake reads as a white dress shirt with folded navy lapels.
        // Only the front-facing half of the wall is covered, so the cake stays round.
        let shirtTop = top + h * 0.16
        let shirtBot = bottom - ry * 0.25
        var shirt = Path()
        shirt.move(to: CGPoint(x: cx - rx * 0.90, y: shirtTop))
        shirt.addLine(to: CGPoint(x: cx + rx * 0.90, y: shirtTop))
        shirt.addLine(to: CGPoint(x: cx + rx * 0.72, y: shirtBot))
        shirt.addQuadCurve(to: CGPoint(x: cx, y: shirtBot + ry * 0.28),
                           control: CGPoint(x: cx + rx * 0.36, y: shirtBot + ry * 0.38))
        shirt.addQuadCurve(to: CGPoint(x: cx - rx * 0.72, y: shirtBot),
                           control: CGPoint(x: cx - rx * 0.36, y: shirtBot + ry * 0.38))
        shirt.closeSubpath()
        ctx.fill(shirt, with: .linearGradient(
            Gradient(stops: [.init(color: Color(hex: 0xFFFFFF), location: 0),
                             .init(color: Color(hex: 0xF2F4F8), location: 0.55),
                             .init(color: Color(hex: 0xDCE2EC), location: 1)]),
            startPoint: CGPoint(x: cx, y: shirtTop), endPoint: CGPoint(x: cx, y: shirtBot)))
        ctx.stroke(shirt, with: .color(blueDeep.opacity(0.35)), lineWidth: 1.1 * u)

        // Two folded lapels: an outer navy wing and a lighter inner satin strip.
        for side in [-1.0, 1.0] as [CGFloat] {
            let p1 = CGPoint(x: cx + side * rx * 0.88, y: shirtTop - h * 0.02)
            let p2 = CGPoint(x: cx + side * rx * 0.12, y: shirtTop + h * 0.06)
            let p3 = CGPoint(x: cx + side * rx * 0.30, y: shirtBot - ry * 0.10)
            let p4 = CGPoint(x: cx + side * rx * 0.78, y: shirtBot - ry * 0.30)
            var lapel = Path()
            lapel.move(to: p1)
            lapel.addLine(to: p2)
            lapel.addLine(to: p3)
            lapel.addLine(to: p4)
            lapel.closeSubpath()
            ctx.fill(lapel, with: .linearGradient(
                Gradient(stops: [.init(color: blueLit, location: 0), .init(color: blueMid, location: 0.35),
                                 .init(color: blueDeep, location: 1)]),
                startPoint: p1, endPoint: p3))
            ctx.stroke(lapel, with: .color(blueDeep), lineWidth: 1.0 * u)
            // A white pinstripe along the inner fold keeps the tailored look crisp.
            var stripe = Path()
            stripe.move(to: CGPoint(x: cx + side * rx * 0.76, y: shirtTop + h * 0.01))
            stripe.addLine(to: CGPoint(x: cx + side * rx * 0.18, y: shirtTop + h * 0.07))
            stripe.addLine(to: CGPoint(x: cx + side * rx * 0.33, y: shirtBot - ry * 0.14))
            ctx.stroke(stripe, with: .color(.white.opacity(0.85)),
                       style: StrokeStyle(lineWidth: 2.0 * u, lineCap: .round))
        }

        // White placket and two fondant buttons.
        let placket = CGRect(x: cx - rx * 0.10, y: shirtTop + h * 0.02,
                             width: rx * 0.20, height: shirtBot - shirtTop - ry * 0.06)
        ctx.fill(Path(roundedRect: placket, cornerRadius: rx * 0.03),
                 with: .color(Color(hex: 0xF7F8FB)))
        ctx.stroke(Path(roundedRect: placket, cornerRadius: rx * 0.03),
                   with: .color(blueDeep.opacity(0.25)), lineWidth: 0.8 * u)
        for f in [0.30, 0.68] as [CGFloat] {
            let buttonY = shirtTop + (shirtBot - shirtTop) * f
            let rr = rx * 0.085
            let p = CGPoint(x: cx, y: buttonY)
            ctx.fill(ellipse(CGPoint(x: p.x, y: p.y + u * 1.2), rr, rr),
                     with: .color(.black.opacity(0.20)))
            ctx.fill(ellipse(p, rr, rr), with: .radialGradient(
                Gradient(stops: [.init(color: blueLit, location: 0),
                                 .init(color: blueMid, location: 0.55),
                                 .init(color: blueDeep, location: 1)]),
                center: CGPoint(x: p.x - rr * 0.3, y: p.y - rr * 0.35),
                startRadius: 0, endRadius: rr * 1.3))
            // four tiny holes
            for (dx, dy) in [(-0.30, -0.30), (0.30, -0.30), (-0.30, 0.30), (0.30, 0.30)] as [(CGFloat, CGFloat)] {
                ctx.fill(ellipse(CGPoint(x: p.x + dx * rr, y: p.y + dy * rr), rr * 0.10, rr * 0.10),
                         with: .color(blueDeep.opacity(0.85)))
            }
        }
        }
    }

    /// The bow itself, drawn in a foreground pass AFTER the number candles so the
    /// digits read as standing behind it, exactly like the reference photographs.
    func comingOfAgeBow(_ ctx: GraphicsContext, girl: Bool) {
        let S = w
        let satin: [Color] = girl
            ? [Color(hex: 0xFFEBF2), Color(hex: 0xFAC3D6), Color(hex: 0xF3A2BE), Color(hex: 0xE17DA2), Color(hex: 0xC65C88), Color(hex: 0x9E3D6A)]
            : [Color(hex: 0xB7C7E8), Color(hex: 0x7C96CF), Color(hex: 0x5372B3),
               Color(hex: 0x3A5896), Color(hex: 0x244079), Color(hex: 0x152A55)]
        if girl {
        // ---- The bow: two upright folded loops, tied exactly at their crossing ----
        // Scaled down and seated on the crown so the loops stay fully inside the
        // top face (never jut past the rim) and leave the digits clear above them.
        let BS = S * 0.78
        let knot = CGPoint(x: cx, y: top + ry * 0.42)
        for side in [-1.0, 1.0] as [CGFloat] {
            // short ribbon tail falling toward the front of the crown
            var tail = Path()
            tail.move(to: CGPoint(x: knot.x + side * BS * 0.03, y: knot.y))
            tail.addCurve(to: CGPoint(x: knot.x + side * BS * 0.27, y: knot.y + BS * 0.15),
                          control1: CGPoint(x: knot.x + side * BS * 0.12, y: knot.y + BS * 0.10),
                          control2: CGPoint(x: knot.x + side * BS * 0.26, y: knot.y + BS * 0.04))
            tail.addLine(to: CGPoint(x: knot.x + side * BS * 0.20, y: knot.y + BS * 0.19))
            tail.addLine(to: CGPoint(x: knot.x + side * BS * 0.13, y: knot.y + BS * 0.13))
            tail.closeSubpath()
            ctx.fill(tail.offsetBy(dx: 0, dy: BS * 0.010), with: .color(.black.opacity(0.22)))
            ctx.fill(tail, with: .linearGradient(
                Gradient(colors: [satin[2], satin[4]]),
                startPoint: CGPoint(x: knot.x, y: knot.y),
                endPoint: CGPoint(x: knot.x + side * BS * 0.28, y: knot.y + BS * 0.18)))

            // the upright folded loop: a broad triangular petal with a soft pointed tip
            let tip = CGPoint(x: knot.x + side * BS * 0.38, y: knot.y - BS * 0.46)
            let outer = CGPoint(x: knot.x + side * BS * 0.47, y: knot.y - BS * 0.04)
            var loop = Path()
            loop.move(to: knot)
            loop.addQuadCurve(to: tip, control: CGPoint(x: knot.x + side * BS * 0.14, y: knot.y - BS * 0.40))
            loop.addQuadCurve(to: outer, control: CGPoint(x: knot.x + side * BS * 0.52, y: knot.y - BS * 0.34))
            loop.addCurve(to: knot,
                          control1: CGPoint(x: knot.x + side * BS * 0.34, y: knot.y + BS * 0.07),
                          control2: CGPoint(x: knot.x + side * BS * 0.12, y: knot.y + BS * 0.05))
            loop.closeSubpath()
            ctx.fill(loop.offsetBy(dx: 0, dy: BS * 0.012), with: .color(.black.opacity(0.24)))
            ctx.fill(loop, with: .linearGradient(
                Gradient(stops: [.init(color: satin[0], location: 0), .init(color: satin[1], location: 0.24),
                                 .init(color: satin[2], location: 0.50), .init(color: satin[3], location: 0.72),
                                 .init(color: satin[5], location: 1)]),
                startPoint: CGPoint(x: knot.x + side * BS * 0.42, y: tip.y),
                endPoint: CGPoint(x: knot.x + side * BS * 0.08, y: knot.y + BS * 0.06)))
            ctx.stroke(loop, with: .color(satin[5].opacity(0.55)), lineWidth: 0.9 * u)

            // the turned-back inner fold, darker, gives the petal its satin crease
            var fold = Path()
            fold.move(to: knot)
            fold.addQuadCurve(to: CGPoint(x: knot.x + side * BS * 0.22, y: knot.y - BS * 0.30),
                              control: CGPoint(x: knot.x + side * BS * 0.10, y: knot.y - BS * 0.28))
            fold.addCurve(to: knot,
                          control1: CGPoint(x: knot.x + side * BS * 0.30, y: knot.y - BS * 0.02),
                          control2: CGPoint(x: knot.x + side * BS * 0.10, y: knot.y + BS * 0.02))
            fold.closeSubpath()
            ctx.fill(fold, with: .linearGradient(Gradient(colors: [satin[3], satin[5]]),
                startPoint: CGPoint(x: knot.x + side * BS * 0.20, y: knot.y - BS * 0.28), endPoint: knot))

            // white fondant polka dots scattered over the petal
            for (fx, fy, fr) in [(0.30, -0.30, 0.046), (0.18, -0.16, 0.036),
                                 (0.40, -0.15, 0.042), (0.27, -0.06, 0.030)] as [(CGFloat, CGFloat, CGFloat)] {
                let p = CGPoint(x: knot.x + side * BS * fx, y: knot.y + BS * fy)
                ctx.fill(ellipse(p, BS * fr, BS * fr), with: .radialGradient(
                    Gradient(colors: [.white, Color(hex: 0xF3E7EC)]),
                    center: CGPoint(x: p.x - BS * fr * 0.3, y: p.y - BS * fr * 0.3),
                    startRadius: 0, endRadius: BS * fr * 1.3))
            }
        }

        // wrapped knot exactly where the two loops cross
        let kw = BS * 0.062, kh = BS * 0.052
        let knotRect = CGRect(x: knot.x - kw, y: knot.y - kh, width: kw * 2, height: kh * 2)
        ctx.fill(Path(roundedRect: knotRect.offsetBy(dx: 0, dy: BS * 0.008), cornerRadius: kw * 0.5),
                 with: .color(.black.opacity(0.28)))
        let kf = Path(roundedRect: knotRect, cornerRadius: kw * 0.5)
        ctx.fill(kf, with: .linearGradient(
            Gradient(stops: [.init(color: satin[0], location: 0), .init(color: satin[2], location: 0.45),
                             .init(color: satin[4], location: 1)]),
            startPoint: CGPoint(x: knot.x - kw, y: knot.y - kh),
            endPoint: CGPoint(x: knot.x + kw, y: knot.y + kh)))
        ctx.stroke(kf, with: .color(satin[5].opacity(0.55)), lineWidth: 0.8 * u)

        // pearls along the remaining crown
        for (r, d) in [(0.88, -150), (0.90, -58), (0.88, 58), (0.84, 150)] as [(CGFloat, CGFloat)] {
            let p = crown(r, d * .pi / 180)
            ctx.fill(ellipse(p, w * 0.014, w * 0.014),
                     with: .radialGradient(Gradient(colors: [.white, Color(hex: 0xEAD9DA)]),
                        center: CGPoint(x: p.x - u, y: p.y - u), startRadius: 0, endRadius: w * 0.017))
        }
        } else {
        // ---- Fondant bow tie: a stiff rolled sheet of royal-blue fondant ----
        // Unlike fabric, fondant holds a crisp cut edge, shows real thickness,
        // and catches light as a soft matte sheen with tool-pressed folds.
        let knot = CGPoint(x: cx, y: top + ry * 0.36)
        let fondantDeep = Color(hex: 0x0A1E4C)
        let fondantMid  = Color(hex: 0x173488)
        let fondantLit  = Color(hex: 0x3561B4)
        let fondantEdge = Color(hex: 0x060F2E)
        let fondantGlow = Color(hex: 0x8EAEE8)

        for side in [-1.0, 1.0] as [CGFloat] {
            let inner = knot.x + side * S * 0.050
            let outer = knot.x + side * S * 0.50
            // A fan-like wing: pinched at the knot, flaring to a near-straight
            // vertical cut at the outer edge, with a high outer top corner.
            var wing = Path()
            wing.move(to: CGPoint(x: inner, y: knot.y - S * 0.050))
            wing.addCurve(to: CGPoint(x: outer, y: knot.y - S * 0.215),
                          control1: CGPoint(x: inner + side * S * 0.12, y: knot.y - S * 0.11),
                          control2: CGPoint(x: outer - side * S * 0.09, y: knot.y - S * 0.24))
            wing.addQuadCurve(to: CGPoint(x: outer + side * S * 0.006, y: knot.y + S * 0.03),
                              control: CGPoint(x: outer + side * S * 0.018, y: knot.y - S * 0.05))
            wing.addQuadCurve(to: CGPoint(x: outer - side * S * 0.012, y: knot.y + S * 0.175),
                              control: CGPoint(x: outer + side * S * 0.012, y: knot.y + S * 0.11))
            wing.addCurve(to: CGPoint(x: inner, y: knot.y + S * 0.060),
                          control1: CGPoint(x: outer - side * S * 0.12, y: knot.y + S * 0.19),
                          control2: CGPoint(x: inner + side * S * 0.12, y: knot.y + S * 0.13))
            wing.closeSubpath()

            // The cut side of the fondant sheet: its thickness below the face.
            ctx.fill(wing.offsetBy(dx: 0, dy: S * 0.016), with: .color(fondantEdge.opacity(0.88)))
            ctx.fill(wing, with: .linearGradient(
                Gradient(stops: [.init(color: fondantMid, location: 0),
                                 .init(color: fondantLit, location: 0.34),
                                 .init(color: fondantMid, location: 0.62),
                                 .init(color: fondantDeep, location: 1)]),
                startPoint: CGPoint(x: inner, y: knot.y - S * 0.19),
                endPoint: CGPoint(x: outer, y: knot.y + S * 0.18)))
            ctx.stroke(wing, with: .color(fondantEdge.opacity(0.45)), lineWidth: 0.8 * u)

            // A broad, low-contrast wash: fondant is matte, so light spreads
            // instead of forming the narrow mirror band a fabric bow would show.
            var wash = Path()
            wash.move(to: CGPoint(x: inner + side * S * 0.07, y: knot.y - S * 0.075))
            wash.addCurve(to: CGPoint(x: outer - side * S * 0.04, y: knot.y - S * 0.15),
                          control1: CGPoint(x: inner + side * S * 0.18, y: knot.y - S * 0.14),
                          control2: CGPoint(x: outer - side * S * 0.13, y: knot.y - S * 0.17))
            wash.addCurve(to: CGPoint(x: outer - side * S * 0.05, y: knot.y + S * 0.015),
                          control1: CGPoint(x: outer - side * S * 0.01, y: knot.y - S * 0.055),
                          control2: CGPoint(x: outer - side * S * 0.02, y: knot.y - S * 0.01))
            wash.addCurve(to: CGPoint(x: inner + side * S * 0.09, y: knot.y + S * 0.005),
                          control1: CGPoint(x: inner + side * S * 0.20, y: knot.y - S * 0.005),
                          control2: CGPoint(x: inner + side * S * 0.14, y: knot.y - S * 0.01))
            wash.closeSubpath()
            ctx.fill(wash, with: .linearGradient(
                Gradient(stops: [.init(color: fondantGlow.opacity(0.0), location: 0),
                                 .init(color: fondantGlow.opacity(0.30), location: 0.42),
                                 .init(color: fondantGlow.opacity(0.0), location: 1)]),
                startPoint: CGPoint(x: inner, y: knot.y - S * 0.12),
                endPoint: CGPoint(x: outer, y: knot.y + S * 0.06)))

            // Three pressed folds fanning from the knot: a dark crease with a
            // pale ridge just above it, the way a modelling tool marks fondant.
            for (lift, weight) in [(-0.02, 1.0), (0.06, 0.85), (0.13, 0.65)] as [(CGFloat, CGFloat)] {
                var fold = Path()
                fold.move(to: CGPoint(x: inner + side * S * 0.01, y: knot.y))
                fold.addCurve(to: CGPoint(x: outer - side * S * 0.03, y: knot.y + S * lift),
                              control1: CGPoint(x: inner + side * S * 0.16, y: knot.y + S * lift * 0.2),
                              control2: CGPoint(x: outer - side * S * 0.14, y: knot.y + S * lift * 0.95))
                ctx.stroke(fold, with: .color(fondantDeep.opacity(0.38 * weight)),
                           style: StrokeStyle(lineWidth: S * 0.016 * weight, lineCap: .round))
                ctx.stroke(fold.offsetBy(dx: 0, dy: -S * 0.014),
                           with: .color(fondantGlow.opacity(0.24 * weight)),
                           style: StrokeStyle(lineWidth: S * 0.009 * weight, lineCap: .round))
            }
        }

        // Centre knot: a plump rolled cylinder of fondant — the band that wraps
        // the middle — with rounded ends and a soft top-lit bulge.
        let kw = S * 0.19, kh = S * 0.135
        let kr = CGRect(x: knot.x - kw * 0.5, y: knot.y - kh * 0.5, width: kw, height: kh)
        let kf = Path(roundedRect: kr, cornerRadius: kw * 0.42)
        ctx.fill(kf.offsetBy(dx: 0, dy: S * 0.018), with: .color(fondantEdge.opacity(0.9)))
        ctx.fill(kf, with: .linearGradient(
            Gradient(stops: [.init(color: fondantDeep, location: 0),
                             .init(color: fondantMid, location: 0.16),
                             .init(color: fondantLit, location: 0.40),
                             .init(color: fondantMid, location: 0.72),
                             .init(color: fondantDeep, location: 1)]),
            startPoint: CGPoint(x: kr.minX, y: knot.y),
            endPoint: CGPoint(x: kr.maxX, y: knot.y)))
        ctx.stroke(kf, with: .color(fondantEdge.opacity(0.55)), lineWidth: 0.9 * u)
        // the two rolled ends catching a highlight, like a wrapped fondant band
        for s in [-1.0, 1.0] as [CGFloat] {
            var endHi = Path()
            endHi.move(to: CGPoint(x: knot.x + s * kw * 0.30, y: kr.minY + kh * 0.14))
            endHi.addQuadCurve(to: CGPoint(x: knot.x + s * kw * 0.30, y: kr.maxY - kh * 0.14),
                               control: CGPoint(x: knot.x + s * kw * 0.40, y: knot.y))
            ctx.stroke(endHi, with: .color(fondantGlow.opacity(0.35)),
                       style: StrokeStyle(lineWidth: S * 0.012, lineCap: .round))
        }
        }
    }


}
