# Audio Removal Log

Date: 2026-04-01

## What Was Removed From Repo

The following non-chip music files (`.mp3`) were removed from version control and from the working tree:

- `game/Music/Junior's Boombox - U2 - Mission Impossible Theme.mp3`
- `game/Music/Junior's Boombox - U2 - Mission Impossible Theme (CUT).mp3`
- `game/Music/Junior's Boombox - Mock Weird Al - Barney's On Fire.mp3`
- `game/Music/Junior's Boombox - Nintendo - Nintendo Elevator Music.mp3`

## Safekeeping Backup Location (Outside Repo)

Files were copied before removal to:

- `/tmp/funnyguyrpg_mp3_backup_20260401_152106`

## Related Cleanup

- Added ignore rules for:
  - `.DS_Store`
  - `Thumbs.db`
  - `PPThumbs.ptn`
  - `game/Save*.lsd`
- History filter targets:
  - `**/*.mp3`
  - `**/PPThumbs.ptn`
  - `**/Thumbs.db`
  - `**/.DS_Store`
