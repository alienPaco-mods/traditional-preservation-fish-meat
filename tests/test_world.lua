-- Checks the tubs' and racks' sprites and the weather record with stand-ins for the engine. Run from the mod
-- folder: luajit tests/test_world.lua
local H = dofile((os.getenv("TPCORE") or "../TraditionalPreservationCore") .. "/tests/harness.lua")
local check, near, list = H.check, H.near, H.list
H.useModPaths()
H.installClock(100)
H.installModData()
H.installEvents()

-- The mod's own modules load for real, vanilla's are left out.
local realRequire = require
require = function(name)
    if name:find("^TraditionalPreservationFishMeat") or name:find("^TraditionalPreservationCore/") then return realRequire(name) end
end

-- Engine stand-ins
function isClient() return false end
ComponentType = { Resources = "Resources", CraftLogic = "CraftLogic", DryingCraftLogic = "DryingCraftLogic" }
ResourceIO = { Input = "Input", Output = "Output" }
ResourceType = { Item = "Item" }
ArrayList = { new = function() return list({}) end }
function getPlayer() return {} end
function getClimateManager()
    return {
        isUpdated = function() return true end, getTemperature = function() return 20 end,
        getHumidity = function() return 0.4 end,
        getPrecipitationIntensity = function() return 0 end,
        getPrecipitationIsSnow = function() return false end,
        getWindIntensity = function() return 0.3 end,
    }
end
local loaders = {}
MapObjects = { OnLoadWithSprite = function(name, handler) loaders[name] = handler end }
local cellSquares = {}
function getCell()
    return { getGridSquare = function(_, x, y, z) return cellSquares[x .. "," .. y .. "," .. z] end }
end
ScriptManager = { instance = { getCraftRecipe = function() return { Load = function() end } end } }

local function square(x, z)
    local s = {}
    function s:getX() return x end
    function s:getY() return 0 end
    function s:getZ() return z end
    -- Nothing else stands on it: no Stone Hearth beside a Smokehouse.
    function s:getObjects() return { size = function() return 0 end } end
    H.shutRoom(s)
    cellSquares[x .. ",0," .. z] = s
    return s
end

local function fish(fullType, modData, rotten)
    return { getFullType = function() return fullType end, getModData = function() return modData or {} end,
        isRotten = function() return rotten or false end }
end

local function recipeData(progress, style)
    local craftRecipeData = { modData = { style = style }, progress = progress }
    function craftRecipeData:getModData() return self.modData end
    return craftRecipeData
end

-- A station with this sprite, with waiting fish, running batches and finished fish.
local function station(spriteName, x, outside, waiting, batches, finished)
    local logic = { inProgress = {} }
    for _, batch in ipairs(batches) do logic.inProgress[batch] = {} end
    function logic:getInputsGroupName() return "in" end
    function logic:getOutputsGroupName() return "out" end
    function logic:getProgress(craftRecipeData) return craftRecipeData.progress end
    logic.tag = "DryingFrame"
    function logic:getRecipeTagQuery() return self.tag end
    function logic:setRecipeTagQuery(tag) self.tag = tag end
    local resources = {}
    function resources:getResourcesFromGroup(group)
        local items = group == "in" and waiting or finished
        return list({ { getStoredItems = function() return list(items) end, storedSize = function() return #items end } })
    end
    local station = { square = square(x, 0), sprites = {}, clears = 0 }
    function station:getComponent(componentType) return componentType == "Resources" and resources or logic end
    function station:getSprite() return { getName = function() return spriteName end } end
    function station:getSquare() return self.square end
    function station:getObjectIndex() return 0 end
    function station:isOutside() return outside end
    function station.square:isOutside() return outside end
    function station.square:isInARoom() return not outside and not station.porch end
    function station:clearAttachedAnimSprite() self.sprites = {} self.clears = self.clears + 1 end
    function station:addAttachedAnimSpriteByName(name) table.insert(self.sprites, name) end
    station.modData = {}
    function station:getModData() return self.modData end
    return station
end

local function tick(times)
    for _ = 1, times do H.fire("OnTick") end
end

dofile("42/media/lua/shared/TraditionalPreservationFishMeat.lua")
dofile("42/media/lua/shared/TraditionalPreservationFishMeatPotted.lua")
dofile("42/media/lua/shared/TraditionalPreservationFishMeatSmokehouse.lua")
for _, name in ipairs({ "Cow", "Pig", "Sheep", "Deer", "AnimalParts" }) do package.loaded["Definitions/animal/" .. name .. "Definitions"] = true end
dofile("42/media/lua/shared/TraditionalPreservationFishMeatBlood.lua")
dofile("42/media/lua/server/TraditionalPreservationFishMeatWorld.lua")
local T, W = TraditionalPreservationFishMeat, TraditionalPreservationFishMeatWorld
local PRESSED, GUTTED = "TraditionalPreservationFishMeat.SaltPressedFish", "TraditionalPreservationFishMeat.GuttedFish"

check("the map loader knows the tub, the frame and both beams", loaders.traditionalpreservationfishmeat_01_0
    and loaders.traditionalpreservationfishmeat_01_7 and loaders.traditionalpreservationfishmeat_02_0 and loaders.traditionalpreservationfishmeat_02_3)
check("and nothing else", loaders.traditionalpreservationfishmeat_01_8 == nil)
local shedTilesLoaded = true
for _, name in ipairs(require("TraditionalPreservationCore/Tiles").CHAMBERS) do shedTilesLoaded = shedTilesLoaded and loaders[name] ~= nil end
check("and all four tiles of TP Core's Smokehouse, either way round, for this mod's pieces in it", shedTilesLoaded)

-- Racks (ROADMAP section 12, R4): what hangs is the rack's piece record, drawn a spot each 2.5 kg of a frame's 20,
-- shared by kind: a finished salt fish, a gutted fish halfway, a fresh salt fish (5.4 kg: 3 spots, salt 2, gutted 1).
ItemTag = ItemTag or { UNCUT_FISH = "uncut", SALT = "salt", FISH_MEAT = "fishmeat" }
local newFood = dofile("tests/standins/food.lua")
function ZombRand() return 0 end
local rackLedger = T.getLedger()
local function hang(rackStation, fullType, weight, style, share, done)
    local piece = T.hangPiece(T.rackOf(rackStation), newFood(fullType, { ActualWeight = weight }), "Sheltered", rackLedger, 100)
    piece.state.style = style
    piece.state.dried = share * (fullType == GUTTED and T.COLD_DRY_HOURS or T.DRY_HOURS)
    if done then piece.doneHour = 100 end
    return piece
end
local shed = station("traditionalpreservationfishmeat_01_6", 1, false, {}, {}, {})
local first = hang(shed, PRESSED, 2.5, T.STYLE_SALT, 1, true)
hang(shed, GUTTED, 2.5, T.STYLE_GUTTED, 0.5)
hang(shed, PRESSED, 0.4, T.STYLE_SALT, 0)
loaders.traditionalpreservationfishmeat_01_6(shed)
tick(30)
-- Salt first (hung first): spot 1 the done fish (tile 2: salt, dry), spot 2 the done fish's end and the fresh one
-- (tile 0, the least dry); then the gutted fish halfway in spot 3 (tile 7: gutted, half dry), face 0; a tile is
-- 8 + (tile x 8 + spot - 1) x 2.
check("each kind gets its spots, in the order first hung", table.concat(shed.sprites, " ") ==
    "traditionalpreservationfishmeat_01_40 traditionalpreservationfishmeat_01_10 traditionalpreservationfishmeat_01_124")
check("its pieces learn they are indoors", first.state.place == "Sheltered")
tick(30)
check("an unchanged rack is left alone", shed.clears == 1)

local yard = station("traditionalpreservationfishmeat_01_7", 2, true, {}, {}, {})
local outdoors = hang(yard, PRESSED, 0.5, T.STYLE_SALT, 0.1)
W.track(yard)
tick(30)
check("an open frame is open", outdoors.state.place == "Open" and yard.sprites[1] == "traditionalpreservationfishmeat_01_9")

local porch = station("traditionalpreservationfishmeat_01_7", 4, false, {}, {}, {})
porch.porch = true
local porched = hang(porch, PRESSED, 0.5, T.STYLE_SALT, 0.1)
W.refresh(porch)
check("a frame under an open roof is covered, and a refresh tracks it", porched.state.place == "Covered" and #porch.sprites == 1)

-- Charque: meat half dry (tile 10) in spot 1: 8 + 10 x 8 x 2 = 168.
local meatRack = station("traditionalpreservationfishmeat_01_6", 5, true, {}, {}, {})
hang(meatRack, T.CURED_MEAT, 0.5, T.STYLE_MEAT, 0)
meatRack.pieces = T.rackOf(meatRack).pieces
meatRack.pieces[1].state.dried = T.CHARQUE_HOURS * 0.5
W.refresh(meatRack)
check("charque hangs from the meat's tiles", table.concat(meatRack.sprites, " ") == "traditionalpreservationfishmeat_01_168")

-- A piece reaching past its spot's share draws in both; a rotted piece shows its kind's rotten look.
local function piece(method, weight, style, spoiled)
    return { weight = weight, method = method, state = { dried = 0, spoiled = spoiled, style = style } }
end
local spots = T.rackSpots({ pieces = { piece("salt", 1.5, T.STYLE_SALT), piece("salt", 1.5, T.STYLE_SALT_HALF),
    piece("salt", 1.5, T.STYLE_SALT) } }, T.HANGERS[6])
check("a piece over a spot's edge fills both spots: 4.5 kg, 2 spots, the middle fish in both",
    spots[1] == T.spotTile(T.STYLE_SALT, 0) and spots[2] == T.spotTile(T.STYLE_SALT_HALF, 0) and spots[3] == nil)
local mixedFrame = { pieces = {} }
for _ = 1, 7 do table.insert(mixedFrame.pieces, piece("salt", 2.5, T.STYLE_SALT)) end
for _ = 1, 3 do table.insert(mixedFrame.pieces, piece("meat", 0.4, T.STYLE_MEAT)) end
spots = T.rackSpots(mixedFrame, T.HANGERS[6])
check("a frame full of fish with 3 steaks shows the meat: 7 fish spots, 1 meat", #spots == 8
    and spots[7] == T.spotTile(T.STYLE_SALT, 0) and spots[8] == T.spotTile(T.STYLE_MEAT, 0))
spots = T.rackSpots({ pieces = { piece("salt", 0.3, T.STYLE_SALT), piece("cold", 0.3, T.STYLE_GUTTED),
    piece("meat", 0.3, T.STYLE_MEAT) } }, T.HANGERS[6])
check("three light kinds take a spot each, though their weight fills one", spots[1] == 0
    and spots[2] == T.spotTile(T.STYLE_GUTTED, 0) and spots[3] == T.spotTile(T.STYLE_MEAT, 0) and spots[4] == nil)
spots = T.rackSpots({ pieces = { piece("salt", 2, T.STYLE_SALT), piece("meat", 5, T.STYLE_MEAT), piece("cold", 8, T.STYLE_GUTTED) } }, T.HANGERS[410])
check("a Gantry with three kinds shows its two heaviest, in the order first hung", spots[1] == T.spotTile(T.STYLE_MEAT, 0)
    and spots[2] == T.spotTile(T.STYLE_GUTTED, 0))
local gantrySpots = T.rackSpots({ pieces = { piece("salt", 12, T.STYLE_SALT, 1) } }, T.HANGERS[410])
check("a Gantry's spot is 50 kg, and a rotted piece's spot is rotten", gantrySpots[1] == T.ROTTEN_TILE + T.ROTTEN_LOOKS.SALT
    and gantrySpots[2] == nil)
-- A spot's 15 tiles (0.4.76): 4 looks x 3 stages, then a rotten one a kind; the frame's from 8, the Beam's from 412,
-- the Gantry's from 532.
check("a spot has 15 tiles, the rotten ones last", T.SPOT_TILES == 15 and T.ROTTEN_TILE == 12
    and T.spotTile(T.STYLE_MEAT, 2) == 11 and T.spotTile(T.STYLE_MEAT, 0, true) == 12 + T.ROTTEN_LOOKS.MEAT)
check("a style draws as its look: salt gutted as salt, a cold half as gutted", T.spotTile(T.STYLE_SALT_GUTTED, 1) == T.spotTile(T.STYLE_SALT, 1)
    and T.spotTile(T.STYLE_HALF, 1) == T.spotTile(T.STYLE_GUTTED, 1) and T.spotTile(T.STYLE_SALT_HALF, 1) == 4)
check("the frame's last tile is 247, the Beam's 412 to 531, the Gantry's 532 to 591",
    W.hangingSprite(T.HANGERS[6], 14, 8, 1) == 247 and W.hangingSprite(T.HANGERS[408], 0, 1, 0) == 412
    and W.hangingSprite(T.HANGERS[408], 14, 4, 1) == 531 and W.hangingSprite(T.HANGERS[410], 0, 1, 0) == 532
    and W.hangingSprite(T.HANGERS[410], 14, 2, 1) == 591)
check("two sheets, keeping their names", T.spriteName(407) == "traditionalpreservationfishmeat_01_407"
    and T.spriteName(408) == "traditionalpreservationfishmeat_02_0" and T.spriteIndex("traditionalpreservationfishmeat_02_471") == 879
    and T.spriteIndex("traditionalpreservationfishmeat_03_0") == nil)
check("a style's rotten kind", T.rottenLook(T.STYLE_SALT_HALF) == T.ROTTEN_LOOKS.SALT and T.rottenLook(T.STYLE_HALF) == T.ROTTEN_LOOKS.COLD
    and T.rottenLook(T.STYLE_MEAT) == T.ROTTEN_LOOKS.MEAT)
local mixed = recipeData(0.5, T.STYLE_MEAT)
mixed.modData.underSpoiled, mixed.modData.spoiled = 1.5, 0
check("a mixed stack whose Corned share rotted keeps drying, and its look", not T.stackRotten(mixed.modData))
mixed.modData.allUnder = true
check("all Corned, it is lost", T.stackRotten(mixed.modData))

-- TP Core's Smokehouse: its pieces are this mod's record on the back left tile (Smokehouse.recordTile), stepped from
-- that tile alone at the shed's own word (out of the rain, an open roof's air). Core draws its look.
local CHAMBERS = require("TraditionalPreservationCore/Tiles").CHAMBERS
local smokehouse = station(CHAMBERS[1], 6, true, {}, {}, {})
smokehouse.sprites = { "core's" }
local smoked = T.hangPiece(T.rackOf(smokehouse), newFood(T.CURED_MEAT, { ActualWeight = 0.5 }), "Open", rackLedger, 100)
smoked.lastLook = 90
W.refresh(smokehouse)
check("a Smokehouse in the open is out of the rain inside, and its pieces are marked as the shed", smoked.lastLook == 100
    and smoked.state.place == "Smokehouse" and T.inShed(smoked.state) and T.sheltered(smoked.state))
check("and the look is Core's to draw", smokehouse.sprites[1] == "core's" and smokehouse.clears == 0)
local doorTile = station(CHAMBERS[2], 8, true, {}, {}, {})
local notHere = T.hangPiece(T.rackOf(doorTile), newFood(T.CURED_MEAT, { ActualWeight = 0.5 }), "Open", rackLedger, 100)
notHere.lastLook = 90
W.refresh(doorTile)
check("another tile of the shed steps nothing: the shed steps once", notHere.lastLook == 90)

-- Tubs: the batch is the tub's own record (movableData), not a crafting station's
local function tubStation(x, pieces, stage)
    local tub = station("traditionalpreservationfishmeat_01_" .. (x % 2), x, true, {}, {}, {})
    local record = T.tubOf(tub)
    for _, piece in ipairs(pieces) do T.putInTub(record, piece) end
    if stage then record.stage = stage end
    W.refresh(tub)
    return tub, record
end
local function piece(kind, extra)
    local made = { kind = kind, tubWeight = 0.5, timing = 0.5, salt = 2 }
    for key, value in pairs(extra or {}) do made[key] = value end
    return made
end
local weighted = tubStation(3, { piece("fish") }, "Done")
check("a cured tub keeps its board and stone on until the last piece is out", table.concat(weighted.sprites, " ") == "traditionalpreservationfishmeat_01_5")
local empty = tubStation(5, {})
check("an empty tub shows nothing", #empty.sprites == 0)
-- An uncovered tub shows its top layer: fish, or the meat by its kind (tiles 870-875, the second sheet from 408).
local filled = tubStation(8, { piece("fish") })
check("a tub of fish waiting shows fish", table.concat(filled.sprites, " ") == "traditionalpreservationfishmeat_01_2")
for n, case in ipairs({ { {}, "beef", "traditionalpreservationfishmeat_02_462" }, { { pork = true }, "pork", "traditionalpreservationfishmeat_02_464" },
                         { { leg = true, pork = true }, "a leg", "traditionalpreservationfishmeat_02_466" } }) do
    local salted = tubStation(10 + n * 2, { piece("meat", case[1]) })
    check("a tub of " .. case[2] .. " waiting shows it", table.concat(salted.sprites, " ") == case[3])
end
check("the kind of a fish is none", W.tubMeat({ pieces = { piece("fish") } }) == nil and W.tubMeat({}) == nil)
check("mixed cuts show the last put in", W.tubMeat({ pieces = { piece("meat"), piece("meat", { pork = true }) } }) == "pork"
    and W.tubMeat({ pieces = { piece("meat", { pork = true }), piece("meat") } }) == "meat")
check("a leg shows wherever it is", W.tubMeat({ pieces = { piece("meat", { leg = true }), piece("meat"), piece("meat") } }) == "leg")
local curing, record = tubStation(20, { piece("fish") })
T.startTub(record, "fish", T.getLedger())
-- The cure's hours in the open air come off the ledger's total there; put back after, for the weather checks below.
local ledger = T.getLedger()
local before = ledger.tubCureOpen
ledger.tubCureOpen = (before or 0) + record.pressHours
W.refresh(curing)
ledger.tubCureOpen = before
check("a look brings the cure up to now, where the tub stands", record.stage == "Done" and record.place == "Open"
    and table.concat(curing.sprites, " ") == "traditionalpreservationfishmeat_01_4")
check("other mods' objects aren't tracked", W.track(station("carpentry_02_122", 4, true, {}, {}, {})) == nil)

-- The stale-station fix: once its chunk unloads the cell no longer returns its square, though the object keeps it.
cellSquares["2,0,0"] = {}
yard.sprites = {}
outdoors.progress = 0.9
tick(30)
check("an unloaded frame is dropped, not refreshed", #yard.sprites == 0)

-- Weather
local ledger = T.getLedger()
local open = ledger.open
H.setHours(101)
H.fire("EveryTenMinutes")
check("the world file records the weather", ledger.temperature == 20 and ledger.wind == 0.3 and ledger.lastHour == 101 and near(ledger.open - open, 1))

H.done()
