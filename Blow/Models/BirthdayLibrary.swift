import Foundation

/// A saved collection of birthday cakes ("presets"). The single editable draft
/// used by SetupView stays in `blow.birthday.v1`; this store holds the library of
/// named cakes and their birth dates for the reminder system.
struct BirthdayLibrary {
    private static let key = "blow.birthdays.v2"
    private static let legacyKey = "blow.birthday.v1"

    static func load() -> [Birthday] {
        if let data = UserDefaults.standard.data(forKey: key),
           let items = try? JSONDecoder().decode([Birthday].self, from: data) {
            return items
        }
        // One-time migration: seed the library with the current editable draft.
        if let data = UserDefaults.standard.data(forKey: legacyKey),
           var current = try? JSONDecoder().decode(Birthday.self, from: data) {
            current.label = current.presetTitle
            let list = [current]
            save(list)
            return list
        }
        return []
    }

    @discardableResult
    static func save(_ items: [Birthday]) -> [Birthday] {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: key)
        }
        return items
    }

    static func upsert(_ birthday: Birthday, into items: [Birthday]) -> [Birthday] {
        var list = items
        if let i = list.firstIndex(where: { $0.id == birthday.id }) {
            list[i] = birthday
        } else {
            list.append(birthday)
        }
        return save(list)
    }

    static func remove(id: UUID, from items: [Birthday]) -> [Birthday] {
        save(items.filter { $0.id != id })
    }
}

extension Birthday {
    /// Best available display name for a library row.
    var presetTitle: String {
        if !label.isEmpty { return label }
        if !recipient.isEmpty { return recipient }
        if !name.isEmpty { return name }
        return "Untitled birthday"
    }
}
