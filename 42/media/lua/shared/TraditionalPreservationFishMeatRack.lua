-- Traditional Preservation (Fish & Meat): what hangs on a Drying Frame, a Hanging Beam or a Gantry (ROADMAP section 12;
-- was a CraftLogic recipe a stack). Each piece hangs on its own: its item kept as the tub keeps one (F.keptPiece), and
-- its own clock, the state a stack used to keep (dried, spoiled, its marks on the ledger, its look), so the drying
-- rules are the stacks' own, run a piece at a time: F.saltStep, F.coldStep, F.charqueStep. A rack takes up to its
-- total weight and its count of pieces, none heavier than its heaviest. A finished piece waits on the rack, ageing
-- at vanilla's pace, until taken; taking it makes what the stack's recipe made (F.rackOutput).
-- The record sits in the rack's movableData (F.RACK_KEY); a rack holding anything stays where it is.
-- Required by TraditionalPreservationFishMeat.lua.
TraditionalPreservationFishMeat = TraditionalPreservationFishMeat or {}
local F = TraditionalPreservationFishMeat
local Station = require "TraditionalPreservationCore/Station"
local FluidAgeing = require "TraditionalPreservationCore/FluidAgeing"
local Weather = require "TraditionalPreservationCore/Weather"
require "TraditionalPreservationFishMeatSmokehouse"   -- F.startSmoke, F.smokedItem

F.RACK_KEY = "tpfmRack"       -- a rack's record in its movableData; never rename once the mod is out

-- Each rack's room (ROADMAP section 12, item 2): its total weight, its heaviest piece and its most pieces, all kg.
-- The totals and counts are the old stacks' (stacks x stack weight, stacks x pieces a stack); the heaviest piece is
-- new, so each rung takes its own size of fish.
F.RACK_LIMITS = {
    frame = { total = 20, heaviest = 2.5, pieces = 200 },
    medium = { total = 60, heaviest = 5, pieces = 48 },
    large = { total = 100, heaviest = 12, pieces = 12 },
}

-- What each way of hanging needs and gives, by F.hangMethod: the hours at a rate of 1 (read when asked: the sandbox
-- sets them), the step that brings a piece up to now, its looks and what comes off.
local METHODS = {
    salt = { hours = function() return F.DRY_HOURS end, step = function(state, ledger) F.saltStep(state, ledger) end,
        output = F.SALT_DRIED, styles = function() return F.pickStyle(F.SALT_STYLES) end, smoke = true },
    cold = { hours = function() return F.COLD_DRY_HOURS end, step = function(state, ledger) F.coldStep(state, ledger) end,
        output = F.COLD_DRIED, styles = function() return F.pickStyle(F.COLD_STYLES) end },
    meat = { hours = function(state) return F.meatHours(state) end, step = function(state, ledger) F.charqueStep(state, ledger) end,
        output = F.CHARQUE, styles = function() return F.STYLE_MEAT end, smoke = true, isMeat = true },
}
F.RACK_METHODS = METHODS

function F.rackCount(rack)
    return #(rack.pieces or {})
end

function F.rackWeight(rack)
    local weight = 0
    for _, piece in ipairs(rack.pieces or {}) do weight = weight + piece.weight end
    return weight
end

-- Why this item can't hang on this rack now, as a translation key (F.REFUSALS), or nil. hanger is the rack's
-- (F.hangerOf), place where it stands (Weather.placeOf). The item first, then the place, then the room.
function F.rackRefusal(rack, hanger, place, item)
    local fullType = item:getFullType()
    local refusal = F.fishRefusal(fullType) or F.sausageRefusal(hanger, item)
    if refusal then return refusal end
    local method = F.hangMethod(fullType)
    if method == "meat" then refusal = F.meatRefusal(hanger, place, item) end
    if method == "cold" then refusal = F.coldRefusal(place) end
    if refusal then return refusal end
    local limits = F.RACK_LIMITS[hanger.name]
    local weight = item:getActualWeight()
    if weight > limits.heaviest then return F.REFUSALS.tooHeavy end
    if F.rackCount(rack) >= limits.pieces or not F.hasRoom(limits.total, F.rackWeight(rack), weight) then
        return F.REFUSALS.frameFull
    end
    return nil
end

-- An ArrayList of one, for the stack code that reads its pieces from one (F.startSmoke).
local function listOf(item)
    return { size = function() return 1 end, get = function() return item end }
end

-- Hangs an item at place: kept, its clock started as a stack's was (startStack and the method's OnStart), marked
-- on the ledger from now, with an id of its own on this rack (pieces are taken by id: a queue of takes doesn't
-- shift). Returns the piece.
function F.hangPiece(rack, item, place, ledger, now)
    local piece = F.keptPiece(item, now)
    rack.nextId = (rack.nextId or 0) + 1
    piece.id = rack.nextId
    piece.method = F.hangMethod(piece.fullType)
    local method = METHODS[piece.method]
    local state = { dried = 0, spoiled = piece.data.cureSpoiled or 0, stackId = now, place = place }
    F.markStack(state, ledger)
    if method.smoke then F.startSmoke(state, listOf(F.keptItem(piece)), method.isMeat == true) end
    state.style = method.styles()
    piece.state = state
    rack.pieces = rack.pieces or {}
    table.insert(rack.pieces, piece)
    return piece
end

-- A piece's share done (0 to 1; a rotten one counts as done), and whether it rotted.
function F.pieceProgress(piece)
    local state = piece.state
    if F.stackRotten(state) then return 1, true end
    return F.stackProgress(state, METHODS[piece.method].hours(state)), false
end

function F.pieceDone(piece)
    return piece.doneHour ~= nil
end

-- Brings every hanging piece up to now at place, the rack's place at this look. A piece that is done (or rotted)
-- stops there, its hour kept: from then it ages as food does. A piece hung before pieces had ids gets one here.
function F.updateRack(rack, place, ledger, now)
    for _, piece in ipairs(rack.pieces or {}) do
        if not piece.id then
            rack.nextId = (rack.nextId or 0) + 1
            piece.id = rack.nextId
        end
        if not F.pieceDone(piece) then
            piece.state.place = place
            METHODS[piece.method].step(piece.state, ledger)
            if F.pieceProgress(piece) >= 1 then piece.doneHour = now end
        end
    end
end

-- The ids of the pieces done (doneOnly) or of every piece, in hang order.
function F.pieceIds(rack, doneOnly)
    local ids = {}
    for _, piece in ipairs(rack.pieces or {}) do
        if not doneOnly or F.pieceDone(piece) then table.insert(ids, piece.id) end
    end
    return ids
end

-- Takes the piece with this id off the rack; returns it, or nil if it is gone.
function F.takePiece(rack, id)
    for index, piece in ipairs(rack.pieces or {}) do
        if piece.id == id then return table.remove(rack.pieces, index) end
    end
end

-- A done piece ages on the rack at vanilla's pace from the hour it finished.
local function addWaited(item, piece, now)
    item:setAge(item:getAge() + math.max((now or piece.doneHour) - piece.doneHour, 0) / 24 * FluidAgeing.foodRotSpeed())
end

-- What a piece taken off gives, as the stack's OnCreate did (F.onCreateDried): rotten, what was hung, rotten; dry
-- cured meat in the shade, Dry Cured (air dried); otherwise the method's output with the piece's food, look and the
-- spoiling its stack took off its keeping, aged since it finished. A piece taken before it is done comes off as it
-- was hung, aged since it went up.
function F.rackOutput(piece, now)
    local state, source = piece.state, F.keptItem(piece)
    if not F.pieceDone(piece) then
        piece.age = piece.age + math.max((now or piece.hour) - piece.hour, 0) / 24 * FluidAgeing.foodRotSpeed()
        return F.itemFromKept(piece)
    end
    local item
    if F.stackRotten(state) then
        item = F.rottenStage(source, state)
    elseif piece.method == "meat" and not F.inShed(state) and F.dryCuring(state) then
        item = F.smokedItem(source, state, F.COLD_FISH_OUT, F.DRY_CURED, true)
    else
        item = instanceItem(METHODS[piece.method].output)
        F.carry(source, item)
        local spoiled = state.spoiled or 0
        item:getModData().stackId, item:getModData().style = state.stackId, state.style
        item:setAge(spoiled >= 1 and item:getOffAgeMax() or item:getOffAge() * spoiled)
        if F.STAGES[item:getFullType()].matures then
            item:getModData().matureAge = item:getAge()
            F.rename(item)
        end
    end
    addWaited(item, piece, now)
    return item
end

-- Engine side

function F.rackOf(station)
    local modData = Station.movableData(station)
    modData[F.RACK_KEY] = modData[F.RACK_KEY] or {}
    return modData[F.RACK_KEY]
end

-- A rack's record brought up to now at the place it stands (Weather.placeOf), and that place.
function F.rackNow(station)
    local rack, place = F.rackOf(station), Weather.placeOf(station)
    F.updateRack(rack, place, F.getLedger(), getGameTime():getWorldAgeHours())
    return rack, place
end
