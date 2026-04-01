# RPG Maker 2003 Path Analysis

## Scope

This analysis was done from project data files in this repo:

- `game/RPG_RT.lmt` (map tree names and hierarchy labels)
- `game/RPG_RT.ldb` (database text, skills, system strings)
- `game/Map0001.lmu` to `game/Map0318.lmu` (event/dialog string extraction)
- `game/Save01.lsd` to `game/Save05.lsd` (rough progression checkpoints)

It is a static extraction pass (primarily string-level), not a full opcode decompile.

## Main Story Route (High-Level)

1. Early game starts in Funnytown/GasTown and pushes into Silent Creek and Toilet City arc.
2. Early gate progression is tied to Strange Keys and city/dungeon unlock events.
3. Laugh Jungle and Bromiliad City arc leads into Evil Scientist storyline and Lab segment.
4. Transition to Sunburn Desert, Ocean City, and Seagull City introduces rail/key progression.
5. Gorge Canyon + Breeze City + Shield City arc introduces pass-based travel checks.
6. Humortopica arc introduces heavy security and elevator pass gating.
7. Endgame shifts into warp-heavy late dungeons and final battle sequence.

## Branching And Optional Paths

- Frequent `Yes/No` prompt events across story and hub maps.
- Explicit travel selection menu observed with destination options like:
  - Funnytown
  - Seagull City
  - Laugh Jungle
  - Gorge Canyon
  - Ice Mountains
- Optional hub content includes inns, shops, taverns, casino, tutorials, and skill-oriented side interactions.
- Several “no turning back” style warnings appear near late-story transitions.

## Confirmed Gate Items / Passes

- Strange Keys
- Rail Keys
- Rail Keys Lv. 2
- Rail Keys Lv. 3
- Rail Keys Lv. 4
- Gorge Pass
- Ice Mountains Key
- Cell Phone
- Green Gem
- Elevator Pass

Observed gate checks include:

- “You need a pass to get through.”
- “Funny Guy shows the pass.”
- “It’s locked. You need a key …”
- “You may pass …”

## Route/Gate Hotspots (Representative Maps)

- `Map0001` / `Map0010`: early regional progression and Toilet City gating language.
- `Map0039` / `Map0043`: Evil Scientist race/lab arc.
- `Map0058`, `Map0112`, `Map0147`, `Map0202`: staged rail key progression.
- `Map0142`, `Map0144`: Gorge Pass obtain/show checks.
- `Map0245`: Humortopica pass gate and Elevator Pass obtain event.
- `Map0299` onward: warp-centric late game.

## Save File Progress Markers (Observed)

- `Save01` and `Save05`: early-game regions.
- `Save02`: desert/mid-game region.
- `Save03` and `Save04`: late-game/endgame (includes final confrontation-related text).

## Practical “Paths We Can Take”

- Mainline progression path: follow key/pass gates in the order above.
- Side content path: clear available city hubs between gate unlocks for extra items, skill scrolls, and party prep.
- Mobility-first path: prioritize transport/pass unlocks (rail key tiers, gorge pass, elevator pass) to reduce backtracking and open route options faster.

## Limitations

- Because this pass is not a full LMU event-command decode, exact switch/variable conditions and all conditional branches are not fully enumerated.
- If needed, next step is to run a full RM2k3 parser/decompiler and produce:
  - a per-map event list,
  - switch/variable dependency graph,
  - and a strict step-by-step critical path walkthrough.
