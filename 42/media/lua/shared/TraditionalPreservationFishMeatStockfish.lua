-- Traditional Preservation (Fish & Meat): stockfish in storage: the Stockfish Pallet's ripening and the bale. Required by TraditionalPreservationFishMeat.lua, whose F it adds
-- to.
TraditionalPreservationFishMeat = TraditionalPreservationFishMeat or {}
local F = TraditionalPreservationFishMeat
local Action = require "TraditionalPreservationCore/Action"

-- How much faster a pallet ripens stockfish than a shelf: place is Weather.placeOf's (a Loft is TP Core's, a room
-- above the ground floor).
function F.palletSpeed(place)
    if place == "Loft" then return F.PALLET_LOFT end
    if place == "Sheltered" then return F.PALLET_GROUND end
    return 1
end

function F.isStockfish(item)
    local stage = F.STAGES[item:getFullType()]
    return stage ~= nil and stage.matures == true
end

-- Calls fn on each stockfish in the container, and in the bales in it.
function F.eachStockfish(container, fn)
    local items = container:getItems()
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if F.isStockfish(item) then
            fn(item)
        elseif item:getFullType() == F.BALE_TYPE and item:getInventory() then
            F.eachStockfish(item:getInventory(), fn)
        end
    end
end

-- The stack to show, 1 to PALLET_LEVELS by the share of the pallet filled, or nil when it is empty or holds
-- anything but stockfish and bales of it.
function F.palletLevel(container)
    local items = container:getItems()
    if items:size() == 0 then return nil end
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if not F.isStockfish(item) then
            if item:getFullType() ~= F.BALE_TYPE then return nil end
            local inside = item:getInventory():getItems()
            for j = 0, inside:size() - 1 do
                if not F.isStockfish(inside:get(j)) then return nil end
            end
        end
    end
    local share = container:getContentsWeight() / F.PALLET_CAPACITY
    return math.max(1, math.min(F.PALLET_LEVELS, math.ceil(share * F.PALLET_LEVELS - 0.0001)))
end

-- Ripens the stockfish on a pallet by extra days of its food clock, by moving its stamp back. A ripe fish stays ripe.
function F.ripenOnPallet(container, extraDays)
    if extraDays <= 0 then return end
    F.eachStockfish(container, function(fish)
        local modData = fish:getModData()
        if modData.matureAge and F.ripeness(fish) < 1 then
            modData.matureAge = modData.matureAge - extraDays
            F.rename(fish)
        end
    end)
end

-- The bale's AcceptItemFunction: only stockfish goes in.
function F.acceptBale(container, item)
    return F.isStockfish(item)
end

-- The cord a bale is tied with: Twine with a use left first, as it is the lighter, then a Rope.
-- Returns the item and its BALE_CORDS entry, or nil.
function F.findCord(inventory)
    for _, cord in ipairs(F.BALE_CORDS) do
        local found = inventory:getFirstEvalRecurse(function(item)
            return item:getFullType() == cord.type and (not cord.uses or item:getCurrentUses() >= cord.uses)
        end)
        if found then return found, cord end
    end
    return nil
end

function F.cordByKey(key)
    for _, cord in ipairs(F.BALE_CORDS) do
        if cord.key == key then return cord end
    end
    return nil
end

-- The stockfish that fit in one bale, in the order given, up to BALE_CAPACITY weight; the rest stay out.
function F.baleLoad(fish)
    local load, weight = {}, 0
    for _, item in ipairs(fish) do
        if F.isStockfish(item) and weight + item:getActualWeight() <= F.BALE_CAPACITY + 0.0001 then
            table.insert(load, item)
            weight = weight + item:getActualWeight()
        end
    end
    return load
end

-- Ties the fish (all in the inventory) into a new bale with the cord, which is used up. Returns the bale.
function F.tieBale(inventory, fish, cordItem, cord)
    local bale = inventory:AddItem(F.BALE_TYPE)
    bale:getModData().cord = cord.key
    bale:setCustomWeight(true)
    bale:setActualWeight(cord.weight)
    local inside = bale:getInventory()
    for _, item in ipairs(fish) do
        Action.removeItem(item)
        inside:AddItem(item)
    end
    if cord.uses then
        for _ = 1, cord.uses do cordItem:UseAndSync() end
    else
        Action.removeItem(cordItem)
    end
    return bale
end

-- Unties a bale in the inventory: its fish and the cord that tied it go into the inventory, the bale is gone.
-- A bale spawned with no cord recorded (the debug Item List, loot) gives back Twine.
function F.untieBale(inventory, bale)
    local items = bale:getInventory():getItems()
    for i = items:size() - 1, 0, -1 do
        local item = items:get(i)
        Action.removeItem(item)
        inventory:AddItem(item)
    end
    local cord = F.cordByKey(bale:getModData().cord) or F.BALE_CORDS[1]
    local given = inventory:AddItem(cord.type)
    if cord.uses then given:setCurrentUses(cord.uses) end
    Action.removeItem(bale)
end
