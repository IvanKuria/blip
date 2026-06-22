import AppKit

/// Where the pill lives: hanging from the top-center of the active screen, lined
/// up with the physical notch when there is one (so it reads as growing from it).
enum NotchGeometry {
    static func activeScreen() -> NSScreen {
        NSScreen.main ?? NSScreen.screens.first ?? NSScreen()
    }

    static func panelFrame(on screen: NSScreen, size: CGSize) -> NSRect {
        let frame = screen.frame
        return NSRect(
            x: frame.midX - size.width / 2,
            y: frame.maxY - size.height,
            width: size.width,
            height: size.height
        )
    }

    static func hasNotch(_ screen: NSScreen) -> Bool {
        screen.safeAreaInsets.top > 0
    }
}
