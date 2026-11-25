import SwiftUI

/// Draws the ambient sticker placements around the cake. Pure code motifs stay
/// asset-free; custom stickers render the user's image loaded from disk.
/// The layer is non-interactive in the ceremony and always sits behind candles.
struct StickerLayer: View {
    let placements: [StickerPlacement]
    let size: CGSize
    var clock: Float = 0
    var floating: Bool = true
    var showsSelection: Bool = false
    var selectedID: UUID?

    var body: some View {
        Canvas { ctx, _ in
            for s in placements {
                let drift: CGFloat = floating ? CGFloat(sin(clock * 1.1 + Float(s.phase))) * size.height * 0.008 : 0
                let centre = CGPoint(x: s.x * size.width, y: s.y * size.height + drift)
                let side = s.scale * size.width
                if showsSelection && s.id == selectedID {
                    // The selection follows the sticker's rotation so the on-canvas
                    // handles line up with the artwork instead of a fixed axis.
                    let a = CGFloat(s.rotation * .pi / 180)
                    let h = side * 0.62
                    var sel = ctx
                    sel.transform = CGAffineTransform(translationX: centre.x, y: centre.y).rotated(by: a)
                    sel.stroke(Path(roundedRect: CGRect(x: -h, y: -h, width: h * 2, height: h * 2),
                                    cornerRadius: side * 0.08),
                               with: .color(.white.opacity(0.75)),
                               style: StrokeStyle(lineWidth: 1.4, dash: [5, 4]))
                    for corner in [CGPoint(x: -h, y: -h), CGPoint(x: h, y: -h),
                                   CGPoint(x: h, y: h), CGPoint(x: -h, y: h)] {
                        sel.fill(Path(ellipseIn: CGRect(x: corner.x - 2, y: corner.y - 2, width: 4, height: 4)),
                                 with: .color(.white.opacity(0.9)))
                    }
                }
                switch s.source {
                case .builtin(let motif):
                    draw(motif, at: centre, side: side, rotation: s.rotation, in: ctx)
                case .custom(let file):
                    if let img = StickerStore.loadImage(named: file) {
                        let sx = side / img.size.width, sy = side / img.size.height
                        let a = CGFloat(s.rotation * .pi / 180)
                        var t = CGAffineTransform(translationX: centre.x, y: centre.y)
                        t = t.rotated(by: a).scaledBy(x: sx, y: sy)
                        var q = ctx
                        q.transform = t
                        let resolved = q.resolve(Image(uiImage: img))
                        q.draw(resolved, in: CGRect(x: -img.size.width / 2, y: -img.size.height / 2, width: img.size.width, height: img.size.height))
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func draw(_ motif: StickerMotif, at p: CGPoint, side: CGFloat,
                      rotation: Double, in ctx: GraphicsContext) {
        var c = ctx
        c.transform = CGAffineTransform(translationX: p.x, y: p.y)
            .rotated(by: CGFloat(rotation * .pi / 180))
        let r = side / 2
        let tint = motif.tint
        switch motif {
        case .balloon:
            c.fill(Path(ellipseIn: CGRect(x: -r * 0.72, y: -r, width: r * 1.44, height: r * 1.8)),
                   with: .radialGradient(Gradient(colors: [.white.opacity(0.75), tint, tint.opacity(0.75)]),
                      center: CGPoint(x: -r * 0.22, y: -r * 0.45), startRadius: 0, endRadius: r * 1.1))
            c.fill(Path(ellipseIn: CGRect(x: -r * 0.14, y: r * 0.78, width: r * 0.28, height: r * 0.18)),
                   with: .color(tint.opacity(0.9)))
            var string = Path()
            string.move(to: CGPoint(x: 0, y: r * 0.96))
            string.addCurve(to: CGPoint(x: r * 0.25, y: r * 1.7),
                            control1: CGPoint(x: -r * 0.2, y: r * 1.3),
                            control2: CGPoint(x: r * 0.5, y: r * 1.4))
            c.stroke(string, with: .color(Color(hex: 0xB9A88A).opacity(0.8)), lineWidth: max(1, side * 0.014))
        case .star:
            c.fill(starPath(r: r, points: 5), with: .linearGradient(
                Gradient(colors: [.white, tint, Color(hex: 0xA97B2C)]),
                startPoint: CGPoint(x: -r, y: -r), endPoint: CGPoint(x: r, y: r)))
        case .heart:
            c.fill(heartPath(r: r), with: .linearGradient(
                Gradient(colors: [.white.opacity(0.85), tint, tint.opacity(0.8)]),
                startPoint: CGPoint(x: -r, y: -r), endPoint: CGPoint(x: r, y: r)))
        case .confetti:
            for i in -1...1 {
                let ribbon = Path(roundedRect: CGRect(x: -r * 0.16, y: -r * 0.7, width: r * 0.32, height: r * 1.4),
                                  cornerRadius: r * 0.08)
                var q = c
                q.rotate(by: .degrees(Double(i) * 38))
                q.fill(ribbon, with: .color(i == 0 ? tint : tint.opacity(0.7)))
            }
        case .bubble:
            c.fill(Path(ellipseIn: CGRect(x: -r, y: -r, width: r * 2, height: r * 2)),
                   with: .radialGradient(Gradient(colors: [.white.opacity(0.65), tint.opacity(0.35), tint.opacity(0.05)]),
                      center: CGPoint(x: -r * 0.3, y: -r * 0.3), startRadius: 0, endRadius: r))
            c.stroke(Path(ellipseIn: CGRect(x: -r, y: -r, width: r * 2, height: r * 2)),
                     with: .color(.white.opacity(0.7)), lineWidth: max(1, side * 0.02))
        case .flower:
            for i in 0..<5 {
                let a = Angle(degrees: Double(i) * 72)
                let petal = Path(ellipseIn: CGRect(x: -r * 0.32, y: -r * 0.92, width: r * 0.64, height: r * 0.9))
                var q = c
                q.rotate(by: a)
                q.fill(petal, with: .color(tint))
            }
            c.fill(Path(ellipseIn: CGRect(x: -r * 0.24, y: -r * 0.24, width: r * 0.48, height: r * 0.48)),
                   with: .color(Color(hex: 0xE9C169)))
        case .gift:
            let box = CGRect(x: -r * 0.8, y: -r * 0.55, width: r * 1.6, height: r * 1.35)
            c.fill(Path(roundedRect: box, cornerRadius: r * 0.12), with: .color(tint))
            c.fill(Path(roundedRect: CGRect(x: -r * 0.14, y: -r * 0.55, width: r * 0.28, height: r * 1.35),
                        cornerRadius: r * 0.05), with: .color(.white.opacity(0.85)))
            c.fill(Path(roundedRect: CGRect(x: -r * 0.8, y: -r * 0.08, width: r * 1.6, height: r * 0.22),
                        cornerRadius: r * 0.05), with: .color(.white.opacity(0.85)))
        case .sparkle:
            c.fill(starPath(r: r, points: 4), with: .color(tint))
        }
    }

    private func starPath(r: CGFloat, points: Int) -> Path {
        var p = Path()
        let n = points * 2
        for i in 0..<n {
            let angle = Double(i) * .pi / Double(points) - .pi / 2
            let rad: CGFloat = i % 2 == 0 ? r : r * 0.44
            let pt = CGPoint(x: cos(angle) * rad, y: sin(angle) * rad)
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath()
        return p
    }

    private func heartPath(r: CGFloat) -> Path {
        // Symmetric closed heart: bottom tip → left lobe → centre notch →
        // right lobe → back to the tip. Control points mirror across x = 0 so
        // the halves meet cleanly, with no notch artefact or self-crossing.
        var p = Path()
        p.move(to: CGPoint(x: 0, y: r))                                  // bottom tip
        p.addCurve(to: CGPoint(x: -r, y: -r * 0.30),                     // left lobe → shoulder
                   control1: CGPoint(x: -r * 0.95, y: r * 0.35),
                   control2: CGPoint(x: -r * 1.12, y: -r * 0.55))
        p.addCurve(to: CGPoint(x: 0, y: -r * 0.18),                      // left shoulder → centre notch
                   control1: CGPoint(x: -r * 0.92, y: -r * 0.95),
                   control2: CGPoint(x: -r * 0.30, y: -r * 0.72))
        p.addCurve(to: CGPoint(x: r, y: -r * 0.30),                      // centre notch → right shoulder
                   control1: CGPoint(x: r * 0.30, y: -r * 0.72),
                   control2: CGPoint(x: r * 0.92, y: -r * 0.95))
        p.addCurve(to: CGPoint(x: 0, y: r),                              // right shoulder → bottom tip
                   control1: CGPoint(x: r * 1.12, y: -r * 0.55),
                   control2: CGPoint(x: r * 0.95, y: r * 0.35))
        p.closeSubpath()
        return p
    }
}

/// Draws any background — normally the real cake preview — with stickers that
/// can be manipulated right on the canvas: tap to select, drag to move, drag the
/// corner handle to scale, drag the top handle to rotate. Two-finger pinch and
/// twist work on the selected sticker as well.
struct InteractiveStickerCanvas<Content: View>: View {
    @Binding var stickers: [StickerPlacement]
    @Binding var selectedID: UUID?
    let content: () -> Content

    init(stickers: Binding<[StickerPlacement]>,
         selectedID: Binding<UUID?>,
         @ViewBuilder content: @escaping () -> Content) {
        self._stickers = stickers
        self._selectedID = selectedID
        self.content = content
    }

    @State private var moveStart: CGPoint?
    @State private var moveOrigin: CGPoint?
    @State private var pinchStart: CGFloat?
    @State private var twistStart: Double?
    @State private var scaleStart: CGFloat?
    @State private var scaleOrigin: CGFloat?
    @State private var angleBase: Double?
    @State private var multiTouch = false

    private var selected: StickerPlacement? { stickers.first { $0.id == selectedID } }

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            ZStack(alignment: .topLeading) {
                content()
                    .frame(width: size.width, height: size.height)
                    .contentShape(Rectangle())
                    .onTapGesture { select(nil) }

                StickerLayer(placements: stickers, size: size, floating: false,
                             showsSelection: true, selectedID: selectedID)

                ForEach($stickers) { $s in
                    let cx = s.x * size.width
                    let cy = s.y * size.height
                    let side = s.scale * size.width
                    Circle()
                        .fill(Color.white.opacity(0.001))
                        .frame(width: max(30, side * 1.1), height: max(30, side * 1.1))
                        .position(x: cx, y: cy)
                        .onTapGesture { select(s.id) }
                        .gesture(
                            DragGesture()
                                .onChanged { v in
                                    guard !multiTouch else { return }
                                    if selectedID != s.id { select(s.id) }
                                    if moveStart == nil {
                                        moveStart = v.startLocation
                                        moveOrigin = CGPoint(x: s.x, y: s.y)
                                    }
                                    guard let st = moveStart, let org = moveOrigin else { return }
                                    s.x = (org.x + (v.location.x - st.x) / max(size.width, 1)).clamped(0.02, 0.98)
                                    s.y = (org.y + (v.location.y - st.y) / max(size.height, 1)).clamped(0.02, 0.98)
                                }
                                .onEnded { _ in moveStart = nil; moveOrigin = nil }
                        )
                }

                if let s = selected {
                    let cx = s.x * size.width
                    let cy = s.y * size.height
                    let h = s.scale * size.width * 0.62
                    let a = CGFloat(s.rotation * .pi / 180)
                    // Delete handle: top-left corner in the sticker's own frame, so
                    // it sits opposite the scale handle and follows the rotation.
                    // Tap to remove right on the canvas — no need to scroll to a menu.
                    let dp = CGPoint(x: cx + h * (sin(a) - cos(a)),
                                     y: cy - h * (sin(a) + cos(a)))
                    ZStack {
                        Circle().fill(Color(red: 0.86, green: 0.19, blue: 0.28, opacity: 0.95))
                        Circle().stroke(Color.white.opacity(0.95), lineWidth: 1.2)
                        Image(systemName: "xmark").font(.system(size: 11, weight: .bold)).foregroundStyle(.white)
                    }
                    .frame(width: 28, height: 28)
                    .position(dp)
                    .onTapGesture { remove(s) }
                    // Scale handle: bottom-right corner in the sticker's own frame.
                    handle(at: CGPoint(x: cx + h * (cos(a) - sin(a)),
                                       y: cy + h * (sin(a) + cos(a))), symbol: "arrowtriangle.up.right")
                        .gesture(DragGesture().onChanged { v in
                            let d = hypot(v.location.x - cx, v.location.y - cy)
                            if scaleStart == nil { scaleStart = max(1, d); scaleOrigin = s.scale }
                            guard let st = scaleStart, let base = scaleOrigin else { return }
                            setScale(base * d / st, id: s.id)
                        }.onEnded { _ in scaleStart = nil; scaleOrigin = nil })
                    // Rotate handle: just above the sticker, following its rotation.
                    let reach = h * 1.5
                    handle(at: CGPoint(x: cx + reach * sin(a), y: cy - reach * cos(a)), symbol: "arrow.clockwise")
                        .gesture(DragGesture().onChanged { v in
                            let deg = atan2(Double(v.location.y - cy), Double(v.location.x - cx)) * 180 / .pi
                            if angleBase == nil { angleBase = deg - s.rotation }
                            guard let base = angleBase else { return }
                            setRotation(deg - base, id: s.id)
                        }.onEnded { _ in angleBase = nil })
                }
            }
            .frame(width: size.width, height: size.height)
            .simultaneousGesture(
                MagnificationGesture()
                    .onChanged { v in
                        guard let id = selectedID, let i = stickers.firstIndex(where: { $0.id == id }) else { return }
                        multiTouch = true
                        if pinchStart == nil { pinchStart = stickers[i].scale }
                        if let base = pinchStart { stickers[i].scale = (base * v).clamped(0.035, 0.35) }
                    }
                    .onEnded { _ in pinchStart = nil; multiTouch = false }
            )
            .simultaneousGesture(
                RotationGesture()
                    .onChanged { v in
                        guard let id = selectedID, let i = stickers.firstIndex(where: { $0.id == id }) else { return }
                        multiTouch = true
                        if twistStart == nil { twistStart = stickers[i].rotation }
                        if let base = twistStart { stickers[i].rotation = base + v.degrees }
                    }
                    .onEnded { _ in twistStart = nil; multiTouch = false }
            )
        }
    }

    private func handle(at p: CGPoint, symbol: String) -> some View {
        ZStack {
            Circle().fill(Color.black.opacity(0.6))
            Circle().stroke(Color.white.opacity(0.9), lineWidth: 1.2)
            Image(systemName: symbol).font(.system(size: 9, weight: .bold)).foregroundStyle(.white)
        }
        .frame(width: 26, height: 26)
        .position(p)
    }

    private func select(_ id: UUID?) {
        selectedID = id
    }

    /// Remove a placement, deleting its local PNG when it was a custom photo.
    private func remove(_ s: StickerPlacement) {
        if case .custom(let file) = s.source { StickerStore.remove(named: file) }
        stickers.removeAll { $0.id == s.id }
        selectedID = nil
    }

    private func setScale(_ v: CGFloat, id: UUID) {
        guard let i = stickers.firstIndex(where: { $0.id == id }) else { return }
        stickers[i].scale = v.clamped(0.035, 0.35)
    }

    private func setRotation(_ v: Double, id: UUID) {
        guard let i = stickers.firstIndex(where: { $0.id == id }) else { return }
        stickers[i].rotation = v
    }
}
