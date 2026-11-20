-- Checks the natural freezer (TraditionalPreservationFishMeatFrost.lua): loose raw meat and fish age nothing in the
-- hours at or below -2 C, by vanilla's clock above it, never in a basement, never cooked; the sandbox off; a piece
-- kept by a station leaves its frost record behind. Run from the mod folder: luajit tests/test_frost.lua
local H = dofile((os.getenv("TPCORE") or "../TraditionalPreservationCore") .. "/tests/harness.lua")
local check, near = H.check, H.near
H.useModPaths()
H.installClock(0)
H.installModData()
H.installEvents()
ItemTag = { UNCUT_FISH = "uncut", FISH_MEAT = "fishmeat" }
dofile("42/media/lua/shared/TraditionalPreservationFishMeat.lua")
local F = TraditionalPreservationFishMeat
local Frost = require "TraditionalPreservationCore/Frost"

-- A raw piece that ages as vanilla's clock does: age advances by hand (ageBy), as the game would between looks.
local function piece(fullType, age)
    local self = { fullType = fullType, age = age or 1, modData = {} }
    function self:getFullType() return self.fullType end
    function self:getAge() return self.age end
    function self:setAge(x) self.age = x end
    function self:getModData() return self.modData end
    function self:isCooked() return self.cooked == true end
    function self:isBurnt() return false end
    return self
end
local function ageBy(item, hours) item.age = item.age + hours / 24 end

-- Test clocks start at the frost ledger's last hour, so every stretch is counted.
local hour = Frost.ledger().lastHour
local function weather(hours, celsius)
    for _ = 1, hours * 6 do
        hour = hour + 1 / 6
        Frost.recordWeather(hour, celsius)
    end
end

check("raw meat and fish freeze at -2 C", F.MEAT_FREEZE_C == -2 and F.MEAT_FROST.celsius == -2)
local kept = F.frostKeptTypes()
check("vanilla's raw fish and cuts, the Leg of Pork, TP's raw pieces and the soaked stages are kept",
    kept["Base.Walleye"] and kept["Base.FishFillet"] and kept["Base.Steak"] and kept["Base.Rabbitmeat"] and kept[F.LEG_OF_PORK]
    and kept[F.GUTTED_FISH] and kept[F.FISH_HALF] and kept[F.FISH_HEAD] and kept[F.FRESH_SAUSAGE] and kept[F.RAW_BLOOD_SAUSAGE]
    and kept[F.CASING_ITEM] and kept["TraditionalPreservationFishMeat.BeefSuet"] and kept[F.SOAKED_CHARQUE]
    and kept[F.SOAKED_SALT_FISH] and kept[F.SOAKED_COLD_FISH])
check("cured, dried and smoked stages are not", not kept[F.PRESSED_FISH] and not kept[F.SALT_DRIED] and not kept[F.CHARQUE]
    and not kept[F.HOT_MEAT] and not kept[F.DRY_CURED] and not kept[F.CURED_MEAT])

weather(1, 5)
local out, mild, cellar, off = piece("Base.Steak"), piece(F.GUTTED_FISH), piece("Base.Walleye"), piece("Base.Beef")
for _, item in ipairs({ out, mild }) do F.keepFrozen(item, hour, "Open") end
F.keepFrozen(cellar, hour, "Basement")
F.keepFrozen(off, hour, "Open")
check("the first look starts a frost record and changes nothing", out.modData[F.FROST_KEY] ~= nil and out.age == 1
    and F.frozenHours(out) == 0)

-- Ten hours outside at -5 C: the clock put 10 hours on each, frost takes them back off.
weather(10, -5)
for _, item in ipairs({ out, cellar, off }) do ageBy(item, 10) end
F.keepFrozen(out, hour, "Open")
F.keepFrozen(cellar, hour, "Basement")
SandboxVars = { TraditionalPreservationFishMeat = { FrostKeepsMeat = false } }
F.keepFrozen(off, hour, "Open")
SandboxVars = nil
check("ten hours at -5 C outside age a Steak nothing", near(out.age, 1) and near(F.frozenHours(out), 10, 1e-6))
check("a basement never freezes: its Walleye aged the ten hours", near(cellar.age, 1 + 10 / 24) and F.frozenHours(cellar) == 0)
check("the sandbox off: vanilla's clock however cold, though the record kept up", near(off.age, 1 + 10 / 24)
    and near(F.frozenHours(off), 10, 1e-6))

-- Ten hours at +5 C: vanilla's clock.
weather(10, 5)
ageBy(mild, 20)
ageBy(out, 10)
F.keepFrozen(out, hour, "Open")
check("ten hours at +5 C age it as vanilla does", near(out.age, 1 + 10 / 24) and near(F.frozenHours(out), 10, 1e-6))
F.keepFrozen(mild, hour, "Open")
check("a gutted fish out the whole twenty: only the frozen ten given back", near(mild.age, 1 + 10 / 24))

-- Never younger than at the last look (a stretch the clock didn't count, say in a powered freezer), never below 0.
weather(10, -5)
F.keepFrozen(out, hour, "Open")
check("frost never takes it younger than at the last look", near(out.age, 1 + 10 / 24))
local young = piece("Base.Pork", 0.1)
F.giveFrostBack(young, 48, 0)
check("nor below 0", young.age == 0)
SandboxVars = { FoodRotSpeed = 1 }
local slow = piece("Base.Pork", 2)
F.giveFrostBack(slow, 24, 0)
SandboxVars = nil
check("at vanilla's pace: Food Spoilage Very Fast gives a day of frost back as 1.7 days", near(slow.age, 0.3))

local cooked = piece("Base.Steak")
cooked.cooked = true
check("cooked meat keeps vanilla's clock: no frost record", F.keepFrozen(cooked, hour, "Open") == nil
    and cooked.modData[F.FROST_KEY] == nil)
check("anything else is left alone", F.keepFrozen(piece("Base.Cabbage"), hour, "Open") == nil
    and F.keepFrozen(piece(F.CHARQUE), hour, "Open") == nil)

-- A piece a station keeps: frost up to the hour it goes in, its record left behind.
local walleye = piece("Base.Walleye")
F.keepFrozen(walleye, hour, "Open")
weather(6, -5)
ageBy(walleye, 6)
walleye.modData.fishName = "Walleye"
function walleye:getActualWeight() return 1 end
function walleye:isCustomWeight() return false end
function walleye:getDisplayName() return "Walleye" end
function walleye:getModelIndex() return 6 end
function walleye:hasTag() return false end
for _, field in ipairs({ "Calories", "Proteins", "Lipids", "Carbohydrates", "BaseHunger", "HungChange" }) do
    walleye["get" .. field] = function() return 0 end
end
-- Where the game would find it: the open air.
local FluidAgeing = require "TraditionalPreservationCore/FluidAgeing"
local placeOfItem = FluidAgeing.placeOfItem
FluidAgeing.placeOfItem = function() return "Open" end
local hung = F.keptPiece(walleye, hour)
FluidAgeing.placeOfItem = placeOfItem
check("a piece going on a rack or in a tub: its frost counted to then, its record left behind",
    near(hung.age, 1) and hung.data[F.FROST_KEY] == nil and hung.data.fishName == "Walleye")

H.done()
