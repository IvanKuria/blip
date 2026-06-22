# Contributing to Blip

Thanks for your interest in Blip. Issues and pull requests are welcome.

## Project layout

- **`Packages/BlipKit/`** is the pure, testable core: the pasteboard abstraction, the content classifier, color formatting, and the change watcher. No UI, no network.
- **`Blip/`** is the macOS app: the notch panel, the pill view, the menu bar, settings, and the controller that wires everything together.
- **`docs/superpowers/`** holds the design spec and the implementation plan.
- **`scripts/`** holds the icon generator and the release (DMG + notarization) script.

## Getting set up

You need Xcode 26 (or newer) and macOS 14+, plus XcodeGen.

```bash
brew install xcodegen
git clone https://github.com/IvanKuria/blip.git
cd blip
xcodegen generate
open Blip.xcodeproj
```

`Blip.xcodeproj` is generated, so it is not committed. Run `xcodegen generate` after pulling changes that touch `project.yml` or add files.

## Tests

All logic lives in `BlipKit` and is unit-tested. Keep it green:

```bash
cd Packages/BlipKit
swift test
```

If you change behavior in `BlipKit`, add or update a test. UI changes are verified by building and running the app and watching the pill.

## Pull requests

1. Branch from `main`.
2. Keep changes focused, and match the existing style (small files, one clear responsibility, SwiftUI plus AppKit conventions already in the tree).
3. Make sure `swift test` passes and the app builds:
   ```bash
   xcodebuild -project Blip.xcodeproj -scheme Blip -destination 'platform=macOS' build
   ```
4. For UI work, include a short before and after screenshot or clip.
5. Open the PR with a clear description of what changed and why.

## Principles

- **Private by design.** Blip is local-only. Do not add network calls, analytics, or clipboard persistence. Respect the `org.nspasteboard.ConcealedType` flag.
- **Native and minimal.** Prefer system materials, SF Pro, and SF Symbols. No heavy dependencies.
- **It is not a clipboard manager.** Keep the scope to confirming the current copy.

## License

By contributing, you agree that your contributions are licensed under the [MIT License](LICENSE).
