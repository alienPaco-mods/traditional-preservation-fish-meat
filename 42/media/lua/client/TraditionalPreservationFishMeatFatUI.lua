-- Traditional Preservation (Fish & Meat): fat in the cauldron of TP Core's Stone Hearth. Put Fat in the Cauldron on the
-- Stone Hearth's menu has a row for each kind of raw fat carried, and Stone Hearth Info says how the fat in the cauldron is doing.
require "TraditionalPreservationFishMeatFat"
require "TimedActions/TPFMFatCauldron"
local UI = require "TraditionalPreservationCore/UI"
local CauldronFluid = require "TraditionalPreservationCore/CauldronFluid"
local CauldronUI = require "TraditionalPreservationCore/CauldronUI"
local F = TraditionalPreservationFishMeat

local function onFatInCauldron(playerObj, fire, raw, pieces)
    if not luautils.walkAdj(playerObj, fire:getSquare(), true) then return end
    for _, item in ipairs(pieces) do ISInventoryPaneContextMenu.transferIfNeeded(playerObj, item) end
    ISTimedActionQueue.add(TPFMFatCauldron:new(playerObj, fire, raw, pieces))
end

CauldronUI.addMenu(function(menu, playerObj, fire, cauldron)
    local carried = {}
    for _, fat in ipairs(F.CAULDRON_FATS) do
        local pieces = UI.findItems(playerObj, function(item) return fat.items[item:getFullType()] and not item:isRotten() end)
        if #pieces > 0 then table.insert(carried, { fat = fat, pieces = pieces }) end
    end
    -- Only someone carrying raw fat sees the row.
    if #carried == 0 then return end
    local option = menu:addOption(getText("ContextMenu_TraditionalPreservationFishMeat_FatInCauldron"))
    option.iconTexture = getTexture("Item_PorkFat")
    local sub = menu:getNew(menu)
    menu:addSubMenu(option, sub)
    for _, entry in ipairs(carried) do
        local row = sub:addOption(getText("ContextMenu_TraditionalPreservationFishMeat_FatPieces_" .. entry.fat.name, tostring(#entry.pieces)),
            playerObj, onFatInCauldron, fire, entry.fat.raw, entry.pieces)
        row.itemForTexture = entry.pieces[1]
        if F.cauldronFatRoom(cauldron, entry.fat.raw) > 0 then
            UI.tooltip(row, getText("IGUI_TraditionalPreservationFishMeat_FatHelp"))
        else
            UI.refuse(row, getText("IGUI_TraditionalPreservationFishMeat_FatNoRoom"))
        end
    end
end)

CauldronUI.addNotes(function(info, notes)
    local cauldron = info.part
    if (cauldron.ml or 0) <= 0 then return end
    if cauldron.fluid == F.RANCID_FAT then
        table.insert(notes, getText("IGUI_TraditionalPreservationFishMeat_FatRancid"))
        return
    end
    for _, fat in ipairs(F.CAULDRON_FATS) do
        if cauldron.fluid == fat.melted then
            table.insert(notes, getText("IGUI_TraditionalPreservationFishMeat_FatMelted"))
        elseif cauldron.fluid == fat.raw then
            local now = getGameTime():getWorldAgeHours()
            table.insert(notes, getText("IGUI_TraditionalPreservationFishMeat_FatRendering",
                UI.hoursText(CauldronFluid.hoursToTurn(cauldron) or 0), UI.hoursText(math.max((cauldron.offAt or now) - now, 0))))
        end
    end
end)
