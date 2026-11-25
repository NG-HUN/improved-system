import SwiftUI
import UIKit

/// A typeface the user can pick for any piece of writing in the app.
///
/// Every one of these ships with iOS, so nothing is bundled and there are no licensing
/// questions. They are grouped by *temperament* rather than by classification, because
/// that is what people actually choose between: a child's birthday and a fortieth want
/// very different letters.
///
/// PostScript names were verified against the system font database. `font(_:)` probes the
/// name at runtime and falls back to a system design if a device is missing it, so a wrong
/// or absent face can never silently leave the app looking unchanged.
enum Typeface: String, Codable, CaseIterable, Identifiable {
    case classic            // the app as it shipped: a system serif

    // MARK: mature & elegant — fashion houses, black-tie
    case didot, bodoni, hoefler

    // MARK: cute & playful — children, birthdays with cake on their face
    case noteworthy, chalkboard, markerFelt, bradleyHand

    // MARK: script & decorative — signatures, vows, the flourish
    case snell, zapfino, savoye, copperplate

    // MARK: classical & warm — letters, lyrics, anything read aloud
    case baskerville, palatino, typewriter

    // MARK: modern & minimal — gallery walls, no decoration
    case avenir, futura, optima, helvetica

    var id: String { rawValue }

    /// What the picker shows. English names: the app's own copy is English.
    var title: String {
        switch self {
        case .classic:      "Classic"
        case .didot:        "Didot"
        case .bodoni:       "Bodoni 72"
        case .hoefler:      "Hoefler Text"
        case .noteworthy:   "Noteworthy"
        case .chalkboard:   "Chalkboard"
        case .markerFelt:   "Marker Felt"
        case .bradleyHand:  "Bradley Hand"
        case .snell:        "Snell Roundhand"
        case .zapfino:      "Zapfino"
        case .savoye:       "Savoye"
        case .copperplate:  "Copperplate"
        case .baskerville:  "Baskerville"
        case .palatino:     "Palatino"
        case .typewriter:   "Typewriter"
        case .avenir:       "Avenir Next"
        case .futura:       "Futura"
        case .optima:       "Optima"
        case .helvetica:    "Helvetica Neue"
        }
    }

    /// One line under the name in the picker.
    var mood: String {
        switch self {
        case .classic:      "the way it has always been"
        case .didot:        "high fashion, high contrast"
        case .bodoni:       "engraved and exacting"
        case .hoefler:      "quiet authority"
        case .noteworthy:   "a note left on the fridge"
        case .chalkboard:   "café specials and classroom walls"
        case .markerFelt:   "felt tip, pressed a little hard"
        case .bradleyHand:  "someone's actual handwriting"
        case .snell:        "copperplate script, for a signature"
        case .zapfino:      "the full flourish"
        case .savoye:       "thin decorative hand"
        case .copperplate:  "ALL CAPS, letterspaced"
        case .baskerville:  "read aloud, by candlelight"
        case .palatino:     "humanist and warm"
        case .typewriter:   "a postcard, typed"
        case .avenir:       "geometric, unhurried"
        case .futura:       "Bauhaus, forward-looking"
        case .optima:       "humanist sans, YSL's choice"
        case .helvetica:    "neutral to the point of absolute"
        }
    }

    enum Temperament: String, CaseIterable, Identifiable {
        case elegant, playful, script, classical, modern
        var id: String { rawValue }

        var title: String {
            switch self {
            case .elegant:   "Mature & Elegant"
            case .playful:   "Cute & Playful"
            case .script:    "Script & Decorative"
            case .classical: "Classical & Warm"
            case .modern:    "Modern & Minimal"
            }
        }

        var subtitle: String {
            switch self {
            case .elegant:   "fashion houses, black-tie"
            case .playful:   "children, confetti"
            case .script:    "signatures, vows"
            case .classical: "letters, lyrics"
            case .modern:    "gallery walls"
            }
        }
    }

    var temperament: Temperament {
        switch self {
        case .classic: .classical
        case .didot, .bodoni, .hoefler: .elegant
        case .noteworthy, .chalkboard, .markerFelt, .bradleyHand: .playful
        case .snell, .zapfino, .savoye, .copperplate: .script
        case .baskerville, .palatino, .typewriter: .classical
        case .avenir, .futura, .optima, .helvetica: .modern
        }
    }

    static func faces(in temperament: Temperament) -> [Typeface] {
        allCases.filter { $0.temperament == temperament }
    }

    /// PostScript name, as CoreText knows it. nil for `.classic`, which uses the system face.
    var postScriptName: String? {
        switch self {
        case .classic:      nil
        case .didot:        "Didot"
        case .bodoni:       "BodoniSvtyTwoITCTT-Book"
        case .hoefler:      "HoeflerText-Regular"
        case .noteworthy:   "Noteworthy-Light"
        case .chalkboard:   "ChalkboardSE-Regular"
        case .markerFelt:   "MarkerFelt-Thin"
        case .bradleyHand:  "BradleyHandITCTT-Bold"
        case .snell:        "SnellRoundhand"
        case .zapfino:      "Zapfino"
        case .savoye:       "SavoyeLetPlain"
        case .copperplate:  "Copperplate-Light"
        case .baskerville:  "Baskerville"
        case .palatino:     "Palatino-Roman"
        case .typewriter:   "AmericanTypewriter"
        case .avenir:       "AvenirNext-Regular"
        case .futura:       "Futura-Medium"
        case .optima:       "Optima-Regular"
        case .helvetica:    "HelveticaNeue"
        }
    }

    /// System design to fall back on if this device somehow lacks the face.
    var fallbackDesign: Font.Design {
        switch self {
        case .classic, .didot, .bodoni, .hoefler,
             .baskerville, .palatino, .snell, .savoye: .serif
        case .noteworthy, .chalkboard, .markerFelt, .bradleyHand, .zapfino: .rounded
        case .copperplate, .typewriter: .monospaced
        case .avenir, .futura, .optima, .helvetica: .default
        }
    }

    /// Whether the face is really a handwriting/script one. These need a larger point size
    /// to read at the same optical weight, and are drawn italic where that suits them.
    var isScript: Bool {
        switch self {
        case .snell, .zapfino, .savoye, .bradleyHand: true
        default: false
        }
    }

    /// Should the face be uppercased and letterspaced? Only Copperplate is designed for it.
    var prefersUppercase: Bool { self == .copperplate }

    /// Tracking to add when uppercasing, in em-ish units of the point size.
    var tracking: CGFloat { prefersUppercase ? 0.18 : 0 }

    /// Optical size correction. Script faces have thin strokes and small x-heights, so the
    /// same point size reads smaller; this scales them up to look equal beside a serif.
    var opticalSize: CGFloat {
        switch self {
        case .zapfino:      0.82   // enormous swashes: shrink so it fits the line
        case .snell:        1.16
        case .savoye:       1.22
        case .bradleyHand:  1.10
        case .noteworthy:   1.06
        case .markerFelt:   1.04
        case .copperplate:  1.12   // small caps read small
        case .typewriter:   1.04
        case .helvetica:    1.02
        default:            1.0
        }
    }

    /// The SwiftUI font at a given point size.
    func font(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        guard let name = postScriptName, UIFont(name: name, size: size) != nil else {
            return .system(size: size, weight: weight, design: fallbackDesign)
        }
        let corrected = size * opticalSize
        var f = Font.custom(name, size: corrected)
        // Only these two ship a real italic that suits the app's voice.
        if weight != .regular, self != .bradleyHand {
            f = f.weight(weight)
        }
        return f
    }

    /// Italic variant where the face has one, otherwise the same face. Used for subtitles
    /// and the wish copy, which the app sets in italic by default.
    func italicFont(_ size: CGFloat) -> Font {
        guard let name = postScriptName, UIFont(name: name, size: size) != nil else {
            return .system(size: size, design: fallbackDesign).italic()
        }
        // Faces without an italic member: fall back to the system serif italic so the
        // voice stays consistent rather than returning an upright face that looks unchanged.
        return switch self {
        case .didot:        Font.custom("Didot-Italic", size: size * opticalSize)
        case .bodoni:       Font.custom("BodoniSvtyTwoITCTT-BookIta", size: size * opticalSize)
        case .hoefler:      Font.custom("HoeflerText-Italic", size: size * opticalSize)
        case .baskerville:  Font.custom("Baskerville-Italic", size: size * opticalSize)
        case .palatino:     Font.custom("Palatino-Italic", size: size * opticalSize)
        case .typewriter:   Font.custom("AmericanTypewriter", size: size * opticalSize)
        case .avenir:       Font.custom("AvenirNext-Italic", size: size * opticalSize)
        case .helvetica:    Font.custom("HelveticaNeue-Italic", size: size * opticalSize)
        case .futura:       Font.custom("Futura-MediumItalic", size: size * opticalSize)
        case .optima:       Font.custom("Optima-Italic", size: size * opticalSize)
        case .classic:      Font.system(size: size, design: .serif).italic()
        default:            // scripts are already slanted; upright looks wrong when scaled
            font(size)
        }
    }

    /// True when this device actually has the face, so the picker can flag the rest.
    var isAvailable: Bool {
        guard let name = postScriptName else { return true }
        return UIFont(name: name, size: 12) != nil
    }
}

/// Where a typeface is used. Each slot can be set independently, which is the point:
/// a Didot title over a Bradley Hand signature is exactly the kind of pairing people want.
enum TypeSlot: String, Codable, CaseIterable, Identifiable {
    case title      // "Happy Birthday" on the ceremony and the card
    case lyrics     // the four sung lines
    case cake       // the lettering piped onto the cake
    case signature  // the name, and the card's "to you"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .title:      "Title"
        case .lyrics:     "Lyrics"
        case .cake:       "On the cake"
        case .signature:  "Name & signature"
        }
    }

    var hint: String {
        switch self {
        case .title:      "Happy Birthday"
        case .lyrics:      "the four sung lines"
        case .cake:       "piped onto the side"
        case .signature:  "whose birthday it is"
        }
    }

    /// The default for each slot, matching how the app looked before typefaces existed.
    var defaultFace: Typeface {
        switch self {
        case .title:      .classic
        case .lyrics:     .classic
        case .cake:       .classic
        case .signature:  .classic
        }
    }
}
