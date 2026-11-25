import SwiftUI

/// A keepsake made to be kept and shared. Foiled gold — a real metallic gradient with
/// light and dark stops — runs through the frame, the corners and the lettering, over
/// deep card stock with a warm pool of candlelight behind the cake.
struct MemoryCard: View {
    let birthday: Birthday
    let date: Date
    let watermark: Bool

    // A five-stop metallic gold gradient: the alternating light/dark bands are what
    // read as real foil rather than a flat ochre colour.
    private let foil = LinearGradient(
        stops: [
            .init(color: Color(hex: 0x8A5E1E), location: 0),
            .init(color: Color(hex: 0xE7BE63), location: 0.22),
            .init(color: Color(hex: 0xFFF3C4), location: 0.42),
            .init(color: Color(hex: 0xD6A23A), location: 0.6),
            .init(color: Color(hex: 0xF6D98A), location: 0.78),
            .init(color: Color(hex: 0x8A5E1E), location: 1)
        ], startPoint: .topLeading, endPoint: .bottomTrailing)
    private let foilHorizontal = LinearGradient(
        stops: [
            .init(color: Color(hex: 0x8A5E1E), location: 0),
            .init(color: Color(hex: 0xF6D98A), location: 0.25),
            .init(color: Color(hex: 0xFFF3C4), location: 0.5),
            .init(color: Color(hex: 0xD6A23A), location: 0.75),
            .init(color: Color(hex: 0x8A5E1E), location: 1)
        ], startPoint: .leading, endPoint: .trailing)

    var body: some View {
        ZStack(alignment: .top) {
            // Warm polaroid stock with a fine double gold keyline — the foil that
            // ties this card to the gold used everywhere else in the app.
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(hex: 0xF7F4EE))
            RoundedRectangle(cornerRadius: 8)
                .stroke(foil, lineWidth: 2)
            RoundedRectangle(cornerRadius: 5)
                .stroke(foil.opacity(0.35), lineWidth: 0.7)
                .padding(7)

            VStack(spacing: 0) {
                // The photograph: a dark window holding the cake, framed in gold.
                ZStack {
                    Rectangle().fill(Color(hex: 0x17171C))
                    RadialGradient(colors: [Color(hex: 0xD6A23A).opacity(0.16), .clear],
                                   center: .init(x: 0.5, y: 0.58), startRadius: 10, endRadius: 170)
                    CakePreview(birthday: birthday, flicker: false)
                        .frame(height: 292)
                        .padding(.horizontal, 6)
                    Rectangle().stroke(foil.opacity(0.4), lineWidth: 1).padding(7)

                    HStack(spacing: 3) {
                        Text("✦").font(.system(size: 8))
                        Text("BLOW").font(.system(size: 9, weight: .heavy)).tracking(2)
                    }
                    .foregroundStyle(foil)
                    .position(x: 48, y: 24)

                    ForEach([0, 1, 2, 3], id: \.self) { k in
                        PhotoCorner()
                            .foregroundStyle(foil.opacity(0.9))
                            .rotationEffect(.degrees(Double(k) * 90))
                            .position(photoCornerPoint(k))
                    }
                }
                .frame(width: 312, height: 318)
                .padding(.horizontal, 24)
                .padding(.top, 24)

                foilRule(width: 240)
                    .padding(.top, 24)

                Text(birthday.recipient.isEmpty ? birthday.displayName : birthday.recipient)
                    .font(Theme.serif(30, weight: .medium).italic())
                    .foregroundStyle(Color(hex: 0x2A2621))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .padding(.horizontal, 18)
                    .padding(.top, 14)

                Text("HAPPY BIRTHDAY · \(date.formatted(.dateTime.year()))")
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(2.4)
                    .foregroundStyle(Color(hex: 0x9A8763))
                    .padding(.top, 5)

                if birthday.showAge && birthday.cake.fixedCandleDigits == nil {
                    Text("turning \(birthday.age)")
                        .font(Theme.serif(11).italic())
                        .foregroundStyle(Color(hex: 0x9A8763))
                        .padding(.top, 3)
                }

                Spacer(minLength: 0)

                HStack(alignment: .center) {
                    Text("✦")
                        .font(.system(size: 12))
                        .foregroundStyle(foil)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 1) {
                        Text(date.formatted(.dateTime.month(.abbreviated).day().year()))
                            .font(Theme.serif(11).italic())
                            .foregroundStyle(Color(hex: 0x8A7757))
                        if watermark {
                            Text("made with Blow ✦")
                                .font(.system(size: 8, weight: .medium)).tracking(1)
                                .foregroundStyle(Color(hex: 0x8A7757).opacity(0.6))
                        }
                    }
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 22)
            }
        }
        .frame(width: 360, height: 520)
    }

    /// Corners of the photo window, inset from its own bounds (312 × 318).
    private func photoCornerPoint(_ k: Int) -> CGPoint {
        let x: CGFloat = (k == 0 || k == 3) ? 12 : 300
        let y: CGFloat = (k == 0 || k == 1) ? 12 : 306
        return CGPoint(x: x, y: y)
    }

    private func cornerPoint(_ k: Int) -> CGPoint {
        let x: CGFloat = (k == 0 || k == 3) ? 20 : 340
        let y: CGFloat = (k == 0 || k == 1) ? 20 : 500
        return CGPoint(x: x, y: y)
    }

    private func foilRule(width: CGFloat) -> some View {
        ZStack {
            Rectangle().fill(foilHorizontal).frame(height: 0.9)
            Text("✦").font(.system(size: 9)).foregroundStyle(foil)
                .background(Color(hex: 0xF7F4EE)).padding(.horizontal, 6)
        }
        .frame(width: width)
    }
}

/// A small gold L-bracket that mounts a photo corner, like a real polaroid corner tack.
private struct PhotoCorner: View {
    var body: some View {
        Path { p in
            p.move(to: CGPoint(x: 0, y: 14))
            p.addLine(to: CGPoint(x: 0, y: 0))
            p.addLine(to: CGPoint(x: 14, y: 0))
        }
        .stroke(style: StrokeStyle(lineWidth: 2, lineCap: .round))
    }
}

/// An engraved gold corner flourish: a quarter arc with a small diamond stud.
private struct CornerFlourish: View {
    var body: some View {
        ZStack {
            Path { p in
                p.move(to: CGPoint(x: 2, y: 30))
                p.addQuadCurve(to: CGPoint(x: 30, y: 2), control: CGPoint(x: 2, y: 2))
            }
            .stroke(style: StrokeStyle(lineWidth: 1.1, lineCap: .round))
            Path { p in
                p.move(to: CGPoint(x: 7, y: 30))
                p.addQuadCurve(to: CGPoint(x: 30, y: 7), control: CGPoint(x: 7, y: 7))
            }
            .stroke(style: StrokeStyle(lineWidth: 0.6, lineCap: .round)).opacity(0.6)
            Path { p in
                p.move(to: CGPoint(x: 16, y: 14))
                p.addLine(to: CGPoint(x: 19, y: 17))
                p.addLine(to: CGPoint(x: 16, y: 20))
                p.addLine(to: CGPoint(x: 13, y: 17))
                p.closeSubpath()
            }
        }
    }
}

/// A rectangle with perforated (stamp-style) edges.
private struct PostageShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let tooth: CGFloat = 5
        let step: CGFloat = 12
        func notches(from a: CGPoint, to b: CGPoint) {
            let dx = b.x - a.x, dy = b.y - a.y
            let len = hypot(dx, dy)
            let n = max(1, Int(len / step))
            let ux = dx / len, uy = dy / len
            var current = a
            p.addLine(to: current)
            for i in 0..<n {
                let t0 = CGFloat(i) / CGFloat(n), t1 = (CGFloat(i) + 0.5) / CGFloat(n), t2 = (CGFloat(i) + 1) / CGFloat(n)
                let mid = CGPoint(x: a.x + dx * t1, y: a.y + dy * t1)
                let end = CGPoint(x: a.x + dx * t2, y: a.y + dy * t2)
                let nx = -uy, ny = ux
                p.addLine(to: CGPoint(x: a.x + dx * t0, y: a.y + dy * t0))
                p.addQuadCurve(to: end,
                               control: CGPoint(x: mid.x + nx * tooth, y: mid.y + ny * tooth))
                current = end
            }
            _ = current
        }
        let tl = CGPoint(x: rect.minX, y: rect.minY)
        let tr = CGPoint(x: rect.maxX, y: rect.minY)
        let br = CGPoint(x: rect.maxX, y: rect.maxY)
        let bl = CGPoint(x: rect.minX, y: rect.maxY)
        p.move(to: tl)
        notches(from: tl, to: tr)
        notches(from: tr, to: br)
        notches(from: br, to: bl)
        notches(from: bl, to: tl)
        p.closeSubpath()
        return p
    }
}

/// A small perforated postage stamp with the year and a tiny cake motif.
private struct Stamp: View {
    let date: Date
    var body: some View {
        VStack(spacing: 1) {
            Text("✦")
                .font(.system(size: 13))
                .foregroundStyle(Theme.glow)
            Text(date.formatted(.dateTime.year()))
                .font(Theme.serif(10, weight: .medium))
                .foregroundStyle(Theme.paper)
        }
        .frame(width: 46, height: 54)
        .background(Theme.nightRaised)
        .overlay(
            RoundedRectangle(cornerRadius: 1)
                .stroke(Theme.paper.opacity(0.55), style: StrokeStyle(lineWidth: 3, dash: [3, 3]))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 1)
                .stroke(Theme.paper.opacity(0.35), lineWidth: 0.8)
                .padding(5)
        )
        .rotationEffect(.degrees(-5))
        .shadow(color: .black.opacity(0.4), radius: 3, y: 2)
    }
}

/// A faded circular postmark over the corner of the card.
private struct Postmark: View {
    var body: some View {
        ZStack {
            Circle().stroke(Theme.paper.opacity(0.22), lineWidth: 1.5).frame(width: 44, height: 44)
            Circle().stroke(Theme.paper.opacity(0.16), lineWidth: 1).frame(width: 34, height: 34)
            Text("BLOW ✦")
                .font(.system(size: 7, weight: .bold)).tracking(1)
                .foregroundStyle(Theme.paper.opacity(0.35))
        }
        .rotationEffect(.degrees(-14))
    }
}

struct MemoryCardSheet: View {
    let birthday: Birthday
    @Environment(StoreManager.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var image: Image?
    @State private var date = Date()

    var body: some View {
        VStack(spacing: 24) {
            Capsule().fill(Color.white.opacity(0.15)).frame(width: 36, height: 5).padding(.top, 10)
            MemoryCard(birthday: birthday, date: date, watermark: !store.isPro)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Theme.hairline))
                .shadow(color: Theme.ember.opacity(0.18), radius: 30)
            if let image {
                ShareLink(item: image, preview: SharePreview("Happy Birthday, \(birthday.displayRecipient)", image: image)) {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .font(Theme.serif(18, weight: .medium))
                        .frame(maxWidth: 280)
                        .padding(.vertical, 14)
                        .background(Capsule().fill(Theme.paper))
                        .foregroundStyle(Theme.ink)
                }
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.night.ignoresSafeArea())
        .task { render() }
    }

    @MainActor
    private func render() {
        let renderer = ImageRenderer(content: MemoryCard(birthday: birthday, date: date, watermark: !store.isPro))
        renderer.scale = 3
        if let ui = renderer.uiImage { image = Image(uiImage: ui) }
    }
}
