import SwiftUI

/// The ritual screen. Adapts to the posture of the phone:
/// - tall: a normal iPhone, or the folding iPhone's cover screen
/// - book: unfolded sideways, crease down the middle — cake on the left page, words on the right
/// - tabletop: unfolded upright, half-folded and standing on the table — cake on top, words below
/// - wide: unfolded and flat, one big stage for photos
///
/// The fold itself is part of the ritual: doors meet along the crease. They open like a gift
/// when the phone unfolds, and close over the cake when it folds shut for the wish.
struct CeremonyView: View {
    let birthday: Birthday
    let onClose: () -> Void

    @Environment(StoreManager.self) private var store
    @State private var model: CeremonyModel
    @State private var duo = true
    @Environment(\.canFold) private var canFold
    @State private var showCard = false
    @State private var savedBrightness: CGFloat?

    enum Posture { case tall, book, tabletop, wide }

    init(birthday: Birthday, onClose: @escaping () -> Void) {
        self.birthday = birthday
        self.onClose = onClose
        _model = State(initialValue: CeremonyModel(birthday: birthday))
    }

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let large = min(size.width, size.height) > 500
            let wide = size.width > size.height * 1.05
            let posture: Posture = !large ? .tall : (wide ? (duo ? .book : .wide) : .tabletop)

            ZStack {
                stage(posture: posture, size: size, large: large)

                if model.phase == .celebrate {
                    // a burst of light on the wish coming true, then the gentle fall
                    WishBurstLayer(elapsed: model.phaseElapsed, clock: model.clock)
                        .allowsHitTesting(false)
                    SparkleLayer(elapsed: model.phaseElapsed, clock: model.clock)
                        .allowsHitTesting(false)

                    if model.phaseElapsed < 2.8 {
                        WishGrantedText(elapsed: model.phaseElapsed,
                                        text: birthday.language == .chinese ? "梦想成真" : "Your wish came true")
                            .allowsHitTesting(false)
                    }
                }

                if model.doorClosure > 0.001 {
                    FoldDoors(model: model, size: size, horizontalSeam: posture == .tabletop,
                              hint: doorHint(large: large))
                }

                topBar(showPostureToggle: large && wide)
            }
            .frame(width: size.width, height: size.height)
            .animation(.easeInOut(duration: 0.6), value: model.phase)
            .onChange(of: large) { old, new in
                model.screenChanged(isLarge: new, wasLarge: old)
            }
        }
        .background(Theme.night.ignoresSafeArea())
        .onAppear {
            model.start()
            UIApplication.shared.isIdleTimerDisabled = true
            brighten()
            // Entering on an already-large screen (an open fold / tablet) means
            // there is no fold-left-to-right transition to trigger openBox(), so
            // open it here. On the cover screen we stay boxed and wait for unfold.
            if currentSmallSide > 500 { model.openBox() }
        }
        .onDisappear {
            model.stop()
            UIApplication.shared.isIdleTimerDisabled = false
            restoreBrightness()
        }
        .sheet(isPresented: $showCard) {
            MemoryCardSheet(birthday: birthday)
                .environment(store)
        }
        #if DEBUG
        .onAppear {
            if UserDefaults.standard.string(forKey: "blow.showCard") == "1" { showCard = true }
        }
        #endif
    }

    // MARK: layouts

    @ViewBuilder
    private func stage(posture: Posture, size: CGSize, large: Bool) -> some View {
        let crease: CGFloat = 28
        switch posture {
        case .book:
            let page = (size.width - crease) / 2
            HStack(spacing: 0) {
                CakeStage(model: model, size: CGSize(width: page, height: size.height), clock: model.clock)
                CreaseGlint(horizontal: false, light: model.light, peak: 0.55, sway: averageSway)
                    .frame(width: crease)
                panel(compact: false, large: large)
                    .frame(width: page, height: size.height)
            }
        case .tabletop:
            let half = (size.height - crease) / 2
            VStack(spacing: 0) {
                CakeStage(model: model, size: CGSize(width: size.width, height: half), clock: model.clock)
                CreaseGlint(horizontal: true, light: model.light, peak: 0.5, sway: averageSway)
                    .frame(height: crease)
                panel(compact: false, large: large)
                    .frame(width: size.width, height: half)
            }
        case .wide:
            let stageHeight = size.height * 0.76
            VStack(spacing: 0) {
                CakeStage(model: model, size: CGSize(width: size.width, height: stageHeight), clock: model.clock)
                panel(compact: true, large: large)
                    .frame(width: size.width, height: size.height - stageHeight)
            }
        case .tall:
            let stageHeight = size.height * 0.66
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                CakeStage(model: model, size: CGSize(width: size.width, height: stageHeight), clock: model.clock)
                panel(compact: true, large: large)
                    .frame(width: size.width, height: size.height * 0.34)
            }
        }
    }

    /// Words and controls under the cake. Changes with each phase of the ritual.
    @ViewBuilder
    private func panel(compact: Bool, large: Bool) -> some View {
        let lines = birthday.language.lines(name: birthday.recipient.isEmpty ? birthday.name : birthday.recipient)
        VStack(spacing: compact ? 14 : 22) {
            switch model.phase {
            case .boxed:
                EmptyView()

            case .arrival:
                Text("for \(birthday.displayRecipient)")
                    .font(Theme.serif(compact ? 22 : 30).italic())
                    .foregroundStyle(Theme.muted)
                    .opacity(min(1, model.phaseElapsed / 1.5))

            case .singing:
                LyricsView(lines: lines, current: model.currentLine, compact: compact)
                Button("Skip", action: model.skipSong)
                    .font(.footnote)
                    .foregroundStyle(Theme.muted.opacity(0.6))

            case .wish:
                VStack(spacing: 10) {
                    Text("Close your eyes.")
                        .font(Theme.serif(compact ? 26 : 34))
                        .foregroundStyle(Theme.cream)
                    Text(large ? "Close the phone and make a wish." : "Place the phone face down and make a wish.")
                        .font(Theme.serif(compact ? 16 : 20).italic())
                        .foregroundStyle(Theme.muted)
                        .multilineTextAlignment(.center)
                }
                .opacity(min(1, model.phaseElapsed / 1.2))
                Button { model.seal(.button) } label: {
                    Text("I've made my wish")
                        .font(.subheadline.weight(.medium))
                        .padding(.horizontal, 20).padding(.vertical, 10)
                        .background(Capsule().stroke(Theme.hairline.opacity(3)))
                }
                .foregroundStyle(Theme.cream.opacity(0.8))
                .opacity(model.phaseElapsed > 2.5 ? 1 : 0)

            case .sealed:
                EmptyView()

            case .blow:
                Text("Now, blow out the candles.")
                    .font(Theme.serif(compact ? 24 : 32))
                    .foregroundStyle(Theme.cream)
                BlowMeter(level: model.blowLevel)
                Text(model.micAvailable ? "or swipe across the flames" : "Swipe across the flames to blow them out")
                    .font(.footnote)
                    .foregroundStyle(Theme.muted.opacity(0.7))

            case .celebrate:
                Text("Happy Birthday,\n\(birthday.displayRecipient)")
                    .font(Theme.serif(compact ? 30 : 42, weight: .medium))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.cream)
                    .opacity(min(1, max(0, (model.phaseElapsed - 0.9) / 1.1)))
                HStack(spacing: 12) {
                    pill("Memory card", systemImage: "photo") { showCard = true }
                    pill("Again", systemImage: "arrow.counterclockwise") { restart() }
                    pill("Done", systemImage: "checkmark") { onClose() }
                }
                .opacity(model.phaseElapsed > 2.0 ? 1 : 0)
            }
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func topBar(showPostureToggle: Bool) -> some View {
        VStack {
            HStack {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(Color.white.opacity(0.06)))
                }
                .accessibilityLabel("Close")
                Spacer()
                if showPostureToggle {
                    Button { withAnimation(.easeInOut(duration: 0.5)) { duo.toggle() } } label: {
                        Image(systemName: duo ? "book" : "rectangle")
                            .font(.system(size: 14, weight: .semibold))
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(Color.white.opacity(0.06)))
                    }
                    .accessibilityLabel(duo ? "One big stage" : "Two pages")
                }
            }
            .foregroundStyle(Theme.muted.opacity(0.7))
            .padding(.horizontal, 16)
            .padding(.top, 8)
            Spacer()
        }
        .opacity(model.phase == .sealed ? 0 : 1)
    }

    private func doorHint(large: Bool) -> String {
        if large { return "Pull the doors apart" }
        return canFold ? "Unfold to open" : "Tap to open"
    }

    /// How hard the flames lean on average — the crease glint drifts with them.
    private var averageSway: Float {
        let lit = model.candles.filter(\.isLit)
        guard !lit.isEmpty else { return 0 }
        return lit.reduce(0) { $0 + $1.sway } / Float(lit.count)
    }

    private func pill(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.medium))
                .lineLimit(1)
                .fixedSize()
                .padding(.horizontal, 16).padding(.vertical, 10)
                .background(Capsule().fill(Color.white.opacity(0.08)))
        }
        .foregroundStyle(Theme.cream)
    }

    private func restart() {
        model.stop()
        model = CeremonyModel(birthday: birthday)
        model.start()
        model.openBox()
    }

    /// The smaller dimension of the window the ceremony currently occupies.
    /// Mirrors the `large` test in `body` so onAppear can decide whether to open.
    private var currentSmallSide: CGFloat {
        let scenes = UIApplication.shared.connectedScenes
        let window = scenes.compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
        let s = window?.bounds.size ?? UIScreen.main.bounds.size
        return min(s.width, s.height)
    }

    // MARK: screen brightness — the phone is the only light in the room

    private var screen: UIScreen? {
        (UIApplication.shared.connectedScenes.first { $0 is UIWindowScene } as? UIWindowScene)?.screen
    }

    private func brighten() {
        guard let screen, savedBrightness == nil else { return }
        savedBrightness = screen.brightness
        screen.brightness = max(screen.brightness, 0.85)
    }

    private func restoreBrightness() {
        guard let screen, let saved = savedBrightness else { return }
        screen.brightness = saved
        savedBrightness = nil
    }
}

// MARK: - pieces

/// Only two or three lines are on screen at once: the current line and its immediate
/// neighbours, so the words cycle gently under the cake instead of sitting as a block.
struct LyricsView: View {
    let lines: [String]
    let current: Int?
    let compact: Bool

    private var window: [Int] {
        guard let c = current else { return lines.indices.map { $0 } }
        let lo = max(0, c - 1), hi = min(lines.count - 1, c + 1)
        return Array(lo...hi)
    }

    var body: some View {
        VStack(spacing: compact ? 6 : 10) {
            ForEach(window, id: \.self) { i in
                let active = current == i
                Text(lines[i])
                    .font(Theme.serif(compact ? 19 : 26, weight: active ? .medium : .regular))
                    .foregroundStyle(active ? Theme.cream : Theme.cream.opacity(0.22))
                    .scaleEffect(active ? 1.05 : 0.97)
                    .shadow(color: active ? Theme.ember.opacity(0.45) : .clear, radius: 10)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: current)
    }
}

struct BlowMeter: View {
    let level: Float
    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<9, id: \.self) { i in
                let on = Float(i) / 9 < level
                Capsule()
                    .fill(on ? Theme.paper : Color.white.opacity(0.10))
                    .frame(width: 4, height: 6 + CGFloat(min(i, 8 - i)) * 3)
            }
        }
        .animation(.easeOut(duration: 0.1), value: level)
        .accessibilityHidden(true)
    }
}

/// Two doors that meet along the crease. Shut, they are either the gift box (ribbon, bow, tag)
/// or the sealed wish (a wax seal over the seam). They swing open from the seam outwards,
/// the way the phone itself unfolds.
struct FoldDoors: View {
    let model: CeremonyModel
    let size: CGSize
    /// Tabletop: the crease runs across the screen, so the doors open up and down.
    let horizontalSeam: Bool
    let hint: String

    /// 0…1, how far a finger has pulled the closed box apart.
    @State private var drag: Double = 0
    @State private var peeks = 0

    private var isGift: Bool { model.phase == .boxed || model.phase == .arrival }

    var body: some View {
        let closure = min(model.doorClosure, 1 - drag * 0.55)
        let open = 1 - closure
        ZStack {
            spill(open: open)
            door(leading: true, open: open)
            door(leading: false, open: open)
            if isGift { giftFront(closure: closure) } else { sealFront(closure: closure) }
        }
        .frame(width: size.width, height: size.height)
        .contentShape(Rectangle())
        .gesture(pull)
        .onTapGesture(perform: tap)
        .allowsHitTesting(model.phase == .boxed || model.phase == .sealed)
    }

    // MARK: doors

    private func door(leading: Bool, open: Double) -> some View {
        let half = horizontalSeam ? CGSize(width: size.width, height: size.height / 2)
                                  : CGSize(width: size.width / 2, height: size.height)
        let hinge: UnitPoint = horizontalSeam ? (leading ? .top : .bottom) : (leading ? .leading : .trailing)
        let angle = open * 100 * (leading ? -1 : 1)
        let axis: (x: CGFloat, y: CGFloat, z: CGFloat) = horizontalSeam ? (1, 0, 0) : (0, 1, 0)
        return DoorPanel(seamEdge: horizontalSeam ? (leading ? .bottom : .top) : (leading ? .trailing : .leading),
                         ribbon: isGift, shade: open)
            .frame(width: half.width, height: half.height)
            .rotation3DEffect(.degrees(horizontalSeam ? -angle : angle), axis: axis, anchor: hinge, perspective: 0.45)
            .opacity(min(1, (1 - open) / 0.18))
            .frame(width: size.width, height: size.height, alignment: Alignment(hinge))
    }

    /// Warm light escaping through the widening gap.
    private func spill(open: Double) -> some View {
        let strength = sin(open * .pi) * (isGift ? 0.55 : 0.35)
        let band = LinearGradient(colors: [.clear, Theme.glow.opacity(strength), .clear],
                                  startPoint: horizontalSeam ? .top : .leading,
                                  endPoint: horizontalSeam ? .bottom : .trailing)
        return Rectangle()
            .fill(band)
            .frame(width: horizontalSeam ? size.width : size.width * (0.2 + open),
                   height: horizontalSeam ? size.height * (0.2 + open) : size.height)
            .blendMode(.plusLighter)
            .allowsHitTesting(false)
    }

    // MARK: what sits on the seam

    private func giftFront(closure: Double) -> some View {
        let shut = ((closure - 0.9) / 0.1).clamped(0, 1)
        return ZStack {
            // The bow's knot sits exactly where the two box ribbons cross, so the
            // bow and the cross read as one continuous wrapped gift.
            Bow()
                .frame(width: 230, height: 230)
            GiftTag(text: "for \(model.birthday.displayRecipient)")
                .offset(x: 122, y: 34)
            Text(hint)
                .font(Theme.serif(17).italic())
                .foregroundStyle(Theme.cream.opacity(0.8))
                .padding(.horizontal, 16).padding(.vertical, 8)
                .background(Capsule().fill(Theme.night.opacity(0.85)))
                .opacity(0.55 + 0.45 * sin(Double(model.clock) * 2.2))
                .offset(y: min(size.height, size.width) * 0.3)
        }
        .opacity(shut)
        .scaleEffect(0.96 + 0.04 * shut)
        .allowsHitTesting(false)
    }

    private func sealFront(closure: Double) -> some View {
        let shut = ((closure - 0.85) / 0.15).clamped(0, 1)
        return ZStack {
            Circle()
                .fill(RadialGradient(colors: [Theme.ember.opacity(0.30), .clear], center: .center, startRadius: 0, endRadius: 150))
                .frame(width: 300, height: 300)
                .scaleEffect(1 + 0.05 * sin(Double(model.clock) * 1.6))
            VStack(spacing: 16) {
                WaxSeal()
                    .frame(width: 74, height: 74)
                    .keyframeAnimator(initialValue: 0.0, trigger: peeks) { content, angle in
                        content.rotationEffect(.degrees(angle))
                    } keyframes: { _ in
                        KeyframeTrack {
                            CubicKeyframe(-14, duration: 0.07)
                            CubicKeyframe(11, duration: 0.08)
                            CubicKeyframe(-6, duration: 0.08)
                            CubicKeyframe(0, duration: 0.12)
                        }
                    }
                Text("Wish sealed")
                    .font(Theme.serif(30))
                    .foregroundStyle(Theme.cream)
                Text(peeks > 0 ? "No peeking ✦" : (model.sealMethod == .fold ? "Open to blow out the candles" : "Keep it to yourself"))
                    .font(Theme.serif(16).italic())
                    .foregroundStyle(Theme.muted)
                    .contentTransition(.opacity)
                    .animation(.easeInOut(duration: 0.3), value: peeks)
            }
        }
        .opacity(shut)
        .scaleEffect(1.08 - 0.08 * shut)
    }

    // MARK: gestures

    private var pull: some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                guard model.phase == .boxed else { return }
                let distance = horizontalSeam ? abs(value.translation.height) : abs(value.translation.width)
                drag = min(1, distance / ((horizontalSeam ? size.height : size.width) * 0.35))
            }
            .onEnded { _ in
                guard model.phase == .boxed else { return }
                if drag > 0.45 {
                    model.openBox(from: 1 - drag * 0.55)
                    drag = 0
                } else {
                    withAnimation(.spring(duration: 0.4, bounce: 0.35)) { drag = 0 }
                }
            }
    }

    private func tap() {
        switch model.phase {
        case .boxed: model.openBox()
        case .sealed:
            peeks += 1
            Haptics.tap()
        default: break
        }
    }
}

/// One door: dark lacquer, a hairline frame, and its half of the ribbon along the seam.
struct DoorPanel: View {
    let seamEdge: Edge
    let ribbon: Bool
    /// 0 facing you … 1 turned away; doors darken as they swing.
    let shade: Double

    var body: some View {
        let alongSeam = seamEdge == .leading || seamEdge == .trailing
        ZStack {
            LinearGradient(colors: [Theme.nightRaised, Theme.night],
                           startPoint: UnitPoint(seamEdge), endPoint: UnitPoint(seamEdge.opposite))
            Rectangle()
                .inset(by: 14)
                .stroke(Theme.glow.opacity(0.10), lineWidth: 1)
            if ribbon {
                // Both bands share one width; the light always runs ALONG the band.
                // A vertical seam (left/right doors) carries a horizontal band across
                // the middle plus two halves that meet to form the vertical band.
                let band: CGFloat = 26
                // band across the middle of the door
                Rectangle()
                    .fill(alongSeam ? Theme.ribbonHorizontal : Theme.ribbon)
                    .frame(width: alongSeam ? nil : band, height: alongSeam ? band : nil)
                // half of the band down the seam
                Rectangle()
                    .fill(alongSeam ? Theme.ribbon : Theme.ribbonHorizontal)
                    .frame(width: alongSeam ? band / 2 : nil, height: alongSeam ? nil : band / 2)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: Alignment(seamEdge))
            }
            Color.black.opacity(shade * 0.55)
        }
    }
}

/// A showpiece gold satin bow modelled on the reference: a horizontal ribbon band,
/// two plump loops per side (a large upper and a smaller lower one, each with a dark
/// turned-back inner fold), a wrapped cylindrical knot and two notched tails. Layered
/// gold stops and specular streaks give it the folded, metallic sheen of real ribbon.
struct Bow: View {
    var body: some View {
        Canvas { ctx, size in
            // The knot sits at the canvas centre; giftFront centres this canvas on the
            // wrapped box's cross ribbon, so bow and ribbon read as one object.
            let c = CGPoint(x: size.width / 2, y: size.height / 2)
            // Silhouette traced 1:1 from the user's sketch (knot at sketch origin).
            // The sketch spans ~1055 units across its wings.
            let s = size.width / 1055.0 * 0.92
            func pt(_ u: CGFloat, _ v: CGFloat) -> CGPoint {
                CGPoint(x: c.x + u * s, y: c.y + v * s)
            }
            func points(_ raw: [(CGFloat, CGFloat)], mirror: Bool = false) -> [CGPoint] {
                raw.map { pt(mirror ? -$0.0 : $0.0, $0.1) }
            }
            /// Smooth closed curve through the given points (quadratic through midpoints),
            /// reproducing the soft rounded edges of the sketch.
            func smooth(_ p: [CGPoint]) -> Path {
                var path = Path()
                let n = p.count
                path.move(to: CGPoint(x: (p[n - 1].x + p[0].x) / 2, y: (p[n - 1].y + p[0].y) / 2))
                for i in 0..<n {
                    let cur = p[i], nxt = p[(i + 1) % n]
                    path.addQuadCurve(to: CGPoint(x: (cur.x + nxt.x) / 2, y: (cur.y + nxt.y) / 2),
                                      control: cur)
                }
                path.closeSubpath()
                return path
            }
            let gold = [
                Color(hex: 0x6E4715), Color(hex: 0xA9761B), Color(hex: 0xD9A231),
                Color(hex: 0xFFE9A4), Color(hex: 0xE7B743), Color(hex: 0x8E5E17),
                Color(hex: 0xF7D16A)
            ]
            func metal(_ stops: [(Color, CGFloat)], from a: CGPoint, to b: CGPoint) -> GraphicsContext.Shading {
                .linearGradient(Gradient(stops: stops.map { .init(color: $0.0, location: $0.1) }),
                                startPoint: a, endPoint: b)
            }
            let bodyStops: [(Color, CGFloat)] = [(gold[0], 0), (gold[2], 0.24), (gold[3], 0.44),
                                                 (gold[1], 0.64), (gold[4], 0.80), (gold[5], 1)]
            let foldStops: [(Color, CGFloat)] = [(gold[5], 0), (gold[0], 0.5), (gold[1], 1)]

            // Control vertices recovered from the sketch, relative to the knot.
            let wing: [(CGFloat, CGFloat)] = [(-490, -233), (-524, 37), (-442, 2), (-77, 35),
                                              (-68, -69), (-212, -181), (-381, -257), (-451, -259)]
            let tail: [(CGFloat, CGFloat)] = [(-77, 48), (-203, 63), (-349, 187), (-420, 297),
                                              (-419, 364), (-246, 535), (-191, 340), (-48, 75)]
            let fold: [(CGFloat, CGFloat)] = [(-527, 49), (-500, 78), (-122, 53), (-78, 47),
                                              (-78, 35), (-436, 3), (-496, 13)]

            // Tails first (behind the wings and knot).
            for m in [false, true] {
                let path = smooth(points(tail, mirror: m))
                ctx.fill(path.offsetBy(dx: 0, dy: s * 5), with: .color(.black.opacity(0.28)))
                ctx.fill(path, with: metal(bodyStops,
                    from: pt(m ? 300 : -300, -40), to: pt(m ? 180 : -180, 520)))
                ctx.stroke(path, with: .color(gold[0].opacity(0.75)), lineWidth: 1)
            }

            // Two broad rounded wings.
            for m in [false, true] {
                let path = smooth(points(wing, mirror: m))
                ctx.fill(path.offsetBy(dx: 0, dy: s * 6), with: .color(.black.opacity(0.30)))
                ctx.fill(path, with: metal(bodyStops,
                    from: pt(m ? 420 : -420, -260), to: pt(m ? 120 : -120, 60)))
                ctx.stroke(path, with: .color(gold[0].opacity(0.7)), lineWidth: 1)

                // Dark crescent fold along the lower edge of each wing.
                let f = smooth(points(fold, mirror: m))
                ctx.fill(f, with: metal(foldStops,
                    from: pt(m ? 500 : -500, 20), to: pt(m ? 90 : -90, 80)))

                // Satin highlight sweeping across the upper face of the wing.
                var spec = Path()
                spec.move(to: pt(m ? 420 : -420, -210))
                spec.addQuadCurve(to: pt(m ? 90 : -90, -50),
                                  control: pt(m ? 300 : -300, -230))
                ctx.stroke(spec, with: .color(.white.opacity(0.30)),
                           style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
            }

            // Rounded-square knot, centred exactly on the cross and drawn last.
            let kw = 153 * s, kh = 153 * s
            let kr = CGRect(x: c.x - kw / 2, y: c.y - kh / 2, width: kw, height: kh)
            ctx.fill(Path(roundedRect: kr.offsetBy(dx: 0, dy: s * 5), cornerRadius: kw * 0.20),
                     with: .color(.black.opacity(0.35)))
            let kf = Path(roundedRect: kr, cornerRadius: kw * 0.20)
            ctx.fill(kf, with: metal([(gold[0], 0), (gold[2], 0.28), (gold[3], 0.46),
                                      (gold[1], 0.64), (gold[4], 0.84), (gold[5], 1)],
                                     from: CGPoint(x: kr.minX, y: kr.minY),
                                     to: CGPoint(x: kr.maxX, y: kr.maxY)))
            ctx.stroke(kf, with: .color(gold[0].opacity(0.7)), lineWidth: 1)
            // soft central sheen
            ctx.fill(Path(ellipseIn: CGRect(x: kr.minX + kw * 0.16, y: kr.minY + kh * 0.12,
                                            width: kw * 0.5, height: kh * 0.30)),
                     with: .color(.white.opacity(0.28)))
        }
        .shadow(color: .black.opacity(0.45), radius: 10, y: 5)
    }
}

/// The little card tied to the bow.
struct GiftTag: View {
    let text: String
    var body: some View {
        Text(text)
            .font(Theme.serif(15).italic())
            .foregroundStyle(Color(red: 0.35, green: 0.22, blue: 0.14))
            .lineLimit(1)
            .padding(.horizontal, 12).padding(.vertical, 6)
            .background(RoundedRectangle(cornerRadius: 4).fill(Theme.cream))
            .overlay(alignment: .leading) {
                Circle().stroke(Color(red: 0.35, green: 0.22, blue: 0.14).opacity(0.4), lineWidth: 1)
                    .frame(width: 5, height: 5)
                    .padding(.leading, 4)
            }
            .rotationEffect(.degrees(-9), anchor: .leading)
            .shadow(color: .black.opacity(0.35), radius: 4, y: 2)
    }
}

/// A quiet gold star seal over the seam — a kept secret, not a warning. The earlier
/// red wax read as an alert; this reads as candlelight and keeps the wish gentle.
struct WaxSeal: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [
                    Color(hex: 0x6B5730), Color(hex: 0x3A3120), Theme.nightRaised],
                    center: UnitPoint(x: 0.35, y: 0.28), startRadius: 2, endRadius: 44))
            Circle()
                .stroke(Theme.glow.opacity(0.55), lineWidth: 1.4)
            Circle()
                .inset(by: 8)
                .stroke(Theme.glow.opacity(0.28), lineWidth: 0.8)
            Text("✦")
                .font(.system(size: 26, weight: .light))
                .foregroundStyle(Theme.glow)
                .shadow(color: Theme.ember.opacity(0.7), radius: 8)
        }
        .shadow(color: Theme.ember.opacity(0.25), radius: 12)
    }
}

/// The fold catches the candlelight: a faint warm line where the screen bends.
struct CreaseGlint: View {
    let horizontal: Bool
    let light: Double
    /// Where along the crease the light is brightest, 0…1.
    let peak: Double
    let sway: Float

    var body: some View {
        let center = (peak + Double(sway) * 0.12).clamped(0.15, 0.85)
        let glint = LinearGradient(stops: [
            .init(color: .clear, location: 0),
            .init(color: Theme.glow.opacity(0.35 * min(light, 1)), location: center),
            .init(color: .clear, location: 1),
        ], startPoint: horizontal ? .leading : .top, endPoint: horizontal ? .trailing : .bottom)
        ZStack {
            Rectangle().fill(glint)
                .frame(width: horizontal ? nil : 1, height: horizontal ? 1 : nil)
            Rectangle().fill(glint)
                .frame(width: horizontal ? nil : 8, height: horizontal ? 8 : nil)
                .blur(radius: 5)
                .opacity(0.7)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .blendMode(.plusLighter)
        .allowsHitTesting(false)
    }
}

private extension Edge {
    var opposite: Edge {
        switch self {
        case .top: .bottom
        case .bottom: .top
        case .leading: .trailing
        case .trailing: .leading
        }
    }
}

private extension UnitPoint {
    init(_ edge: Edge) {
        switch edge {
        case .top: self = .top
        case .bottom: self = .bottom
        case .leading: self = .leading
        case .trailing: self = .trailing
        }
    }
}

private extension Alignment {
    init(_ point: UnitPoint) {
        switch point {
        case .top: self = .top
        case .bottom: self = .bottom
        case .leading: self = .leading
        case .trailing: self = .trailing
        default: self = .center
        }
    }

    init(_ edge: Edge) { self.init(UnitPoint(edge)) }
}

/// A huge, cinematic burst for the moment the wish comes true: a blinding core flash,
/// three expanding shockwaves, jagged lightning spokes, two waves of light rays,
/// sharp four-point star flares, and a rain of spinning gold confetti — layered with
/// additive blending so it genuinely feels like an explosion of light.
struct WishBurstLayer: View {
    let elapsed: Double
    let clock: Float

    var body: some View {
        Canvas { ctx, size in
            guard elapsed >= 0 else { return }
            let centre = CGPoint(x: size.width / 2, y: size.height * 0.42)
            let reach = hypot(size.width, size.height) * 0.72

            // ---- warm halo wash ---------------------------------------------------
            let haloT = (elapsed / 1.3).clamped(0, 1)
            if haloT < 1 {
                let r = reach * (0.04 + Ease.outCubic(haloT) * 0.85)
                ctx.fill(Path(ellipseIn: CGRect(x: centre.x - r, y: centre.y - r, width: r * 2, height: r * 2)),
                         with: .radialGradient(Gradient(colors: [
                            Theme.glow.opacity((1 - haloT) * 0.62),
                            Color(hex: 0xFFB03A).opacity((1 - haloT) * 0.34), .clear]),
                            center: centre, startRadius: 0, endRadius: r))
            }

            // ---- three shockwave rings racing outward ----------------------------
            for (i, delay) in [0.0, 0.09, 0.2].enumerated() {
                let rt = ((elapsed - delay) / (0.6 + Double(i) * 0.12)).clamped(0, 1)
                guard elapsed >= delay, rt < 1 else { continue }
                let r = reach * Ease.outCubic(rt) * 0.9
                ctx.stroke(Path(ellipseIn: CGRect(x: centre.x - r, y: centre.y - r, width: r * 2, height: r * 2)),
                           with: .color(i == 0 ? Theme.cream.opacity((1 - rt) * 0.9)
                                               : Theme.glow.opacity((1 - rt) * 0.55)),
                           lineWidth: max(0.5, CGFloat(4 - i) * (1 - rt)))
            }

            // ---- blinding core flash with a cross-shaped glare --------------------
            let flashT = (elapsed / 0.5).clamped(0, 1)
            if flashT < 1 {
                let a = pow(1 - flashT, 1.5)
                let r = reach * (0.1 + Ease.outCubic(flashT) * 0.42)
                ctx.fill(Path(ellipseIn: CGRect(x: centre.x - r, y: centre.y - r, width: r * 2, height: r * 2)),
                         with: .radialGradient(Gradient(colors: [
                            Color.white.opacity(a), Color.white.opacity(a * 0.8),
                            Theme.glow.opacity(a * 0.55), .clear]),
                            center: centre, startRadius: 0, endRadius: r))
                // four-point glare spikes through the core
                let spike = reach * (0.25 + Ease.outCubic(flashT) * 0.55) * a
                for k in 0..<4 {
                    let ang = CGFloat(k) * .pi / 2 + .pi / 4
                    let ex = centre.x + cos(ang) * spike, ey = centre.y + sin(ang) * spike
                    let perp = CGVector(dx: -sin(ang), dy: cos(ang))
                    let half = size.width * 0.012 * a
                    var g = Path()
                    g.move(to: centre)
                    g.addLine(to: CGPoint(x: ex + perp.dx * half, y: ey + perp.dy * half))
                    g.addLine(to: CGPoint(x: ex - perp.dx * half, y: ey - perp.dy * half))
                    g.closeSubpath()
                    ctx.fill(g, with: .color(Theme.cream.opacity(a * 0.7)))
                }
            }

            // ---- lightning spokes: sharp zig-zags that crack outward -------------
            var lrng = SeededRandom(seed: 3391)
            for k in 0..<20 {
                let ang = Double(k) / 20.0 * 2 * .pi + Double(lrng.range(-0.05, 0.05))
                let delay = 0.02 + Double(lrng.unit()) * 0.1
                let t = ((elapsed - delay) / 0.9).clamped(0, 1)
                guard elapsed >= delay, t < 1 else { continue }
                let travel = Ease.outCubic(t)
                let life = pow(1 - travel, 1.6)
                var bolt = Path()
                let startR = reach * 0.06
                let endR = reach * (0.3 + travel * 0.85)
                bolt.move(to: CGPoint(x: centre.x + cos(ang) * startR, y: centre.y + sin(ang) * startR))
                let segs = 5
                for j in 1...segs {
                    let rr = startR + (endR - startR) * CGFloat(j) / CGFloat(segs)
                    let jitter = (j == segs ? 0 : Double(lrng.range(-0.06, 0.06)))
                    let aa = CGFloat(ang + jitter)
                    bolt.addLine(to: CGPoint(x: centre.x + cos(aa) * rr, y: centre.y + sin(aa) * rr))
                }
                ctx.stroke(bolt, with: .color(Color(hex: 0xFFF2C8).opacity(life * 0.85)),
                           style: StrokeStyle(lineWidth: max(0.6, 2.4 * life), lineCap: .round, lineJoin: .round))
            }

            // ---- two waves of glowing rays, each tipped with a star --------------
            var rng = SeededRandom(seed: 7717)
            for wave in 0..<3 {
                let rays = wave == 0 ? 64 : (wave == 1 ? 44 : 30)
                let delay = [0.0, 0.12, 0.26][wave]
                for k in 0..<rays {
                    let angle = Double(k) / Double(rays) * 2 * .pi
                               + (wave == 0 ? 0 : .pi / Double(rays)) + Double(rng.range(-0.04, 0.04))
                    let localDelay = delay + Double(rng.unit()) * 0.12
                    let t = ((elapsed - localDelay) / 1.25).clamped(0, 1)
                    guard elapsed >= localDelay, t < 1 else { continue }
                    let travel = Ease.outCubic(t)
                    let dist = reach * (0.12 + travel * rng.range(0.75, 1.2))
                    let life = (1 - travel) * (1 - travel)
                    let len = size.height * rng.range(0.05, 0.14) * (0.4 + life)
                    let px = centre.x + cos(angle) * dist
                    let py = centre.y + sin(angle) * dist
                    var ray = Path()
                    ray.move(to: CGPoint(x: px - cos(angle) * len, y: py - sin(angle) * len))
                    ray.addLine(to: CGPoint(x: px + cos(angle) * len, y: py + sin(angle) * len))
                    let tone: Color = k % 5 == 0 ? Color(hex: 0xFFB7D2)
                                    : (k % 3 == 0 ? Color(hex: 0xFFE7A8) : Theme.glow)
                    ctx.stroke(ray, with: .color(tone.opacity(life)),
                               style: StrokeStyle(lineWidth: rng.range(1.6, 3.6), lineCap: .round))
                    // a four-point flare at the tip of some rays
                    if k % 4 == 0 {
                        let s = size.height * rng.range(0.015, 0.03) * (0.5 + life)
                        var star = Path()
                        star.move(to: CGPoint(x: px, y: py - s))
                        star.addLine(to: CGPoint(x: px + s * 0.22, y: py - s * 0.22))
                        star.addLine(to: CGPoint(x: px + s, y: py))
                        star.addLine(to: CGPoint(x: px + s * 0.22, y: py + s * 0.22))
                        star.addLine(to: CGPoint(x: px, y: py + s))
                        star.addLine(to: CGPoint(x: px - s * 0.22, y: py + s * 0.22))
                        star.addLine(to: CGPoint(x: px - s, y: py))
                        star.addLine(to: CGPoint(x: px - s * 0.22, y: py - s * 0.22))
                        star.closeSubpath()
                        ctx.fill(star, with: .color(Theme.cream.opacity(life)))
                    }
                }
            }

            // ---- spinning gold confetti rain -------------------------------------
            let confT = (elapsed / 2.2).clamped(0, 1)
            if confT > 0 {
                let confetti = [Theme.glow, Color(hex: 0xFFB7D2), Color(hex: 0xFFE7A8),
                                Theme.cream, Color(hex: 0xFF9E4A)]
                for k in 0..<64 {
                    let seed = Double(k) * 1.7
                    let angle = seed.truncatingRemainder(dividingBy: 2 * .pi) + confT * 0.7
                    let d = reach * (0.18 + (seed.truncatingRemainder(dividingBy: 0.7)) * 1.35) * Ease.outCubic(confT)
                    let x = centre.x + cos(angle) * d
                    let y = centre.y + sin(angle) * d + confT * confT * size.height * 0.3
                    let wd = size.width * 0.007, ht = size.width * 0.015
                    let fade = (1 - confT) * 0.95
                    let spin = confT * 12 + seed
                    var flake = Path()
                    flake.move(to: CGPoint(x: x - wd, y: y - ht))
                    flake.addLine(to: CGPoint(x: x + wd, y: y - ht * 0.4))
                    flake.addLine(to: CGPoint(x: x + wd * 0.6, y: y + ht))
                    flake.addLine(to: CGPoint(x: x - wd * 0.6, y: y + ht * 0.6))
                    flake.closeSubpath()
                    var fc = ctx
                    fc.translateBy(x: x, y: y)
                    fc.rotate(by: .radians(Double(sin(spin) * 0.9)))
                    fc.translateBy(x: -x, y: -y)
                    fc.fill(flake, with: .color(confetti[k % confetti.count].opacity(fade)))
                }
            }
        }
        .blendMode(.plusLighter)
    }
}

/// The wish line that blooms over the burst, then melts away.
struct WishGrantedText: View {
    let elapsed: Double
    let text: String

    private var opacity: Double {
        let rise = (elapsed / 0.5).clamped(0, 1)
        let fall = 1 - ((elapsed - 1.5) / 1.2).clamped(0, 1)
        return rise * fall
    }

    var body: some View {
        VStack(spacing: 10) {
            Text("✦")
                .font(.system(size: 22))
                .foregroundStyle(Theme.glow)
            Text(text)
                .font(Theme.serif(30, weight: .medium).italic())
                .foregroundStyle(Theme.cream)
                .shadow(color: Theme.glow.opacity(0.6), radius: 16)
        }
        .opacity(opacity)
        .scaleEffect(0.94 + 0.06 * (elapsed / 0.5).clamped(0, 1))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .offset(y: -60)
    }
}

/// Warm motes of light drifting down after the candles are out.
struct SparkleLayer: View {
    let elapsed: Double
    let clock: Float

    var body: some View {
        Canvas { ctx, size in
            var rng = SeededRandom(seed: 2026)
            // ease in after the burst has had its moment
            let fade = ((elapsed - 0.6) / 0.9).clamped(0, 1)
            for _ in 0..<110 {
                let x0 = Double.random(in: 0...1, using: &rng)
                let speed = Double.random(in: 0.05...0.16, using: &rng)
                let phase = Double.random(in: 0...1, using: &rng)
                let r = Double.random(in: 1.0...3.2, using: &rng)
                let hue = Double.random(in: 0...1, using: &rng)
                let y = (phase + elapsed * speed).truncatingRemainder(dividingBy: 1.1) - 0.05
                let x = x0 + sin(elapsed * 0.8 + phase * 12) * 0.02
                let twinkle = 0.5 + 0.5 * sin(Double(clock) * 3 + phase * 40)
                let color = hue < 0.7 ? Theme.glow : (hue < 0.85 ? Color(red: 1, green: 0.75, blue: 0.8) : Theme.cream)
                let rect = CGRect(x: x * size.width - r, y: y * size.height - r, width: r * 2, height: r * 2)
                ctx.fill(Path(ellipseIn: rect), with: .color(color.opacity(0.85 * twinkle * fade)))
            }
        }
        .blendMode(.plusLighter)
    }
}
