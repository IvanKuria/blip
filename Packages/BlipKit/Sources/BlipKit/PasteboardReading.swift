import Foundation

/// The single seam over the system pasteboard, so the classifier and watcher can
/// be unit-tested against a fake instead of `NSPasteboard.general`.
public protocol PasteboardReading {
    /// Monotonically increasing counter the system bumps on every change.
    var changeCount: Int { get }
    /// Type identifiers currently available on the pasteboard.
    func availableTypes() -> [String]
    func string(forType type: String) -> String?
    func data(forType type: String) -> Data?
    /// File names (last path components) if file URLs are present.
    func fileNames() -> [String]
}

/// De-facto-standard and system pasteboard type identifiers Blip cares about.
public enum PBType {
    /// Set by password managers; contents must be treated as secret.
    public static let concealed = "org.nspasteboard.ConcealedType"
    /// Set for transient/automation copies that shouldn't be surfaced.
    public static let transient = "org.nspasteboard.TransientType"
    public static let string = "public.utf8-plain-text"
    public static let fileURL = "public.file-url"
    public static let png = "public.png"
    public static let tiff = "public.tiff"
}
