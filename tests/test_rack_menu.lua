-- Checks a rack's right-click menu and its hand jobs (TPFMRack) with stand-ins for the engine: the status row, Info,
-- the Hang rows (One / All, refusals with their reason), hanging, Take Done and Take Everything Off, and that a rack
-- holding anything stays put. Run from the mod folder: luajit tests/test_rack_menu.lua
local H = dofile((os.getenv("TPCORE") or "../TraditionalPreservationCore") .. "/tests/harness.lua")
local check, near = H.check, H.near
H.useModPaths()
H.installClock(100)
H.installModData()
H.installEvents()
H.installGetText()

-- The mod's own modules, TP Core's and the mod's action load for real, vanilla's are left out.
local realRequire = require
require = function(name)
    if name:find("^TraditionalPreservation") or name:find("^TimedActions/TP") then return realRequire(name) end
end

local ui = H.installMenus()
function isClient() return false end
function getClimateManager()
    return { isUpdated = function() return true end, getTemperature = function() return 15 end, getHumidity = function() return 0.4 end,
        getPrecipitationIntensity = function() return 0 end, getPrecipitationIsSnow = function() return false end,
        getWindIntensity = function() return 0.3 end }
end
ItemTag.SALT, ItemTag.UNCUT_FISH, ItemTag.FISH_MEAT = "base:salt", "base:uncutfish", "base:fishmeat"
Perks = { Cooking = "Cooking" }
function ZombRandFloat(low, high) return (low + high) / 2 end
ComponentType = { Resources = "Resources", CraftLogic = "CraftLogic", DryingCraftLogic = "DryingCraftLogic" }
MapObjects = { OnLoadWithSprite = function() end }
CharacterActionAnims = { Craft = "Craft" }
local square = H.shutRoom({ getX = function() return 5 end, getY = function() return 4 end, getZ = function() return 0 end,
    getObjects = function() return H.list({}) end, isOutside = function() return false end, isInARoom = function() return true end })
function getCell()
    return { getGridSquare = function(_, x, y, z) if x == 5 and y == 4 and (z or 0) == 0 then return square end end }
end

-- What the player carries, as the inventory and the reach both see it.
local xp = {}
local function remove(item)
    for i, carried in ipairs(ui.carried) do
        if carried == item then return table.remove(ui.carried, i) end
    end
end
local inventory = { Remove = function(_, item) remove(item) end }
function inventory:containsRecursive(item)
    for _, carried in ipairs(ui.carried) do if carried == item then return true end end
    return false
end
function inventory:getFirstTypeRecurse(fullType)
    for _, carried in ipairs(ui.carried) do if carried:getFullType() == fullType then return carried end end
end
function inventory:getAllTagRecurse(tag, list)
    for _, carried in ipairs(ui.carried) do if carried.tag == tag then list:add(carried) end end
    return list
end
local given = {}
local playerObj = {
    getInventory = function() return inventory end,
    getXp = function() return { AddXP = function(_, perk, amount) xp[perk] = (xp[perk] or 0) + amount end } end,
    isTimedActionInstant = function() return false end,
    getSquare = function() return square end,
}
function getSpecificPlayer() return playerObj end
ArrayList = { new = function()
    local list = { items = {} }
    function list:add(x) table.insert(self.items, x) end
    function list:size() return #self.items end
    function list:get(i) return self.items[i + 1] end
    function list:isEmpty() return #self.items == 0 end
    return list
end }
Actions = { addOrDropItem = function(_, item) table.insert(given, item) end }

local FOOD_FIELDS = { "Calories", "Proteins", "Lipids", "Carbohydrates", "BaseHunger", "HungChange", "ActualWeight", "Age",
    "OffAge", "OffAgeMax", "ThirstChange", "ModelIndex" }
local MEAT = { ["Base.Steak"] = true, ["Base.Beef"] = true, ["Base.Pork"] = true }
local function food(fullType, weight, age)
    local item = { class = "Food", fullType = fullType, modData = {}, values = { ActualWeight = weight or 1, Age = age or 0,
        Calories = 100, HungChange = -0.2, BaseHunger = -0.2, OffAge = 7, OffAgeMax = 14, ModelIndex = -1 } }
    for _, name in ipairs(FOOD_FIELDS) do
        item["get" .. name] = function(self) return self.values[name] or 0 end
        item["set" .. name] = function(self, x) self.values[name] = x end
    end
    function item:getFullType() return self.fullType end
    function item:getModData() return self.modData end
    function item:isCustomWeight() return self.custom == true end
    function item:setCustomWeight(x) self.custom = x end
    function item:getDisplayName() return self.name or self.fullType:match("[^.]+$") end
    function item:setName(x) self.name = x end
    function item:setCustomName() end
    function item:setUnhappyChange() end
    function item:hasTag(tag)
        if tag == ItemTag.SALT then return self.tag == tag end
        local fish = fullType:sub(1, 5) == "Base." and not MEAT[fullType] and fullType ~= "Base.Plank" and fullType ~= "Base.FlatStone"
        if tag == ItemTag.FISH_MEAT then return fish end
        return tag == ItemTag.UNCUT_FISH and fish and fullType ~= "Base.FishFillet"
    end
    for _, state in ipairs({ "isRotten", "isFrozen", "isCooked", "isBurnt", "isFavorite" }) do item[state] = function() return false end end
    function item:getContainer() return inventory end
    function item:getCurrentUses() return self.uses or 0 end
    function item:setCurrentUses(x) self.uses = x end
    function item:getWorldItem() return nil end
    function item:getTexture() return self.fullType end
    return item
end
function instanceItem(fullType) return food(fullType) end
ScriptManager = { instance = { getItem = function(_, fullType) return { getNormalTexture = function() return fullType end } end,
    getCraftRecipe = function() return { Load = function() end } end } }

require "TraditionalPreservationFishMeat"
local F = TraditionalPreservationFishMeat
ISCollapsableWindow = H.class("ISCollapsableWindow")
function ZombRand() return 0 end
ISPanel = H.class("ISPanel")
ISWidgetCraftLogicOutputProgress = { createDynamicChildren = function() end, calculateLayout = function() end }
dofile("42/media/lua/client/TraditionalPreservationFishMeatRackUI.lua")
local handlers = H.handlers.OnFillWorldObjectContextMenu
local onFillMenu = handlers[#handlers]

local modData = {}
local frameObject = {
    getSprite = function() return { getName = function() return F.spriteName(6) end } end,
    getModData = function() return modData end,
    hasModData = function() return true end,
    getSquare = function() return square end,
    isOutside = function() return false end,
}

local function menuFor()
    local context = H.menu()
    onFillMenu(0, context, { frameObject }, false)
    return context.options[1], context.options[1].subOption
end

local function named(menu, prefix)
    for _, option in ipairs(menu.options) do
        if option.name:sub(1, #prefix) == prefix then return option end
    end
end

local function choose(option) option.onSelect(option.target, unpack(option.args)) end

local function runQueued()
    local queued = ui.queued
    ui.queued = {}
    for _, action in ipairs(queued) do
        action.setActionAnim = function() end
        action.setOverrideHandModels = function() end
        if action:isValid() then
            action:start()
            action:complete()
        end
    end
end

local function cured(weight, name, age)
    local item = food(F.PRESSED_FISH, weight, age)
    item.name = name
    return item
end

check("a probe for the controller's prompt finds the frame", (function()
    local before = ui.probes
    onFillMenu(0, H.menu(), { frameObject }, true)
    return ui.probes == before + 1
end)())

-- An empty frame, with 3 small salt bluegill and a salt walleye too heavy for it carried.
for i = 1, 3 do table.insert(ui.carried, cured(0.5, "Bluegill (Salt Cured)", i)) end
table.insert(ui.carried, cured(3.1, "Walleye (Salt Cured)"))
local top, menu = menuFor()
check("the rack's own entry, by its name, with its icon", top.name == "Drying Frame"
    and top.iconTexture == "media/textures/Item_DryingFrame.png")
local function allIconed(menu)
    for _, option in ipairs(menu.options) do
        if not option.iconTexture then return false, option.name end
        if option.subOption and not allIconed(option.subOption) then return false, option.name end
    end
    return true
end
check("the status row first, greyed: what it holds", menu.options[1].name == "Holds 0 pieces, 0.0 of 20 kg"
    and menu.options[1].isDisabled == true)
check("then its Info", menu.options[2].name == "Drying Frame Info")
local salt = named(menu, "Hang Salt Fish")
check("one Hang Salt Fish submenu, its kinds inside", salt and salt.subOption and #salt.subOption.options == 2
    and named(menu, "Hang Bluegill") == nil)
local bluegill = named(salt.subOption, "Bluegill")
check("Bluegill (Salt Cured): One, then All (3)", bluegill and bluegill.subOption.options[1].name == "One"
    and bluegill.subOption.options[2].name == "All (3)")
local walleye = named(salt.subOption, "Walleye")
check("the heavy walleye is refused, with every rack's limit", walleye.notAvailable == true
    and walleye.toolTip.description:find("Too heavy for a frame: 3.1 kg.", 1, true) ~= nil)
choose(walleye)
check("clicking a refused row queues nothing", #ui.queued == 0)
local finished = named(menu, "Take Done (0)")
check("Take Done (0) is there, greyed: nothing hangs", finished and finished.isDisabled == true
    and finished.toolTip.description == "Nothing hangs on it." and named(menu, "Take Everything Off") == nil)

choose(bluegill.subOption.options[2])
check("All queues one action a fish", #ui.queued == 3 and ui.queued[1].mode == "hang")
check("the moves into the inventory come first and the walk keeps them (vanilla's order)", #ui.moved == 3 and ui.cleared == 0)
runQueued()
local rack = F.rackOf(frameObject)
check("three hung, gone from the hands", F.rackCount(rack) == 3 and #ui.carried == 1)
local function canPickUp() return ISMoveableSpriteProps.canPickUpMoveable({}, playerObj, square, frameObject) end
check("a rack holding pieces can't be picked up (no station moves mid-process)", canPickUp() == false)

top, menu = menuFor()
check("the status row counts them", menu.options[1].name == "Holds 3 pieces, 1.5 of 20 kg")
finished = named(menu, "Take Done (0)")
check("with pieces drying, Take Done (0) is greyed and says when the next is", finished.isDisabled == true
    and finished.toolTip.description:find("Nothing finished yet", 1, true) ~= nil)
check("and Take Everything Off is there", named(menu, "Take Everything Off") ~= nil)
check("every row of the rack's menu has an icon, its submenus' rows too", allIconed(menu))

-- One done: Take Done (1) takes it as Salt Dried.
rack.pieces[1].doneHour, rack.pieces[1].state.dried = 1000, F.DRY_HOURS
top, menu = menuFor()
local takeDone = named(menu, "Take Done (1)")
check("Take Done (1), open", takeDone ~= nil and not takeDone.isDisabled)
choose(takeDone)
runQueued()
check("the done piece comes off Salt Dried", #given == 1 and given[1].fullType == F.SALT_DRIED and F.rackCount(rack) == 2)
choose(named(menu, "Take Everything Off"))
check("a take queued for a piece already gone does nothing", (function()
    runQueued()
    return F.rackCount(rack) == 0 and #given == 3 and given[2].fullType == F.PRESSED_FISH
end)())
check("emptied, it picks up again", canPickUp() == true)

-- A full frame: the row stays, with no room.
for _ = 1, 8 do F.hangPiece(rack, cured(2.5, "Big"), "Sheltered", F.getLedger(), 1000) end
table.insert(ui.carried, cured(0.4, "Perch (Salt Cured)"))
top, menu = menuFor()
local perch = named(named(menu, "Hang Salt Fish").subOption, "Perch")
check("on a full frame a row is refused: full", perch.notAvailable == true and perch.toolTip.description:find("Full", 1, true) ~= nil)
local action = TPFMRack:new(playerObj, frameObject, "hang", ui.carried[#ui.carried])
check("and a hang queued before it filled drops out", action:isValid() == false)

H.done()
