import SwiftUI

@main
struct FlightTrackerApp: App {
    @State private var store = TrackerStore()

    var body: some Scene {
        WindowGroup {
            RouteListView()
                .environment(store)
                .task { NotificationService.shared.requestAuthorizationIfNeeded() }
        }
    }
}
