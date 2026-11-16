-- Traditional Preservation (Fish & Meat): the Smokehouse, its Stone Hearth and the flue are TP Core's (Smokehouse.lua,
-- SmokehouseUI.lua). Stone Hearth Info adds what a Stone Hearth joined to the Smokehouse does to this mod's stacks in the shed.
local FireUI = require "TraditionalPreservationCore/FireUI"
local Smokehouse = require "TraditionalPreservationCore/Smokehouse"

FireUI.addNotes(function(fireView, notes)
    if fireView.connection and fireView.connection.id == Smokehouse.ID then table.insert(notes, getText("IGUI_TraditionalPreservationFishMeat_FlueSmokes")) end
end)
