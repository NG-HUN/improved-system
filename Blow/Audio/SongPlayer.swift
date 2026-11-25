import AVFoundation

enum AudioSession {
    /// Play and record so the blow detector can listen without re-configuring mid-ceremony.
    /// Called when the ritual starts — not at launch, so opening Blow never interrupts
    /// whatever the user was already listening to.
    static func configure() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playAndRecord, mode: .default,
                                 options: [.defaultToSpeaker, .allowBluetoothA2DP])
        try? session.setActive(true)
    }

    /// Hand the audio route back so interrupted playback resumes.
    static func release() {
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}

/// Plays the synthesized song (through a hall reverb) and the effects.
@MainActor
final class SongPlayer {
    private let engine = AVAudioEngine()
    private let music = AVAudioPlayerNode()
    private let effects = (0..<4).map { _ in AVAudioPlayerNode() }
    private var nextEffect = 0
    private let reverb = AVAudioUnitReverb()
    private let format = AVAudioFormat(standardFormatWithSampleRate: Synth.sampleRate, channels: 2)!

    private var song: AVAudioPCMBuffer?
    private var ignite: AVAudioPCMBuffer?
    private var puff: AVAudioPCMBuffer?
    private var chime: AVAudioPCMBuffer?
    private var finale: AVAudioPCMBuffer?

    private(set) var isReady = false
    private(set) var songDuration: Double = 0
    private var clockStart: Double?

    init() {
        engine.attach(music)
        effects.forEach { engine.attach($0) }
        engine.attach(reverb)
        reverb.loadFactoryPreset(.largeHall)
        reverb.wetDryMix = 32
        engine.connect(music, to: reverb, format: format)
        engine.connect(reverb, to: engine.mainMixerNode, format: format)
        effects.forEach { engine.connect($0, to: engine.mainMixerNode, format: format) }
    }

    /// Renders the chosen song off the main thread. Call as early as possible.
    ///
    /// The song is rendered FIRST and flagged ready on its own, so the moment the
    /// box opens the tune can start — it never waits on the little effects. Those
    /// render afterwards in a second pass; they are only needed at ignition and
    /// the finale, by which time they are long since done.
    func prepare(rounds: Int, choice: SongChoice = .classic) async {
        let r = rounds
        let score = choice.score
        // Pass 1: the song only. This is the buffer the ceremony needs instantly.
        let samples = await Task.detached(priority: .userInitiated) {
            Synth.renderSong(rounds: r, score: score)
        }.value
        song = makeBuffer(samples)
        songDuration = score.duration(rounds: rounds)
        startEngine()
        isReady = true

        // Pass 2: effects, off the critical path of "open the box → hear music".
        let fx = await Task.detached(priority: .utility) {
            (Synth.renderIgnite(), Synth.renderPuff(), Synth.renderChime(),
             Synth.renderChime([67, 71, 74, 79, 83, 86], spacing: 0.11))
        }.value
        ignite = makeBuffer(fx.0)
        puff = makeBuffer(fx.1)
        chime = makeBuffer(fx.2)
        finale = makeBuffer(fx.3)
    }

    /// Synchronously swap in a freshly rendered song for setup previews.
    func preparePreview(rounds: Int, choice: SongChoice) {
        let score = choice.score
        let samples = Synth.renderSong(rounds: rounds, score: score)
        song = makeBuffer(samples)
        songDuration = score.duration(rounds: rounds)
        startEngine()
        isReady = true
    }

    func playSong() {
        guard let song else { return }
        startEngine()
        music.stop()
        music.volume = 1
        music.scheduleBuffer(song, at: nil)
        music.play()
        clockStart = CACurrentMediaTime()
    }

    /// Play a short taste of the tune while the user browses songs in setup.
    /// Reuses the prepared one-round buffer and fades itself out after a couple of bars.
    func preview(seconds: Double = 6) {
        guard isReady else { return }
        AudioSession.configure()
        playSong()
        music.volume = 0.85
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(seconds))
            self?.fadeOutSong(over: 0.8)
        }
    }

    /// Seconds into the song, from the audio clock when available.
    var songTime: Double? {
        if let nodeTime = music.lastRenderTime, music.isPlaying,
           let playerTime = music.playerTime(forNodeTime: nodeTime) {
            return Double(playerTime.sampleTime) / playerTime.sampleRate
        }
        guard let clockStart else { return nil }
        return CACurrentMediaTime() - clockStart
    }

    func fadeOutSong(over seconds: Double = 1.2) {
        let steps = 12
        Task { [weak self] in
            for i in 1...steps {
                try? await Task.sleep(for: .seconds(seconds / Double(steps)))
                guard let self else { return }
                self.music.volume = Float(1 - Double(i) / Double(steps))
            }
            self?.music.stop()
            self?.music.volume = 1
        }
    }

    func playIgnite() { play(ignite, volume: 0.5) }
    func playPuff() { play(puff, volume: 0.7) }
    func playChime() { play(chime, volume: 0.8) }
    func playFinale() { play(finale, volume: 0.9) }

    func stop() {
        music.stop()
        effects.forEach { $0.stop() }
        engine.stop()
        clockStart = nil
    }

    private func play(_ buffer: AVAudioPCMBuffer?, volume: Float) {
        guard let buffer else { return }
        startEngine()
        let node = effects[nextEffect]
        nextEffect = (nextEffect + 1) % effects.count
        node.stop()
        node.volume = volume
        node.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
        node.play()
    }

    private func startEngine() {
        guard !engine.isRunning else { return }
        engine.prepare()
        try? engine.start()
    }

    private func makeBuffer(_ samples: [Float]) -> AVAudioPCMBuffer? {
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(samples.count)),
              let channels = buffer.floatChannelData else { return nil }
        buffer.frameLength = AVAudioFrameCount(samples.count)
        samples.withUnsafeBufferPointer { src in
            for ch in 0..<Int(format.channelCount) {
                channels[ch].update(from: src.baseAddress!, count: samples.count)
            }
        }
        return buffer
    }
}
