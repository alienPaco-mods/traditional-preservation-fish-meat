-- Traditional Preservation (Fish & Meat): Put Fat in the Cauldron, putting pieces of raw fat from the inventory into
-- a Stone Hearth's cauldron (TP Core's), as many as fit.
require "TimedActions/ISBaseTimedAction"
require "TraditionalPreservationFishMeatFat"

TPFMFatCauldron = ISBaseTimedAction:derive("TPFMFatCauldron")

local F = TraditionalPreservationFishMeat
local Fire = require "TraditionalPreservationCore/Fire"
local Action = require "TraditionalPreservationCore/Action"

local TICKS_A_PIECE = 15

-- The pieces still on the player and not rotten.
local function piecesHere(self)
    local inventory, here = self.character:getInventory(), {}
    for _, item in ipairs(self.pieces) do
        if inventory:containsRecursive(item) and not item:isRotten() then table.insert(here, item) end
    end
    return here
end

function TPFMFatCauldron:isValid()
    return self.hearth:getSquare() ~= nil and #piecesHere(self) > 0
        and F.cauldronFatRoom(Fire.cauldronState(self.hearth:getModData()), self.raw) > 0
end

function TPFMFatCauldron:waitToStart()
    self.character:faceThisObject(self.hearth)
    return self.character:shouldBeTurning()
end

function TPFMFatCauldron:start()
    self:setActionAnim("Loot")
end

function TPFMFatCauldron:complete()
    -- Brought up to the minute first, so the fat mixes with the cauldron as it is now.
    local cauldron = Fire.cauldronOf(self.hearth)
    local now = getGameTime():getWorldAgeHours()
    local pieces, hoursLeft = piecesHere(self), {}
    for index, item in ipairs(pieces) do hoursLeft[index] = F.fatHoursLeft(item) end
    local count = F.putFatInCauldron(cauldron, self.raw, hoursLeft, now)
    for index = 1, count do
        Action.removeItem(pieces[index])
    end
    Fire.redraw(self.hearth)
    return count > 0
end

function TPFMFatCauldron:perform()
    ISBaseTimedAction.perform(self)
end

function TPFMFatCauldron:getDuration()
    return Action.duration(self.character, TICKS_A_PIECE * #self.pieces)
end

function TPFMFatCauldron:new(character, hearth, raw, pieces)
    local o = ISBaseTimedAction.new(self, character)
    o.hearth = hearth
    o.raw = raw
    o.pieces = pieces
    o.maxTime = o:getDuration()
    return o
end
