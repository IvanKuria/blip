import AppKit
import BlipKit

/// `PasteboardReading` backed by the real system pasteboard.
struct SystemPasteboard: PasteboardReading {
    private let pasteboard = NSPasteboard.general

    var changeCount: Int { pasteboard.changeCount }

    func availableTypes() -> [String] {
        (pasteboard.types ?? []).map(\.rawValue)
    }

    func string(forType type: String) -> String? {
        pasteboard.string(forType: NSPasteboard.PasteboardType(type))
    }

    func data(forType type: String) -> Data? {
        pasteboard.data(forType: NSPasteboard.PasteboardType(type))
    }

    func fileNames() -> [String] {
        let options: [NSPasteboard.ReadingOptionKey: Any] = [.urlReadingFileURLsOnly: true]
        guard let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: options) as? [URL],
              !urls.isEmpty else {
            return []
        }
        return urls.map { $0.lastPathComponent }
    }
}
