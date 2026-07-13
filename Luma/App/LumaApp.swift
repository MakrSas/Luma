import SwiftUI

@main
struct LumaApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .preferredColorScheme(nil)
        }
    }
}
