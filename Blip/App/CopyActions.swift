import AppKit
import BlipKit

/// A single contextual quick-action shown in the copy-confirmation pill.
struct CopyAction: Identifiable {
    let id = UUID()
    let title: String
    let systemImage: String   // SF Symbol name
    let perform: @MainActor () -> Void
}

/// Builds the contextual quick-actions for a given copy, reading from the
/// general pasteboard as needed. Every `perform` is self-contained and
/// crash-safe: it re-reads the pasteboard at invocation time and guards every
/// optional so a stale or empty pasteboard can never trap.
@MainActor
enum CopyActions {
    static func actions(for content: CopyContent) -> [CopyAction] {
        switch content {
        case .link:
            return linkActions()
        case .files(_, let count):
            return fileActions(count: count)
        case .image:
            return imageActions()
        case .color(let hex):
            return colorActions(hex: hex)
        case .text:
            return textActions()
        case .concealed:
            // Never act on secrets.
            return []
        }
    }

    // MARK: - Link

    private static func linkActions() -> [CopyAction] {
        [
            CopyAction(title: "Open Link", systemImage: "safari") {
                guard let string = NSPasteboard.general.string(forType: .string),
                      let url = URL(string: string.trimmingCharacters(in: .whitespacesAndNewlines))
                else { return }
                NSWorkspace.shared.open(url)
            },
            CopyAction(title: "Copy as Plain Text", systemImage: "textformat") {
                guard let string = NSPasteboard.general.string(forType: .string) else { return }
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                pasteboard.setString(string, forType: .string)
            }
        ]
    }

    // MARK: - Files

    private static func fileActions(count: Int) -> [CopyAction] {
        var actions: [CopyAction] = [
            CopyAction(title: "Reveal in Finder", systemImage: "folder") {
                let urls = fileURLs()
                guard !urls.isEmpty else { return }
                NSWorkspace.shared.activateFileViewerSelecting(urls)
            }
        ]
        if count == 1 {
            actions.append(
                CopyAction(title: "Open", systemImage: "arrow.up.forward.app") {
                    guard let first = fileURLs().first else { return }
                    NSWorkspace.shared.open(first)
                }
            )
        }
        return actions
    }

    private static func fileURLs() -> [URL] {
        let options: [NSPasteboard.ReadingOptionKey: Any] = [.urlReadingFileURLsOnly: true]
        let objects = NSPasteboard.general.readObjects(forClasses: [NSURL.self], options: options)
        guard let urls = objects as? [URL] else { return [] }
        return urls
    }

    // MARK: - Image

    private static func imageActions() -> [CopyAction] {
        [
            CopyAction(title: "Save to Downloads", systemImage: "square.and.arrow.down") {
                guard let image = NSImage(pasteboard: NSPasteboard.general) else { return }
                guard let tiff = image.tiffRepresentation,
                      let rep = NSBitmapImageRep(data: tiff),
                      let png = rep.representation(using: .png, properties: [:])
                else { return }

                let downloads = FileManager.default.urls(
                    for: .downloadsDirectory, in: .userDomainMask
                ).first
                guard let directory = downloads else { return }

                let timestamp = Int(Date().timeIntervalSince1970)
                let destination = directory.appendingPathComponent("Copied-\(timestamp).png")

                do {
                    try png.write(to: destination)
                } catch {
                    // Avoid crashing if the write fails (e.g. sandbox denial).
                    return
                }
                NSWorkspace.shared.activateFileViewerSelecting([destination])
            }
        ]
    }

    // MARK: - Color

    private static func colorActions(hex: String) -> [CopyAction] {
        return [
            CopyAction(title: "Copy RGB", systemImage: "number") {
                guard let rgb = parseRGB(hex: hex) else { return }
                let value = "rgb(\(rgb.r), \(rgb.g), \(rgb.b))"
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                pasteboard.setString(value, forType: .string)
            },
            CopyAction(title: "Copy HSL", systemImage: "number") {
                guard let rgb = parseRGB(hex: hex) else { return }
                let hsl = rgbToHSL(r: rgb.r, g: rgb.g, b: rgb.b)
                let value = "hsl(\(hsl.h)\u{00B0}, \(hsl.s)%, \(hsl.l)%)"
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                pasteboard.setString(value, forType: .string)
            }
        ]
    }

    /// Parses a `#RGB`, `#RRGGBB`, or `#RRGGBBAA` style hex string into 0...255
    /// integer components. Returns `nil` for anything unparseable.
    private static func parseRGB(hex: String) -> (r: Int, g: Int, b: Int)? {
        var cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("#") {
            cleaned.removeFirst()
        }
        cleaned = cleaned.uppercased()

        // Expand shorthand #RGB -> #RRGGBB.
        if cleaned.count == 3 {
            cleaned = cleaned.map { "\($0)\($0)" }.joined()
        }

        // Accept RRGGBB (6) and RRGGBBAA (8); ignore alpha.
        guard cleaned.count == 6 || cleaned.count == 8 else { return nil }
        let rgbPart = String(cleaned.prefix(6))

        guard let value = UInt32(rgbPart, radix: 16) else { return nil }
        let r = Int((value >> 16) & 0xFF)
        let g = Int((value >> 8) & 0xFF)
        let b = Int(value & 0xFF)
        return (r, g, b)
    }

    /// Converts 0...255 RGB to integer-rounded HSL (h in degrees, s/l in percent).
    private static func rgbToHSL(r: Int, g: Int, b: Int) -> (h: Int, s: Int, l: Int) {
        let rf = Double(r) / 255.0
        let gf = Double(g) / 255.0
        let bf = Double(b) / 255.0

        let maxVal = max(rf, gf, bf)
        let minVal = min(rf, gf, bf)
        let delta = maxVal - minVal

        let lightness = (maxVal + minVal) / 2.0

        var hue = 0.0
        var saturation = 0.0

        if delta != 0 {
            saturation = delta / (1.0 - abs(2.0 * lightness - 1.0))

            if maxVal == rf {
                hue = ((gf - bf) / delta).truncatingRemainder(dividingBy: 6.0)
            } else if maxVal == gf {
                hue = ((bf - rf) / delta) + 2.0
            } else {
                hue = ((rf - gf) / delta) + 4.0
            }
            hue *= 60.0
            if hue < 0 { hue += 360.0 }
        }

        return (
            h: Int(hue.rounded()),
            s: Int((saturation * 100.0).rounded()),
            l: Int((lightness * 100.0).rounded())
        )
    }

    // MARK: - Text

    private static func textActions() -> [CopyAction] {
        [
            CopyAction(title: "Copy as Plain Text", systemImage: "textformat") {
                guard let string = NSPasteboard.general.string(forType: .string) else { return }
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                pasteboard.setString(string, forType: .string)
            }
        ]
    }
}
