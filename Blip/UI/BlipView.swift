import SwiftUI
import BlipKit

/// The pill itself — a Dynamic-Island-style capsule that animates down from the
/// notch, shows a green check + a content-aware chip, and retracts.
struct BlipView: View {
    @Bindable var model: PillModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack {
            if let content = model.content {
                pill(for: content)
                    .opacity(model.isVisible ? 1 : 0)
                    .scaleEffect(model.isVisible ? 1 : 0.86, anchor: .top)
                    .offset(y: model.isVisible ? 0 : -18)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(reduceMotion ? .easeInOut(duration: 0.2) : Theme.spring, value: model.isVisible)
        .allowsHitTesting(false)
    }

    private func pill(for content: CopyContent) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white, Theme.check)

            chip(for: content)

            VStack(alignment: .leading, spacing: 1) {
                Text(title(for: content))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.title)
                Text(subtitle(for: content))
                    .font(.system(size: 11).monospacedDigit())
                    .foregroundStyle(Theme.subtitle)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 18)
        .frame(height: Theme.pillHeight)
        .background(
            RoundedRectangle(cornerRadius: Theme.pillCornerRadius, style: .continuous)
                .fill(.black)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.pillCornerRadius, style: .continuous)
                        .strokeBorder(.white.opacity(0.08), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.35), radius: 12, y: 6)
        .fixedSize()
    }

    // MARK: Content chip

    @ViewBuilder
    private func chip(for content: CopyContent) -> some View {
        switch content {
        case .color(let hex):
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color(hexString: hex))
                .frame(width: 28, height: 28)
                .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(.white.opacity(0.15)))
        case .image:
            chipGlyph("photo")
        case .files:
            chipGlyph("doc.on.doc.fill")
        case .link:
            chipGlyph("link")
        case .concealed:
            chipGlyph("lock.fill")
        case .text:
            chipGlyph("textformat")
        }
    }

    private func chipGlyph(_ name: String) -> some View {
        Image(systemName: name)
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(Theme.subtitle)
            .frame(width: 28, height: 28)
            .background(RoundedRectangle(cornerRadius: 6, style: .continuous).fill(.white.opacity(0.08)))
    }

    // MARK: Copy

    private func title(for content: CopyContent) -> String {
        if case .link = content { return "Copied link" }
        return "Copied"
    }

    private func subtitle(for content: CopyContent) -> String {
        switch content {
        case .text(let characters, let preview):
            if model.showPreview, !preview.isEmpty { return preview }
            return "\(characters) character\(characters == 1 ? "" : "s")"
        case .color(let hex):
            return hex
        case .image(let w, let h, let bytes):
            return "\(w)×\(h) · \(byteString(bytes))"
        case .files(let names, let count):
            return count == 1 ? (names.first ?? "1 item") : "\(count) items"
        case .link(let domain):
            return domain
        case .concealed:
            return "hidden"
        }
    }

    private func byteString(_ bytes: Int) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
    }
}
