import WatchKit

/// Keeps the app running while the wrist is down, so haptics and tones arrive on time.
///
/// Spike: uses a `WKExtendedRuntimeSession` (background mode `physical-therapy`,
/// max. ~1 h). If this proves unreliable on the device, switch to `HKWorkoutSession`.
final class RuntimeSession: NSObject {
    private var session: WKExtendedRuntimeSession?
    /// Invalidated sessions are retained until the system confirms the invalidation;
    /// releasing them earlier makes WatchKit end them a second time and log errors.
    private var ending: [WKExtendedRuntimeSession] = []

    func begin() {
        if let session, session.state == .running || session.state == .notStarted { return }
        let session = WKExtendedRuntimeSession()
        session.delegate = self
        session.start()
        self.session = session
    }

    func end() {
        guard let session else { return }
        self.session = nil
        guard session.state == .running || session.state == .notStarted else { return }
        ending.append(session)
        session.invalidate()
    }

    private func didInvalidate(_ id: ObjectIdentifier) {
        ending.removeAll { ObjectIdentifier($0) == id }
        if let session, ObjectIdentifier(session) == id {
            self.session = nil
        }
    }
}

extension RuntimeSession: WKExtendedRuntimeSessionDelegate {
    nonisolated func extendedRuntimeSessionDidStart(_ extendedRuntimeSession: WKExtendedRuntimeSession) {}

    nonisolated func extendedRuntimeSessionWillExpire(_ extendedRuntimeSession: WKExtendedRuntimeSession) {}

    nonisolated func extendedRuntimeSession(
        _ extendedRuntimeSession: WKExtendedRuntimeSession,
        didInvalidateWith reason: WKExtendedRuntimeSessionInvalidationReason,
        error: (any Error)?
    ) {
        let id = ObjectIdentifier(extendedRuntimeSession)
        Task { @MainActor in
            self.didInvalidate(id)
        }
    }
}
