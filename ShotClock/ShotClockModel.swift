import Foundation
import Observation
import ShotClockCore

/// Drives the `ShotClock` in real time and turns its events into feedback.
@Observable
final class ShotClockModel {
    private(set) var clock = ShotClock()

    @ObservationIgnored private let feedback = FeedbackService()
    @ObservationIgnored private let runtime = RuntimeSession()
    @ObservationIgnored private var loop: Task<Void, Never>?

    /// Polling interval of the update loop; well below one second so ticks land on time.
    private static let pollInterval: Duration = .milliseconds(50)
    /// Keeps the runtime session alive briefly after expiry so the final signal plays out.
    private static let expiryGrace: Duration = .seconds(3)

    var isRunning: Bool {
        if case .running = clock.phase { true } else { false }
    }

    func perform(_ action: ClockAction) {
        clock.perform(action, at: .now)
        if isRunning {
            runtime.begin()
            feedback.activate()
            feedback.started()
            startLoop()
        } else {
            stopLoop()
            feedback.stopped()
            feedback.deactivate()
            runtime.end()
        }
    }

    func newRack() {
        clock.newRack()
    }

    func toggleBreakBonus() {
        clock.isBreakBonusArmed.toggle()
    }

    private func startLoop() {
        guard loop == nil else { return }
        loop = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                self.tick()
                guard self.isRunning else {
                    self.loop = nil
                    try? await Task.sleep(for: Self.expiryGrace)
                    if !self.isRunning {
                        self.feedback.deactivate()
                        self.runtime.end()
                    }
                    return
                }
                try? await Task.sleep(for: Self.pollInterval)
            }
        }
    }

    private func stopLoop() {
        loop?.cancel()
        loop = nil
    }

    private func tick() {
        // Update a copy and only write back on change, so observers are not
        // notified 20 times per second while nothing visible happens.
        var next = clock
        let events = next.update(at: .now)
        guard !events.isEmpty || next.phase != clock.phase else { return }
        clock = next
        events.forEach(feedback.play)
    }
}
