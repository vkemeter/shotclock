# ``ShotClockCore``

Platform-independent logic of a personal shot clock for pool billiards.

## Overview

ShotClockCore models the shot clock of a single player who wears the watch: one
countdown per shot, one extension per rack, an optional bonus for the first shot after
the break, and the haptic and audible cues that tell the player how much time is left.
The defaults follow the shot clock rules of the World Pool-Billiard Association (WPA);
see ``RuleSet/wpa``.

The package has no UI and no dependency on WatchKit, so every rule is covered by unit
tests. The watch app owns the real-time loop: it calls ``ShotClock/update(at:)``
frequently, renders ``ShotClock/remaining(at:)`` and turns the returned
``ClockEvent`` values into haptics and tones.

```swift
var clock = ShotClock(rules: .wpa)
clock.perform(.startOrRestart, at: .now)

// Later, from the app's update loop:
for event in clock.update(at: .now) {
    switch event {
    case .warning: playHaptic()
    case .tick(let second): playTone(second)
    case .expired: playExpirySignal()
    }
}
```

## Topics

### Essentials

- <doc:TimingModel>
- ``ShotClock``
- ``RuleSet``

### Input and Output

- ``ClockAction``
- ``ClockEvent``
