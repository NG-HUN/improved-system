// Draws the app icon: a candle on sealing-wax red, its flame leaning away from someone's breath.
//
//   swiftc -O -parse-as-library tools/AppIcon.swift -o /tmp/appicon
//   /tmp/appicon Blow/Assets.xcassets/AppIcon.appiconset/AppIcon.png
//
// Not part of the app target.

import SwiftUI
import ImageIO
import UniformTypeIdentifiers

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255, opacity: opacity)
    }
}

/// A flame with its foot at the origin, `h` tall, the tip pushed to the right.
func blownFlame(height h: CGFloat) -> Path {
    var p = Path()
    p.move(to: .zero)
    p.addCurve(to: CGPoint(x: -0.20 * h, y: -0.27 * h), control1: CGPoint(x: -0.12 * h, y: 0), control2: CGPoint(x: -0.22 * h, y: -0.11 * h))
    p.addCurve(to: CGPoint(x: 0.36 * h, y: -1.0 * h), control1: CGPoint(x: -0.17 * h, y: -0.56 * h), control2: CGPoint(x: 0.20 * h, y: -0.66 * h))
    p.addCurve(to: CGPoint(x: 0.20 * h, y: -0.27 * h), control1: CGPoint(x: 0.30 * h, y: -0.80 * h), control2: CGPoint(x: 0.32 * h, y: -0.50 * h))
    p.addCurve(to: .zero, control1: CGPoint(x: 0.17 * h, y: -0.09 * h), control2: CGPoint(x: 0.11 * h, y: 0))
    p.closeSubpath()
    return p
}

struct AppIcon: View {
    var body: some View {
        Canvas { ctx, size in
            let s = size.width
            let full = Path(CGRect(x: 0, y: 0, width: s, height: s))
            let cx = s * 0.465

            // sealing wax: lit from where the flame is, falling off to oxblood in the corners
            ctx.fill(full, with: .color(Color(hex: 0x5A0B1E)))
            ctx.fill(full, with: .radialGradient(
                Gradient(stops: [.init(color: Color(hex: 0xD9566A), location: 0), .init(color: Color(hex: 0xB42A44), location: 0.34),
                                 .init(color: Color(hex: 0x8E1730), location: 0.68), .init(color: Color(hex: 0x5A0B1E), location: 1)]),
                center: CGPoint(x: s * 0.53, y: s * 0.40), startRadius: 0, endRadius: s * 0.80))

            let cw = s * 0.172
            let top = s * 0.665
            let rim = cw * 0.16                      // how much of the candle's top we see
            let wickTop = top - s * 0.050
            let flameH = s * 0.505

            // the light around the flame
            var light = ctx
            light.blendMode = .plusLighter
            let lc = CGPoint(x: cx + s * 0.05, y: wickTop - flameH * 0.46)
            light.fill(Path(ellipseIn: CGRect(x: lc.x - s * 0.5, y: lc.y - s * 0.5, width: s, height: s)),
                       with: .radialGradient(Gradient(colors: [Color(hex: 0xFFC27A, opacity: 0.42), Color(hex: 0xFF9A5A, opacity: 0.12), .clear]),
                                             center: lc, startRadius: 0, endRadius: s * 0.46))

            // the candle's shadow on the wax behind it
            var shade = ctx
            shade.addFilter(.blur(radius: s * 0.03))
            shade.fill(Path(CGRect(x: cx - cw * 0.5 + s * 0.035, y: top + s * 0.05, width: cw, height: s)), with: .color(Color(hex: 0x3A0512, opacity: 0.55)))

            // candle
            let body = CGRect(x: cx - cw / 2, y: top, width: cw, height: s)
            var candle = Path()
            candle.addRect(body)
            candle.addEllipse(in: CGRect(x: body.minX, y: top - rim, width: cw, height: rim * 2))
            ctx.fill(candle, with: .linearGradient(
                Gradient(stops: [.init(color: Color(hex: 0xD3BE9C), location: 0), .init(color: Color(hex: 0xFFF7E8), location: 0.30),
                                 .init(color: Color(hex: 0xFFF7E8), location: 0.56), .init(color: Color(hex: 0xC9B08A), location: 1)]),
                startPoint: CGPoint(x: body.minX, y: 0), endPoint: CGPoint(x: body.maxX, y: 0)))
            var lit = ctx
            lit.clip(to: candle)
            // the wax glows where the flame shines through it, and cools toward the foot
            lit.fill(Path(CGRect(x: body.minX, y: top - rim, width: cw, height: cw * 1.9)),
                     with: .linearGradient(Gradient(colors: [Color(hex: 0xFFC56E, opacity: 0.85), Color(hex: 0xFFC56E, opacity: 0)]),
                                           startPoint: CGPoint(x: 0, y: top - rim), endPoint: CGPoint(x: 0, y: top + cw * 1.9)))
            lit.fill(Path(body), with: .linearGradient(Gradient(colors: [.clear, Color(hex: 0x8E1730, opacity: 0.26)]),
                                                       startPoint: CGPoint(x: 0, y: top + cw * 0.9), endPoint: CGPoint(x: 0, y: s)))
            // the top: a shallow pool of melted wax
            let pool = CGRect(x: body.minX + cw * 0.07, y: top - rim * 0.78, width: cw * 0.86, height: rim * 1.56)
            ctx.fill(Path(ellipseIn: pool), with: .linearGradient(Gradient(colors: [Color(hex: 0xFFE2A6), Color(hex: 0xFFF6DC)]),
                                                                  startPoint: CGPoint(x: 0, y: pool.minY), endPoint: CGPoint(x: 0, y: pool.maxY)))
            // one short run of wax down the side
            let dx = body.minX + cw * 0.74, dw = cw * 0.13, dl = cw * 0.52
            var drip = Path()
            drip.addRoundedRect(in: CGRect(x: dx - dw / 2, y: top - rim * 0.3, width: dw, height: dl), cornerSize: CGSize(width: dw / 2, height: dw / 2))
            drip.addEllipse(in: CGRect(x: dx - dw * 0.62, y: top + dl - dw * 1.5, width: dw * 1.24, height: dw * 1.4))
            ctx.fill(drip.offsetBy(dx: s * 0.004, dy: s * 0.003), with: .color(Color(hex: 0xB9A07A, opacity: 0.45)))
            ctx.fill(drip, with: .color(Color(hex: 0xFFF6E4)))

            // wick
            var wick = Path()
            wick.move(to: CGPoint(x: cx, y: top + rim * 0.1))
            wick.addQuadCurve(to: CGPoint(x: cx + s * 0.014, y: wickTop), control: CGPoint(x: cx - s * 0.006, y: top - s * 0.03))
            ctx.stroke(wick, with: .color(Color(hex: 0x2A1810)), style: StrokeStyle(lineWidth: s * 0.015, lineCap: .round))

            // flame
            var f = ctx
            f.translateBy(x: cx + s * 0.010, y: wickTop + s * 0.016)
            var outer = f
            outer.addFilter(.blur(radius: s * 0.0035))
            outer.fill(blownFlame(height: flameH), with: .linearGradient(
                Gradient(stops: [.init(color: Color(hex: 0xF04E12), location: 0), .init(color: Color(hex: 0xFF8A1F), location: 0.28),
                                 .init(color: Color(hex: 0xFFBE4E), location: 0.60), .init(color: Color(hex: 0xFFE7A8), location: 1)]),
                startPoint: CGPoint(x: flameH * 0.34, y: -flameH), endPoint: .zero))
            var mid = f
            mid.addFilter(.blur(radius: s * 0.012))
            mid.translateBy(x: 0, y: -flameH * 0.02)
            mid.fill(blownFlame(height: flameH * 0.70), with: .color(Color(hex: 0xFFD98A, opacity: 0.75)))
            var core = f
            core.addFilter(.blur(radius: s * 0.010))
            core.translateBy(x: 0, y: -flameH * 0.045)
            core.fill(blownFlame(height: flameH * 0.46), with: .color(Color(hex: 0xFFFAEC)))
            var blue = f
            blue.addFilter(.blur(radius: s * 0.010))
            blue.fill(Path(ellipseIn: CGRect(x: -flameH * 0.075, y: -flameH * 0.065, width: flameH * 0.15, height: flameH * 0.085)),
                      with: .color(Color(hex: 0x5E93FF, opacity: 0.6)))
        }
        .frame(width: 1024, height: 1024)
    }
}

@main
struct Tool {
    @MainActor
    static func main() {
        let path = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "AppIcon.png"
        let renderer = ImageRenderer(content: AppIcon())
        renderer.scale = 1
        guard let image = renderer.cgImage else { fatalError("could not render the icon") }
        // App Store icons must not carry an alpha channel
        let space = CGColorSpace(name: CGColorSpace.sRGB)!
        let flat = CGContext(data: nil, width: 1024, height: 1024, bitsPerComponent: 8, bytesPerRow: 0, space: space,
                             bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
        flat.draw(image, in: CGRect(x: 0, y: 0, width: 1024, height: 1024))
        let dest = CGImageDestinationCreateWithURL(URL(fileURLWithPath: path) as CFURL, UTType.png.identifier as CFString, 1, nil)!
        CGImageDestinationAddImage(dest, flat.makeImage()!, nil)
        CGImageDestinationFinalize(dest)
        print("wrote", path)
    }
}
