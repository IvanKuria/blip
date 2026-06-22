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
                    .opacity(model.isVisible ? 1 : 0)
                    .scaleEffect(
                        x: model.isVisible ? 1 : 0.65,
                        y: model.isVisible ? 1 : 0.4,
                        anchor: .top
                    )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .animation(reduceMotion ? .easeInOut(duration: 0.22) : Theme.spring, value: model.isVisible)
        .animation(reduceMotion ? .easeInOut(duration: 0.18) : Theme.spring, value: model.isHovered)
        .preferredColorScheme(.dark)
    }

    private func pill(for content: CopyContent) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 15) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 27, weight: .semibold))
                    .foregroundStyle(.white, Theme.check)

                chip(for: content)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title(for: content))
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                    subtitle(for: content)
                }

                if model.comboCount > 1 { comboBadge }
            }

            if model.isHovered, !model.actions.isEmpty {
                actionRow
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, (model.hasNotch ? model.notchHeight : 6) + 12)
        .padding(.bottom, 18)
        .frame(minWidth: max(model.minWidth, 300))
        .background { background.shadow(color: .black.opacity(0.3), radius: 9, y: 5) }
        .padding(.top, model.hasNotch ? 0 : 8)
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
            NotchBackground(radius: 14)
        } else {
            RoundedRectangle(cornerRadius: 20, style: .continuous).fill(.black)
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
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(hexString: hex))
                .frame(width: 44, height: 44)
                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(.white.opacity(0.2)))
        } else {
            chipGlyph(glyphName(for: content))
        }
    }

    private func thumbnailView(_ image: NSImage) -> some View {
        Image(nsImage: image)
            .resizable().interpolation(.high).aspectRatio(contentMode: .fill)
            .frame(width: 44, height: 44)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(.white.opacity(0.15)))
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
            .foregroundStyle(.white.opacity(0.7))
            .frame(width: 40, height: 40)
            .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(.white.opacity(0.10)))
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
                Image(nsImage: icon).resizable().frame(width: 16, height: 16)
            }
            Text(detailText(for: content))
                .font(.system(size: 13).monospacedDigit())
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
