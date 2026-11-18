-- Traditional Preservation (Fish & Meat): the names of fish and meat at every stage, and what a hanging stack will come down
-- as. Required by TraditionalPreservationFishMeat.lua, whose F it adds
-- to.
TraditionalPreservationFishMeat = TraditionalPreservationFishMeat or {}
local F = TraditionalPreservationFishMeat

-- Names (6a): the name says what it is now, a permanent fact in front ("Beef (Corned)", "Beef Charque"); a bracket
-- holds a state that changes or wants acting on, one at most, before vanilla's freshness ("Beef (Dry Cured, Aged)").
-- A meat stage's name, from the cut it was made of (its model index; a slice's is in modData.cut): nil for one
-- spawned without a cut. Vanilla's grade ("Beef (Prime Cut)") stays behind: the food values carry it.
local function meatStageName(item)
    local fullType, modData = item:getFullType(), item:getModData()
    local stage = F.STAGES[fullType]
    local index = item:getModelIndex()
    if stage.slice then index = modData.cut end
    local cut = index and F.MEAT_CUTS[index + 1]
    if not cut then return nil end
    local animal = getText("IGUI_TraditionalPreservationFishMeat_Animal" .. F.MEAT_ANIMALS[index + 1])
    if fullType == F.CURED_MEAT then
        return getText(modData.longCure and "IGUI_TraditionalPreservationFishMeat_CountryCured" or "IGUI_TraditionalPreservationFishMeat_Corned",
            getItemNameFromFullType(cut))
    elseif fullType == F.CHARQUE then
        return getText("IGUI_TraditionalPreservationFishMeat_CharqueOf", animal)
    elseif fullType == F.SOAKED_CHARQUE then
        return getText("IGUI_TraditionalPreservationFishMeat_Named", getText("IGUI_TraditionalPreservationFishMeat_CharqueOf", animal),
            getText("IGUI_TraditionalPreservationFishMeat_Soaked"))
    elseif fullType == F.HOT_MEAT then
        -- Poultry and rabbit keep the cut, whose food differs (a turkey fillet is no wing): "Turkey Wing (Hot Smoked)".
        if F.HOT_ONLY_INDICES[index] then return getText("IGUI_TraditionalPreservationFishMeat_HotSmokedOf", getItemNameFromFullType(cut)) end
        return getText("IGUI_TraditionalPreservationFishMeat_HotSmokedOf", animal)
    elseif stage.hot then
        return getText("IGUI_TraditionalPreservationFishMeat_HotSmokedOf", getText("IGUI_TraditionalPreservationFishMeat_SliceOf", animal))
    end
    local aged = F.agedness(item) >= 1
    if stage.slice then aged = modData.aged == true end
    -- A ham keeps its own name ("Smoked Country Ham Slice (Aged)"); the rest go by the animal and the way they dried,
    -- as every other stage does: "Mutton (Dry Cured)", "Beef Slice (Cold Smoked, Aged)".
    if index == F.LEG_INDEX then
        local name = getText((modData.airDried and "IGUI_TraditionalPreservationFishMeat_AirDried_" or "IGUI_TraditionalPreservationFishMeat_Smoked_") .. "Leg")
        if stage.slice then name = getText("IGUI_TraditionalPreservationFishMeat_SliceOf", name) end
        if not aged then return name end
        return getText("IGUI_TraditionalPreservationFishMeat_Named", name, getText("IGUI_TraditionalPreservationFishMeat_Aged"))
    end
    local way = getText(modData.airDried and "IGUI_TraditionalPreservationFishMeat_DryCured" or "IGUI_TraditionalPreservationFishMeat_ColdSmoked")
    if aged then way = getText("IGUI_TraditionalPreservationFishMeat_AndAged", way) end
    if stage.slice then animal = getText("IGUI_TraditionalPreservationFishMeat_SliceOf", animal) end
    return getText("IGUI_TraditionalPreservationFishMeat_Named", animal, way)
end

-- What one piece of meat comes down as: "charque", "hot", "smoked" or "airDried", named for its cut as the finished
-- item will be. A cut spawned without one gets the item's own name.
local function meatOutcomeName(input, way)
    local index = input:getModelIndex()
    local cut = index and F.MEAT_CUTS[index + 1]
    if way == "hot" and F.isPork(input) and not F.isLeg(input) then return getItemNameFromFullType(F.VANILLA_HAM) end
    if not cut then
        local fullType = way == "charque" and F.CHARQUE or way == "hot" and F.HOT_MEAT
            or F.isLeg(input) and F.COUNTRY_HAM or F.DRY_CURED
        return getItemNameFromFullType(fullType)
    end
    local animal = getText("IGUI_TraditionalPreservationFishMeat_Animal" .. F.MEAT_ANIMALS[index + 1])
    if way == "charque" then return getText("IGUI_TraditionalPreservationFishMeat_CharqueOf", animal) end
    if way == "hot" and F.HOT_ONLY_INDICES[index] then
        return getText("IGUI_TraditionalPreservationFishMeat_HotSmokedOf", getItemNameFromFullType(cut))
    end
    if way == "hot" then return getText("IGUI_TraditionalPreservationFishMeat_HotSmokedOf", animal) end
    if index == F.LEG_INDEX then
        return getText((way == "airDried" and "IGUI_TraditionalPreservationFishMeat_AirDried_" or "IGUI_TraditionalPreservationFishMeat_Smoked_") .. "Leg")
    end
    return getText("IGUI_TraditionalPreservationFishMeat_Named", animal,
        getText(way == "airDried" and "IGUI_TraditionalPreservationFishMeat_DryCured" or "IGUI_TraditionalPreservationFishMeat_ColdSmoked"))
end

-- What a hanging stack would come down as if it were done now, by F.onCreateDried's rules: a stoked run counting in
-- the Smokehouse makes it Hot Smoked, its hours of smoke Cold Smoked, else it is air dried there; on a frame meat
-- is charque unless it dry cures. The names of its pieces' products, each once ("Rotten" for a lost piece). The
-- likeliest result, not a promise: the next stoking, banking or move can change it. For the stack's popup.
function F.stackOutcome(modData, items, method)
    if (modData.spoiled or 0) >= 1 then return getText("IGUI_TraditionalPreservationFishMeat_OutcomeRotten") end
    local way
    if F.inShed(modData) then
        way = (modData.hotOnly or F.cookShare(modData) or F.hotStations[modData.stackId]) and "hot"
            or F.coldDone(modData) and "smoked" or "airDried"
    elseif method == "meat" then
        way = F.dryCuring(modData) and "airDried" or "charque"
    end
    if method ~= "meat" then
        local fullType = method == "cold" and F.COLD_DRIED or way == "hot" and F.HOT_FISH
            or way == "smoked" and F.COLD_FISH_OUT or F.SALT_DRIED
        return getItemNameFromFullType(fullType)
    end
    local names, seen = {}, {}
    for i = 0, items and items:size() - 1 or -1 do
        local input = items:get(i)
        local name
        if (modData.spoiled or 0) + F.underLoss(input, modData) >= 1 then
            name = getText("IGUI_TraditionalPreservationFishMeat_OutcomeRotten")
        else
            name = meatOutcomeName(input, way)
        end
        if not seen[name] then
            seen[name] = true
            table.insert(names, name)
        end
    end
    if #names == 0 then return getText("IGUI_TraditionalPreservationFishMeat_Outcome_" .. way) end
    return table.concat(names, ", ")
end

-- Stockfish is named by its species alone ("Walleye Stockfish"): no size, nor Gutted, which nearly all of it is.
-- One from another mod's fish (no icon of ours) keeps the name it came with. Matured once ripe; Soaked, rehydrated.
local function stockfishName(item, fishName)
    local index = item:getModelIndex()
    if index >= 0 then fishName = getItemNameFromFullType(F.FISH_ICONS[index % #F.FISH_ICONS + 1]) end
    local name = getText("IGUI_TraditionalPreservationFishMeat_Stockfish", fishName)
    local stage = F.STAGES[item:getFullType()]
    if stage.ripened then
        return getText("IGUI_TraditionalPreservationFishMeat_Named", name, getText("IGUI_TraditionalPreservationFishMeat_Rehydrated"))
    end
    if F.ripeness(item) >= 1 then
        return getText("IGUI_TraditionalPreservationFishMeat_Named", name, getText("IGUI_TraditionalPreservationFishMeat_Ripe"))
    end
    return name
end

-- A fish stage's name: the fish (Gutted if it went through Gut Fish), then its stage in brackets, as in
-- "Gutted Medium Walleye (Salt Dried, Rinsed)"; stockfish and meat have their own. Vanilla adds (Fresh) or
-- (Stale) after it. Nil for a stage item that never had a species or a cut.
function F.stageName(item)
    local stage = F.STAGES[item:getFullType()]
    if not stage then return nil end
    if F.isMeatStage(item:getFullType()) then return meatStageName(item) end
    local modData = item:getModData()
    local fishName = modData.fishName
    if not fishName then return nil end
    if stage.matures or stage.ripened then return stockfishName(item, fishName) end
    if stage.prep then return stage.name and getText(stage.name, fishName) or fishName end
    if F.wasGutted(item) then fishName = getText("IGUI_TraditionalPreservationFishMeat_Gutted", fishName) end
    local stageText = getText(stage.name)
    if stage.salty and modData.rinsed then
        stageText = getText("IGUI_TraditionalPreservationFishMeat_And", stageText, getText("IGUI_TraditionalPreservationFishMeat_Rinsed"))
    end
    return getText("IGUI_TraditionalPreservationFishMeat_Named", fishName, stageText)
end

-- Brings a fish stage's name up to date (ripening, ageing), and a maturing
-- stockfish's tooltip, which the game doesn't save. The tooltip has a key for each tenth (..._ColdDried_40):
-- the game looks the text up without formatting it, so a made-up text would log a missing translation.
function F.rename(item)
    local ages = F.ageDays(item) ~= nil
    if ages then F.applyAged(item) end
    local name = F.stageName(item)
    if name and item:getDisplayName() ~= name then
        F.nameAs(item, name)
    end
    -- Dry cured meat's tooltip says how far it has aged, a key per tenth as stockfish; air dried meat's has no
    -- smoke in it.
    if ages then
        local agedness = F.agedness(item)
        local tooltip = "Tooltip_TraditionalPreservationFishMeat_" .. (F.STAGES[item:getFullType()].ham and "CountryHam" or item:getModData().airDried and "AirDried" or "DryCured")
        item:setTooltip(tooltip .. "_" .. (agedness >= 1 and "Aged" or math.floor(agedness * 10) * 10))
    end
    if not F.STAGES[item:getFullType()].matures then return end
    local ripeness = F.ripeness(item)
    local tooltip = "Tooltip_TraditionalPreservationFishMeat_ColdDried"
    if ripeness < 1 then tooltip = tooltip .. "_" .. math.floor(ripeness * 10) * 10 end
    item:setTooltip(tooltip)
end
