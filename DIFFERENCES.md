# Differences from vanilla

In the format of the engine's `docs/known-differences.md`. The base game's
own ledger stays "None currently"; these are this mod's divergences.

## Art

- **The player wears green.** The overworld walker, the `BICYCLE` sheet where
  the import wrote one, the battle back pic, the front pic that Oak's intro,
  the trainer card and the Hall of Fame share, and the title screen's
  standing figure are recolored from the player's own imported cache to the
  Wild Green ramp. `PLAYER = RED` turns all of it off.
- **His skin is skin.** On the overworld sheets the face keeps a tan, the
  lips keep vanilla's red and the cap's bill is a green-tinted white. On the
  big pictures `PORTRAIT SKIN` finds the face, the ear, the temple and both
  hands — see the note below for how, since none of it is decided by shade.
- **The names are `GREEN`.** The name a save gets when you type none, and the
  list on the naming screen's `NEW NAME` page: `GREEN / WILD / JACK` where
  the game offered `RED / ASH / JACK`. The rival's three are untouched. It is
  the only thing here that ends up written into a save, and it has its own
  row.
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

- **The title screen's standing figure is coloured in most modes and swapped
  in one.** His rectangle is cut out of the true-colour region so the cycling
  mon keeps its palette, and what is left is painted by shade — so a
  recoloured file handed to that draw is thrown away, and `MEWMON` is what
  colours him. `TITLE FIGURE` switches that off.

- **Under `ADVANCED` he is drawn from a file, and that is Crystal Animated
  Sprites' rectangle.** That mode does not run the zone pass over him, and
  the pinned mod marks his rectangle true-colour there and bakes his grey art
  to Red's own white / skin / red / navy. This mod wraps
  `TitleState.currentSprite` outside that wrapper — it is priority 1300 and
  loads last — **and `TitleState.draw` as well**, because the draw reads
  `self.player` into a local before it calls `currentSprite`, and skips
  `currentSprite` entirely for one phase of the title's animation. Both the
  picture and the true-colour mark on its rectangle come from that draw for
  that reason: unmarked, the zone pass repaints the rectangle by shade, and
  under `ADVANCED` that is `MEWMON` out of `data/palettes_gbc` — a purple
  figure, whatever image is underneath. It hands
  the draw the recipe's own copy of
  `assets/generated/title/player.png`, which carries the same face, ear and
  hands the trainer card gets. `TitleState` keeps the path it loaded him
  from, so the twin is derived from that rather than guessed, and
  `Assets.image` resolves it through `save/mod-derived`. A cache with no such
  file falls back to a flat luminance bake. Turn Crystal Animated Sprites off
  and `ADVANCED` still gets the green figure; turn `TITLE FIGURE` off and
  neither happens.

- **`PORTRAIT SKIN` reaches two shades, because skin is drawn in two.** The
  face is shade 2 with its brow in shade 3; the hands are shade 3 alone, the
  same shade as the trousers and the cap; the ear is one pixel of each.
  Nothing is decided by size or colour — the face is the biggest patch of
  shade 2 high in the figure with paper against it, the ear is a speck beside
  its upper half, and the hands are small patches of shade 3 reaching past
  the shirt's edge at hip height and ringed by outline. The cap's shading,
  the jacket's shoulder and sleeves, the collar and the shirt's hem each fail
  one of those and stay green. No face found and nothing is painted at all.
  The battle back pic is that case, and is painted from a table of its own
  instead: there is no face on the back of his head, and the back of his hand
  is drawn in the paper shade, which no rule here touches. Under `ADVANCED` the title
  screen's standing figure is drawn from the recipe's own copy of that
  picture, so he gets the same face, ear and hands; in every other mode his
  rectangle is painted by shade and `MEWMON` colours him flat.

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
- **…except in the dark, where he gives the exemption up.** The palette pass
  `trueColor` opts out of is also what blacks out an unlit cave — Rock Tunnel
  and the other unlit floors arm PaletteFX's dark shift, and the engine
  exempts a true-colour sprite from the whole thing. So the one sprite that
  opted out of being *recoloured* had also opted out of being *blacked out*,
  and the green player walked through Rock Tunnel lit up beside a screenful of
  silhouettes.

  In an unlit frame the flag is dropped for the length of the draw and the
  engine's own path bakes the sheet through `PaletteFX.dmgObj()`, which is
  already the darkened `OBP0` there. He is the same silhouette, in the same
  shade, as a player who is not wearing green. It costs nothing because the
  recipe already keeps the green bucketing onto the engine's four shades the
  way the vanilla art did — the bake was never garbage, and an unlit map has
  no colour to keep.

  Only this mod's own art. A walker another mod reskinned is that mod's to
  darken; [Crystal Animated Sprites][crystal] sets `trueColor` on its own
  overworld sheets and glows in the same caves for the same reason.
- **A new version takes effect on the next launch.** Mods are loaded once,
  at boot, so a version installed over a running game leaves the previous one
  running until you restart. On the launch after that everything is current:
  the title draw keeps asking for the recipe's copy of the figure while it
  hasn't got one, rather than settling on the flat bake, because the
  transform writes its pictures at install time and that screen is drawn very
  early.

- **`PLAYER` takes effect on the next launch** for the overworld walker,
  which is a `sprites` record and settled at load. The battle and card pics
  ride the `player.sprite` hook and change as soon as the pic is re-resolved.
- **The default name only reaches a new game.** A save that already has a
  name keeps it, which is the point.
- **A cache without one of the pictures leaves that picture alone.**
  The recipe skips what `ctx.exists` says is not there, and `main.lua` only
  repoints a record whose art it actually recolored — so a partial import
  degrades one picture at a time instead of drawing nothing.

## Not changed

No map, script, encounter, trainer, item, move or battle behaviour. Nothing
here is read by anything but the renderer. The mod declares one permission,
`engine_internals`, and uses it for the title screen's figure under
`ADVANCED` and nothing else: `src.ui.TitleState` to get in front of the draw,
`src.render.PaletteFX` to know the mode and mark the rectangle, and
`src.render.Assets` to resolve a generated path to the file a transform
wrote. Nothing else in the mod touches an engine module.

## Save data

None. The mod stores nothing in the save; its five rows live in the
profile's mod options like any other. Uninstalling it leaves a save that loads exactly
as it did.

[crystal]: https://github.com/distilledorion-sketch/crystal_animated_sprites_with_shiny_visuals
