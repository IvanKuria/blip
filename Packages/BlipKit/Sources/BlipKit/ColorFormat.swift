import Foundation

/// Formats a hex color string into `rgb(...)` / `hsl(...)` notations.
/// Accepts `#RRGGBB`, `RRGGBB`, `#RGB`, `RGB`. Returns nil for invalid input.
public enum ColorFormat {
    public static func rgb(hex: String) -> String? {
        guard let (r, g, b) = components(hex: hex) else { return nil }
        return "rgb(\(r), \(g), \(b))"
    }

    public static func hsl(hex: String) -> String? {
        guard let (r, g, b) = components(hex: hex) else { return nil }

        let rf = Double(r) / 255.0
        let gf = Double(g) / 255.0
        let bf = Double(b) / 255.0

        let maxV = max(rf, gf, bf)
        let minV = min(rf, gf, bf)
        let delta = maxV - minV

        let l = (maxV + minV) / 2.0

        var h = 0.0
        var s = 0.0

        if delta != 0 {
            s = delta / (1.0 - abs(2.0 * l - 1.0))

            if maxV == rf {
                h = ((gf - bf) / delta).truncatingRemainder(dividingBy: 6.0)
            } else if maxV == gf {
                h = (bf - rf) / delta + 2.0
            } else {
                h = (rf - gf) / delta + 4.0
            }
            h *= 60.0
            if h < 0 { h += 360.0 }
        }

        let hi = Int(h.rounded())
        let si = Int((s * 100.0).rounded())
        let li = Int((l * 100.0).rounded())
        return "hsl(\(hi)°, \(si)%, \(li)%)"
    }

    // MARK: - Helpers

    /// Normalizes hex like the classifier and returns the (R, G, B) byte components.
    private static func components(hex: String) -> (Int, Int, Int)? {
        let body = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        guard body.allSatisfy({ $0.isHexDigit }),
              body.count == 3 || body.count == 6 else {
            return nil
        }
        let expanded = body.count == 3 ? body.map { "\($0)\($0)" }.joined() : body
        let chars = Array(expanded)
        guard let r = Int(String(chars[0...1]), radix: 16),
              let g = Int(String(chars[2...3]), radix: 16),
              let b = Int(String(chars[4...5]), radix: 16) else {
            return nil
        }
        return (r, g, b)
    }
}
