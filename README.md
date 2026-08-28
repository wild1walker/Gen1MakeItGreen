# Wild Green

**The player wears green, he is called GREEN, and the title screen says so.**
That is the whole mod.

It is the identity half of the [Wild Green][cart] cart: the cart
pins [Gen1WildUI](https://github.com/wild1walker/Gen1WildUI) and
[Gen1WildQOL](https://github.com/wild1walker/Gen1WildQOL) for everything a
playthrough actually does, and this supplies the one thing a pinned mod set
cannot — a game that looks like its own version rather than like Red with
things added.

It works on its own too. Nothing here depends on either bundle.

## What it changes

| | | how |
|---|---|---|
| the overworld walker | `SPRITE_RED`, and the `BICYCLE` sheet where the import wrote one | the `sprites` registry |
| the battle back pic | the one drawn at 2x until "Go!" | the `player.sprite` hook |
| the front pic | Oak's intro, the trainer card, the Hall of Fame | the `player.sprite` hook |
| the title screen | the standing figure, and the version ribbon | `field.boot.title` |
| the default name | `GREEN` where the game offered `RED` | `field.boot.playerName` |

The two battle pics go through the **hook** rather than a registry write, and
that is not a style choice. `Sprites.playerPath` resolves them through
`FieldDefaults.fieldValue`, not `data.field` — so `field:get("playerPics")`
hands back nothing, and a patch built out of it patches nothing at all. That
is what 1.0.0 did, and why the player stayed red everywhere but the
overworld. The hook runs over the already-resolved path, so it needs no guess
about where the vanilla art lives.

The ribbon is one continuous strip reading **WILD GREEN VERSION**, where the
vanilla art is two fragments the title code repositions. It is drawn by
[`tools/make_ribbon.py`](tools/make_ribbon.py) on the importer's four
grey shades, and the green arrives from the `LOGO1` palette this mod
overrides — the SGB palette the title's ribbon band wears.

## The three rows

In the mod manager, or in `OPTION > MODS`:

```
WILD GREEN
  PLAYER              GREEN     <- or RED
  TITLE RIBBON        ON
  DEFAULT NAME GREEN  ON
```

- **`PLAYER`** is the switch back. `RED` gives you the vanilla character
  everywhere — no recolor is applied at all, and the vanilla art was never
  overwritten to begin with. It decides a `sprites` record, which is settled
  at load, so it takes effect on the next launch.
- **`TITLE RIBBON`** is the branding, and it is independent of `PLAYER`.
  Off gives back the imported ribbon and the imported band colour. On, the
  title says `WILD GREEN VERSION` whichever colour the character is —
  that is the game's name, not the character's outfit.
- **`DEFAULT NAME GREEN`** is the name offered before you type one. It has a
  row of its own because it is the one thing here that ends up written into
  a save, and it follows `PLAYER`: switch the character back to red and the
  name goes back with him.

## No green pixel ships

The player's four pictures are the vanilla ones, so this mod may not ship
them ([Art Pipeline](https://github.com/bryanthaboi/gen1recomp/wiki/Guide-Art-Pipeline),
"The rule"). Derived art travels as a recipe, and the pixels come from your
own imported cache. [`transforms.lua`](transforms.lua) is that recipe: it
runs once on install, and again only when the cache is re-imported or the
recipe changes.

Its outputs go under a `green/` prefix rather than over the cache paths they
were read from. Writing `sprites/red.png` would make the player green
everywhere, always, and would take the `PLAYER` row away — there would be no
red art left to switch back to. Under `green/` they shadow nothing, and both
sets exist the whole time; `main.lua` points the records at one or the other.

## The palette

Four colours, in [`tools/palette.py`](tools/palette.py), and the same
four everywhere they appear — the sprite recolor, the ribbon lettering, the
cart's shell and the cart's label:

**The character**, in shade order:

| | | |
|---|---|---|
| paper | `#ffffff` | stays pure white: the battle back pic mattes on it |
| skin | `#f8d8a8` | **the face, and the shirt's white** |
| outfit | `#65ba3f` | the cap and clothes — the reference green |
| ink | `#000000` | outline and hair |

That second row is the one 1.0.0 got wrong. Shade 2 is not clothing; it is
the skin. Recolouring shades 2 and 3 both turns the face green with the cap,
which in the field read as one green blob. Under `trueColor` these pixels are
drawn exactly as written and the palette pass is not coming along afterwards
to make a face out of grey, so shade 2 has to be a skin tone itself.

**The title band** is lettering on white, not a sprite, so it gets its own —
and both greens are dark enough to read as ink at 8px, which the character's
light green was not:

| | | |
|---|---|---|
| mid | `#2e8b3a` | the lettering's shadow |
| ink | `#14571f` | the `VERSION` lettering, **and the cartridge shell** |

They are written out three times — once in Python, twice in Lua — because
none of the three can import from the others: the transform runs in a sandbox
with no `require`, an entry chunk cannot require its own files, and the tools
are Python. [`tools/check.py`](tools/check.py) fails the build if they drift
apart.

`tools/palette.py` and `tools/ribbon.py` are carried in the [cart's repo][cart]
too, because the cartridge's shell and the label's version line are drawn from
the same four numbers and the same 5×7 face. Change one, change both.

## Alongside other mods

`crystal_animated_sprites_with_shiny_visuals` is an optional dependency, not
a fork. It ships its own player portraits and its own `PLAYER SPRITE` row;
this mod does not touch them, and with both installed you get its Crystal
artwork with this mod's overworld and title work around it.

More generally, a walker whose art is not the vanilla path is left where it
points. If another mod has already reskinned the player, this one declines
rather than fighting it.

## Tests

```sh
python3 tools/check.py             # the palettes agree, the ribbon is current
luajit tests/wild_green_test.lua   # what the mod actually does
```

Stands up the loader's `mod` table and the asset sandbox's `ctx`, runs the
real files against them, and checks everything settled before a pixel is
drawn — including that `PLAYER = RED` writes no character patch at all.

## Credits

- **distilledorion-sketch** — [Crystal Animated Sprites with Shiny
  Visuals](https://github.com/distilledorion-sketch/crystal_animated_sprites_with_shiny_visuals),
  which this is meant to sit beside rather than replace.
- **Gen1Recomp** — the mod API, the asset-transform sandbox this recolor runs
  in, and the title screen it draws on.
- **pret** — the disassemblies underneath all of it.

## Licence

MIT, same as the rest of the suite. See [LICENSE](LICENSE).

[cart]: https://github.com/wild1walker/Gen1WildGreen
