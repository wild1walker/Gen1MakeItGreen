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
| the credits and intro pics | where the import wrote them | the `player.sprite` hook |
| the title screen | the version ribbon | `field.boot.title` |
| the title figure | the standing player on that screen | the `MEWMON` palette, and a bake of its own under `ADVANCED` |
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

## The four rows

In the mod manager, or in `OPTION > MODS`:

```
WILD GREEN
  PLAYER              GREEN     <- or RED
  PORTRAIT SKIN       ON
  TITLE RIBBON        ON
  TITLE FIGURE        ON
  DEFAULT NAME GREEN  ON
```

- **`PLAYER`** is the switch back. `RED` gives you the vanilla character
  everywhere — no recolor is applied at all, and the vanilla art was never
  overwritten to begin with. It decides a `sprites` record, which is settled
  at load, so it takes effect on the next launch.
- **`PORTRAIT SKIN`** paints the face on the big pictures — the battle back
  pic, the trainer card, Oak's intro, the credits, the Hall of Fame — the
  character's own skin instead of the light green. Off is the flat green
  those pictures wore in 1.4.0. It has a row of its own because the rule
  that finds the face is a guess about art this mod never sees; see below.
- **`TITLE RIBBON`** is the branding, and it is independent of `PLAYER`.
  Off gives back the imported ribbon and the imported band colour. On, the
  title says `WILD GREEN VERSION` whichever colour the character is —
  that is the game's name, not the character's outfit.
- **`TITLE FIGURE`** colours the standing player on the title screen. In
  most display modes that is the `MEWMON` zone palette, which takes the
  `GAME FREAK` line with it — see below for why the two cannot be separated.
  Under `ADVANCED` the zone pass does not reach him at all and he is baked
  instead, so there the copyright line is untouched. Off gives that screen
  back to the base game either way.
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

The recipe and the hook name the **same eight pictures**, in the same order,
and `tools/check.py` fails the build if they drift apart. That is not
tidiness: a swap to a green file the recipe never wrote does not fall back to
the red one — the image fails to load and the draw shows nothing at all.

Its outputs go under a `green/` prefix rather than over the cache paths they
were read from. Writing `sprites/red.png` would make the player green
everywhere, always, and would take the `PLAYER` row away — there would be no
red art left to switch back to. Under `green/` they shadow nothing, and both
sets exist the whole time; `main.lua` points the records at one or the other.

## The palette

Four colours, in [`tools/palette.py`](tools/palette.py), and the same
four everywhere they appear — the sprite recolor, the ribbon lettering, the
cart's shell and the cart's label:

**The overworld character**, in shade order:

| | | |
|---|---|---|
| paper | `#ffffff` | stays pure white: the battle back pic mattes on it |
| skin | `#f0a363` | **the face and hands** — sampled off the reference sprite |
| outfit | `#65ba3f` | the cap and clothes — the reference green |
| ink | `#000000` | outline and hair |

and two colours that are not shades at all:

| | | |
|---|---|---|
| mouth | `#ec4d29` | the lips — vanilla's own, sampled off red Red |
| bill | `#e6f4dc` | the cap's bill — a green-tinted white |

**The trainer art** — the battle back pic, and the front pic Oak's intro,
the trainer card and the Hall of Fame share — takes a different four, because
shade 2 does not mean the same thing there:

| | | |
|---|---|---|
| paper | `#ffffff` | |
| light | `#a8dd8a` | the light for **everything**: the cap's front, the shirt's shading, the knees |
| outfit | `#65ba3f` | |
| ink | `#000000` | |

On the 16×16 sprite shade 2 is only ever the face. On the 56×56 portrait it
is the light on every surface. Vanilla gets away with one shade for both
because its ramp is monochrome red — white, light red, red, black — and light
red happens to look like skin; painting that shade a skin tone put orange
blotches on the hat and the knees. The portrait gets the same trick in green,
and neither of the overworld position rules, because a face-sized rule on
face-sized art is noise.

### Finding the face by what is inside it

Which leaves the face reading as a pale green rather than as skin — and
`PORTRAIT SKIN` is the way out of that compromise. Nothing about the *shade*
can pick the face out, because the shade is the light on every surface. What
can is what is **inside** it: the face is the only patch of shade 2 with
**eyes** in it — islands of ink whose every neighbour is that one patch. The
cap's front, the shirt's shading and the knees have nothing inside them at
all, and the outline is one ink region that runs off the edge of the art
rather than an island.

The rule **fails closed**, on purpose. Fewer than two eyes, a patch the wrong
size, a patch too far down the picture, or *two* patches that both look like
a face, and it paints nothing — and that picture is the flat green of 1.4.0.
The worst it can do is nothing, never a blotch, which is what makes it safe
to ship against art this file never sees. The battle back pic is exactly that
case: there is no face on the back of his head to find.

The recipe writes **both** copies of every portrait — `green/` and
`greenskin/` — and the row picks between two files that already exist, rather
than deciding a recolour. That is what makes it a switch you can flip in a
menu instead of one that needs a release to undo. Where the rule found no
face the two copies are identical, so the row is a no-op on that picture
rather than broken.

The title screen's standing figure is not covered by it: that one is baked
from the grey art at draw time (see below), not read from a file, and it
keeps the flat green.

That second row is the one this mod got wrong twice. Shade 2 is not clothing;
it is the skin. 1.0.0 recoloured shades 2 and 3 both, which turned the face
green with the cap and read as one green blob. 1.1.0 made it `#f8d8a8` and
the face read as a washed-out cream nothing. Under `trueColor` these pixels
are drawn exactly as written and no palette pass follows to make a face out
of them, so shade 2 has to be a real skin tone — and the one that works is
the one measured off the reference, not the one picked from the middle of
the ramp.

### The title figure is coloured, not recoloured

`markVisibleTrueColor` cuts the player's rectangle *out* of the true-colour
region on purpose, so the mon cycling behind him keeps its palette. What is
left is painted **by shade**, and the colour a file carries is thrown away
before it reaches the screen. Handing that draw recoloured art does nothing;
it has to be coloured at the other end.

So the figure keeps the vanilla grey art and **`MEWMON`**, its zone palette,
is overridden instead. That zone is tile rows 10–17, which is not free:

- The **`GAME FREAK` line goes green** with him. That is the cost.
- The **cycling Pokémon is untouched** while its art is true-colour, because
  `markVisibleTrueColor` marks the mon and cuts the figure out of it — the
  palette reaches one and not the other. That holds with any sprite mod on,
  including the one the cart pins. Switch them all off and the title mon
  goes green too, which is what the `TITLE FIGURE` row is for.

### …except under `ADVANCED`, where he is baked

`ADVANCED` (`PaletteFX.mode` `redpp`) does not run the zone pass over that
rectangle, so `MEWMON` never reaches him — and the cart's own
[Crystal Animated Sprites][crystal] marks the rectangle true-colour there
and luminance-bakes his grey art to Red's white / skin / red / navy, so he
is not left raw grey. That bake is downstream of every seam this mod has,
which is why the figure stayed red on that screen through 1.3.0 no matter
what was done to the art or the palette.

1.4.0 does the same bake in this mod's four. It wraps
`TitleState.currentSprite` from *outside* — this mod is priority 1300 and
loads last, so its wrapper goes on over theirs — captures the untouched grey
art on the way in, before the red bake happens, and paints that green on the
way out, in the same white / light green / green / black the trainer card
uses. Out of `ADVANCED` it hands the grey art back and `MEWMON` has him
again.

It is the mod's one engine internal, and the reason it declares
`engine_internals`. Every step of it is guarded: without the module, without
`love.graphics`, without a clonable `ImageData`, the figure is exactly what
it was before, and nothing else in the mod is affected.

[crystal]: https://github.com/distilledorion-sketch/crystal_animated_sprites_with_shiny_visuals

### The mouth is not clothing, and the bill is not skin

Red's overworld mouth is one block of the *cap's* colour sitting in the
middle of his face, so a flat shade remap paints it with the clothes — green
lips. It cannot be told apart by shade, because it is the same shade; only by
where it sits. A shade-3 pixel with skin on both sides of it in the same row
is enclosed by face and is not clothing, so it is painted in the lips'
colour instead. That colour is vanilla's own: Red's mouth is drawn in the
*cap's* shade, which is why it comes out red and reads as lips at all.
Painting it skin, as 1.1.2 did, does not fix it so much as delete it. The cap
and the clothes are bounded by black, never by skin, so they are never caught
by the rule.

The bill of the cap is the same problem the other way round. Vanilla draws it
in the *face's* shade — on red Red the bill and the face are the same colour
and nobody notices, but put a green cap above it and the hat reads as having
no bill. A shade-2 pixel sitting directly under a shade-3 one is the bill,
and it goes with the hat.

It is found by **region**: a small patch of the face's shade, touching the
cap, high in its frame. All three, because any two of them catch something
else — small-and-touching is also the hands, touching-and-high is also the
top of the face, small-and-high is whatever else is up there.

And it is painted a green-tinted white rather than the cap's green. Vanilla's
own colour reads as nothing; the cap's green merges it into the hat. This
gives it an edge against both.

The rule runs on the overworld sheets only, where the frames really are a
16px stack and the cap is a handful of pixels. On the 56×56 trainer card
there are dozens of small shade-2 regions touching shade 3 that are shading
rather than a bill.

### The hook has to sit at priority 940

`Hooks:call` walks the chain **highest priority first**, and a link that
returns without calling `next()` ends the chain there. [Crystal Animated
Sprites][crystal] wraps `player.sprite` at **930** and does exactly that:
when its `PLAYER SPRITE` option names a portrait it returns its own file and
never calls `next()`.

At the default priority of `0` this mod's link sat downstream of a chain that
never reached it, which is why the battle back pic, the trainer card, Oak's
intro and the Hall of Fame stayed red through every release from 1.0.0 to
1.1.4. It wraps at **940** now, and computes the swap from the path it is
handed rather than from what downstream answers.

The cost belongs to the `PLAYER` row: on `GREEN` a portrait chosen in
`CRYSTAL SPRITES > PLAYER SPRITE` no longer applies to the player. `RED`
hands it back. Opponent portraits, the animated battle sprites and the shiny
work are untouched either way — this link only ever answers for the player.

[crystal]: https://github.com/distilledorion-sketch/crystal_animated_sprites_with_shiny_visuals

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
