import ShotClockCore
import SwiftUI

struct ClockView: View {
    let model: ShotClockModel

    var body: some View {
        NavigationStack {
            TimelineView(.animation(minimumInterval: 0.1, paused: !model.isRunning)) { context in
                Button {
                    model.perform(.startOrRestart)
                } label: {
                    ClockFace(clock: model.clock, now: context.date)
                }
                .buttonStyle(.plain)
                .handGestureShortcut(.primaryAction)
                .accessibilityLabel(model.isRunning ? Text("Restart") : Text("Start"))
                .accessibilityValue(Self.accessibilityStatus(of: model.clock, at: context.date))
                .accessibilityAddTraits(.updatesFrequently)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("New rack", systemImage: "arrow.counterclockwise") {
                        model.newRack()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Break bonus", systemImage: model.clock.isBreakBonusArmed ? "bolt.fill" : "bolt") {
                        model.toggleBreakBonus()
                    }
                    .tint(model.clock.isBreakBonusArmed ? .yellow : nil)
                    .accessibilityValue(model.clock.isBreakBonusArmed ? Text("On") : Text("Off"))
                    .accessibilityHint(Text("The next start gets bonus time."))
                }
                ToolbarItemGroup(placement: .bottomBar) {
                    Button("Stop", systemImage: "stop.fill") {
                        model.perform(.stop)
                    }
                    .disabled(model.clock.phase == .idle)

                    Spacer()

                    NavigationLink {
                        SettingsView(model: model)
                    } label: {
                        Label("Settings", systemImage: "gearshape")
                    }

                    Spacer()

                    Button("Extension", systemImage: "plus.circle") {
                        model.perform(.useExtension)
                    }
                    .disabled(!model.clock.canUseExtension)
                }
            }
        }
    }

    /// Spoken summary of what the clock face shows only visually.
    private static func accessibilityStatus(of clock: ShotClock, at now: Date) -> String {
        var parts: [String] = []
        if clock.phase == .expired {
            parts.append(String(localized: "Time is up"))
        } else {
            let seconds = Int(clock.remaining(at: now).rounded(.up))
            parts.append(
                clock.phase == .idle
                    ? String(localized: "\(seconds) seconds")
                    : String(localized: "\(seconds) seconds remaining"))
        }
        let isExtensionAvailable = clock.extensionsUsed < clock.rules.extensionsPerRack
        parts.append(
            isExtensionAvailable
                ? String(localized: "Extension available")
                : String(localized: "Extension used"))
        if clock.isBreakBonusArmed {
            parts.append(String(localized: "Break bonus active"))
        }
        return parts.joined(separator: ", ")
    }
}

private struct ClockFace: View {
    let clock: ShotClock
    let now: Date

    @Environment(\.isLuminanceReduced) private var isLuminanceReduced
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var remaining: TimeInterval { clock.remaining(at: now) }

    private var isExtensionAvailable: Bool { clock.extensionsUsed < clock.rules.extensionsPerRack }

    private var color: Color {
        if clock.phase == .idle { return .secondary }
        if remaining <= TimeInterval(clock.rules.countdownFrom) { return .red }
        if remaining <= clock.rules.warningAt { return .yellow }
        return .green
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.25), lineWidth: 8)
            Circle()
                .trim(from: 0, to: min(1, remaining / clock.rules.shotTime))
                .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .opacity(isLuminanceReduced ? 0.5 : 1)

            VStack(spacing: 0) {
                if clock.phase == .expired {
                    Text("TIME")
                        .font(.system(size: 40, weight: .heavy, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .foregroundStyle(.red)
                } else {
                    Text("\(Int(remaining.rounded(.up)))")
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .contentTransition(reduceMotion ? .identity : .numericText(countsDown: true))
                }
                Text("EXT")
                    .font(.caption2.bold())
                    .strikethrough(!isExtensionAvailable)
                    .foregroundStyle(isExtensionAvailable ? AnyShapeStyle(.green) : AnyShapeStyle(.secondary))
            }
            .padding(.horizontal, 16)
        }
        .padding(4)
        .contentShape(Circle())
    }
}

#Preview {
    ClockView(model: ShotClockModel())
}
