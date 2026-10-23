import AVFoundation
import OSLog
import ShotClockCore
import WatchKit

/// Haptics and sounds for clock events.
///
/// The audio session is activated asynchronously once per shot clock run and the
/// engine keeps running until `deactivate()`, so playing a tone never blocks the
/// main thread with a synchronous session activation.
///
/// Spike: whether the tones are audible with the wrist down and in silent mode has
/// to be verified on the device (see SPEC.md, risks).
final class FeedbackService {
    private let device = WKInterfaceDevice.current()
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
    private lazy var tickTone = Tone.buffer(frequency: 1760, duration: 0.12, format: format)
    private lazy var expiryTone = Tone.buffer(frequency: 880, duration: 1.2, format: format)
    private var isActive = false

    private static let log = Logger(subsystem: "de.vkemeter.shotclock", category: "Feedback")

    init() {
        engine.attach(player)
        do {
            try engine.connectNode(player, to: engine.mainMixerNode, format: format)
        } catch {
            Self.log.error("Audio graph setup failed: \(error.localizedDescription)")
        }
    }

    /// Activates the audio session and starts the engine; call when the clock starts.
    func activate() {
        guard !isActive else { return }
        isActive = true
        Task {
            let session = AVAudioSession.sharedInstance()
            do {
                try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
                guard try await session.activate(options: []), isActive else { return }
                try engine.start()
                try player.playAudio()
                Self.log.info("Audio engine started")
            } catch {
                Self.log.error("Audio activation failed: \(error.localizedDescription)")
            }
        }
    }

    /// Stops the engine and releases the audio session; call when the clock is no longer running.
    func deactivate() {
        guard isActive else { return }
        isActive = false
        player.stop()
        engine.stop()
        Task {
            do {
                _ = try await AVAudioSession.sharedInstance().deactivate(options: [.notifyOthersOnDeactivation])
            } catch {
                Self.log.error("Audio deactivation failed: \(error.localizedDescription)")
            }
        }
    }

    func started() {
        device.play(.start)
    }

    func stopped() {
        device.play(.stop)
    }

    func play(_ event: ClockEvent) {
        switch event {
        case .warning:
            device.play(.notification)
        case .tick:
            device.play(.click)
            playTone(tickTone)
        case .expired:
            device.play(.failure)
            playTone(expiryTone)
        }
    }

    private func playTone(_ buffer: AVAudioPCMBuffer) {
        guard engine.isRunning else {
            Self.log.notice("Tone skipped, audio engine not running")
            return
        }
        player.scheduleBuffer(buffer, at: nil, options: .interrupts)
        Self.log.debug("Tone scheduled")
        guard !player.isPlaying else { return }
        do {
            try player.playAudio()
        } catch {
            Self.log.error("Tone playback failed: \(error.localizedDescription)")
        }
    }
}

/// Generates short sine beeps, so no audio assets are needed.
enum Tone {
    static func buffer(frequency: Double, duration: TimeInterval, format: AVAudioFormat) -> AVAudioPCMBuffer {
        let sampleRate = format.sampleRate
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount

        let samples = buffer.floatChannelData![0]
        let count = Int(frameCount)
        let fade = max(1, min(count / 2, Int(sampleRate / 100))) // 10 ms fade against clicks
        for i in 0..<count {
            let envelope = min(1, Double(min(i, count - 1 - i)) / Double(fade))
            samples[i] = Float(sin(2 * .pi * frequency * Double(i) / sampleRate) * envelope * 0.9)
        }
        return buffer
    }
}
