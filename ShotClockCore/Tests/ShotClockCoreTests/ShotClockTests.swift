import Foundation
import Testing

@testable import ShotClockCore

private let t0 = Date(timeIntervalSinceReferenceDate: 1_000)

private func at(_ seconds: TimeInterval) -> Date {
    t0.addingTimeInterval(seconds)
}

/// Calls `update` every 0.1 s from `from` to `to` and collects all events.
private func run(_ clock: inout ShotClock, from: TimeInterval, to: TimeInterval) -> [ClockEvent] {
    let steps = Int(((to - from) * 10).rounded())
    return (0...steps).flatMap { clock.update(at: at(from + Double($0) / 10)) }
}

@Suite("Start, Stopp, Ablauf")
struct BasicFlowTests {
    @Test func idleShowsFullShotTime() {
        let clock = ShotClock()
        #expect(clock.phase == .idle)
        #expect(clock.remaining(at: t0) == 30)
    }

    @Test func runningCountsDownFromDeadline() {
        var clock = ShotClock()
        clock.start(at: t0)
        #expect(clock.remaining(at: at(12.5)) == 17.5)
    }

    @Test func restartWhileRunningBeginsNewShot() {
        var clock = ShotClock()
        clock.start(at: t0)
        clock.start(at: at(20))
        #expect(clock.remaining(at: at(20)) == 30)
    }

    @Test func stopReturnsToIdle() {
        var clock = ShotClock()
        clock.start(at: t0)
        clock.stop()
        #expect(clock.phase == .idle)
        #expect(clock.update(at: at(40)).isEmpty)
    }

    @Test func expiresExactlyOnce() {
        var clock = ShotClock()
        clock.start(at: t0)
        let events = run(&clock, from: 29.5, to: 32)
        #expect(events.filter { $0 == .expired }.count == 1)
        #expect(clock.phase == .expired)
        #expect(clock.remaining(at: at(32)) == 0)
    }

    @Test func canRestartAfterExpiry() {
        var clock = ShotClock()
        clock.start(at: t0)
        _ = clock.update(at: at(31))
        clock.start(at: at(40))
        #expect(clock.remaining(at: at(40)) == 30)
    }
}

@Suite("Warnungen")
struct AlertTests {
    @Test func fullShotProducesWarningCountdownAndExpiry() {
        var clock = ShotClock()
        clock.start(at: t0)
        let events = run(&clock, from: 0, to: 30)
        #expect(events == [.warning, .tick(5), .tick(4), .tick(3), .tick(2), .tick(1), .expired])
    }

    @Test func warningFiresAtTenSecondsRemaining() {
        var clock = ShotClock()
        clock.start(at: t0)
        #expect(clock.update(at: at(19.9)).isEmpty)
        #expect(clock.update(at: at(20)) == [.warning])
    }

    @Test func tickFiresWhenFiveSecondsRemain() {
        var clock = ShotClock()
        clock.start(at: t0)
        _ = clock.update(at: at(20))
        #expect(clock.update(at: at(24.9)).isEmpty)
        #expect(clock.update(at: at(25)) == [.tick(5)])
    }

    @Test func lateUpdateOnlyReportsCurrentSecond() {
        var clock = ShotClock()
        clock.start(at: t0)
        // App was suspended and wakes with 2.5 s left: one warning, one tick – no burst.
        #expect(clock.update(at: at(27.5)) == [.warning, .tick(3)])
    }

    @Test func restartRearmsAlerts() {
        var clock = ShotClock()
        clock.start(at: t0)
        _ = run(&clock, from: 0, to: 26)
        clock.start(at: at(27))
        let events = run(&clock, from: 27, to: 57)
        #expect(events == [.warning, .tick(5), .tick(4), .tick(3), .tick(2), .tick(1), .expired])
    }
}

@Suite("Verlängerung")
struct ExtensionTests {
    @Test func extensionAddsThirtySeconds() {
        var clock = ShotClock()
        clock.start(at: t0)
        let used = clock.useExtension(at: at(10))
        #expect(used)
        #expect(clock.remaining(at: at(10)) == 50)
    }

    @Test func onlyOneExtensionPerRack() {
        var clock = ShotClock()
        clock.start(at: t0)
        let used = clock.useExtension(at: at(5))
        #expect(used)
        clock.start(at: at(20))
        let usedAgain = clock.useExtension(at: at(25))
        #expect(!usedAgain)
        #expect(!clock.canUseExtension)
    }

    @Test func newRackRestoresExtension() {
        var clock = ShotClock()
        clock.start(at: t0)
        clock.useExtension(at: at(5))
        clock.newRack()
        clock.start(at: at(60))
        #expect(clock.canUseExtension)
        let used = clock.useExtension(at: at(61))
        #expect(used)
    }

    @Test func extensionNotAvailableWhenIdleOrExpired() {
        var clock = ShotClock()
        let used = clock.useExtension(at: t0)
        #expect(!used)
        clock.start(at: t0)
        _ = clock.update(at: at(31))
        let usedAgain = clock.useExtension(at: at(31))
        #expect(!usedAgain)
        #expect(clock.extensionsUsed == 0)
    }

    @Test func extensionDuringCountdownRearmsAlerts() {
        var clock = ShotClock()
        clock.start(at: t0)
        _ = run(&clock, from: 0, to: 27)
        clock.useExtension(at: at(27))
        // 3 s + 30 s = 33 s left at t = 27 → expires at t = 60.
        let events = run(&clock, from: 27, to: 60)
        #expect(events == [.warning, .tick(5), .tick(4), .tick(3), .tick(2), .tick(1), .expired])
    }
}

@Suite("Break-Bonus")
struct BreakBonusTests {
    @Test func armedBonusExtendsNextStart() {
        var clock = ShotClock()
        clock.isBreakBonusArmed = true
        #expect(clock.remaining(at: t0) == 60)
        clock.start(at: t0)
        #expect(clock.remaining(at: t0) == 60)
    }

    @Test func bonusIsConsumedByStart() {
        var clock = ShotClock()
        clock.isBreakBonusArmed = true
        clock.start(at: t0)
        #expect(!clock.isBreakBonusArmed)
        clock.start(at: at(30))
        #expect(clock.remaining(at: at(30)) == 30)
    }
}

@Suite("Pause")
struct PauseTests {
    @Test func pauseFreezesRemainingTime() {
        var clock = ShotClock()
        clock.start(at: t0)
        clock.pause(at: at(10))
        #expect(clock.remaining(at: at(100)) == 20)
        #expect(clock.update(at: at(100)).isEmpty)
        clock.resume(at: at(100))
        #expect(clock.remaining(at: at(105)) == 15)
    }

    @Test func extensionWhilePaused() {
        var clock = ShotClock()
        clock.start(at: t0)
        clock.pause(at: at(10))
        let used = clock.useExtension(at: at(12))
        #expect(used)
        #expect(clock.remaining(at: at(12)) == 50)
    }
}

@Suite("Aktionen (Action-Taste)")
struct ActionTests {
    @Test func startOrRestart() {
        var clock = ShotClock()
        clock.perform(.startOrRestart, at: t0)
        clock.perform(.startOrRestart, at: at(10))
        #expect(clock.remaining(at: at(10)) == 30)
    }

    @Test func toggleStartsAndStops() {
        var clock = ShotClock()
        clock.perform(.toggleStartStop, at: t0)
        #expect(clock.phase == .running(deadline: at(30)))
        clock.perform(.toggleStartStop, at: at(5))
        #expect(clock.phase == .idle)
    }

    @Test func toggleAfterExpiryStops() {
        var clock = ShotClock()
        clock.perform(.toggleStartStop, at: t0)
        _ = clock.update(at: at(31))
        clock.perform(.toggleStartStop, at: at(32))
        #expect(clock.phase == .idle)
    }

    @Test func extensionAction() {
        var clock = ShotClock()
        clock.perform(.startOrRestart, at: t0)
        clock.perform(.useExtension, at: at(1))
        #expect(clock.remaining(at: at(1)) == 59)
    }
}

@Suite("Eigene Regeln (Einstellungen)")
struct CustomRulesTests {
    @Test func idleShowsChangedShotTime() {
        var clock = ShotClock()
        clock.rules.shotTime = 45
        #expect(clock.remaining(at: t0) == 45)
    }

    @Test func changeDuringShotKeepsRunningDeadline() {
        var clock = ShotClock()
        clock.start(at: t0)
        clock.rules.shotTime = 60
        #expect(clock.remaining(at: at(10)) == 20)
        clock.start(at: at(10))
        #expect(clock.remaining(at: at(10)) == 60)
    }

    @Test func moreExtensionsPerRack() {
        var clock = ShotClock()
        clock.rules.extensionsPerRack = 2
        clock.start(at: t0)
        let used = [1, 2, 3].map { clock.useExtension(at: at($0)) }
        #expect(used == [true, true, false])
    }

    @Test func noExtensionsPerRack() {
        var clock = ShotClock()
        clock.rules.extensionsPerRack = 0
        clock.start(at: t0)
        #expect(!clock.canUseExtension)
    }

    @Test func ruleSetSurvivesEncoding() throws {
        var rules = RuleSet.wpa
        rules.shotTime = 40
        rules.countdownFrom = 3
        let data = try JSONEncoder().encode(rules)
        #expect(try JSONDecoder().decode(RuleSet.self, from: data) == rules)
    }
}
