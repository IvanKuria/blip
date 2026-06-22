import Foundation
import ImageIO

/// Turns the current pasteboard into a `CopyContent` for display, or `nil` when
/// there's nothing worth showing (transient or empty). Pure and deterministic.
public enum ClipboardClassifier {
    public static func classify(_ pasteboard: PasteboardReading) -> CopyContent? {
        let types = pasteboard.availableTypes()

        // Transient copies (automation/app-internal) are never surfaced.
        if types.contains(PBType.transient) { return nil }

        // Concealed copies (password managers) show "hidden", never the value.
        if types.contains(PBType.concealed) { return .concealed }

        // Files.
        let names = pasteboard.fileNames()
        if !names.isEmpty {
            return .files(names: names, count: names.count)
        }

        // Image (dimensions via ImageIO - no AppKit needed).
        for imageType in [PBType.png, PBType.tiff] where types.contains(imageType) {
            if let data = pasteboard.data(forType: imageType), let size = pixelSize(of: data) {
                return .image(pixelWidth: size.0, pixelHeight: size.1, byteCount: data.count)
            }
        }

        // Text-ish.
        if let raw = pasteboard.string(forType: PBType.string) {
            let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return nil }

            if let hex = normalizedHex(trimmed) { return .color(hex: hex) }
            if let domain = linkDomain(trimmed) { return .link(domain: domain) }

            let words = trimmed.split(whereSeparator: { $0.isWhitespace }).count
            let preview = String(trimmed.prefix(64))
                .replacingOccurrences(of: "\n", with: " ")
            return .text(characters: trimmed.count, words: words, preview: preview)
        }

        return nil
    }

    // MARK: - Helpers

    private static func pixelSize(of data: Data) -> (Int, Int)? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = props[kCGImagePropertyPixelWidth] as? Int,
              let height = props[kCGImagePropertyPixelHeight] as? Int else {
            return nil
        }
        return (width, height)
    }

    /// `#RRGGBB` / `RRGGBB` / `#RGB` / `RGB` → normalized uppercase `#RRGGBB`.
    private static func normalizedHex(_ string: String) -> String? {
        let body = string.hasPrefix("#") ? String(string.dropFirst()) : string
        let isHex = body.allSatisfy { $0.isHexDigit }
        guard isHex, body.count == 3 || body.count == 6 else { return nil }
        let expanded = body.count == 3 ? body.map { "\($0)\($0)" }.joined() : body
        return "#" + expanded.uppercased()
    }

    /// http/https URL → bare host (drops a leading `www.`).
    private static func linkDomain(_ string: String) -> String? {
        guard let components = URLComponents(string: string),
              let scheme = components.scheme?.lowercased(),
              scheme == "http" || scheme == "https",
              var host = components.host, !host.isEmpty else {
            return nil
        }
        if host.hasPrefix("www.") { host.removeFirst(4) }
        return host
    }
}
