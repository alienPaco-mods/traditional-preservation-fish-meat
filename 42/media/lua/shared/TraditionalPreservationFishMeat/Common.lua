-- Traditional Preservation (Fish & Meat): what every file of the mod shares, on the mod's table: the items the code
-- names, one constant each, and the small helpers for food values, names, the sandbox and vanilla's parts tables.
-- Every file that uses one requires this, so they are there whatever order the files load in.
TraditionalPreservationFishMeat = TraditionalPreservationFishMeat or {}
local F = TraditionalPreservationFishMeat

-- The items.
local function item(name) return "TraditionalPreservationFishMeat." .. name end
F.PACKED_FISH = item("SaltPackedFish")
F.PRESSED_FISH = item("SaltPressedFish")
F.SALT_DRIED = item("SaltDriedFish")
F.SOAKED_SALT_FISH = item("SoakedSaltFish")
F.GUTTED_FISH = item("GuttedFish")
F.FISH_HALF = item("FishHalf")
F.COLD_DRIED = item("ColdDriedFish")
F.SOAKED_COLD_FISH = item("SoakedColdFish")
F.HOT_FISH = item("HotSmokedFish")
F.COLD_FISH_OUT = item("ColdSmokedFish")
F.FISH_HEAD = item("FishHead")
F.PACKED_MEAT = item("SaltPackedMeat")
F.CURED_MEAT = item("SaltCuredMeat")
F.CHARQUE = item("Charque")
F.SOAKED_CHARQUE = item("SoakedCharque")
F.HOT_MEAT = item("HotSmokedMeat")
F.DRY_CURED = item("DryCuredMeat")
F.LEG_OF_PORK = item("LegOfPork")
F.COUNTRY_HAM = item("CountryHam")
F.HOT_SLICE = item("HotSmokedMeatSlice")
F.DRY_CURED_SLICE = item("DryCuredMeatSlice")
F.HAM_SLICE = item("CountryHamSlice")
F.BLOOD_SAUSAGE = item("BloodSausage")
F.RAW_BLOOD_SAUSAGE = item("RawBloodSausage")
F.SMOKED_BLOOD_SAUSAGE = item("SmokedBloodSausage")
F.FRESH_SAUSAGE = item("FreshSausage")
F.SMOKED_SAUSAGE = item("SmokedSausage")
F.CASING_ITEM = item("RawCasings")
F.CROCK = item("CrockOfPottedMeat")
F.BALE_TYPE = item("StockfishBale")

-- A food item's calories, proteins, lipids and carbohydrates, from a table with those fields.
local NUTRIENTS = { "Calories", "Proteins", "Lipids", "Carbohydrates" }
function F.setNutrients(item, food)
    item:setCalories(food.calories)
    item:setProteins(food.proteins)
    item:setLipids(food.lipids)
    item:setCarbohydrates(food.carbohydrates)
end

-- Multiplies a food item's calories, proteins, lipids and carbohydrates by share.
function F.scaleNutrients(item, share)
    for _, name in ipairs(NUTRIENTS) do item["set" .. name](item, item["get" .. name](item) * share) end
end

-- A food's values now, or a share of them: hunger, calories, carbohydrates, lipids and proteins.
function F.foodOf(item, share)
    share = share or 1
    return {
        hunger = item:getHungChange() * share, calories = item:getCalories() * share,
        carbohydrates = item:getCarbohydrates() * share, lipids = item:getLipids() * share,
        proteins = item:getProteins() * share,
    }
end

-- Empties a table in place: recipe data is pooled with its ModData (ENGINE_NOTES), so a new run starts from this.
function F.clearData(data)
    local keys = {}
    for key in pairs(data) do keys[#keys + 1] = key end
    for _, key in ipairs(keys) do data[key] = nil end
end

-- Gives an item a name of its own.
function F.nameAs(item, name)
    item:setName(name)
    item:setCustomName(true)
end

-- Whether a created item is the empty pot a recipe hands back, not the food.
function F.isEmptyPot(item)
    local fullType = item:getFullType()
    return fullType == "Base.Pot" or fullType == "Base.PotForged"
end

-- A switch in the mod's sandbox options: on unless the option says otherwise.
function F.optionOn(name)
    local options = SandboxVars and SandboxVars.TraditionalPreservationFishMeat
    return not options or options[name] ~= false
end

-- Puts a row for item into the parts table of each of the animals named (keys of vanilla's
-- AnimalPartsDefinitions.animals), once however often it runs: breeds share one table per kind. With enabled false,
-- only takes it out. An animal vanilla no longer has is skipped.
function F.setPartRow(item, minNb, maxNb, animals, enabled)
    local defined = AnimalPartsDefinitions and AnimalPartsDefinitions.animals
    if not defined then return end
    for _, name in ipairs(animals) do
        local parts = defined[name] and defined[name].parts
        if parts then
            for index = #parts, 1, -1 do
                if parts[index].item == item then table.remove(parts, index) end
            end
            if enabled ~= false then table.insert(parts, { item = item, minNb = minNb, maxNb = maxNb }) end
        end
    end
end

return F
