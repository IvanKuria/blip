import SwiftUI
import BlipKit

/// The pill — drawn as the notch *itself* extending downward: flush to the top
/// edge, square top corners, rounded bottom, true black so it merges with the
/// physical notch. Content sits below the notch line.
struct BlipView: View {
    @Bindable var model: PillModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let bottomRadius: CGFloat = 20

    var body: some View {
        ZStack(alignment: .top) {
            if let content = model.content {
                pill(for: content)
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
        .allowsHitTesting(false)
        .preferredColorScheme(.dark)
    }

    private func pill(for content: CopyContent) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white, Theme.check)

            chip(for: content)

            VStack(alignment: .leading, spacing: 1) {
                Text(title(for: content))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                Text(subtitle(for: content))
                    .font(.system(size: 11).monospacedDigit())
                    .foregroundStyle(.white.opacity(0.6))
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 18)
        // Push content below the physical notch (or below the menu bar on
        // non-notch displays), so the top of the shape merges with the notch.
        .padding(.top, (model.hasNotch ? model.notchHeight : 4) + 6)
        .padding(.bottom, 13)
        .frame(minWidth: model.minWidth)
        .background {
            background
                .shadow(color: .black.opacity(0.3), radius: 9, y: 5)
        }
        .padding(.top, model.hasNotch ? 0 : 8)  // soft-pill nudge on non-notch
    }

    /// The notch silhouette (flush top + concave fillets + rounded bottom) on
    /// notch Macs; a fully rounded soft pill otherwise.
    @ViewBuilder
    private var background: some View {
        if model.hasNotch {
            NotchBackground(radius: 14)
        } else {
            RoundedRectangle(cornerRadius: bottomRadius, style: .continuous).fill(.black)
        }
    }

    // MARK: Content chip

    @ViewBuilder
    private func chip(for content: CopyContent) -> some View {
        switch content {
        case .color(let hex):
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color(hexString: hex))
                .frame(width: 26, height: 26)
                .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(.white.opacity(0.18)))
        case .image: chipGlyph("photo")
        case .files: chipGlyph("doc.on.doc.fill")
        case .link: chipGlyph("link")
        case .concealed: chipGlyph("lock.fill")
        case .text: chipGlyph("textformat")
        }
    }

    private func chipGlyph(_ name: String) -> some View {
        Image(systemName: name)
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(.white.opacity(0.7))
            .frame(width: 26, height: 26)
            .background(RoundedRectangle(cornerRadius: 6, style: .continuous).fill(.white.opacity(0.10)))
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
        case .color(let hex): return hex
        case .image(let w, let h, let bytes): return "\(w)×\(h) · \(byteString(bytes))"
        case .files(let names, let count): return count == 1 ? (names.first ?? "1 item") : "\(count) items"
        case .link(let domain): return domain
        case .concealed: return "hidden"
        }
    }

    private func byteString(_ bytes: Int) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
    }
}
