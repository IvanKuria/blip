import AppKit
import SwiftUI
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

        positionPanel()
        model.content = event.content
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

    private func retract() {
        model.isVisible = false
        // Order the panel out after the retract animation completes.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { [weak self] in
            guard let self, self.model.isVisible == false else { return }
            self.panel.orderOut(nil)
            self.model.content = nil
        }
    }

    private func positionPanel() {
        let screen = NotchGeometry.activeScreen()
        panel.setFrame(NotchGeometry.panelFrame(on: screen, size: Theme.panelSize), display: false)
    }
}
