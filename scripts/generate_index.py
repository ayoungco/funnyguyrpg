#!/usr/bin/env python3
"""
Generate an EasyRPG-compatible index.json for the web build.

This mirrors the structure produced by EasyRPG's `gencache` tool closely
enough for the current web player:

  {
    "metadata": { "version": 2, "date": "YYYY-MM-DD" },
    "cache": { ... }
  }

Run this against the game directory that will be served from `games/default/`.
"""

from __future__ import annotations

import json
import pathlib
import sys
import unicodedata
from datetime import date


KEEP_EXTENSIONS = {".ini", ".po"}


def normalized_key(name: str) -> str:
    return unicodedata.normalize("NFKC", name).lower()


def file_key(name: str, top_level: bool) -> str:
    lowered = normalized_key(name)
    stem = pathlib.PurePosixPath(lowered).stem

    if top_level:
        return "exfont" if stem == "exfont" else lowered

    suffix = pathlib.PurePosixPath(lowered).suffix
    if suffix in KEEP_EXTENSIONS:
        return lowered
    return stem


def build_cache(directory: pathlib.Path, depth: int, top_level: bool) -> dict[str, object]:
    if depth == 0:
        return {}

    cache: dict[str, object] = {}
    if not top_level:
        cache["_dirname"] = directory.name

    for entry in sorted(directory.iterdir(), key=lambda p: normalized_key(p.name)):
        name = entry.name
        if name == "_dirname":
            continue

        if entry.is_dir():
            nested = build_cache(entry, depth - 1, top_level=False)
            if nested:
                cache[normalized_key(name)] = nested
            continue

        if not entry.is_file():
            continue

        if name == "index.json":
            continue

        cache[file_key(name, top_level=top_level)] = name

    return cache


def generate(output_dir: pathlib.Path, recursion_depth: int = 4) -> None:
    if not output_dir.is_dir():
        print(f"error: {output_dir} is not a directory", file=sys.stderr)
        sys.exit(1)

    payload = {
        "metadata": {
            "version": 2,
            "date": date.today().isoformat(),
        },
        "cache": build_cache(output_dir, recursion_depth, top_level=True),
    }

    index_path = output_dir / "index.json"
    index_path.write_text(json.dumps(payload, indent=2) + "\n")
    print(f"wrote {index_path}")


if __name__ == "__main__":
    target = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else pathlib.Path("web")
    generate(target)
