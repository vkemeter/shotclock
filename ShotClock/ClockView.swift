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
                .accessibilityLabel(model.isRunning ? "Neustart" : "Start")
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Neues Rack", systemImage: "arrow.counterclockwise") {
                        model.newRack()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Break-Bonus", systemImage: model.clock.isBreakBonusArmed ? "bolt.fill" : "bolt") {
                        model.toggleBreakBonus()
                    }
                    .tint(model.clock.isBreakBonusArmed ? .yellow : nil)
                }
                ToolbarItemGroup(placement: .bottomBar) {
                    Button("Stopp", systemImage: "stop.fill") {
                        model.perform(.stop)
                    }
                    .disabled(model.clock.phase == .idle)

                    Spacer()

                    Button("Verlängerung", systemImage: "plus.circle") {
                        model.perform(.useExtension)
                    }
                    .disabled(!model.clock.canUseExtension)
                }
            }
        }
    }
}

private struct ClockFace: View {
    let clock: ShotClock
    let now: Date

    @Environment(\.isLuminanceReduced) private var isLuminanceReduced

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
                        .contentTransition(.numericText(countsDown: true))
                }
                Text("EXT")
                    .font(.caption2.bold())
                    .strikethrough(!isExtensionAvailable)
                    .foregroundStyle(isExtensionAvailable ? AnyShapeStyle(.green) : AnyShapeStyle(.secondary))
                    .accessibilityLabel(isExtensionAvailable ? "Verlängerung verfügbar" : "Verlängerung verbraucht")
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
