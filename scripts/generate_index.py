#!/usr/bin/env python3
"""
Generate index.json for EasyRPG Player's web build.

Run this from the web output directory (where the game files and EasyRPG
player files live together) any time game assets are added or removed:

    python3 scripts/generate_index.py [output-dir]

If output-dir is omitted, defaults to web/.
"""

import json
import pathlib
import sys

# File extensions that belong to the EasyRPG player itself or the build
# tooling -- not game data, so not included in the game file index.
PLAYER_EXTENSIONS = {".js", ".wasm", ".html", ".py", ".toml"}
PLAYER_FILENAMES = {"index.json", "_headers", "favicon.png"}

def generate(output_dir: pathlib.Path) -> None:
    if not output_dir.is_dir():
        print(f"error: {output_dir} is not a directory", file=sys.stderr)
        sys.exit(1)

    files = []
    for p in sorted(output_dir.rglob("*")):
        if not p.is_file():
            continue
        if p.name.startswith("."):
            continue
        if p.suffix.lower() in PLAYER_EXTENSIONS:
            continue
        if p.name in PLAYER_FILENAMES:
            continue
        files.append(str(p.relative_to(output_dir)))

    index_path = output_dir / "index.json"
    index_path.write_text(json.dumps(files, indent=2) + "\n")
    print(f"wrote {len(files)} entries to {index_path}")

if __name__ == "__main__":
    target = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else pathlib.Path("web")
    generate(target)
