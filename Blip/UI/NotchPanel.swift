import AppKit

/// A borderless, non-activating panel that floats the pill above everything,
/// on every Space, never stealing focus or clicks.
final class NotchPanel: NSPanel {
    init(contentView: NSView) {
        super.init(
            contentRect: NSRect(origin: .zero, size: Theme.panelSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        isFloatingPanel = true
        level = .statusBar
        collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        ignoresMouseEvents = true
        hidesOnDeactivate = false
        isReleasedWhenClosed = false
        self.contentView = contentView
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
