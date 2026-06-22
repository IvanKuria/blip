#!/usr/bin/env bash
#
# make-icon.sh — Reproducible macOS app-icon pipeline for "Blip".
#
# Concept: a dark charcoal/blue macOS squircle with the MacBook "notch" pill
# and a system-green confirmation checkmark — "a copy confirmed in the notch".
#
# Pipeline:
#   1. Generate a 1024x1024 vector source (SVG) with a true Apple-style
#      superellipse squircle (continuous curvature, not a plain rounded rect).
#   2. Render the SVG to a 1024 master PNG with rsvg-convert.
#   3. Downsample to every required macOS icon size with sips (high-quality).
#   4. Emit a valid AppIcon.appiconset/Contents.json.
#
# Tools required: python3 (SVG generation), rsvg-convert (vector render), sips (downscale).
#
set -euo pipefail

# ---- Paths -----------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
ASSETS_DIR="${PROJECT_ROOT}/Blip/Resources/Assets.xcassets"
ICONSET_DIR="${ASSETS_DIR}/AppIcon.appiconset"
SVG_PATH="${SCRIPT_DIR}/icon.svg"
MASTER_PNG="${SCRIPT_DIR}/icon-1024.png"

mkdir -p "${ICONSET_DIR}"

# ---- Tool checks -----------------------------------------------------------
command -v python3      >/dev/null 2>&1 || { echo "error: python3 not found";      exit 1; }
command -v rsvg-convert >/dev/null 2>&1 || { echo "error: rsvg-convert not found"; exit 1; }
command -v sips         >/dev/null 2>&1 || { echo "error: sips not found";         exit 1; }

# ---- 1. Generate the SVG source --------------------------------------------
echo "==> Generating SVG source"
python3 - "${SVG_PATH}" <<'PY'
import math, sys

def squircle(cx, cy, r, n=5.0, steps=240):
    pts = []
    for i in range(steps + 1):
        t = 2 * math.pi * i / steps
        ct, st = math.cos(t), math.sin(t)
        x = cx + r * math.copysign(abs(ct) ** (2.0 / n), ct)
        y = cy + r * math.copysign(abs(st) ** (2.0 / n), st)
        pts.append((x, y))
    d = "M %.2f %.2f " % pts[0]
    for p in pts[1:]:
        d += "L %.2f %.2f " % p
    return d + "Z"

# Apple-style continuous-curvature squircle, inset a touch from the 1024 canvas.
SQ = squircle(512, 512, 432, n=5.0)

svg = f'''<?xml version="1.0" encoding="UTF-8"?>
<svg width="1024" height="1024" viewBox="0 0 1024 1024" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="bgGrad" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0"    stop-color="#3B4252"/>
      <stop offset="0.42" stop-color="#262B36"/>
      <stop offset="1"    stop-color="#13161D"/>
    </linearGradient>
    <radialGradient id="topSheen" cx="0.5" cy="0.02" r="0.95">
      <stop offset="0"    stop-color="#FFFFFF" stop-opacity="0.18"/>
      <stop offset="0.45" stop-color="#FFFFFF" stop-opacity="0.035"/>
      <stop offset="1"    stop-color="#FFFFFF" stop-opacity="0"/>
    </radialGradient>
    <linearGradient id="notchGrad" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#0C0E12"/>
      <stop offset="1" stop-color="#000000"/>
    </linearGradient>
    <linearGradient id="greenGrad" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#54E27E"/>
      <stop offset="1" stop-color="#26B04E"/>
    </linearGradient>
    <radialGradient id="badgeSheen" cx="0.5" cy="0.12" r="0.9">
      <stop offset="0"   stop-color="#FFFFFF" stop-opacity="0.32"/>
      <stop offset="0.6" stop-color="#FFFFFF" stop-opacity="0.04"/>
      <stop offset="1"   stop-color="#FFFFFF" stop-opacity="0"/>
    </radialGradient>
    <clipPath id="squircleClip"><path d="{SQ}"/></clipPath>
    <filter id="badgeShadow" x="-50%" y="-50%" width="200%" height="200%">
      <feDropShadow dx="0" dy="16" stdDeviation="22" flood-color="#000000" flood-opacity="0.42"/>
    </filter>
    <filter id="notchShadow" x="-40%" y="-40%" width="180%" height="220%">
      <feDropShadow dx="0" dy="10" stdDeviation="16" flood-color="#000000" flood-opacity="0.45"/>
    </filter>
  </defs>

  <!-- Squircle body -->
  <g clip-path="url(#squircleClip)">
    <rect width="1024" height="1024" fill="url(#bgGrad)"/>
    <rect width="1024" height="1024" fill="url(#topSheen)"/>

    <!-- Notch pill: flush top edge, rounded bottom corners (the MacBook notch) -->
    <g filter="url(#notchShadow)">
      <path d="M338 286
               h348
               v128
               a98 98 0 0 1 -98 98
               h-152
               a98 98 0 0 1 -98 -98
               z"
            fill="url(#notchGrad)"/>
    </g>
    <path d="M338 286 h348 v4 h-348 z" fill="#FFFFFF" fill-opacity="0.06"/>
  </g>

  <!-- Crisp inner edge -->
  <path d="{SQ}" fill="none" stroke="#FFFFFF" stroke-opacity="0.10" stroke-width="2"/>

  <!-- Green confirmation badge -->
  <g filter="url(#badgeShadow)" transform="translate(512 564)">
    <circle r="156" fill="url(#greenGrad)"/>
    <circle r="156" fill="url(#badgeSheen)"/>
    <circle r="155" fill="none" stroke="#FFFFFF" stroke-opacity="0.18" stroke-width="2"/>
    <path d="M-68 8 L-18 60 L78 -54"
          fill="none" stroke="#FFFFFF" stroke-width="36"
          stroke-linecap="round" stroke-linejoin="round"/>
  </g>
</svg>
'''
with open(sys.argv[1], "w") as f:
    f.write(svg)
print("    wrote", sys.argv[1])
PY

# ---- 2. Render the 1024 master ---------------------------------------------
echo "==> Rendering 1024 master PNG"
rsvg-convert -w 1024 -h 1024 "${SVG_PATH}" -o "${MASTER_PNG}"

# ---- 3. Downsample to all macOS sizes --------------------------------------
echo "==> Generating icon sizes"
# filename:pixel-size
SIZES=(
  "icon_16x16.png:16"
  "icon_16x16@2x.png:32"
  "icon_32x32.png:32"
  "icon_32x32@2x.png:64"
  "icon_128x128.png:128"
  "icon_128x128@2x.png:256"
  "icon_256x256.png:256"
  "icon_256x256@2x.png:512"
  "icon_512x512.png:512"
  "icon_512x512@2x.png:1024"
)
for entry in "${SIZES[@]}"; do
  name="${entry%%:*}"
  px="${entry##*:}"
  if [ "${px}" -eq 1024 ]; then
    cp "${MASTER_PNG}" "${ICONSET_DIR}/${name}"
  else
    sips -s format png -z "${px}" "${px}" "${MASTER_PNG}" --out "${ICONSET_DIR}/${name}" >/dev/null
  fi
  echo "    ${name} (${px}px)"
done

# ---- 4. Write Contents.json ------------------------------------------------
echo "==> Writing Contents.json"
cat > "${ICONSET_DIR}/Contents.json" <<'JSON'
{
  "images" : [
    { "idiom" : "mac", "scale" : "1x", "size" : "16x16",   "filename" : "icon_16x16.png" },
    { "idiom" : "mac", "scale" : "2x", "size" : "16x16",   "filename" : "icon_16x16@2x.png" },
    { "idiom" : "mac", "scale" : "1x", "size" : "32x32",   "filename" : "icon_32x32.png" },
    { "idiom" : "mac", "scale" : "2x", "size" : "32x32",   "filename" : "icon_32x32@2x.png" },
    { "idiom" : "mac", "scale" : "1x", "size" : "128x128", "filename" : "icon_128x128.png" },
    { "idiom" : "mac", "scale" : "2x", "size" : "128x128", "filename" : "icon_128x128@2x.png" },
    { "idiom" : "mac", "scale" : "1x", "size" : "256x256", "filename" : "icon_256x256.png" },
    { "idiom" : "mac", "scale" : "2x", "size" : "256x256", "filename" : "icon_256x256@2x.png" },
    { "idiom" : "mac", "scale" : "1x", "size" : "512x512", "filename" : "icon_512x512.png" },
    { "idiom" : "mac", "scale" : "2x", "size" : "512x512", "filename" : "icon_512x512@2x.png" }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
JSON

# ---- 5. Top-level catalog Contents.json (create if missing) ----------------
CATALOG_JSON="${ASSETS_DIR}/Contents.json"
if [ ! -f "${CATALOG_JSON}" ]; then
  echo "==> Writing top-level Assets.xcassets/Contents.json"
  cat > "${CATALOG_JSON}" <<'JSON'
{
  "info" : { "author" : "xcode", "version" : 1 }
}
JSON
fi

echo "==> Done. Master: ${MASTER_PNG}"
