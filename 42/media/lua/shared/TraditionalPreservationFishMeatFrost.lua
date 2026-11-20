-- Traditional Preservation (Fish & Meat): the natural freezer. Vanilla's food ages by the clock wherever it is, unless
-- a powered freezer stops it; raw meat and fish left in the frost keep as in a freezer too. Each look brings a raw
-- piece's frost record (TP Core's Frost) up to now, at the place it was seen in last, and gives back the age the hours
-- at or below MEAT_FREEZE_C put on it. Above it, vanilla's clock as ever. Only loose pieces: carried, in a container
-- or on the floor. A piece hung on a rack or packed in a tub is on the station's own record (F.keptPiece leaves its
-- frost record behind). Required by TraditionalPreservationFishMeat.lua.
require "TraditionalPreservationFishMeat/Common"
TraditionalPreservationFishMeat = TraditionalPreservationFishMeat or {}
local F = TraditionalPreservationFishMeat
local Frost = require "TraditionalPreservationCore/Frost"
local FluidAgeing = require "TraditionalPreservationCore/FluidAgeing"
local Weather = require "TraditionalPreservationCore/Weather"

-- Raw meat and fish freeze at -2 C (the salts and sugars in the flesh keep it from freezing at 0). Dry curing stops
-- there too (F.dryCureRate): frozen meat takes no salt.
F.MEAT_FREEZE_C = -2
F.MEAT_FROST = Frost.point(F.MEAT_FREEZE_C)
F.FROST_KEY = "tpfmFrost"     -- a raw piece's frost record in its modData; never rename once the mod is out

-- TP's own raw pieces: from Gut Fish, Split Fish, butchering, the sausage and blood recipes, and the soaked stages,
-- which are raw again and must be cooked.
F.FROST_RAW = { F.GUTTED_FISH, F.FISH_HALF, F.FISH_HEAD, F.FRESH_SAUSAGE, F.RAW_BLOOD_SAUSAGE, F.CASING_ITEM,
    "TraditionalPreservationFishMeat.PorkFat", "TraditionalPreservationFishMeat.MuttonFat",
    "TraditionalPreservationFishMeat.BeefSuet", F.SOAKED_CHARQUE, F.SOAKED_SALT_FISH, F.SOAKED_COLD_FISH }

-- The full types frost keeps: vanilla's raw fish (F.FISH_ICONS) and raw cuts (F.MEAT_CUTS, the Leg of Pork too) and
-- F.FROST_RAW. Made on first use, as the lists are on the mod's table once TraditionalPreservationFishMeat.lua has run.
local frostKept
function F.frostKeptTypes()
    if not frostKept then
        frostKept = {}
        for _, list in ipairs({ F.FISH_ICONS, F.MEAT_CUTS, F.FROST_RAW }) do
            for _, fullType in ipairs(list) do frostKept[fullType] = true end
        end
    end
    return frostKept
end

-- Whether the sandbox lets frost keep raw meat and fish. On unless the option says otherwise.
function F.frostKeepsMeat()
    return F.optionOn("FrostKeepsMeat")
end

-- Takes hours of frost off an item's age, as a freezer would have kept it: at vanilla's pace (Food Spoilage
-- included), never below floorAge nor below 0. An item already younger than floorAge stays as it is.
function F.giveFrostBack(item, hours, floorAge)
    local age = item:getAge()
    local least = math.max(math.min(floorAge or 0, age), 0)
    item:setAge(math.max(age - hours / 24 * FluidAgeing.foodRotSpeed(), least))
end

-- Brings a raw piece's frost up to now at the place it was seen in last, and counts from where it is now (place, or
-- where the item is): the hours frozen since the last look age it nothing, never below the age it had then. The
-- sandbox off, the record still keeps up, and the item ages by vanilla's clock. Returns its frost record, or nil for
-- anything else and for a cooked or burnt piece (vanilla's clock).
function F.keepFrozen(item, now, place)
    if not F.frostKeptTypes()[item:getFullType()] or item:isCooked() or item:isBurnt() then return nil end
    now = now or getGameTime():getWorldAgeHours()
    local fire, holder
    if not place then place, fire, holder = FluidAgeing.placeOfItem(item) end
    local itemModData = item:getModData()
    local record = itemModData[F.FROST_KEY]
    place = place or (record and record.place) or Weather.DEFAULT_PLACE
    if not record then
        record = Frost.newRecord(F.MEAT_FROST, now, place)
        itemModData[F.FROST_KEY] = record
    else
        local hours = Frost.catchUp(record, F.MEAT_FROST, now, place, record)
        if hours > 0 and F.frostKeepsMeat() then F.giveFrostBack(item, hours, record.itemAge) end
    end
    -- The age at this look: the next look's frost never takes it younger.
    record.itemAge = item:getAge()
    if holder then FluidAgeing.noteFire(record, fire, holder, now) end
    return record
end

-- Hours frozen in all on a raw piece's frost record, or nil when it has none.
function F.frozenHours(item)
    local record = item:getModData()[F.FROST_KEY]
    return record and record.age
end
