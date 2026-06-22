import Foundation

/// Watches the pasteboard for real changes and emits a classified `CopyEvent`.
///
/// The app drives `poll()` on a timer (~0.25s). The watcher only acts when
/// `changeCount` actually advances, and emits nothing for transient/empty copies
/// (the classifier returns `nil`) while still tracking the new count.
public final class ClipboardWatcher {
    private let pasteboard: PasteboardReading
    private let now: () -> Date
    private var lastChangeCount: Int

    /// Called on the main actor by the app; not thread-safe by itself.
    public var onEvent: ((CopyEvent) -> Void)?

    public init(pasteboard: PasteboardReading, now: @escaping () -> Date = Date.init) {
        self.pasteboard = pasteboard
        self.now = now
        // Capture the current count so only future changes fire.
        self.lastChangeCount = pasteboard.changeCount
    }

    public func poll() {
        let current = pasteboard.changeCount
        guard current != lastChangeCount else { return }
        lastChangeCount = current

        if let content = ClipboardClassifier.classify(pasteboard) {
            onEvent?(CopyEvent(content: content, date: now()))
        }
    }
}
