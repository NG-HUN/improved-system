import Foundation
import UserNotifications

/// Schedules local birthday reminders. iOS forbids silent auto-sending, so a
/// reminder taps the user into the app where the pre-filled card is one share
/// away. Every birthday is re-scheduled (old requests removed first) to avoid
/// duplicates when a date changes.
@MainActor
final class ReminderManager {
    static let shared = ReminderManager()

    /// Pending notification identifiers are tracked in UserDefaults so we can
    /// cancel exactly the ones we created.
    private let idsKey = "blow.reminder.ids"

    func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional: return true
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        default: return false
        }
    }

    /// Rebuild all reminders from the current library. Keeps only the nearest
    /// `limit` upcoming birthdays because iOS caps pending requests (~64).
    func reschedule(_ items: [Birthday], daysBefore: Int = 1, hour: Int = 9, limit: Int = 40) async {
        let center = UNUserNotificationCenter.current()
        await cancelAll(center)

        let upcoming = items.compactMap { b -> (Birthday, Date)? in
            guard let date = b.birthDate else { return nil }
            guard let next = nextOccurrence(of: date) else { return nil }
            return (b, next)
        }
        .sorted { $0.1 < $1.1 }
        .prefix(limit)

        // Group the firing dates by calendar day so a day with N birthdays gets
        // a badge of N (cumulative unread), not one badge per notification.
        struct Entry { let birthday: Birthday; let comps: DateComponents; let dayKey: String }
        var entries: [Entry] = []
        for (b, next) in upcoming {
            guard let fire = calendar.date(byAdding: .day, value: -daysBefore, to: next),
                  let scheduled = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: fire),
                  scheduled > Date() else { continue }
            var comps = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: scheduled)
            comps.second = 0
            let dayKey = "\(comps.year ?? 0)-\(comps.month ?? 0)-\(comps.day ?? 0)"
            entries.append(Entry(birthday: b, comps: comps, dayKey: dayKey))
        }
        var badgeForDay: [String: Int] = [:]
        for e in entries { badgeForDay[e.dayKey, default: 0] += 1 }

        var ids: [String] = []
        for e in entries {
            let content = UNMutableNotificationContent()
            content.title = "Time to send your wishes"
            content.body = "\(e.birthday.presetTitle)'s birthday is coming up. Open Blow to send a card."
            content.sound = .default
            content.badge = NSNumber(value: badgeForDay[e.dayKey] ?? 1)

            let trigger = UNCalendarNotificationTrigger(dateMatching: e.comps, repeats: false)
            let id = "blow.reminder.\(e.birthday.id.uuidString)"
            if (try? await center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))) != nil {
                ids.append(id)
            }
        }
        UserDefaults.standard.set(ids, forKey: idsKey)
    }

    /// Clear the unread badge when the user opens the app.
    func clearBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0) { _ in }
    }

    func cancelAll(_ center: UNUserNotificationCenter = .current()) async {
        let stored = UserDefaults.standard.stringArray(forKey: idsKey) ?? []
        if !stored.isEmpty { center.removePendingNotificationRequests(withIdentifiers: stored) }
        UserDefaults.standard.removeObject(forKey: idsKey)
    }

    private var calendar: Calendar { Calendar.current }

    private func nextOccurrence(of date: Date) -> Date? {
        let now = Date()
        let comps = calendar.dateComponents([.month, .day], from: date)
        guard let next = calendar.nextDate(after: now, matching: comps,
                                           matchingPolicy: .nextTime, repeatedTimePolicy: .first,
                                           direction: .forward) else { return nil }
        return next
    }
}
