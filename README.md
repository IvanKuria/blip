<h1 align="center">Blip</h1>

<p align="center"><em>Cmd+C, finally with a moment.</em></p>

<p align="center">
  A tiny, native macOS app that confirms every copy in your notch — and tells you
  <em>what</em> you grabbed. The acknowledgement macOS never gave you.
</p>

---

> 🚧 Early development.

## Why

You press Cmd+C and macOS shows you… nothing. So you re-copy "just in case." **Blip** gives that moment a beautiful, content-aware confirmation right in the notch (a soft pill on non-notch Macs): copy text → "Copied · 142 characters"; copy a color → a swatch + hex; copy an image → a thumbnail; copy a file → its icon and name.

It is **not** a clipboard manager — no history, no list. Just a momentary, delightful "got it."

## Private by design

- 100% local. **No network, ever.** No clipboard history or storage.
- Respects the `org.nspasteboard.ConcealedType` flag, so a password-manager copy shows "Copied · hidden" — never the value.

## Building from source

```bash
brew install xcodegen
xcodegen generate
open Blip.xcodeproj
```

## License

[MIT](LICENSE) © 2026 Ivan Kuria
