# Web Release: Serving The Funny Guy RPG in a Browser

The practical path is EasyRPG Player's web build, which runs RPG Maker 2000/2003 games
entirely in the browser via WebAssembly. The server only serves static files — no backend
required.

---

## How it works

- The EasyRPG Player is compiled to WebAssembly (`.wasm`) and loaded by a JavaScript loader.
- Your game's asset files (`game/`) are served from `games/default/` under the player shell.
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

This EasyRPG web player expects games under `games/`, with the default game in
`games/default/`. The game files and their `index.json` must live there.

**Copy the game assets** from `game/` into `dist/web/games/default/`. Do **not** copy the
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
games/
  default/
    index.json              ← generated manifest
    RPG_RT.ini              ← game
    RPG_RT.ldb              ← game
    RPG_RT.lmt              ← game
    RPG_RT.ind              ← game
    Map0001.lmu             ← game (repeat for all maps)
    ...
    Backdrop/               ← game asset directories
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
them. The official tool for this is `gencache`, which writes an `index.json` that the
current player expects.

**Using `gencache` (preferred):**

```sh
cd <player-root>/games/default
gencache
```

This writes `index.json` into the game directory. Run it again any time you add or remove
game files.

If you do not have `gencache`, use this repo's compatibility generator instead:

```sh
cd <repo-root>
python3 scripts/generate_index.py dist/web/games/default
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

### Laravel Forge

Forge can deploy this repo directly from GitHub. Create the site from your repository, then in
Forge's site advanced settings set the web directory to `/dist/web` so nginx serves the built
bundle instead of the repo root. Forge documents custom web directories and deploy scripts in:

- https://forge.laravel.com/docs/sites/the-basics
- https://forge.laravel.com/docs/sites/deployments

Use [scripts/forge-build-web.sh](/Users/ayounglad/src/funnyguyrpg/scripts/forge-build-web.sh:1)
inside your Forge deploy script after the new code has been checked out.

Standard deployment script:

```bash
cd $FORGE_SITE_PATH
git pull origin "$FORGE_SITE_BRANCH"

bash scripts/forge-build-web.sh
```

Zero-downtime deployment script:

```bash
$CREATE_RELEASE()
cd $FORGE_RELEASE_DIRECTORY

bash scripts/forge-build-web.sh

$ACTIVATE_RELEASE()
```

Notes:

- `scripts/build-web.sh` requires `python3` and `rsync`, which are available on typical Forge
  Ubuntu servers.
- If you enable Forge's GitHub push-to-deploy integration, Forge will run the deploy script on
  every push to the configured branch automatically.
- Keep the COOP/COEP headers and `.wasm` MIME type configuration from step 6 in the Forge site's
  nginx configuration.

### GitHub Actions deploy to a self-hosted server

This repo includes [.github/workflows/deploy-web.yml](/Users/ayounglad/src/funnyguyrpg/.github/workflows/deploy-web.yml:1),
which builds `dist/web/` on every push to `main` and deploys it over SSH with `rsync`.

Configure these GitHub repository secrets before enabling it:

- `DEPLOY_HOST`: Hostname or IP of your server.
- `DEPLOY_USER`: SSH user for deployment.
- `DEPLOY_PATH`: Absolute target directory on the server, for example `/var/www/funnyguyrpg`.
- `DEPLOY_SSH_KEY`: Private SSH key GitHub Actions should use.
- `DEPLOY_KNOWN_HOSTS`: Output of `ssh-keyscan -p <port> <host>`.
- `DEPLOY_PORT`: Optional SSH port. Defaults to `22`.

The workflow assumes your server is already configured to serve the deployed directory with the
required COOP/COEP headers and `.wasm` MIME type from step 6.

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
