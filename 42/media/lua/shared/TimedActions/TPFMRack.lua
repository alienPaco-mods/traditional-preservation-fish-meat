-- Traditional Preservation (Fish & Meat): the hand jobs at a Drying Frame, a Hanging Beam or a Gantry. "hang" hangs
-- one carried piece (if the rack still takes it when the hands are done), "take" takes one piece off by its id: what
-- it has become if done, as it was hung if not (F.rackOutput). One piece an action, so a queue of them shows its
-- progress and stops where the player stops it.
require "TimedActions/ISBaseTimedAction"
require "TraditionalPreservationFishMeat"

TPFMRack = ISBaseTimedAction:derive("TPFMRack")

local F = TraditionalPreservationFishMeat
local Action = require "TraditionalPreservationCore/Action"
local Weather = require "TraditionalPreservationCore/Weather"
local DURATIONS = { hang = 40, take = 30 }

local function carried(self)
    return self.item ~= nil and self.character:getInventory():containsRecursive(self.item)
end

-- Why the rack won't take this piece now, or nil.
function TPFMRack.hangRefusal(station, rack, place, item)
    return F.rackRefusal(rack, F.hangerOf(station), place, item)
end

local function holds(rack, id)
    for _, piece in ipairs(rack.pieces or {}) do
        if piece.id == id then return true end
    end
    return false
end

function TPFMRack:isValid()
    if not self.station:getSquare() then return false end
    local rack = F.rackOf(self.station)
    if self.mode == "hang" then
        return carried(self) and TPFMRack.hangRefusal(self.station, rack, Weather.placeOf(self.station), self.item) == nil
    end
    return holds(rack, self.id)
end

function TPFMRack:waitToStart()
    self.character:faceThisObject(self.station)
    return self.character:shouldBeTurning()
end

-- Vanilla's take-down-curtain reach (ISRemoveSheetAction), hands empty: up to the rack, hanging or taking down.
function TPFMRack:start()
    self:setActionAnim("RemoveCurtain")
    self:setOverrideHandModels(nil, nil)
end

function TPFMRack:complete()
    local rack, place = F.rackNow(self.station)
    local now = getGameTime():getWorldAgeHours()
    if self.mode == "hang" then
        if carried(self) and TPFMRack.hangRefusal(self.station, rack, place, self.item) == nil then
            F.hangPiece(rack, self.item, place, F.getLedger(), now)
            Action.removeItem(self.item)
        end
    else
        local piece = F.takePiece(rack, self.id)
        if piece then Actions.addOrDropItem(self.character, F.rackOutput(piece, now)) end
    end
    return true
end

function TPFMRack:perform()
    ISBaseTimedAction.perform(self)
end

function TPFMRack:getDuration()
    return Action.duration(self.character, DURATIONS[self.mode])
end

-- "hang": item is the carried piece; "take": id is the piece's id on this rack.
function TPFMRack:new(character, station, mode, item, id)
    local o = ISBaseTimedAction.new(self, character)
    o.station = station
    o.mode = mode
    o.item = item
    o.id = id
    o.maxTime = o:getDuration()
    return o
end
