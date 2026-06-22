<h1 align="center">Blip</h1>

<p align="center"><em>Cmd+C, finally with a moment.</em></p>

<p align="center">
  A tiny, native macOS app that confirms every copy in your notch — and tells you
  <em>what</em> you grabbed. The acknowledgement macOS never gave you.
</p>

---

## Why

You press Cmd+C and macOS shows you… nothing. So you re-copy "just in case." **Blip** gives that moment a beautiful, content-aware confirmation right in the notch (a soft pill on non-notch Macs):

- **Text** → "Copied" + a preview (or character count)
- **A color** (`#3DD4FF`) → a swatch + the hex
- **An image** → dimensions + size
- **File(s)** → name (or "N items")
- **A link** → "Copied link" + the domain
- **A password** (from your password manager) → "Copied · hidden" — never the value

It is **not** a clipboard manager — no history, no list. Just a momentary, delightful "got it," then it retracts.

## Private by design

- **100% local. No network, ever.** (There's intentionally no network entitlement.)
- **No clipboard history or storage** — each copy is shown and discarded.
- Honors the `org.nspasteboard.ConcealedType` flag, so password-manager copies show "hidden."

## Settings

Launch at login, on-screen duration, optional sound, text-preview toggle — all in a small native window (⌘,).

## Install

**Homebrew** (after first release):
```bash
brew install --cask IvanKuria/blip/blip   # tap + cask
```

**Or build from source:**
```bash
brew install xcodegen
xcodegen generate
open Blip.xcodeproj   # ⌘R
```

## How it's built

- `BlipKit` — a pure, unit-tested Swift package (pasteboard abstraction, content classifier, change watcher). No UI, no network. 15 tests.
- `Blip` — a thin SwiftUI/AppKit menu-bar app rendering the notch pill (`NSPanel`, system materials, SF Pro, SF Symbols, springs, Reduce-Motion aware).

## License

[MIT](LICENSE) © 2026 Ivan Kuria
