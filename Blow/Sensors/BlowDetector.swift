import AVFoundation
import Accelerate

/// Listens to the microphone and estimates how hard someone is blowing.
///
/// Blowing on a mic is loud, broadband noise. Speech and singing are tonal.
/// So the score combines loudness with spectral flatness (noise-likeness).
final class BlowDetector {
    /// 0 = nothing, 1 = a strong blow. Updated on the main thread.
    private(set) var score: Float = 0
    private(set) var isRunning = false

    private let engine = AVAudioEngine()
    private let n = 1024
    private let fft: vDSP.FFT<DSPSplitComplex>?
    private let window: [Float]

    init() {
        fft = vDSP.FFT(log2n: 10, radix: .radix2, ofType: DSPSplitComplex.self)
        window = vDSP.window(ofType: Float.self, usingSequence: .hanningDenormalized, count: 1024, isHalfWindow: false)
    }

    /// Returns false if permission was refused or the mic is unavailable.
    func start() async -> Bool {
        guard !isRunning else { return true }
        let granted = await AVAudioApplication.requestRecordPermission()
        guard granted else { return false }

        let input = engine.inputNode
        let format = input.outputFormat(forBus: 0)
        guard format.sampleRate > 0, format.channelCount > 0 else { return false }

        input.removeTap(onBus: 0)
        input.installTap(onBus: 0, bufferSize: AVAudioFrameCount(n), format: format) { [weak self] buffer, _ in
            guard let self else { return }
            let s = self.analyze(buffer)
            DispatchQueue.main.async { self.score = s }
        }
        engine.prepare()
        do {
            try engine.start()
            isRunning = true
            return true
        } catch {
            input.removeTap(onBus: 0)
            return false
        }
    }

    func stop() {
        guard isRunning else { return }
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        isRunning = false
        score = 0
    }

    private func analyze(_ buffer: AVAudioPCMBuffer) -> Float {
        guard let channel = buffer.floatChannelData?[0], let fft else { return 0 }
        let count = min(Int(buffer.frameLength), n)
        guard count > 64 else { return 0 }

        var samples = [Float](repeating: 0, count: n)
        samples.withUnsafeMutableBufferPointer { dst in
            dst.baseAddress!.update(from: channel, count: count)
        }

        // loudness
        let rms = vDSP.rootMeanSquare(samples[0..<count])
        let db = 20 * log10(max(rms, 1e-7))

        // spectrum
        let windowed = vDSP.multiply(samples, window)
        var real = [Float](repeating: 0, count: n / 2)
        var imag = [Float](repeating: 0, count: n / 2)
        var magnitudes = [Float](repeating: 0, count: n / 2)
        real.withUnsafeMutableBufferPointer { rp in
            imag.withUnsafeMutableBufferPointer { ip in
                var split = DSPSplitComplex(realp: rp.baseAddress!, imagp: ip.baseAddress!)
                windowed.withUnsafeBufferPointer { wp in
                    wp.baseAddress!.withMemoryRebound(to: DSPComplex.self, capacity: n / 2) {
                        vDSP_ctoz($0, 2, &split, 1, vDSP_Length(n / 2))
                    }
                }
                fft.forward(input: split, output: &split)
                vDSP.squareMagnitudes(split, result: &magnitudes)
            }
        }

        // spectral flatness over roughly 80 Hz – 6 kHz
        let lo = 2, hi = min(n / 2, 140)
        var logSum: Float = 0, sum: Float = 0
        for i in lo..<hi {
            let m = magnitudes[i] + 1e-12
            logSum += log(m)
            sum += m
        }
        let bins = Float(hi - lo)
        let flatness = exp(logSum / bins) / (sum / bins)

        // map: loud (> -32 dB) and noisy (flatness > ~0.12)
        let loud = ((db + 34) / 18).clamped(0, 1)
        let noisy = ((flatness - 0.08) / 0.22).clamped(0, 1)
        return loud * noisy
    }
}
