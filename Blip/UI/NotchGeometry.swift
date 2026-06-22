import AppKit

/// Notch detection + placement. The pill hangs flush from the very top of the
/// built-in display, centered on the physical notch, so it reads as the notch
/// itself growing downward. (Notch-size technique adapted from Lakr233/NotchDrop, MIT.)
enum NotchGeometry {
    /// The screen with the physical notch, falling back to main/first.
    static func notchScreen() -> NSScreen {
        NSScreen.screens.first(where: { $0.safeAreaInsets.top > 0 })
            ?? NSScreen.main
            ?? NSScreen.screens.first
            ?? NSScreen()
    }

    /// Width of the physical notch on `screen`, or 0 if there isn't one.
    static func notchWidth(_ screen: NSScreen) -> CGFloat {
        guard screen.safeAreaInsets.top > 0,
              let left = screen.auxiliaryTopLeftArea?.width,
              let right = screen.auxiliaryTopRightArea?.width,
              left > 0, right > 0 else { return 0 }
        return screen.frame.width - left - right
    }

    /// A panel pinned flush to the top-center of `screen`.
    static func panelFrame(on screen: NSScreen, size: CGSize) -> NSRect {
        let frame = screen.frame
        return NSRect(
            x: frame.midX - size.width / 2,
            y: frame.maxY - size.height,
            width: size.width,
            height: size.height
        )
    }
}
