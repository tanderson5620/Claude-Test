import SwiftUI

@main
@MainActor
struct FlightTrackerApp: App {
    @State private var settings: Settings
    @State private var store: TrackerStore

    init() {
        let settings = Settings()
        _settings = State(initialValue: settings)
        _store = State(initialValue: TrackerStore(provider: settings.makeProvider()))
    }

    var body: some Scene {
        WindowGroup {
            RouteListView()
                .environment(store)
                .environment(settings)
                .task {
                    NotificationService.shared.requestAuthorizationIfNeeded()
                    // Pick up a key entered on a previous launch.
                    store.useProvider(settings.makeProvider())
                }
        }
    }
}
