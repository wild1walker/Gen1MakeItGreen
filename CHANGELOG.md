# Changelog

All notable changes to this mod are recorded here, newest first.

## [1.1.0] - unreleased

Everything in 1.0.0 that reached the screen reached it wrong. This is the
fix, from four things seen in the field.

### Fixed

- **The player only changed in the overworld.** The battle back pic, the
  front pic that Oak's intro and the trainer card and the Hall of Fame
  share, and the title screen's standing figure all stayed red.
  `Sprites.playerPath` resolves those through `FieldDefaults.fieldValue`,
  not `data.field`, so `field:get("playerPics")` handed back nothing and the
  patch built out of it patched nothing. They now go through the
  `player.sprite` hook, which runs over the already-resolved path and needs
  no guess about where the vanilla art lives.
- **The overworld player was green all over instead of green-clothed.**
  Shade 2 is the SKIN and the shirt's white; shade 3 is the outfit. 1.0.0
  turned both green, so the face went green with the cap. Shade 2 is now a
  skin tone and only shade 3 is green.
- **The title lettering was too light.** The ribbon band no longer borrows
  the character's light green: `LOGO1` gets its own darker pair, dark enough
  to read as ink on white at 8px.
- **`field.boot` was patched twice** — once for the name, once for the title
  — and the second write is what the merge keeps. Both now go in as one
  patch. The test stub reproduces the replacing behaviour on purpose, so
  splitting them again fails the suite.

### Added

- **The default name is GREEN**, where the game used to offer RED, on a
  `DEFAULT NAME GREEN` row of its own. It follows `PLAYER`: switch the
  character back to red and the name goes back with him.
- The recipe probes `battle/back/redb.png` as well as `battle/redb.png`, and
  the hook derives its green path from whatever the engine resolved rather
  than from a filename whitelist, so the two halves cannot disagree about a
  name.
- A line in the log on every load saying which way `PLAYER` and
  `TITLE RIBBON` are set and where the recoloured art is read from.

## [1.0.0] - 2026-08-28

### Added

- The player, green: the overworld walker, the `BICYCLE` sheet, the battle
  back pic, the front pic Oak's intro and the trainer card and the Hall of
  Fame share, and the standing figure on the title screen. Recolored from
  the player's own imported cache by `transforms.lua`; no pixel ships.
- `WILD GREEN VERSION` on the title screen, as one continuous ribbon, with
  the `LOGO1` band recolored to match.
- A `PLAYER` row — `GREEN` or `RED` — so the vanilla character is one switch
  away, and a `TITLE RIBBON` row for the branding.
- `tests/wild_green_test.lua`, which runs both files against a stood-up
  `mod` table and asset `ctx`.
