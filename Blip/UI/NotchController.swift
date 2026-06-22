import AppKit
import SwiftUI
import QuickLookThumbnailing
import BlipKit

/// Owns the notch panel and drives the show → hold → retract cycle, coalescing
/// rapid copies. Reads display preferences live from `UserDefaults`.
@MainActor
final class NotchController {
    private let model = PillModel()
    private let panel: NotchPanel
    private var hideWork: DispatchWorkItem?

    init() {
        let hosting = NSHostingView(rootView: BlipView(model: model))
        hosting.translatesAutoresizingMaskIntoConstraints = true
        hosting.autoresizingMask = [.width, .height]
        panel = NotchPanel(contentView: hosting)
    }

    func show(_ event: CopyEvent) {
        let defaults = UserDefaults.standard
        model.showPreview = defaults.object(forKey: "showPreview") as? Bool ?? true
        let duration = defaults.object(forKey: "duration") as? Double ?? 1.2

        let screen = NotchGeometry.notchScreen()
        model.notchHeight = screen.safeAreaInsets.top
        model.minWidth = max(NotchGeometry.notchWidth(screen), 200)
        panel.setFrame(NotchGeometry.panelFrame(on: screen, size: Theme.panelSize), display: false)

        model.content = event.content
        model.sourceApp = NSWorkspace.shared.frontmostApplication?.localizedName
        enrichThumbnail(for: event.content)
        panel.orderFrontRegardless()
        model.isVisible = true

        if defaults.bool(forKey: "soundEnabled") {
            NSSound(named: "Tink")?.play()
        }

        hideWork?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.retract() }
        hideWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: work)
    }

    /// Pull a real preview from the system pasteboard (app-layer, keeps BlipKit pure):
    /// the copied image itself, or a file's QuickLook thumbnail (icon as fallback).
    private func enrichThumbnail(for content: CopyContent) {
        model.thumbnail = nil
        switch content {
        case .image:
            model.thumbnail = NSImage(pasteboard: .general)
        case .files:
            guard let url = firstFileURL() else { return }
            model.thumbnail = NSWorkspace.shared.icon(forFile: url.path)  // instant fallback
            let request = QLThumbnailGenerator.Request(
                fileAt: url, size: CGSize(width: 64, height: 64),
                scale: 2, representationTypes: .thumbnail
            )
            QLThumbnailGenerator.shared.generateBestRepresentation(for: request) { [weak self] rep, _ in
                guard let rep else { return }
                let image = rep.nsImage
                DispatchQueue.main.async {
                    guard let self, self.model.content == content else { return }
                    self.model.thumbnail = image
                }
            }
        default:
            break
        }
    }

    private func firstFileURL() -> URL? {
        let options: [NSPasteboard.ReadingOptionKey: Any] = [.urlReadingFileURLsOnly: true]
        return (NSPasteboard.general.readObjects(forClasses: [NSURL.self], options: options) as? [URL])?.first
    }

    private func retract() {
        model.isVisible = false
        // Order the panel out after the retract animation completes.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { [weak self] in
            guard let self, self.model.isVisible == false else { return }
            self.panel.orderOut(nil)
            self.model.content = nil
            self.model.thumbnail = nil
            self.model.sourceApp = nil
        }
    }

}
