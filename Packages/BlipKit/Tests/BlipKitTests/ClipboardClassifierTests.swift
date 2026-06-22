import XCTest
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
@testable import BlipKit

final class ClipboardClassifierTests: XCTestCase {

    /// Build a real PNG of known dimensions so the ImageIO path is exercised.
    private func makePNG(width: Int, height: Int) -> Data {
        let ctx = CGContext(
            data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        ctx.setFillColor(CGColor(red: 1, green: 0, blue: 0, alpha: 1))
        ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
        let image = ctx.makeImage()!
        let data = NSMutableData()
        let dest = CGImageDestinationCreateWithData(data, UTType.png.identifier as CFString, 1, nil)!
        CGImageDestinationAddImage(dest, image, nil)
        CGImageDestinationFinalize(dest)
        return data as Data
    }

    func testTransientIsIgnored() {
        let pb = FakePasteboard(types: [PBType.transient, PBType.string], strings: [PBType.string: "x"])
        XCTAssertNil(ClipboardClassifier.classify(pb))
    }

    func testConcealedIsHidden() {
        let pb = FakePasteboard(types: [PBType.concealed, PBType.string], strings: [PBType.string: "hunter2"])
        XCTAssertEqual(ClipboardClassifier.classify(pb), .concealed)
    }

    func testFiles() {
        let pb = FakePasteboard(types: [PBType.fileURL], names: ["Report.pdf", "photo.jpg"])
        XCTAssertEqual(ClipboardClassifier.classify(pb), .files(names: ["Report.pdf", "photo.jpg"], count: 2))
    }

    func testImageDimensionsViaImageIO() {
        let png = makePNG(width: 3, height: 2)
        let pb = FakePasteboard(types: [PBType.png], datas: [PBType.png: png])
        XCTAssertEqual(ClipboardClassifier.classify(pb), .image(pixelWidth: 3, pixelHeight: 2, byteCount: png.count))
    }

    func testHexColorWithAndWithoutHash() {
        let a = FakePasteboard(types: [PBType.string], strings: [PBType.string: "#3DD4FF"])
        XCTAssertEqual(ClipboardClassifier.classify(a), .color(hex: "#3DD4FF"))
        let b = FakePasteboard(types: [PBType.string], strings: [PBType.string: "3dd4ff"])
        XCTAssertEqual(ClipboardClassifier.classify(b), .color(hex: "#3DD4FF"))
    }

    func testLinkDomain() {
        let pb = FakePasteboard(types: [PBType.string], strings: [PBType.string: "https://www.apple.com/mac/x?y=1"])
        XCTAssertEqual(ClipboardClassifier.classify(pb), .link(domain: "apple.com"))
    }

    func testPlainText() {
        let pb = FakePasteboard(types: [PBType.string], strings: [PBType.string: "  hello world  "])
        XCTAssertEqual(ClipboardClassifier.classify(pb), .text(characters: 11, preview: "hello world"))
    }

    func testEmptyIsNil() {
        XCTAssertNil(ClipboardClassifier.classify(FakePasteboard()))
    }
}
