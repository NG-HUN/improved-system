import Foundation

/// Offline synthesis of the song and the little sound effects.
/// Everything is generated in code, so the app ships with no audio assets
/// and no licensing questions.
enum Synth {
    static let sampleRate: Double = 44_100

    enum Timbre {
        case musicBox, felt

        /// (frequency ratio, amplitude, decay per second)
        var partials: [(Double, Float, Float)] {
            switch self {
            case .musicBox: [(1, 1.0, 2.3), (2, 0.30, 4.5), (3, 0.11, 7.0), (4.17, 0.06, 10.0)]
            case .felt: [(1, 1.0, 1.4), (2, 0.42, 2.6), (3, 0.16, 3.8), (4, 0.07, 5.5)]
            }
        }
        var length: Double { self == .musicBox ? 2.6 : 3.0 }
        var attack: Double { self == .musicBox ? 0.003 : 0.014 }
    }

    // MARK: song

    static func renderSong(rounds: Int, score: SongScore = SongLibrary.classic) -> [Float] {
        let spb = score.secondsPerBeat
        let roundSeconds = score.roundSeconds
        let total = score.duration(rounds: rounds) + 4
        var out = [Float](repeating: 0, count: Int(total * sampleRate))
        let accompaniment = score.accompaniment

        out.withUnsafeMutableBufferPointer { buf in
            for r in 0..<max(rounds, 1) {
                let offset = Double(r) * roundSeconds
                for n in score.melody {
                    addNote(buf, midi: n.midi, at: offset + n.beat * spb, velocity: 0.55, timbre: score.melodyTimbre)
                    // a quiet octave shimmer on long notes
                    if n.length >= score.shimmerThreshold {
                        addNote(buf, midi: n.midi + 12, at: offset + n.beat * spb + 0.01, velocity: 0.08, timbre: score.melodyTimbre)
                    }
                }
                for h in accompaniment {
                    addNote(buf, midi: h.midi, at: offset + h.beat * spb, velocity: h.velocity, timbre: score.accompanimentTimbre)
                }
            }
        }
        normalize(&out, peak: 0.8)
        return out
    }

    // MARK: effects

    /// Soft "fff" of a match catching.
    static func renderIgnite() -> [Float] {
        noiseBurst(seconds: 0.55, attack: 0.04, decay: 6, cutoff: 0.10, gain: 0.35, seed: 7)
    }

    /// Breathy puff when a flame goes out.
    static func renderPuff() -> [Float] {
        noiseBurst(seconds: 0.40, attack: 0.01, decay: 10, cutoff: 0.05, gain: 0.45, seed: 11)
    }

    /// A small rising music-box figure.
    static func renderChime(_ notes: [Int] = [74, 79, 83, 86], spacing: Double = 0.13) -> [Float] {
        let total = spacing * Double(notes.count) + 2.8
        var out = [Float](repeating: 0, count: Int(total * sampleRate))
        out.withUnsafeMutableBufferPointer { buf in
            for (i, m) in notes.enumerated() {
                addNote(buf, midi: m, at: Double(i) * spacing, velocity: 0.35, timbre: .musicBox)
            }
        }
        normalize(&out, peak: 0.6)
        return out
    }

    // MARK: building blocks

    static func addNote(_ buf: UnsafeMutableBufferPointer<Float>, midi: Int, at start: Double,
                        velocity: Float, timbre: Timbre) {
        let f = 440 * pow(2, Double(midi - 69) / 12)
        let startIndex = Int(start * sampleRate)
        guard startIndex >= 0, startIndex < buf.count else { return }
        let count = min(Int(timbre.length * sampleRate), buf.count - startIndex)
        let attack = Float(timbre.attack * sampleRate)
        let fadeLength = 2000

        for (ratio, amp, decay) in timbre.partials {
            let freq = f * ratio
            guard freq < sampleRate / 2.2 else { continue }
            let w = 2 * Double.pi * freq / sampleRate
            let cw = Float(cos(w)), sw = Float(sin(w))
            var c: Float = 1, s: Float = 0
            var env: Float = 1
            let decayStep = Float(exp(-Double(decay) / sampleRate))
            let gain = velocity * amp
            for i in 0..<count {
                let a: Float = Float(i) < attack ? Float(i) / attack : 1
                let tail: Float = i > count - fadeLength ? Float(count - i) / Float(fadeLength) : 1
                buf[startIndex + i] += gain * env * a * tail * s
                let nc = c * cw - s * sw
                s = s * cw + c * sw
                c = nc
                env *= decayStep
            }
        }
    }

    private static func noiseBurst(seconds: Double, attack: Double, decay: Float,
                                   cutoff: Float, gain: Float, seed: UInt64) -> [Float] {
        let n = Int(seconds * sampleRate)
        var out = [Float](repeating: 0, count: n)
        var rng = SeededRandom(seed: seed)
        var lp: Float = 0, lp2: Float = 0
        let attackSamples = Float(attack * sampleRate)
        for i in 0..<n {
            let white = Float.random(in: -1...1, using: &rng)
            lp += cutoff * (white - lp)
            lp2 += cutoff * (lp - lp2)
            let t = Float(i) / Float(sampleRate)
            let a: Float = Float(i) < attackSamples ? Float(i) / attackSamples : 1
            out[i] = lp2 * a * exp(-decay * t)
        }
        normalize(&out, peak: gain)
        return out
    }

    private static func normalize(_ x: inout [Float], peak: Float) {
        var m: Float = 0
        for v in x { m = max(m, abs(v)) }
        guard m > 0 else { return }
        let k = peak / m
        for i in x.indices { x[i] *= k }
    }
}
