-- Wild Green -- the recipe that turns the player green.
--
-- The player's pictures are the vanilla ones, so this mod may not ship them:
-- derived art travels as a recipe and the pixels come from the player's own
-- imported cache (Guide: Art Pipeline, "The rule").  This file is that
-- recipe.  It runs once on install, and again only when the cache is
-- re-imported or this file changes.
--
-- ------- shade 2 is the face, not the outfit
--
-- The importer decodes vanilla art to four grey shades and the palette pass
-- colours them at draw time.  On the player those four are, in order: the
-- transparent/white ground, the SKIN and the shirt's white, the OUTFIT, and
-- the black outline and hair.
--
-- The first cut of this file recoloured shades 2 and 3 both, on the
-- assumption that everything above black was clothing.  In the field that
-- turned his face green as well -- the whole sprite read as one green blob.
-- Only shade 3 is the outfit.  Shade 2 becomes skin, because under trueColor
-- these pixels are drawn exactly as written and the palette pass is not
-- coming along afterwards to make a face out of grey.
--
-- ------- why it writes to green/ and not over the cache path
--
-- A transform's output shadows the cache by relative path: write
-- "sprites/red.png" and every draw of the player is green, everywhere,
-- always.  That is one line shorter and it takes the PLAYER option away --
-- there would be no red art left to switch back to.
--
-- So the outputs go under a "green/" prefix, which matches nothing the
-- importer writes and therefore shadows nothing.  They are still reachable:
-- Assets.resolve rewrites any "assets/generated/<rel>" through
-- save/mod-derived/<id>/<rel> whether or not the cache has a file there
-- (src/render/Assets.lua, derivedPath).  main.lua points the player's art at
-- "assets/generated/green/..." when the option says GREEN and leaves it
-- alone when it says RED, and both sets exist the whole time.
--
-- ------- the sandbox
--
-- No require, no love, no io, no os.  ctx is the entire surface, so the
-- palette below is a copy of tools/palette.py's rather than an import of
-- it; tools/check.py fails if the two ever disagree.

return function(ctx)
  -- lightest first, which is the order ctx.recolor reads
  local WILD_GREEN = {
    { 0xff, 0xff, 0xff },   -- paper  -- pure white: battle pics matte on it
    { 0xf0, 0xa3, 0x63 },   -- skin   #f0a363  the face and hands
    { 0x65, 0xba, 0x3f },   -- outfit #65ba3f  the cap and clothes
    { 0x00, 0x00, 0x00 },   -- ink    -- outline and hair
  }

  -- Every picture of the player, by its cache-relative path.
  --
  --   sprites/red.png        the overworld walker (SPRITE_RED, 16x96)
  --   sprites/red_bike.png   the same on the BICYCLE, where the import made one
  --   battle/redb.png        the battle back pic, drawn at 2x until "Go!"
  --   trainer_card/red.png   the front pic: Oak's intro, the card, Hall of Fame
  --
  -- The title screen's standing figure is NOT in this list, and cannot be.
  -- TitleState bakes the OBJ palette onto it (Sprites.recolor with
  -- PaletteFX.ogObj) and has no trueColor path for it -- markVisibleTrueColor
  -- explicitly cuts the player's rectangle OUT of the true-colour region, so
  -- the mon behind him keeps its palette.  A recoloured pic handed to that
  -- draw is read back through the shade buckets: the tan skin comes out white
  -- and the green outfit comes out whatever colour index 3 happens to be,
  -- which in the field was pink.  So the title keeps the figure the base game
  -- drew, and the ribbon carries the branding on its own.
  --
  -- The names are the importer's, not this mod's, and a cache that spells one
  -- differently is a cache this mod cannot recolour -- so every candidate is
  -- probed rather than assumed.
  -- The hook in main.lua derives its green path from whatever the engine
  -- hands it, so anything written here is picked up without being named
  -- twice.
  --
  -- The old man's demo back pic (battle/oldmanb.png) is deliberately absent:
  -- he is not the player, and the catch tutorial should not turn green.
  local PICS = {
    "sprites/red.png",
    "sprites/red_bike.png",
    "battle/redb.png",
    "battle/back/redb.png",
    "trainer_card/red.png",
  }

  -- ------- the mouth is not clothing
  --
  -- Red's overworld mouth is one block of the CAP's colour sitting in the
  -- middle of his face, so a flat shade remap paints it green: in the field
  -- that read as green lips.  It cannot be told apart by shade, because it
  -- IS the outfit shade -- only by where it sits.
  --
  -- The rule: a shade-3 pixel with skin on both sides of it in the same row,
  -- within a few pixels, is enclosed by face and is not clothing.  The cap
  -- and the clothes are bounded by black, never by skin, so they are never
  -- caught by it.
  --
  -- ctx has no per-pixel verb, so this reaches for ImageData's own getPixel
  -- and mapPixel on the objects ctx hands over -- the same methods
  -- AssetTransform.recolor uses internally.  That is one step past the
  -- documented surface, so the whole thing is pcall'd: if those methods are
  -- ever not there, the picture falls back to the plain remap and comes out
  -- exactly as 1.1.1 drew it, green mouth and all, rather than not at all.

  local REACH = 3

  local function shadeOf(r)
    if r > 0.83 then return 1 end
    if r > 0.5 then return 2 end
    if r > 0.17 then return 3 end
    return 4
  end

  local function mouthAware(rel)
    local src = ctx.readImage(rel)
    local out = ctx.readImage(rel)
    local w = src:getDimensions()

    local function shadeAt(x, y)
      if x < 0 or x >= w then return nil end
      return shadeOf((src:getPixel(x, y)))
    end

    -- the first shade either side that is not shade 3, within REACH
    local function neighbour(x, y, step)
      for d = 1, REACH do
        local other = shadeAt(x + step * d, y)
        if other == nil or other ~= 3 then return other end
      end
      return nil
    end

    out:mapPixel(function(x, y, r, g, b, a)
      if a == 0 then return r, g, b, a end
      local shade = shadeOf(r)
      local colour = WILD_GREEN[shade]
      if shade == 3 and neighbour(x, y, -1) == 2 and neighbour(x, y, 1) == 2 then
        colour = WILD_GREEN[2]
      end
      return colour[1] / 255, colour[2] / 255, colour[3] / 255, a
    end)
    return out
  end

  for _, rel in ipairs(PICS) do
    -- A cache that does not carry one of these is a cache from a version or
    -- an import that never made it, not a broken install: skip it and leave
    -- that picture as the base game drew it.
    if ctx.exists(rel) then
      local ok, image = pcall(mouthAware, rel)
      if not ok then
        image = ctx.recolor(ctx.readImage(rel), WILD_GREEN)
      end
      ctx.writeImage(image, "green/" .. rel)
    end
  end
end
