-- Traditional Preservation (Fish & Meat): the Salting Tub (0.4.66; was a crafting station). One batch at a time,
-- fish or meat, never both: the first piece in decides. Pieces go in raw (Put in Tub): fish whole up to
-- MIN_SLICE_WEIGHT (a small fish keeps its guts, ripped out once it is dry), gutted, halved or as fillets; a whole fish
-- heavier than that is gutted first (Gut Fish), and one over SALT_WHOLE_MAX split. Meat as vanilla cuts it. Until the
-- batch starts everything comes back out (Unpack), aged as it would lying out. A start row salts the lot (each piece's
-- F.saltFor) and lays a board and a stone on it: Cure Fish, Corn the Meat (the short cure) or Country Cure (the long
-- one). The cure runs by the tub's place on the ledger's tubCure totals (F.pressDone), the warm and long cure spoil it
-- (F.cureSpoiled), and the cured pieces wait in the tub until taken out, the last of them giving the board and stone
-- back.
-- The batch sits in the tub's movableData, so it goes with a tub picked up. Required by TraditionalPreservationFishMeat.lua.
TraditionalPreservationFishMeat = TraditionalPreservationFishMeat or {}
local F = TraditionalPreservationFishMeat
local Station = require "TraditionalPreservationCore/Station"
local FluidAgeing = require "TraditionalPreservationCore/FluidAgeing"

F.TUB_KEY = "tpfmTub"         -- the tub's record in its movableData; never rename once the mod is out
F.TUB_BOARD = "Base.Plank"    -- the press: board and stone, both back with the last piece out
F.TUB_STONE = "Base.FlatStone"
F.TUB_SALT_XP = 3             -- Cooking, a piece salted (the old Pack in Salt recipes' award)

-- The start rows, in menu order: the kind of batch each takes, and the cured item it gives.
F.TUB_METHODS = { "fish", "corn", "long" }
F.TUB_METHOD = {
    fish = { kind = "fish", cured = F.PRESSED_FISH },
    corn = { kind = "meat", cured = F.CURED_MEAT },
    long = { kind = "meat", cured = F.CURED_MEAT, countryCure = true },
}

-- Empty, Packing, Curing or Done.
function F.tubStage(tub)
    return tub.stage or "Empty"
end

-- "fish", "meat", or nil for anything the tub doesn't take.
function F.tubKindOf(item)
    local fullType = item:getFullType()
    if F.isMeatCut(fullType) then return "meat" end
    if F.COLD_FISH[fullType] or item:hasTag(ItemTag.FISH_MEAT) then return "fish" end
    return nil
end

-- Why this item can't go in any tub, or nil: "NotForTub", "Spoilt" (rotten, frozen or cooked), "GutFirst",
-- "SplitFirst", "CharqueOff".
function F.tubItemRefusal(item)
    local kind = instanceof(item, "Food") and F.tubKindOf(item)
    if not kind then return "NotForTub" end
    if item:isRotten() or item:isFrozen() or item:isCooked() or item:isBurnt() then return "Spoilt" end
    if kind == "meat" and not F.CHARQUE_ON then return "CharqueOff" end
    if F.hasGuts(item) then return "GutFirst" end
    if F.tooBigToSaltWhole(item) then return "SplitFirst" end
    return nil
end

function F.tubCount(tub)
    return #(tub.pieces or {})
end

function F.tubWeight(tub)
    local weight = 0
    for _, piece in ipairs(tub.pieces or {}) do weight = weight + piece.tubWeight end
    return weight
end

-- Why a piece of this kind and weight can't go in this tub now, or nil: "Busy" (salted, or cured and not all out),
-- "Mixed", "Full".
function F.tubRefusal(tub, kind, weight)
    local stage = F.tubStage(tub)
    if stage ~= "Empty" and stage ~= "Packing" then return "Busy" end
    if tub.kind and tub.kind ~= kind then return "Mixed" end
    if F.tubCount(tub) >= F.TUB_MAX_ITEMS or not F.hasRoom(F.TUB_CAPACITY, F.tubWeight(tub), weight) then return "Full" end
    return nil
end

local FOOD_FIELDS = { "Calories", "Proteins", "Lipids", "Carbohydrates", "BaseHunger", "HungChange" }

-- A modData value, tables copied through.
local function copyValue(value)
    if type(value) ~= "table" then return value end
    local copy = {}
    for key, inner in pairs(value) do copy[key] = copyValue(inner) end
    return copy
end

-- An item as the tub keeps it: everything the cure (F.carry) and Unpack read off it, its weight in the tub (as it
-- weighed packed in salt: a vanilla fillet by its food, F.packedWeight), the weight that sets the cure's hours
-- (F.timingWeight's, packed), its salt (F.saltFor) and the hour it went in.
function F.tubPiece(item, hour)
    local piece = { fullType = item:getFullType(), age = item:getAge(), hour = hour, food = {},
        weight = item:getActualWeight(), customWeight = item:isCustomWeight(), name = item:getDisplayName(),
        modelIndex = item:getModelIndex(), uncut = item:hasTag(ItemTag.UNCUT_FISH), data = copyValue(item:getModData()),
        kind = F.tubKindOf(item), tubWeight = F.packedWeight(item), salt = F.saltFor(item),
        leg = F.isLeg(item), pork = F.PORK_INDICES[F.cutIndex(item) or -1] == true, hotOnly = F.isHotOnly(item) }
    for _, field in ipairs(FOOD_FIELDS) do piece.food[field] = item["get" .. field](item) end
    piece.timing = F.TIMING_WEIGHTS[F.cutIndex(item) or -1] or piece.tubWeight
    return piece
end

-- A kept piece standing in for the item it was, for F.carry and the rules that read an item.
function F.tubItem(piece)
    local stored = {}
    function stored:getFullType() return piece.fullType end
    function stored:getModData() return piece.data end
    function stored:getActualWeight() return piece.weight end
    function stored:isCustomWeight() return piece.customWeight end
    function stored:getDisplayName() return piece.name end
    function stored:getModelIndex() return piece.modelIndex end
    function stored:hasTag(tag) return tag == ItemTag.UNCUT_FISH and piece.uncut end
    function stored:getAge() return piece.age end
    for _, field in ipairs(FOOD_FIELDS) do
        stored["get" .. field] = function() return piece.food[field] end
    end
    return stored
end

function F.putInTub(tub, piece)
    tub.stage, tub.kind = "Packing", piece.kind
    tub.pieces = tub.pieces or {}
    table.insert(tub.pieces, piece)
end

-- A packed piece's age now: what it had, plus the days since it went in at vanilla's pace (Food Spoilage included),
-- so an unsalted tub is no cold store.
function F.tubPieceAge(piece, now)
    if not piece.hour or not now then return piece.age end
    return piece.age + math.max(now - piece.hour, 0) / 24 * FluidAgeing.foodRotSpeed()
end

local function clear(tub)
    for key in pairs(tub) do tub[key] = nil end
end

-- Everything packed comes back out, each piece with its age now, the tub empty again. Only before the start.
function F.unpackTub(tub, now)
    if F.tubStage(tub) ~= "Packing" then return {} end
    local back = {}
    for _, piece in ipairs(tub.pieces) do
        piece.age = F.tubPieceAge(piece, now)
        table.insert(back, piece)
    end
    clear(tub)
    return back
end

function F.tubSalt(tub)
    local salt = 0
    for _, piece in ipairs(tub.pieces or {}) do salt = salt + piece.salt end
    return salt
end

-- Why a start row can't start, or nil: "Busy", "Empty", "WrongKind", "LegNeedsLongCure", "HotOnlyShortCure",
-- "NoSalt", "NoBoard", "NoStone". have: what the player has in reach { salt = uses, board, stone = true/false }.
function F.startRefusal(tub, method, have)
    local stage = F.tubStage(tub)
    if stage == "Empty" then return "Empty" end
    if stage ~= "Packing" then return "Busy" end
    if F.TUB_METHOD[method].kind ~= tub.kind then return "WrongKind" end
    for _, piece in ipairs(tub.pieces) do
        if method == "corn" and piece.leg then return "LegNeedsLongCure" end
        if method == "long" and piece.hotOnly then return "HotOnlyShortCure" end
    end
    if (have.salt or 0) < F.tubSalt(tub) then return "NoSalt" end
    if not have.board then return "NoBoard" end
    if not have.stone then return "NoStone" end
    return nil
end

-- Hours a batch takes at full speed: the heaviest piece's (F.pressHours, F.meatPressHours), the long cure's own.
function F.tubHours(tub, method)
    local heaviest, leg = 0, false
    for _, piece in ipairs(tub.pieces) do
        heaviest = math.max(heaviest, piece.timing)
        leg = leg or piece.leg
    end
    if F.TUB_METHOD[method].countryCure then return F.longCureHours(leg) end
    return tub.kind == "meat" and F.meatPressHours(heaviest) or F.pressHours(heaviest)
end

-- Salts and weighs down a packed tub: the cure starts, marked on the ledger at the tub's place. The pieces' ages
-- stay behind: a cured piece starts fresh (less what a warm cure takes), as it always has.
function F.startTub(tub, method, ledger)
    tub.stage, tub.method = "Curing", method
    tub.pressHours = F.tubHours(tub, method)
    tub.countryCure = F.TUB_METHOD[method].countryCure == true
    tub.tubDone = 0
    F.markTub(tub, ledger)
end

-- Brings a curing tub up to now at its place (tub.place, the World's last look): hours of cure since the last look,
-- and once done, what a warm or long cure took from the batch's keeping.
function F.updateTub(tub, ledger, now)
    if F.tubStage(tub) ~= "Curing" then return end
    tub.tubDone = F.pressDone(tub, ledger)
    F.mark(tub, ledger, { "tubCure" })
    if tub.tubDone >= tub.pressHours then
        tub.stage, tub.doneHour = "Done", now
        tub.spoiled = F.cureSpoiled(tub, ledger)
    end
end

-- Takes one cured piece out of a done tub: { piece, method, spoiled, doneHour, last }, or nil. The last one empties it.
function F.takeFromTub(tub)
    if F.tubStage(tub) ~= "Done" or F.tubCount(tub) == 0 then return nil end
    local taken = { piece = table.remove(tub.pieces, 1), method = tub.method, spoiled = tub.spoiled or 0, doneHour = tub.doneHour }
    if F.tubCount(tub) == 0 then
        taken.last = true
        clear(tub)
    end
    return taken
end

-- Engine side

function F.tubOf(station)
    local modData = Station.movableData(station)
    modData[F.TUB_KEY] = modData[F.TUB_KEY] or {}
    return modData[F.TUB_KEY]
end

-- The raw piece Unpack gives back, as it went in and aged since.
function F.itemFromTub(piece)
    local item = instanceItem(piece.fullType)
    for _, field in ipairs(FOOD_FIELDS) do item["set" .. field](item, piece.food[field]) end
    item:setActualWeight(piece.weight)
    item:setCustomWeight(piece.customWeight == true)
    if piece.name ~= item:getDisplayName() then
        item:setName(piece.name)
        item:setCustomName(true)
    end
    local modData = item:getModData()
    for key, value in pairs(piece.data or {}) do modData[key] = copyValue(value) end
    if piece.modelIndex and piece.modelIndex >= 0 then item:setModelIndex(piece.modelIndex) end
    item:setAge(piece.age)
    return item
end

-- A taken piece, cured: Salt Cured fish, or Corned or Country Cured meat, with its food and name from what went in
-- (F.carry), a light brine's days for poultry and rabbit, the warm cure's share off its keeping, and the days it has
-- waited in the tub since the cure ended, at vanilla's pace.
function F.curedFromTub(taken, now)
    local method = F.TUB_METHOD[taken.method]
    local cured = instanceItem(method.cured)
    F.carry(F.tubItem(taken.piece), cured)
    if cured:getFullType() == F.CURED_MEAT and F.isHotOnly(cured) then
        cured:setOffAge(F.HOT_ONLY_DAYS[1])
        cured:setOffAgeMax(F.HOT_ONLY_DAYS[2])
    end
    local spoiled = taken.spoiled
    local age = 0
    if spoiled > 0 then
        cured:getModData().cureSpoiled = spoiled
        age = spoiled >= 1 and cured:getOffAgeMax() or cured:getOffAge() * spoiled
    end
    if method.countryCure then
        cured:getModData().longCure = true
        F.rename(cured)
    end
    local waited = taken.doneHour and now and math.max(now - taken.doneHour, 0) / 24 * FluidAgeing.foodRotSpeed() or 0
    cured:setAge(age + waited)
    return cured
end
