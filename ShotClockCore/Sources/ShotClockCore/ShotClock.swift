import Foundation

/// Feedback the UI layer has to deliver to the player.
public enum ClockEvent: Equatable, Sendable {
    /// Remaining time reached `RuleSet.warningAt` (haptic warning).
    case warning
    /// Audible countdown; the associated value is the remaining whole second.
    case tick(Int)
    /// Time is up.
    case expired
}

/// Actions that can be bound to an input such as the Action button.
public enum ClockAction: String, CaseIterable, Sendable {
    case startOrRestart
    case toggleStartStop
    case stop
    case useExtension
}

/// Personal shot clock for the player wearing the watch.
///
/// A pure value type: every time-dependent call takes `now`, so the clock is driven
/// by the caller and is deterministic under test. Remaining time is always derived
/// from the deadline, never counted down, so a late `update` cannot cause drift.
public struct ShotClock: Sendable {
    public enum Phase: Equatable, Sendable {
        case idle
        case running(deadline: Date)
        case paused(remaining: TimeInterval)
        case expired
    }

    /// Changes apply to the next start; a running shot keeps its deadline.
    public var rules: RuleSet
    public private(set) var phase: Phase = .idle
    public private(set) var extensionsUsed = 0
    /// When set, the next `start` gets `RuleSet.breakBonus` on top; consumed by that start.
    public var isBreakBonusArmed = false

    private var warningIssued = false
    private var lastTick: Int?

    public init(rules: RuleSet = .wpa) {
        self.rules = rules
    }

    public var canUseExtension: Bool {
        guard extensionsUsed < rules.extensionsPerRack else { return false }
        switch phase {
        case .running, .paused: return true
        case .idle, .expired: return false
        }
    }

    public func remaining(at now: Date) -> TimeInterval {
        switch phase {
        case .idle: rules.shotTime + (isBreakBonusArmed ? rules.breakBonus : 0)
        case .running(let deadline): max(0, deadline.timeIntervalSince(now))
        case .paused(let remaining): remaining
        case .expired: 0
        }
    }

    /// Starts a new shot; restarts if the clock is already running.
    public mutating func start(at now: Date) {
        var duration = rules.shotTime
        if isBreakBonusArmed {
            duration += rules.breakBonus
            isBreakBonusArmed = false
        }
        phase = .running(deadline: now.addingTimeInterval(duration))
        rearmAlerts(remaining: duration)
    }

    public mutating func stop() {
        phase = .idle
    }

    public mutating func pause(at now: Date) {
        guard case .running = phase else { return }
        phase = .paused(remaining: remaining(at: now))
    }

    public mutating func resume(at now: Date) {
        guard case .paused(let remaining) = phase else { return }
        phase = .running(deadline: now.addingTimeInterval(remaining))
    }

    @discardableResult
    public mutating func useExtension(at now: Date) -> Bool {
        guard canUseExtension else { return false }
        switch phase {
        case .running(let deadline):
            phase = .running(deadline: deadline.addingTimeInterval(rules.extensionTime))
        case .paused(let remaining):
            phase = .paused(remaining: remaining + rules.extensionTime)
        case .idle, .expired:
            return false
        }
        extensionsUsed += 1
        rearmAlerts(remaining: remaining(at: now))
        return true
    }

    public mutating func newRack() {
        extensionsUsed = 0
    }

    public mutating func perform(_ action: ClockAction, at now: Date) {
        switch action {
        case .startOrRestart:
            start(at: now)
        case .toggleStartStop:
            if case .idle = phase { start(at: now) } else { stop() }
        case .stop:
            stop()
        case .useExtension:
            useExtension(at: now)
        }
    }

    /// Advances the clock and returns the feedback due since the last call.
    ///
    /// If calls were missed (e.g. the app was suspended), only the current state is
    /// reported – one warning and the current tick, never a burst of stale ticks.
    public mutating func update(at now: Date) -> [ClockEvent] {
        guard case .running = phase else { return [] }
        let remaining = remaining(at: now)
        if remaining <= 0 {
            phase = .expired
            return [.expired]
        }

        var events: [ClockEvent] = []
        if !warningIssued && remaining <= rules.warningAt {
            warningIssued = true
            events.append(.warning)
        }
        let second = Int(remaining.rounded(.up))
        if second <= rules.countdownFrom && second != lastTick {
            lastTick = second
            events.append(.tick(second))
        }
        return events
    }

    private mutating func rearmAlerts(remaining: TimeInterval) {
        warningIssued = remaining <= rules.warningAt
        let second = Int(remaining.rounded(.up))
        lastTick = second <= rules.countdownFrom ? second : nil
    }
}
