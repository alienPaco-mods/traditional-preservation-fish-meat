-- Checks Put Fat in the Cauldron on the Stone Hearth's menu, and the mod's Stone Hearth Info notes, with stand-ins for the engine. Run from the mod folder:
-- luajit tests/test_fat_ui.lua
local H = dofile((os.getenv("TPCORE") or "../TraditionalPreservationCore") .. "/tests/harness.lua")
local check = H.check
H.useModPaths()
package.path = (os.getenv("TPCORE") or "../TraditionalPreservationCore") .. "/42/media/lua/shared/?.lua;" .. package.path
H.installClock(100)
H.installModData()
H.installEvents()
H.installGetText()

-- The mod's and the core's own modules and actions load for real, vanilla's are left out.
local realRequire = require
require = function(name)
    if name:find("^TraditionalPreservation") or name:find("^TimedActions/TP") then return realRequire(name) end
end

local ui = H.installMenus()
AnimalPartsDefinitions = { animals = {} }

local Fire = require "TraditionalPreservationCore/Fire"
local StoneHearth = require "TraditionalPreservationCore/StoneHearth"
local Cauldron = require "TraditionalPreservationCore/Cauldron"
local FireUI = require "TraditionalPreservationCore/FireUI"
require "TraditionalPreservationFishMeatFatUI"
require "TraditionalPreservationCore/CauldronUI"
local F = TraditionalPreservationFishMeat
local onFillMenu = H.handlers.OnFillWorldObjectContextMenu[1]

local function withCauldron(cauldron)
    local modData = { [Fire.KEY] = { [Cauldron.ID] = cauldron or {} } }
    local square = { getX = function() return 5 end, getY = function() return 5 end, getZ = function() return 0 end }
    return {
        class = "IsoFireplace",
        getSprite = function() return { getName = function() return StoneHearth.cauldronSprite("Empty", 0) end } end,
        getModData = function() return modData end,
        getSquare = function() return square end,
        getTileName = function() return "Stone Oven" end,
        isLit = function() return false end,
        getFuelAmount = function() return 120 end,
    }
end

local function fat(fullType, rotten, age)
    return {
        getFullType = function() return fullType end,
        isRotten = function() return rotten or false end,
        getFluidContainer = function() return nil end,
        isFavorite = function() return false end,
        hasTag = function() return false end,
        getAge = function() return age or 1 end,
        getOffAgeMax = function() return 4 end,
    }
end

-- The player the menu is for: the one whose job is queued.
local character = { isTimedActionInstant = function() return false end }
function getSpecificPlayer() return character end

local function open(aHearth)
    local context = H.menu()
    onFillMenu(0, context, { aHearth }, false)
    local sub = context:getOptionFromName(getText("IGUI_CraftingWindow_TPStoneHearthCauldron")).subOption
    return sub:getOptionFromName(getText("ContextMenu_TraditionalPreservationFishMeat_FatInCauldron"))
end

check("with no raw fat carried the Stone Hearth's menu has no fat row", open(withCauldron()) == nil)
local pork, pork2, suet, mutton = fat("TraditionalPreservationFishMeat.PorkFat"), fat("TraditionalPreservationFishMeat.PorkFat"),
    fat("TraditionalPreservationFishMeat.BeefSuet"), fat("TraditionalPreservationFishMeat.MuttonFat", false, 3)
ui.carried = { pork, suet, pork2, mutton, fat("TraditionalPreservationFishMeat.PorkFat", true), fat("Base.Lard") }
local empty = withCauldron()
local rows = open(empty).subOption.options
check("carrying both kinds gives a row each, counting the pieces and leaving rotten ones out", #rows == 2
    and rows[1].name == getText("ContextMenu_TraditionalPreservationFishMeat_FatPieces_PorkFat", "2")
    and rows[2].name == getText("ContextMenu_TraditionalPreservationFishMeat_FatPieces_Suet", "2"))
check("an empty cauldron takes either", not rows[1].notAvailable and not rows[2].notAvailable)
local picks = rows[2].subOption.options
check("two pieces fit: the row opens One and All (2)", #picks == 2 and picks[1].name == getText("ContextMenu_TraditionalPreservationCore_PiecesOne")
    and picks[2].name == getText("ContextMenu_TraditionalPreservationCore_PiecesAll", "2"))
picks[1].onSelect(picks[1].target, unpack(picks[1].args))
local queued = ui.queued[#ui.queued]
check("One takes the piece nearest to going off", #queued.pieces == 1 and queued.pieces[1] == mutton)
picks[2].onSelect(picks[2].target, unpack(picks[2].args))
queued = ui.queued[#ui.queued]
check("All walks over, takes the pieces in hand, oldest first, and queues the job", ui.walks == 2 and #ui.moved == 3
    and queued.Type == "TPPutPieces" and queued.asFluid.fluid == "RawSuet" and queued.pieces[1] == mutton and queued.pieces[2] == suet
    and queued.into.station == empty)
rows = open(withCauldron({ ml = 500, fluid = "RawPorkFat", tempC = 20 })).subOption.options
check("a cauldron of pork fat takes more pork fat and refuses suet with the reason", not rows[1].notAvailable and rows[2].notAvailable == true
    and rows[2].toolTip.description == getText("IGUI_TraditionalPreservationFishMeat_FatNoRoom"))
rows = open(withCauldron({ ml = 500, fluid = "MeltedLard", tempC = 90 })).subOption.options
check("melted fat takes no raw", rows[1].notAvailable == true and rows[2].notAvailable == true)
rows = open(withCauldron({ ml = 500, fluid = "Water", tempC = 20 })).subOption.options
check("nor does water", rows[1].notAvailable == true)

-- Stone Hearth Info's notes: the fat in the cauldron, and the smoke note on a Stone Hearth joined to the Smokehouse
local Smokehouse = require "TraditionalPreservationCore/Smokehouse"
require "TraditionalPreservationFishMeatSmokehouseUI"
local notes = FireUI.notes({ attachment = Fire.attachment(Cauldron.ID), part = { ml = 500, fluid = "MeltedLard", tempC = 90 }, lit = true })
check("melted fat in the cauldron gets its note", table.concat(notes, "|"):find(getText("IGUI_TraditionalPreservationFishMeat_FatMelted"), 1, true) ~= nil)
local smokes = getText("IGUI_TraditionalPreservationFishMeat_FlueSmokes")
notes = FireUI.notes({ help = StoneHearth.kind.display.help, lit = true, connection = { id = Smokehouse.ID }, joined = { kitName = "Pipe" } })
check("a Stone Hearth joined to the Smokehouse says what its fire does to the stacks", notes[#notes] == smokes)
notes = FireUI.notes({ help = StoneHearth.kind.display.help, lit = true })
check("one joined to nothing doesn't", notes[#notes] ~= smokes)

check("no text would make the game's formatter warn" .. (H.textWarnings[1] and " (" .. table.concat(H.textWarnings, "; ") .. ")" or ""),
    #H.textWarnings == 0)

H.done()
