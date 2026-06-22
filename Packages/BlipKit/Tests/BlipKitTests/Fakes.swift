import Foundation
@testable import BlipKit

/// In-memory `PasteboardReading` for tests - set whatever the system pasteboard
/// would expose and assert on classification/watching.
final class FakePasteboard: PasteboardReading {
    var changeCount: Int
    var types: [String]
    var strings: [String: String]
    var datas: [String: Data]
    var names: [String]

    init(
        changeCount: Int = 0,
        types: [String] = [],
        strings: [String: String] = [:],
        datas: [String: Data] = [:],
        names: [String] = []
    ) {
        self.changeCount = changeCount
        self.types = types
        self.strings = strings
        self.datas = datas
        self.names = names
    }

    func availableTypes() -> [String] { types }
    func string(forType type: String) -> String? { strings[type] }
    func data(forType type: String) -> Data? { datas[type] }
    func fileNames() -> [String] { names }
}
