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
--   TitleState         the same figure under REDPP, where the zone pass does
--                      not reach him and another mod paints him red after
--                      everything this one can say.  The only engine
--                      internal here, and the reason for the permission.
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
  -- the same portraits with the face painted skin.  A second set of files
  -- rather than a second recipe: the recipe runs at install and never sees
  -- the options, so both are written and this picks between them.
  local SKINNED = CACHE .. "greenskin/"

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

  -- The trainer art's four, which is what the title figure is baked to as
  -- well: monochrome green, because shade 2 on a portrait is the LIGHT for
  -- everything rather than the face.  transforms.lua explains it at length.
  -- Another copy tools/check.py keeps honest.
  local WILD_GREEN_PIC = {
    { 0xff, 0xff, 0xff },
    { 0xa8, 0xdd, 0x8a },
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
    -- The face on the big pictures -- the battle back pic, the trainer card,
    -- Oak's intro, the credits, the Hall of Fame.  Its own row because the
    -- rule that finds it is a guess about a picture this mod never sees, and
    -- a guess a player can switch off is a different thing from one they
    -- cannot.  See the note over greenOf.
    { key = "portrait_skin", type = "toggle", label = "PORTRAIT SKIN",
      default = true },
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
  -- Same shape as the recipe's own list, second value and all: true is an
  -- overworld sheet, false is a portrait.  Portraits are the ones with a
  -- skinned twin, so the two files have to agree about which is which.
  local RECOLOURED = {
    { "sprites/red.png", true },
    { "sprites/red_bike.png", true },
    { "battle/redb.png", false },
    { "battle/back/redb.png", false },
    { "trainer_card/red.png", false },
    { "credits/red.png", false },
    { "intro/red.png", false },
    { "hall_of_fame/red.png", false },
  }

  local KNOWN, PORTRAIT = {}, {}
  for _, entry in ipairs(RECOLOURED) do
    KNOWN[entry[1]] = true
    if not entry[2] then PORTRAIT[entry[1]] = true end
  end

  -- ------- PORTRAIT SKIN, and why it is a file and not a flag
  --
  -- Shade 2 on a portrait is the light for everything, so the monochrome
  -- ramp is what keeps the cap and the knees from going orange.  The recipe
  -- writes a second copy of each portrait with one patch of that shade --
  -- the one with eyes in it -- painted the character's skin instead, and
  -- fails closed to the monochrome copy when it cannot find exactly one.
  --
  -- So this is a choice between two files that both exist, not a recolour
  -- decided here.  Off is exactly 1.4.0's picture.
  local skinned = option("portrait_skin", true)

  -- The green twin of a cache path, or nil when there is not one.
  local function greenOf(path)
    if type(path) ~= "string" then return nil end
    local rel = path:match("^" .. CACHE .. "(.+)$")
    if not rel or not KNOWN[rel] then return nil end
    if skinned and PORTRAIT[rel] then return SKINNED .. rel end
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
  -- Not by swapping the pic.  The figure's rectangle is cut OUT of the
  -- true-colour region on purpose, so the mon cycling behind it keeps its
  -- palette, and what is left is painted by the SGB zone pass -- which
  -- reads the art's shade and not its colour.  Recoloured art handed to
  -- that draw comes back as whatever the zone palette says.
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
  -- ------- ...and the same figure under REDPP, where MEWMON cannot reach him
  --
  -- ADVANCED (PaletteFX.mode "redpp") does not run the zone pass over that
  -- rectangle at all, and this cart is the reason.  Crystal Animated
  -- Sprites -- pinned here -- marks the trainer's rect true-colour under
  -- REDPP so the zone pass cannot smear MEWMON over the vivid mon behind
  -- him, and then luminance-bakes his grey art to Red's own white / skin /
  -- red / navy so he is not left raw grey.  That bake is the whole of "the
  -- main screen didn't change": the figure is red because another mod
  -- paints him red, downstream of everything this one can say.
  --
  -- It is also what 1.1.0 actually was.  The white-and-pink figure that
  -- release put on screen was that same bake reading OUR green art -- the
  -- outfit green and the light green both land in its skin bucket -- not
  -- the engine's shade buckets, which is what 1.1.1's note said and got
  -- wrong.  Swapping the pic was never going to work; running after the
  -- bake is.
  --
  -- So: the same bake in this mod's four.  It wraps TitleState.currentSprite
  -- from OUTSIDE (this mod is priority 1300 and loads last, so its wrapper
  -- goes on over theirs), captures the untouched art on the way in -- before
  -- the red bake happens -- and paints that on the way out.  Out of REDPP it
  -- hands the grey art back and MEWMON has him again.
  --
  -- Every step is pcall'd and every miss is a no-op: without the engine
  -- module, without love.graphics, without a clonable ImageData, the figure
  -- is exactly what it was before this block existed.
  local function shadeOf(r)
    -- the recipe's own four thresholds.  The red channel rather than a
    -- weighted luminance, so art that is already green -- if something got
    -- there first -- buckets by its shade instead of collapsing into one.
    if r > 0.83 then return 1 end
    if r > 0.5 then return 2 end
    if r > 0.17 then return 3 end
    return 4
  end

  -- ------- getting an Image's pixels back, which is not one call
  --
  -- love.graphics.Image has no getData under LOVE 11: the texture does not
  -- keep the ImageData it was built from.  1.4.0 called it and gave up when
  -- it was not there, so the bake below failed on the very first frame,
  -- cached the failure, and left the figure exactly as it was -- which is
  -- why 1.4.0 changed nothing on screen.
  --
  -- The way back to the pixels is to draw the image into a canvas of its own
  -- size and read that. Two things make it safe: everything it touches is
  -- put back, and the blit runs at the origin -- currentSprite can be called
  -- mid-draw with the screen's own transform still on the stack, and drawing
  -- through that transform pushes the art out of a 1:1 canvas and reads back
  -- nothing at all.
  --
  -- getData is still tried first, because where it exists it is cheaper and
  -- needs no graphics state at all.  A clone either way: the title art is
  -- cached and other draws read the same object, so mapping it in place
  -- would recolour theirs too.
  local function pixelsOf(image)
    local okData, data = pcall(image.getData, image)
    if okData and data then
      local okClone, clone = pcall(data.clone, data)
      if okClone and clone then return clone end
    end

    local g = type(love) == "table" and love.graphics or nil
    if not (g and g.newCanvas and g.getCanvas) then return nil end
    local okDim, w, h = pcall(image.getDimensions, image)
    if not (okDim and w and h and w > 0 and h > 0) then return nil end

    local wasCanvas = g.getCanvas()
    local blend, alphaMode = g.getBlendMode()
    local cr, cg, cb, ca = g.getColor()
    local out
    pcall(function()
      local canvas = g.newCanvas(w, h, { dpiscale = 1 })
      g.setCanvas(canvas)
      g.clear(0, 0, 0, 0)
      g.setBlendMode("replace", "premultiplied")
      g.setColor(1, 1, 1, 1)
      g.push()
      g.origin()
      g.draw(image, 0, 0)
      g.pop()
      g.setCanvas()
      out = canvas:newImageData()
      if canvas.release then pcall(canvas.release, canvas) end
    end)
    -- put the screen back whether or not any of that worked
    if wasCanvas then pcall(g.setCanvas, wasCanvas) else pcall(g.setCanvas) end
    pcall(g.setBlendMode, blend or "alpha", alphaMode)
    pcall(g.setColor, cr or 1, cg or 1, cb or 1, ca or 1)
    return out
  end

  -- A PRIVATE copy, recoloured.  Never the shared ImageData in place: the
  -- title art is cached and other draws read the same object.
  local function greenBake(raw)
    local copy = pixelsOf(raw)
    if not copy then return nil end
    local okMap = pcall(function()
      copy:mapPixel(function(_, _, r, g, b, a)
        if a == 0 then return r, g, b, a end
        local colour = WILD_GREEN_PIC[shadeOf(r)]
        return colour[1] / 255, colour[2] / 255, colour[3] / 255, a
      end)
    end)
    if not okMap then return nil end
    local okNew, image = pcall(love.graphics.newImage, copy)
    if not (okNew and image) then return nil end
    pcall(image.setFilter, image, "nearest", "nearest")
    return image
  end

  local function wrapTitleFigure()
    if type(love) ~= "table" or type(love.graphics) ~= "table" then
      return "no love.graphics"
    end
    local okTitle, TitleState = pcall(require, "src.ui.TitleState")
    if not okTitle or type(TitleState) ~= "table"
        or type(TitleState.currentSprite) ~= "function" then
      return "no TitleState.currentSprite"
    end
    if TitleState.__wildGreenFigure then return "already wrapped" end
    local okFX, PaletteFX = pcall(require, "src.render.PaletteFX")
    if not okFX or type(PaletteFX) ~= "table" then return "no PaletteFX" end

    -- Where the strip is drawn.  Not derivable from here: it is the rect
    -- Crystal marks true-colour for the same image on the same screen, and
    -- it is marked again rather than conditionally, because the mark has to
    -- happen whether or not that mod is installed and marking the same rect
    -- twice costs nothing.
    local FIGURE_X, FIGURE_Y = 82, 80

    local function apply(title)
      local raw = title.__wildGreenRaw
      if not raw then
        -- the art was not there on the way in, which happens if the screen
        -- loads it inside currentSprite.  Crystal captured the same
        -- untouched picture before baking over it; take that rather than
        -- the bake that is on screen now.
        raw = title.__crystalPlayerRaw
        if not raw then return end
        title.__wildGreenRaw = raw
      end
      if PaletteFX.mode == "redpp" then
        if title.__wildGreenBaked == nil then
          title.__wildGreenBaked = greenBake(raw) or false
          -- once per visit to that screen, and the line 1.4.0 needed: the
          -- wrap succeeded there and the BAKE was what failed, silently, a
          -- frame later.  "wrapped" was true and the figure was still red.
          mod.log:info("title figure: %s", title.__wildGreenBaked
            and "baked green"
            or "could not read the art, left as it was")
        end
        local baked = title.__wildGreenBaked
        if not baked then return end
        title.player = baked
        -- Crystal re-bakes on every call until its own flag is set; with it
        -- set its bake returns early and leaves ours standing.  Its restore
        -- path -- a switch out of REDPP -- then puts back the same picture
        -- we captured, which is where the branch below leaves it too, so the
        -- two agree about the figure in both directions.
        title.__crystalPlayerRaw = title.__crystalPlayerRaw or raw
        title.__crystalTrainerBaked = true
        if type(PaletteFX.markTrueColor) == "function" then
          local okDim, w, h = pcall(baked.getDimensions, baked)
          if okDim and w and h then
            pcall(PaletteFX.markTrueColor, FIGURE_X, FIGURE_Y, w, h)
          end
        end
      elseif title.__wildGreenBaked then
        -- out of REDPP the zone pass runs again and MEWMON is what colours
        -- him, so the grey art goes back: baked green through the zone pass
        -- would be painted twice.
        if title.player == title.__wildGreenBaked then title.player = raw end
        title.__wildGreenBaked = nil
        title.__crystalTrainerBaked = nil
      end
    end

    TitleState.__wildGreenFigure = true
    local inner = TitleState.currentSprite
    function TitleState:currentSprite(...)
      -- captured on the way IN, which is the only moment the art is still
      -- the grey the importer wrote
      if self.player and not self.__wildGreenRaw then
        self.__wildGreenRaw = self.player
      end
      local image, trueColor = inner(self, ...)
      pcall(apply, self)
      return image, trueColor
    end
    return "wrapped"
  end

  if green and option("title_figure", true) then
    try("palettes.MEWMON", function()
      mod.content.palettes:override("MEWMON", WILD_GREEN)
    end)
    try("title.figure", function()
      mod.log:info("title figure under REDPP: %s", tostring(wrapTitleFigure()))
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
  -- Which rows are set, and which set of files the pics are read from.  The
  -- prefix is the answer to "did PORTRAIT SKIN take": greenskin/ is the
  -- skinned copies, green/ the flat ones -- and a build that does not name a
  -- prefix at all is a build older than the row.
  mod.log:info("player=%s portrait_skin=%s ribbon=%s -- pics are read from %s",
    green and "GREEN" or "RED", tostring(skinned),
    tostring(option("ribbon", true)), skinned and SKINNED or GREEN)
end
