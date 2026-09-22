# Fare Watch — web app

The installable build of Fare Watch. Everything here is static; there is no
build step and no server.

| File | Purpose |
|---|---|
| `index.html` | The whole app — markup, styles and logic in one file |
| `data.json` | Tracked routes and their recorded fares |
| `manifest.webmanifest` | Makes it installable, with the standalone display mode |
| `icon-192.png`, `icon-512.png`, `apple-touch-icon.png` | Home-screen icons |

## Serving it

GitHub Pages: repository **Settings → Pages**, source **Deploy from a branch**,
branch `claude/iphone-app-claude-instance-z1z8lx`, folder `/docs`. Free Pages
requires the repository to be public.

Any other static host works too — upload the contents of this folder as-is.

## Where the data comes from

`data.json` is rewritten by the daily fare sweep. The app fetches it on load
and falls back to whatever this browser last stored, so it still opens offline.
Edits made inside the app stay on that device; they are not pushed back here.

## Installing

Open the served URL on a phone, then **Share → Add to Home Screen**. It gets
the plane icon and launches without browser chrome.
