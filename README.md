# ICAO RT Trainer

Aviation English training app (ICAO radiotelephony, COMPLANG Units 1–8): radio practice with ATC, emergencies, phrase games, numbers and phonetic alphabet, METAR/TAF decoding, aerodrome layouts.

## Files

| File | Purpose |
|---|---|
| `index.html` | The whole app |
| `manifest.json`, `sw.js` | Install as a web app, offline support |
| `icon-*.png`, `icon.svg` | App icons |
| `debug.keystore` | Signing key for the Android APK (keeps updates installable) |
| `.github/workflows/build-apk.yml` | Builds the Android APK on GitHub (Actions tab) |
| `.nojekyll` | Tells GitHub Pages to publish files as they are |

## Android APK

Actions → **Build APK** → **Run workflow**. About 4–6 minutes later the APK is under **Releases** (`RT-Trainer.apk`).
The workflow also runs by itself every time `index.html` changes.

## Website

Settings → Pages → Deploy from a branch → `main` / `(root)`.
