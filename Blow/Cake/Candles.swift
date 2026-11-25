import SwiftUI

/// Wax candle (stick or number) with its wick.
struct CandleBody: View {
    let kind: CandleKind
    let style: CandleStyle
    let slot: CakeLayout.Slot
    let burn: Double
    /// seconds since it went out, nil while burning / unlit
    let emberAge: Double?
    /// which candle on the cake this is; party candles come in turns of colour
    var index: Int = 0

    static let party = [0xFF5C93, 0x4BA3FF, 0xFFC531, 0x3CCBA9, 0xA883FF, 0xFF8552].map { Color(hex: $0) }
    private static let goldLeaf = Color(hex: 0xE2B84E)

    var body: some View {
        switch kind {
        case .stick: stick
        case .digit(let ch): digit(ch)
        }
    }

    private var stick: some View {
        let visible = slot.height * (1 - CGFloat(burn))
        let wickRoom = slot.width * 0.55
        let bw = slot.width * style.girth
        let frame = CGSize(width: max(bw, slot.width) * 1.5, height: visible + wickRoom)
        return Canvas { ctx, size in
            let u = slot.width / 9
            let body = CGRect(x: (size.width - bw) / 2, y: wickRoom, width: bw, height: visible)
            let shape = Path(roundedRect: body, cornerRadius: bw * 0.28)
            ctx.fill(shape, with: .linearGradient(
                Gradient(stops: [.init(color: style.wax[1], location: 0), .init(color: style.wax[0], location: 0.32),
                                 .init(color: style.wax[0], location: 0.55), .init(color: style.wax[1], location: 1)]),
                startPoint: CGPoint(x: body.minX, y: 0), endPoint: CGPoint(x: body.maxX, y: 0)))

            var c = ctx
            c.clip(to: shape)
            // patterns are anchored to the foot, so they stay put as the candle burns down
            switch style {
            case .twist:
                let tone = Self.party[index % Self.party.count]
                var y = body.maxY + bw
                while y > body.minY - bw {
                    var p = Path()
                    p.move(to: CGPoint(x: body.minX - 1, y: y))
                    p.addLine(to: CGPoint(x: body.maxX + 1, y: y - bw * 1.1))
                    c.stroke(p, with: .color(tone), lineWidth: bw * 0.42)
                    y -= bw * 1.45
                }
            case .beeswax:
                var y = body.maxY + bw
                while y > body.minY - bw {
                    for lean in [-1.0, 1.0] as [CGFloat] {
                        var p = Path()
                        p.move(to: CGPoint(x: body.minX - 1, y: y))
                        p.addLine(to: CGPoint(x: body.maxX + 1, y: y + lean * bw * 0.9))
                        c.stroke(p, with: .color(Color(hex: 0x8A5A14, opacity: 0.38)), lineWidth: max(0.5, 0.7 * u))
                    }
                    y -= bw * 0.5
                }
            case .stardust:
                var rng = SeededRandom(seed: UInt64(index) &* 31 &+ 7)
                for _ in 0..<Int(slot.height / max(bw, 1) * 2.2) {
                    let p = CGPoint(x: body.minX + rng.unit() * bw, y: body.maxY - rng.unit() * slot.height)
                    let r = rng.range(0.4, 1.1) * u
                    c.fill(Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r, width: r * 2, height: r * 2)), with: .color(Self.goldLeaf))
                }
            case .altar:
                for (lift, thick) in [(2.4, 0.5), (3.2, 0.22), (1.9, 0.22)] as [(CGFloat, CGFloat)] {
                    c.fill(Path(CGRect(x: body.minX, y: body.maxY - bw * lift, width: bw, height: bw * thick)), with: .color(Self.goldLeaf))
                }
            case .pearl:
                // an opalescent sheen down one side, cool lilac into warm cream
                c.fill(Path(body), with: .linearGradient(Gradient(colors: [.clear, Color(hex: 0xD9C6EC, opacity: 0.5), Color(hex: 0xF3B8C4, opacity: 0.5)]),
                                                         startPoint: CGPoint(x: body.minX, y: body.maxY - slot.height * 0.8), endPoint: CGPoint(x: body.maxX, y: body.maxY)))
                var y = body.maxY
                while y > body.minY - bw {
                    c.fill(Path(ellipseIn: CGRect(x: body.midX - bw * 0.22, y: y - bw * 0.10,
                                                  width: bw * 0.44, height: bw * 0.20)), with: .color(.white.opacity(0.5)))
                    y -= bw * 0.7
                }
            case .gilded:
                // bright gold bands wrapped around a honey-coloured candle
                for (lift, thick) in [(1.3, 0.16), (2.4, 0.10), (3.6, 0.16)] as [(CGFloat, CGFloat)] {
                    let yy = body.maxY - bw * lift
                    if yy > body.minY {
                        c.fill(Path(CGRect(x: body.minX, y: yy, width: bw, height: bw * thick)), with: .color(Self.goldLeaf))
                    }
                }
                c.fill(Path(CGRect(x: body.minX + bw * 0.62, y: body.minY, width: bw * 0.12, height: body.height)), with: .color(.white.opacity(0.25)))
            case .candy:
                // liquorice: bold diagonal candy stripes in two reds
                var y = body.maxY + bw
                while y > body.minY - bw {
                    var p = Path()
                    p.move(to: CGPoint(x: body.minX - 1, y: y))
                    p.addLine(to: CGPoint(x: body.maxX + 1, y: y - bw * 1.2))
                    c.stroke(p, with: .color(Color(hex: 0xFFD9DE, opacity: 0.85)), lineWidth: bw * 0.34)
                    y -= bw * 1.7
                }
                c.fill(Path(CGRect(x: body.minX + bw * 0.18, y: body.minY, width: bw * 0.10, height: body.height)), with: .color(.white.opacity(0.35)))
            case .midnight:
                // deep indigo with a single fine gold pinstripe and tiny stars
                for lift in [CGFloat(1.4), 2.6, 3.9] {
                    let yy = body.maxY - bw * lift
                    if yy > body.minY, yy < body.maxY {
                        c.fill(Path(CGRect(x: body.minX + bw * 0.46, y: yy, width: bw * 0.08, height: bw * 0.5)), with: .color(Self.goldLeaf))
                    }
                }
                var srng = SeededRandom(seed: UInt64(index) &* 17 &+ 5)
                for _ in 0..<8 {
                    let px = body.minX + srng.range(0.15, 0.8) * bw
                    let py = body.maxY - srng.unit() * min(slot.height, body.height)
                    let r = 0.6 * u
                    c.fill(Path(ellipseIn: CGRect(x: px - r, y: py - r, width: r * 2, height: r * 2)),
                           with: .color(Color(hex: 0xFFE9A8, opacity: 0.9)))
                }
            }
            // the light catching one edge
            c.fill(Path(CGRect(x: body.minX + bw * 0.22, y: body.minY, width: max(0.8, bw * (style == .gilded ? 0.16 : 0.10)), height: body.height)),
                   with: .color(.white.opacity(style == .gilded ? 0.75 : 0.4)))
            // warm melt at the top
            c.fill(Path(CGRect(x: body.minX, y: body.minY, width: bw, height: min(visible, bw * 2.6))),
                   with: .linearGradient(Gradient(colors: [Theme.glow.opacity(0.6), .clear]),
                                         startPoint: CGPoint(x: 0, y: body.minY), endPoint: CGPoint(x: 0, y: body.minY + min(visible, bw * 2.6))))
            if style == .altar || style == .beeswax {
                // a run of wax down one side
                let x = body.minX + bw * 0.74, len = min(visible * 0.5, bw * 3.2)
                var drip = Path()
                drip.addRoundedRect(in: CGRect(x: x - bw * 0.11, y: body.minY, width: bw * 0.22, height: len), cornerSize: CGSize(width: bw * 0.11, height: bw * 0.11))
                drip.addEllipse(in: CGRect(x: x - bw * 0.16, y: body.minY + len - bw * 0.3, width: bw * 0.32, height: bw * 0.36))
                c.fill(drip, with: .color(style.wax[0]))
            }

            // wick
            let ww = max(1.2, slot.width * 0.13), wh = slot.width * 0.6
            let wick = CGRect(x: (size.width - ww) / 2, y: wickRoom - wh * 0.92, width: ww, height: wh)
            ctx.fill(Path(roundedRect: wick, cornerRadius: ww / 2), with: .color(Color(red: 0.12, green: 0.09, blue: 0.08)))
            let ember = emberAge.map { max(0, 1 - $0 / 1.8) } ?? 0
            if ember > 0 {
                var e = ctx
                e.addFilter(.blur(radius: 1))
                e.fill(Path(ellipseIn: CGRect(x: wick.midX - ww * 0.8, y: wick.minY - ww * 0.3, width: ww * 1.6, height: ww * 1.6)),
                       with: .color(Color(red: 1.0, green: 0.35, blue: 0.12).opacity(ember)))
            }
        }
        .frame(width: frame.width, height: frame.height)
        .position(x: slot.x, y: slot.y - frame.height / 2)
        .allowsHitTesting(false)
    }

    private func digit(_ ch: Character) -> some View {
        let fontSize = slot.height * 1.28
        // Coming-of-age digits: warm metallic gold for him, rose for her, each
        // set with little studs like the reference cakes.
        let isGentleman = style == .midnight
        let face: [Color] = isGentleman
            ? [Color(hex: 0xFFF1C4), Color(hex: 0xE4B95C), Color(hex: 0xA9781F)]
            : [Color(hex: 0xFFC6D9), Color(hex: 0xE17DA2), Color(hex: 0xB84C7B)]
        let stud = isGentleman ? Color(hex: 0xF6D98A) : Color(hex: 0xE9C46A)
        return ZStack(alignment: .top) {
            ZStack {
                Text(String(ch))
                    .font(.system(size: fontSize, weight: .heavy, design: .serif))
                    .foregroundStyle(LinearGradient(colors: face, startPoint: .top, endPoint: .bottom))
                    .overlay(
                        Text(String(ch))
                            .font(.system(size: fontSize, weight: .heavy, design: .serif))
                            .foregroundStyle(LinearGradient(colors: [stud.opacity(0.9), stud.opacity(0.25)],
                                                            startPoint: .top, endPoint: .bottom))
                            .mask(LinearGradient(colors: [.white, .clear, .white],
                                                 startPoint: .top, endPoint: .bottom))
                            .opacity(0.35)
                    )
                    .shadow(color: .black.opacity(0.35), radius: 1.5, y: 1)
                    .shadow(color: Theme.glow.opacity(0.30), radius: 4, y: -2)
                // scattered gold studs, positioned in numeral-local fractions
                ForEach([(0.30, 0.30), (0.68, 0.34), (0.46, 0.58), (0.28, 0.74), (0.72, 0.78)] as [(CGFloat, CGFloat)], id: \.0) { fx, fy in
                    let studColours: [Color] = isGentleman
                        ? [Color(hex: 0xFFF6D8), Color(hex: 0xC99A3B), Color(hex: 0x8A631C)]
                        : [Color(hex: 0xFFF0C8), stud, Color(hex: 0xA97B2C)]
                    Circle()
                        .fill(RadialGradient(colors: studColours,
                                             center: .topLeading, startRadius: 0, endRadius: slot.width * 0.055))
                        .frame(width: slot.width * 0.10, height: slot.width * 0.10)
                        .offset(x: (fx - 0.5) * slot.width * 0.85, y: (fy - 0.5) * slot.height * 0.92)
                }
            }
            .fixedSize()
            .offset(y: fontSize * 0.2)
            .frame(width: slot.width * 1.3, height: slot.height, alignment: .bottom)
            Capsule()
                .fill(Color(red: 0.12, green: 0.09, blue: 0.08))
                .overlay(alignment: .top) {
                    Circle()
                        .fill(Color(red: 1.0, green: 0.35, blue: 0.12))
                        .frame(width: 3.2, height: 3.2)
                        .blur(radius: 1)
                        .opacity(emberAge.map { max(0, 1 - $0 / 1.8) } ?? 0)
                }
                .frame(width: 2, height: slot.width * 0.12)
                .offset(y: -slot.width * 0.08)
        }
        .frame(width: slot.width * 1.3, height: slot.height)
        .position(x: slot.x, y: slot.y - slot.height / 2)
    }
}

/// A still life of the cake for the setup screen, the thumbnails and the memory card.
struct CakePreview: View {
    let birthday: Birthday
    var flicker: Bool = true
    /// Turned off when an interactive sticker canvas draws them instead.
    var showsStickers: Bool = true

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let kinds = birthday.candleKinds
            let layout = CakeLayout(size: size, kinds: kinds, candle: birthday.candle, tiers: birthday.tiers, cakeStyle: birthday.cake)
            ZStack(alignment: .topLeading) {
                RoomGlow(layout: layout, light: 1)
                CakeCanvas(layout: layout, style: birthday.cake, text: birthday.cakeText, textEdit: birthday.textEdit, topper: birthday.topper)
                    .equatable()
                if showsStickers {
                    StickerLayer(placements: birthday.stickers, size: size, floating: flicker)
                }
                do {
                    ForEach(kinds.indices, id: \.self) { i in
                        CandleBody(kind: kinds[i], style: birthday.candle, slot: layout.slots[i], burn: 0, emberAge: nil, index: i)
                    }
                    CakeFrontDecor(layout: layout, style: birthday.cake)
                        .equatable()
                    TimelineView(.animation(minimumInterval: 1.0 / 30, paused: !flicker)) { timeline in
                        let t = timeline.date.timeIntervalSinceReferenceDate
                        ZStack(alignment: .topLeading) {
                            ForEach(kinds.indices, id: \.self) { i in
                                let fs = layout.flameSize(layout.slots[i], kind: kinds[i])
                                let wick = layout.wickTop(layout.slots[i], kind: kinds[i], burn: 0)
                                StillFlame(size: CGSize(width: fs.width * 0.40, height: fs.height * 0.66),
                                           phase: flicker ? t * 6 + Double(i) * 1.7 : Double(i),
                                           halo: min(1, 4.5 / Double(kinds.count)))
                                    .position(x: wick.x, y: wick.y - fs.height * 0.30)
                            }
                        }
                        .frame(width: size.width, height: size.height)
                    }
                }
            }
            .frame(width: size.width, height: size.height)
        }
    }
}

/// The warmth the candles put into the room behind the cake. Fades out before the edges of
/// its frame, so the stage never shows as a box.
struct RoomGlow: View {
    let layout: CakeLayout
    let light: Double

    var body: some View {
        let size = layout.size
        let centre = CGPoint(x: layout.centerX, y: layout.topY - layout.cakeWidth * 0.22)
        let reach = max(1, min(layout.cakeWidth * 0.98, centre.y, size.width - centre.x, centre.x, size.height - centre.y))
        RadialGradient(colors: [Theme.ember.opacity(0.30 * light), Theme.ember.opacity(0.07 * light), .clear],
                       center: UnitPoint(x: centre.x / max(size.width, 1), y: centre.y / max(size.height, 1)),
                       startRadius: 0, endRadius: reach)
            .frame(width: size.width, height: size.height)
            .allowsHitTesting(false)
    }
}

/// A gradient flame that renders anywhere (including ImageRenderer, which can't run shaders).
struct StillFlame: View {
    let size: CGSize
    let phase: Double
    /// Turned down when many flames stand close together, so their light doesn't pile up into a slab.
    var halo: Double = 1

    var body: some View {
        let wobble = 0.04 * sin(phase) + 0.02 * sin(phase * 2.3)
        let reach = size.height * 1.5
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [Theme.ember.opacity(0.5 * halo), Theme.ember.opacity(0.13 * halo), .clear],
                                     center: .center, startRadius: 0, endRadius: reach))
                .frame(width: reach * 2, height: reach * 2)
                .offset(y: -size.height * 0.1)
                .blendMode(.plusLighter)
            FlameShape()
                .fill(LinearGradient(colors: [Color(red: 0.93, green: 0.35, blue: 0.08), Color(red: 1, green: 0.66, blue: 0.24),
                                              Color(red: 1, green: 0.9, blue: 0.62)],
                                     startPoint: .top, endPoint: .bottom))
                .blur(radius: 0.6)
                .frame(width: size.width, height: size.height)
            FlameShape()
                .fill(Color(red: 1, green: 0.97, blue: 0.88))
                .frame(width: size.width, height: size.height)
                .scaleEffect(x: 0.42, y: 0.5, anchor: .bottom)
                .blur(radius: 1.2)
        }
        .frame(width: size.width, height: size.height)
        .scaleEffect(x: 1, y: 1 + wobble, anchor: .bottom)
        .rotationEffect(.radians(wobble * 0.6), anchor: .bottom)
        .allowsHitTesting(false)
    }
}

struct FlameShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let w = r.width, h = r.height
        p.move(to: CGPoint(x: r.midX, y: r.minY))
        p.addCurve(to: CGPoint(x: r.midX + w * 0.5, y: r.minY + h * 0.72),
                   control1: CGPoint(x: r.midX + w * 0.12, y: r.minY + h * 0.25),
                   control2: CGPoint(x: r.midX + w * 0.5, y: r.minY + h * 0.45))
        p.addCurve(to: CGPoint(x: r.midX, y: r.maxY),
                   control1: CGPoint(x: r.midX + w * 0.5, y: r.minY + h * 0.92),
                   control2: CGPoint(x: r.midX + w * 0.28, y: r.maxY))
        p.addCurve(to: CGPoint(x: r.midX - w * 0.5, y: r.minY + h * 0.72),
                   control1: CGPoint(x: r.midX - w * 0.28, y: r.maxY),
                   control2: CGPoint(x: r.midX - w * 0.5, y: r.minY + h * 0.92))
        p.addCurve(to: CGPoint(x: r.midX, y: r.minY),
                   control1: CGPoint(x: r.midX - w * 0.5, y: r.minY + h * 0.45),
                   control2: CGPoint(x: r.midX - w * 0.12, y: r.minY + h * 0.25))
        p.closeSubpath()
        return p
    }
}
