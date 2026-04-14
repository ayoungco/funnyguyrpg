# The Funny Guy RPG

You've heard us talkin' about it... here it is. A RPG made in 7th grade (circa 2003) based on the characters from **The Funny Guy Comics** — a comics series drawn on the backs of school handouts, passed around class, and now preserved here for posterity. Built on the RPG Maker 2003 engine for maximum novelty value and coolness, this is a game you won't want to miss. Even if you have no idea what an RPG is, I have no doubt you'll enjoy yourself. It pokes fun at classic RPGs like Final Fantasy, and even other RPG Maker 2003 games. Help Funny Guy find his brothers and team up against the hordes of Humorless and their elite masters... the Evilies themselves!

This repository is the source for the game as it exists today. The goal is to get it running in a browser using [EasyRPG Player](https://easyrpg.org/) so that anyone can play it without installing anything — no Windows required, no setup, just a link.

## Repository Layout

The RPG Maker 2003 project files live under `game/` to keep the repository root tidy.

- Game data: `game/RPG_RT.ldb`, `game/RPG_RT.lmt`, `game/Map*.lmu`
- Assets: `game/CharSet/`, `game/ChipSet/`, `game/Sound/`, `game/Music/`, etc.
- Docs and planning notes: `docs/`

## Playing the Game

### On Windows (the old-fashioned way)

The `game/` directory contains everything you need. Run `game/RPG_RT.exe` directly — no installer required.

### In the Browser (coming soon)

We're working on a web release using the EasyRPG Player web build, which runs the game entirely in WebAssembly. No plugins, no downloads. See `docs/next/00-web-release.md` for the full setup instructions.

## Frequently Asked Questions

For those of you who don't know what an FAQ is, here's a definition for you... FAQ: A list of frequently asked questions and their answers about a given subject. With that said, let's move on!

### What even is The Funny Guy Comics?

The Funny Guy Comics was a handmade comics series created some time around 2002–2003. The "medium" was the backs of school handouts. The distribution network was passing them to friends in class. The production budget was zero. The FGRPG adapts those characters into a full RPG adventure, which at the time felt like an extremely ambitious undertaking for a 7th grader. It was.

### I'm stuck at [place in game]!

Honestly, same. It's been a while. Your best bet is to just explore every room and talk to everyone — this game was made by a 7th grader who did not always leave clear signposting. If you find a solution, feel free to open an issue and we'll add a hint.

### I found a glitch!

Report it in the [issue tracker](../../issues). The FGRPG uses semantic versioning (x.y.z): major overhauls bump x, significant updates bump y, and glitch fixes bump z. So the next patch would be 1.0.5.

### The game looks tiny / the window is small.

The FGRPG was designed for a 320x240 display scaled up to 640x480 — that was standard for RPG Maker 2003 games in 2003. On modern screens it will look small in windowed mode. Press F4 to toggle fullscreen, or use EasyRPG Player which has better scaling options.

### When running the game on Windows, everything acts laggy.

Try closing other programs and switching to full-screen mode (F4). The game runs a lot of events simultaneously in certain areas. It was tested on early-2000s hardware, so it should be fine on anything built in the last decade.
