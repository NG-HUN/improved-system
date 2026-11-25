import SwiftUI

/// Geometry of the cake and where each candle stands, for a given stage size.
struct CakeLayout: Equatable {
    struct Slot: Equatable { let x: CGFloat; let y: CGFloat; let width: CGFloat; let height: CGFloat; let depth: CGFloat }

    let size: CGSize
    let cakeWidth: CGFloat
    let sideHeight: CGFloat
    let topRadiusY: CGFloat
    let centerX: CGFloat
    let topY: CGFloat
    let bottomY: CGFloat
    let slots: [Slot]
    /// Number of stacked tiers (1…3). `topY` is always the top of the *topmost* tier,
    /// where the candles sit; tier geometry below it is derived through `tier*`.
    let tiers: Int
    /// Fixed-number cakes (coming-of-age) stand their digits as candles on the crown.
    let sideDigits: Bool

    var topRadiusX: CGFloat { cakeWidth / 2 }

    /// Each higher tier is a scaled-down copy: narrower, but NOT proportionally shorter.
    /// Reference cakes keep roughly the same wall height per tier; the perspective
    /// read comes from the width shrinking and the top ellipse flattening, not from
    /// squatting the upper tiers into discs.
    static func widthFrac(_ i: Int) -> CGFloat { 1 - CGFloat(i) * 0.17 }
    /// Wall height falls off towards the crown, matching the reference stack:
    /// bottom : middle : top ≈ 1 : 0.78 : 0.60. A uniform-height stack reads as
    /// three equal drums; tapering the walls is what makes it look like a cake.
    static func heightFrac(_ i: Int) -> CGFloat { 0.46 * ([1.0, 0.78, 0.60][min(i, 2)]) }

    init(size: CGSize, kinds: [CandleKind], candle: CandleStyle = .beeswax, tiers: Int = 1,
         cakeStyle: CakeStyle? = nil, cakeScale: CGFloat = 1) {
        let tiers = tiers.clamped(1, 3)
        let count = kinds.count
        // Coming-of-age cakes stand their fixed "18" as real candles on the crown.
        let sideDigits = cakeStyle == .comingOfAgeGirl || cakeStyle == .comingOfAgeBoy

        // Stack height: each tier sits on the TOP FACE of the tier below, not sunk
        // into it. The 1.05 step lifts it just past that face's centre so a clean
        // ledge of the lower top stays visible around it — the reference's read.
        var stackTop: CGFloat = 0
        for k in 0..<tiers { stackTop += Self.heightFrac(k) }
        // Number candles stand taller than sticks and carry a large flame: reserve
        // extra headroom so "18" + flames always fit above the crown.
        let heightFactor = stackTop + 0.30 + (sideDigits ? 0.92 : 0.55)
        // Number candles are much taller than sticks; give their cake extra air
        // on both sides so the flames never crowd the top of a preview or a card.
        let widthFraction: CGFloat = tiers == 1 ? (sideDigits ? 0.64 : 0.72)
                                                : (sideDigits ? 0.72 : 0.76)
        let w = min(size.width * widthFraction, size.height / heightFactor) * cakeScale
        // A flatter top ellipse (elbow-to-elbow ≈ 0.25 × width) matches the reference.
        let rx = w / 2, ry = w * 0.125, cx = size.width / 2
        // Leave a full 0.10w of clear space below the plate: the plate rim extends
        // ~0.21w past `bottom`, so the whole cake is always visible.
        let bottom = size.height - w * 0.32

        let candleTop = bottom - (tiers > 1 ? Self.tierDrop(tiers: tiers, w: w) : 0) - Self.heightFrac(tiers - 1) * w

        self.size = size
        cakeWidth = w
        sideHeight = w * Self.heightFrac(0)
        topRadiusY = ry
        centerX = cx
        bottomY = bottom
        topY = candleTop
        self.tiers = tiers
        self.sideDigits = sideDigits

        // Enlarged number candles, planted slightly behind the crown centre so the
        // bow tie / satin bow drawn in the foreground sits in front of their bases.
        if case .digit(_)? = kinds.first {
            // Smaller digits, but planted on the top face (not lifted into the
            // air behind it): the base sits at the centre of the top ellipse so
            // the candles read as standing ON the cake. The bow is lowered to match.
            let digitW = w * 0.255
            let digitH = w * 0.38
            slots = kinds.indices.map { i in
                let offset = (CGFloat(i) - CGFloat(count - 1) / 2) * digitW * 1.04
                // A lone digit stands dead centre on the top face; a pair is kept
                // slightly back so a foreground bow can sit in front of their bases.
                let y = count == 1 ? candleTop : candleTop - ry * 0.22
                return Slot(x: cx + offset, y: y, width: digitW, height: digitH, depth: 1)
            }
            return
        }

        let scale: CGFloat = count <= 6 ? 1 : max(0.68, 1 - CGFloat(count - 6) * 0.026)
        let candleW = w * 0.034 * scale
        let candleH = w * 0.22 * scale * candle.stature
        // candles stand on the topmost tier, which is narrower on a stacked cake
        let topRx = rx * Self.widthFrac(tiers - 1)

        func row(_ n: Int, y: CGFloat, spread: CGFloat, depth: CGFloat) -> [Slot] {
            guard n > 0 else { return [] }
            return (0..<n).map { i in
                let u: CGFloat = n == 1 ? 0 : (CGFloat(i) / CGFloat(n - 1)) * 2 - 1
                let x = cx + u * topRx * spread
                // A single candle sits dead centre of the top face; with a row the
                // middle candles dip slightly forward to follow the ellipse's arc.
                let arc: CGFloat = n == 1 ? 0 : ry * 0.22 * (1 - u * u)
                return Slot(x: x, y: y + arc, width: candleW * depth, height: candleH * depth, depth: depth)
            }
        }

        if count <= 7 {
            let spread: CGFloat = count == 1 ? 0 : min(0.72, 0.16 * CGFloat(count))
            slots = row(count, y: candleTop, spread: spread, depth: 1)
        } else {
            let back = (count + 1) / 2
            // The further row sits behind: smaller, higher and slightly dimmed, so
            // candles overlap the front row correctly instead of all reading flat.
            slots = row(back, y: candleTop - ry * 0.42, spread: 0.60, depth: 0.90)
                  + row(count - back, y: candleTop + ry * 0.40, spread: 0.70, depth: 1.0)
        }
    }

    /// How far below the base the topmost tier's crown sits, in points.
    private static func tierDrop(tiers: Int, w: CGFloat) -> CGFloat {
        var d: CGFloat = 0
        for k in 0..<(tiers - 1) { d += heightFrac(k) * w }
        return d
    }

    /// Geometry of tier `index` (0 = bottom). Each tier is a smaller copy as it rises.
    func tierBottom(_ index: Int) -> CGFloat {
        var y = bottomY
        for k in 0..<index { y -= Self.heightFrac(k) * cakeWidth }
        return y
    }
    func tierTop(_ index: Int) -> CGFloat { tierBottom(index) - Self.heightFrac(index) * cakeWidth }
    func tierWidth(_ index: Int) -> CGFloat { cakeWidth * Self.widthFrac(index) }
    func tierHeight(_ index: Int) -> CGFloat { cakeWidth * Self.heightFrac(index) }

    /// Where the flame of a candle sits (wick top), given how much it has burned.
    func wickTop(_ slot: Slot, kind: CandleKind, burn: Double) -> CGPoint {
        switch kind {
        case .stick:
            let visible = slot.height * (1 - CGFloat(burn))
            return CGPoint(x: slot.x, y: slot.y - visible - slot.width * 0.55)
        case .digit:
            return CGPoint(x: slot.x, y: slot.y - slot.height * 0.98)
        }
    }

    func flameSize(_ slot: Slot, kind: CandleKind) -> CGSize {
        let base: CGFloat
        switch kind {
        case .stick: base = max(slot.width * 5.2, 20)
        case .digit: base = cakeWidth * 0.20
        }
        return CGSize(width: base, height: base * 1.75)
    }
}
