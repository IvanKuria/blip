import XCTest
@testable import BlipKit

final class ModelTests: XCTestCase {
    func testFakePasteboardExposesValues() {
        let pb = FakePasteboard(changeCount: 3, types: [PBType.string], strings: [PBType.string: "hi"])
        XCTAssertEqual(pb.changeCount, 3)
        XCTAssertEqual(pb.availableTypes(), [PBType.string])
        XCTAssertEqual(pb.string(forType: PBType.string), "hi")
    }

    func testCopyContentEquatable() {
        XCTAssertEqual(CopyContent.concealed, CopyContent.concealed)
        XCTAssertEqual(CopyContent.color(hex: "#FFFFFF"), CopyContent.color(hex: "#FFFFFF"))
        XCTAssertNotEqual(CopyContent.text(characters: 1, preview: "a"),
                          CopyContent.text(characters: 2, preview: "a"))
    }
}
