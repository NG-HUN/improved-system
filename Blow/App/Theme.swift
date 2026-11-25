import SwiftUI

enum Theme {
    /// The room with the lights off.
    static let night = Color(red: 0.035, green: 0.027, blue: 0.031)
    static let nightRaised = Color(red: 0.075, green: 0.060, blue: 0.060)
    // Candlelight. These two belong to the flame and what it lights — never to buttons.
    static let ember = Color(red: 1.00, green: 0.62, blue: 0.28)
    static let glow = Color(red: 1.00, green: 0.78, blue: 0.48)
    // The interface is a letter: paper for buttons and selection, ink for what is written
    // on them, and sealing-wax red for small touches (switches, bullets) and the app icon.
    static let paper = Color(hex: 0xF4E9D8)
    static let ink = Color(hex: 0x1B1410)
    static let wax = Color(hex: 0xBE3048)
    // The one interface accent: a clear, readable sealing-wax red used for every
    // interactive control (toggles, sliders, selected chips, tinted buttons).
    // `accentGold` is the supporting tone for secondary highlights only.
    static let accent = Color(hex: 0xE23A57)
    static let accentGold = Color(hex: 0xE0A93C)
    static let cream = Color(red: 0.98, green: 0.93, blue: 0.85)
    static let muted = Color(red: 0.98, green: 0.93, blue: 0.85).opacity(0.55)
    static let hairline = Color.white.opacity(0.08)
    // The gift box's cross ribbon. This is the *single* ribbon the bow is tied onto,
    // so it shares the bow's metallic gold palette and reads as one piece of satin.
    private static let ribbonStops: [Gradient.Stop] = [
        .init(color: Color(hex: 0x8E5E17), location: 0),
        .init(color: Color(hex: 0xD9A231), location: 0.22),
        .init(color: Color(hex: 0xFFE9A4), location: 0.42),
        .init(color: Color(hex: 0xC9973F), location: 0.60),
        .init(color: Color(hex: 0xF7D16A), location: 0.80),
        .init(color: Color(hex: 0x8E5E17), location: 1)
    ]
    /// Vertical ribbon band: light runs top→bottom along its length.
    static let ribbon = LinearGradient(stops: ribbonStops, startPoint: .top, endPoint: .bottom)
    /// Horizontal ribbon band: the *same* satin, rotated 90° so its highlight runs
    /// left→right along the band instead of being squeezed into its thin height.
    static let ribbonHorizontal = LinearGradient(stops: ribbonStops, startPoint: .leading, endPoint: .trailing)

    static func serif(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255, opacity: opacity)
    }

    /// 24-bit RGB value for persisting a user-picked icing colour.
    var rgbHex: UInt32 {
        let c = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        c.getRed(&r, green: &g, blue: &b, alpha: &a)
        return (UInt32((r * 255).rounded()) << 16)
             | (UInt32((g * 255).rounded()) << 8)
             |  UInt32((b * 255).rounded())
    }
}

extension Comparable {
    func clamped(_ lo: Self, _ hi: Self) -> Self { min(max(self, lo), hi) }
}

enum Ease {
    static func outCubic(_ t: Double) -> Double { let p = 1 - t.clamped(0, 1); return 1 - p * p * p }
    static func inOut(_ t: Double) -> Double { let x = t.clamped(0, 1); return x * x * (3 - 2 * x) }
    static func outBounce(_ t: Double) -> Double {
        let x = t.clamped(0, 1)
        let n1 = 7.5625, d1 = 2.75
        if x < 1 / d1 { return n1 * x * x }
        if x < 2 / d1 { let y = x - 1.5 / d1; return n1 * y * y + 0.75 }
        if x < 2.5 / d1 { let y = x - 2.25 / d1; return n1 * y * y + 0.9375 }
        let y = x - 2.625 / d1; return n1 * y * y + 0.984375
    }
}

extension String {
    /// Stable across launches, unlike `hashValue` — Swift randomises that per process,
    /// so seeding from it made every replay of the same birthday look different.
    /// FNV-1a over the UTF-8 bytes: cheap, and the same forever on any platform.
    var stableHash: UInt64 {
        var hash: UInt64 = 0xcbf2_9ce4_8422_2325
        for byte in utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x0000_0100_0000_01b3
        }
        return hash
    }
}

/// Small deterministic RNG so every birthday looks the same each time it is replayed.
struct SeededRandom: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed &+ 0x9E3779B97F4A7C15 }
    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }

    mutating func unit() -> CGFloat { CGFloat(Double.random(in: 0...1, using: &self)) }
    mutating func range(_ a: CGFloat, _ b: CGFloat) -> CGFloat { a + (b - a) * unit() }
    mutating func pick<T>(_ items: [T]) -> T { items[Int(next() % UInt64(items.count))] }
}
