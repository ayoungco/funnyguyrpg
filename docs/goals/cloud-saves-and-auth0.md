# Cloud Saves for the Web Release (with Auth0 Email Capture)

Evaluation of how to make save games survive beyond a single browser/device once
[`web-release.md`](web-release.md) is deployed, and how to layer an Auth0
passwordless-email login on top as both the sync mechanism and a mailing-list signal.

Not yet implemented — this is a design doc to make a build/no-build call on.

---

## The problem with what's already planned

`web-release.md` is correct that EasyRPG's web build needs no backend to *run*. But
"saves go to browser localStorage" (as currently written there) undersells what's actually
happening and where it breaks:

- EasyRPG's Emscripten build mounts an **IDBFS** filesystem and calls `FS.syncfs()` to
  persist it to **IndexedDB** — not `localStorage`. Small distinction, same conclusion:
  storage is scoped to one browser profile on one device, at one origin.
- IndexedDB under that origin is subject to normal browser storage eviction (private
  browsing, "clear site data," Safari's non-installed-PWA eviction policy, a user switching
  browsers or computers). None of that is EasyRPG's fault — it's just what "local" storage
  means.
- There's a documented EasyRPG bug where saves collide/land in the wrong slot when multiple
  games share a domain, keyed by a `Module={EASYRPG_GAME:""}` string in the loader. Not a
  concern for a single-game deploy as long as that string is set to something unique (e.g.
  `funnyguyrpg`) — cheap to just do regardless.
- There is **no built-in cross-device save import/export UI** in EasyRPG Player as of this
  writing. Anything durable has to be built in the JS loader layer around the Emscripten
  `Module`, not inside EasyRPG itself — which is good news: it means no fork of EasyRPG or
  recompilation, everything happens in `index.html`/the loader script the web-release doc
  already has you customizing.

So "persist saves between sessions" in the sense of *this device, this browser, tomorrow*
already works today, for free, once `web-release.md` is deployed. "Persist between
sessions" in the sense of *a different laptop, six months from now, after clearing
cookies* requires shipping the save bytes somewhere off the browser — which requires a
backend and an identity to key it on. That's the actual ask here.

---

## Recommended architecture

**Auth0 (Passwordless Email) for identity + email capture, Cloudflare Workers + KV for the
save blob store.** Both are static-hosting-friendly, match the Cloudflare Pages deploy
target `web-release.md` already recommends, and add no server to operate.

```
┌─────────────┐        ┌──────────────────┐        ┌─────────────────────┐
│   Browser    │        │  Auth0 (hosted)   │        │  Cloudflare Worker   │
│  EasyRPG WASM│───────▶│  Passwordless      │        │  + KV (save blobs)   │
│  + loader.js │◀───────│  Email login       │        │  keyed by Auth0 `sub`│
└──────┬───────┘  JWT   └──────────────────┘        └──────────┬───────────┘
       │ FS.readFile / writeFile (IDBFS)                        │ verify JWT (JWKS)
       └──────────────────── save bytes, base64 ─────────────────┘
```

1. **Game boots with no login required.** Local IDBFS saves work exactly as
   `web-release.md` describes — casual play has zero friction, matching the "no backend
   required" spirit of the original plan.
2. A **"Save to Cloud" widget** sits in the page around the game canvas (not inside the
   WASM canvas — plain HTML/JS). Clicking it opens Auth0's Universal Login configured for
   the **Passwordless / Email connection** (magic link or one-time code, no password).
   This is the "email capture loop": every cloud-save opt-in is an email address in Auth0's
   user store, with no separate signup form to build.
3. On successful login, the loader gets a JWT from Auth0 (`@auth0/auth0-spa-js`, loaded from
   `cdn.auth0.com` or bundled). It reads the current `Save*.lsd` files out of IDBFS via
   `Module.FS.readFile(...)`, base64s them, and `POST`s them to a Cloudflare Worker with the
   JWT as a bearer token. The Worker verifies the JWT against Auth0's JWKS endpoint and
   writes the blob to KV keyed by the Auth0 `sub` claim.
4. **On page load, if an Auth0 session already exists** (silent auth via refresh token),
   the loader fetches the stored blob *before* instantiating the EasyRPG `Module`, writes it
   into IDBFS with `Module.FS.writeFile(...)`, then calls `FS.syncfs(false, cb)` so the game
   boots seeing the cloud save already in place — no extra step from the player past the
   first login on a new device.
5. **Upload trigger.** EasyRPG's C++ save routine can't be hooked directly without patching
   and recompiling the Player, which is out of scope. Pragmatic alternative: poll the
   `Save*.lsd` files' contents/mtimes every ~30s while the tab is visible, and again on
   `visibilitychange`/`pagehide`; diff against the last-uploaded copy and only `POST` when
   something changed. The files are a few KB each — this is cheap. Pair it with the manual
   "Save to Cloud" button for a player who wants certainty before closing the tab.

## Why not skip the backend entirely?

Two ways to avoid standing up Workers/KV, both worth naming and rejecting on purpose rather
than by default:

- **Store the save blob in Auth0 `app_metadata`** instead of a separate store — zero extra
  infrastructure, since the loader would only ever talk to Auth0. Rejected as the primary
  approach: `app_metadata` has a per-field size ceiling in the low tens of KB, and RPG Maker
  2003 supports up to 15 save slots — comfortably over that ceiling if a player fills more
  than one or two slots. Writing `app_metadata` also requires the Auth0 Management API,
  which isn't safe to call with a token minted in the browser — you'd still need *some*
  backend (even just a tiny function) to broker that call, so it doesn't actually remove the
  backend, just makes it do less. Fine as a v0 spike if you want to prove the loop end-to-end
  before building the Worker.
- **Manual export/import** (player downloads a `.zip` of their save, re-uploads it on the
  next device) — no infra, no login required at all. Rejected as the primary mechanism
  because it's the exact friction the ask is trying to remove, but worth keeping as a
  fallback "Export Save" button regardless of which path you pick — it's a good insurance
  policy against Auth0/Worker downtime and costs almost nothing to add (same
  `Module.FS.readFile` calls, wired to a browser download instead of a `POST`).

## Open questions this doc can't settle for you

- **Minors and email capture.** `fgoac`'s old `PrivacyPolicy.htm` already had to say "we
  will not accept information from minors unless they have their parent's/guardian's
  permission" — the FGRPG's audience skews the same way. Passwordless email login as a
  save-sync mechanism is still collecting a minor's email address under COPPA if the
  audience includes under-13s. Worth a real privacy notice on the login screen, not just a
  footer link, and worth deciding now whether Auth0's collected emails are *only* used for
  save sync or also folded into a newsletter list (the latter needs explicit opt-in
  language, not a checkbox pre-checked by default).
- **Auth0 tier.** Free tier covers 25k MAU as of this writing, which is very unlikely to be
  the constraint for this project — but confirm current terms before committing, Auth0's
  free-tier limits have moved before.
- **Whether this is worth building at all yet.** `web-release.md` itself hasn't been
  executed — there's no player root committed to this repo yet. Cloud saves are a layer on
  top of a deploy that doesn't exist yet. Recommend treating this doc as the plan for
  *after* `web-release.md` ships and someone's actually hit "I lost my save switching
  computers" as a real complaint, not before.

## Sources

- [Import save files to browser? – EasyRPG Community](https://community.easyrpg.org/t/import-save-files-to-browser/894)
- [Browser Version: Saves not being kept when leaving and returning to game page? – EasyRPG Community](https://community.easyrpg.org/t/browser-version-saves-not-being-kept-when-leaving-and-returning-to-game-page/927)
- [Emscripten Filesystem API — IDBFS](https://emscripten.org/docs/api_reference/Filesystem-API.html)
