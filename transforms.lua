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

  -- Nor this.  Vanilla draws the shadow on the skin -- the ear, the brow,
  -- the line of the mouth -- in the shade BELOW the skin's own, which on a
  -- monochrome ramp is the same shade as the clothes.  Painting only shade 2
  -- leaves those as green freckles on a skin-coloured face, so the pieces
  -- of shade 3 sealed inside skin take the skin's own shadow.
  local SKIN_DARK = { 0xad, 0x75, 0x47 }

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

  -- ------- which parts of a portrait are skin
  --
  -- Vanilla's ramp on this art is monochrome, so a pixel's SHADE never says
  -- whether it is a cheek or a sleeve.  Worse, skin is not one shade: the
  -- face is drawn in shade 2 with its brow and mouth in shade 3, and the
  -- HANDS are drawn in shade 3 alone -- the same shade as the trousers and
  -- the cap.  Every rule up to 1.8.0 only ever looked at shade 2, so the
  -- hands and the ear were never reachable by any of them, and what it did
  -- reach on the arms was the jacket's own shading.
  --
  -- Read back out of the game, the card's four skin parts are:
  --
  --   the FACE   one patch of shade 2, 22px, high in the figure.
  --   the EAR    ONE pixel of shade 2 beside it, with one of shade 3 under
  --              it.  Not in any patch big enough to have a rule of its own.
  --   the HANDS  two patches of SHADE 3 -- 6px at the left hip, 7px at the
  --              right -- sitting past the edge of the shirt.
  --   the DETAIL small pieces of shade 3 inside or against skin: the brow,
  --              the mouth, the ear's own shadow.
  --
  -- and the four things that look like them and are not:
  --
  --   the cap's shading (19px of shade 2, sealed inside the cap);
  --   the jacket's shoulder and its sleeve shading (shade 2, and on the real
  --     art one pixel away from a hand on every local count there is);
  --   the collar (6px of shade 3, the same size and profile as a hand);
  --   the shirt's hem (4px of shade 3 past the shirt's edge).
  --
  -- So nothing here is decided by size or by colour alone.  Every rule is
  -- about WHERE a patch sits relative to the figure and to the biggest mass
  -- of ink in it, which is his shirt front.
  local FACE_BAND = 0.40   -- how far down the figure a face may begin
  local FACE_PAPER = 2     -- paper against it; a garment's shading has none
  local EAR_MAX = 2        -- an ear is a speck, not a patch
  local EAR_NEAR = 4       -- and it is right beside the face
  local HAND_MIN = 4       -- smaller than this out there is dither
  local HAND_MAX = 8       -- bigger is the trouser leg
  local HAND_INK = 4       -- outline around it: a hem strip has almost none
  local HAND_REACH = 2     -- rows past the shirt a hand may still start
  local DETAIL_MAX = 6     -- sealed inside skin: a brow, never a garment
  local SPECK_MAX = 2      -- or a speck against it: the ear's own shadow
  local GLINT_MAX = 2      -- a speck of the LIGHT shade inside a hand
  local TEMPLE_MAX = 3     -- and the specks between the hat and the face
  local TEMPLE_ROWS = 3    -- which is all the higher this ever looks

  -- every 4-connected patch of one shade
  local function connected(shade, w, h, want)
    local id, list = {}, {}
    for y = 0, h - 1 do id[y] = {} end
    for y = 0, h - 1 do
      for x = 0, w - 1 do
        if shade[y][x] == want and not id[y][x] then
          local n = #list + 1
          local pixels, stack = {}, { { x, y } }
          id[y][x] = n
          while #stack > 0 do
            local at = table.remove(stack)
            pixels[#pixels + 1] = at
            for _, step in ipairs(STEPS) do
              local nx, ny = at[1] + step[1], at[2] + step[2]
              if nx >= 0 and nx < w and ny >= 0 and ny < h
                  and shade[ny][nx] == want and not id[ny][nx] then
                id[ny][nx] = n
                stack[#stack + 1] = { nx, ny }
              end
            end
          end
          list[n] = pixels
        end
      end
    end
    return list
  end

  local function bounds(pixels)
    local top, bottom, left, right
    for _, at in ipairs(pixels) do
      local x, y = at[1], at[2]
      if not top or y < top then top = y end
      if not bottom or y > bottom then bottom = y end
      if not left or x < left then left = x end
      if not right or x > right then right = x end
    end
    return top, bottom, left, right
  end

  -- how many neighbours of a patch are paper, or are ink
  local function against(pixels, shade, w, h, paper)
    local n = 0
    for _, at in ipairs(pixels) do
      for _, step in ipairs(STEPS) do
        local nx, ny = at[1] + step[1], at[2] + step[2]
        if nx >= 0 and nx < w and ny >= 0 and ny < h then
          local s = shade[ny][nx]
          if paper then
            if s == 0 or s == 1 then n = n + 1 end
          elseif s == 4 then
            n = n + 1
          end
        end
      end
    end
    return n
  end

  -- -> the mask of skin, and the mask of the shade-3 detail inside it
  local function skinMask(shade, w, h)
    -- the drawn figure, ignoring the ground: "high in the picture" has to
    -- mean high in HIM, not high in a canvas that is mostly padding
    local top, bottom
    for y = 0, h - 1 do
      for x = 0, w - 1 do
        local s = shade[y][x]
        if s ~= 0 and s ~= 1 then
          if not top then top = y end
          if y > (bottom or -1) then bottom = y end
        end
      end
    end
    if not top then return nil, nil end
    local high = top + (bottom - top + 1) * FACE_BAND

    local light = connected(shade, w, h, 2)
    local mid = connected(shade, w, h, 3)

    -- the FACE: the biggest patch of shade 2 high in the figure with paper
    -- against it.  The cap's own shading is bigger than either hand and sits
    -- up there too, but it is sealed inside the cap and touches no paper.
    local face
    for _, pixels in ipairs(light) do
      local t = bounds(pixels)
      if t <= high and against(pixels, shade, w, h, true) >= FACE_PAPER
          and (not face or #pixels > #face) then
        face = pixels
      end
    end
    if not face then return nil, nil end

    local skin = {}
    local function paint(pixels)
      for _, at in ipairs(pixels) do
        skin[at[2]] = skin[at[2]] or {}
        skin[at[2]][at[1]] = true
      end
    end
    paint(face)

    local ftop, fbot, fleft, fright = bounds(face)

    -- the EAR: a speck of the same shade BESIDE the upper half of the face.
    -- Beside, because inside is the face already and below is the collar;
    -- upper half, because that is where an ear is and the chin is not.
    local earBottom = ftop + math.floor((fbot - ftop + 1) / 2)
    for _, pixels in ipairs(light) do
      if pixels ~= face and #pixels <= EAR_MAX then
        local t, b, l, r = bounds(pixels)
        if b >= ftop - 1 and t <= earBottom
            and (l > fright or r < fleft)
            and l <= fright + EAR_NEAR and r >= fleft - EAR_NEAR then
          paint(pixels)
        end
      end
    end

    -- the HANDS, which are shade 3 and not shade 2 at all.  The shirt front
    -- is the biggest mass of ink there is; a hand is a small patch past its
    -- edge, low enough to be at the hip rather than the shoulder, and ringed
    -- by outline -- which is what the shirt's own hem, out there at the same
    -- height and the same size, is not.
    local torso
    for _, pixels in ipairs(connected(shade, w, h, 4)) do
      if not torso or #pixels > #torso then torso = pixels end
    end
    local isHand = {}
    if torso then
      local vtop, vbot, vleft, vright = bounds(torso)
      local waist = (vtop + vbot) / 2
      for i, pixels in ipairs(mid) do
        local t, b, l, r = bounds(pixels)
        if #pixels >= HAND_MIN and #pixels <= HAND_MAX
            and b >= waist and t <= vbot + HAND_REACH
            -- reaching PAST the shirt's edge, not merely overlapping it: a
            -- hand at the hip still shares a column or two with the shirt
            and (l < vleft or r > vright)
            and against(pixels, shade, w, h, false) >= HAND_INK then
          isHand[i] = true
          paint(pixels)
        end
      end
    end

    -- the GLINT: a speck of the LIGHT shade sitting inside skin already
    -- painted.  Leaving it green puts a green pixel in the middle of a hand.
    --
    -- It takes the hand's own tone rather than the light one its shade would
    -- otherwise earn, which is the one place this file does not go by shade.
    -- At six pixels a hand is a fist, and a single lighter pixel inside a
    -- fist reads as the gap between two fingers, not as a highlight on it --
    -- so it goes in with the shadow and the hand comes out one colour.
    --
    -- It has to run after the hands, and it only ever looks at skin this
    -- pass has painted: every other light-shade speck on the picture is
    -- dither on the cap or the knees, and there are twenty-eight of those.
    local glint = {}
    for _, pixels in ipairs(light) do
      if #pixels <= GLINT_MAX then
        local touching, foreign = 0, false
        for _, at in ipairs(pixels) do
          for _, step in ipairs(STEPS) do
            local nx, ny = at[1] + step[1], at[2] + step[2]
            if nx >= 0 and nx < w and ny >= 0 and ny < h then
              if skin[ny] and skin[ny][nx] then touching = touching + 1
              elseif shade[ny][nx] == 2 then foreign = true end
            end
          end
        end
        if touching >= 2 and not foreign then
          glint[#glint + 1] = pixels
        end
      end
    end

    -- the TEMPLE: the specks of mid shade between the hat's underside and
    -- the face.  They touch no skin -- the hat's outline is in the way -- so
    -- nothing below can reach them, and they are the last of him that is
    -- still green.  Bounded to the rows just above the face, so the hat's
    -- own dither is never in range.
    local isTemple = {}
    for i, pixels in ipairs(mid) do
      local t, b = bounds(pixels)
      if #pixels <= TEMPLE_MAX and b < ftop and b >= ftop - TEMPLE_ROWS then
        isTemple[i] = true
      end
    end

    -- the DETAIL: shade 3 sealed inside skin -- the brow, the mouth -- or a
    -- speck of it against skin, which is the ear's own shadow.  All of it in
    -- the skin's shadow colour, the temple included: shade 3 is the shade
    -- BELOW the skin's own everywhere it appears.
    local detail = {}
    for i, pixels in ipairs(mid) do
      if isTemple[i] and not isHand[i] then
        for _, at in ipairs(pixels) do
          detail[at[2]] = detail[at[2]] or {}
          detail[at[2]][at[1]] = true
        end
      elseif not isHand[i] and #pixels <= DETAIL_MAX then
        local sealed, touching = true, 0
        for _, at in ipairs(pixels) do
          for _, step in ipairs(STEPS) do
            local nx, ny = at[1] + step[1], at[2] + step[2]
            if nx < 0 or nx >= w or ny < 0 or ny >= h then
              sealed = false
            else
              local s = shade[ny][nx]
              if s == 2 then
                if skin[ny] and skin[ny][nx] then touching = touching + 1
                else sealed = false end
              elseif s == 0 or s == 1 then
                sealed = false
              end
            end
          end
        end
        if touching > 0 and (#pixels <= SPECK_MAX or sealed) then
          for _, at in ipairs(pixels) do
            detail[at[2]] = detail[at[2]] or {}
            detail[at[2]][at[1]] = true
          end
        end
      end
    end

    for _, pixels in ipairs(glint) do
      for _, at in ipairs(pixels) do
        detail[at[2]] = detail[at[2]] or {}
        detail[at[2]][at[1]] = true
      end
    end

    return skin, detail
  end

  local function recoloured(rel, field, wantSkin)
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
    local skin, detail
    if (not field) and wantSkin then skin, detail = skinMask(shade, w, h) end

    out:mapPixel(function(x, y, r, g, b, a)
      if a == 0 then return r, g, b, a end
      local s = shade[y][x]
      local colour = ramp[s]
      if not field then
        -- The portrait: the ramp, and the skin if any was found.  WHICH skin
        -- is the pixel's own shade and nothing else -- the light shade takes
        -- the skin, the mid shade takes its shadow -- so a hand drawn
        -- entirely in the mid shade comes out shadowed the way the brow and
        -- the ear's underside do, and the one light pixel inside it stays
        -- the highlight vanilla drew there.  Up to 1.10.0 the hands were
        -- painted flat: found by zone, coloured by zone, and so the only
        -- skin on the picture that ignored its own shade.
        if skin and skin[y] and skin[y][x] then
          colour = (s == 3) and SKIN_DARK or WILD_GREEN[2]
        elseif detail and detail[y] and detail[y][x] then
          colour = SKIN_DARK
        end
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
