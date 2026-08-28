# Changelog

All notable changes to this mod are recorded here, newest first.

## [1.1.3] - unreleased

### Fixed

- **The cap's bill was skin-coloured.** Vanilla draws it in the same shade as
  the face, so on red Red the bill and the face are the same colour and
  nobody notices; put a green cap above it and the hat reads as having no
  bill at all. A shade-2 pixel sitting directly under a shade-3 one is the
  bill, and it goes with the hat. The face is not caught by it — there is a
  black row between the bill and the face, so what is above the face is black
  rather than cap.

  The rule runs on the overworld sheets only. There the cap is a handful of
  pixels and "skin directly under cap" means one thing; on the 56×56 trainer
  card there are dozens of shade-2-under-shade-3 adjacencies that are shading
  rather than a bill, and every one of them would turn green.

## [1.1.2] - 2026-08-28

### Fixed

- **His lips were green.** Red's overworld mouth is one block of the *cap's*
  colour sitting in the middle of his face, so a flat shade remap paints it
  with the clothes. It cannot be told apart by shade, because it is the same
  shade — only by where it sits. A shade-3 pixel with skin on both sides of
  it in the same row is enclosed by face and is not clothing; the cap and the
  clothes are bounded by black, never by skin, so they are never caught by
  it. `ctx` has no per-pixel verb, so this reaches for ImageData's own
  `getPixel`/`mapPixel` — one step past the documented surface, and therefore
  `pcall`'d: if those are ever missing the picture falls back to the plain
  remap and comes out exactly as 1.1.1 drew it rather than not at all.

### Added

- **The title screen's standing figure is green**, on a `TITLE FIGURE` row.
  Not by swapping the pic — there is no `trueColor` seam there, which is what
  made 1.1.0's attempt come back white and pink. The figure keeps the vanilla
  grey art and `MEWMON`, its zone palette, is overridden instead. That zone
  is tile rows 10–17, so the `GAME FREAK` line goes green with him; that is
  the cost, taken deliberately. The cycling Pokémon is untouched while its
  art is true-colour — `markVisibleTrueColor` marks the mon and cuts the
  figure out of it — which holds with any sprite mod on, including the one
  the cart pins. The row is there to switch back out of it otherwise.
- **The `player.sprite` hook says what it sees**, once per pic per session:
  the kind, the side, the resolved path, and whether it swapped. 1.1.1
  greened the battle back pic and left the trainer card red, and there was no
  way to tell from outside whether the hook never ran or ran and declined a
  path shaped differently than expected. This answers that without a
  debugger.

### Known

- The trainer card's front pic was still red in 1.1.1 and this release does
  not claim to fix it — it makes the cause visible. The card resolves its pic
  through `Sprites.playerPath`, which runs the hook, so the log line for
  `trainer_card/front` will say which path it was handed and why it was
  declined.

## [1.1.1] - 2026-08-28

Two more from the field, both on 1.1.0's own fixes.

### Fixed

- **The skin was a pale cream, not skin.** `#f8d8a8` read as no colour at
  all -- a washed-out blob where a face should be. It is `#f0a363` now, a
  warm tan, sampled straight off the reference sprite rather than guessed
  at from the middle of the ramp.
- **The title screen's standing figure came out white and pink.**
  `TitleState` bakes the OBJ palette onto that pic (`Sprites.recolor` with
  `PaletteFX.ogObj`) and gives it no `trueColor` path -- `markVisibleTrueColor`
  cuts the player's rectangle *out* of the true-colour region on purpose, so
  the cycling mon behind him keeps its palette. Recoloured art handed to that
  draw is read back through the shade buckets: the tan comes out white and
  the green comes out whatever colour index 3 is. There is no seam to do this
  through, so the figure stays as the base game drew it and the ribbon
  carries that screen on its own. The recipe no longer writes it either.

## [1.1.0] - 2026-08-28

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
