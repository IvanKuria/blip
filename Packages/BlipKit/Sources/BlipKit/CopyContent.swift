import Foundation

/// What the user just copied, classified for display. Carries only what the pill
/// needs to render - never the raw secret value for concealed copies.
public enum CopyContent: Equatable, Sendable {
    case text(characters: Int, words: Int, preview: String)
    case color(hex: String)
    case image(pixelWidth: Int, pixelHeight: Int, byteCount: Int)
    case files(names: [String], count: Int)
    case link(domain: String)
    case concealed
}

/// A single copy, ready to show.
public struct CopyEvent: Equatable, Sendable {
    public let content: CopyContent
    public let date: Date

    public init(content: CopyContent, date: Date) {
        self.content = content
        self.date = date
    }
}
