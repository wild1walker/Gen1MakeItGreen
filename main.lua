-- Wild Green
--
-- The player is green, he is called GREEN, and the title screen says so.
-- That is the whole mod.
--
-- It is the identity half of the Wild Green cart: the cart pins the two
-- Gen1Wild bundles for everything a playthrough actually does, and this
-- supplies the one thing a pinned mod set cannot -- a game that looks like
-- its own version rather than like Red with things added.
--
-- ------- the seams it uses, and why each one
--
--   player.sprite      the battle back pic and the front pic that Oak's
--                      intro, the trainer card and the Hall of Fame share.
--                      A HOOK, not a registry write: those paths are not in
--                      data.field at all.  Sprites.playerPath resolves them
--                      through FieldDefaults.fieldValue, so
--                      `field:get("playerPics")` hands back nothing and a
--                      patch built from it silently patches nothing -- which
--                      is exactly what 1.0.0 did, and why the player stayed
--                      red everywhere except the overworld.  The hook runs
--                      over the ALREADY-RESOLVED path, so it needs no guess
--                      about where the vanilla art lives.
--   sprites            the overworld walker.  A real record, so a patch does
--                      land -- and being a record it is decided at load, so
--                      PLAYER takes effect on the next launch.
--   field.boot.title   the title screen's version ribbon.  boot.title is the
--                      mod-reachable half of field.title, which the field
--                      schema does not expose.
--   palettes MEWMON    the title screen's standing figure, which has no
--                      per-image seam and is coloured by its zone palette.
--   field.boot         playerName, so the game offers GREEN where it used to
--                      offer RED.
--   palettes LOGO1     the SGB palette the title's ribbon band wears.
--
-- None of the green pixels are here.  Every recoloured picture is written by
-- transforms.lua out of the player's own imported cache, under a "green/"
-- prefix that shadows nothing, and this file points the art at it.  Read
-- that file first: it explains the prefix, and why shade 2 is the face.

return function(mod)
  local CACHE = "assets/generated/"
  local GREEN = CACHE .. "green/"

  -- The character's four, lightest first: paper, skin, outfit, ink.  A copy
  -- of the ramp in transforms.lua, which cannot be imported from --
  -- tools/check.py fails the build if the two drift apart.  It is here for
  -- MEWMON, the title screen's own palette; the recolouring itself is the
  -- recipe's job.
  local WILD_GREEN = {
    { 0xff, 0xff, 0xff },
    { 0xf0, 0xa3, 0x63 },
    { 0x65, 0xba, 0x3f },
    { 0x00, 0x00, 0x00 },
  }

  -- The ribbon band is lettering on white, not a sprite, so it does not use
  -- the character ramp.  It gets its own four, and both greens are dark
  -- enough to read as ink at 8px: 1.0.0 lent it the character's light green
  -- and it washed out on the title screen.
  local WILD_GREEN_TITLE = {
    { 0xff, 0xff, 0xff },
    { 0x2e, 0x8b, 0x3a },
    { 0x14, 0x57, 0x1f },
    { 0x00, 0x00, 0x00 },
  }

  mod.options:define({
    -- The character, and the only thing here a player is likely to want both
    -- ways: GREEN is what the cart is for, RED is the vanilla art untouched.
    -- The overworld walker is a record, so this lands on the next launch;
    -- the battle and card pics follow the hook and change immediately.
    { key = "player", type = "choice", label = "PLAYER",
      choices = { { "GREEN", "green" }, { "RED", "red" } },
      default = "green" },
    -- The title screen's version ribbon and the band it sits in.
    { key = "ribbon", type = "toggle", label = "TITLE RIBBON",
      default = true },
    -- The standing figure on the title screen.  Its own row because it is
    -- the one change here with a visible cost: see the note at the override.
    { key = "title_figure", type = "toggle", label = "TITLE FIGURE",
      default = true },
    -- The name the game offers before you type one.  Its own row because a
    -- default name is the one thing here that ends up written into a save.
    { key = "name", type = "toggle", label = "DEFAULT NAME GREEN",
      default = true },
  })

  -- options:get can throw on a profile that has never stored a value for a
  -- row; every mod in the suite reads through a guard like this one.
  local function option(key, fallback)
    local ok, value = pcall(function() return mod.options:get(key) end)
    if not ok or value == nil then return fallback end
    return value
  end

  local green = option("player", "green") == "green"

  -- Exactly the pictures transforms.lua recolours, and the only ones this
  -- will swap.  It is the same list, in the same order, and tools/check.py
  -- compares the two -- because a swap to a green file the recipe did not
  -- write does not fall back to the red one, it draws nothing at all.
  local RECOLOURED = {
    "sprites/red.png",
    "sprites/red_bike.png",
    "battle/redb.png",
    "battle/back/redb.png",
    "trainer_card/red.png",
    "credits/red.png",
    "intro/red.png",
    "hall_of_fame/red.png",
  }

  local KNOWN = {}
  for _, rel in ipairs(RECOLOURED) do KNOWN[rel] = true end

  -- The green twin of a cache path, or nil when there is not one.
  local function greenOf(path)
    if type(path) ~= "string" then return nil end
    local rel = path:match("^" .. CACHE .. "(.+)$")
    if not rel or not KNOWN[rel] then return nil end
    return GREEN .. rel
  end

  -- Registry writes are pcall'd one at a time rather than in a block: a
  -- schema that has moved under us should cost the thing it names and not
  -- the four that were fine.
  local function try(what, fn)
    local ok, problem = pcall(fn)
    if not ok then
      mod.log:warn("%s: %s", what, tostring(problem))
    end
    return ok
  end

  -- ------- the character

  if green then
    -- The battle back pic, and the front pic Oak's intro, the trainer card
    -- and the Hall of Fame share.  ctx.demo is the catch tutorial's old man
    -- and ctx.oakDemo is Yellow's PROF.OAK -- neither is the player, and
    -- neither should turn green.
    -- Every distinct path this hook is handed, said once.  1.1.1 swapped the
    -- battle back pic and left the trainer card red, and there was no way to
    -- tell from outside whether the hook never ran, or ran and declined a
    -- path that is not shaped the way this expects.  One line per pic per
    -- session answers that without a debugger.
    local seen = {}
    local function note(path, ctx, verdict)
      if seen[path] then return end
      seen[path] = true
      mod.log:info("player.sprite %s/%s -> %s (%s)",
        tostring(ctx.kind), tostring(ctx.side), tostring(path), verdict)
    end

    -- ------- priority 940, and why it is not 0
    --
    -- Hooks:call walks the chain highest priority first, and a link that
    -- returns without calling next() ends it there (src/mods/Hooks.lua).
    -- Crystal Animated Sprites -- which this cart pins -- wraps player.sprite
    -- at 930 and does exactly that: when its PLAYER SPRITE option names a
    -- portrait it returns its own file and never calls next().
    --
    -- So at the default priority of 0 this link sat downstream of a chain
    -- that never reached it, and the battle back pic, the trainer card, Oak's
    -- intro and the Hall of Fame stayed red no matter what was done to them.
    -- Every attempt at those pictures from 1.0.0 to 1.1.4 was aimed at the
    -- wrong end of the problem.
    --
    -- 940 puts this one link outside that one, and no further up than it has
    -- to be.  The swap is computed from the path this link is HANDED, not
    -- from what downstream would answer -- downstream is where the
    -- substitution happens, and the point is to get in front of it.
    --
    -- The cost is real and is the PLAYER row's to pay: with GREEN the
    -- player's own portrait is the recoloured vanilla art, so a portrait
    -- chosen in CRYSTAL SPRITES > PLAYER SPRITE does not apply to the player.
    -- RED hands that back. Opponent portraits, the animated battle sprites
    -- and the shiny work are untouched either way -- this link only ever
    -- answers for the player.
    mod.hooks:wrap("player.sprite", function(next, path, ctx)
      if ctx.demo or ctx.oakDemo then
        note(path, ctx, "left alone: not the player")
        return next(path, ctx)
      end
      local swapped = greenOf(path)
      if not swapped then
        note(path, ctx, "NOT SWAPPED: outside " .. CACHE)
        return next(path, ctx)
      end
      note(path, ctx, "green")
      -- Drawn as written: without this the palette pass reads our green
      -- through the same red-channel shade buckets it reads grey art
      -- through and remaps it to something else entirely.
      ctx.trueColor = true
      return swapped
    end, 940)

    -- Every sprite record drawn from cache art: SPRITE_RED and, where the
    -- import wrote one, the BICYCLE sheet.  Found by image rather than by id
    -- so a name this mod guessed wrong is simply not matched.  A walker
    -- another mod has already reskinned points outside the cache, so
    -- greenOf declines it and this does not fight over it.
    try("sprites", function()
      for id, def in mod.content.sprites:each() do
        local image = type(def) == "table" and def.image
        if type(image) == "string" and image:match("red") then
          local swapped = greenOf(image)
          if swapped then
            mod.content.sprites:patch(id, { image = swapped, trueColor = true })
          end
        end
      end
    end)
  end

  -- ------- the name and the title screen
  --
  -- Both live under field.boot, and they go in as ONE patch.  Two calls
  -- would be two writes to the same id, and the second is what the merge
  -- keeps -- which quietly cost the default name when this was written as
  -- two.

  local bootPatch, title = {}, {}

  -- GREEN where the game used to offer RED.  It follows the character: a
  -- player who has switched back to the red sprite is playing as RED.
  if green and option("name", true) then
    bootPatch.playerName = "GREEN"
  end

  if option("ribbon", true) then
    -- versionRibbon, not version: the importer's key is the vanilla pair of
    -- fragments the draw pass repositions, and ours is one continuous strip.
    -- TitleState centres a versionRibbon whole at y=64.
    title.versionRibbon =
      mod.assets:path("assets/title/wild_green_version.png")
  end

  if next(title) then bootPatch.title = title end

  if next(bootPatch) then
    try("field.boot", function()
      mod.content.field:patch("boot", bootPatch)
    end)
  end

  -- ------- the title screen's standing figure
  --
  -- Not by swapping the pic.  TitleState bakes the OBJ palette onto it and
  -- cuts its rectangle OUT of the true-colour region on purpose, so the mon
  -- cycling behind it keeps its palette -- there is no trueColor seam, and
  -- 1.1.0 proved it: recoloured art handed to that draw came back through
  -- the shade buckets as a white-and-pink figure.
  --
  -- So the figure keeps the vanilla grey art and MEWMON is what colours it.
  -- MEWMON is the zone palette for tile rows 10-17, which is the figure, the
  -- cycling Pokemon and the GAME FREAK line, so this is not free:
  --
  --   * the copyright line goes green with him.  It is the cost, and it was
  --     taken deliberately.
  --   * the cycling Pokemon is untouched while its art is true-colour --
  --     markVisibleTrueColor marks the mon and cuts the figure out of it, so
  --     the palette reaches the figure and not the mon.  With a mod like
  --     Crystal Animated Sprites on, which the cart pins, that always holds.
  --     Switch every sprite mod off and the title mon goes green too; the
  --     TITLE FIGURE row is there to switch back out of that.
  --
  -- Like LOGO1 below, this is a registry record only under SGB: OG RED
  -- short-circuits every named palette to the boot-ROM pair and ADVANCED
  -- reads data/palettes_gbc.
  if green and option("title_figure", true) then
    try("palettes.MEWMON", function()
      mod.content.palettes:override("MEWMON", WILD_GREEN)
    end)
  end

  if option("ribbon", true) then
    -- The ribbon art is grey, because the band it lands in is an SGB palette
    -- zone: TitleState:sgbPalettes colours tile rows 8-9 with LOGO1 and the
    -- shader remaps by shade.  So the green comes from here.
    --
    -- This is the one thing in the mod that does not reach every display
    -- mode.  PaletteFX.pal short-circuits every name to the boot-ROM palette
    -- under OG RED, and reads data/palettes_gbc under ADVANCED, so in those
    -- two the band wears the mode's own colour and the lettering is red.
    -- DIFFERENCES.md says so.
    try("palettes.LOGO1", function()
      mod.content.palettes:override("LOGO1", WILD_GREEN_TITLE)
    end)
  end

  -- One line a player can quote back when a picture stays red.  The recipe
  -- only recolours what the cache actually carries, and which pictures those
  -- are is the difference between "this mod is broken" and "your import
  -- never wrote that file".
  mod.log:info("player=%s ribbon=%s -- recoloured art is read from %s",
    green and "GREEN" or "RED", tostring(option("ribbon", true)), GREEN)
end
