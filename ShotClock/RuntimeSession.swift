import WatchKit

/// Keeps the app running while the wrist is down, so haptics and tones arrive on time.
///
/// Spike: uses a `WKExtendedRuntimeSession` (background mode `physical-therapy`,
/// max. ~1 h). If this proves unreliable on the device, switch to `HKWorkoutSession`.
final class RuntimeSession: NSObject {
    private var session: WKExtendedRuntimeSession?

    func begin() {
        if let session, session.state == .running || session.state == .notStarted { return }
        let session = WKExtendedRuntimeSession()
        session.delegate = self
        session.start()
        self.session = session
    }

    func end() {
        session?.invalidate()
        session = nil
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
            if let session = self.session, ObjectIdentifier(session) == id {
                self.session = nil
            }
        }
    }
}
