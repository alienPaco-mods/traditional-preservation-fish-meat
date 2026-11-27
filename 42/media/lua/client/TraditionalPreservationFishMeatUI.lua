-- Traditional Preservation (Fish & Meat): the stations' placement rules, the hourly renaming of fish and crocks, the
-- natural freezer's looks, Rinse at Sink, Tie / Untie Bale and the Stockfish Pallet's menu. The tub's, the racks' and
-- the Smokehouse's menus and Info windows are in ...TubUI.lua and ...RackUI.lua.
local UI = require "TraditionalPreservationCore/UI"
local Transfer = require "TraditionalPreservationCore/Transfer"
local PlaceKeepingUI = require "TraditionalPreservationCore/PlaceKeepingUI"
local KeepingTooltip = require "TraditionalPreservationCore/KeepingTooltip"
local Weather = require "TraditionalPreservationCore/Weather"
local Tiles = require "TraditionalPreservationFishMeat/Tiles"
local F = TraditionalPreservationFishMeat

-- A tub with anything in it stays where it is: pieces waiting, curing or cured, its time goes by its place (user,
-- 2026-11-19: no station is moved mid-process), and so does one with its board and stone on (Unseal first). Empty,
-- it picks up as any moveable.
UI.keepInPlace(function(isoObject)
    if not F.isTub(isoObject) or not isoObject:hasModData() then return nil end
    local movableData = isoObject:getModData().movableData
    local tub = movableData and movableData[F.TUB_KEY]
    return (tub ~= nil and (F.tubStage(tub) ~= "Empty" or F.tubCount(tub) > 0 or F.tubPressed(tub))) or nil
end)

-- The Gantry and the Hanging Beam keep out of a door's front, indoors or out (TP Core's Smokehouse keeps its own rules).
UI.keepDoorsFree(Tiles.DOOR_KEPT)
-- Nor the frame, the tub or the pallet, at any fill.
UI.keepDoorsFree(Tiles.STATIONS)
UI.keepDoorsFree({ Tiles.PALLET })
UI.keepDoorsFree(Tiles.PALLET_STACKS)

-- Fish names and the stockfish's ripeness follow the days: the player's own things every hour, and any
-- container as soon as the inventory windows show it.
-- Crocks of Potted Meat catch up on their keeping the same way (F.keepCrock).
-- One look through the container (and the bags in it) finds both.
local function staged(item)
    local fullType = item:getFullType()
    return F.STAGES[fullType] ~= nil or fullType == F.CROCK
end

local function renameIn(container)
    if not container then return end
    local items = container:getAllEvalRecurse(staged)
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item:getFullType() == F.CROCK then F.keepCrock(item) else F.rename(item) end
    end
end

Events.EveryHours.Add(function()
    for i = 0, getNumActivePlayers() - 1 do
        local player = getSpecificPlayer(i)
        if player then renameIn(player:getInventory()) end
    end
end)

Events.OnRefreshInventoryWindowContainers.Add(function(page, reason)
    if reason ~= "end" then return end
    for _, button in ipairs(page.backpacks or {}) do renameIn(button.inventory) end
end)

-- A crock is looked at as it is moved, while it is still where it was, so its time there counts at that place.
Transfer.before(function(_, item)
    if item:getFullType() == F.CROCK then F.keepCrock(item) end
end)

-- A crock's tooltip says how long it keeps where it is (TP Core's KeepingTooltip).
KeepingTooltip.add({ [F.CROCK] = true }, function(item) return KeepingTooltip.keeperLines(F.POTTED, item) end)

-- Loose raw meat and fish catch up on their frost whenever they are looked at or moved (TP Core's PlaceKeepingUI).
PlaceKeepingUI.watch({ keep = F.keepFrozen }, F.frostKeptTypes())

-- Rinse at Sink: the Rinse recipe takes carried water, and this takes it from the nearest sink, bathtub, barrel or
-- well of clean water, walking there. It goes in the fish's own submenu, beside the recipe, for every selected fish.
local function onRinse(playerObj, fish, source)
    for _, item in ipairs(fish) do ISInventoryPaneContextMenu.transferIfNeeded(playerObj, item) end
    if not luautils.walkAdj(playerObj, source:getSquare(), true) then return end
    for _, item in ipairs(fish) do ISTimedActionQueue.add(TPFMRinse:new(playerObj, item, source)) end
end

-- The submenu named after the fish that holds its recipes (TP Core's UI.itemSubMenu).
local fishSubMenu = UI.itemSubMenu

local function onFillRinseMenu(playerNum, context, items)
    local fish = UI.selectedItems(items, F.canRinse)
    if #fish == 0 then return end
    local playerObj = getSpecificPlayer(playerNum)
    local source = F.findWaterSource(playerObj, F.RINSE_LITRES)
    if not source then return end
    local option = fishSubMenu(context, fish[1]):addOption(getText("ContextMenu_TraditionalPreservationFishMeat_RinseAtSink"), playerObj, onRinse, fish, source)
    option.iconTexture = fish[1]:getTexture()
    UI.tooltip(option, getText("Tooltip_TraditionalPreservationFishMeat_RinseAtSink", tostring(#fish), string.format("%.2f", F.RINSE_LITRES * #fish)))
end

Events.OnFillInventoryObjectContextMenu.Add(onFillRinseMenu)

-- Tie a Bale on selected stockfish, in the fish's submenu, and Untie Bale on a bale. The fish, the cord and the
-- bale come into the main inventory first.
local function onTieBale(playerObj, fish, cordItem, cord)
    for _, item in ipairs(fish) do ISInventoryPaneContextMenu.transferIfNeeded(playerObj, item) end
    ISInventoryPaneContextMenu.transferIfNeeded(playerObj, cordItem)
    ISTimedActionQueue.add(TPFMTieBale:new(playerObj, fish, cordItem, cord))
end

local function onUntieBale(playerObj, bales)
    for _, bale in ipairs(bales) do
        ISInventoryPaneContextMenu.transferIfNeeded(playerObj, bale)
        ISTimedActionQueue.add(TPFMUntieBale:new(playerObj, bale))
    end
end

local function isBale(item)
    return item:getFullType() == F.BALE_TYPE
end

local function onFillBaleMenu(playerNum, context, items)
    local playerObj = getSpecificPlayer(playerNum)
    local fish = F.baleLoad(UI.selectedItems(items, F.isStockfish))
    if #fish > 0 then
        local cordItem, cord = F.findCord(playerObj:getInventory())
        local option = fishSubMenu(context, fish[1]):addOption(getText("ContextMenu_TraditionalPreservationFishMeat_TieBale"), playerObj, onTieBale, fish, cordItem, cord)
        option.iconTexture = getTexture("Item_StockfishBale")
        if cord then
            local weight = 0
            for _, item in ipairs(fish) do weight = weight + item:getActualWeight() end
            UI.tooltip(option, getText("Tooltip_TraditionalPreservationFishMeat_TieBale", tostring(#fish), string.format("%.1f", weight), cordItem:getDisplayName()))
        else
            UI.refuse(option, getText("Tooltip_TraditionalPreservationFishMeat_TieBaleNoCord"))
        end
    end
    local bales = UI.selectedItems(items, isBale)
    if #bales > 0 then
        local option = context:addOption(getText("ContextMenu_TraditionalPreservationFishMeat_UntieBale"), playerObj, onUntieBale, bales)
        option.iconTexture = getTexture("Item_StockfishBale")
        local cord = F.cordByKey(bales[1]:getModData().cord) or F.BALE_CORDS[1]
        UI.tooltip(option, getText("Tooltip_TraditionalPreservationFishMeat_UntieBale", getItemNameFromFullType(cord.type)))
    end
end

Events.OnFillInventoryObjectContextMenu.Add(onFillBaleMenu)

-- The Stockfish Pallet has no window: its right-click menu says what it does where it stands.
local PALLET_PLACES = { [F.PALLET_AIRED] = "IGUI_TraditionalPreservationFishMeat_PalletAired", [F.PALLET_ROOM] = "IGUI_TraditionalPreservationFishMeat_PalletRoom" }

local function onFillPalletMenu(playerNum, context, worldobjects, test)
    for _, isoObject in ipairs(worldobjects) do
        local sprite = isoObject:getSprite()
        if sprite and sprite:getName() == Tiles.PALLET then
            if test then return end
            local speed = F.palletSpeed(Weather.placeOf(isoObject))
            local text = PALLET_PLACES[speed]
                and getText("ContextMenu_TraditionalPreservationFishMeat_PalletSpeed", tostring(speed), getText(PALLET_PLACES[speed]))
                or getText("ContextMenu_TraditionalPreservationFishMeat_PalletNoSpeed")
            local option = context:addOption(text)
            option.iconTexture = getTexture("Item_StockfishPallet")
            UI.tooltip(option, getText("Tooltip_craft_stockfishPalletDesc"))
            return
        end
    end
end

Events.OnFillWorldObjectContextMenu.Add(onFillPalletMenu)

-- The pallet's own icon in the loot window, not vanilla's shelves (its container type: tools/build_tileset.py).
UI.containerIcon("stockfishpallet", "media/textures/Container_StockfishPallet.png")
