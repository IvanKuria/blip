# Blip — Design Spec

> A tiny, Apple-grade macOS app that gives **Cmd+C a moment**: copy anything and the notch briefly expands to confirm *what* you grabbed — then retracts. The acknowledgement macOS never gave you.

- **Status:** Design (pre-implementation)
- **Date:** 2026-06-22
- **Name:** Blip (rename-friendly)
- **Location:** `~/Documents/Blip`
- **Platform:** native Swift / SwiftUI + AppKit, macOS 14+

---

## Context

Copying on macOS gives **zero feedback** — you press Cmd+C and nothing happens visibly, so people re-copy "just in case." Blip fixes that overlooked, million-times-a-day moment in the spirit of *boring.notch*: it turns a wasted interaction into a small, delightful, useful confirmation anchored in the notch (a "soft pill" on non-notch displays).

It is **not** a clipboard manager (no history, no list). It is a momentary, content-aware acknowledgement. Verified-open: the only thing close is an off-by-default toast buried inside one clipboard manager; no dedicated app owns this.

**Intended outcome:** a free, beautifully native app with an instantly-demoable hook ("your Mac never told you Cmd+C worked — now it does"), architected so sibling "notch moments" (device-connect, charging) can be added later as an optional suite.

**Design bar:** must look and feel as if Apple made it — SF Pro, SF Symbols, system materials/vibrancy, semantic colors, light/dark adaptive, spring animation that matches the system, Retina-crisp, Reduce-Motion aware.

---

## Goals / Non-goals

**Goals**
- Show a content-aware "Copied" confirmation in the notch on every user copy.
- Adapt to content type: text, color, image, file(s), link.
- Feel indistinguishable from a native macOS affordance.
- Be privacy-trustworthy: local-only, no storage, no network, honor concealed-clipboard flags.
- Zero-config: launch, grant nothing scary, it just works. Minimal settings.

**Non-goals (v1)**
- No clipboard **history**/manager (that's a different, saturated category).
- No device-connect / charging moments yet (architected for; shipped later as the "Moments" suite).
- No iOS companion, no accounts, no cloud, no network of any kind.

---

## Users & the hook

- **Primary user:** any Mac user (writers, designers, developers, students) — copying is universal.
- **The shareable moment:** copy a color → a swatch + hex blips in the notch; copy an image → a thumbnail; copy 142 characters → "Copied · 142 characters." That 5-second clip is the video.

---

## Experience

### Surface
- **Menu-bar accessory** (`LSUIElement`, no Dock icon).
- The confirmation renders in a **borderless, non-activating panel** anchored to the notch:
  - **Notch Macs:** the pill visually *grows from* the physical notch (matched corner radius), then retracts.
  - **Non-notch displays:** a matching "soft pill" descends from top-center of the active display.
- Never steals focus; never blocks clicks (ignores mouse events except optional hover-to-hold).

### The moment (per copy)
1. User copies (Cmd+C or any app writing to the general pasteboard).
2. Pill expands (spring), content fades in: a green `checkmark.circle.fill`, a content chip, a title + subtitle.
3. Holds ~1.2s (configurable), then retracts (spring). Hovering keeps it open.

### Content adaptivity
| Copied | Title | Subtitle / chip |
|---|---|---|
| Plain text | "Copied" | "N characters" (tabular) + tiny truncated preview |
| A color (hex/`NSColor`) | "Copied" | hex string + a rounded **swatch** |
| Image | "Copied" | "image · W×H · size" + **thumbnail** |
| File(s) | "Copied" | file name (or "N items") + **`NSWorkspace` icon** |
| URL/link | "Copied link" | domain + link glyph |
| Concealed (password) | "Copied" | "hidden" — **never** the value |

### Settings (one small, native window)
- Launch at login (`SMAppService`).
- Enable/disable; display duration; position (Auto / Notch / Top-center); sound on/off; show-preview on/off.
- Privacy note shown inline. That's it — Apple-minimal.

---

## Design language (Apple-grade — first-class requirement)

- **Material:** `NSVisualEffectView` HUD/popover material; the notch body is true black to blend with the physical notch; vibrancy for text/glyphs.
- **Typography:** SF Pro; **tabular figures** for counts; title `.headline`, subtitle `.caption` in `secondaryLabelColor`.
- **Iconography:** SF Symbols only (`checkmark.circle.fill`, `doc.on.doc`, `photo`, `link`, `eyedropper.halffull`), rendered with hierarchical/again system rendering.
- **Color:** semantic system colors (`controlAccentColor`, `labelColor`, `secondaryLabelColor`); success green from the system palette. No hardcoded brand colors except content (e.g., the copied swatch).
- **Motion:** a single spring (`.snappy`-like, ~0.35 response) for expand/retract; content cross-fades; honor **Reduce Motion** (cross-fade only, no scale/spring) and **Reduce Transparency** (solid background).
- **Light/Dark:** fully adaptive. **Retina-crisp** at all scales.

---

## Architecture

Mirror the clean split used before: a pure, testable core package + a thin app target.

### `BlipKit` (pure Swift, no UI — unit-tested with fakes)
- `protocol PasteboardReading` — abstracts `NSPasteboard` (changeCount + typed reads) for testing.
- `ClipboardWatcher` — polls `changeCount` (~0.25s) via an injected clock + `PasteboardReading`; emits a `CopyEvent` only on real change; **drops transient/concealed appropriately**.
- `ClipboardClassifier` — pure function: pasteboard contents → `CopyContent` enum
  `.text(count:preview:) | .color(hex:) | .image(pixelSize:byteCount:) | .files([name],count:) | .link(domain:) | .concealed`.
  Detects concealed via `org.nspasteboard.ConcealedType`; ignores `org.nspasteboard.TransientType`; recognizes hex-color strings.
- `CopyEvent { content: CopyContent; date: Date }`.
- No storage, no network anywhere in the package.

### `Blip` (app target — macOS glue, Apple-grade UI)
- `AppDelegate` composition root: menu bar, watcher, notch controller, settings, login item.
- `NotchPanel` — borderless non-activating `NSPanel` at status/popUpMenu window level, `canJoinAllSpaces`, `ignoresMouseEvents` (toggled for hover). Computes notch frame (via `NSScreen.safeAreaInsets` / `auxiliaryTopLeftArea`) or top-center fallback.
- `NotchController` — owns the panel, drives expand/hold/retract animation, hosts SwiftUI `BlipView` for the content. Debounces rapid copies (coalesce).
- `BlipView` (SwiftUI) — renders the content-adaptive pill per the design language.
- `MenuBarController` — `NSStatusItem` (SF Symbol), menu: toggle, Settings…, Quit.
- `SettingsView` (SwiftUI) — the small native settings window.
- Thumbnail/icon rendering uses `NSWorkspace`/`NSImage` (no QuickLook needed for v1).

### Data flow
`ClipboardWatcher` (on change) → `ClipboardClassifier` → `CopyEvent` → `NotchController.show(event)` → `BlipView` renders → auto-retract.

---

## Privacy (load-bearing for trust + the YouTube comments)

- **Local-only. No network. No clipboard history/persistence** — events render and are discarded.
- Honor **`org.nspasteboard.ConcealedType`**: password-manager copies show "Copied · hidden", never the value.
- Ignore **`org.nspasteboard.TransientType`** (don't blip on app-internal transient copies).
- Reading `changeCount` needs **no permission/prompt**; reading contents needs none either but is treated with care (processed in-memory only).
- README + Settings state this plainly.

---

## Distribution (do it right)
- New local git repo in `~/Documents/Blip` (GitHub remote optional, on request).
- Developer ID **notarized** build (hardened runtime), DMG via a `scripts/build-dmg.sh`, Homebrew cask, README with the hero GIF (color/image/file blips), app icon.
- Dev builds: ad-hoc "sign to run locally"; real signing/notarization at the packaging milestone (Developer ID: Ivan Kuria, team 347LA37C2B).

---

## v1 scope (locked)

In: menu-bar app; clipboard watcher; content-aware classifier (text/color/image/files/link/concealed); notch pill (notch + soft-pill fallback) with Apple-grade design + animation; Reduce-Motion/Transparency + light/dark; minimal settings (login item, duration, position, sound, preview toggle); privacy guarantees; icon + README + notarized DMG + Homebrew.

Deferred (suite): device-connect moment, charging flourish, other "notch moments"; per-content actions; optional history.

---

## Risks & mitigations

| Risk | Mitigation |
|---|---|
| Notch frame geometry varies (models, external displays) | Detect via `NSScreen.safeAreaInsets`/`auxiliaryTopLeftArea`; clean top-center fallback; test on built-in + external |
| Polling cost | 0.25s timer, negligible; only act on `changeCount` delta |
| Showing sensitive copies | Honor ConcealedType; never store; in-memory only |
| Noisy/rapid copies | Debounce + coalesce in `NotchController` |
| "Looks cheap" | Apple-grade design language is a first-class spec section; system materials/SF Pro/SF Symbols/springs; Reduce-Motion/Transparency support |
| Pasteboard edge cases | `ClipboardClassifier` is pure + unit-tested across all content types via a fake pasteboard |

---

## Verification

- **Unit tests (`BlipKit`):** classifier across text/color/image/files/link/concealed/transient via a fake `PasteboardReading`; watcher emits exactly once per `changeCount` change and never for concealed/transient; hex-color detection; preview truncation.
- **Manual end-to-end:** copy text → "N characters"; copy a hex string → swatch+hex; copy an image → thumbnail; copy file(s) in Finder → icon+name; copy from a password manager → "hidden"; verify on a notch Mac (built-in display) and on an external/non-notch display (soft pill); toggle Reduce Motion + Reduce Transparency + light/dark; confirm no network connections (Little Snitch/`nettop`).
- **Perf:** idle CPU ≈ 0; no leaks across thousands of copies.
