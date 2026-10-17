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

## iPhone / iPad

**Quickest (no Apple account needed):** open https://alfatango1.github.io/rt-trainer/ in **Safari**, tap **Share → Add to Home Screen**. It opens full-screen like an app and works offline.

**Native app (.ipa):** Actions → **Build iOS** → Run workflow.
- Without secrets you get `RT-Trainer-unsigned.ipa` (Releases). Install it with Sideloadly or AltStore on a computer, signing in with your Apple ID (free Apple IDs must re-install every 7 days).
- With a paid Apple Developer account add these repository secrets to get a signed `RT-Trainer.ipa`:
  `IOS_CERT_P12_BASE64`, `IOS_CERT_PASSWORD`, `IOS_PROFILE_BASE64`, `IOS_TEAM_ID` (optional: `IOS_BUNDLE_ID`, `IOS_EXPORT_METHOD` = ad-hoc / development / app-store).
