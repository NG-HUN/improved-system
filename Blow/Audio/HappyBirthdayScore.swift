import Foundation

/// "Happy Birthday to You" (public domain in the US) in G major, 3/4.
/// Times are in beats from the start of one round.
enum HappyBirthdayScore {
    struct Note { let midi: Int; let beat: Double; let length: Double }
    struct Hit { let midi: Int; let beat: Double; let velocity: Float }

    static let bpm: Double = 96
    static let beatsPerRound: Double = 28
    static let gapBeats: Double = 2
    /// Beats at which each of the four sung lines starts / ends.
    static let lineStarts: [Double] = [0, 6, 12, 21]
    static let lineEnds: [Double] = [6, 12, 21, 28]

    static let melody: [Note] = [
        // Hap-py birth-day to you
        Note(midi: 62, beat: 0, length: 0.75), Note(midi: 62, beat: 0.75, length: 0.25),
        Note(midi: 64, beat: 1, length: 1), Note(midi: 62, beat: 2, length: 1),
        Note(midi: 67, beat: 3, length: 1), Note(midi: 66, beat: 4, length: 2),
        // Hap-py birth-day to you
        Note(midi: 62, beat: 6, length: 0.75), Note(midi: 62, beat: 6.75, length: 0.25),
        Note(midi: 64, beat: 7, length: 1), Note(midi: 62, beat: 8, length: 1),
        Note(midi: 69, beat: 9, length: 1), Note(midi: 67, beat: 10, length: 2),
        // Hap-py birth-day dear Na-me
        Note(midi: 62, beat: 12, length: 0.75), Note(midi: 62, beat: 12.75, length: 0.25),
        Note(midi: 74, beat: 13, length: 1), Note(midi: 71, beat: 14, length: 1),
        Note(midi: 67, beat: 15, length: 1), Note(midi: 66, beat: 16, length: 1),
        Note(midi: 64, beat: 17, length: 4),
        // Hap-py birth-day to you
        Note(midi: 72, beat: 21, length: 0.75), Note(midi: 72, beat: 21.75, length: 0.25),
        Note(midi: 71, beat: 22, length: 1), Note(midi: 67, beat: 23, length: 1),
        Note(midi: 69, beat: 24, length: 1), Note(midi: 67, beat: 25, length: 3),
    ]

    private struct Chord { let bass: Int; let upper: [Int] }
    private static let G = Chord(bass: 55, upper: [59, 62])
    private static let D7 = Chord(bass: 50, upper: [54, 60])
    private static let C = Chord(bass: 48, upper: [52, 55])

    private static let changes: [(beat: Double, chord: Chord)] = [
        (1, G), (4, D7), (7, D7), (10, G), (13, G), (16, C), (19, C), (22, G), (24, D7), (25, G),
    ]

    /// Gentle waltz accompaniment: bass on the downbeat, a soft dyad on beats 2 and 3.
    static func accompaniment() -> [Hit] {
        var hits: [Hit] = []
        for b in 1..<27 {
            let beat = Double(b)
            guard let chord = changes.last(where: { $0.beat <= beat })?.chord else { continue }
            if (b - 1) % 3 == 0 {
                hits.append(Hit(midi: chord.bass, beat: beat, velocity: 0.30))
            } else if beat < 25 {
                for m in chord.upper { hits.append(Hit(midi: m, beat: beat, velocity: 0.11)) }
            }
        }
        // closing chord
        hits.append(Hit(midi: 55, beat: 25, velocity: 0.12))
        hits.append(Hit(midi: 59, beat: 25, velocity: 0.12))
        return hits
    }

    static var secondsPerBeat: Double { 60 / bpm }
    static var roundSeconds: Double { (beatsPerRound + gapBeats) * secondsPerBeat }

    static func duration(rounds: Int) -> Double {
        Double(max(rounds, 1)) * roundSeconds - gapBeats * secondsPerBeat
    }

    /// Which line (0…3) is being sung at `time` seconds into playback, nil between rounds.
    static func line(at time: Double) -> Int? {
        guard time >= 0 else { return nil }
        let beat = time.truncatingRemainder(dividingBy: roundSeconds) / secondsPerBeat
        for i in 0..<4 where beat >= lineStarts[i] - 0.15 && beat < lineEnds[i] - 0.15 { return i }
        return nil
    }
}
