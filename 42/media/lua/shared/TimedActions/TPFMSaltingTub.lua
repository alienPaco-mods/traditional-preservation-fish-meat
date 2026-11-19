-- Traditional Preservation (Fish & Meat): the hand jobs at a Salting Tub. "put" lays one piece of fish or meat in,
-- "unpack" takes everything back out before it is salted, "start" salts the batch and lays the board and stone on it
-- for one of the cures (method: "fish", "corn" or "long"), and "take" takes one cured piece out. The last piece gives
-- the board and stone back.
require "TimedActions/ISBaseTimedAction"
require "TraditionalPreservationFishMeat"

TPFMSaltingTub = ISBaseTimedAction:derive("TPFMSaltingTub")

local F = TraditionalPreservationFishMeat
local Action = require "TraditionalPreservationCore/Action"
local Uses = require "TraditionalPreservationCore/Uses"
local DURATIONS = { put = 50, unpack = 150, start = 250, take = 40 }

-- Brought up to the minute first, so a tub that has just finished is seen as it is now.
local function tubNow(self)
    if TraditionalPreservationFishMeatWorld then return TraditionalPreservationFishMeatWorld.updateTub(self.station) end
    return F.tubOf(self.station)
end

local function inInventory(self, item)
    return item ~= nil and self.character:getInventory():containsRecursive(item)
end

-- What the character has on them for a start, as F.startRefusal reads it: the salt's uses, the board and the stone.
function TPFMSaltingTub.startKit(character)
    local inventory = character:getInventory()
    return { salt = Uses.count(character, ItemTag.SALT), board = inventory:getFirstTypeRecurse(F.TUB_BOARD),
        stone = inventory:getFirstTypeRecurse(F.TUB_STONE) }
end

-- Why this piece can't go in this tub, or nil.
function TPFMSaltingTub.putRefusal(tub, item)
    return F.tubItemRefusal(item) or F.tubRefusal(tub, F.tubKindOf(item), F.packedWeight(item))
end

function TPFMSaltingTub:isValid()
    if not self.station:getSquare() then return false end
    local tub = F.tubOf(self.station)
    local stage = F.tubStage(tub)
    if self.mode == "put" then
        return inInventory(self, self.item) and TPFMSaltingTub.putRefusal(tub, self.item) == nil
    elseif self.mode == "unpack" then
        return stage == "Packing"
    elseif self.mode == "start" then
        -- The kit is looked for once, before the action starts, and again as it ends: not on every tick.
        return self.started or F.startRefusal(tub, self.method, TPFMSaltingTub.startKit(self.character)) == nil
    end
    return stage == "Done"
end

function TPFMSaltingTub:waitToStart()
    self.character:faceThisObject(self.station)
    return self.character:shouldBeTurning()
end

function TPFMSaltingTub:start()
    self.started = true
    self:setActionAnim("Loot")
end

local function give(character, fullType)
    Actions.addOrDropItem(character, instanceItem(fullType))
end

function TPFMSaltingTub:complete()
    local tub = tubNow(self)
    local character = self.character
    local now = getGameTime():getWorldAgeHours()
    if self.mode == "put" then
        if inInventory(self, self.item) and TPFMSaltingTub.putRefusal(tub, self.item) == nil then
            F.putInTub(tub, F.tubPiece(self.item, now))
            Action.removeItem(self.item)
        end
    elseif self.mode == "unpack" then
        for _, piece in ipairs(F.unpackTub(tub, now)) do
            Actions.addOrDropItem(character, F.itemFromKept(piece))
        end
    elseif self.mode == "start" then
        local kit = TPFMSaltingTub.startKit(character)
        if F.startRefusal(tub, self.method, kit) == nil then
            Uses.take(character, ItemTag.SALT, F.tubSalt(tub))
            Action.removeItem(kit.board)
            Action.removeItem(kit.stone)
            Action.addXp(character, { "Cooking", F.TUB_SALT_XP * F.tubCount(tub) })
            F.startTub(tub, self.method, F.getLedger())
        end
    else
        local taken = F.takeFromTub(tub)
        if taken then
            Actions.addOrDropItem(character, F.curedFromTub(taken, now))
            if taken.last then
                give(character, F.TUB_BOARD)
                give(character, F.TUB_STONE)
            end
        end
    end
    if TraditionalPreservationFishMeatWorld then TraditionalPreservationFishMeatWorld.refresh(self.station) end
    return true
end

function TPFMSaltingTub:perform()
    ISBaseTimedAction.perform(self)
end

function TPFMSaltingTub:getDuration()
    return Action.duration(self.character, DURATIONS[self.mode])
end

-- item is the piece for "put"; method the cure for "start".
function TPFMSaltingTub:new(character, station, mode, item, method)
    local o = ISBaseTimedAction.new(self, character)
    o.station = station
    o.mode = mode
    o.item = item
    o.method = method
    o.maxTime = o:getDuration()
    return o
end
