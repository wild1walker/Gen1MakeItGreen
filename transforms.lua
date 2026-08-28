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
  -- not turn green.  And the title screen's standing figure is not swapped
  -- either: his rectangle is cut out of the true-colour region so the mon
  -- cycling behind him keeps its palette, and what is left is painted by
  -- shade -- by the SGB zone pass in most modes, and by another mod's
  -- luminance bake under REDPP.  Either way the colour a recoloured file
  -- carries is thrown away before it reaches the screen.  main.lua colours
  -- him through MEWMON and, under REDPP, through a bake of its own.
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

  -- ------- the skin on a portrait, which shade 2 alone cannot tell you
  --
  -- Shade 2 on the trainer art is the light for more than one thing, which
  -- is why 1.2.0's flat skin tone put orange on the cap and why 1.3.0 gave
  -- up and went monochrome.  Measured off the real art -- the card's shade
  -- map read back out of the game -- it is 128 pixels in 43 separate
  -- pieces, and they are three different things:
  --
  --   * the SKIN.  A few solid patches: the face (22px), and the hands and
  --     forearms (11, 8, 6).
  --   * the SHADING INSIDE A GARMENT.  One solid patch of 19px in the top
  --     of the cap -- bigger than any single hand, so size alone cannot
  --     tell them apart.
  --   * DITHER.  Twenty-nine single pixels and a dozen pairs, checkerboarded
  --     against shade 3 to make a mid-tone on the knees and the shoes.
  --
  -- Two rules, and between them they separate all three:
  --
  --   size    dither is a checkerboard, so its pieces are 4-connected
  --           regions of one or two pixels.  Nothing under SKIN_MIN is skin.
  --   paper   shading inside a garment is bounded by that garment and its
  --           outline and touches no white AT ALL -- the cap's 19px patch
  --           has zero paper neighbours.  Skin sits at the silhouette or
  --           against the shirt's white: the face has 10, the hands 3 to 6.
  --
  -- The margin between them on the real art is 0 against 3, which is why
  -- the threshold is a small number rather than a ratio fitted to it.
  --
  -- Where nothing qualifies, nothing is painted and the picture is the
  -- monochrome green -- the battle BACK pic is expected to be close to that
  -- case, since most of what faces you there is his jacket.
  local SKIN_MIN = 6      -- smaller than this is dither, not a limb
  local SKIN_MAX = 400    -- bigger than this is not skin either
  local SKIN_PAPER = 2    -- white neighbours: a garment's own shading has 0

  local function skinMask(shade, w, h)
    -- label every patch of shade 2
    local region, regions = {}, {}
    for y = 0, h - 1 do region[y] = {} end
    for y = 0, h - 1 do
      for x = 0, w - 1 do
        if shade[y][x] == 2 and not region[y][x] then
          local id = #regions + 1
          local pixels, stack = {}, { { x, y } }
          region[y][x] = id
          while #stack > 0 do
            local at = table.remove(stack)
            pixels[#pixels + 1] = at
            for _, step in ipairs(STEPS) do
              local nx, ny = at[1] + step[1], at[2] + step[2]
              if nx >= 0 and nx < w and ny >= 0 and ny < h
                  and shade[ny][nx] == 2 and not region[ny][nx] then
                region[ny][nx] = id
                stack[#stack + 1] = { nx, ny }
              end
            end
          end
          regions[id] = pixels
        end
      end
    end

    local mask, found = {}, false
    for _, pixels in ipairs(regions) do
      if #pixels >= SKIN_MIN and #pixels <= SKIN_MAX then
        local paper = 0
        for _, at in ipairs(pixels) do
          for _, step in ipairs(STEPS) do
            local nx, ny = at[1] + step[1], at[2] + step[2]
            if nx >= 0 and nx < w and ny >= 0 and ny < h
                and shade[ny][nx] == 1 then
              paper = paper + 1
            end
          end
        end
        if paper >= SKIN_PAPER then
          found = true
          for _, at in ipairs(pixels) do
            mask[at[2]] = mask[at[2]] or {}
            mask[at[2]][at[1]] = true
          end
        end
      end
    end
    if not found then return nil end
    return mask
  end

  local function recoloured(rel, field, face)
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

    -- only asked for on the skinned copy of a portrait; nil is the answer
    -- that leaves the picture monochrome
    local skin = (not field) and face and skinMask(shade, w, h) or nil

    out:mapPixel(function(x, y, r, g, b, a)
      if a == 0 then return r, g, b, a end
      local s = shade[y][x]
      local colour = ramp[s]
      if not field then
        -- the portrait: the ramp, and the face if one was found
        if skin and skin[y] and skin[y][x] then colour = WILD_GREEN[2] end
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

      -- A second copy of every portrait with the face painted skin, which is
      -- what the PORTRAIT SKIN row picks between.  Two files rather than one
      -- decided here, because the recipe runs at install and never sees the
      -- options -- and because it makes the rule something a player can turn
      -- off in a menu rather than something that needs a release to undo.
      --
      -- When the rule finds no face the two copies are identical, so the row
      -- is a no-op on that picture rather than broken.  The battle BACK pic
      -- is exactly that case: there is no face on it to find.
      if not field then
        local okSkin, skinned = pcall(recoloured, rel, field, true)
        ctx.writeImage(okSkin and skinned or image, "greenskin/" .. rel)
      end
    end
  end
end
