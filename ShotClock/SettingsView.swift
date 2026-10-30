import ShotClockCore
import SwiftUI

struct SettingsView: View {
    @Bindable var model: ShotClockModel

    var body: some View {
        List {
            Section {
                SecondsPicker("Shot time", value: $model.rules.shotTime, options: stride(from: 10, through: 90, by: 5))
                SecondsPicker(
                    "Break bonus", value: $model.rules.breakBonus, options: stride(from: 0, through: 60, by: 5))
            }
            Section("Extension") {
                SecondsPicker(
                    "Duration", value: $model.rules.extensionTime, options: stride(from: 5, through: 60, by: 5))
                Picker("Per rack", selection: $model.rules.extensionsPerRack) {
                    ForEach(0...3, id: \.self) { count in
                        CountLabel(count: count).tag(count)
                    }
                }
            }
            Section("Signals") {
                SecondsPicker("Vibrate at", value: $model.rules.warningAt, options: stride(from: 0, through: 20, by: 1))
                Picker("Tones from", selection: $model.rules.countdownFrom) {
                    ForEach(0...10, id: \.self) { second in
                        SecondsLabel(seconds: second).tag(second)
                    }
                }
            }
            Section {
                Button("WPA default") {
                    model.rules = .wpa
                }
                .disabled(model.rules == .wpa)
            } footer: {
                Text("Changes apply from the next start.")
            }
        }
        .navigationTitle("Settings")
    }
}

/// Picks a whole number of seconds; 0 reads as "Off".
private struct SecondsPicker: View {
    let title: LocalizedStringKey
    @Binding var value: TimeInterval
    let options: [Int]

    init(_ title: LocalizedStringKey, value: Binding<TimeInterval>, options: some Sequence<Int>) {
        self.title = title
        self._value = value
        self.options = Array(options)
    }

    var body: some View {
        Picker(title, selection: Binding(get: { Int(value) }, set: { value = TimeInterval($0) })) {
            ForEach(options, id: \.self) { second in
                SecondsLabel(seconds: second).tag(second)
            }
        }
    }
}

/// Short "30 s" on screen, spoken as "30 seconds".
private struct SecondsLabel: View {
    let seconds: Int

    var body: some View {
        if seconds == 0 {
            Text("Off")
        } else {
            Text("\(seconds) s")
                .accessibilityLabel(Text("\(seconds) seconds"))
        }
    }
}

/// Short "2×" on screen, spoken as "2 times".
private struct CountLabel: View {
    let count: Int

    var body: some View {
        if count == 0 {
            Text("None")
        } else {
            Text("\(count)×")
                .accessibilityLabel(Text("\(count) times"))
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView(model: ShotClockModel())
    }
}
