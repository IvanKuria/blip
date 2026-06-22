import XCTest
@testable import BlipKit

final class ClipboardWatcherTests: XCTestCase {
    private let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)

    func testEmitsOnceOnChange() {
        let pb = FakePasteboard(changeCount: 0)
        let watcher = ClipboardWatcher(pasteboard: pb, now: { self.fixedDate })
        var events: [CopyEvent] = []
        watcher.onEvent = { events.append($0) }

        pb.changeCount = 1
        pb.types = [PBType.string]
        pb.strings = [PBType.string: "hello"]
        watcher.poll()

        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?.content, .text(characters: 5, preview: "hello"))
        XCTAssertEqual(events.first?.date, fixedDate)
    }

    func testNoEmitWhenChangeCountUnchanged() {
        let pb = FakePasteboard(changeCount: 5, types: [PBType.string], strings: [PBType.string: "x"])
        let watcher = ClipboardWatcher(pasteboard: pb, now: { self.fixedDate })
        var count = 0
        watcher.onEvent = { _ in count += 1 }

        watcher.poll()   // changeCount went 5 (init) -> still 5? init captures current, so no change
        watcher.poll()
        XCTAssertEqual(count, 0, "no change since init -> no events")
    }

    func testTransientAdvancesCountButEmitsNothing() {
        let pb = FakePasteboard(changeCount: 0)
        let watcher = ClipboardWatcher(pasteboard: pb, now: { self.fixedDate })
        var count = 0
        watcher.onEvent = { _ in count += 1 }

        pb.changeCount = 1
        pb.types = [PBType.transient, PBType.string]
        pb.strings = [PBType.string: "automation"]
        watcher.poll()

        XCTAssertEqual(count, 0)
    }

    func testConcealedEmitsHidden() {
        let pb = FakePasteboard(changeCount: 0)
        let watcher = ClipboardWatcher(pasteboard: pb, now: { self.fixedDate })
        var events: [CopyEvent] = []
        watcher.onEvent = { events.append($0) }

        pb.changeCount = 9
        pb.types = [PBType.concealed]
        watcher.poll()

        XCTAssertEqual(events.map(\.content), [.concealed])
    }
}
