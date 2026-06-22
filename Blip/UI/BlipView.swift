import SwiftUI
import AppKit
import BlipKit

/// The pill — drawn as the notch extending downward (flush top + concave
/// fillets + rounded bottom). Shows a green check, a content-aware preview
/// (thumbnail / stacked file thumbnails / color swatch), source app, a combo
/// streak, and — on hover — contextual quick actions.
struct BlipView: View {
    @Bindable var model: PillModel
    var onHoverChange: (Bool) -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack(alignment: .top) {
            if let content = model.content {
                pill(for: content)
                    .onHover { hovering in
                        model.isHovered = hovering
                        onHoverChange(hovering)
                    }
                    .onTapGesture { model.actions.first?.perform() }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .animation(reduceMotion ? .easeInOut(duration: 0.22) : Theme.spring, value: model.isVisible)
        .animation(reduceMotion ? .easeInOut(duration: 0.18) : Theme.spring, value: model.isHovered)
        .preferredColorScheme(.dark)
    }

    private func pill(for content: CopyContent) -> some View {
        VStack(spacing: 0) {
            contentBody(for: content)
            if model.isHovered, !model.actions.isEmpty { actionRow }
        }
        .padding(.horizontal, 20)
        .padding(.top, (model.hasNotch ? model.notchHeight : 6) + 8)
        .padding(.bottom, 14)
        .frame(minWidth: max(model.minWidth, 230))
        // Content fades + lifts (applied before the background so only the
        // content fades, not the black).
        .opacity(model.isVisible ? 1 : 0)
        .scaleEffect(model.isVisible ? 1 : 0.97, anchor: .top)
        .offset(y: model.isVisible ? 0 : -6)
        // The black notch shape widens out of the notch and collapses back into
        // it — scaling AND fading symmetrically so there's no opaque pop on exit.
        // Bled 2px above the top edge so there's never a seam at the menu bar.
        .background {
            backgroundLayer
                .scaleEffect(x: model.isVisible ? 1 : 0.42, y: model.isVisible ? 1 : 0.32, anchor: .top)
                .opacity(model.isVisible ? 1 : 0)
                .padding(.top, model.hasNotch ? -2 : 0)
        }
        .padding(.top, model.hasNotch ? 0 : 8)
    }

    @ViewBuilder
    private var backgroundLayer: some View {
        if model.hasNotch {
            background
        } else {
            background.shadow(color: .black.opacity(0.3), radius: 9, y: 5)
        }
    }

    // MARK: Content body (single row, or side-by-side file tray)

    @ViewBuilder
    private func contentBody(for content: CopyContent) -> some View {
        if case .files = content, !model.fileItems.isEmpty {
            filesBody(content)
        } else {
            singleRow(content)
        }
    }

    private func singleRow(_ content: CopyContent) -> some View {
        HStack(spacing: 12) {
            checkmark
            chip(for: content)
            VStack(alignment: .leading, spacing: 2) {
                Text(title(for: content))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                subtitle(for: content)
            }
            if model.comboCount > 1 { comboBadge }
        }
    }

    private func filesBody(_ content: CopyContent) -> some View {
        let total: Int = { if case let .files(_, count) = content { return count } else { return model.fileItems.count } }()
        let extra = max(0, total - model.fileItems.count)
        return VStack(alignment: .leading, spacing: 13) {
            HStack(spacing: 15) {
                checkmark
                VStack(alignment: .leading, spacing: 2) {
                    Text("Copied").font(.system(size: 15, weight: .semibold)).foregroundStyle(.white)
                    HStack(spacing: 6) {
                        if let icon = model.sourceAppIcon {
                            Image(nsImage: icon).resizable().frame(width: 20, height: 20)
                        }
                        Text("\(total) item\(total == 1 ? "" : "s")")
                            .font(.system(size: 12).monospacedDigit())
                            .foregroundStyle(.white.opacity(0.62))
                    }
                }
                if model.comboCount > 1 { comboBadge }
            }
            HStack(spacing: 10) {
                ForEach(model.fileItems) { fileTile($0) }
                if extra > 0 { moreTile(extra) }
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(.white.opacity(0.06)))
        }
    }

    private func fileTile(_ item: FileItem) -> some View {
        VStack(spacing: 6) {
            Image(nsImage: item.image)
                .resizable().interpolation(.high).aspectRatio(contentMode: .fit)
                .frame(width: 46, height: 46)
            Text(item.name)
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.8))
                .lineLimit(1).truncationMode(.middle)
                .frame(width: 78)
        }
        .frame(width: 86)
    }

    private func moreTile(_ count: Int) -> some View {
        VStack(spacing: 6) {
            Text("+\(count)")
                .font(.system(size: 18, weight: .semibold).monospacedDigit())
                .foregroundStyle(.white.opacity(0.8))
                .frame(width: 46, height: 46)
                .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(.white.opacity(0.08)))
            Text("more").font(.system(size: 11)).foregroundStyle(.white.opacity(0.6))
        }
        .frame(width: 64)
    }

    private var checkmark: some View {
        Image(systemName: "checkmark.circle.fill")
            .font(.system(size: 21, weight: .semibold))
            .foregroundStyle(.white, Theme.check)
    }

    // MARK: Hover actions

    private var actionRow: some View {
        HStack(spacing: 8) {
            ForEach(model.actions) { action in
                Button {
                    action.perform()
                    model.isHovered = false
                    onHoverChange(false)
                } label: {
                    Label(action.title, systemImage: action.systemImage)
                        .font(.system(size: 13, weight: .medium))
                        .padding(.horizontal, 12).padding(.vertical, 7)
                        .background(Capsule().fill(.white.opacity(0.12)))
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 10)
    }

    private var comboBadge: some View {
        Text("×\(model.comboCount)")
            .font(.system(size: 15, weight: .bold).monospacedDigit())
            .foregroundStyle(.white)
            .padding(.horizontal, 9).padding(.vertical, 4)
            .background(Capsule().fill(Theme.check))
    }

    // MARK: Background shape

    @ViewBuilder
    private var background: some View {
        if model.hasNotch {
            NotchBackground(radius: 22)
        } else {
            RoundedRectangle(cornerRadius: 24, style: .continuous).fill(.black)
        }
    }

    // MARK: Content chip (thumbnail / stack / swatch / glyph)

    @ViewBuilder
    private func chip(for content: CopyContent) -> some View {
        if model.thumbnails.count > 1 {
            stackedThumbnails
        } else if let thumb = model.thumbnails.first {
            thumbnailView(thumb)
        } else if case let .color(hex) = content {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(Color(hexString: hex))
                .frame(width: 38, height: 38)
                .overlay(RoundedRectangle(cornerRadius: 9).strokeBorder(.white.opacity(0.2)))
        } else {
            chipGlyph(glyphName(for: content))
        }
    }

    private func thumbnailView(_ image: NSImage) -> some View {
        Image(nsImage: image)
            .resizable().interpolation(.high).aspectRatio(contentMode: .fill)
            .frame(width: 38, height: 38)
            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 9).strokeBorder(.white.opacity(0.15)))
    }

    private var stackedThumbnails: some View {
        ZStack {
            ForEach(Array(model.thumbnails.prefix(3).enumerated().reversed()), id: \.offset) { index, image in
                Image(nsImage: image)
                    .resizable().interpolation(.high).aspectRatio(contentMode: .fill)
                    .frame(width: 38, height: 38)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(.white.opacity(0.2)))
                    .rotationEffect(.degrees(Double(index) * 6 - 6))
                    .offset(x: CGFloat(index) * 4, y: CGFloat(index) * -1.5)
            }
        }
        .frame(width: 50, height: 44)
    }

    private func chipGlyph(_ name: String) -> some View {
        Image(systemName: name)
            .font(.system(size: 19, weight: .medium))
            .foregroundStyle(.white.opacity(0.85))
            .frame(width: 34, height: 34)
    }

    private func glyphName(for content: CopyContent) -> String {
        switch content {
        case .image: "photo"
        case .files: "doc.on.doc.fill"
        case .link: "link"
        case .concealed: "lock.fill"
        case .text, .color: "textformat"
        }
    }

    // MARK: Title / subtitle

    private func title(for content: CopyContent) -> String {
        if case .link = content { return "Copied link" }
        return "Copied"
    }

    @ViewBuilder
    private func subtitle(for content: CopyContent) -> some View {
        HStack(spacing: 6) {
            if let icon = model.sourceAppIcon, !isColor(content) {
                Image(nsImage: icon).resizable().frame(width: 20, height: 20)
            }
            Text(detailText(for: content))
                .font(.system(size: 12).monospacedDigit())
                .foregroundStyle(.white.opacity(0.62))
                .lineLimit(1)
        }
    }

    private func isColor(_ content: CopyContent) -> Bool {
        if case .color = content { return true }
        return false
    }

    private func detailText(for content: CopyContent) -> String {
        switch content {
        case .text(let characters, let words, let preview):
            if model.showPreview, !preview.isEmpty {
                return prefixApp(preview)
            }
            return prefixApp("\(words) word\(words == 1 ? "" : "s") · \(characters) character\(characters == 1 ? "" : "s")")
        case .color(let hex):
            if let rgb = ColorFormat.rgb(hex: hex) { return "\(hex) · \(rgb)" }
            return hex
        case .image(let w, let h, let bytes):
            return prefixApp("\(w)×\(h) · \(byteString(bytes))")
        case .files(let names, let count):
            return prefixApp(count == 1 ? (names.first ?? "1 item") : "\(count) items")
        case .link(let domain):
            return prefixApp(domain)
        case .concealed:
            return prefixApp("hidden")
        }
    }

    private func prefixApp(_ detail: String) -> String {
        if let app = model.sourceApp, !app.isEmpty { return "\(app) · \(detail)" }
        return detail
    }

    private func byteString(_ bytes: Int) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
    }
}
