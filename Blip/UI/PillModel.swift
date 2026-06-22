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
}
