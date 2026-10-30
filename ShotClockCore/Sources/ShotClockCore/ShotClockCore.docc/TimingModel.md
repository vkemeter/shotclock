# Timing Model

How the shot clock keeps exact time and decides which cues are due.

## Overview

A shot clock on a watch cannot rely on a timer that fires every second: the system may
suspend or throttle the app while the wrist is down. ``ShotClock`` therefore never counts
down. It stores a deadline and derives everything from the current time that the caller
passes in.

### Deadline Instead of Countdown

Starting a shot sets ``ShotClock/Phase/running(deadline:)`` to *now + shot time* (plus the
break bonus if it is armed). ``ShotClock/remaining(at:)`` is the distance to that
deadline, so a late or skipped update can never make the clock drift. An extension moves
the deadline; it does not add to a counter.

### Phases

| Phase | Meaning |
|---|---|
| ``ShotClock/Phase/idle`` | No shot running; shows the time the next start will get. |
| ``ShotClock/Phase/running(deadline:)`` | A shot is being timed. |
| ``ShotClock/Phase/paused(remaining:)`` | Frozen remaining time; available in the core, not used by the watch app. |
| ``ShotClock/Phase/expired`` | Time ran out; shown as "TIME" until the next start. |

### Cues

``ShotClock/update(at:)`` returns the cues that became due since the previous call:

- ``ClockEvent/warning`` once, when the remaining time reaches ``RuleSet/warningAt``.
- ``ClockEvent/tick(_:)`` once per whole second from ``RuleSet/countdownFrom`` down to 1.
- ``ClockEvent/expired`` once, when the deadline has passed.

If updates were missed, only the current state is reported: at most one warning and the
current second, never a burst of stale ticks. Restarting a shot or using an extension
re-arms the cues for the new remaining time, so a warning that already fired is not
repeated while the new time is still below the threshold.

### Per-Rack State

``ShotClock/extensionsUsed`` counts extensions in the current rack against
``RuleSet/extensionsPerRack``; ``ShotClock/newRack()`` resets it. The break bonus is a
manual switch (``ShotClock/isBreakBonusArmed``) that the next start consumes.
