import AppKit
import Observation
import BlipKit

/// Observable state the pill view renders. The controller mutates it; the view
/// animates off `isVisible`.
/// One copied file in the side-by-side tray.
struct FileItem: Identifiable {
    let id = UUID()
    let name: String
    var image: NSImage
}

@MainActor
@Observable
final class PillModel {
    var content: CopyContent?
    var isVisible = false
    var showPreview = true
    /// Minimum pill width so it never looks narrower than the physical notch.
    var minWidth: CGFloat = 200
    /// Height of the physical notch (0 on displays without one).
    var notchHeight: CGFloat = 0
    var hasNotch: Bool { notchHeight > 0 }
    /// Real previews (the copied image).
    var thumbnails: [NSImage] = []
    /// Copied files, shown side-by-side (NotchDrop-style tray).
    var fileItems: [FileItem] = []
    /// The app the copy came from (e.g. "Safari") + its icon.
    var sourceApp: String?
    var sourceAppIcon: NSImage?
    /// How many rapid copies in a row (shown as "×N" when > 1).
    var comboCount: Int = 1
    /// True while the cursor is over the pill (keeps it open, reveals actions).
    var isHovered = false
    /// Contextual quick actions for the current content.
    var actions: [CopyAction] = []
}
