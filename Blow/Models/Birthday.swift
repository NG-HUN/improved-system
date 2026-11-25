import SwiftUI

/// The piped message on the wall of a cake. Every style has its own size, position,
/// colour, face and finish, so the same words feel at home on a rustic sponge and on a
/// dark chocolate ganache. `maxChars` keeps long names off cakes that cannot carry them.
struct LetteringSpec {
    var v: CGFloat = 0.60              // height on the wall, 0 = top, 1 = bottom
    var size: CGFloat = 0.074          // font size as a fraction of cake width
    var weight: Font.Weight = .medium
    var design: Font.Design = .serif
    var italic: Bool = true
    var uppercase: Bool = false
    var spacing: CGFloat = 0           // extra tracking as a fraction of cake width
    var colorHex: UInt32 = 0x7A4A28
    var shadowHex: UInt32 = 0xFFFFFF
    var shadowOpacity: Double = 0.35
    /// 0 = flat print, 1 = heavily piped / embossed. Drives the relief passes.
    var relief: Double = 0.45
    var maxChars: Int = 22

    var color: Color { Color(hex: colorHex) }
    var shadow: Color { Color(hex: shadowHex).opacity(shadowOpacity) }
    func font(width w: CGFloat) -> Font {
        var f = Font.system(size: w * size, weight: weight, design: design)
        if italic { f = f.italic() }
        return f
    }
}

/// User edits to the piped message, layered on top of the cake style's own design.
/// Every field is optional: `nil` keeps the style default, so each cake still looks
/// the way it was designed until the user chooses to change that attribute.
struct TextEdit: Codable, Equatable {
    /// Height on the wall, 0 = top, 1 = bottom.
    var v: CGFloat? = nil
    /// Font size as a fraction of cake width.
    var size: CGFloat? = nil
    /// 24-bit RGB of the piped icing; `nil` uses the style's colour.
    var colorHex: UInt32? = nil

    var isEmpty: Bool { v == nil && size == nil && colorHex == nil }

    /// Apply this edit onto a style's lettering spec.
    func applied(to base: LetteringSpec) -> LetteringSpec {
        var s = base
        if let v { s.v = v }
        if let size { s.size = size }
        if let colorHex { s.colorHex = colorHex }
        return s
    }
}

/// A cake and everything that comes with it: its stand, what lies on the table, and the candles
/// it was designed around.
enum CakeStyle: String, Codable, CaseIterable, Identifiable {
    case wildflower, cherry, noir, starry, roseWindow
    case berry, azure, christmasTree, halloween
    case comingOfAgeGirl, comingOfAgeBoy
    var id: String { rawValue }

    /// The craft cakes and the seasonal / occasion cakes are the Pro collection.
    /// The everyday sponges stay free so the ritual is always within reach.
    var isPro: Bool {
        switch self {
        case .noir, .roseWindow, .christmasTree, .halloween, .comingOfAgeGirl, .comingOfAgeBoy: true
        default: false
        }
    }

    var title: String {
        switch self {
        case .wildflower: "Wildflower"
        case .cherry: "Cherry Vintage"
        case .noir: "Noir & Gold"
        case .starry: "Starry Night"
        case .roseWindow: "Rose Window"
        case .berry: "Berry Buttercream"
        case .azure: "Azure Wave"
        case .christmasTree: "Christmas Tree"
        case .halloween: "Halloween"
        case .comingOfAgeGirl: "Sweet Eighteen"
        case .comingOfAgeBoy: "Coming of Age"
        }
    }

    /// One line under the name in the picker.
    var mood: String {
        switch self {
        case .wildflower: "picked this morning"
        case .cherry: "sweet as a love letter"
        case .noir: "dark chocolate, gold leaf"
        case .starry: "painted after dark"
        case .roseWindow: "light through coloured glass"
        case .berry: "whipped, with berries"
        case .azure: "blue, and a little playful"
        case .christmasTree: "a little evergreen"
        case .halloween: "trick or treat"
        case .comingOfAgeGirl: "a pink ribbon, eighteen"
        case .comingOfAgeBoy: "a blue bow tie, eighteen"
        }
    }

    /// The candles this cake was drawn with. Picking the cake picks these; they can still be swapped.
    var candle: CandleStyle {
        switch self {
        case .wildflower: .beeswax
        case .cherry: .pearl
        case .noir: .gilded
        case .starry: .stardust
        case .roseWindow: .altar
        case .berry: .twist
        case .azure: .stardust
        case .christmasTree: .gilded
        case .halloween: .candy
        case .comingOfAgeGirl: .pearl
        case .comingOfAgeBoy: .midnight
        }
    }

    /// Occasion cakes that always carry a fixed number candle ("18"), which cannot be edited.
    var fixedCandleDigits: String? {
        switch self {
        case .comingOfAgeGirl, .comingOfAgeBoy: "18"
        default: nil
        }
    }

    /// The colour of the one shared cake stand, so each cake sits on a plate
    /// that belongs to it while keeping the same silhouette.
    var standLight: Color {
        switch self {
        case .wildflower: Color(hex: 0xFFF8EA)
        case .cherry:     Color(hex: 0xFFFBF6)
        case .noir:       Color(hex: 0xFFE9A8)
        case .starry:     Color(hex: 0xD8DDE5)
        case .roseWindow: Color(hex: 0xF7DE96)
        case .berry:      Color(hex: 0xFFF4F6)
        case .azure:      Color(hex: 0xE4F2FF)
        case .christmasTree: Color(hex: 0xE8F0E4)
        case .halloween: Color(hex: 0xF6E3C8)
        case .comingOfAgeGirl: Color(hex: 0xFFF0F4)
        case .comingOfAgeBoy:  Color(hex: 0xEAF0FA)
        }
    }
    var standDark: Color {
        switch self {
        case .wildflower: Color(hex: 0xB89A70)
        case .cherry:     Color(hex: 0xC6B5AE)
        case .noir:       Color(hex: 0x8A6220)
        case .starry:     Color(hex: 0x4A5260)
        case .roseWindow: Color(hex: 0x86611F)
        case .berry:      Color(hex: 0xCE9AAC)
        case .azure:      Color(hex: 0x7FA8D4)
        case .christmasTree: Color(hex: 0x5A7A52)
        case .halloween: Color(hex: 0x8A5A2E)
        case .comingOfAgeGirl: Color(hex: 0xD2A0B2)
        case .comingOfAgeBoy:  Color(hex: 0x8FA2C4)
        }
    }
    var standAccent: Color? {
        switch self {
        case .noir: Color(hex: 0xFFF1B8)
        case .comingOfAgeGirl: Color(hex: 0xEFA8C0)
        case .comingOfAgeBoy: Color(hex: 0x6C86BC)
        default: Color(hex: 0xD9B25A)
        }
    }

    /// Material and rim treatment of the shared flat plate, matched to each cake.
    enum PlateFinish {
        case porcelain, scallop, gold, roseGold, slate, mirrored, wood, marble
    }
    var plateFinish: PlateFinish {
        switch self {
        case .wildflower: .wood
        case .cherry: .scallop
        case .noir: .gold
        case .starry: .slate
        case .roseWindow: .gold
        case .berry: .porcelain
        case .azure: .mirrored
        case .christmasTree: .slate
        case .halloween: .wood
        case .comingOfAgeGirl: .scallop
        case .comingOfAgeBoy:  .marble
        }
    }

    /// Per-cake lettering design: size, place, colour, face and finish are all deliberate.
    var lettering: LetteringSpec {
        switch self {
        case .wildflower:  // hand-piped script low on rustic sponge
            LetteringSpec(v: 0.56, size: 0.074, design: .serif, italic: true,
                          colorHex: 0x7A4A28, shadowHex: 0xFFFFFF, shadowOpacity: 0.38, relief: 0.35, maxChars: 24)
        case .cherry:      //高贵 vintage script, a little larger
            LetteringSpec(v: 0.71, size: 0.078, weight: .medium, design: .serif, italic: true,
                          colorHex: 0xA61E3C, shadowHex: 0xFFFFFF, shadowOpacity: 0.5, relief: 0.55, maxChars: 22)
        case .noir:        // small gold script, low, glowing against dark ganache
            LetteringSpec(v: 0.62, size: 0.070, weight: .medium, design: .serif, italic: true,
                          colorHex: 0xF1CD72, shadowHex: 0x000000, shadowOpacity: 0.6, relief: 0.65, maxChars: 20)
        case .starry:      // delicate cream script near the foot
            LetteringSpec(v: 0.905, size: 0.066, weight: .medium, design: .serif, italic: true,
                          colorHex: 0xF3DE9E, shadowHex: 0x000000, shadowOpacity: 0.6, relief: 0.5, maxChars: 24)
        case .roseWindow:  // formal spaced serif, small capitals
            LetteringSpec(v: 0.888, size: 0.050, weight: .semibold, design: .serif, italic: false,
                          uppercase: true, spacing: 0.007,
                          colorHex: 0x8A6526, shadowHex: 0xFFFFFF, shadowOpacity: 0.5, relief: 0.30, maxChars: 26)
        case .berry:       // soft cream script
            LetteringSpec(v: 0.70, size: 0.074, design: .serif, italic: true,
                          colorHex: 0x9A5A6A, shadowHex: 0xFFFFFF, shadowOpacity: 0.45, relief: 0.4, maxChars: 22)
        case .azure:       // bold rounded, modern
            LetteringSpec(v: 0.72, size: 0.074, weight: .semibold, design: .rounded, italic: false,
                          colorHex: 0x1E3E7A, shadowHex: 0xFFFFFF, shadowOpacity: 0.5, relief: 0.55, maxChars: 20)
        case .christmasTree: // warm gold script near the foot
            LetteringSpec(v: 0.90, size: 0.070, design: .serif, italic: true,
                          colorHex: 0xF6E3A8, shadowHex: 0x000000, shadowOpacity: 0.5, relief: 0.55, maxChars: 22)
        case .halloween:   // heavy rounded orange, playful
            LetteringSpec(v: 0.72, size: 0.076, weight: .heavy, design: .rounded, italic: false,
                          colorHex: 0xFF9A3C, shadowHex: 0x000000, shadowOpacity: 0.6, relief: 0.8, maxChars: 18)
        case .comingOfAgeGirl: // pink embossed capitals, the birthday greeting is the decoration
            LetteringSpec(v: 0.62, size: 0.082, weight: .heavy, design: .rounded, italic: false,
                          uppercase: true, spacing: 0.004,
                          colorHex: 0xEC8FAE, shadowHex: 0xFFFFFF, shadowOpacity: 0.7, relief: 0.95, maxChars: 18)
        case .comingOfAgeBoy:  // indigo embossed capitals
            LetteringSpec(v: 0.62, size: 0.080, weight: .heavy, design: .rounded, italic: false,
                          uppercase: true, spacing: 0.004,
                          colorHex: 0x2E4A86, shadowHex: 0xFFFFFF, shadowOpacity: 0.7, relief: 0.95, maxChars: 18)
        }
    }
}

/// A small extra arranged on the crown of the cake, on top of whatever the
/// style already draws. None is the default, so existing birthdays look the same.
enum CakeTopper: String, Codable, CaseIterable, Identifiable {
    case none, berries, blossoms, goldLeaf, stars
    var id: String { rawValue }
    var isPro: Bool { self == .goldLeaf || self == .stars }
    var title: String {
        switch self {
        case .none: "None"
        case .berries: "Berries"
        case .blossoms: "Blossoms"
        case .goldLeaf: "Gold leaf"
        case .stars: "Stars"
        }
    }
}

enum CandleStyle: String, Codable, CaseIterable, Identifiable {
    case beeswax, pearl, gilded, twist, stardust, altar, candy, midnight
    var id: String { rawValue }
    var isPro: Bool { self == .midnight }

    var title: String {
        switch self {
        case .beeswax: "Beeswax"
        case .pearl: "Pearl"
        case .gilded: "Gilded"
        case .twist: "Candy Twist"
        case .stardust: "Stardust"
        case .altar: "Altar"
        case .candy: "Licorice"
        case .midnight: "Midnight"
        }
    }

    /// Light side and shadow side of the wax.
    var wax: [Color] {
        switch self {
        case .beeswax: [Color(hex: 0xF3C567), Color(hex: 0xB9822E)]
        case .pearl: [Color(hex: 0xFFF8F2), Color(hex: 0xE2C2C0)]
        case .gilded: [Color(hex: 0xFBE29A), Color(hex: 0xA97B2C)]
        case .twist: [Color(hex: 0xFFFDF8), Color(hex: 0xD9D0C6)]
        case .stardust: [Color(hex: 0xFDF6E3), Color(hex: 0xC9BCA0)]
        case .altar: [Color(hex: 0xFFF7E6), Color(hex: 0xD3C19E)]
        case .candy: [Color(hex: 0xE8506E), Color(hex: 0x9C1F3C)]
        case .midnight: [Color(hex: 0x4A4B7C), Color(hex: 0x1B1B3A)]
        }
    }

    /// How thick the candle is drawn, relative to a plain one.
    var girth: CGFloat {
        switch self {
        case .beeswax: 1.0
        case .pearl: 0.62
        case .gilded: 0.70
        case .twist: 1.18
        case .stardust: 0.82
        case .altar: 1.30
        case .candy: 0.90
        case .midnight: 0.74
        }
    }

    /// How tall it stands, relative to a plain one. Tapers are tall, party candles short.
    var stature: CGFloat {
        switch self {
        case .beeswax: 1.0
        case .pearl: 1.42
        case .gilded: 1.32
        case .twist: 0.82
        case .stardust: 1.08
        case .altar: 1.20
        case .candy: 0.94
        case .midnight: 1.50
        }
    }
}

enum SongLanguage: String, Codable, CaseIterable, Identifiable {
    case english, spanish, french, german, chinese
    var id: String { rawValue }
    var isPro: Bool { self != .english }

    var title: String {
        switch self {
        case .english: "English"
        case .spanish: "Español"
        case .french: "Français"
        case .german: "Deutsch"
        case .chinese: "中文"
        }
    }

    /// Four sung lines, the third one carries the name.
    func lines(name: String) -> [String] {
        let n = name.trimmingCharacters(in: .whitespaces)
        switch self {
        case .english:
            return ["Happy birthday to you", "Happy birthday to you",
                    n.isEmpty ? "Happy birthday, dear friend" : "Happy birthday, dear \(n)",
                    "Happy birthday to you"]
        case .spanish:
            return ["Cumpleaños feliz", "Te deseamos a ti",
                    n.isEmpty ? "Cumpleaños, querido amigo" : "Cumpleaños, \(n)",
                    "Cumpleaños feliz"]
        case .french:
            return ["Joyeux anniversaire", "Joyeux anniversaire",
                    n.isEmpty ? "Joyeux anniversaire" : "Joyeux anniversaire, \(n)",
                    "Joyeux anniversaire"]
        case .german:
            return ["Zum Geburtstag viel Glück", "Zum Geburtstag viel Glück",
                    n.isEmpty ? "Zum Geburtstag, alles Liebe" : "Zum Geburtstag, liebe(r) \(n)",
                    "Zum Geburtstag viel Glück"]
        case .chinese:
            return ["祝你生日快乐", "祝你生日快乐",
                    n.isEmpty ? "祝你生日快乐" : "祝\(n)生日快乐",
                    "祝你生日快乐"]
        }
    }
}

enum CandleKind: Equatable {
    case stick
    case digit(Character)
}

struct Birthday: Codable, Equatable, Identifiable {
    /// Stable identity for saved presets / reminders.
    var id: UUID = UUID()
    /// Optional birthday date used by the reminder system.
    var birthDate: Date?
    /// A short label for this preset in the birthday library.
    var label: String = ""
    var name: String = ""
    /// Person the celebration is for — shown in "for …" and on the keepsake card.
    var recipient: String = ""
    var age: Int = 1
    var showAge: Bool = true
    /// nil = automatic (number candles above 20)
    var numberCandles: Bool? = nil
    var cakeText: String = "Happy Birthday"
    /// Optional user edits to the message's position, size and colour.
    var textEdit: TextEdit = TextEdit()
    var cake: CakeStyle = .wildflower
    var candle: CandleStyle = .beeswax
    var topper: CakeTopper = .none
    /// 1–3 stacked tiers. Kept optional in archives so old birthdays stay single-tier.
    var tiers: Int = 1
    var language: SongLanguage = .english
    /// Which birthday tune to play. Defaults to the original song so existing
    /// birthdays are unchanged.
    var song: SongChoice = .classic
    var rounds: Int = 1
    /// Ambient stickers arranged around the cake. Empty means none placed yet.
    var stickers: [StickerPlacement] = []

    /// Each piece of writing can be set in its own face. Defaults reproduce the app
    /// as it shipped, so an existing saved birthday looks unchanged after updating.
    var titleFont: Typeface = .classic
    var lyricsFont: Typeface = .classic
    var cakeFont: Typeface = .classic
    var signatureFont: Typeface = .classic

    func face(for slot: TypeSlot) -> Typeface {
        switch slot {
        case .title:      titleFont
        case .lyrics:     lyricsFont
        case .cake:       cakeFont
        case .signature:  signatureFont
        }
    }

    mutating func setFace(_ face: Typeface, for slot: TypeSlot) {
        switch slot {
        case .title:      titleFont = face
        case .lyrics:     lyricsFont = face
        case .cake:       cakeFont = face
        case .signature:  signatureFont = face
        }
    }

    var usesNumberCandles: Bool { numberCandles ?? (age > 20) }

    var candleKinds: [CandleKind] {
        if let digits = cake.fixedCandleDigits { return Array(digits).map { .digit($0) } }
        guard showAge else { return [.stick] }
        if usesNumberCandles { return String(max(age, 0)).map { .digit($0) } }
        return Array(repeating: .stick, count: max(1, min(age, 20)))
    }

    var displayName: String {
        let n = name.trimmingCharacters(in: .whitespaces)
        return n.isEmpty ? "you" : n
    }
    /// Who the cake is for; defaults to the celebrant's name.
    var displayRecipient: String {
        let n = recipient.trimmingCharacters(in: .whitespaces)
        return n.isEmpty ? displayName : n
    }

    var cakeTextLimit: Int { cake.lettering.maxChars }

    // MARK: persistence
    private static let key = "blow.birthday.v1"

    static func load() -> Birthday {
        var b: Birthday
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode(Birthday.self, from: data) {
            b = decoded
        } else {
            b = Birthday()
        }
        #if DEBUG
        // `-blow.cake noir` on the command line picks a cake for screenshots
        if let raw = UserDefaults.standard.string(forKey: "blow.tiers"), let t = Int(raw) {
            b.tiers = t.clamped(1, 3)
        }
        if let raw = UserDefaults.standard.string(forKey: "blow.cake"), let cake = CakeStyle(rawValue: raw) {
            b.cake = cake
            b.candle = cake.candle
        }
        if let raw = UserDefaults.standard.string(forKey: "blow.age"), let age = Int(raw) {
            b.age = age
        }
        if let raw = UserDefaults.standard.string(forKey: "blow.numberCandles"), let use = Bool(raw) {
            b.numberCandles = use
        }
        // Lettering overrides for verifying position / size / colour on screenshots.
        if let raw = UserDefaults.standard.string(forKey: "blow.textV"), let v = Double(raw) {
            b.textEdit.v = CGFloat(v).clamped(0.3, 0.92)
        }
        if let raw = UserDefaults.standard.string(forKey: "blow.textSize"), let s = Double(raw) {
            b.textEdit.size = CGFloat(s).clamped(0.035, 0.14)
        }
        if let raw = UserDefaults.standard.string(forKey: "blow.textColor"), let h = UInt32(raw, radix: 16) {
            b.textEdit.colorHex = h
        }
        if let raw = UserDefaults.standard.string(forKey: "blow.candle"), let c = CandleStyle(rawValue: raw) {
            b.candle = c
        }
        if let raw = UserDefaults.standard.string(forKey: "blow.song"), let choice = SongChoice(rawValue: raw) {
            b.song = choice
        }
        if UserDefaults.standard.string(forKey: "blow.stickers") == "classic" {
            b.stickers = StickerPack.classic()
        }
        // Debug: one large heart sticker to inspect the motif's outline.
        if UserDefaults.standard.string(forKey: "blow.heart") == "1" {
            b.stickers = [StickerPlacement(source: .builtin(.heart), x: 0.5, y: 0.42, scale: 0.28, rotation: 0)]
        }
        #endif
        return b
    }

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.key)
        }
    }
}

extension Birthday {
    /// Reads what it can and keeps the default for the rest, so a birthday saved by an older
    /// build (with cakes that no longer exist) still opens with its name and age.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init()
        if let v = try? c.decode(UUID.self, forKey: .id) { id = v }
        if let v = try? c.decode(Date.self, forKey: .birthDate) { birthDate = v }
        if let v = try? c.decode(String.self, forKey: .label) { label = v }
        if let v = try? c.decode(String.self, forKey: .name) { name = v }
        if let v = try? c.decode(String.self, forKey: .recipient) { recipient = v }
        if let v = try? c.decode(Int.self, forKey: .age) { age = v }
        if let v = try? c.decode(Bool.self, forKey: .showAge) { showAge = v }
        numberCandles = try? c.decode(Bool.self, forKey: .numberCandles)
        if let v = try? c.decode(String.self, forKey: .cakeText) { cakeText = v }
        if let v = try? c.decode(TextEdit.self, forKey: .textEdit) { textEdit = v }
        if let v = try? c.decode(CakeStyle.self, forKey: .cake) { cake = v }
        if let v = try? c.decode(CandleStyle.self, forKey: .candle) { candle = v } else { candle = cake.candle }
        if let v = try? c.decode(CakeTopper.self, forKey: .topper) { topper = v }
        if let v = try? c.decode(Int.self, forKey: .tiers) { tiers = v.clamped(1, 3) }
        if let v = try? c.decode(SongLanguage.self, forKey: .language) { language = v }
        if let v = try? c.decode(SongChoice.self, forKey: .song) { song = v }
        if let v = try? c.decode(Int.self, forKey: .rounds) { rounds = v }
        if let v = try? c.decode([StickerPlacement].self, forKey: .stickers) { stickers = v }
        // Fonts arrived later than the first release; an older archive simply keeps the defaults.
        if let v = try? c.decode(Typeface.self, forKey: .titleFont) { titleFont = v }
        if let v = try? c.decode(Typeface.self, forKey: .lyricsFont) { lyricsFont = v }
        if let v = try? c.decode(Typeface.self, forKey: .cakeFont) { cakeFont = v }
        if let v = try? c.decode(Typeface.self, forKey: .signatureFont) { signatureFont = v }
    }
}
