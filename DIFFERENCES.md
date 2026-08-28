# Differences from vanilla

In the format of the engine's `docs/known-differences.md`. The base game's
own ledger stays "None currently"; these are this mod's divergences.

## Art

- **The player wears green.** The overworld walker, the `BICYCLE` sheet where
  the import wrote one, the battle back pic, the front pic that Oak's intro,
  and the trainer card and the Hall of Fame share are recolored from the player's own imported cache to the Wild
  Green ramp. Only the outfit shade changes: the face keeps a skin tone and
  the hair and outline stay black. `PLAYER = RED` turns all of it off.
- **The default name is `GREEN`**, where the game offered `RED`. It is the
  only thing here that ends up written into a save, and it has its own row.
- **The title screen reads `WILD GREEN VERSION`.** One continuous ribbon in
  place of the imported pair of fragments. `TITLE RIBBON = OFF` gives back
  the imported art.
- **`LOGO1` is overridden** to the Wild Green ramp. It is the SGB palette the
  title's version-ribbon band wears, and the title screen is the only thing
  that reads it.

## Known limits

- **On `PLAYER = GREEN` the player's portrait is this mod's, not Crystal
  Animated Sprites'.** That mod wraps `player.sprite` at priority 930 and
  short-circuits the chain; this one wraps at 940 to get in front of it, so a
  portrait chosen in `CRYSTAL SPRITES > PLAYER SPRITE` does not reach the
  player. `PLAYER = RED` hands it back. Nothing else of that mod's is
  affected: opponent portraits, the animated battle sprites and the shiny
  reveal all go through other seams.

- **The title screen's standing figure is coloured, never swapped.** His
  rectangle is cut out of the true-colour region so the cycling mon keeps its
  palette, and what is left is painted by shade — so recoloured art handed to
  that draw is thrown away. `MEWMON` colours him in every mode that runs the
  zone pass, and `TITLE FIGURE` switches that off.

- **Under `ADVANCED` he is baked, not palettised, and that is Crystal
  Animated Sprites' rectangle.** That mode does not run the zone pass over
  him, and the pinned mod marks his rectangle true-colour there and bakes his
  grey art to Red's own white / skin / red / navy. This mod wraps
  `TitleState.currentSprite` outside that wrapper — it is priority 1300 and
  loads last — and re-bakes from the grey art it captured on the way in, in
  the trainer card's white / light green / green / black. Turn Crystal
  Animated Sprites off and `ADVANCED` still gets the green bake; turn
  `TITLE FIGURE` off and neither happens.

- **`PORTRAIT SKIN` finds the skin by size and by white.** Shade 2 on the
  big pictures is three things at once: the skin, the shading inside a
  garment, and checkerboard dither. A patch under six pixels is dither; a
  patch with no white anywhere against it is a garment's own shading — the
  cap's is a solid 19 pixels with zero paper neighbours, bigger than any
  single hand, which is why size alone will not do it. What is left is the
  face and the hands. Where nothing qualifies, that picture keeps the flat
  green; the battle back pic is expected to be near that case. The title
  screen's standing figure is baked at draw time rather than read from a
  file, so it keeps the flat green either way.

- **The green band is a registry record only under SGB.** `PaletteFX.pal`
  (`src/render/PaletteFX.lua`) short-circuits every named palette to the
  boot-ROM pair under `OG RED`, and reads `data/palettes_gbc` under
  `ADVANCED`. In those two display modes the ribbon band keeps that mode's
  own colour, so the lettering still says `WILD GREEN VERSION` but is drawn
  in red. Nothing a mod can reach decides those two.
- **The recolored art is true-colour.** `trueColor` is what keeps the
  overworld's OBP bake from reading our green through the shade buckets it
  reads grey art through. The mono and inverted display modes do not honour
  `trueColor` (`PaletteFX.honorsTrueColor`), so there the player falls back
  to the baked ramp like any other sprite.
- **`PLAYER` takes effect on the next launch** for the overworld walker,
  which is a `sprites` record and settled at load. The battle and card pics
  ride the `player.sprite` hook and change as soon as the pic is re-resolved.
- **The default name only reaches a new game.** A save that already has a
  name keeps it, which is the point.
- **A cache without one of the five pictures leaves that picture alone.**
  The recipe skips what `ctx.exists` says is not there, and `main.lua` only
  repoints a record whose art it actually recolored — so a partial import
  degrades one picture at a time instead of drawing nothing.

## Not changed

No map, script, encounter, trainer, item, move or battle behaviour. Nothing
here is read by anything but the renderer. The mod declares one permission,
`engine_internals`, and uses it for exactly one thing: `src.ui.TitleState`
and `src.render.PaletteFX`, to bake the title figure green under `ADVANCED`.
Nothing else in the mod touches an engine module.

## Save data

None. The mod stores nothing in the save; its two rows live in the profile's
mod options like any other. Uninstalling it leaves a save that loads exactly
as it did.
