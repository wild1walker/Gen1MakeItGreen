-- Headless coverage of the two files that decide what Wild Green does.
--
-- Neither can be exercised in place: main.lua wants the loader's `mod` table
-- and transforms.lua wants the asset sandbox's `ctx`.  Both are small, honest
-- surfaces, so both are stood up here and the real files are run against
-- them.  What is checked is everything settled before a pixel is drawn:
--
--   * the recipe recolors exactly the five player pictures, writes them under
--     green/ where they shadow nothing, and skips a picture the cache has
--     not got rather than failing the run;
--   * PLAYER = GREEN repoints the overworld walker and the BICYCLE sheet and
--     leaves every other sprite -- Oak's included -- alone;
--   * it repoints the battle back pic and the front pic, and does NOT touch
--     the old man's demo back pic;
--   * PLAYER = RED writes no character patch at all, which is the switch the
--     cart promises;
--   * TITLE RIBBON is the only thing that decides the ribbon and LOGO1, and
--     it is independent of PLAYER;
--   * the ramp in main.lua is the ramp in transforms.lua, byte for byte.
--
-- Run:  luajit tests/wild_green_test.lua   (from the mod's root)

local MOD = ""

local passed, failed = 0, 0
local function ok(condition, description)
  if condition then
    passed = passed + 1
  else
    failed = failed + 1
    io.write("  FAIL  ", description, "\n")
  end
end
local function eq(actual, expected, description)
  if actual ~= expected then
    io.write(("  FAIL  %s\n         got %s, wanted %s\n")
      :format(description, tostring(actual), tostring(expected)))
    failed = failed + 1
  else
    passed = passed + 1
  end
end

local function chunk(path)
  local loaded, problem = loadfile(path)
  if not loaded then error(problem, 0) end
  return loaded()
end

-- ------- a stand-in for love's ImageData
--
-- Only what the recipe reaches for: getDimensions, getPixel, mapPixel.  A
-- cache entry given as `true` gets none of them, which is how the recipe's
-- pcall fallback is exercised alongside the real path.

local function makeImageData(rel, rows)
  local data = { image = rel, rows = rows }
  function data:getDimensions() return #self.rows[1], #self.rows end
  function data:getPixel(x, y)
    local v = self.rows[y + 1][x + 1] / 255
    return v, v, v, 1
  end
  function data:mapPixel(fn)
    self.out = {}
    for y = 1, #self.rows do
      self.out[y] = {}
      for x = 1, #self.rows[y] do
        local v = self.rows[y][x] / 255
        local r, g, b = fn(x - 1, y - 1, v, v, v, 1)
        self.out[y][x] = { math.floor(r * 255 + .5), math.floor(g * 255 + .5),
                           math.floor(b * 255 + .5) }
      end
    end
    return self
  end
  return data
end

-- ------- the asset sandbox

-- Everything the recipe is handed, and nothing else: the real ctx has no
-- require, no love and no io either.
local function fakeCtx(cache)
  local ctx = { written = {}, read = {} }
  function ctx.exists(rel) return cache[rel] ~= nil end
  function ctx.readImage(rel)
    ctx.read[#ctx.read + 1] = rel
    local pixels = cache[rel]
    if type(pixels) ~= "table" then
      -- no per-pixel surface: mouthAware raises, the recipe falls back
      return { image = rel }
    end
    return makeImageData(rel, pixels)
  end
  function ctx.recolor(image, shades)
    return { image = image.image, shades = shades }
  end
  function ctx.writeImage(image, rel)
    ctx.written[rel] = image
    return rel
  end
  return ctx
end

local VANILLA = {
  ["sprites/red.png"] = true,
  ["sprites/red_bike.png"] = true,
  ["battle/redb.png"] = true,
  ["trainer_card/red.png"] = true,
  ["title/player.png"] = true,
  -- present in the cache, and none of our business
  ["battle/oldmanb.png"] = true,
  ["sprites/oak.png"] = true,
}

local function runTransform(cache)
  local ctx = fakeCtx(cache)
  chunk(MOD .. "transforms.lua")(ctx)
  return ctx
end

-- Red's face, in the four grey shades the importer writes: a row of skin
-- with a shade-3 mouth in the middle of it, over a row of solid shade-3
-- clothing bounded by black.  The mouth is the outfit's own shade -- that is
-- the whole problem -- so only where it sits can tell them apart.
-- One 16-row frame, because the bill rule reads y % 16: the cap and its bill
-- live in the top rows, the face below them.  Row 4 is the side view's bill,
-- which sticks out BESIDE the cap rather than under it -- the case 1.1.3's
-- above-only rule missed.
local W, S, O, K = 255, 170, 85, 0
local FACE = {
  { K, O, O, O, O, O, K },   -- 0  the cap: shade 3
  { K, S, S, S, S, S, K },   -- 1  the bill under the cap (facing down)
  { S, O, O, O, O, O, K },   -- 2  the bill beside the cap (facing sideways)
  { K, K, K, K, K, K, K },   -- 3
  { K, K, K, K, K, K, K },   -- 4
  { K, K, K, K, K, K, K },   -- 5
  { K, S, S, S, S, S, K },   -- 6  the face begins below BILL_ROWS
  { K, S, K, S, K, S, K },   -- 7  eyes
  { K, S, S, O, S, S, K },   -- 8  the mouth: shade 3, skin either side
  { K, K, O, O, O, K, K },   -- 9  the collar: shade 3 bounded by black
  { S, K, O, O, O, K, S },   -- 10 the hands: small and touching the body,
                             --    but low in the frame, so not a bill
  { K, S, S, S, S, S, K },   -- 11 more face, deep in the frame
  { K, S, S, S, K, K, K },   -- 12 the profile: a cheek, and under it a
  { K, O, S, S, K, K, K },   -- 13 mouth with skin on ONE side only
  { K, K, K, K, K, K, K },   -- 14
  { K, K, K, K, K, K, K },   -- 15
}

local function hex(c) return ("%02x%02x%02x"):format(c[1], c[2], c[3]) end

-- The sideburn: the hair's tip between the cap and the ear, which vanilla
-- draws skin in one forward walk frame and ink in the other.  A full 16
-- columns, because the test reaches three pixels out one way (outline, ear,
-- outline) and four the other (the cheek), and because three cases have to
-- sit side by side without touching.
--
-- Row 11 is the brim line and holds all three.  Under it, row 12 is what
-- tells them apart:
--
--   x=4   ear out to the left -- K S K at x=3,2,1 -- and cheek running
--         right: a sideburn, and the only pixel here that becomes skin.
--   x=8   cheek running left, but no ear either way.  That is the profile
--         frames' hairline above the eye, and it stays black.
--   x=12  an ear out to the right, but no cheek behind it.  Also black.
--
-- The last two are what keep the rule honest: drop either half of it and
-- one of them turns to flesh.
local SIDEBURN = {
  { K, K, K, K, K, K, K, K, K, K, K, K, K, K, K, K },   -- 0
  { K, K, K, K, K, K, K, K, K, K, K, K, K, K, K, K },   -- 1
  { K, K, K, K, K, K, K, K, K, K, K, K, K, K, K, K },   -- 2
  { K, K, K, K, K, K, K, K, K, K, K, K, K, K, K, K },   -- 3
  { K, K, K, K, K, K, K, K, K, K, K, K, K, K, K, K },   -- 4
  { K, K, K, K, K, K, K, K, K, K, K, K, K, K, K, K },   -- 5
  { K, K, K, K, K, K, K, K, K, K, K, K, K, K, K, K },   -- 6
  { K, K, K, K, K, K, K, K, K, K, K, K, K, K, K, K },   -- 7
  { K, K, K, K, K, K, K, K, K, K, K, K, K, K, K, K },   -- 8
  { K, K, K, O, O, O, O, O, O, O, O, O, O, O, O, K },   -- 9  the cap
  { K, K, K, K, K, K, K, K, K, K, K, K, K, K, K, K },   -- 10 its bottom edge
  { K, K, K, K, K, K, K, K, K, K, K, K, K, K, K, K },   -- 11 the brim line
  { K, K, S, K, S, S, S, S, S, K, K, K, S, K, S, K },   -- 12 ears and cheeks
  { K, K, K, K, K, K, K, K, K, K, K, K, K, K, K, K },   -- 13
  { K, K, K, K, K, K, K, K, K, K, K, K, K, K, K, K },   -- 14
  { K, K, K, K, K, K, K, K, K, K, K, K, K, K, K, K },   -- 15
}

io.write("transforms.lua -- the sideburn\n")
do
  local ctx = fakeCtx({ ["sprites/red.png"] = SIDEBURN })
  chunk(MOD .. "transforms.lua")(ctx)
  local px = ctx.written["green/sprites/red.png"]
  px = px and px.out
  ok(px ~= nil, "the per-pixel path ran")
  eq(px and hex(px[12][5]), "f0a363",
    "the sideburn is skin: cap above, cheek below, an ear beside it")
  eq(px and hex(px[12][9]), "000000",
    "a hairline with a cheek but no ear stays black")
  eq(px and hex(px[12][13]), "000000",
    "an ear with no cheek behind it stays black")
  eq(px and hex(px[13][3]), "f0a363", "the ear itself is untouched")
  eq(px and hex(px[10][5]), "65ba3f", "and the cap is still the cap")

  -- nothing else in the sheet moved: exactly one pixel of ink became skin
  local painted = 0
  for y = 1, #SIDEBURN do
    for x = 1, #SIDEBURN[1] do
      if SIDEBURN[y][x] == K and hex(px[y][x]) == "f0a363" then
        painted = painted + 1
      end
    end
  end
  eq(painted, 1, "...and it is the only black pixel in the sheet that moved")
end

io.write("transforms.lua -- the mouth and the bill\n")
do
  local ctx = fakeCtx({ ["sprites/red.png"] = FACE })
  chunk(MOD .. "transforms.lua")(ctx)
  local out = ctx.written["green/sprites/red.png"]
  ok(out ~= nil and out.out ~= nil, "the per-pixel path ran")
  local px = out and out.out
  eq(px and hex(px[9][4]), "ec4d29",
    "the mouth is vanilla's own red -- lips, not skin and not clothing")
  eq(px and hex(px[10][3]), "65ba3f",
    "the collar is still green -- black either side, not skin")
  eq(px and hex(px[2][3]), "e6f4dc",
    "the bill under the cap is the green-tinted white (facing down)")
  eq(px and hex(px[3][1]), "e6f4dc",
    "the bill beside the cap is too (facing sideways)")
  eq(px and hex(px[7][3]), "f0a363",
    "the face is still skin -- too big a region to be a bill")
  eq(px and hex(px[12][3]), "f0a363",
    "...and so is the face deeper in the frame")
  eq(px and hex(px[11][1]), "f0a363",
    "a hand is skin: small and touching the body, but low in the frame")
  eq(px and hex(px[8][3]), "000000", "an eye stays black")
  eq(px and hex(px[14][2]), "ec4d29",
    "the sideways mouth is vanilla's red too -- skin on one side, the "
    .. "silhouette on the other, and cheek above it")
  eq(px and hex(px[3][2]), "65ba3f",
    "the cap's bottom row stays green: the skin above it is the bill")
end

io.write("transforms.lua -- the trainer art takes the other ramp\n")
do
  -- Shade 2 on the 56x56 portrait is the LIGHT for everything -- the cap's
  -- front, the shirt's shading, the knees -- not the face.  A skin tone
  -- there put orange blotches on the hat, and the face-sized position rules
  -- are noise at that size.  So the portrait gets a monochrome green ramp
  -- and neither rule, the way vanilla's own ramp is monochrome red.
  local ctx = fakeCtx({ ["trainer_card/red.png"] = FACE })
  chunk(MOD .. "transforms.lua")(ctx)
  local px = ctx.written["green/trainer_card/red.png"].out
  eq(hex(px[7][3]), "a8dd8a",
    "shade 2 is the light green, not skin")
  eq(hex(px[1][3]), "65ba3f", "shade 3 is still the outfit green")
  eq(hex(px[9][4]), "65ba3f",
    "no mouth rule on the portrait: shade 3 stays the outfit")
  eq(hex(px[2][3]), "a8dd8a",
    "no bill rule either: shade 2 touching the cap stays the light")
  eq(hex(px[8][3]), "000000", "ink is still ink")
end

io.write("transforms.lua -- which parts of a portrait are skin\n")
do
  -- Skin is not one shade here.  The face is shade 2 with its brow in shade
  -- 3; the HANDS are shade 3 alone -- the same shade as the trousers and the
  -- cap -- and the ear is one pixel of each.  The fixture carries all four
  -- of those and all four of the things that look like them and are not.
  local PORTRAIT = {
    { W, W, K, K, K, K, K, K, K, K, W, W, W, W },  -- 0
    { W, K, O, O, O, O, O, O, O, O, K, W, W, W },  -- 1  the cap: one ring of
    { W, K, O, S, S, S, S, S, S, O, K, W, W, W },  -- 2  mid shade round 12px
    { W, K, O, S, S, S, S, S, S, O, K, W, W, W },  -- 3  of shading, sealed,
    { W, W, K, K, K, K, K, K, K, K, W, W, W, W },  -- 4  BIGGER than the face
    { W, W, W, O, W, W, W, W, O, W, W, W, W, W },  -- 5  the TEMPLE: specks
    { W, W, W, S, W, S, S, S, W, W, W, W, W, W },  -- 6  under the hat that
    { W, W, K, K, S, S, S, S, K, W, S, W, W, W },  -- 7  touch no skin at all
    { W, W, K, S, S, O, S, S, K, W, O, W, W, W },  -- 8  the face, and the EAR
    { W, W, K, K, K, K, K, K, K, W, W, W, W, W },  -- 9
    { W, W, W, W, W, W, W, W, W, W, W, W, W, W },  -- 10
    { W, S, S, S, W, W, W, W, W, W, W, W, W, W },  -- 11 the jacket's
    { W, S, S, S, W, W, W, W, S, W, W, W, W, W },  -- 12 shoulder, and a speck
    { W, W, W, W, K, K, K, K, K, W, W, W, W, W },  -- 13 beside the face but
    { W, K, O, O, K, K, K, K, K, W, W, W, W, W },  -- 14 too LOW.  The collar:
    { W, K, O, O, K, K, K, K, K, W, S, S, W, W },  -- 15 hand-shaped, ringed
    { W, W, S, S, W, K, K, K, K, W, S, S, W, W },  -- 16 by ink, past the
    { W, W, W, W, K, K, K, K, K, W, W, W, W, W },  -- 17 shirt -- but ABOVE
    { W, K, O, O, K, K, O, O, K, K, O, O, K, W },  -- 18 the waist.  The
    { W, K, O, O, K, K, O, O, K, K, O, O, K, W },  -- 19 HANDS, with a GLINT
    { W, K, O, S, K, K, O, O, K, K, O, O, K, W },  -- 20 in one, and a hole in
    { W, W, W, W, K, K, K, K, K, W, W, W, W, W },  -- 21 the shirt that is
    { W, W, W, W, W, W, W, W, W, W, W, W, W, W },  -- 22 not past its edge
    { W, W, W, O, O, O, O, W, W, W, W, W, W, W },  -- 23 the hem: no ink
    { W, W, W, W, W, W, W, W, W, W, W, W, W, W },  -- 24
  }

  local ctx = fakeCtx({ ["trainer_card/red.png"] = PORTRAIT })
  chunk(MOD .. "transforms.lua")(ctx)
  local plain = ctx.written["green/trainer_card/red.png"]
  local skin = ctx.written["greenskin/trainer_card/red.png"]
  ok(plain ~= nil and skin ~= nil, "both copies of the portrait are written")
  eq(hex(plain.out[7][6]), "a8dd8a", "green/ leaves the face the light green")
  eq(hex(plain.out[19][3]), "65ba3f", "...and the hands the outfit green")

  -- the face, and the shadow in it
  eq(hex(skin.out[7][6]), "f0a363", "the face is skin")
  eq(hex(skin.out[9][7]), "f0a363", "...all of it")
  eq(hex(skin.out[9][6]), "ad7547", "the brow inside it is the skin's shadow")

  -- the ear: one pixel of each shade, beside the UPPER half of the face
  eq(hex(skin.out[8][11]), "f0a363", "the ear is skin")
  eq(hex(skin.out[9][11]), "ad7547", "...and the pixel under it is its shadow")
  eq(hex(skin.out[7][4]), "a8dd8a",
    "a speck inside the face's own columns is not an ear")
  eq(hex(skin.out[13][9]), "a8dd8a",
    "...and neither is one beside it but down at the chest")

  -- the temple: under the hat, above the face, touching no skin at all
  eq(hex(skin.out[6][4]), "ad7547", "the temple under the hat is skin's shadow")
  eq(hex(skin.out[6][9]), "ad7547", "...on the other side of the brim too")

  -- a hand is skin; only the crease inside it is the shadow
  eq(hex(skin.out[19][3]), "f0a363", "a hand is skin")
  eq(hex(skin.out[19][11]), "f0a363", "...on both sides")
  eq(hex(skin.out[21][4]), "ad7547",
    "the speck inside a hand is the crease in it, so it takes the shadow")
  ok(hex(skin.out[21][4]) ~= hex(skin.out[19][3]),
    "...which is the one thing in a hand that is not the skin tone")

  -- and everything that looks like skin and is not
  eq(hex(skin.out[3][5]), "a8dd8a",
    "the cap's shading stays green: bigger than the face, but sealed in")
  eq(hex(skin.out[2][3]), "65ba3f",
    "the cap's own ring stays green: too big to be a temple speck")
  eq(hex(skin.out[12][2]), "a8dd8a", "the jacket's shoulder stays green")
  eq(hex(skin.out[17][11]), "a8dd8a",
    "the sleeve's shading stays green -- this is what 1.8.0 read as a hand")
  eq(hex(skin.out[15][3]), "65ba3f",
    "the collar stays green: hand-shaped and ringed by ink, but too high")
  eq(hex(skin.out[19][7]), "65ba3f",
    "a hole in the shirt stays green: not past its edge")
  eq(hex(skin.out[24][4]), "65ba3f",
    "the hem stays green: past the edge, but no outline round it")
  eq(hex(skin.out[14][6]), "000000", "the shirt front is still ink")
  eq(hex(skin.out[7][1]), "ffffff", "the ground is still paper")
end

io.write("transforms.lua -- no face, no skin anywhere\n")
do
  -- The battle BACK pic: no face on the back of his head, so nothing is
  -- painted at all -- not even something shaped like a hand.
  local NO_FACE = {
    { W, W, K, K, K, K, K, K, W, W, W, W, W, W },
    { W, K, O, S, S, S, S, O, K, W, W, W, W, W },
    { W, K, O, S, S, S, S, O, K, W, W, W, W, W },
    { W, W, K, K, K, K, K, K, W, W, W, W, W, W },
    { W, W, W, W, K, K, K, K, K, W, W, W, W, W },
    { W, W, W, W, K, K, K, K, K, W, W, W, W, W },
    { W, K, O, O, K, K, K, K, K, K, O, O, K, W },
    { W, K, O, O, K, K, K, K, K, K, O, O, K, W },
    { W, W, W, W, K, K, K, K, K, W, W, W, W, W },
  }
  local ctx = fakeCtx({ ["battle/redb.png"] = NO_FACE })
  chunk(MOD .. "transforms.lua")(ctx)
  local skin = ctx.written["greenskin/battle/redb.png"]
  ok(skin ~= nil, "the skinned copy is still written")
  eq(hex(skin.out[2][5]), "a8dd8a", "the sealed shading is not a face")
  eq(hex(skin.out[7][3]), "65ba3f",
    "and with no face found, a hand-shaped patch is left alone too")
end

io.write("transforms.lua -- the title figure is painted from a table\n")
do
  -- The one picture the rules cannot express: fourteen of its skin pixels
  -- come from the PAPER shade and eight go to ink, and nothing in this file
  -- touches white.  So it carries a table instead -- row, column, the shade
  -- that must be under it, and the tone -- and the shade is the guard.
  --
  -- Here every cell is paper, so almost none of the table's entries find the
  -- shade they were authored against and the picture falls through to the
  -- ordinary rules, which find no face and paint nothing.
  local FLAT = {}
  for y = 1, 30 do
    FLAT[y] = {}
    for x = 1, 41 do FLAT[y][x] = W end
  end
  local ctx = fakeCtx({ ["title/player.png"] = FLAT })
  chunk(MOD .. "transforms.lua")(ctx)
  local skin = ctx.written["greenskin/title/player.png"]
  ok(skin ~= nil, "the title figure is written like any other portrait")
  -- 26,2 is one of the entries whose shade IS paper, so it would match on
  -- this all-paper cache; what stops it is that only a handful of the 95 do
  eq(hex(skin.out[27][3]), "ffffff",
    "a cache whose figure is not the one the table was drawn against is "
    .. "left to the rules, not painted at coordinates that mean nothing")

  -- and the POKE BALL, which the engine lifts out of this file at (0,16)
  -- and throws on its own: it keeps vanilla's red rather than going green
  local BALL = {}
  for y = 1, 30 do
    BALL[y] = {}
    for x = 1, 41 do BALL[y][x] = O end
  end
  local ctx2 = fakeCtx({ ["title/player.png"] = BALL })
  chunk(MOD .. "transforms.lua")(ctx2)
  local out = ctx2.written["greenskin/title/player.png"].out
  eq(hex(out[18][4]), "d84030", "the ball's mid shade is vanilla's red")
  eq(hex(out[24][4]), "d84030", "...to the bottom row of its 8x8")
  eq(hex(out[17][4]), "d84030", "...from its top row, which is row 16")
  eq(hex(out[16][4]), "65ba3f", "the row above the ball is his outfit")
  eq(hex(out[25][4]), "65ba3f", "...and so is the row below it")
  eq(hex(out[20][9]), "65ba3f", "...and the column beside it")
end

io.write("transforms.lua -- every picture is covered\n")
do
  -- The hook only swaps what the recipe writes, so a picture named in one
  -- and not the other draws nothing at all.  Both lists are checked against
  -- each other by tools/check.py; this checks the recipe reaches them.
  local all = {}
  for _, rel in ipairs({ "sprites/red.png", "sprites/red_bike.png",
                         "battle/redb.png", "battle/back/redb.png",
                         "trainer_card/red.png", "credits/red.png",
                         "intro/red.png", "hall_of_fame/red.png" }) do
    all[rel] = FACE
  end
  local ctx = fakeCtx(all)
  chunk(MOD .. "transforms.lua")(ctx)
  for rel in pairs(all) do
    ok(ctx.written["green/" .. rel] ~= nil, "green/" .. rel .. " written")
  end
  -- and the two ramps land on the right side of the line
  eq(hex(ctx.written["green/sprites/red.png"].out[7][3]), "f0a363",
    "the overworld sheet keeps skin")
  eq(hex(ctx.written["green/battle/redb.png"].out[7][3]), "a8dd8a",
    "the battle back pic takes the light green")
end

io.write("transforms.lua\n")
do
  local ctx = runTransform(VANILLA)
  local wrote = {}
  local count = 0
  for rel in pairs(ctx.written) do
    wrote[rel] = true
    count = count + 1
  end
  eq(count, 8, "only what this cache carries is written")
  ok(wrote["greenskin/battle/redb.png"] and wrote["greenskin/trainer_card/red.png"],
    "...and every portrait gets a skinned twin beside it")
  ok(not wrote["greenskin/sprites/red.png"],
    "an overworld sheet gets no skinned twin: it already has a face rule")
  for _, rel in ipairs({ "sprites/red.png", "sprites/red_bike.png",
                         "battle/redb.png", "trainer_card/red.png" }) do
    ok(wrote["green/" .. rel], "green/" .. rel .. " written")
  end
  -- The title figure IS recoloured, for one mode.  In every other mode his
  -- rectangle is painted by shade and the colour a file carries is thrown
  -- away, so MEWMON does that work; under ADVANCED main.lua hands the draw
  -- this file instead, and the face and hands come with it.
  ok(wrote["green/title/player.png"] and wrote["greenskin/title/player.png"],
    "the title screen's standing figure gets both copies too")
  ok(not wrote["green/battle/oldmanb.png"],
    "the old man's demo back pic is left alone")
  ok(not wrote["green/sprites/oak.png"], "Oak is left alone")

  -- nothing lands on a cache path, which is what keeps the RED switch alive
  for rel in pairs(ctx.written) do
    ok(rel:sub(1, 6) == "green/" or rel:sub(1, 10) == "greenskin/",
      rel .. " is under a prefix that shadows nothing")
  end

  local shades = ctx.written["green/sprites/red.png"].shades
  eq(#shades, 4, "the ramp is four colours")
  eq(("%02x%02x%02x"):format(shades[1][1], shades[1][2], shades[1][3]),
    "ffffff", "shade 1 is pure white, so a battle pic still mattes")
  eq(("%02x%02x%02x"):format(shades[2][1], shades[2][2], shades[2][3]),
    "f0a363", "shade 2 is a warm tan skin, not green and not a pale cream")
  eq(("%02x%02x%02x"):format(shades[3][1], shades[3][2], shades[3][3]),
    "65ba3f", "shade 3 is the outfit green")
  eq(("%02x%02x%02x"):format(shades[4][1], shades[4][2], shades[4][3]),
    "000000", "shade 4 is ink")
end

do
  -- an import that never wrote a BICYCLE sheet is a cache, not a fault
  local thin = {}
  for rel in pairs(VANILLA) do thin[rel] = true end
  thin["sprites/red_bike.png"] = nil
  local ctx = runTransform(thin)
  ok(ctx.written["green/sprites/red.png"] ~= nil, "the walker is still written")
  ok(ctx.written["green/sprites/red_bike.png"] == nil,
    "a missing BICYCLE sheet is skipped, not invented")
end

-- ------- the loader's mod table

-- The field registry's semantics are "deep" (src/mods/Schemas.lua), and under
-- deep semantics Merge.deepMerge CONCATENATES arrays rather than replacing
-- them.  The stub used to keep the last payload handed to patch(), so every
-- assertion here read what the mod MEANT rather than what the game would get
-- -- which is exactly how 1.19.0 shipped a naming menu offering six names.
--
-- It folds now, with the two rules that decide this: mod.DELETE unsets a key,
-- and a list merged over a list appends.  `patches[id]` is the folded value.
local DELETE = setmetatable({}, { __tostring = function() return "<DELETE>" end })

local function isList(t)
  if type(t) ~= "table" or next(t) == nil then return false end
  local n = 0
  for k in pairs(t) do
    if type(k) ~= "number" then return false end
    n = n + 1
  end
  for i = 1, n do if t[i] == nil then return false end end
  return true
end

local function foldDeep(dst, src)
  if type(dst) ~= "table" then dst = {} end
  for key, value in pairs(src) do
    if value == DELETE then
      dst[key] = nil
    elseif isList(value) then
      if isList(dst[key]) then                    -- the append that bit us
        for _, item in ipairs(value) do dst[key][#dst[key] + 1] = item end
      else
        dst[key] = value
      end
    elseif type(value) == "table" then
      dst[key] = foldDeep(type(dst[key]) == "table" and dst[key] or {}, value)
    else
      dst[key] = value
    end
  end
  return dst
end

local function fakeRegistry(base, log)
  local registry = { base = base, patches = {}, overrides = {} }
  function registry:get(id) return self.base[id] end
  function registry:each()
    return coroutine.wrap(function()
      for id, def in pairs(self.base) do coroutine.yield(id, def) end
    end)
  end
  function registry:patch(id, partial)
    self.patches[id] = foldDeep(self.patches[id]
      or (self.base[id] and foldDeep({}, self.base[id])) or {}, partial)
    log[#log + 1] = "patch " .. id
  end
  function registry:override(id, value)
    self.overrides[id] = value
    log[#log + 1] = "override " .. id
  end
  return registry
end

local function fakeMod(options)
  local log = {}
  local mod = { log = {}, calls = log, hooks = { wrapped = {} } }
  function mod.hooks:wrap(name, fn)
    self.wrapped[name] = fn
    log[#log + 1] = "wrap " .. name
  end
  function mod.log:info(...) log[#log + 1] = "info " .. select(1, ...) end
  function mod.log:warn(...) log[#log + 1] = "warn " .. select(1, ...) end
  function mod.log:error(...) log[#log + 1] = "error " .. select(1, ...) end

  mod.options = {
    defined = nil,
    define = function(self, rows) self.defined = rows end,
    get = function(_, key) return options[key] end,
  }
  mod.assets = {
    path = function(_, rel) return "mods/wild_green/" .. rel end,
  }
  mod.DELETE = DELETE            -- src/mods/Loader.lua:1180

  mod.content = {
    sprites = fakeRegistry({
      SPRITE_RED = { image = "assets/generated/sprites/red.png",
                     frames = 6, walker = true },
      SPRITE_RED_BIKE = { image = "assets/generated/sprites/red_bike.png",
                          frames = 6, walker = true },
      SPRITE_OAK = { image = "assets/generated/sprites/oak.png",
                     frames = 6, walker = true },
      BOULDER = { image = "assets/generated/sprites/boulder.png", frames = 1 },
    }, log),
    -- No playerPics here, deliberately: Sprites.playerPath reads those
    -- through FieldDefaults.fieldValue, so data.field does not carry them
    -- and a mod that builds a patch out of field:get("playerPics") patches
    -- nothing at all.  That was the 1.0.0 bug; the stub reproduces the
    -- shape that caused it so the hook is the only route left.
    field = fakeRegistry({
      -- vanilla's own lists are here (src/core/Data.lua fills them from the
      -- importer's field.presetNames) so a patch that appends to them shows
      -- up as six names rather than three
      boot = { startMap = "REDS_HOUSE_2F", namePresets = {
        player = { "RED", "ASH", "JACK" },
        rival = { "BLUE", "GARY", "JOHN" } } },
    }, log),
    palettes = fakeRegistry({
      LOGO1 = { { 255, 255, 255 }, { 255, 0, 0 }, { 148, 0, 0 }, { 0, 0, 0 } },
    }, log),
  }
  return mod
end

local function run(options)
  local mod = fakeMod(options)
  chunk(MOD .. "main.lua")(mod)
  return mod
end

io.write("main.lua -- PLAYER = GREEN\n")
do
  local mod = run({ player = "green", ribbon = true })
  local sprites = mod.content.sprites.patches

  ok(sprites.SPRITE_RED ~= nil, "the overworld walker is repointed")
  eq(sprites.SPRITE_RED and sprites.SPRITE_RED.image,
    "assets/generated/green/sprites/red.png", "...at the green path")
  eq(sprites.SPRITE_RED and sprites.SPRITE_RED.trueColor, true,
    "...and true-colour, so the OBP bake leaves it alone")
  ok(sprites.SPRITE_RED_BIKE ~= nil, "the BICYCLE sheet is repointed too")
  ok(sprites.SPRITE_OAK == nil, "Oak is not repainted")
  ok(sprites.BOULDER == nil, "the boulder is not repainted")

  -- The pics go through the hook, over the path the engine already
  -- resolved.  Nothing is patched into field.playerPics, because nothing
  -- is there to patch.
  ok(mod.content.field.patches.playerPics == nil,
    "field.playerPics is not patched -- those paths are not in data.field")
  local hook = mod.hooks.wrapped["player.sprite"]
  ok(hook ~= nil, "player.sprite is wrapped")

  local function through(path, ctx)
    ctx = ctx or {}
    return hook(function(p) return p end, path, ctx), ctx
  end

  local back, backCtx = through("assets/generated/battle/redb.png",
    { side = "back", kind = "battle" })
  eq(back, "assets/generated/greenskin/battle/redb.png",
    "the battle back pic is swapped for the green one")
  eq(backCtx.trueColor, true,
    "...and marked true-colour, so the palette pass leaves it alone")

  local front = through("assets/generated/trainer_card/red.png",
    { side = "front", kind = "intro" })
  eq(front, "assets/generated/greenskin/trainer_card/red.png",
    "the front pic Oak's intro and the card share is swapped")

  -- Whatever the engine resolved is what gets a green twin: no filename
  -- whitelist, so a cache that spells one differently still works.
  eq(through("assets/generated/battle/back/redb.png", {}),
    "assets/generated/greenskin/battle/back/redb.png",
    "an unexpected cache path is still swapped, not ignored")

  eq(through("assets/generated/battle/oldmanb.png", { demo = true }),
    "assets/generated/battle/oldmanb.png",
    "the catch tutorial's old man is left alone")
  eq(through("assets/generated/battle/oakb.png", { oakDemo = true }),
    "assets/generated/battle/oakb.png",
    "Yellow's PROF.OAK demo is left alone")
  eq(through("mods/some_other/hero.png", {}), "mods/some_other/hero.png",
    "a path outside the cache is left where it points")
  eq(through("assets/generated/green/battle/redb.png", {}),
    "assets/generated/green/battle/redb.png",
    "an already-green path is not doubled up")

  local boot = mod.content.field.patches.boot
  ok(boot and boot.title, "field.boot.title is patched")
  ok(boot and boot.title and boot.title.player == nil,
    "boot.title does not repoint the figure: every mode but ADVANCED paints "
    .. "him by shade, so the swap happens at the draw, not in the record")
  eq(boot and boot.title and boot.title.versionRibbon,
    "mods/wild_green/assets/title/wild_green_version.png",
    "the ribbon is the mod's own art")
  ok(boot and boot.title and boot.title.version == nil,
    "versionRibbon, not version -- ours is one continuous strip")

  -- The title figure has no per-image seam, so it is coloured by its zone
  -- palette instead: MEWMON, in the character's own four.
  local mew = mod.content.palettes.overrides.MEWMON
  ok(mew ~= nil, "MEWMON is overridden, which is what colours the title figure")
  eq(mew and ("%02x%02x%02x"):format(mew[2][1], mew[2][2], mew[2][3]),
    "f0a363", "...with the character's skin")
  eq(mew and ("%02x%02x%02x"):format(mew[3][1], mew[3][2], mew[3][3]),
    "65ba3f", "...and the character's outfit green")

  ok(mod.content.palettes.overrides.LOGO1 ~= nil, "LOGO1 is overridden")
  local logo = mod.content.palettes.overrides.LOGO1
  eq(logo and ("%02x%02x%02x"):format(logo[3][1], logo[3][2], logo[3][3]),
    "14571f", "...to the title ramp, which is darker than the character's")
  ok(logo and logo[2][1] ~= 0xf8,
    "the title band does not borrow the character's skin shade")

  -- the rows the manager draws
  local rows = {}
  for _, row in ipairs(mod.options.defined or {}) do rows[row.key] = row end
  ok(rows.player ~= nil, "a PLAYER row is defined")
  eq(rows.player and rows.player.default, "green", "...defaulting to green")
  ok(rows.ribbon ~= nil, "a TITLE RIBBON row is defined")
end

io.write("main.lua -- PORTRAIT SKIN\n")
do
  local on = run({ player = "green", portrait_skin = true })
  local hook = on.hooks.wrapped["player.sprite"]
  local function through(mod, path)
    return mod.hooks.wrapped["player.sprite"](function(p) return p end, path, {})
  end
  eq(through(on, "assets/generated/trainer_card/red.png"),
    "assets/generated/greenskin/trainer_card/red.png",
    "on, a portrait comes from the skinned set")
  eq(through(on, "assets/generated/sprites/red.png"),
    "assets/generated/green/sprites/red.png",
    "...and an overworld sheet never does: it has its own face rule")
  ok(hook ~= nil, "the hook is still the seam")

  local off = run({ player = "green", portrait_skin = false })
  eq(through(off, "assets/generated/trainer_card/red.png"),
    "assets/generated/green/trainer_card/red.png",
    "off, the portrait is the monochrome copy -- exactly 1.4.0's picture")
  eq(through(off, "assets/generated/battle/redb.png"),
    "assets/generated/green/battle/redb.png",
    "...on every portrait")
  ok(off.content.sprites.patches.SPRITE_RED ~= nil,
    "and the overworld player is still green: the rows are independent")

  local rows = {}
  for _, row in ipairs(on.options.defined or {}) do rows[row.key] = row end
  ok(rows.portrait_skin ~= nil, "a PORTRAIT SKIN row is defined")
  eq(rows.portrait_skin and rows.portrait_skin.default, true,
    "...defaulting to on")
end

io.write("main.lua -- the default name\n")
do
  local mod = run({ player = "green", ribbon = true, name = true })
  local boot = mod.content.field.patches.boot
  eq(boot and boot.playerName, "GREEN",
    "the game offers GREEN where it used to offer RED")
  -- The whole list, not its first entries: vanilla's own three are seeded
  -- in the stub's base, and the field registry appends lists rather than
  -- replacing them, so a patch that gets this wrong leaves six names with
  -- ours at the BACK -- which is what 1.19.0 shipped and reads fine if you
  -- only ever check presets[1].
  local presets = boot and boot.namePresets and boot.namePresets.player
  eq(presets and table.concat(presets, "/"), "WILD/GREEN/VERSION",
    "the player's list is exactly WILD / GREEN / VERSION")
  local rival = boot and boot.namePresets and boot.namePresets.rival
  eq(rival and table.concat(rival, "/"), "Thanks/For/Playing!",
    "the rival's is exactly Thanks / For / Playing!")
  ok(presets and not table.concat(presets, "/"):find("RED", 1, true),
    "...with no RED / ASH / JACK left in front of them")
  ok(rival and not table.concat(rival, "/"):find("BLUE", 1, true),
    "...and no BLUE / GARY / JOHN")
  -- A preset is picked from a menu, never typed, so the seven-character
  -- typing limit does not apply -- but the BOX does.  Menu widens to
  -- `widest + 3` tiles and the intro box asks for 11, so nine characters
  -- would grow the frame off vanilla's width.  Ten would not fit the save
  -- either (GenSave writes at most NAME_LENGTH - 1).
  for _, list in ipairs({ presets, rival }) do
    for _, name in ipairs(list or {}) do
      ok(#name >= 1 and #name <= 8,
        ("%q is 1-8 characters, so the naming box keeps vanilla's width")
          :format(name))
    end
  end
end
do
  local mod = run({ player = "green", ribbon = true, name = false })
  local boot = mod.content.field.patches.boot
  ok(boot == nil or boot.playerName == nil,
    "GREEN NAME LIST off leaves the vanilla default alone")
  local kept = boot and boot.namePresets
  eq(kept and table.concat(kept.player, "/"), "RED/ASH/JACK",
    "...and the naming menu keeps RED / ASH / JACK")
  eq(kept and table.concat(kept.rival, "/"), "BLUE/GARY/JOHN",
    "...and the rival keeps BLUE / GARY / JOHN")
  ok(mod.content.sprites.patches.SPRITE_RED ~= nil,
    "...and the character is still green: the rows are independent")
end

io.write("main.lua -- PLAYER = RED\n")
do
  local mod = run({ player = "red", ribbon = true })
  ok(next(mod.content.sprites.patches) == nil,
    "no sprite is repointed: the character is vanilla again")
  ok(mod.hooks.wrapped["player.sprite"] == nil,
    "player.sprite is not even wrapped, so the pics stay vanilla")
  ok(mod.content.palettes.overrides.MEWMON == nil,
    "and the title figure is red again with him")
  ok(mod.content.field.patches.boot == nil
     or mod.content.field.patches.boot.playerName == nil,
    "and the default name stays RED")

  local boot = mod.content.field.patches.boot
  eq(boot and boot.title and boot.title.versionRibbon,
    "mods/wild_green/assets/title/wild_green_version.png",
    "the ribbon still says WILD GREEN VERSION -- it is the game's name")
  ok(mod.content.palettes.overrides.LOGO1 ~= nil,
    "...and the band is still green")
end

io.write("main.lua -- TITLE FIGURE off\n")
do
  local mod = run({ player = "green", ribbon = true, title_figure = false })
  ok(mod.content.palettes.overrides.MEWMON == nil,
    "the title figure goes back to the base game's colours")
  ok(mod.content.palettes.overrides.LOGO1 ~= nil,
    "...and the ribbon band stays green: the rows are independent")
end

io.write("main.lua -- TITLE RIBBON off\n")
do
  local mod = run({ player = "green", ribbon = false })
  local boot = mod.content.field.patches.boot
  -- With the figure no longer patched, TITLE RIBBON off leaves nothing for
  -- boot.title to carry, so the key is absent rather than empty.
  ok(boot == nil or boot.title == nil or boot.title.versionRibbon == nil,
    "the imported ribbon comes back")
  ok(mod.content.palettes.overrides.LOGO1 == nil,
    "...and so does the imported band colour")
  ok(mod.content.sprites.patches.SPRITE_RED ~= nil,
    "the player is still green: the two rows are independent")
end

io.write("main.lua -- a profile with no stored options\n")
do
  local mod = run({})
  ok(mod.content.sprites.patches.SPRITE_RED ~= nil,
    "an unanswered PLAYER falls back to green")
  ok(mod.content.palettes.overrides.LOGO1 ~= nil,
    "an unanswered TITLE RIBBON falls back to on")
end

io.write("main.lua -- a player already reskinned by another mod\n")
do
  -- greenOf declines a path we have no green for, so a record another mod
  -- has already pointed elsewhere is left where it points
  local mod = fakeMod({ player = "green", ribbon = true })
  mod.content.sprites.base.SPRITE_RED.image = "mods/some_other/hero.png"
  chunk(MOD .. "main.lua")(mod)
  ok(mod.content.sprites.patches.SPRITE_RED == nil,
    "a walker that is not vanilla art is not fought over")
end

-- ------- the title screen's standing figure, under REDPP
--
-- MEWMON colours him in every mode that runs the SGB zone pass.  ADVANCED
-- (PaletteFX.mode "redpp") does not run it over his rectangle, and Crystal
-- Animated Sprites -- which the cart pins -- luminance-bakes his grey art to
-- Red's own white / skin / red / navy there so he is not left grey.  That
-- bake is downstream of every seam this mod has, which is why the figure
-- stayed red through 1.3.0.  main.lua wraps TitleState.currentSprite from
-- outside it, captures the grey art on the way in and paints it green on the
-- way out.
--
-- The stubs below are that screen: an ImageData that can be cloned and
-- mapped, a love.graphics that makes an image out of one, a PaletteFX with a
-- mode and a markTrueColor, and an inner currentSprite that bakes red first
-- the way Crystal's does.

local RED_BAKE = { { 255, 255, 255 }, { 236, 168, 120 },
                   { 216, 64, 48 }, { 56, 64, 120 } }

-- Both verbs on every copy: a canvas readback hands back a real ImageData
-- that can be mapped straight away, and a cloned one can be too.
local function fakeImageData(rows)
  local data = { rows = rows }
  function data:mapPixel(fn)
    self.out = {}
    for y = 1, #self.rows do
      self.out[y] = {}
      for x = 1, #self.rows[y] do
        local v = self.rows[y][x] / 255
        local r, g, b, a = fn(x - 1, y - 1, v, v, v, 1)
        self.out[y][x] = { math.floor(r * 255 + .5),
                           math.floor(g * 255 + .5),
                           math.floor(b * 255 + .5), a }
      end
    end
    return self
  end
  function data:clone() return fakeImageData(self.rows) end
  return data
end

-- `getData` is the LOVE 10 shape.  Under LOVE 11 a graphics Image does NOT
-- keep the ImageData it was built from and has no getData at all, so the
-- pixels have to come back off a canvas -- which is the whole of the 1.4.0
-- bug: it called getData, gave up when it was not there, and left the figure
-- exactly as it found it.  `legacy` picks which engine the stub is.
local function fakeTitleImage(rows, legacy)
  local image = { rows = rows, kind = "raw" }
  if legacy then
    function image:getData() return fakeImageData(self.rows) end
  end
  function image:getDimensions() return #self.rows[1], #self.rows end
  function image:setFilter() end
  return image
end

-- the whole screen: fresh modules, a fresh global love, one title instance.
-- `lazy` is the art the inner link loads for itself, the way a screen that
-- builds its own picture inside currentSprite would -- there is nothing to
-- capture on the way in then, and the fallback is what has to find it.
local function inner_kind(image)
  return type(image) == "table" and image.kind or tostring(image)
end

local function titleScreen(options, mode, lazy, cache)
  cache = cache or {}
  local marks = {}
  local PaletteFX = {
    mode = mode,
    markTrueColor = function(x, y, w, h)
      marks[#marks + 1] = { x = x, y = y, w = w, h = h }
    end,
  }
  local inner = { calls = 0, draws = 0 }
  local TitleState = {}
  -- the real draw takes `local playerImage = self.player` at the top and
  -- only calls currentSprite further down -- and not at all in one phase.
  -- The stub is that shape, so a fix that only touches currentSprite fails.
  function TitleState:draw()
    inner.draws = inner.draws + 1
    inner.drew = self.player
    -- the stub's title tables are plain, so reach the wrapper by name the
    -- way the engine reaches it through TitleState's metatable
    if not self.skipSprite then TitleState.currentSprite(self) end
  end
  -- Crystal's link: under redpp it replaces the art with its own red bake
  -- and flags it, and out of redpp it puts the untouched art back.
  function TitleState:currentSprite()
    inner.calls = inner.calls + 1
    if lazy then self.player = self.player or lazy end
    if PaletteFX.mode == "redpp" then
      if not self.__crystalPlayerRaw then self.__crystalPlayerRaw = self.player end
      if not self.__crystalTrainerBaked then
        local red = { kind = "red bake" }
        function red:getDimensions() return 16, 24 end
        function red:setFilter() end
        self.player = red
        self.__crystalTrainerBaked = true
      end
    elseif self.__crystalTrainerBaked then
      self.player = self.__crystalPlayerRaw
      self.__crystalTrainerBaked = nil
    end
    return "the cycling mon", true
  end

  -- the recipe's own copy of the figure, reached the way the engine reaches
  -- a derived file: Assets.image over an "assets/generated/..." path
  local asked = {}
  local Assets = { image = function(path)
    asked[#asked + 1] = path
    if not cache[path] then return nil, "no such file" end
    local image = { kind = "derived", path = path }
    function image:getDimensions() return 8, 12 end
    function image:setFilter() end
    return image
  end }

  package.loaded["src.ui.TitleState"] = TitleState
  package.loaded["src.render.PaletteFX"] = PaletteFX
  package.loaded["src.render.Assets"] = Assets

  -- left installed on purpose: main.lua reads the `love` global when it
  -- bakes, which is at currentSprite time and not at load
  local made = {}
  local gfx = { canvas = nil, blend = "alpha", alphaMode = "alphamultiply",
                colour = { 1, 1, 1, 1 }, depth = 0, drawn = nil, leaked = nil }
  _G.love = { graphics = {
    newImage = function(data)
      local image = { data = data, kind = "baked" }
      function image:getDimensions()
        return #self.data.rows[1], #self.data.rows
      end
      function image:setFilter() end
      made[#made + 1] = image
      return image
    end,
    -- the canvas readback, close enough to answer whether main.lua drives it
    -- correctly: the pixels come back, and the screen is put back
    newCanvas = function(w, h)
      local canvas = { w = w, h = h }
      function canvas:newImageData()
        return fakeImageData(gfx.drawn and gfx.drawn.rows or {})
      end
      function canvas:release() end
      return canvas
    end,
    getCanvas = function() return gfx.canvas end,
    setCanvas = function(c) gfx.canvas = c end,
    clear = function() end,
    getBlendMode = function() return gfx.blend, gfx.alphaMode end,
    setBlendMode = function(b, a) gfx.blend, gfx.alphaMode = b, a end,
    getColor = function() return unpack(gfx.colour) end,
    setColor = function(r, g, b, a) gfx.colour = { r, g, b, a } end,
    push = function() gfx.depth = gfx.depth + 1 end,
    origin = function() end,
    pop = function() gfx.depth = gfx.depth - 1 end,
    draw = function(image)
      -- drawing into a canvas that is not set is the mistake this catches
      if not gfx.canvas then gfx.leaked = "drew with no canvas set" end
      gfx.drawn = image
    end,
  } }

  local mod = fakeMod(options)
  chunk(MOD .. "main.lua")(mod)

  package.loaded["src.ui.TitleState"] = nil
  package.loaded["src.render.PaletteFX"] = nil
  package.loaded["src.render.Assets"] = nil

  return {
    mod = mod, TitleState = TitleState, PaletteFX = PaletteFX,
    marks = marks, inner = inner, made = made, gfx = gfx, asked = asked,
    -- one 4x2 strip in the four grey shades the importer writes, in the
    -- shape LOVE 11 hands over: no getData on it
    raw = fakeTitleImage({ { W, S, O, K }, { W, S, O, K } }),
  }
end

io.write("main.lua -- the title figure under REDPP\n")
do
  local screen = titleScreen({ player = "green", ribbon = true }, "redpp")
  local title = { player = screen.raw }

  local image, trueColor = screen.TitleState.currentSprite(title)
  eq(image, "the cycling mon", "the inner link's return is passed through")
  eq(trueColor, true, "...and so is its true-colour answer")
  eq(screen.inner.calls, 1, "the inner link ran exactly once")

  ok(title.player ~= nil and title.player.kind == "baked",
    "the figure is this mod's bake, not the red one downstream of it")
  eq(title.__wildGreenRaw, screen.raw,
    "the grey art was captured on the way in, before the red bake")

  local px = title.player.data.out
  eq(hex(px[1][1]), "ffffff", "shade 1 is paper")
  eq(hex(px[1][2]), "a8dd8a", "shade 2 is the light green, as on the card")
  eq(hex(px[1][3]), "65ba3f", "shade 3 is the outfit green")
  eq(hex(px[1][4]), "000000", "shade 4 is ink")

  eq(#screen.marks, 1, "the strip is marked true-colour")
  eq(screen.marks[1] and screen.marks[1].w, 4, "...at the baked art's width")
  eq(screen.marks[1] and screen.marks[1].h, 2, "...and its height")

  -- the flag that stops the red bake coming back a frame later
  eq(title.__crystalTrainerBaked, true,
    "the downstream bake is flagged done, so it does not repaint him")

  local first = title.player
  screen.TitleState.currentSprite(title)
  eq(title.player, first, "a second frame keeps the same baked image")
  eq(screen.inner.calls, 2, "...and still runs the inner link")
end

io.write("main.lua -- reading an Image's pixels back\n")
do
  -- 1.4.0 called Image:getData and gave up when it was not there.  Under
  -- LOVE 11 it never is: the texture does not keep the ImageData it was
  -- built from.  So the bake failed on the first frame, cached the failure,
  -- and the figure kept the red one downstream of it -- the release changed
  -- nothing on screen.  The pixels come off a canvas now.
  local screen = titleScreen({ player = "green", ribbon = true }, "redpp")
  local title = { player = screen.raw }
  ok(screen.raw.getData == nil,
    "the stub is the LOVE 11 shape: no getData on a graphics Image")

  screen.TitleState.currentSprite(title)
  ok(title.player ~= nil and title.player.kind == "baked",
    "the figure is baked anyway -- the pixels came off a canvas")
  eq(hex(title.player.data.out[1][3]), "65ba3f",
    "...and they are the right pixels, in the outfit green")
  eq(screen.gfx.drawn, screen.raw,
    "the art itself was the thing drawn into the canvas")

  -- and the screen is handed back exactly as it was found: currentSprite can
  -- run mid-draw, so a canvas or a blend mode left behind is a corrupted frame
  ok(screen.gfx.leaked == nil, "nothing was drawn with no canvas set")
  eq(screen.gfx.canvas, nil, "the canvas is put back")
  eq(screen.gfx.blend, "alpha", "the blend mode is put back")
  eq(screen.gfx.depth, 0, "the transform stack is balanced")
  eq(screen.gfx.colour[1], 1, "the draw colour is put back")

  -- the old shape still works, and never touches the graphics state at all
  local legacy = titleScreen({ player = "green", ribbon = true }, "redpp")
  local old = { player = fakeTitleImage({ { W, S, O, K } }, true) }
  legacy.TitleState.currentSprite(old)
  ok(old.player ~= nil and old.player.kind == "baked",
    "an Image that does have getData is baked through it")
  eq(legacy.gfx.drawn, nil, "...and no canvas is touched for it")
end

io.write("main.lua -- the title figure prefers the recipe's copy\n")
do
  -- The bake is flat green: it works off the shade buckets and knows nothing
  -- about where a face is.  The recipe's copy of the same picture has the
  -- face, the ear and the hands on it already, so that is what the draw gets
  -- when there is one -- and the bake is what is left when there is not.
  local have = { ["assets/generated/greenskin/title/player.png"] = true }
  local screen = titleScreen({ player = "green", ribbon = true }, "redpp", nil, have)
  local title = { player = screen.raw,
                  playerPath = "assets/generated/title/player.png" }
  screen.TitleState.currentSprite(title)
  eq(title.player and title.player.kind, "derived",
    "the figure is the recipe's copy, not a bake")
  eq(title.player and title.player.path,
    "assets/generated/greenskin/title/player.png",
    "...the skinned one, because PORTRAIT SKIN is on")
  eq(screen.gfx.drawn, nil, "and no canvas was touched for it")

  -- PORTRAIT SKIN off asks for the flat copy instead
  local flat = { ["assets/generated/green/title/player.png"] = true }
  local off = titleScreen({ player = "green", portrait_skin = false },
                          "redpp", nil, flat)
  local t2 = { player = off.raw,
               playerPath = "assets/generated/title/player.png" }
  off.TitleState.currentSprite(t2)
  eq(t2.player and t2.player.path, "assets/generated/green/title/player.png",
    "off, the figure is the flat copy")

  -- and a cache with no such file still gets a figure, baked
  local none = titleScreen({ player = "green", ribbon = true }, "redpp", nil, {})
  local t3 = { player = none.raw,
               playerPath = "assets/generated/title/player.png" }
  none.TitleState.currentSprite(t3)
  eq(t3.player and t3.player.kind, "baked",
    "with no derived copy, the bake still runs")
  eq(hex(t3.player.data.out[1][3]), "65ba3f", "...and it is still green")
end

io.write("main.lua -- a derived copy that arrives late is still picked up\n")
do
  -- The recipe's copy is a file, and on the first boot after an install it
  -- can arrive after this screen does.  Settling for the flat bake for the
  -- life of the screen is what would make a fresh install show a faceless
  -- green figure until the next launch.
  local have = {}
  local screen = titleScreen({ player = "green", ribbon = true }, "redpp", nil, have)
  local title = { player = screen.raw,
                  playerPath = "assets/generated/title/player.png" }

  screen.TitleState.currentSprite(title)
  eq(inner_kind(title.player), "baked",
    "with no file there yet, the flat bake carries the screen")

  -- the transform finishes and the file appears
  have["assets/generated/greenskin/title/player.png"] = true
  local found = false
  for _ = 1, 200 do
    screen.TitleState.currentSprite(title)
    if inner_kind(title.player) == "derived" then found = true break end
  end
  ok(found, "...and the copy is picked up once it is there")
  eq(inner_kind(title.player), "derived", "the figure is the recipe's copy")

  -- and once it has it, it stops asking
  local asked = #screen.asked
  for _ = 1, 50 do screen.TitleState.currentSprite(title) end
  eq(#screen.asked, asked, "no more file loads once the copy is in hand")
end

io.write("main.lua -- the figure is asserted before the draw reads it\n")
do
  -- TitleState:draw captures self.player at the top and calls currentSprite
  -- below it -- and skips currentSprite entirely for one phase of the title
  -- animation.  Asserting the figure only from currentSprite therefore draws
  -- the previous picture, and for that whole phase draws Crystal's red bake.
  local have = { ["assets/generated/greenskin/title/player.png"] = true }
  local screen = titleScreen({ player = "green", ribbon = true }, "redpp", nil, have)
  local title = { player = screen.raw,
                  playerPath = "assets/generated/title/player.png" }

  screen.TitleState.draw(title)
  eq(inner_kind(screen.inner.drew), "derived",
    "the very first draw already has the green figure, not the one before it")

  -- and the phase that never calls currentSprite at all
  title.skipSprite = true
  title.ballY = 96
  local before = screen.inner.calls
  local marks = #screen.marks
  screen.TitleState.draw(title)
  eq(screen.inner.calls, before, "this phase really does skip currentSprite")
  eq(inner_kind(screen.inner.drew), "derived",
    "...and the figure is still green through it")

  -- ...and marked, or the zone pass repaints it MEWMON purple over the top
  ok(#screen.marks > marks,
    "the figure's rect is marked true-colour from the draw as well -- "
    .. "currentSprite is what this phase skips, and it is what marks")
  local last = screen.marks[#screen.marks]
  local figure, ball = false, false
  for i = marks + 1, #screen.marks do
    local m = screen.marks[i]
    if m.x == 82 and m.y == 80 then figure = true end
    if m.x == 82 and m.y == 96 and m.w == 8 and m.h == 8 then ball = true end
  end
  ok(figure, "the figure's own rect at 82,80")
  ok(ball, "and the ball's, which this phase is the whole point of")
  ok(last ~= nil, "at least one mark was recorded")
end

io.write("main.lua -- the title figure out of REDPP\n")
do
  -- every other mode runs the zone pass, and MEWMON is what colours him:
  -- the grey art has to go back or he would be painted twice
  local screen = titleScreen({ player = "green", ribbon = true }, "redpp")
  local title = { player = screen.raw }
  screen.TitleState.currentSprite(title)
  ok(title.player.kind == "baked", "green under redpp")

  screen.PaletteFX.mode = "sgb"
  screen.TitleState.currentSprite(title)
  eq(title.player, screen.raw, "the grey art is handed back for the zone pass")
  ok(title.__crystalTrainerBaked == nil, "...and the downstream flag with it")
  eq(#screen.marks, 1, "nothing new is marked true-colour")

  screen.PaletteFX.mode = "redpp"
  screen.TitleState.currentSprite(title)
  ok(title.player.kind == "baked", "back into redpp and he is green again")
end

io.write("main.lua -- the title figure when the art arrives late\n")
do
  -- a screen that loads its own art inside currentSprite gives this nothing
  -- to capture on the way in; Crystal's capture of the same untouched
  -- picture is what it falls back to, never the bake that is on screen
  local raw = fakeTitleImage({ { W, S, O, K }, { W, S, O, K } })
  local screen = titleScreen({ player = "green", ribbon = true }, "redpp", raw)
  local title = {}

  screen.TitleState.currentSprite(title)
  eq(title.__wildGreenRaw, raw, "the untouched art is found, not the bake")
  ok(title.player ~= nil and title.player.kind == "baked",
    "...and the figure is baked green from it")
  eq(hex(title.player.data.out[1][3]), "65ba3f", "...in the outfit green")
end

io.write("main.lua -- the title figure is not always wrapped\n")
do
  local off = titleScreen({ player = "green", title_figure = false }, "redpp")
  ok(off.TitleState.__wildGreenFigure == nil,
    "TITLE FIGURE off leaves TitleState alone entirely")

  local red = titleScreen({ player = "red" }, "redpp")
  ok(red.TitleState.__wildGreenFigure == nil,
    "PLAYER = RED leaves TitleState alone too")

  -- a boot with no love and no engine modules is the headless case, and it
  -- must cost the figure and nothing else
  _G.love = nil
  local mod = fakeMod({ player = "green", ribbon = true })
  chunk(MOD .. "main.lua")(mod)
  ok(mod.content.sprites.patches.SPRITE_RED ~= nil,
    "with no TitleState to wrap, the rest of the mod still lands")
end

io.write(("\n%d passed, %d failed\n"):format(passed, failed))
os.exit(failed == 0 and 0 or 1)
