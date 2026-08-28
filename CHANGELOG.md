# Changelog

All notable changes to this mod are recorded here, newest first.

## [1.16.0] - 2026-08-28

### Fixed

- **The first launch after an install no longer settles for the flat bake.**
  The recipe's copy of the title figure is a file, the transform writes it at
  install time, and the title screen is one of the earliest things drawn — so
  on a fresh install the copy can arrive a moment after the screen does. The
  draw took that as final and kept the faceless green bake for the life of
  the screen, which is what "works after a relaunch, not before" looked like.

  It asks again now while it hasn't got the copy — once every 45 draws, so a
  miss costs one file load a second rather than one a frame — and stops the
  moment it has it.

### Notes

- A new *version* still needs a relaunch to load at all: mods are loaded once
  at boot, so installing over a running game leaves the previous one running.
  That is the engine's, not this mod's, and both docs now say which is which.

## [1.15.0] - 2026-08-28

### Fixed

- **The title figure flashed back to the red bake.** Asserting it from
  `TitleState.currentSprite` is not enough: the draw reads `self.player`
  into a local at the top and only calls `currentSprite` further down, so a
  frame that changes the figure inside `currentSprite` still draws the
  picture captured before the change. One frame late would be invisible if
  the value were stable — and it is not, because the same draw skips
  `currentSprite` altogether while `scrollPhase` is `"ball"`. For that whole
  phase nothing re-asserted the figure and Crystal's red bake was what
  stood, which is the flash.

  `TitleState.draw` is wrapped too now, and asserts the figure before the
  draw reads it. No true-colour mark from that path — the rect is marked
  from `currentSprite`, inside the pass that owns those marks.

- The derived copy no longer waits on the untouched art. It is a file, found
  from the path `TitleState` loaded, and needs none — only the flat bake
  does. Requiring it up front is why the first draw of a visit had nothing
  to show.

## [1.14.0] - 2026-08-28

### Changed

- **The title figure is painted from a table, not from rules.** The rules
  could not express it: of the 95 pixels that are not plain ramp on that
  figure, fourteen come from the *paper* shade — the lit side of his face,
  the back of a hand — and eight go to ink. Nothing in the recipe touches
  white, and a rule invented to fit one sprite is a drawing with extra
  steps. So it is a drawing, authored by eye against the figure on screen
  and encoded as *row, column, the shade that must be under it, and the
  tone*.

  It ships no vanilla pixels: the art stays in the player's cache, and what
  the table carries is where a face is. The shade is the guard — a cache
  whose figure differs fails those checks and falls through to the ordinary
  rules rather than being painted at coordinates that mean nothing there.

- **The Poké Ball keeps vanilla's red.** The engine lifts an 8×8 out of that
  file at `(0,16)` and throws it on a y of its own, so in a screenshot it is
  never where it lives — but the rect is an engine constant, so the ball is
  coloured by rect and never needs a coordinate. It is a ball, not the
  player, which is the same argument the overworld `MOUTH` rule makes.

### Notes

- Checked against the authored figure pixel for pixel: **0 of 2,289
  differ**, outside the ball's own rect.

## [1.13.0] - 2026-08-28

### Fixed

- **A hand is skin; only the crease in it is the shadow.** 1.11.0 coloured
  every skin pixel by its own shade, which made both hands shadow throughout
  — they are drawn wholly in the mid shade. On this art that reads as a hand
  in shadow rather than as a hand. The ask was one pixel darker, and one
  pixel is what changes now: the speck sealed inside the right hand.

  Which pieces take the shadow is the detail pass's answer, not the shade's:
  the brow, the mouth, the ear's underside, the temple under the hat, and
  that speck. Everything else the skin passes find is the skin tone.

## [1.12.0] - 2026-08-28

### Changed

- **The title screen's figure gets the same skin as the trainer card.** He
  was the last picture of the player still flat green: `main.lua` baked him
  from the shade buckets at draw time, and a bake knows nothing about where
  a face is.

  He is a cache file like any other — `assets/generated/title/player.png` —
  so the recipe recolours him now, face and ear and hands and all, and
  `main.lua` hands that draw the derived copy instead of baking one.
  `TitleState` keeps the path it loaded him from, so there is nothing to
  guess: the green twin of *that* is what gets drawn, resolved through
  `Assets.image` like any other generated path. `PORTRAIT SKIN` picks
  between the two copies there exactly as it does on the card.

  Only under `ADVANCED`. In every other mode his rectangle is painted by
  shade, so a recoloured file is thrown away before it reaches the screen
  and `MEWMON` does that work, unchanged. A cache with no such file falls
  back to the flat bake, which is what 1.11.0 drew.

### Notes

- `1.11.1` is this same change released without its changelog or manifest
  bump — a doc script failed halfway and the commit went out regardless.
  `1.12.0` is the one to pin.

## [1.11.0] - 2026-08-28

### Fixed

- **The hands are the skin's shadow, not flat skin.** They were the only
  skin on the picture coloured by the zone that found them rather than by
  their own shade — found as hands, painted `#f0a363`, while every other
  mid-shade pixel of skin (the brow, the ear's underside, the temple) took
  `#ad7547`. They are drawn entirely in the mid shade, so they take the
  shadow now, the same as everything else.

  Which skin a pixel gets is its own shade and nothing else: light shade
  `#f0a363`, mid shade `#ad7547`.

- **The speck inside the right hand takes the hand's tone.** By shade alone
  it would be the light one — a highlight — but at six pixels a hand is a
  fist, and a lighter pixel inside a fist reads as the gap between two
  fingers, not a highlight on it. It goes in with the shadow, so the fist
  comes out one colour rather than one pixel of another. It is the one
  place in the recipe that does not go by shade, and it says so.

## [1.10.0] - 2026-08-28

### Fixed

- **The temple and the hand's highlight.** Three specks of the mid shade sit
  between the hat's underside and the face — they touch no skin at all, the
  hat's outline is in the way, so nothing else could reach them and they
  were the last of his head still green. And a single pixel of the *light*
  shade sits inside the right hand: on a hand drawn entirely in the mid
  shade that is its highlight, and leaving it green put a green pixel in the
  middle of a hand. Both are found now; the whole card is 51 pixels of skin.

### Added

- **The naming screen's list.** `field.boot.namePresets.player` reads
  **GREEN / WILD / JACK** where vanilla's reads RED / ASH / JACK. Only
  `player` is named, so the rival's own three survive the deep merge. The
  `DEFAULT NAME GREEN` row is `GREEN NAME LIST` now, and covers both that
  list and the fallback name a save gets when nothing is typed.

### Notes

- Both player portraits the engine has are covered. `Sprites.playerPath`
  resolves exactly two files (`FieldDefaults.PLAYER_PICS`): the back pic,
  `battle/redb.png`, and the front pic, `trainer_card/red.png` — and the
  trainer card, Oak's intro, the Hall of Fame and the credits all draw that
  same front pic. The other four paths in the recipe's list are names an
  import may or may not have written; `ctx.exists` skips them.
- All nine clauses are load-bearing: breaking any one fails the suite.

## [1.9.0] - 2026-08-28

### Fixed

- **The hands and the ear are skin, and the sleeves are not.** Skin on this
  art is not one shade: the face is shade 2 with its brow in shade 3, the
  **hands are shade 3 alone** — the same shade as the trousers and the cap —
  and the ear is one pixel of each. Every rule up to 1.8.0 only ever looked
  at shade 2, so the hands and the ear could not be reached by any of them,
  and the patches those rules did find on the arms were the jacket's own
  sleeve shading.

  Nothing here is decided by size or colour now. The face is the biggest
  patch of shade 2 high in the figure with paper against it; the ear is a
  speck of shade 2 beside its upper half; the hands are small patches of
  shade 3 reaching past the shirt's edge, low enough to be at the hip, and
  ringed by outline. The three things that look exactly like a hand each
  fail one clause: the collar is too high, the shirt's hem has no outline
  round it, and a hole in the shirt is not past its edge.

### Notes

- Checked against the card's real shade map, region by region: face, ear and
  both hands skin; cap shading, jacket shoulder, sleeves, collar, hem,
  trousers and shoes green.
- All seven clauses are load-bearing — breaking any one of them fails the
  suite. The fixture carries a decoy for each.

## [1.8.0] - 2026-08-28

### Fixed

- **`PORTRAIT SKIN` painted a jacket highlight and only half of each hand.**
  1.7.0 separated skin from clothing by size and by how much white was
  against a patch, and that cannot be done. Measured on the real card, the
  jacket's shoulder highlight is 8 pixels with 3 white, 6 outfit and 7 ink
  neighbours; the left hand is 5 with 3, 5 and 4. One pixel apart on every
  count. Any threshold that keeps the hand takes the shoulder.

  It goes by **where things sit** now:

  - the **face** is the biggest patch of shade 2 high in the figure with
    paper against it — the cap's own shading is a solid patch up there and
    bigger than either hand, but it is sealed inside the cap and touches no
    paper at all;
  - the **hands** are the patches beside the *lower half* of the torso, the
    biggest mass of ink in the picture; the jacket's shoulder is beside the
    torso too, but above its middle;
  - the **detail** is small pieces of shade 3 sealed inside skin — the ear,
    the brow, the line of the mouth. Vanilla draws those in the shade below
    the skin's, so painting only shade 2 left green freckles on the face.

### Added

- A second skin colour, `#ad7547`, for that detail. Shade 2 is the light on
  the skin and shade 3 is its shadow; a face needs both.

### Notes

- Checked against the card's real shade map, region by region: face, both
  hands and the ear come out skin; cap, jacket shoulder, collar, brim and
  shoes stay green. All ten labelled regions correct.
- Every clause is load-bearing — removing the paper test, the waist test,
  the hand size floor or the detail pass each fails the suite.

## [1.7.0] - 2026-08-28

### Fixed

- **`PORTRAIT SKIN` never fired.** 1.5.0 looked for the face by the *eyes*
  inside it — a patch of shade 2 enclosing small islands of ink. On the real
  card there are **no** such islands: the art is dithered, and the eyes are
  part of the outline. The rule failed closed on every picture, exactly as
  designed, and the row did nothing.

  The rule now comes from the card's real shade map, read back out of the
  game. Shade 2 there is 128 pixels in 43 pieces and they are three
  different things: the skin (the face at 22px, the hands and forearms at
  11, 8, 6), the shading inside the cap (one solid patch of **19px** —
  bigger than any single hand, so size alone cannot separate them), and
  dither (29 single pixels checkerboarded against shade 3 on the knees and
  shoes).

  So: a patch must be at least six pixels — dither is never that — **and**
  must have at least two white neighbours. Shading sealed inside a garment
  has none at all; the cap's 19px patch has zero, the face has ten, the
  hands three to six. Zero against three is the margin, which is why it is a
  small count rather than a ratio fitted to one picture.

  Run against that real art, the recipe paints 47 pixels: all 22 of the
  face, both hands, and nothing inside the cap.

  Where nothing qualifies the picture still keeps the flat green. The battle
  back pic is expected to be near that case; what faces you there is mostly
  his jacket.

## [1.6.0] - 2026-08-28

### Fixed

- **The title figure's bake never ran, so 1.4.0 changed nothing on screen.**
  It read the art with `Image:getData` — and under LÖVE 11 a graphics
  `Image` does not keep the `ImageData` it was built from and has no
  `getData` at all. The call failed on the first frame, the failure was
  cached, and the figure kept the red bake downstream of it. The wrap was
  fine; the pixels were never reachable.

  They come off a canvas now: the art is drawn into a canvas of its own size
  at the origin and read back. `getData` is still tried first, because where
  it exists it is cheaper and touches no graphics state. Everything the
  readback touches — canvas, blend mode, draw colour, transform stack — is
  put back, because `currentSprite` can be called mid-draw and a canvas left
  behind is a corrupted frame.

  The test stub was the reason this shipped: its fake `Image` had `getData`,
  so it exercised a path the engine does not have. It is the LÖVE 11 shape
  now, with a canvas the readback actually drives, and there is a case for
  the old shape beside it.

### Changed

- The load line names the row states and the prefix the pics are read from
  (`player=GREEN portrait_skin=true ribbon=true -- pics are read from
  assets/generated/greenskin/`), and the title figure says whether it baked
  or could not read the art. 1.4.0 logged `wrapped` and was still red; that
  is the line that was missing.

## [1.5.0] - 2026-08-28

### Added

- **`PORTRAIT SKIN`** — the face on the big pictures is the character's own
  skin (`#f0a363`) instead of the light green, and the cap, the shirt's
  shading and the knees keep the green they have. Those are all the same
  shade, which is why 1.3.0 gave up and went monochrome; nothing about the
  shade can tell them apart.

  What can is what is *inside* the face: it is the only patch of shade 2
  with **eyes** in it — islands of ink whose every neighbour is that one
  patch. The cap's front, the shirt and the knees have nothing inside them,
  and the outline is one ink region that runs off the edge of the art rather
  than an island.

  The rule **fails closed**. Fewer than two eyes, a patch the wrong size, a
  patch too far down the picture, or two patches that both look like a face,
  and nothing is painted — and that picture is exactly the flat green of
  1.4.0. The worst it can do is nothing, never a blotch, which is what makes
  it safe against art this mod never sees. The battle back pic is that case
  by construction: there is no face on the back of his head.

  The recipe writes **both** copies of every portrait, `green/` and
  `greenskin/`, and the row picks between two files that already exist. So
  it is a switch in a menu rather than a recolour that needs a release to
  undo, and where no face was found the two copies are identical.

  Not covered: the title screen's standing figure, which is baked from the
  grey art at draw time rather than read from a file, and keeps the flat
  green.

### Changed

- `main.lua`'s `RECOLOURED` list carries the recipe's `field` flag as well as
  the path, and `tools/check.py` compares both — a picture the two files
  disagree about is a row that silently does nothing on it, or one that
  points at a file that is not there.

## [1.4.0] - 2026-08-28

### Fixed

- **The title screen's standing figure is green under `ADVANCED`.** He had
  stayed red there through every release, and not because of anything the
  palette or the art was doing. `ADVANCED` (`PaletteFX.mode` `redpp`) does
  not run the SGB zone pass over his rectangle, so the `MEWMON` override
  1.1.2 added never reached him — and [Crystal Animated Sprites][crystal],
  which the Wild Green cart pins, marks that rectangle true-colour there and
  luminance-bakes his grey art to Red's own white / skin / red / navy so he
  is not left raw grey. That bake is downstream of every seam this mod had.

  So it now does the same bake in its own four. It wraps
  `TitleState.currentSprite` from outside (priority 1300, loaded last),
  captures the untouched grey art on the way in — before the red bake — and
  paints it white / light green / green / black on the way out, the trainer
  card's ramp. Out of `ADVANCED` it hands the grey art back and `MEWMON` has
  him again, exactly as before.

  This also corrects 1.1.1's note, which is wrong. The white-and-pink figure
  1.1.0 put on screen was that same red bake reading *this mod's* green art —
  the outfit green and the light green both land in its skin bucket — not the
  engine's shade buckets. Swapping the pic was never going to work in that
  mode; running after the bake is what does.

### Changed

- The mod declares one permission, `engine_internals`, and uses it for
  `src.ui.TitleState` and `src.render.PaletteFX` and nothing else. Every step
  of the bake is guarded: without the modules, without `love.graphics`,
  without a clonable `ImageData`, the figure is what it was and the rest of
  the mod is untouched.

[crystal]: https://github.com/distilledorion-sketch/crystal_animated_sprites_with_shiny_visuals

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
