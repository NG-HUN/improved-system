import SwiftUI

/// Everything on the table: the glow, the cake, candles, flames, smoke.
struct CakeStage: View {
    let model: CeremonyModel
    let size: CGSize
    let clock: Float

    var body: some View {
        let birthday = model.birthday
        // A touch smaller than the setup preview so the opened cake sits comfortably
        // in the ritual stage with room for the glow and the words below.
        let layout = CakeLayout(size: size, kinds: model.candles.map(\.kind), candle: birthday.candle, tiers: birthday.tiers, cakeStyle: birthday.cake, cakeScale: 0.86)
        let light = model.light
        let burn = model.burn
        let order = model.candles.indices.sorted { layout.slots[$0].y < layout.slots[$1].y }

        ZStack(alignment: .topLeading) {
            // warm room glow behind the cake
            RoomGlow(layout: layout, light: light)

            CakeCanvas(layout: layout, style: birthday.cake, text: birthday.cakeText, textEdit: birthday.textEdit, topper: birthday.topper, light: Double(light))
                .equatable()
                .frame(width: size.width, height: size.height)

            // Ambient stickers float around the cake, behind the candles.
            StickerLayer(placements: birthday.stickers, size: size, clock: clock)

            do {
            ForEach(order, id: \.self) { i in
                let c = model.candles[i]
                let slot = layout.slots[i]
                CandleBody(kind: c.kind, style: birthday.candle, slot: slot, burn: burn,
                           emberAge: c.outAt.map { model.now - $0 }, index: i)
                    .offset(y: dropOffset(model.dropProgress(of: c)))
                    .opacity(c.dropStart.isFinite && model.now >= c.dropStart ? 1 : 0)
            }

            // pearls threaded between the candles, overlapping their bases for depth
            CakeFrontDecor(layout: layout, style: birthday.cake)
                .equatable()
                .frame(width: size.width, height: size.height)

            // the room darkens as candles go out — soft-edged, so the stage never shows as a box
            Color.black.opacity(0.66 * (1 - min(light, 1)))
                .frame(width: size.width, height: size.height)
                .mask(RadialGradient(stops: [.init(color: .black, location: 0), .init(color: .black, location: 0.78),
                                             .init(color: .clear, location: 1)],
                                     center: UnitPoint(x: layout.centerX / max(size.width, 1),
                                                       y: (layout.topY + layout.bottomY) / 2 / max(size.height, 1)),
                                     startRadius: 0, endRadius: layout.cakeWidth * 1.05))
                .mask(LinearGradient(stops: [.init(color: .clear, location: 0), .init(color: .black, location: 0.12),
                                             .init(color: .black, location: 0.86), .init(color: .clear, location: 1)],
                                     startPoint: .top, endPoint: .bottom))
                .allowsHitTesting(false)

            // candlelight falling on the cake
            RadialGradient(colors: [Theme.glow.opacity(0.10 * min(light, 1)), .clear],
                           center: UnitPoint(x: layout.centerX / max(size.width, 1),
                                             y: layout.topY / max(size.height, 1)),
                           startRadius: 0, endRadius: layout.cakeWidth * 0.75)
                .frame(width: size.width, height: size.height)
                .blendMode(.plusLighter)
                .allowsHitTesting(false)

            ForEach(order, id: \.self) { i in
                let c = model.candles[i]
                let slot = layout.slots[i]
                let fs = layout.flameSize(slot, kind: c.kind)
                let wick = layout.wickTop(slot, kind: c.kind, burn: c.kind == .stick ? burn : 0)
                let intensity = model.intensity(of: c)
                if intensity > 0.001 {
                    Circle()
                        .fill(RadialGradient(colors: [Theme.ember.opacity(0.45 * min(1, 4.5 / Double(model.candles.count))), .clear],
                                             center: .center, startRadius: 0, endRadius: fs.width * 1.6))
                        .frame(width: fs.width * 3.2, height: fs.width * 3.2)
                        .position(x: wick.x, y: wick.y - fs.height * 0.25)
                        .opacity(Double(intensity) * (0.85 + 0.15 * sin(Double(clock) * 7 + Double(c.seed) * 9)))
                        .blendMode(.plusLighter)
                    FlameView(size: fs, time: clock, sway: c.sway, intensity: intensity,
                              seed: c.seed, agitation: model.phase == .blow ? min(1, model.blowLevel * 1.6) : 0)
                        .position(x: wick.x, y: wick.y + fs.height * 0.10 - fs.height / 2 + fs.height * 0.04)
                }
            }

            SmokeLayer(model: model, layout: layout, burn: burn)
                .frame(width: size.width, height: size.height)
                .allowsHitTesting(false)
            }
        }
        .frame(width: size.width, height: size.height)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0).onChanged { value in
                guard model.phase == .blow else { return }
                for (i, c) in model.candles.enumerated() where c.isLit {
                    let slot = layout.slots[i]
                    let fs = layout.flameSize(slot, kind: c.kind)
                    let wick = layout.wickTop(slot, kind: c.kind, burn: c.kind == .stick ? burn : 0)
                    let flameCenter = CGPoint(x: wick.x, y: wick.y - fs.height * 0.3)
                    if hypot(value.location.x - flameCenter.x, value.location.y - flameCenter.y) < fs.width * 0.9 {
                        model.extinguish(c.id)
                    }
                }
            }
        )
    }

    private func dropOffset(_ p: Double) -> CGFloat {
        -CGFloat(1 - Ease.outBounce(p)) * size.height * 0.95
    }
}

/// The Metal flame.
struct FlameView: View {
    let size: CGSize
    let time: Float
    let sway: Float
    let intensity: Float
    let seed: Float
    let agitation: Float

    var body: some View {
        Rectangle()
            .fill(.white)
            .frame(width: size.width, height: size.height)
            .colorEffect(ShaderLibrary.candleFlame(
                .float2(size), .float(time), .float(sway),
                .float(intensity), .float(seed), .float(agitation)))
            .allowsHitTesting(false)
    }
}

/// Wisps of smoke rising from candles that just went out.
struct SmokeLayer: View {
    let model: CeremonyModel
    let layout: CakeLayout
    let burn: Double

    var body: some View {
        Canvas { ctx, _ in
            ctx.addFilter(.blur(radius: 3))
            for (i, c) in model.candles.enumerated() {
                guard let out = c.outAt else { continue }
                let age = model.now - out
                guard age >= 0, age < 4.5 else { continue }
                let slot = layout.slots[i]
                let wick = layout.wickTop(slot, kind: c.kind, burn: c.kind == .stick ? burn : 0)
                let scale = layout.cakeWidth / 300
                for k in 0..<18 {
                    let a = age - Double(k) * 0.07
                    guard a > 0, a < 3.2 else { continue }
                    let rise = a * 46 * scale
                    let drift = sin(a * 2.6 + Double(k) * 0.7 + Double(c.seed) * 6) * (4 + a * 9) * scale
                    let r = (2.0 + a * 5.5) * scale
                    let alpha = (1 - a / 3.2) * 0.22 * min(1, a * 4)
                    let rect = CGRect(x: wick.x + drift - r, y: wick.y - rise - r, width: r * 2, height: r * 2)
                    ctx.fill(Path(ellipseIn: rect), with: .color(Color(white: 0.85).opacity(alpha)))
                }
            }
        }
    }
}
