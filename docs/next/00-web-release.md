# Web Release: Serving The Funny Guy RPG in a Browser

The practical path is EasyRPG Player's web build, which runs RPG Maker 2000/2003 games
entirely in the browser via WebAssembly. The server only serves static files — no backend
required.

---

## How it works

- The EasyRPG Player is compiled to WebAssembly (`.wasm`) and loaded by a JavaScript loader.
- Your game's asset files (`game/`) are served alongside the player.
- EasyRPG fetches each asset on demand using HTTP range requests.
- Everything runs client-side. No save-game server needed (saves go to browser localStorage).

---

## Prerequisites

- Python 3 (to generate the file index and optionally run a local dev server)
- A static file host (GitHub Pages, Netlify, Cloudflare Pages, or any nginx/Apache server)
- The EasyRPG Player web release archive (see step 1)

---

## Step 1 — Download the EasyRPG Player web build

Go to the EasyRPG Player releases page:

```
https://github.com/EasyRPG/Player/releases
```

Download the latest web build archive. At the time of writing, the official archive exposes a
JS build named like `easyrpg-player-latest-js.tar.gz`.

Extract it. You will get a directory containing at minimum:

```
index.html
index.js
index.wasm
favicon.png
```

Keep these files in `web/` as the source web shell. The final deployable bundle will be
generated into `dist/web/`.

---

## Step 2 — Prepare the game files

The EasyRPG web player expects game files to live in a subdirectory called `games/` under the
player root, or directly in the root if you are only shipping one game. One-game layout is
simpler and is what these instructions use.

**Copy the game assets** from `game/` into the build output directory (`dist/web/`). Do **not** copy the
following — they are Windows-only and/or irrelevant on the web:

| File/pattern | Reason to exclude |
|---|---|
| `RPG_RT.exe` | Windows executable, unused in web build |
| `RPG_RT.exe.mbxcfg` | Windows config, unused |
| `RPG_RT.exe.old` | Old backup, unused |
| `ultimate_rt_eb.dll` | Windows DLL, unused |
| `logo.rc` | Windows resource file, unused |
| `Save*.lsd` | In-progress save files — do not ship developer saves |
| `The_Funny_Guy_RPG.r3proj` | RPG Maker project file, not needed at runtime |
| `audio-removal-log.md` | Internal doc |

Everything else goes in. The result should look like:

```
index.html                  ← EasyRPG Player
index.js                    ← EasyRPG Player
index.wasm                  ← EasyRPG Player
RPG_RT.ini                  ← game
RPG_RT.ldb                  ← game
RPG_RT.lmt                  ← game
RPG_RT.ind                  ← game
Map0001.lmu                 ← game (repeat for all maps)
...
Backdrop/                   ← game asset directories
Battle/
BattleCharSet/
BattleWeapon/
CharSet/
ChipSet/
Data_1.bin
FaceSet/
GameOver/
Monster/
Music/
Panorama/
Picture/
Sound/
System/
System2/
Title/
```

---

## Step 3 — Generate the file index

EasyRPG's web player needs a manifest of every game file so it can preload or lazy-fetch
them. The player release includes a helper script (`generate_index.py`) to create this. If
the release you downloaded does not include it, create it manually:

**Using the bundled script (preferred):**

```sh
cd <player-root>
python3 generate_index.py
```

This writes `index.json` (sometimes `filelist.js` depending on the player version) to the
same directory. Run it again any time you add or remove game files.

**If no script is included**, create `index.json` manually. It is a flat JSON array of
relative paths to every file the player needs to load:

```sh
cd <player-root>
python3 -c "
import json, pathlib
files = [str(p.relative_to('.')) for p in pathlib.Path('.').rglob('*') if p.is_file()
         and not p.name.startswith('.')
         and p.suffix not in ('.js', '.wasm', '.html', '.py', '.json')]
print(json.dumps(sorted(files), indent=2))
" > index.json
```

---

## Step 4 — Configure `RPG_RT.ini` for web

No changes are strictly required, but confirm the `GameTitle` line is set — EasyRPG uses it
for the browser tab title:

```ini
[RPG_RT]
GameTitle=The Funny Guy RPG
```

Remove `MapEditMode` and `MapEditZoom` if you want a clean production config (they are
editor-only settings and have no effect at runtime).

---

## Step 5 — Test locally

EasyRPG's WASM build requires files to be served over HTTP (not `file://`) because browsers
block `SharedArrayBuffer` on local file URLs. Use Python's built-in server:

```sh
cd <repo-root>
python3 -m http.server 8080 --directory dist/web/
```

Open `http://localhost:8080` in your browser. The game should load and start.

**Checklist before moving on:**

- [ ] Title screen appears
- [ ] Music plays (MIDI files are supported natively by EasyRPG's web build via a bundled
      synthesizer; no browser MIDI support required)
- [ ] Sound effects play
- [ ] You can navigate menus and start a new game
- [ ] Saves work (they persist to browser localStorage between page reloads)
- [ ] No 404 errors in the browser console (missing assets show up here)

---

## Step 6 — Configure the server for production

Two HTTP headers are **required** for the WASM player to work correctly in all browsers:

```
Cross-Origin-Opener-Policy: same-origin
Cross-Origin-Embedder-Policy: require-corp
```

These enable `SharedArrayBuffer`, which EasyRPG uses for audio threading. Without them,
audio may be broken or the player may fail to initialize in Chromium-based browsers.

Also ensure the server sends the correct MIME type for `.wasm` files:

```
Content-Type: application/wasm
```

Most modern hosts set this automatically. If you are running nginx or Apache yourself, verify
it explicitly.

### nginx example

```nginx
server {
    listen 80;
    root /var/www/funnyguyrpg;

    add_header Cross-Origin-Opener-Policy "same-origin";
    add_header Cross-Origin-Embedder-Policy "require-corp";

    location ~* \.wasm$ {
        types { application/wasm wasm; }
    }
}
```

### Netlify (`netlify.toml`)

```toml
[[headers]]
  for = "/*"
  [headers.values]
    Cross-Origin-Opener-Policy = "same-origin"
    Cross-Origin-Embedder-Policy = "require-corp"
```

### GitHub Pages

GitHub Pages does not support custom response headers. Use Cloudflare Pages or Netlify
instead, both of which support header configuration and have generous free tiers.

---

## Step 7 — Deploy

### Cloudflare Pages (recommended for simplicity)

1. Push the player root directory to a GitHub repository (can be this repo with the player
   files added, or a separate deployment repo).
2. Go to Cloudflare Pages > Create application > Connect to Git.
3. Set the build output directory to `dist/web/`.
4. Add the two required headers in Pages > your project > Settings > Headers, or via a
   `_headers` file in the root:

```
/*
  Cross-Origin-Opener-Policy: same-origin
  Cross-Origin-Embedder-Policy: require-corp
```

5. Deploy. Cloudflare Pages serves from a CDN automatically.

### Netlify

1. Drag-and-drop the player root folder onto `app.netlify.com/drop`, or connect via Git.
2. Ensure `netlify.toml` (from step 6) is at the root of the deployed directory.
3. Deploy.

### Self-hosted (nginx/Apache)

1. Copy the player root to your server's web root.
2. Apply the nginx config from step 6.
3. Confirm `application/wasm` MIME type is registered.

---

## File size considerations

The `game/` directory contains uncompressed WAV sound effects and MIDI music files. Before
deploying, consider:

- **Music**: The MIDI files in `Music/` are already small. No action needed.
- **Sound**: WAV files in `Sound/` can be large. EasyRPG's web player supports OGG Vorbis
  as a drop-in replacement. Converting WAVs to OGG reduces download size significantly with
  no code changes required (EasyRPG will prefer `.ogg` over `.wav` automatically if both
  are present, or if only `.ogg` is present).

  Batch convert with ffmpeg:
  ```sh
  cd game/Sound
  for f in *.wav; do ffmpeg -i "$f" -q:a 4 "${f%.wav}.ogg" && rm "$f"; done
  ```

- **Graphics**: The graphic assets are already in the RPG Maker binary formats that EasyRPG
  reads directly. No conversion needed.

---

## Ongoing workflow

When you update the game in RPG Maker 2003 and export a new build:

1. Copy updated files from `game/` into the player root (same exclusions as step 2).
2. Re-run `generate_index.py` (or regenerate `index.json`) to reflect any added/removed
   files.
3. Redeploy.

Automate steps 1–2 with a shell script to avoid forgetting the index regeneration step.
