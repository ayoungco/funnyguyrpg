# Repo Tidiness: Should We Move RM2k3 Files Into `game/`?

Status: implemented in this repository. RM2k3 runtime/data files are now under `game/`.

Short answer: **yes, for repo hygiene**; **not as a direct in-place move without compatibility handling**.

## Why It Helps

Moving the large RPG Maker payload into `game/` makes root-level repo content much cleaner:

- keeps docs/scripts/config visible at top level
- reduces noise from hundreds of `MapXXXX.lmu` files
- improves contributor onboarding

## Risk

RPG Maker 2003 projects and related tooling commonly assume the executable and data folders are co-located in one game directory (relative paths). A naive move can break:

- runtime asset lookup (`CharSet`, `ChipSet`, `Sound`, etc.)
- save file assumptions
- tool scripts expecting files at repo root

## Recommended Layout

```text
/
  game/
    RPG_RT.exe
    RPG_RT.ini
    RPG_RT.ldb
    RPG_RT.lmt
    Map*.lmu
    Save*.lsd
    Backdrop/
    Battle/
    CharSet/
    ...
  docs/
  scripts/
  README.md
```

## Migration Strategy (Low Risk)

1. Move all RM2k3 runtime/data assets together into `game/` in one commit.
2. Add/update launch instructions to run from `game/` (not repo root).
3. Update any scripts/CI/docs that reference root-level `Map*.lmu` or `RPG_RT.*`.
4. Keep compatibility wrappers:
   - helper script in repo root (`scripts/run-game.sh` or `.bat`) that launches `game/RPG_RT.exe`
5. Verify:
   - boot succeeds,
   - maps load,
   - save/load works,
   - key audio/graphic assets resolve.

## Recommendation For This Repo

Proceed with a `game/` subfolder migration, but do it as a deliberate refactor with path updates and a quick runtime smoke test. This gives you a much tidier repo without sacrificing reliability.
