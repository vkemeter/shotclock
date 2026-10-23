import SwiftUI

@main
struct ShotClockApp: App {
    @State private var model = ShotClockModel()

    var body: some Scene {
        WindowGroup {
            ClockView(model: model)
                #if DEBUG
                .task {
                    // Lets the simulator show a running clock without interaction.
                    if ProcessInfo.processInfo.arguments.contains("-autostart") {
                        model.perform(.startOrRestart)
                    }
                }
                #endif
        }
    }
}
