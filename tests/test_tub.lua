-- Checks the Salting Tub's right-click menu and its hand jobs (TPFMSaltingTub) with stand-ins for the engine: put in,
-- unpack, the start rows, take out. Run from the mod folder: luajit tests/test_tub.lua
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
local square = { getX = function() return 5 end, getY = function() return 4 end, getZ = function() return 0 end,
    getObjects = function() return H.list({}) end, isOutside = function() return false end, isInARoom = function() return true end }
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
require "TimedActions/TPFMSaltingTub"
dofile("42/media/lua/server/TraditionalPreservationFishMeatWorld.lua")
dofile("42/media/lua/client/TraditionalPreservationFishMeatTubUI.lua")
local handlers = H.handlers.OnFillWorldObjectContextMenu
local onFillMenu = handlers[#handlers]

local modData = {}
local tubObject = {
    getSprite = function() return { getName = function() return "traditionalpreservationfishmeat_01_0" end } end,
    getModData = function() return modData end,
    getSquare = function() return square end,
    isOutside = function() return false end,
    clearAttachedAnimSprite = function() end,
    addAttachedAnimSpriteByName = function() end,
}

local function menuFor()
    local context = H.menu()
    onFillMenu(0, context, { tubObject }, false)
    return context.options[1].subOption
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
        if action:isValid() then
            action:start()
            action:complete()
        end
    end
end

check("a probe for the controller's prompt finds the tub", (function()
    local before = ui.probes
    onFillMenu(0, H.menu(), { tubObject }, true)
    return ui.probes == before + 1
end)())

-- An empty tub, with 4 small bluegill, a whole walleye to gut and 2 steaks carried
for i = 1, 4 do table.insert(ui.carried, food("Base.Bluegill", 0.5, i)) end
table.insert(ui.carried, food("Base.Walleye", 3))
table.insert(ui.carried, food("Base.Steak", 0.3))
table.insert(ui.carried, food("Base.Steak", 0.3))
local menu = menuFor()
local bluegill = named(menu, "Put Bluegill")
check("Put Bluegill in the Tub: All (4), then One", bluegill and bluegill.subOption.options[1].name == "All (4)"
    and bluegill.subOption.options[2].name == "One")
local walleye = named(menu, "Put Walleye")
check("a whole walleye is refused: gut it first", walleye.notAvailable == true
    and walleye.toolTip.description:find("gutted first", 1, true) ~= nil)
check("no start rows on an empty tub", named(menu, "Cure Fish") == nil)

choose(bluegill.subOption.options[1])
check("All queues one action a fish, oldest first", #ui.queued == 4 and ui.queued[1].item.values.Age == 4)
runQueued()
local tub = F.tubOf(tubObject)
check("4 fish in, kept as they were", F.tubCount(tub) == 4 and tub.kind == "fish" and near(F.tubWeight(tub), 2) and tub.pieces[1].salt == 4)

menu = menuFor()
check("the status row says packing, with its contents", menu.options[1].name:find("Packing", 1, true) ~= nil
    and menu.options[1].name:find("4 fish", 1, true) ~= nil)
check("steak is refused once fish is in", named(menu, "Put Steak").notAvailable == true)
local cure = named(menu, "Cure Fish")
check("Cure Fish asks 16 salt, refused without it", cure.name:find("16 salt", 1, true) ~= nil and cure.notAvailable == true)
check("the meat rows are refused for a tub of fish", named(menu, "Corn the Meat").notAvailable == true
    and named(menu, "Country Cure").notAvailable == true)
check("Unpack is offered while packing", named(menu, "Unpack") ~= nil)

-- Unpack gives them back, then they go in again
choose(named(menu, "Unpack"))
runQueued()
check("Unpack gives the 4 back and empties the tub", #given == 4 and given[1].fullType == "Base.Bluegill"
    and near(given[1].values.ActualWeight, 0.5) and F.tubStage(tub) == "Empty")
for _, fish in ipairs(given) do table.insert(ui.carried, fish) end
given = {}
choose(named(menuFor(), "Put Bluegill").subOption.options[1])
runQueued()

-- Salt, a plank and a stone
local salt = food("Base.Salt")
salt.tag, salt.uses = "base:salt", 20
local plank, stone = food("Base.Plank"), food("Base.FlatStone")
for _, item in ipairs({ salt, plank, stone }) do table.insert(ui.carried, item) end
cure = named(menuFor(), "Cure Fish")
check("with salt, a plank and a stone it can start", not cure.notAvailable)
choose(cure)
check("the plank and stone are carried first", #ui.moved >= 2)
runQueued()
check("salted and weighed down: 16 salt and the press taken, Cooking xp", F.tubStage(tub) == "Curing" and salt.uses == 4
    and not inventory:containsRecursive(plank) and not inventory:containsRecursive(stone) and xp.Cooking == 4 * F.TUB_SALT_XP)
menu = menuFor()
check("curing: no put rows, no unpack, no start", named(menu, "Put") == nil and named(menu, "Unpack") == nil and named(menu, "Cure Fish") == nil)

-- Cured: take out
local ledger = F.getLedger()
for _, key in ipairs(F.FAMILY_KEYS.tubCure) do ledger[key] = (ledger[key] or 0) + tub.pressHours end
menu = menuFor()
local take = named(menu, "Take Out")
check("cured: Take Out (4)", F.tubStage(tub) == "Done" and take and take.name:find("4", 1, true) ~= nil)
choose(take.subOption.options[2])
runQueued()
check("one Salt Cured fish out, its food carried", #given == 1 and given[1].fullType == F.PRESSED_FISH
    and given[1].values.Calories == 100 and F.tubCount(tub) == 3)
choose(named(menuFor(), "Take Out").subOption.options[1])
runQueued()
check("All takes the other 3, then the plank and stone come back", #given == 6 and given[5].fullType == "Base.Plank"
    and given[6].fullType == "Base.FlatStone" and F.tubStage(tub) == "Empty")

H.done()
