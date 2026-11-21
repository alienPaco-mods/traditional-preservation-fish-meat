-- Checks the mod's menus and placement rules outside the game (not the racks' and the tub's: test_rack_menu,
-- test_tub). Run from the mod folder: luajit tests/test_ui.lua
local H = dofile((os.getenv("TPCORE") or "../TraditionalPreservationCore") .. "/tests/harness.lua")
H.useModPaths()
ModData = { getOrCreate = function() return {} end }
local handlers = {}
-- Each event calls its handlers in the order they were added, as the game does.
Events = setmetatable({}, { __index = function(_, name) return { Add = function(handler)
    local before = handlers[name]
    handlers[name] = before and function(...) before(...) return handler(...) end or handler
end } end })
-- The mod's own modules load for real, vanilla's are left out.
local realRequire = require
require = function(name)
    if name:find("^TraditionalPreservationFishMeat") or name:find("^TraditionalPreservationCore/") then return realRequire(name) end
end
dofile("42/media/lua/shared/TraditionalPreservationFishMeat.lua")
dofile("42/media/lua/shared/TraditionalPreservationFishMeatPotted.lua")
for _, name in ipairs({ "Cow", "Pig", "Sheep", "Deer", "AnimalParts" }) do package.loaded["Definitions/animal/" .. name .. "Definitions"] = true end
dofile("42/media/lua/shared/TraditionalPreservationFishMeatBlood.lua")

function getPlayer() return "player" end
function getText(key) return key end
function getTexture(name) return name end
instanceof = function() return true end
ArrayList = { new = function() return H.list({}) end }
ISMoveableSpriteProps = {}
function ISMoveableSpriteProps:canPlaceMoveable() return true end
function ISMoveableSpriteProps:canPickUpMoveable() return true end
function ISMoveableSpriteProps:getInfoPanelFlagsPerTile() end
dofile("42/media/lua/client/TraditionalPreservationFishMeatUI.lua")


local check = H.check

local list = H.list

local TUB = "traditionalpreservationfishmeat_01_0"

-- The game can't format a bare %, so a line's own percent sign belongs in the value it is given.
local translations = io.open("42/media/lua/shared/Translate/EN/IG_UI.json"):read("*a")
check("translations have no bare percent signs", not translations:find("%%%D"))

-- Picked-up beams can't be put down in a room
-- An empty map round the square: no door opens onto it.
local function emptyCell() return { getGridSquare = function() return nil end } end
local function placing(spriteName, inRoom)
    local realCell = getCell
    getCell = emptyCell
    local square = { isInARoom = function() return inRoom end, getX = function() return 0 end, getY = function() return 0 end,
        getZ = function() return 0 end }
    local fits = ISMoveableSpriteProps.canPlaceMoveable({ spriteName = spriteName }, nil, square, nil)
    getCell = realCell
    return fits
end
check("a Gantry and a Hanging Beam can be put down in a room", placing("traditionalpreservationfishmeat_02_3", true)
    and placing("traditionalpreservationfishmeat_02_2", true) and placing("traditionalpreservationfishmeat_02_0", true))
check("but can outdoors or under an open roof", placing("traditionalpreservationfishmeat_02_2", false))
check("and the frame can go anywhere", placing("traditionalpreservationfishmeat_01_0", true))

-- Names follow the days in any container the inventory shows
local renamed = {}
local fakeFish = { fullType = "TraditionalPreservationFishMeat.ColdDriedFish" }
function fakeFish:getFullType() return self.fullType end
local plainItem = { getFullType = function() return "Base.Carrots" end }
local container = {}
function container:getAllEvalRecurse(wanted)
    local found = {}
    for _, item in ipairs({ fakeFish, plainItem }) do if wanted(item) then table.insert(found, item) end end
    return H.list(found)
end
local F = TraditionalPreservationFishMeat
local realRename = F.rename
F.rename = function(item) table.insert(renamed, item) end
handlers.OnRefreshInventoryWindowContainers({ backpacks = { { inventory = container } } }, "begin")
check("names wait for the window to finish refreshing", #renamed == 0)
handlers.OnRefreshInventoryWindowContainers({ backpacks = { { inventory = container } } }, "end")
check("then every fish stage in each shown container is renamed", #renamed == 1 and renamed[1] == fakeFish)
check("and the player's things every hour", handlers.EveryHours ~= nil)
-- A crock in the same look catches up on its keeping instead (F.keepCrock).
local kept = {}
local crock = { getFullType = function() return F.CROCK end }
local realKeep = F.keepCrock
F.keepCrock = function(item) table.insert(kept, item) end
function container:getAllEvalRecurse(wanted)
    local found = {}
    for _, item in ipairs({ fakeFish, crock, plainItem }) do if wanted(item) then table.insert(found, item) end end
    return H.list(found)
end
renamed = {}
handlers.OnRefreshInventoryWindowContainers({ backpacks = { { inventory = container } } }, "end")
check("one look finds the crocks too, kept and not renamed", #kept == 1 and kept[1] == crock and #renamed == 1)
F.keepCrock = realKeep
F.rename = realRename

-- Picking a tub up: only empty (user, 2026-11-19: no station is moved mid-process)
local function tubObject(tub)
    local modData = { movableData = { [F.TUB_KEY] = tub } }
    return { getSprite = function() return { getName = function() return TUB end } end,
        hasModData = function() return true end, getModData = function() return modData end }
end
local pickUp = function(isoObject) return ISMoveableSpriteProps.canPickUpMoveable({}, nil, nil, isoObject) end
check("an empty tub picks up", pickUp(tubObject({})) == true)
check("not with pieces waiting", pickUp(tubObject({ pieces = { {} } })) == false)
check("nor curing or cured", pickUp(tubObject({ stage = "Curing", pieces = {} })) == false
    and pickUp(tubObject({ stage = "Done", pieces = { {} } })) == false)

-- Rinse at Sink
local ui = H.installMenus()
dofile("42/media/lua/shared/TimedActions/TPFMRinse.lua")
local function rinsable(fullType, name)
    local modData = {}
    return { class = "InventoryItem", getFullType = function() return fullType end, getModData = function() return modData end,
        getDisplayName = function() return name or "Walleye (Salt Cured)" end, getTexture = function() return "fish icon" end }
end
local sink
local person = {
    getX = function() return 10 end, getY = function() return 10 end, getZ = function() return 0 end,
    isTimedActionInstant = function() return false end,
}
function getSpecificPlayer() return person end
function getCell()
    return { getGridSquare = function(_, x, y)
        if x ~= 12 or y ~= 10 or not sink then return nil end
        return { getObjects = function() return H.list({ sink }) end }
    end }
end
local function rinseMenu(items, context)
    context = context or H.menu()
    ui.queued = {}
    handlers.OnFillInventoryObjectContextMenu(0, context, items)
    return context
end
local function rinseOption(menu)
    return menu:getOptionFromName("ContextMenu_TraditionalPreservationFishMeat_RinseAtSink")
end
local pressedOne, pressedTwo = rinsable("TraditionalPreservationFishMeat.SaltPressedFish"), rinsable("TraditionalPreservationFishMeat.SaltPressedFish")
local stack = { items = { pressedOne, pressedOne, pressedTwo } }
check("no sink, no option: the Rinse recipe covers carried water", #rinseMenu({ stack }).options == 0)
sink = {
    hasWater = function() return true end, isTaintedWater = function() return false end,
    getFluidAmount = function() return 10 end, getSquare = function() return "sink square" end,
}
check("no option on a fish that isn't Salt Cured", #rinseMenu({ rinsable("TraditionalPreservationFishMeat.SaltDriedFish") }).options == 0)

-- Vanilla's recipe submenu for the fish already there: the option joins it.
local withSub = H.menu()
local vanillaSub = withSub:getNew()
withSub:addSubMenu(withSub:addOption("Walleye (Salt Cured)"), vanillaSub)
vanillaSub:addOption("Slice")
rinseMenu({ stack }, withSub)
local atSink = rinseOption(vanillaSub)
check("near a sink it goes in the fish's submenu", #withSub.options == 1 and atSink ~= nil)
atSink.onSelect(atSink.target, unpack(atSink.args))
check("and rinses each fish of a stack once, after walking to the sink", #ui.queued == 2 and ui.queued[1].fish == pressedOne
    and ui.queued[2].fish == pressedTwo and ui.queued[1].source == sink and ui.walks == 1)

-- A lone recipe option: turned into the fish's submenu where it stands.
function ISInventoryPaneContextMenu.OnNewCraft() end
local lone = H.menu()
lone:addOption("Eat")
local slice = lone:addOption("Slice", pressedOne, ISInventoryPaneContextMenu.OnNewCraft)
slice.iconTexture = "slice icon"
rinseMenu({ stack }, lone)
local parent = lone.options[2]
check("a lone recipe becomes the fish's submenu in its place", #lone.options == 2 and parent.name == "Walleye (Salt Cured)" and parent.onSelect == nil)
local moved = parent.subOption.options[1]
check("holding the recipe as it was, then Rinse at Sink", moved.name == "Slice" and moved.target == pressedOne
    and moved.onSelect == ISInventoryPaneContextMenu.OnNewCraft and moved.iconTexture == "slice icon" and rinseOption(parent.subOption) ~= nil)

sink.isTaintedWater = function() return true end
check("a sink of tainted water doesn't count", #rinseMenu({ stack }).options == 0)

-- Tie a Bale and Untie Bale
dofile("42/media/lua/shared/TimedActions/TPFMTieBale.lua")
dofile("42/media/lua/shared/TimedActions/TPFMUntieBale.lua")
function getItemNameFromFullType(fullType) return fullType == "Base.Rope" and "Rope" or "Twine" end
local cordItem
local carried = { getFirstEvalRecurse = function(_, fn) return cordItem and fn(cordItem) and cordItem or nil end }
person.getInventory = function() return carried end
local function stockfishItem(weight)
    return { class = "InventoryItem", getFullType = function() return "TraditionalPreservationFishMeat.ColdDriedFish" end,
        getActualWeight = function() return weight end, getDisplayName = function() return "Gutted Walleye (Cold Dried)" end,
        getTexture = function() return "fish icon" end, getModData = function() return {} end }
end
local function tieOption(context)
    local sub = context.options[1] and context.options[1].subOption
    return sub and sub:getOptionFromName("ContextMenu_TraditionalPreservationFishMeat_TieBale")
end
local dried = {}
for i = 1, 60 do dried[i] = stockfishItem(0.2) end
local noCord = rinseMenu({ { items = { dried[1], unpack(dried) } } })
check("no cord, the Tie option says what it needs", tieOption(noCord) ~= nil and tieOption(noCord).notAvailable == true)
cordItem = { getFullType = function() return "Base.Twine" end, getCurrentUses = function() return 3 end,
    getDisplayName = function() return "Twine" end }
local withCord = rinseMenu({ { items = { dried[1], unpack(dried) } } })
local tie = tieOption(withCord)
check("with twine it goes in the fish's submenu", tie ~= nil and not tie.notAvailable)
tie.onSelect(tie.target, unpack(tie.args))
check("and ties the first 10 weight with the twine", #ui.queued == 1 and #ui.queued[1].fish == 50
    and ui.queued[1].cordItem == cordItem and ui.queued[1].cord.key == "twine")
check("no Tie option on salt fish", tieOption(rinseMenu({ rinsable("TraditionalPreservationFishMeat.SaltDriedFish") })) == nil)
local baleData = { cord = "rope" }
local bale = { class = "InventoryItem", getFullType = function() return F.BALE_TYPE end, getModData = function() return baleData end }
local untieMenu = rinseMenu({ bale })
local untie = untieMenu:getOptionFromName("ContextMenu_TraditionalPreservationFishMeat_UntieBale")
check("a bale has Untie Bale", untie ~= nil and untie.toolTip ~= nil)
untie.onSelect(untie.target, unpack(untie.args))
check("which unties it", #ui.queued == 1 and ui.queued[1].bale == bale)

-- The pallet's right-click line
local Tiles = require "TraditionalPreservationFishMeat/Tiles"
local function palletAt(z, place)
    package.loaded["TraditionalPreservationCore/Weather"].placeOf = function() return place end
    return { getSprite = function() return { getName = function() return Tiles.PALLET end } end,
        getSquare = function() return { getZ = function() return z end } end }
end
local realPlaceOf = package.loaded["TraditionalPreservationCore/Weather"].placeOf
local function palletLine(z, place)
    local context = H.menu()
    handlers.OnFillWorldObjectContextMenu(0, context, { palletAt(z, place) })
    return context.options[1]
end
check("a loft pallet says x2", palletLine(1, "Sheltered").name == "ContextMenu_TraditionalPreservationFishMeat_PalletSpeed")
check("a covered one says it's no faster", palletLine(0, "Covered").name == "ContextMenu_TraditionalPreservationFishMeat_PalletNoSpeed")
check("the line explains the places on hover", palletLine(0, "Sheltered").toolTip.description == "Tooltip_craft_stockfishPalletDesc")
local none = H.menu()
handlers.OnFillWorldObjectContextMenu(0, none, { { getSprite = function() return nil end } })
check("nothing for other objects", #none.options == 0)
package.loaded["TraditionalPreservationCore/Weather"].placeOf = realPlaceOf

check("the Stockfish Pallet has its own loot-window icon, not vanilla's shelves",
    ContainerButtonIcons.stockfishpallet == "media/textures/Container_StockfishPallet.png")
H.done()
