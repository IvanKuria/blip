import XCTest
@testable import BlipKit

final class SmokeTests: XCTestCase {
    func testVersionExposed() {
        XCTAssertFalse(BlipKit.version.isEmpty)
    }
}
