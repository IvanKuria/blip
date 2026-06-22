import AppKit
import SwiftUI
import QuickLookThumbnailing
import BlipKit

/// Owns the notch panel and drives show → hold → retract, coalescing rapid
/// copies (with a combo count), enriching with real previews + source app, and
/// keeping the pill open while hovered so its quick actions are usable.
@MainActor
final class NotchController {
    private let model = PillModel()
    private let panel: NotchPanel
    private let hosting: NSHostingView<AnyView>
    private var hideWork: DispatchWorkItem?
    private var lastShownAt: Date?

    init() {
        hosting = NSHostingView(rootView: AnyView(EmptyView()))
        hosting.translatesAutoresizingMaskIntoConstraints = true
        hosting.autoresizingMask = [.width, .height]
        panel = NotchPanel(contentView: hosting)
        hosting.rootView = AnyView(
            BlipView(
                model: model,
                onHoverChange: { [weak self] hovering in self?.hoverChanged(hovering) }
            )
        )
    }

    func show(_ event: CopyEvent) {
        let defaults = UserDefaults.standard
        model.showPreview = defaults.object(forKey: "showPreview") as? Bool ?? true
        let duration = defaults.object(forKey: "duration") as? Double ?? 2.6

        let screen = NotchGeometry.notchScreen()
        model.notchHeight = screen.safeAreaInsets.top
        model.minWidth = max(NotchGeometry.notchWidth(screen), 200)
        panel.setFrame(NotchGeometry.panelFrame(on: screen, size: Theme.panelSize), display: false)

        // Combo: rapid successive copies stack a "×N" streak.
        let now = Date()
        model.comboCount = (lastShownAt.map { now.timeIntervalSince($0) < 1.6 } ?? false) ? model.comboCount + 1 : 1
        lastShownAt = now

        model.content = event.content
        let app = NSWorkspace.shared.frontmostApplication
        model.sourceApp = app?.localizedName
        model.sourceAppIcon = app?.icon
        model.actions = CopyActions.actions(for: event.content)
        enrichThumbnails(for: event.content)

        panel.orderFrontRegardless()
        model.isVisible = true

        if defaults.bool(forKey: "soundEnabled") {
            NSSound(named: "Tink")?.play()
        }

        scheduleHide(after: duration)
    }

    // MARK: Hover

    private func hoverChanged(_ hovering: Bool) {
        if hovering {
            hideWork?.cancel()
        } else {
            scheduleHide(after: 0.5)
        }
    }

    private func scheduleHide(after delay: TimeInterval) {
        hideWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            if self.model.isHovered { self.scheduleHide(after: 0.5); return }
            self.retract()
        }
        hideWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }

    private func retract() {
        model.isVisible = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { [weak self] in
            guard let self, self.model.isVisible == false else { return }
            self.panel.orderOut(nil)
            self.model.content = nil
            self.model.thumbnails = []
            self.model.sourceApp = nil
            self.model.sourceAppIcon = nil
            self.model.actions = []
            self.model.isHovered = false
        }
    }

    // MARK: Previews

    private func enrichThumbnails(for content: CopyContent) {
        model.thumbnails = []
        switch content {
        case .image:
            if let image = NSImage(pasteboard: .general) { model.thumbnails = [image] }
        case .files:
            let urls = fileURLs()
            model.thumbnails = urls.prefix(3).map { NSWorkspace.shared.icon(forFile: $0.path) }
            if let first = urls.first { upgradeWithQuickLook(first, for: content) }
        default:
            break
        }
    }

    private func upgradeWithQuickLook(_ url: URL, for content: CopyContent) {
        let request = QLThumbnailGenerator.Request(
            fileAt: url, size: CGSize(width: 64, height: 64), scale: 2, representationTypes: .thumbnail
        )
        QLThumbnailGenerator.shared.generateBestRepresentation(for: request) { [weak self] rep, _ in
            guard let rep else { return }
            let image = rep.nsImage
            DispatchQueue.main.async {
                guard let self, self.model.content == content, !self.model.thumbnails.isEmpty else { return }
                self.model.thumbnails[0] = image
            }
        }
    }

    private func fileURLs() -> [URL] {
        let options: [NSPasteboard.ReadingOptionKey: Any] = [.urlReadingFileURLsOnly: true]
        return (NSPasteboard.general.readObjects(forClasses: [NSURL.self], options: options) as? [URL]) ?? []
    }
}
