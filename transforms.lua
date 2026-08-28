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

  -- Not a shade.  Red's lips are drawn in the CAP's shade, so in vanilla they
  -- come out the same red as his hat -- which is why they read as lips at all.
  -- 1.1.2 turned them skin and they vanished; this is vanilla's own colour,
  -- sampled off red Red, so they read as lips on a green hat too.
  local MOUTH = { 0xec, 0x4d, 0x29 }

  -- Nor is this.  The bill is drawn in the FACE's shade, so on red Red it is
  -- the same colour as his cheek and reads as nothing at all -- and painting
  -- it the cap's green just merged it into the hat.  A green-tinted white
  -- gives it back its own edge against both.
  local BILL = { 0xe6, 0xf4, 0xdc }

  -- The trainer art takes a DIFFERENT four, because shade 2 does not mean
  -- the same thing there.
  --
  -- On the 16x16 overworld sprite shade 2 is only ever the face.  On the
  -- 56x56 portrait it is the LIGHT for everything: the cap's front, the
  -- shading on the shirt, the highlight on the knees and the shoes.  Vanilla
  -- gets away with one shade for both because its ramp is monochrome red --
  -- white, light red, red, black -- and light red happens to look like skin.
  -- Painting that shade a skin tone put orange blotches on the hat and the
  -- knees, and the mouth rule speckled red over the rest.
  --
  -- So the portrait gets the same trick in green, and neither of the
  -- position rules: a face-sized rule on face-sized art is noise.
  local WILD_GREEN_PIC = {
    { 0xff, 0xff, 0xff },
    { 0xa8, 0xdd, 0x8a },
    { 0x65, 0xba, 0x3f },
    { 0x00, 0x00, 0x00 },
  }

  -- Every picture of the player this recipe knows how to recolour, and the
  -- ONLY ones main.lua will swap: the hook checks this same list, so it can
  -- never point a draw at a green file the recipe did not write.  The two
  -- copies are compared by tools/check.py.
  --
  --   sprites/red.png        the overworld walker (SPRITE_RED, 16x96)
  --   sprites/red_bike.png   the same on the BICYCLE
  --   battle/redb.png        the battle back pic, drawn at 2x until "Go!"
  --   trainer_card/red.png   the front pic Oak's intro, the card and the
  --                          Hall of Fame share
  --
  -- The rest are names an import may or may not have written; ctx.exists
  -- decides, and a cache without one simply keeps that picture as the base
  -- game drew it.
  --
  -- Two absences are deliberate.  The old man's demo back pic
  -- (battle/oldmanb.png) is not the player, and the catch tutorial should
  -- not turn green.  And the title screen's standing figure has no seam:
  -- TitleState bakes the OBJ palette onto it and cuts its rectangle out of
  -- the true-colour region so the mon behind it keeps its palette, so
  -- recoloured art handed to that draw comes back through the shade buckets
  -- -- white and pink, in the field.  main.lua colours it through MEWMON
  -- instead.
  --
  -- `field` picks the ramp: true takes the overworld four and the mouth and
  -- bill rules, false takes the portrait four and neither.
  local PICS = {
    { "sprites/red.png", true },
    { "sprites/red_bike.png", true },
    { "battle/redb.png", false },
    { "battle/back/redb.png", false },
    { "trainer_card/red.png", false },
    { "credits/red.png", false },
    { "intro/red.png", false },
    { "hall_of_fame/red.png", false },
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

  -- The bill is a SMALL patch of the face's shade, TOUCHING the cap, HIGH in
  -- its frame.  All three, because any two of them catch something else:
  --
  --   * small and touching clothing is also the HANDS, which sit beside the
  --     body lower down -- so the height matters;
  --   * touching and high is also the top of the FACE in some frames -- so
  --     the size matters;
  --   * small and high is also whatever else the cap has around it -- so the
  --     touching matters.
  --
  -- 1.1.3 looked only directly above a pixel and missed the profile frames,
  -- where the bill sticks out beside the cap rather than under it.  Region
  -- and neighbourhood, rather than one direction, is what covers all six
  -- frames of a walker sheet.
  local BILL_MAX = 8

  -- The overworld sheets are 16x16 frames stacked into one column (Art
  -- Pipeline: "Overworld character sprites").  The cap and its bill live in
  -- the top half of a frame; the hands are below it.
  local FRAME, BILL_ROWS = 16, 8

  local function shadeOf(r)
    if r > 0.83 then return 1 end
    if r > 0.5 then return 2 end
    if r > 0.17 then return 3 end
    return 4
  end

  local STEPS = { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }

  local function recoloured(rel, field)
    local ramp = field and WILD_GREEN or WILD_GREEN_PIC
    local bill = field
    local src = ctx.readImage(rel)
    local out = ctx.readImage(rel)
    local w, h = src:getDimensions()

    -- every pixel's shade up front: the rules below ask about neighbours, and
    -- reading them back out of the image being written would see its own work
    local shade = {}
    for y = 0, h - 1 do
      shade[y] = {}
      for x = 0, w - 1 do
        local r, _, _, a = src:getPixel(x, y)
        shade[y][x] = (a == 0) and 0 or shadeOf(r)
      end
    end

    local function shadeAt(x, y)
      if x < 0 or x >= w or y < 0 or y >= h then return nil end
      return shade[y][x]
    end

    -- the first shade either side that is not shade 3, within REACH
    local function beside(x, y, step)
      for d = 1, REACH do
        local other = shadeAt(x + step * d, y)
        if other == nil or other ~= 3 then return other end
      end
      return nil
    end

    -- flood the shade-2 regions; the small ones that touch the cap are bill
    local isBill = {}
    if bill and h % FRAME == 0 then
      local seen = {}
      local function mark(x, y)
        seen[y] = seen[y] or {}
        if seen[y][x] then return false end
        seen[y][x] = true
        return true
      end
      for y = 0, h - 1 do
        for x = 0, w - 1 do
          if shade[y][x] == 2 and mark(x, y) then
            local stack, region, touchesCap = { { x, y } }, {}, false
            while #stack > 0 do
              local at = table.remove(stack)
              region[#region + 1] = at
              for _, step in ipairs(STEPS) do
                local nx, ny = at[1] + step[1], at[2] + step[2]
                local s = shadeAt(nx, ny)
                if s == 3 then
                  touchesCap = true
                elseif s == 2 and mark(nx, ny) then
                  stack[#stack + 1] = { nx, ny }
                end
              end
            end
            local high = true
            for _, at in ipairs(region) do
              if at[2] % FRAME >= BILL_ROWS then high = false break end
            end
            if touchesCap and high and #region <= BILL_MAX then
              for _, at in ipairs(region) do
                isBill[at[2]] = isBill[at[2]] or {}
                isBill[at[2]][at[1]] = true
              end
            end
          end
        end
      end
    end

    out:mapPixel(function(x, y, r, g, b, a)
      if a == 0 then return r, g, b, a end
      local s = shade[y][x]
      local colour = ramp[s]
      if not field then
        -- the portrait: the ramp and nothing else
      elseif s == 3 and beside(x, y, -1) == 2 and beside(x, y, 1) == 2 then
        -- a mouth: the outfit's shade, but enclosed by face
        colour = MOUTH
      elseif s == 2 and isBill[y] and isBill[y][x] then
        colour = BILL
      end
      return colour[1] / 255, colour[2] / 255, colour[3] / 255, a
    end)
    return out
  end

  for _, entry in ipairs(PICS) do
    local rel, field = entry[1], entry[2]
    -- A cache that does not carry one of these is a cache from a version or
    -- an import that never made it, not a broken install: skip it and leave
    -- that picture as the base game drew it.
    if ctx.exists(rel) then
      local ok, image = pcall(recoloured, rel, field)
      if not ok then
        -- the per-pixel path is one step past the documented ctx, so its
        -- absence costs the position rules and nothing else
        image = ctx.recolor(ctx.readImage(rel),
          field and WILD_GREEN or WILD_GREEN_PIC)
      end
      ctx.writeImage(image, "green/" .. rel)
    end
  end
end
