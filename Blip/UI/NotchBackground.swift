import SwiftUI

/// The black notch silhouette: flush top, rounded bottom corners, and small
/// *concave* fillets at the top-left/right so it flows out of the menu bar like
/// the real notch. (Technique adapted from Lakr233/NotchDrop, MIT.)
struct NotchBackground: View {
    var radius: CGFloat = 32       // matches NotchDrop's opened corner radius
    private let spacing: CGFloat = 16

    var body: some View {
        Rectangle()
            .fill(.black)
            .clipShape(.rect(bottomLeadingRadius: radius, bottomTrailingRadius: radius))
            .overlay(concave(topTrailing: true))   // carves the top-left fillet
            .overlay(concave(topTrailing: false))  // carves the top-right fillet
            .compositingGroup()
    }

    /// A black square with one top corner rounded out via destination-out, placed
    /// just outside a top corner to create the concave curve into the menu bar.
    private func concave(topTrailing: Bool) -> some View {
        ZStack(alignment: topTrailing ? .topTrailing : .topLeading) {
            Rectangle()
                .frame(width: radius, height: radius)
                .foregroundStyle(.black)
            Rectangle()
                .clipShape(topTrailing
                    ? .rect(topTrailingRadius: radius)
                    : .rect(topLeadingRadius: radius))
                .foregroundStyle(.white)
                .frame(width: radius + spacing, height: radius + spacing)
                .blendMode(.destinationOut)
        }
        .compositingGroup()
        .frame(
            maxWidth: .infinity, maxHeight: .infinity,
            alignment: topTrailing ? .topLeading : .topTrailing
        )
        .offset(
            x: topTrailing ? (-radius - spacing + 0.5) : (radius + spacing - 0.5),
            y: -0.5
        )
    }
}
