import SwiftUI

/// Design tokens. Apple-grade: system materials, SF Pro, semantic colors,
/// a single system-style spring.
enum Theme {
    static let pillCornerRadius: CGFloat = 26
    static let panelSize = CGSize(width: 620, height: 260)

    static let spring = Animation.spring(response: 0.42, dampingFraction: 0.8)

    static let check = Color(nsColor: .systemGreen)
    static let title = Color(nsColor: .labelColor)
    static let subtitle = Color(nsColor: .secondaryLabelColor)
}

extension Color {
    /// Build a color from a `#RRGGBB` string for the copied-color swatch.
    init(hexString: String) {
        let body = hexString.hasPrefix("#") ? String(hexString.dropFirst()) : hexString
        var value: UInt64 = 0
        Scanner(string: body).scanHexInt64(&value)
        self = Color(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }
}
