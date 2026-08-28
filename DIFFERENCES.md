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

- **The title screen's standing figure stays vanilla.** `TitleState` bakes
  the OBJ palette onto it and cuts its rectangle out of the true-colour
  region so the cycling mon keeps its palette, so there is no seam to hand it
  recoloured art through. The ribbon carries that screen instead.

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
here is read by anything but the renderer, and the mod declares no
`permissions` at all.

## Save data

None. The mod stores nothing in the save; its two rows live in the profile's
mod options like any other. Uninstalling it leaves a save that loads exactly
as it did.
