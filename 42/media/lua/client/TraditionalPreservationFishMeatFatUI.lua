-- Traditional Preservation (Fish & Meat): fat in the cauldron of TP Core's Stone Hearth. Put Fat in the Cauldron on the
-- Stone Hearth's menu has a row for each kind of raw fat carried, and Stone Hearth Info says how the fat in the cauldron is doing.
require "TraditionalPreservationFishMeatFat"
local UI = require "TraditionalPreservationCore/UI"
local CauldronFluid = require "TraditionalPreservationCore/CauldronFluid"
local CauldronUI = require "TraditionalPreservationCore/CauldronUI"
local F = TraditionalPreservationFishMeat

-- A row for each kind of raw fat (TP Core's CauldronUI.addPieces and its action).
local fluidRows = {}
for _, fat in ipairs(F.CAULDRON_FATS) do
    table.insert(fluidRows, { fluid = fat.raw, items = fat.items, label = function(count)
        return getText("ContextMenu_TraditionalPreservationFishMeat_FatPieces_" .. fat.name, tostring(count))
    end })
end
CauldronUI.addPieces({
    title = getText("ContextMenu_TraditionalPreservationFishMeat_FatInCauldron"),
    icon = "Item_PorkFat",
    pieceMl = F.FAT_PIECE_ML,
    hoursLeft = F.fatHoursLeft,
    fluidRows = fluidRows,
    help = getText("IGUI_TraditionalPreservationFishMeat_FatHelp"),
    noRoom = getText("IGUI_TraditionalPreservationFishMeat_FatNoRoom"),
})

CauldronUI.addNotes(function(fireView, notes)
    local cauldron = fireView.part
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
