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

-- A done piece ages on the rack at vanilla's pace from the hour it finished; dry cured meat left hanging where it
-- dried also ages on faster, as a finished stack did (F.ageHanging: its stamp moved back by the extra days).
local function addWaited(item, piece, now)
    local days = math.max((now or piece.doneHour) - piece.doneHour, 0) / 24
    item:setAge(item:getAge() + days * FluidAgeing.foodRotSpeed())
    if days > 0 and F.ageDays(item) then
        local modData = item:getModData()
        modData.agedFrom = (modData.agedFrom or 0) - days * (1 / F.HANG_AGE_SHARE - 1)
        F.rename(item)
    end
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

-- What shows on the rack (ROADMAP section 12, item 7): a spot each total / spots kg, as many in use as the weight hung
-- fills. The spots in use are shared out by kind (salt fish, gutted fish, meat: the method), so a mixed rack shows
-- each kind: every kind gets one spot, the rest go one by one to the kind with the most weight a spot; a rack with more
-- kinds than spots (a Gantry's 2) shows its heaviest. Kinds stand in the order they were first hung; within a kind its
-- pieces fill its spots by weight in hang order, a piece in every spot its weight reaches into. A spot shows its
-- pieces' look at the least dry piece's stage, its first piece's style, rotten if any piece in it rotted. Returns a
-- spot's tile a spot (F.spotTile: 0 to SPOT_TILES - 1), nil for an empty spot.
local function rackKinds(rack)
    local kinds, byMethod, total = {}, {}, 0
    for _, piece in ipairs(rack.pieces or {}) do
        local kind = byMethod[piece.method]
        if not kind then
            kind = { pieces = {}, weight = 0, order = #kinds + 1 }
            byMethod[piece.method] = kind
            table.insert(kinds, kind)
        end
        table.insert(kind.pieces, piece)
        kind.weight, total = kind.weight + piece.weight, total + piece.weight
    end
    return kinds, total
end

-- Shares used spots among kinds: the heaviest kinds when there are more kinds than spots, one each, then the rest
-- one at a time to the kind with the most weight a spot (ties to the first hung). Kept in first-hung order.
local function shareSpots(kinds, used)
    if #kinds > used then
        table.sort(kinds, function(a, b)
            if a.weight ~= b.weight then return a.weight > b.weight end
            return a.order < b.order
        end)
        for i = #kinds, used + 1, -1 do table.remove(kinds, i) end
        table.sort(kinds, function(a, b) return a.order < b.order end)
    end
    for _, kind in ipairs(kinds) do kind.spots = 1 end
    for _ = #kinds + 1, used do
        local best
        for _, kind in ipairs(kinds) do
            if not best or kind.weight / kind.spots > best.weight / best.spots then best = kind end
        end
        best.spots = best.spots + 1
    end
    return kinds
end

function F.rackSpots(rack, hanger)
    local kinds, total = rackKinds(rack)
    if #kinds == 0 then return {} end
    local spotWeight = F.RACK_LIMITS[hanger.name].total / hanger.stacks
    local used = math.min(hanger.stacks, math.max(math.ceil(total / spotWeight - F.WEIGHT_SLACK), #kinds, 1))
    local bySpot, offset = {}, 0
    for _, kind in ipairs(shareSpots(kinds, used)) do
        local from = 0
        for _, piece in ipairs(kind.pieces) do
            local to = from + piece.weight
            local first = math.min(math.floor(from / kind.weight * kind.spots) + 1, kind.spots)
            local last = math.min(math.max(math.ceil(to / kind.weight * kind.spots - F.WEIGHT_SLACK), first), kind.spots)
            for spot = offset + first, offset + last do
                bySpot[spot] = bySpot[spot] or {}
                table.insert(bySpot[spot], piece)
            end
            from = to
        end
        offset = offset + kind.spots
    end
    local stages, looks = F.DRYING_STAGES, {}
    for spot = 1, hanger.stacks do
        local pieces = bySpot[spot]
        if pieces then
            local style, stage, rotten = pieces[1].state.style or F.STYLE_SALT, stages - 1, false
            for _, piece in ipairs(pieces) do
                local progress, lost = F.pieceProgress(piece)
                rotten = rotten or lost
                if not F.pieceDone(piece) then stage = math.min(stage, F.dryingStage(progress)) end
            end
            looks[spot] = F.spotTile(style, stage, rotten)
        end
    end
    return looks
end

-- Engine side

-- Whether an object is one of the three racks (not the tub, not the Smokehouse).
function F.isRack(isoObject)
    local hanger = F.hangerOf(isoObject)
    return hanger ~= nil and F.RACK_LIMITS[hanger.name] ~= nil
end

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
