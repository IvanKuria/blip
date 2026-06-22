import XCTest
@testable import BlipKit

final class ColorFormatTests: XCTestCase {
    func testRGBExample() {
        XCTAssertEqual(ColorFormat.rgb(hex: "#3DD4FF"), "rgb(61, 212, 255)")
    }

    func testPureRed() {
        XCTAssertEqual(ColorFormat.rgb(hex: "#FF0000"), "rgb(255, 0, 0)")
        XCTAssertEqual(ColorFormat.hsl(hex: "#FF0000"), "hsl(0°, 100%, 50%)")
    }

    func testWhite() {
        XCTAssertEqual(ColorFormat.hsl(hex: "#FFFFFF"), "hsl(0°, 0%, 100%)")
    }

    func testThreeDigit() {
        XCTAssertEqual(ColorFormat.rgb(hex: "#0F0"), "rgb(0, 255, 0)")
        XCTAssertEqual(ColorFormat.hsl(hex: "#0F0"), "hsl(120°, 100%, 50%)")
    }

    func testInvalid() {
        XCTAssertNil(ColorFormat.rgb(hex: "xyz"))
        XCTAssertNil(ColorFormat.hsl(hex: "xyz"))
    }
}
