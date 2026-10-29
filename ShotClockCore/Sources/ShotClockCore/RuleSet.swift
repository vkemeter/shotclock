import Foundation

/// Time control of a shot clock.
public struct RuleSet: Sendable, Equatable, Codable {
    /// Time per shot.
    public var shotTime: TimeInterval
    /// Time added by one extension.
    public var extensionTime: TimeInterval
    /// Extensions available per rack.
    public var extensionsPerRack: Int
    /// Extra time for the first shot after the break.
    public var breakBonus: TimeInterval
    /// Remaining time at which the (haptic) warning is issued.
    public var warningAt: TimeInterval
    /// Remaining seconds from which every second is announced (audible countdown).
    public var countdownFrom: Int

    public init(
        shotTime: TimeInterval,
        extensionTime: TimeInterval,
        extensionsPerRack: Int,
        breakBonus: TimeInterval,
        warningAt: TimeInterval,
        countdownFrom: Int
    ) {
        self.shotTime = shotTime
        self.extensionTime = extensionTime
        self.extensionsPerRack = extensionsPerRack
        self.breakBonus = breakBonus
        self.warningAt = warningAt
        self.countdownFrom = countdownFrom
    }

    /// WPA: 30 s per shot, one 30 s extension per rack, +30 s for the first shot after the break.
    public static let wpa = RuleSet(
        shotTime: 30,
        extensionTime: 30,
        extensionsPerRack: 1,
        breakBonus: 30,
        warningAt: 10,
        countdownFrom: 5
    )
}
