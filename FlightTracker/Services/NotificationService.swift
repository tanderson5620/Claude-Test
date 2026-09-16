import Foundation
import UserNotifications

/// Local notifications for price drops. No server involved — these fire from
/// the app itself when a refresh turns up a new low.
final class NotificationService {
    static let shared = NotificationService()
    private init() {}

    func requestAuthorizationIfNeeded() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func notifyPriceDrop(route: TrackedRoute, newPrice: Decimal) {
        let content = UNMutableNotificationContent()
        content.title = "\(route.origin) → \(route.destination) got cheaper"
        content.body = "Now \(newPrice.formatted(.currency(code: route.currencyCode)))"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
}
