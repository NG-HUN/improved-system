import Foundation
import SwiftUI

/// Stores user-uploaded sticker images locally in Documents/Stickers.
/// Nothing leaves the device — no network, no cloud, no photo-library write.
enum StickerStore {
    private static var dir: URL? {
        guard let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        let d = docs.appendingPathComponent("Stickers", isDirectory: true)
        if !FileManager.default.fileExists(atPath: d.path) {
            try? FileManager.default.createDirectory(at: d, withIntermediateDirectories: true)
        }
        return d
    }

    /// Save a UIImage as PNG and return the file name to reference in a placement.
    @discardableResult
    static func save(image: UIImage) -> String? {
        guard let dir,
              let data = image.pngData() else { return nil }
        let name = "sticker-\(UUID().uuidString).png"
        let url = dir.appendingPathComponent(name)
        do {
            try data.write(to: url, options: .atomic)
            return name
        } catch { return nil }
    }

    static func loadImage(named name: String) -> UIImage? {
        guard let dir else { return nil }
        return UIImage(contentsOfFile: dir.appendingPathComponent(name).path)
    }

    static func remove(named name: String) {
        guard let dir else { return }
        try? FileManager.default.removeItem(at: dir.appendingPathComponent(name))
    }

    /// Names of every custom sticker currently on disk.
    static func allNames() -> [String] {
        guard let dir,
              let files = try? FileManager.default.contentsOfDirectory(atPath: dir.path) else { return [] }
        return files.filter { $0.hasPrefix("sticker-") && $0.hasSuffix(".png") }
    }
}
