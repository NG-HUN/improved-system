import UIKit
import UserNotifications

/// Captures a tap on a birthday reminder and hands the target preset to RootView.
/// The app cannot auto-send, but a tap lands the user straight on a pre-filled card.
final class NotificationDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    static let launchKey = "blow.notification.launchPreset"

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let id = response.notification.request.identifier
        if id.hasPrefix("blow.reminder.") {
            let uuid = String(id.dropFirst("blow.reminder.".count))
            UserDefaults.standard.set(uuid, forKey: Self.launchKey)
        }
        completionHandler()
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }
}
