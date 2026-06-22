import Foundation
import Observation
import BlipKit

/// Observable state the pill view renders. The controller mutates it; the view
/// animates off `isVisible`.
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
}
