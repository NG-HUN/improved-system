import SwiftUI
import QuartzCore

struct CandleState: Identifiable {
    let id: Int
    let kind: CandleKind
    let seed: Float
    /// Blow energy needed to put this one out.
    let resistance: Float
    var dropStart: Double
    var landed = false
    var igniteAt: Double = .infinity
    var litAt: Double?
    var outAt: Double?
    var sway: Float = 0
    var swayVelocity: Float = 0
    var stiffness: Float

    var isLit: Bool { litAt != nil && outAt == nil }
}

/// Drives the whole ritual: box opens → candles fall → song → wish → blow → celebrate.
@MainActor
@Observable
final class CeremonyModel {
    enum Phase: Equatable { case boxed, arrival, singing, wish, sealed, blow, celebrate }
    enum SealMethod { case fold, faceDown, button }

    let birthday: Birthday
    private(set) var phase: Phase = .boxed
    private(set) var now: Double = CACurrentMediaTime()
    private(set) var phaseStart: Double = CACurrentMediaTime()
    private(set) var candles: [CandleState] = []
    private(set) var blowLevel: Float = 0
    private(set) var micAvailable = true
    private(set) var currentLine: Int?
    private(set) var songStart: Double?
    private(set) var songEnd: Double?
    private(set) var sealMethod: SealMethod?

    static let dropDuration: Double = 0.9
    static let doorDuration: Double = 1.1

    @ObservationIgnored let player = SongPlayer()
    @ObservationIgnored private let detector = BlowDetector()
    @ObservationIgnored private let motion = MotionManager()
    @ObservationIgnored private var link: CADisplayLink?
    @ObservationIgnored private var proxy: DisplayLinkProxy?
    @ObservationIgnored private var lastTick: Double = CACurrentMediaTime()
    @ObservationIgnored private var blowEnergy: Float = 0
    @ObservationIgnored private var faceDownSince: Double?
    @ObservationIgnored private var allOutAt: Double?
    @ObservationIgnored private var started = false
    @ObservationIgnored private var doorFrom: Double = 1
    @ObservationIgnored private var gustPending = false
    /// The box was opened before the song finished rendering. Play it the instant
    /// it is ready instead of waiting for the candle-lighting chain to finish.
    @ObservationIgnored private var songPending = false
    @ObservationIgnored private let epoch = CACurrentMediaTime()
    #if DEBUG
    @ObservationIgnored private var debugCelebrateOffset: Double = 0
    @ObservationIgnored private var debugFreeze = false
    #endif

    /// Small, precise time value for the shaders.
    var clock: Float { Float((now - epoch).truncatingRemainder(dividingBy: 1000)) }

    init(birthday: Birthday) {
        self.birthday = birthday
        // Begin rendering the song at construction time — not at start() — so by
        // the time the user pulls the bow open the tune is ready to play instantly.
        Task { [weak self] in
            guard let self else { return }
            await player.prepare(rounds: birthday.rounds, choice: birthday.song)
            // If the box was opened while rendering was still in flight, fire now.
            // Guard on phase so an idle, still-boxed ceremony stays silent.
            if songPending, songStart == nil, phase != .boxed { startSongNow() }
        }
        // Deterministic: the same name and age always produce the same candles,
        // sway and resistance, so a replayed birthday looks identical.
        var rng = SeededRandom(seed: birthday.name.stableHash &+ UInt64(bitPattern: Int64(birthday.age)))
        let kinds = birthday.candleKinds
        candles = kinds.enumerated().map { i, kind in
            CandleState(id: i, kind: kind,
                        seed: Float.random(in: 0...1, using: &rng),
                        resistance: i == 0 ? 0.06 : Float.random(in: 0.08...0.75, using: &rng),
                        dropStart: .infinity,
                        stiffness: Float.random(in: 28...52, using: &rng))
        }
        #if DEBUG
        // Screenshot hook: -blow.celebrate 1 jumps straight to the wish-came-true scene.
        if let raw = UserDefaults.standard.string(forKey: "blow.celebrate"), raw == "1" {
            phase = .celebrate
            debugFreeze = UserDefaults.standard.string(forKey: "blow.celebrateFreeze") == "1"
            debugCelebrateOffset = Double(UserDefaults.standard.string(forKey: "blow.celebrateAt") ?? "") ?? 0.5
            let t = CACurrentMediaTime()
            phaseStart = t - debugCelebrateOffset
            now = t
            for i in candles.indices {
                candles[i].outAt = phaseStart - 2
                candles[i].litAt = phaseStart - 10
            }
            allOutAt = phaseStart - 2
        }
        // -blow.phase boxed|arrival|singing|wish|sealed|blow — freeze at a stage
        // (used to inspect the bow, the wish prompt, the sealed box, etc.)
        if let stage = UserDefaults.standard.string(forKey: "blow.phase") {
            switch stage {
            case "boxed": phase = .boxed
            case "arrival": phase = .arrival
            case "singing": phase = .singing
            case "wish": phase = .wish
            case "sealed": phase = .sealed
            case "blow": phase = .blow
            default: break
            }
            if phase != .celebrate {
                debugFreeze = true
                // A phase jumped to directly never went through openBox(), so the
                // candles would still be parked above the screen. Put them on the
                // cake and light them, exactly where the real flow leaves them.
                let now = CACurrentMediaTime()
                for i in candles.indices {
                    candles[i].dropStart = now - 10
                    if stage == "sealed" {
                        candles[i].litAt = now - 10
                        candles[i].outAt = now - 5
                    } else if stage != "boxed" {
                        candles[i].litAt = now - 10
                    }
                }
            }
        }
        #endif
    }

    // MARK: lifecycle

    func start() {
        guard !started else { return }
        started = true
        let t = CACurrentMediaTime()
        now = t
        lastTick = t
        #if DEBUG
        if let raw = UserDefaults.standard.string(forKey: "blow.elapsed"), let offset = Double(raw) {
            // Freeze a stage this far into its animation (e.g. past the opening doors).
            phaseStart = t - offset
        } else {
            phaseStart = phase == .celebrate ? t - debugCelebrateOffset : t
        }
        #else
        phaseStart = t
        #endif

        Haptics.prepare()
        motion.start()
        AudioSession.configure()
        // Song rendering already began in init(); openBox()/tick() will start it
        // the instant it is ready. Nothing to do here but wire up the frame loop.

        let proxy = DisplayLinkProxy { [weak self] in self?.tick() }
        let link = CADisplayLink(target: proxy, selector: #selector(DisplayLinkProxy.step))
        link.preferredFrameRateRange = CAFrameRateRange(minimum: 30, maximum: 120, preferred: 60)
        link.add(to: .main, forMode: .common)
        self.proxy = proxy
        self.link = link
    }

    func stop() {
        link?.invalidate()
        link = nil
        player.stop()
        detector.stop()
        motion.stop()
        AudioSession.release()
    }

    // MARK: user actions

    /// Unfold / pull the doors apart / tap: the gift box opens and the candles start to fall.
    /// `closure` is how shut the doors still are when the gesture lets go.
    func openBox(from closure: Double = 1) {
        guard phase == .boxed else { return }
        doorFrom = closure.clamped(0, 1)
        setPhase(.arrival)
        let spacing = min(0.22, 2.4 / Double(max(candles.count, 1)))
        let first = now + Self.doorDuration * doorFrom * 0.6 + 0.4
        for i in candles.indices { candles[i].dropStart = first + Double(i) * spacing }
        player.playPuff()
        Haptics.success()
        // Start the music right now, in step with the bow / doors, rather than
        // after every candle has landed and been lit (which felt sluggish).
        startSongNow()
    }

    /// Kick off the song the moment it is available. Rendering happens off-thread
    /// at `start()`; if it is still in flight we flag it and `tick()` fires this
    /// the instant `isReady` flips, so sound is never held hostage to candle timing.
    private func startSongNow() {
        guard songStart == nil else { return }
        guard player.isReady else { songPending = true; return }
        songPending = false
        songStart = now
        player.playSong()
    }

    func skipSong() {
        guard phase == .singing else { return }
        enterWish()
    }

    /// Fold closed / phone face down / "I made my wish" button.
    func seal(_ method: SealMethod) {
        guard phase == .wish else { return }
        sealMethod = method
        setPhase(.sealed)
        player.playChime()
        Haptics.success()
        if method == .button {
            Task { [weak self] in
                try? await Task.sleep(for: .seconds(2.6))
                self?.beginBlow()
            }
        }
    }

    /// Fold opened again / phone turned face up.
    func reopen() {
        guard phase == .sealed else { return }
        beginBlow()
    }

    func screenChanged(isLarge: Bool, wasLarge: Bool) {
        if phase == .boxed, !wasLarge, isLarge { openBox() }
        else if phase == .wish, wasLarge, !isLarge { seal(.fold) }
        else if phase == .sealed, sealMethod == .fold, isLarge { reopen() }
    }

    func extinguish(_ id: Int) {
        guard phase == .blow, let i = candles.firstIndex(where: { $0.id == id }), candles[i].isLit else { return }
        candles[i].outAt = now
        player.playPuff()
        Haptics.puff()
    }

    // MARK: derived values for the views

    /// 0 → unlit, ramps up on ignite with a little overshoot, fades on extinguish.
    func intensity(of c: CandleState) -> Float {
        guard let lit = c.litAt else { return 0 }
        let rise = Float(Ease.outCubic((now - lit) / 0.7))
        var value = rise + 0.15 * sin(Float(min(now - lit, 0.7) / 0.7) * .pi)
        if let out = c.outAt {
            value *= Float(1 - Ease.outCubic((now - out) / 0.28))
        }
        return max(0, value)
    }

    /// How far the candle has burned down (0 … 0.6).
    var burn: Double {
        guard let songStart else { return 0 }
        let songLength = max(player.songDuration, 1)
        let during = min(1, (now - songStart) / songLength) * 0.45
        let after = songEnd.map { min(0.12, (now - $0) * 0.005) } ?? 0
        return during + after
    }

    /// Fraction of candles still lit — the room's light level.
    var light: Double {
        let lit = candles.reduce(0.0) { $0 + Double(intensity(of: $1)) }
        let full = Double(max(candles.count, 1))
        return (lit / full).clamped(0, 1.15)
    }

    func dropProgress(of c: CandleState) -> Double {
        ((now - c.dropStart) / Self.dropDuration).clamped(0, 1)
    }

    var phaseElapsed: Double { now - phaseStart }

    /// How shut the doors over the cake are: 1 = the closed gift box or the sealed wish, 0 = open.
    var doorClosure: Double {
        switch phase {
        case .boxed: 1
        case .arrival: doorFrom * (1 - Ease.outCubic(phaseElapsed / Self.doorDuration))
        case .sealed: Ease.inOut(phaseElapsed / 0.8)
        case .blow: 1 - Ease.outCubic(phaseElapsed / Self.doorDuration)
        default: 0
        }
    }

    // MARK: frame loop

    private func tick() {
        let t = CACurrentMediaTime()
        let dt = Float(min(t - lastTick, 1.0 / 20.0))
        lastTick = t
        #if DEBUG
        if debugFreeze {
            // Hold the clock so a screenshot can catch a precise frame: `now` stays
            // where start() left it, so phaseElapsed remains exactly the requested offset.
            return
        }
        #endif
        now = t

        // If the box was opened before rendering finished, fire the song the
        // instant it becomes ready — no longer tied to the candle chain.
        if songPending, player.isReady { startSongNow() }

        switch phase {
        case .boxed: break
        case .arrival:
            tickArrival(t)
            // Music may already be playing while candles are still falling.
            if songStart != nil { currentLine = birthday.song.score.line(at: player.songTime ?? 0) }
        case .singing:
            let st = player.songTime ?? 0
            currentLine = birthday.song.score.line(at: st)
            if st >= player.songDuration + 0.4 { enterWish() }
        case .wish:
            if motion.faceDown {
                if faceDownSince == nil { faceDownSince = t }
                if let since = faceDownSince, t - since > 1.0 { seal(.faceDown) }
            } else {
                faceDownSince = nil
            }
        case .sealed:
            if sealMethod == .faceDown, !motion.faceDown, phaseElapsed > 1.2 { reopen() }
        case .blow: tickBlow(t, dt)
        case .celebrate: break
        }

        updateSway(dt)
    }

    private func tickArrival(_ t: Double) {
        var lastLanding = 0.0
        for i in candles.indices {
            let landing = candles[i].dropStart + Self.dropDuration * 0.62
            lastLanding = max(lastLanding, landing)
            if !candles[i].landed, t >= landing {
                candles[i].landed = true
                Haptics.land(final: i == candles.count - 1)
            }
        }
        guard candles.allSatisfy(\.landed) else { return }

        // light them one by one
        if candles.allSatisfy({ $0.igniteAt == .infinity }) {
            let spacing = min(0.2, 2.0 / Double(max(candles.count, 1)))
            for i in candles.indices { candles[i].igniteAt = t + 0.6 + Double(i) * spacing }
        }
        for i in candles.indices where candles[i].litAt == nil && t >= candles[i].igniteAt {
            candles[i].litAt = t
            player.playIgnite()
            Haptics.tap()
        }
        // The song now starts at open-box time; switching to `.singing` here is
        // only a UI-state change after the candles are lit, not the play trigger.
        if let lastLit = candles.compactMap(\.litAt).max(),
           candles.allSatisfy({ $0.litAt != nil }), t - lastLit > 0.35 {
            setPhase(.singing)
        }
    }

    private func tickBlow(_ t: Double, _ dt: Float) {
        // air rushes in as the doors swing open
        if gustPending, phaseElapsed > 0.2 {
            gustPending = false
            gust()
        }

        let raw = detector.score
        blowLevel += (raw - blowLevel) * min(1, dt * 14)

        if raw > 0.08 {
            blowEnergy += raw * raw * dt * 1.8
        } else {
            blowEnergy = max(0, blowEnergy - 0.45 * dt)
        }
        for c in candles where c.isLit && blowEnergy > c.resistance {
            extinguish(c.id)
        }

        if candles.allSatisfy({ $0.outAt != nil }) {
            if allOutAt == nil { allOutAt = t }
            if let out = allOutAt, t - out > 1.3 { celebrate() }
        }
    }

    private func updateSway(_ dt: Float) {
        let center = Float(candles.count - 1) / 2
        let blowPush = phase == .blow ? blowLevel : 0
        for i in candles.indices {
            let side: Float = candles.count == 1 ? 1 : (Float(i) - center >= 0 ? 1 : -1)
            let target = motion.lean + blowPush * 0.9 * side
            let k = candles[i].stiffness
            let damping = 2 * sqrt(k) * 0.32
            candles[i].swayVelocity += ((target - candles[i].sway) * k - candles[i].swayVelocity * damping) * dt
            candles[i].sway += candles[i].swayVelocity * dt
        }
    }

    // MARK: phases

    private func setPhase(_ p: Phase) {
        phase = p
        phaseStart = now
    }

    private func enterWish() {
        songEnd = now
        currentLine = nil
        player.fadeOutSong()
        setPhase(.wish)
    }

    private func beginBlow() {
        guard phase == .sealed else { return }
        setPhase(.blow)
        blowEnergy = 0
        gustPending = true
        Task {
            micAvailable = await detector.start()
        }
    }

    /// Flames bow outwards, away from the opening seam, then spring back.
    private func gust(_ strength: Float = 10) {
        let center = Float(candles.count - 1) / 2
        for i in candles.indices where candles[i].isLit {
            let side: Float = candles.count == 1 ? 1 : (Float(i) - center >= 0 ? 1 : -1)
            candles[i].swayVelocity += side * strength * (0.7 + candles[i].seed * 0.6)
        }
        Haptics.puff()
    }

    private func celebrate() {
        detector.stop()
        blowLevel = 0
        setPhase(.celebrate)
        player.playFinale()
        Haptics.success()
    }
}

/// CADisplayLink needs an NSObject target; this keeps the model free of that.
final class DisplayLinkProxy: NSObject {
    private let action: @MainActor () -> Void
    init(_ action: @escaping @MainActor () -> Void) { self.action = action }
    @objc func step() { MainActor.assumeIsolated { action() } }
}
