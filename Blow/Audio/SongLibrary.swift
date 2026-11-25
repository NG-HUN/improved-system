import Foundation

/// A singable melody built from the same 28-beat, four-line structure as the
/// classic birthday song, so lyric highlighting stays in sync. Every entry has
/// its own notes, tempo, accompaniment and timbre — they are genuinely different
/// tunes, not just different languages over one melody.
struct SongScore {
    typealias Note = HappyBirthdayScore.Note
    typealias Hit = HappyBirthdayScore.Hit

    let title: String
    let subtitle: String
    let bpm: Double
    let melody: [Note]
    let accompaniment: [Hit]
    /// Melody notes longer than this get a quiet octave shimmer.
    let shimmerThreshold: Double
    let melodyTimbre: Synth.Timbre
    let accompanimentTimbre: Synth.Timbre

    var secondsPerBeat: Double { 60 / bpm }
    var roundSeconds: Double {
        (HappyBirthdayScore.beatsPerRound + HappyBirthdayScore.gapBeats) * secondsPerBeat
    }
    func duration(rounds: Int) -> Double {
        Double(max(rounds, 1)) * roundSeconds
            - HappyBirthdayScore.gapBeats * secondsPerBeat
    }
    /// Which of the four lyric lines is being sung at `time` seconds, using this
    /// tune's own tempo so highlighting stays in sync for faster/slower songs.
    func line(at time: Double) -> Int? {
        guard time >= 0 else { return nil }
        let beat = time.truncatingRemainder(dividingBy: roundSeconds) / secondsPerBeat
        let starts = HappyBirthdayScore.lineStarts
        let ends = HappyBirthdayScore.lineEnds
        for i in 0..<4 where beat >= starts[i] - 0.15 && beat < ends[i] - 0.15 { return i }
        return nil
    }
}

/// The selectable tunes in Settings. `.classic` is the original G-major song and
/// stays the default so existing birthdays are unchanged.
enum SongChoice: String, Codable, CaseIterable, Identifiable {
    case classic, jazz, bright, lullaby

    var id: String { rawValue }

    var title: String { score.title }
    var subtitle: String { score.subtitle }
    /// Every tune is free so the choice is meaningful for all users.
    var isProSong: Bool { false }

    var score: SongScore {
        switch self {
        case .classic: return SongLibrary.classic
        case .jazz:    return SongLibrary.jazz
        case .bright:  return SongLibrary.bright
        case .lullaby: return SongLibrary.lullaby
        }
    }
}

enum SongLibrary {
    // MARK: - Helpers

    private typealias Note = HappyBirthdayScore.Note
    private typealias Hit = HappyBirthdayScore.Hit

    /// Build a 3/4 waltz accompaniment from a repeating chord progression.
    /// `pattern` optionally remaps each beat's chord index for different feels.
    private static func waltz(
        chords: [(bass: Int, upper: [Int])],
        beats: Range<Int> = 1..<27,
        closing: (Int, Int)
    ) -> [Hit] {
        var hits: [Hit] = []
        for b in beats {
            let chord = chords[(b - 1) % chords.count]
            if (b - 1) % 3 == 0 {
                hits.append(Hit(midi: chord.bass, beat: Double(b), velocity: 0.30))
            } else {
                for m in chord.upper {
                    hits.append(Hit(midi: m, beat: Double(b), velocity: 0.11))
                }
            }
        }
        hits.append(Hit(midi: closing.0, beat: 25, velocity: 0.12))
        hits.append(Hit(midi: closing.1, beat: 25, velocity: 0.12))
        return hits
    }

    // MARK: - 1. Classic (original G major)

    static let classic = SongScore(
        title: "Happy Birthday · Classic",
        subtitle: "Gentle music box · G major",
        bpm: HappyBirthdayScore.bpm,
        melody: HappyBirthdayScore.melody,
        accompaniment: HappyBirthdayScore.accompaniment(),
        shimmerThreshold: 2,
        melodyTimbre: .musicBox,
        accompanimentTimbre: .felt
    )

    // MARK: - 2. Jazz (swung sevenths, blue notes)

    private static let jazzMelody: [Note] = [
        Note(midi: 65, beat: 0, length: 0.75), Note(midi: 65, beat: 0.75, length: 0.25),
        Note(midi: 69, beat: 1, length: 1), Note(midi: 67, beat: 2, length: 1),
        Note(midi: 72, beat: 3, length: 1), Note(midi: 70, beat: 4, length: 2),
        Note(midi: 65, beat: 6, length: 0.75), Note(midi: 65, beat: 6.75, length: 0.25),
        Note(midi: 69, beat: 7, length: 1), Note(midi: 67, beat: 8, length: 1),
        Note(midi: 74, beat: 9, length: 1), Note(midi: 72, beat: 10, length: 2),
        Note(midi: 65, beat: 12, length: 0.75), Note(midi: 65, beat: 12.75, length: 0.25),
        Note(midi: 77, beat: 13, length: 1), Note(midi: 74, beat: 14, length: 1),
        Note(midi: 72, beat: 15, length: 1), Note(midi: 70, beat: 16, length: 1),
        Note(midi: 69, beat: 17, length: 4),
        Note(midi: 74, beat: 21, length: 0.75), Note(midi: 74, beat: 21.75, length: 0.25),
        Note(midi: 72, beat: 22, length: 1), Note(midi: 69, beat: 23, length: 1),
        Note(midi: 70, beat: 24, length: 1), Note(midi: 69, beat: 25, length: 3),
    ]

    private static let jazzAccomp: [Hit] = waltz(
        chords: [
            (bass: 53, upper: [57, 60, 64]),
            (bass: 48, upper: [52, 55, 58]),
            (bass: 55, upper: [59, 62, 65]),
            (bass: 50, upper: [54, 57, 60]),
        ],
        closing: (53, 57)
    )

    static let jazz = SongScore(
        title: "Happy Birthday · Jazz",
        subtitle: "Swinging sevenths · F major",
        bpm: 112,
        melody: jazzMelody,
        accompaniment: jazzAccomp,
        shimmerThreshold: 99,
        melodyTimbre: .musicBox,
        accompanimentTimbre: .felt
    )

    // MARK: - 3. Bright (upbeat, arpeggiated, high register)

    private static let brightMelody: [Note] = [
        Note(midi: 72, beat: 0, length: 0.5), Note(midi: 76, beat: 0.5, length: 0.5),
        Note(midi: 79, beat: 1, length: 1), Note(midi: 76, beat: 2, length: 1),
        Note(midi: 77, beat: 3, length: 1), Note(midi: 76, beat: 4, length: 2),
        Note(midi: 72, beat: 6, length: 0.5), Note(midi: 76, beat: 6.5, length: 0.5),
        Note(midi: 79, beat: 7, length: 1), Note(midi: 76, beat: 8, length: 1),
        Note(midi: 81, beat: 9, length: 1), Note(midi: 79, beat: 10, length: 2),
        Note(midi: 72, beat: 12, length: 0.5), Note(midi: 76, beat: 12.5, length: 0.5),
        Note(midi: 84, beat: 13, length: 1), Note(midi: 81, beat: 14, length: 1),
        Note(midi: 79, beat: 15, length: 1), Note(midi: 77, beat: 16, length: 1),
        Note(midi: 76, beat: 17, length: 4),
        Note(midi: 84, beat: 21, length: 0.5), Note(midi: 84, beat: 21.5, length: 0.5),
        Note(midi: 83, beat: 22, length: 1), Note(midi: 79, beat: 23, length: 1),
        Note(midi: 81, beat: 24, length: 1), Note(midi: 79, beat: 25, length: 3),
    ]

    private static let brightAccomp: [Hit] = waltz(
        chords: [
            (bass: 60, upper: [64, 67]),
            (bass: 55, upper: [59, 62]),
            (bass: 57, upper: [60, 64]),
            (bass: 53, upper: [57, 60]),
        ],
        closing: (60, 64)
    )

    static let bright = SongScore(
        title: "Happy Birthday · Bright",
        subtitle: "Bright staccato · C major",
        bpm: 132,
        melody: brightMelody,
        accompaniment: brightAccomp,
        shimmerThreshold: 2,
        melodyTimbre: .musicBox,
        accompanimentTimbre: .felt
    )

    // MARK: - 4. Lullaby (slow, simple, gentle)

    private static let lullabyMelody: [Note] = [
        Note(midi: 60, beat: 0, length: 1), Note(midi: 60, beat: 1, length: 1),
        Note(midi: 62, beat: 2, length: 1), Note(midi: 60, beat: 3, length: 3),
        Note(midi: 60, beat: 6, length: 1), Note(midi: 60, beat: 7, length: 1),
        Note(midi: 62, beat: 8, length: 1), Note(midi: 65, beat: 9, length: 3),
        Note(midi: 60, beat: 12, length: 1), Note(midi: 60, beat: 13, length: 1),
        Note(midi: 67, beat: 14, length: 1), Note(midi: 65, beat: 15, length: 1),
        Note(midi: 62, beat: 16, length: 1), Note(midi: 60, beat: 17, length: 4),
        Note(midi: 65, beat: 21, length: 1), Note(midi: 65, beat: 22, length: 1),
        Note(midi: 64, beat: 23, length: 1), Note(midi: 62, beat: 24, length: 1),
        Note(midi: 60, beat: 25, length: 3),
    ]

    private static let lullabyAccomp: [Hit] = waltz(
        chords: [
            (bass: 48, upper: [55, 60]),
            (bass: 48, upper: [55, 60]),
            (bass: 53, upper: [57, 60]),
            (bass: 55, upper: [59, 62]),
        ],
        closing: (48, 55)
    )

    static let lullaby = SongScore(
        title: "Happy Birthday · Lullaby",
        subtitle: "Soft single notes · Adagio",
        bpm: 72,
        melody: lullabyMelody,
        accompaniment: lullabyAccomp,
        shimmerThreshold: 0,
        melodyTimbre: .musicBox,
        accompanimentTimbre: .felt
    )
}
