# Blip Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship a tiny, Apple-grade macOS menu-bar app that confirms every Cmd+C in the notch, content-aware (text/color/image/files/link/concealed), local-only.

**Architecture:** A pure, unit-tested `BlipKit` SPM package (pasteboard abstraction, content classifier, change watcher - no UI, no network) consumed by a thin `Blip` AppKit/SwiftUI menu-bar app that renders a notch-anchored pill with native materials, SF Pro, SF Symbols, and system springs.

**Tech Stack:** Swift 6 / Xcode 26, SwiftUI + AppKit, XcodeGen, ImageIO (image dimensions), SMAppService (login item). No third-party deps. No network.

## Global Constraints

- **Platform:** macOS 14+ deployment target; native Swift only.
- **Name/bundle:** app name **Blip**, bundle id `com.ivankuria.blip`.
- **Privacy:** local-only; NO network anywhere; NO clipboard history/persistence; honor `org.nspasteboard.ConcealedType` (show "hidden"); ignore `org.nspasteboard.TransientType`.
- **Design bar:** Apple-grade - SF Pro, tabular figures, SF Symbols, `NSVisualEffectView` materials, semantic system colors, system spring animation, light/dark adaptive, honor Reduce Motion + Reduce Transparency.
- **Two-target split:** all testable logic in `BlipKit` (Foundation/ImageIO only, no AppKit UI); macOS glue in `Blip`.
- **Signing:** dev = ad-hoc ("sign to run locally"); release = Developer ID "Ivan Kuria" (team 347LA37C2B) + notarization (M3).
- **Repo:** local git in `~/Documents/Blip`; GitHub remote optional.

---

## File Structure

```
Blip/
  project.yml                         # XcodeGen
  .gitignore  LICENSE  README.md
  Packages/BlipKit/
    Package.swift
    Sources/BlipKit/
      PasteboardReading.swift         # protocol abstracting NSPasteboard
      CopyContent.swift               # CopyContent enum + CopyEvent
      ClipboardClassifier.swift       # reading -> CopyContent? (pure)
      ClipboardWatcher.swift          # changeCount polling -> CopyEvent stream
    Tests/BlipKitTests/
      Fakes.swift                     # FakePasteboard, fixtures
      ClipboardClassifierTests.swift
      ClipboardWatcherTests.swift
  Blip/
    App/BlipApp.swift                 # @main, menu-bar accessory, composition root
    App/MenuBarController.swift       # NSStatusItem + menu
    App/SystemPasteboard.swift        # PasteboardReading via NSPasteboard.general
    App/LoginItem.swift               # SMAppService wrapper
    UI/Theme.swift                    # tokens (fonts, spacing, motion)
    UI/NotchGeometry.swift            # notch frame vs top-center fallback
    UI/NotchPanel.swift               # borderless non-activating NSPanel
    UI/NotchController.swift          # expand/hold/retract + debounce
    UI/BlipView.swift                 # SwiftUI content-adaptive pill
    UI/Settings.swift                 # SwiftUI settings + @AppStorage prefs
    Resources/Assets.xcassets         # AppIcon, accent
    Resources/Blip.entitlements       # app sandbox (NO network entitlement)
  scripts/build-dmg.sh
  docs/superpowers/...
```

---

# Milestone 1 - BlipKit core (fully testable)

### Task 1: Scaffold, git, build-green

**Files:** Create `Packages/BlipKit/Package.swift`, `Packages/BlipKit/Sources/BlipKit/BlipKit.swift` (stub), `Packages/BlipKit/Tests/BlipKitTests/SmokeTests.swift`, `project.yml`, `Blip/App/BlipApp.swift` (minimal `MenuBarExtra` or accessory stub), `Blip/Resources/Blip.entitlements`, `.gitignore`, `LICENSE` (MIT, Ivan Kuria 2026), `README.md` (stub).

**Interfaces:** Produces a buildable empty menu-bar app + importable `BlipKit`.

- [ ] **Step 1:** `Package.swift` - library `BlipKit`, platform `.macOS(.v14)`, swift-tools 6.0, a target + test target (no external deps).
- [ ] **Step 2:** `project.yml` - app target `Blip`, macOS 14, `INFOPLIST_KEY_LSUIElement: YES`, local package dep on `Packages/BlipKit`, `GENERATE_INFOPLIST_FILE: YES`, bundle id `com.ivankuria.blip`, `CODE_SIGN_STYLE: Manual`, `CODE_SIGN_IDENTITY: "-"`, entitlements path, `ENABLE_HARDENED_RUNTIME: YES`, `SWIFT_VERSION: 6.0`.
- [ ] **Step 3:** `BlipApp.swift` - `@main struct BlipApp: App { var body: some Scene { MenuBarExtra("Blip", systemImage: "checkmark.circle") { Button("Quit") { NSApp.terminate(nil) } } } }`. Entitlements: `com.apple.security.app-sandbox = true` only (no network).
- [ ] **Step 4:** `.gitignore` (`.build/`, `*.xcodeproj`, `DerivedData/`, `.DS_Store`, `*.dmg`), MIT LICENSE, README stub. `BlipKit.swift`: `public enum BlipKit { public static let version = "0.1.0" }`. `SmokeTests.swift`: assert version non-empty.
- [ ] **Step 5:** Run `xcodegen generate` then `swift test` in `Packages/BlipKit` (PASS) and `xcodebuild -scheme Blip -destination 'platform=macOS' build` (BUILD SUCCEEDED).
- [ ] **Step 6 (commit):**
```bash
cd ~/Documents/Blip && git init -b main
git add -A && git commit -m "chore: scaffold Blip menu-bar app + BlipKit package"
```

---

### Task 2: PasteboardReading + CopyContent model

**Files:** Create `PasteboardReading.swift`, `CopyContent.swift`; Test `Fakes.swift`.

**Interfaces:**
- Produces:
  - `protocol PasteboardReading { var changeCount: Int { get }; func availableTypes() -> [String]; func string(forType type: String) -> String?; func data(forType type: String) -> Data?; func fileNames() -> [String] }`
  - `enum CopyContent: Equatable, Sendable { case text(characters: Int, preview: String); case color(hex: String); case image(pixelWidth: Int, pixelHeight: Int, byteCount: Int); case files(names: [String], count: Int); case link(domain: String); case concealed }`
  - `struct CopyEvent: Equatable, Sendable { let content: CopyContent; let date: Date }`
  - Type-id constants: `enum PBType { static let concealed = "org.nspasteboard.ConcealedType"; static let transient = "org.nspasteboard.TransientType"; static let string = "public.utf8-plain-text"; static let fileURL = "public.file-url"; static let png = "public.png"; static let tiff = "public.tiff" }`
  - In `Fakes.swift`: `final class FakePasteboard: PasteboardReading` with settable `changeCount`, `types`, `strings: [String:String]`, `datas: [String:Data]`, `names: [String]`.

- [ ] **Step 1: Write a compile/sanity test** in `Fakes.swift` usage (a trivial test constructing `FakePasteboard` and `CopyContent.concealed`, asserting equality).
- [ ] **Step 2:** `swift test` → FAIL (types undefined).
- [ ] **Step 3:** Implement the protocol, enum, struct, constants, and `FakePasteboard`.
- [ ] **Step 4:** `swift test` → PASS.
- [ ] **Step 5: commit** `feat(blipkit): pasteboard abstraction + CopyContent model`.

---

### Task 3: ClipboardClassifier

**Files:** Create `ClipboardClassifier.swift`; Test `ClipboardClassifierTests.swift`.

**Interfaces:**
- Consumes: `PasteboardReading`, `CopyContent`, `PBType`.
- Produces: `enum ClipboardClassifier { static func classify(_ pb: PasteboardReading) -> CopyContent? }`
  - Precedence: if `availableTypes()` contains `PBType.transient` → return `nil` (ignore). If contains `PBType.concealed` → `.concealed`. Else if `fileNames()` non-empty → `.files(names:count:)`. Else if an image type (`png`/`tiff`) present → decode dimensions via ImageIO (`CGImageSourceCreateWithData`) → `.image(...)` with `byteCount = data.count`. Else if string present and is a hex color → `.color(hex:)` (normalize to uppercase `#RRGGBB`). Else if string present and parses as http/https URL → `.link(domain:)`. Else if string present → `.text(characters:, preview:)` where preview = first 40 chars single-lined, trimmed. Else `nil`.
  - Hex detection regex: `^#?([0-9a-fA-F]{6}|[0-9a-fA-F]{3})$` on trimmed string.

- [ ] **Step 1: Write failing tests** covering: transient→nil; concealed→.concealed; file names→.files; png data→.image with correct WxH (use a tiny known PNG fixture built in-test via a 2x2 bytes or a base64 constant); `#3DD4FF`→.color("#3DD4FF"); `3dd4ff`→.color("#3DD4FF"); `https://apple.com/x`→.link("apple.com"); `"hello world ..."`→.text(characters: N, preview:...); empty→nil.
- [ ] **Step 2:** `swift test --filter ClipboardClassifierTests` → FAIL.
- [ ] **Step 3:** Implement `classify` per precedence above (ImageIO import for dimensions; URLComponents for domain; regex for hex).
- [ ] **Step 4:** run → PASS.
- [ ] **Step 5: commit** `feat(blipkit): content-aware clipboard classifier`.

---

### Task 4: ClipboardWatcher

**Files:** Create `ClipboardWatcher.swift`; Test `ClipboardWatcherTests.swift`.

**Interfaces:**
- Consumes: `PasteboardReading`, `ClipboardClassifier`, `CopyEvent`.
- Produces:
  - `final class ClipboardWatcher { init(pasteboard: PasteboardReading, now: @escaping () -> Date = Date.init); var onEvent: ((CopyEvent) -> Void)?; func poll() }`
  - `poll()` reads `changeCount`; if unchanged since last poll → do nothing; if changed → classify; if classify returns non-nil → call `onEvent(CopyEvent(content:, date: now()))`; always update stored changeCount. (Transient → classify nil → no event, but changeCount still advances.)
  - (The app drives `poll()` on a 0.25s timer; the timer itself is app-side, not tested here.)

- [ ] **Step 1: Write failing tests:** (a) first `poll()` with a changed count + text emits exactly one event; (b) calling `poll()` again with same changeCount emits nothing; (c) changeCount advances but content is transient → no event; (d) concealed → emits `.concealed` event. Use `FakePasteboard` + a fixed `now`.
- [ ] **Step 2:** run → FAIL.
- [ ] **Step 3:** implement watcher (store `lastChangeCount`, init to pasteboard's current so the first real change triggers; guard unchanged).
- [ ] **Step 4:** run → PASS.
- [ ] **Step 5: commit** `feat(blipkit): clipboard change watcher`. **M1 done - run full `swift test` (all green).**

---

# Milestone 2 - App UI (Apple-grade, run-verified)

> Verified by building + launching and observing. Each ends in a commit.

### Task 5: SystemPasteboard + menu bar + composition
**Files:** Create `App/SystemPasteboard.swift`, `App/MenuBarController.swift`; modify `App/BlipApp.swift`.
- `SystemPasteboard: PasteboardReading` wrapping `NSPasteboard.general` (map `availableTypes`, `string(forType:)`, `data(forType:)`, `fileNames()` via `readObjects([NSURL])`).
- App becomes `.accessory`; `MenuBarController` builds the `NSStatusItem` (SF Symbol `checkmark.circle`), menu (Enabled toggle, Settings…, Quit). A 0.25s `Timer` calls `watcher.poll()`.
- **Verify:** launch → menu-bar icon present; console logs a CopyEvent when you copy text. Commit.

### Task 6: NotchGeometry + NotchPanel
**Files:** Create `UI/NotchGeometry.swift`, `UI/NotchPanel.swift`.
- `NotchGeometry.pillFrame(on: NSScreen, expandedSize:) -> NSRect` - if the screen has a notch (`safeAreaInsets.top > 0` / `auxiliaryTopLeftArea`), center on the notch; else top-center of the screen, just under the menu bar.
- `NotchPanel: NSPanel` - borderless, `.nonactivatingPanel`, `level = .statusBar`, `collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]`, `isOpaque=false`, clear background, `ignoresMouseEvents=true`, `hasShadow=false`. Hosts an `NSHostingView`.
- **Verify:** a temporary call shows an empty pill at the notch on the built-in display and top-center on an external display. Commit.

### Task 7: Theme + BlipView (content-adaptive pill)
**Files:** Create `UI/Theme.swift`, `UI/BlipView.swift`.
- `Theme`: SF Pro fonts (tabular for counts), spacing, the spring (`.spring(response:0.34, dampingFraction:0.82)`), corner radius matching the notch.
- `BlipView(content: CopyContent)`: leading `checkmark.circle.fill` (green, SF Symbol), a content chip (swatch / `NSImage` thumbnail / `NSWorkspace` file icon / link glyph), title "Copied"/"Copied link", subtitle per type (tabular figures), true-black notch body via material; adapts light/dark.
- **Verify:** preview each `CopyContent` case (drive via temporary buttons or `#Preview`); all read as native. Commit.

### Task 8: NotchController (animation + debounce) wired live
**Files:** Create `UI/NotchController.swift`; wire into composition.
- `show(_ event: CopyEvent)`: place/resize panel via `NotchGeometry`, set `BlipView`, animate expand (spring), hold (configurable, default 1.2s), retract; coalesce rapid copies (cancel pending hide, replace content). Hover keeps open (toggle `ignoresMouseEvents`). Honors Reduce Motion (cross-fade, no spring).
- Connect `watcher.onEvent = { controller.show($0) }`.
- **Verify:** copy text/color/image/file → correct pill animates in your notch and retracts; rapid copies coalesce. Commit. **Push/checkpoint.**

### Task 9: Settings + login item + prefs
**Files:** Create `UI/Settings.swift`, `App/LoginItem.swift`.
- `@AppStorage` prefs: enabled, durationSeconds, position (auto/notch/top), soundEnabled, showPreview. `Settings` SwiftUI scene (native form). `LoginItem` via `SMAppService.mainApp` register/unregister. Wire prefs into watcher/controller (enabled gates polling; duration/position/preview affect display; sound plays a subtle `NSSound` on show if enabled).
- **Verify:** toggle each setting; login item appears in System Settings > General > Login Items; concealed copy shows "hidden". Commit.

### Task 10: Accessibility + polish pass
**Files:** across UI.
- Reduce Motion + Reduce Transparency paths; light/dark; precise notch radius/inset; subtle sound; empty/permission-free states; record hero GIF here (color/image/file blips).
- **Verify:** flip Reduce Motion/Transparency + light/dark; confirm Apple-grade feel. Commit. **Push.**

---

# Milestone 3 - Icon, README, packaging

### Task 11: App icon
**Files:** `Blip/Resources/Assets.xcassets/AppIcon.appiconset` + `scripts/make-icon.sh`.
- A premium, Apple-style icon (a clipboard/checkmark or a notch-pill mark; dark + accent). All macOS sizes + Contents.json (reproducible script).
- **Verify:** icon in built app + Finder. Commit.

### Task 12: README + hero GIF
**Files:** `README.md`.
- One-line pitch, hero GIF, feature bullets, privacy section (local-only, concealed-type respected), install (Homebrew + DMG), build-from-source, license.
- **Verify:** renders on GitHub. Commit.

### Task 13: DMG + notarization + Homebrew
**Files:** `scripts/build-dmg.sh`, cask file.
- Archive Release, sign with **Developer ID Application: Ivan Kuria (347LA37C2B)** + hardened runtime, `notarytool` submit + staple, package DMG; draft Homebrew cask.
- **Verify:** `spctl -a -vv Blip.app` → accepted/Notarized; clean-Gatekeeper open. Commit. **Push, tag release.**

---

## Self-Review (done)

- **Spec coverage:** classifier across all content types (T3), watcher w/ concealed+transient (T4), notch pill + geometry/fallback (T6–T8), Apple-grade design + Reduce-Motion/Transparency + light/dark (T7,T10), settings + login item + privacy (T9), local-only/no-network (entitlements T1, no net code anywhere), icon/README/notarized DMG/Homebrew (T11–T13). ✓
- **Placeholders:** none - core tasks have concrete tests + interfaces; UI tasks specify files + manual verification (appropriate). ✓
- **Type consistency:** `PasteboardReading`, `CopyContent`, `CopyEvent`, `ClipboardClassifier.classify`, `ClipboardWatcher`, `PBType` used consistently across tasks. ✓
