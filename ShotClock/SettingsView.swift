import ShotClockCore
import SwiftUI

struct SettingsView: View {
    @Bindable var model: ShotClockModel

    var body: some View {
        List {
            Section {
                SecondsPicker("Stoßzeit", value: $model.rules.shotTime, options: stride(from: 10, through: 90, by: 5))
                SecondsPicker("Break-Bonus", value: $model.rules.breakBonus, options: stride(from: 0, through: 60, by: 5))
            }
            Section("Verlängerung") {
                SecondsPicker("Dauer", value: $model.rules.extensionTime, options: stride(from: 5, through: 60, by: 5))
                Picker("Pro Rack", selection: $model.rules.extensionsPerRack) {
                    ForEach(0...3, id: \.self) { count in
                        Text(count == 0 ? "keine" : "\(count)×")
                            .accessibilityLabel(count == 0 ? "keine" : count == 1 ? "einmal" : "\(count)-mal")
                            .tag(count)
                    }
                }
            }
            Section("Signale") {
                SecondsPicker("Vibration bei", value: $model.rules.warningAt, options: stride(from: 0, through: 20, by: 1))
                Picker("Töne ab", selection: $model.rules.countdownFrom) {
                    ForEach(0...10, id: \.self) { second in
                        Text(second == 0 ? "aus" : "\(second) s")
                            .accessibilityLabel(second == 0 ? "aus" : second == 1 ? "ab 1 Sekunde" : "ab \(second) Sekunden")
                            .tag(second)
                    }
                }
            }
            Section {
                Button("WPA-Standard") {
                    model.rules = .wpa
                }
                .disabled(model.rules == .wpa)
            } footer: {
                Text("Änderungen gelten ab dem nächsten Start.")
            }
        }
        .navigationTitle("Einstellungen")
    }
}

/// Picks a whole number of seconds; 0 reads as "aus".
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
                Text(second == 0 ? "aus" : "\(second) s")
                    .accessibilityLabel(second == 0 ? "aus" : second == 1 ? "1 Sekunde" : "\(second) Sekunden")
                    .tag(second)
            }
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView(model: ShotClockModel())
    }
}
