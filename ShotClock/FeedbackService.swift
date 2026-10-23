import AVFoundation
import ShotClockCore
import WatchKit

/// Haptics and sounds for clock events.
///
/// Spike: whether the generated tones are audible with the wrist down and in silent
/// mode has to be verified on the device (see SPEC.md, risks).
final class FeedbackService {
    private let device = WKInterfaceDevice.current()
    private let tickPlayer = FeedbackService.player(frequency: 1760, duration: 0.12)
    private let expiryPlayer = FeedbackService.player(frequency: 880, duration: 1.2)

    /// Activates the audio session; call when the clock starts.
    func prepare() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default)
        try? session.setActive(true)
        tickPlayer?.prepareToPlay()
        expiryPlayer?.prepareToPlay()
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
            replay(tickPlayer)
        case .expired:
            device.play(.failure)
            replay(expiryPlayer)
        }
    }

    private func replay(_ player: AVAudioPlayer?) {
        guard let player else { return }
        player.currentTime = 0
        player.play()
    }

    private static func player(frequency: Double, duration: TimeInterval) -> AVAudioPlayer? {
        try? AVAudioPlayer(data: Tone.wav(frequency: frequency, duration: duration))
    }
}

/// Generates a short sine beep as 16-bit mono PCM WAV data, so no audio assets are needed.
enum Tone {
    static func wav(frequency: Double, duration: TimeInterval, sampleRate: Int = 44_100) -> Data {
        let sampleCount = Int(duration * Double(sampleRate))
        let fade = min(sampleCount / 2, sampleRate / 100) // 10 ms fade against clicks
        var samples = [Int16](repeating: 0, count: sampleCount)
        for i in 0..<sampleCount {
            let envelope = min(1, Double(min(i, sampleCount - 1 - i)) / Double(max(fade, 1)))
            let value = sin(2 * .pi * frequency * Double(i) / Double(sampleRate)) * envelope * 0.9
            samples[i] = Int16(value * Double(Int16.max))
        }

        let dataSize = sampleCount * 2
        var data = Data()
        data.append(contentsOf: Array("RIFF".utf8))
        data.append(littleEndian: UInt32(36 + dataSize))
        data.append(contentsOf: Array("WAVEfmt ".utf8))
        data.append(littleEndian: UInt32(16))               // fmt chunk size
        data.append(littleEndian: UInt16(1))                // PCM
        data.append(littleEndian: UInt16(1))                // mono
        data.append(littleEndian: UInt32(sampleRate))
        data.append(littleEndian: UInt32(sampleRate * 2))   // byte rate
        data.append(littleEndian: UInt16(2))                // block align
        data.append(littleEndian: UInt16(16))               // bits per sample
        data.append(contentsOf: Array("data".utf8))
        data.append(littleEndian: UInt32(dataSize))
        samples.forEach { data.append(littleEndian: $0) }
        return data
    }
}

private extension Data {
    mutating func append<T: FixedWidthInteger>(littleEndian value: T) {
        Swift.withUnsafeBytes(of: value.littleEndian) { append(contentsOf: $0) }
    }
}
