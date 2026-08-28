# Changelog

All notable changes to this mod are recorded here, newest first.

## [1.3.0] - unreleased

### Changed

- **The trainer art takes its own ramp: white, light green, green, black.**
  1.2.0 reached those pictures for the first time and they came out blotchy —
  orange patches on the cap and knees, red speckles over the rest — and that
  was not a tuning problem. Shade 2 does not mean the same thing on the two
  kinds of art. On the 16×16 overworld sprite it is only ever the face; on
  the 56×56 portrait it is the *light* for everything: the cap's front, the
  shirt's shading, the knees, the shoes.

  Vanilla gets away with one shade for both because its ramp is monochrome
  red — white, light red, red, black — and light red happens to look like
  skin. Painting that shade a skin tone is what put the orange on the hat.

  So the portrait gets the same trick in green, and neither position rule:
  a face-sized rule on face-sized art is noise. The face reads as a pale
  green rather than as skin, which is the same compromise vanilla makes in
  the other direction. The overworld sheets are untouched — they keep the
  skin tone, the red lips and the green-tinted bill.

### Fixed

- **The recipe and the hook share one list of pictures.** The hook swapped
  any cache path it was handed, and a swap to a green file the recipe never
  wrote does not fall back to the red one — the image fails to load and the
  draw shows nothing. Both now name the same eight, in the same order, and
  `tools/check.py` fails the build if they drift apart.
- **Five more pictures are covered**: `battle/back/redb.png`,
  `credits/red.png`, `intro/red.png` and `hall_of_fame/red.png` join the
  four that were already there. Each is probed with `ctx.exists`, so a cache
  without one simply keeps that picture as the base game drew it.

## [1.2.0] - 2026-08-28

### Fixed

- **The large sprites were never reachable, and now they are.** The battle
  back pic, the trainer card, Oak's intro and the Hall of Fame stayed red
  through every release from 1.0.0 on, and each attempt was aimed at the
  wrong end of the problem.

  `Hooks:call` walks the chain **highest priority first**, and a link that
  returns without calling `next()` ends the chain there. Crystal Animated
  Sprites — which the cart pins — wraps `player.sprite` at priority **930**
  and does exactly that: when its `PLAYER SPRITE` option names a portrait it
  returns its own file and never calls `next()`. This mod's link took the
  default priority of `0`, so it sat downstream of a chain that never reached
  it. Nothing it did to those pictures could have worked.

  It wraps at **940** now — outside that one, and no further up than it has
  to be — and computes the swap from the path it is handed rather than from
  what downstream answers, because downstream is where the substitution
  happens.

  The cost is the `PLAYER` row's to pay: on `GREEN`, a portrait chosen in
  `CRYSTAL SPRITES > PLAYER SPRITE` no longer applies to the player. `RED`
  hands it back. Opponent portraits, the animated battle sprites and the
  shiny work are untouched either way — this link only ever answers for the
  player.

### Changed

- **The bill is a green-tinted white** (`#e6f4dc`) rather than the cap's
  green. Vanilla draws it in the *face's* shade, so it reads as nothing at
  all; 1.1.3 painted it the cap's green and it merged into the hat instead.
  Now it has an edge against both.
- **The bill is found by region, not by direction or by row.** It is a small
  patch of the face's shade, touching the cap, high in its frame — all three,
  because any two of them catch something else: small-and-touching is also
  the hands, touching-and-high is also the top of the face, small-and-high is
  whatever else is up there. 1.1.3 looked only directly above a pixel and
  missed the profile frames; 1.1.4's row cutoff assumed a fixed cap height.

## [1.1.4] - 2026-08-28

### Fixed

- **The lips are red again, not gone.** 1.1.2 painted the mouth skin, which
  did not fix it so much as delete it. Red's lips are drawn in the *cap's*
  shade, which is why they come out red in vanilla and read as lips at all —
  so they are painted `#ec4d29`, vanilla's own colour sampled off red Red,
  rather than either the clothes' green or the face's tan.
- **The bill was green facing down and skin facing sideways.** 1.1.3's rule
  only looked directly above a pixel. Facing down the bill sits *under* the
  cap, but in profile it sticks out *beside* it, so the side frames kept the
  vanilla colour and the two views disagreed. Any of the four neighbours
  counts now, bounded to the top rows of each 16px frame so the face below
  is never caught by it.

## [1.1.3] - 2026-08-28

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
