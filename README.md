# ICAO RT Trainer

Aviation English training app (ICAO radiotelephony, COMPLANG Units 1–8): radio practice with ATC, emergencies, phrase games, numbers and phonetic alphabet, METAR/TAF decoding, aerodrome layouts.

## Files

| File | Purpose |
|---|---|
| `index.html` | The whole app |
| `manifest.json` | App name, colours and icons (makes it installable) |
| `sw.js` | Offline support (service worker) |
| `icon-192.png`, `icon-512.png`, `icon-maskable-512.png`, `icon.svg` | App icons |
| `.nojekyll` | Tells GitHub Pages to publish files as they are |

## Website (GitHub Pages)

Settings → Pages → Deploy from a branch → `main` / `(root)` → Save.
Site: `https://<username>.github.io/rt-trainer/`

## Android app

Build it with https://www.pwabuilder.com from the site address.

## Updating

1. Upload the new `index.html`.
2. Open `sw.js` → edit (pencil) → change `rt-v1` to `rt-v2` (next time `rt-v3` …) → Commit.
   This makes installed apps download the new version.
