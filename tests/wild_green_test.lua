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
  { K, K, K, K, K, K, K },   -- 12
  { K, K, K, K, K, K, K },   -- 13
  { K, K, K, K, K, K, K },   -- 14
  { K, K, K, K, K, K, K },   -- 15
}

local function hex(c) return ("%02x%02x%02x"):format(c[1], c[2], c[3]) end

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

io.write("transforms.lua -- the face on a portrait\n")
do
  -- Shade 2 on a portrait is the light for everything, so nothing about the
  -- shade says which of it is the face.  What does: the face is the only
  -- patch of it with EYES in it -- islands of ink whose every neighbour is
  -- that one patch.  The cap's front, the shirt's shading and the knees
  -- below have nothing inside them, and the outline runs off the edge of the
  -- art rather than being an island.
  local PORTRAIT = {
    { W, W, K, K, K, K, K, K, W, W, W, W },  -- 0  the cap's outline
    { W, K, O, O, O, O, O, O, K, W, W, W },  -- 1  the cap
    { W, K, O, O, O, O, O, O, K, W, W, W },  -- 2
    { W, K, S, S, S, S, S, S, K, W, W, W },  -- 3  the face
    { W, K, S, K, S, S, K, S, K, W, W, W },  -- 4  two eyes, enclosed by it
    { W, K, S, S, S, S, S, S, K, W, W, W },  -- 5
    { W, K, S, S, S, S, S, S, K, W, W, W },  -- 6
    { W, W, K, K, K, K, K, K, W, W, W, W },  -- 7  the jaw
    { W, W, K, O, O, O, O, K, W, W, W, W },  -- 8  the shirt
    { W, W, K, O, S, S, O, K, W, W, W, W },  -- 9  its highlight: shade 2,
    { W, W, K, O, S, S, O, K, W, W, W, W },  -- 10 and no eyes in it
    { W, W, K, O, O, O, O, K, W, W, W, W },  -- 11
    { W, W, W, K, S, S, K, W, W, W, W, W },  -- 12 the knees: shade 2 again
    { W, W, W, K, K, K, K, W, W, W, W, W },  -- 13
  }

  local ctx = fakeCtx({ ["trainer_card/red.png"] = PORTRAIT })
  chunk(MOD .. "transforms.lua")(ctx)

  local plain = ctx.written["green/trainer_card/red.png"]
  local skin = ctx.written["greenskin/trainer_card/red.png"]
  ok(plain ~= nil and skin ~= nil, "both copies of the portrait are written")

  -- the monochrome copy is untouched by any of this
  eq(hex(plain.out[4][3]), "a8dd8a", "green/ leaves the face the light green")
  eq(hex(plain.out[10][5]), "a8dd8a", "...and the shirt's highlight with it")

  -- and the skinned copy paints the face, and only the face
  eq(hex(skin.out[4][3]), "f0a363", "greenskin/ paints the face skin")
  eq(hex(skin.out[6][3]), "f0a363", "...all of it, not just the eye row")
  eq(hex(skin.out[5][4]), "000000", "the eyes stay ink")
  eq(hex(skin.out[2][3]), "65ba3f", "the cap is still the outfit green")
  eq(hex(skin.out[10][5]), "a8dd8a",
    "the shirt's highlight is still the light green -- no eyes in it")
  eq(hex(skin.out[13][5]), "a8dd8a", "...and so are the knees")
  eq(hex(skin.out[1][1]), "ffffff", "the ground is still paper")
end

io.write("transforms.lua -- the face rule fails closed\n")
do
  -- No eyes, so no face, so the skinned copy is the monochrome one.  This is
  -- the battle BACK pic's case, and the case of any art the rule does not
  -- fit: the worst it can do is nothing.
  local NO_EYES = {
    { W, W, K, K, K, K, K, K, W, W, W, W },
    { W, K, O, O, O, O, O, O, K, W, W, W },
    { W, K, S, S, S, S, S, S, K, W, W, W },
    { W, K, S, S, S, S, S, S, K, W, W, W },
    { W, K, S, S, S, S, S, S, K, W, W, W },
    { W, W, K, K, K, K, K, K, W, W, W, W },
  }
  local ctx = fakeCtx({ ["battle/redb.png"] = NO_EYES })
  chunk(MOD .. "transforms.lua")(ctx)
  local skin = ctx.written["greenskin/battle/redb.png"]
  ok(skin ~= nil, "the skinned copy is still written")
  eq(hex(skin.out[3][3]), "a8dd8a",
    "with no eyes to find, nothing is painted skin")
  eq(hex(skin.out[2][3]), "65ba3f", "and the outfit is untouched")
end

do
  -- Two patches that both look like a face is not two faces found, it is a
  -- rule that does not fit this picture.  It declines rather than guessing.
  local HEAD = {
    { W, W, K, K, K, K, K, K, W, W, W, W },
    { W, K, O, O, O, O, O, O, K, W, W, W },
    { W, K, S, S, S, S, S, S, K, W, W, W },
    { W, K, S, K, S, S, K, S, K, W, W, W },
    { W, K, S, S, S, S, S, S, K, W, W, W },
    { W, W, K, K, K, K, K, K, W, W, W, W },
  }
  local TWO = {}
  for _ = 1, 2 do
    for _, row in ipairs(HEAD) do TWO[#TWO + 1] = row end
  end
  local ctx = fakeCtx({ ["credits/red.png"] = TWO })
  chunk(MOD .. "transforms.lua")(ctx)
  local skin = ctx.written["greenskin/credits/red.png"]
  eq(hex(skin.out[3][3]), "a8dd8a",
    "two candidate faces means none is painted")
  eq(hex(skin.out[9][3]), "a8dd8a", "...on either of them")
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
  eq(count, 6, "only what this cache carries is written")
  ok(wrote["greenskin/battle/redb.png"] and wrote["greenskin/trainer_card/red.png"],
    "...and every portrait gets a skinned twin beside it")
  ok(not wrote["greenskin/sprites/red.png"],
    "an overworld sheet gets no skinned twin: it already has a face rule")
  for _, rel in ipairs({ "sprites/red.png", "sprites/red_bike.png",
                         "battle/redb.png", "trainer_card/red.png" }) do
    ok(wrote["green/" .. rel], "green/" .. rel .. " written")
  end
  -- The title figure is painted by shade, not by colour -- the zone pass in
  -- most modes, another mod's luminance bake under REDPP -- so a recoloured
  -- file for him is thrown away before it reaches the screen.  He is
  -- coloured at the other end instead; see the REDPP section below.
  ok(not wrote["green/title/player.png"],
    "the title screen's standing figure is not recoloured")
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

local function fakeRegistry(base, log)
  local registry = { base = base, patches = {}, overrides = {} }
  function registry:get(id) return self.base[id] end
  function registry:each()
    return coroutine.wrap(function()
      for id, def in pairs(self.base) do coroutine.yield(id, def) end
    end)
  end
  function registry:patch(id, partial)
    self.patches[id] = partial
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
      boot = { startMap = "REDS_HOUSE_2F" },
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
    "the title's standing figure is not swapped -- it is coloured, not swapped")
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
end
do
  local mod = run({ player = "green", ribbon = true, name = false })
  local boot = mod.content.field.patches.boot
  ok(boot == nil or boot.playerName == nil,
    "DEFAULT NAME GREEN off leaves the vanilla default alone")
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

local function fakeImageData(rows)
  local data = { rows = rows }
  function data:clone()
    local copy = { rows = self.rows }
    copy.clone = data.clone
    function copy:mapPixel(fn)
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
    return copy
  end
  return data
end

local function fakeTitleImage(rows)
  local image = { rows = rows, kind = "raw" }
  function image:getData() return fakeImageData(self.rows) end
  function image:getDimensions() return #self.rows[1], #self.rows end
  function image:setFilter() end
  return image
end

-- the whole screen: fresh modules, a fresh global love, one title instance.
-- `lazy` is the art the inner link loads for itself, the way a screen that
-- builds its own picture inside currentSprite would -- there is nothing to
-- capture on the way in then, and the fallback is what has to find it.
local function titleScreen(options, mode, lazy)
  local marks = {}
  local PaletteFX = {
    mode = mode,
    markTrueColor = function(x, y, w, h)
      marks[#marks + 1] = { x = x, y = y, w = w, h = h }
    end,
  }
  local inner = { calls = 0 }
  local TitleState = {}
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

  package.loaded["src.ui.TitleState"] = TitleState
  package.loaded["src.render.PaletteFX"] = PaletteFX

  -- left installed on purpose: main.lua reads the `love` global when it
  -- bakes, which is at currentSprite time and not at load
  local made = {}
  _G.love = { graphics = { newImage = function(data)
    local image = { data = data, kind = "baked" }
    function image:getDimensions() return #self.data.rows[1], #self.data.rows end
    function image:setFilter() end
    made[#made + 1] = image
    return image
  end } }

  local mod = fakeMod(options)
  chunk(MOD .. "main.lua")(mod)

  package.loaded["src.ui.TitleState"] = nil
  package.loaded["src.render.PaletteFX"] = nil

  return {
    mod = mod, TitleState = TitleState, PaletteFX = PaletteFX,
    marks = marks, inner = inner, made = made,
    -- one 4x2 strip in the four grey shades the importer writes
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
