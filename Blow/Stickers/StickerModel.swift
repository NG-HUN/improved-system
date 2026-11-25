import Foundation
import SwiftUI

/// Built-in ambient sticker motifs. Each is drawn in code so the app ships with
/// no image assets. Users can also place their own uploaded image (see `source`).
enum StickerMotif: String, Codable, CaseIterable, Identifiable {
    case balloon, star, heart, confetti, bubble, flower, gift, sparkle

    var id: String { rawValue }

    /// All built-in motifs are free.
    var notPro: Bool { false }

    var title: String {
        switch self {
        case .balloon: "Balloon"
        case .star: "Star"
        case .heart: "Heart"
        case .confetti: "Confetti"
        case .bubble: "Bubble"
        case .flower: "Flower"
        case .gift: "Gift"
        case .sparkle: "Sparkle"
        }
    }

    /// Base colour of the motif; the painter adds highlights and depth.
    var tint: Color {
        switch self {
        case .balloon: Color(hex: 0xE17DA2)
        case .star: Color(hex: 0xE9C169)
        case .heart: Color(hex: 0xE2526A)
        case .confetti: Color(hex: 0x7FB6E8)
        case .bubble: Color(hex: 0xBFE4F0)
        case .flower: Color(hex: 0xF3A2BE)
        case .gift: Color(hex: 0xC6943C)
        case .sparkle: Color(hex: 0xFFF0B8)
        }
    }
}

/// Where a sticker's image comes from.
enum StickerSource: Codable, Equatable {
    case builtin(StickerMotif)
    /// File name of a user-uploaded image stored in Documents/Stickers.
    case custom(String)
}

/// One placed sticker: which motif/image plus its normalised position, size and
/// rotation. Coordinates are 0…1 fractions of the canvas so they survive any
/// screen size; `anchor` keeps them near the cake rather than dead centre.
struct StickerPlacement: Codable, Equatable, Identifiable {
    let id: UUID
    var source: StickerSource
    /// Normalised centre (0…1) of the whole canvas.
    var x: CGFloat
    var y: CGFloat
    /// Fraction of canvas width.
    var scale: CGFloat
    var rotation: Double
    /// Gentle float phase, derived from id so each sticker drifts differently.
    var phase: Double

    init(id: UUID = UUID(), source: StickerSource, x: CGFloat, y: CGFloat,
         scale: CGFloat = 0.09, rotation: Double = 0, phase: Double? = nil) {
        self.id = id
        self.source = source
        self.x = x
        self.y = y
        self.scale = scale
        self.rotation = rotation
        self.phase = phase ?? Double(id.uuidString.hash % 1000) / 1000.0 * .pi * 2
    }
}

/// Curated starter layouts. Free users get the classic pack; the ceremony can
/// seed the canvas with one of these so the cake always opens with some ambience.
enum StickerPack {
    static func classic(seed: Int = 0) -> [StickerPlacement] {
        let jitter = CGFloat(seed % 5) * 0.01
        return [
            StickerPlacement(source: .builtin(.balloon), x: 0.16 + jitter, y: 0.30, scale: 0.10, rotation: -8),
            StickerPlacement(source: .builtin(.balloon), x: 0.84 - jitter, y: 0.26, scale: 0.09, rotation: 7),
            StickerPlacement(source: .builtin(.star), x: 0.26, y: 0.16, scale: 0.06, rotation: 12),
            StickerPlacement(source: .builtin(.heart), x: 0.74, y: 0.44, scale: 0.055, rotation: -10),
            StickerPlacement(source: .builtin(.confetti), x: 0.12, y: 0.52, scale: 0.07, rotation: 25),
            StickerPlacement(source: .builtin(.sparkle), x: 0.88, y: 0.56, scale: 0.05, rotation: 0),
        ]
    }
}
