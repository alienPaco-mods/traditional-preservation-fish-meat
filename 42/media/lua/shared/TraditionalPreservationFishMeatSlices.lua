-- Traditional Preservation (Fish & Meat): slices, phase 6c. Hot Smoked meat and dry cured cuts slice into as many
-- slices of about SLICE_HUNGER as they hold, MIN_SLICES at least (a Beef (Hot Smoked) six, a dry cured chop two). A
-- Country Ham is carved: CARVE_SLICES slices of CARVE_HUNGER in all come off and the ham stays, lighter, on its own
-- long clock, until the last carving takes what is left: fifteen slices from a leg in three carvings. A
-- slice takes its share of the piece's food and mood, keeps half the piece's days (its script) and starts as far
-- through them as the piece was. Hot smoked pork is vanilla's Ham, which vanilla slices. Hot smoked poultry and
-- rabbit aren't sliced; a whole bird is carved into vanilla's six cuts.
require "TraditionalPreservationFishMeat/Common"
TraditionalPreservationFishMeat = TraditionalPreservationFishMeat or {}
local F = TraditionalPreservationFishMeat
local Recipes = require "TraditionalPreservationCore/Recipes"

F.SLICE_HUNGER = 0.14
-- What the slicing recipes' scripts give; the rest are made in OnCreate.
F.MIN_SLICES = 2
F.CARVE_SLICES = 5
F.CARVE_HUNGER = 0.7
-- With this much hunger or less left on it, the next carving is the ham's last.
F.CARVE_LAST = 1.05
F.SLICES = {
    [F.HOT_MEAT] = F.HOT_SLICE,
    [F.DRY_CURED] = F.DRY_CURED_SLICE,
    [F.COUNTRY_HAM] = F.HAM_SLICE,
}

-- The mood and thirst a food item gives as it is, not as staleness or cooking would change them.
local EXTRAS = { "UnhappyChange", "BoredomChange", "ThirstChange" }
local function extra(item, field)
    local unmodified = item["get" .. field .. "Unmodified"]
    if unmodified then return unmodified(item) end
    return item["get" .. field](item)
end

-- A slice's age: as far through its shorter days as the piece is through its own, fresh and stale alike.
function F.sliceAge(age, offAge, offAgeMax, sliceOffAge, sliceOffAgeMax)
    if age <= offAge or offAgeMax <= offAge then return age / offAge * sliceOffAge end
    return sliceOffAge + math.min((age - offAge) / (offAgeMax - offAge), 1) * (sliceOffAgeMax - sliceOffAge)
end

-- How many slices a cut gives: what is left of it in slices of about SLICE_HUNGER.
function F.sliceCount(piece)
    return math.max(F.MIN_SLICES, math.floor(-piece:getHungChange() / F.SLICE_HUNGER + 0.5))
end

-- Gives each slice (a Lua list) an equal part of `share` of the piece: food, weight, mood, what it was made of and
-- whether it had aged. A slice is a whole thing, not a part-eaten one.
function F.fillSlices(piece, slices, share)
    F.rename(piece)
    local each = share / #slices
    local pieceData = piece:getModData()
    for _, slice in ipairs(slices) do
        F.copyFood(piece, slice, each)
        slice:setBaseHunger(slice:getHungChange())
        for _, field in ipairs(EXTRAS) do slice["set" .. field](slice, extra(piece, field) * each) end
        slice:setActualWeight(piece:getActualWeight() * each)
        slice:setCustomWeight(true)
        slice:setAge(F.sliceAge(piece:getAge(), piece:getOffAge(), piece:getOffAgeMax(), slice:getOffAge(), slice:getOffAgeMax()))
        local modData = slice:getModData()
        modData.cut = piece:getModelIndex()
        modData.airDried = pieceData.airDried
        modData.aged = pieceData.aged
        F.rename(slice)
    end
end

-- Takes `share` off what is left of a piece: its food, mood and weight. BaseHunger stays, as when it is eaten.
function F.carveOff(piece, share)
    local left = 1 - share
    piece:setHungChange(piece:getHungChange() * left)
    F.scaleNutrients(piece, left)
    for _, field in ipairs(EXTRAS) do piece["set" .. field](piece, extra(piece, field) * left) end
    piece:setActualWeight(piece:getActualWeight() * left)
    piece:setCustomWeight(true)
end

-- Whether a ham has more on it than one last carving. HungChange is negative.
function F.carvesOn(ham)
    return -ham:getHungChange() > F.CARVE_LAST + 0.001
end

-- OnTest sees every input, so the knife passes here too.
function F.canCarve(item)
    return item:getFullType() ~= F.COUNTRY_HAM or F.carvesOn(item)
end

function F.canCarveLast(item)
    return item:getFullType() ~= F.COUNTRY_HAM or not F.carvesOn(item)
end

-- Hot smoked poultry and rabbit (0.4.34) aren't sliced: the cuts are eaten as they are, and a whole bird is carved
-- (Carve Chicken / Turkey (Hot Smoked)). OnTest sees the knife too.
function F.canSliceHot(item)
    return item:getFullType() ~= F.HOT_MEAT or not F.isHotOnly(item)
end

-- Whether this is a whole bird of the MEAT_CUTS index wanted, at a stage (a full type; Hot Smoked if left out).
-- Anything else in the recipe (the knife) passes.
local function wholeBird(item, index, stage)
    return item:getFullType() ~= (stage or F.HOT_MEAT) or item:getModelIndex() == index
end

function F.canCarveChicken(item)
    return wholeBird(item, F.WHOLE_CHICKEN)
end

function F.canCarveTurkey(item)
    return wholeBird(item, F.WHOLE_TURKEY)
end

-- A whole bird packed in salt, or corned in the tub, is carved too, so a bird packed whole can still go on in pieces.
function F.canCarvePackedChicken(item)
    return wholeBird(item, F.WHOLE_CHICKEN, F.PACKED_MEAT)
end

function F.canCarvePackedTurkey(item)
    return wholeBird(item, F.WHOLE_TURKEY, F.PACKED_MEAT)
end

function F.canCarveCornedChicken(item)
    return wholeBird(item, F.WHOLE_CHICKEN, F.CURED_MEAT)
end

function F.canCarveCornedTurkey(item)
    return wholeBird(item, F.WHOLE_TURKEY, F.CURED_MEAT)
end

-- A copy of a modData value, tables copied through, so the pieces don't share one.
local function copyValue(value)
    if type(value) ~= "table" then return value end
    local copy = {}
    for key, inner in pairs(value) do copy[key] = copyValue(inner) end
    return copy
end

local created = Recipes.created

-- Carve Chicken / Turkey (Hot Smoked, Salt Packed or Corned): the script's six pieces become 2 legs, 2 wings and 2
-- fillets (WHOLE_BIRDS), sharing the bird's food by the vanilla cuts' hunger and weighing CARVE_BIRD_SHARE of it in
-- all, as vanilla's Cut Chicken does; each keeps the bird's mood, salt and age. A smoked bird's cuts keep its rinse,
-- stack and style; a packed or corned bird's keep its whole cure record, so they go on in the tub or the shed as it would.
function F.onCreateBirdCarved(craftRecipeData)
    local bird = craftRecipeData:getAllInputItemsWithFlag("ItemCount"):get(0)
    local cuts = F.WHOLE_BIRDS[bird:getModelIndex()]
    local pieces = created(craftRecipeData)
    if not cuts then return end
    local hungers, total = {}, 0
    for n, index in ipairs(cuts) do
        hungers[n] = math.abs(instanceItem(F.MEAT_CUTS[index + 1]):getHungChange())
        total = total + 2 * hungers[n]
    end
    for i, piece in ipairs(pieces) do
        local n = math.floor((i - 1) / 2) + 1
        local share = hungers[n] / total
        F.copyFood(bird, piece, share)
        for _, field in ipairs(EXTRAS) do piece["set" .. field](piece, extra(bird, field) * share) end
        piece:setActualWeight(bird:getActualWeight() * share * F.CARVE_BIRD_SHARE)
        piece:setCustomWeight(true)
        piece:setAge(bird:getAge())
        piece:setModelIndex(cuts[n])
        local modData, birdData = piece:getModData(), bird:getModData()
        if bird:getFullType() == F.HOT_MEAT then
            modData.rinsed, modData.stackId, modData.style = birdData.rinsed, birdData.stackId, birdData.style
        else
            for key, value in pairs(birdData) do modData[key] = copyValue(value) end
        end
        F.rename(piece)
    end
end

-- Slice Hot Smoked Meat and Slice Dry Cured Meat: the whole cut, in as many slices as it holds. The recipe makes
-- MIN_SLICES; the rest go straight to the character.
function F.onCreateMeatSliced(craftRecipeData, character)
    local piece = craftRecipeData:getAllInputItemsWithFlag("ItemCount"):get(0)
    local slices = created(craftRecipeData)
    local inventory = (character or craftRecipeData:getCharacter()):getInventory()
    for _ = #slices + 1, F.sliceCount(piece) do
        table.insert(slices, inventory:AddItem(instanceItem(slices[1]:getFullType())))
    end
    F.fillSlices(piece, slices, 1)
end

-- Carve the Last of a Country Ham: all that is left, in the carving's slices.
function F.onCreateLastCarved(craftRecipeData)
    local ham = craftRecipeData:getAllInputItemsWithFlag("ItemCount"):get(0)
    F.fillSlices(ham, created(craftRecipeData), 1)
end

-- Carve a Country Ham: the ham is kept, less the slices.
function F.onCreateCarved(craftRecipeData)
    local ham = craftRecipeData:getAllInputItemsWithFlag("ItemCount"):get(0)
    local share = math.min(1, F.CARVE_HUNGER / -ham:getHungChange())
    F.fillSlices(ham, created(craftRecipeData), share)
    F.carveOff(ham, share)
end
