-- Checks the racks' record (TraditionalPreservationFishMeatRack.lua) outside the game: what a rack takes, and that a
-- piece hung on its own dries, spoils and comes off as a one-piece stack did on the old recipe, through the same
-- weather. Run from the mod folder: luajit tests/test_rack.lua
local H = dofile((os.getenv("TPCORE") or "../TraditionalPreservationCore") .. "/tests/harness.lua")
H.useModPaths()
local check = H.check
local hours = 100
ModData = { tables = {} }
function ModData.getOrCreate(key)
    ModData.tables[key] = ModData.tables[key] or {}
    return ModData.tables[key]
end
function getGameTime()
    return { getWorldAgeHours = function() return hours end }
end
function ZombRandFloat(low, high) return (low + high) / 2 end
function ZombRand() return 0 end
ItemTag = { UNCUT_FISH = "uncut", SALT = "salt", FISH_MEAT = "fishmeat" }
H.installGetText()
function getItemNameFromFullType(fullType) return (fullType:gsub("^[^.]*%.", "")) end
Events = { OnInitGlobalModData = { Add = function() end } }
ScriptManager = { instance = { getCraftRecipe = function() return { Load = function() end } end } }
dofile("42/media/lua/shared/TraditionalPreservationFishMeat.lua")
dofile("42/media/lua/shared/TraditionalPreservationFishMeatSmokehouse.lua")
local T = TraditionalPreservationFishMeat

local function near(a, b) return math.abs(a - b) < 1e-6 end

local newFood = dofile("tests/standins/food.lua")
function instanceItem(fullType) return newFood(fullType) end

-- The old way: a stack of one on a recipe, for the same weather.
local function newRecipeData(fish)
    local craftRecipeData = { modData = {}, elapsed = 0 }
    function craftRecipeData:getModData() return self.modData end
    function craftRecipeData:setElapsedTime(elapsed) self.elapsed = elapsed end
    function craftRecipeData:getRecipe() return { getTime = function() return 1 end } end
    function craftRecipeData:getAllInputItemsWithFlag() return H.list(fish) end
    function craftRecipeData:getAllCreatedItems() return H.list({}) end
    return craftRecipeData
end

local FRAME, BEAM, GANTRY = T.HANGERS[6], T.HANGERS[408], T.HANGERS[410]
check("the racks are named for their limits", FRAME.name == "frame" and BEAM.name == "medium" and GANTRY.name == "large"
    and T.CHAMBER_HANGER.name == "chamber")

local PRESSED, GUTTED, MEAT = T.PRESSED_FISH, T.GUTTED_FISH, T.CURED_MEAT
local function fish(fullType, weight) return newFood(fullType, { ActualWeight = weight, Calories = 100 * weight }) end

-- What a rack takes.
local rack = {}
local R = T.REFUSALS
check("a frame takes a salt fish", T.rackRefusal(rack, FRAME, "Open", fish(PRESSED, 2.5)) == nil)
check("but none over 2.5 kg", T.rackRefusal(rack, FRAME, "Open", fish(PRESSED, 2.6)) == R.tooHeavy)
check("the Beam takes up to 5", T.rackRefusal(rack, BEAM, "Open", fish(PRESSED, 5)) == nil
    and T.rackRefusal(rack, BEAM, "Open", fish(PRESSED, 5.1)) == R.tooHeavy)
check("the Gantry up to 12", T.rackRefusal(rack, GANTRY, "Open", fish(PRESSED, 12)) == nil
    and T.rackRefusal(rack, GANTRY, "Open", fish(PRESSED, 12.1)) == R.tooHeavy)
check("raw fish isn't hung", T.rackRefusal(rack, FRAME, "Open", fish("Base.Bluegill", 0.5)) == R.needsPressed)
check("gutted fish wants moving air", T.rackRefusal(rack, FRAME, "Open", fish(GUTTED, 1)) == nil
    and T.rackRefusal(rack, FRAME, "Basement", fish(GUTTED, 1)) == R.noColdIndoors)
local country = newFood(MEAT, { ActualWeight = 1 }, 1)
country:getModData().longCure = true
check("Country Cured meat stays out of the open", T.rackRefusal(rack, FRAME, "Open", country) == R.countryCuredSmokehouse
    and T.rackRefusal(rack, FRAME, "Covered", country) == nil)
check("corned pork is the Smokehouse's", T.rackRefusal(rack, FRAME, "Open", newFood(MEAT, { ActualWeight = 1 }, 4)) == R.porkSmokehouse)
check("blood sausage is the Smokehouse's", T.rackRefusal(rack, FRAME, "Open", newFood(T.BLOOD_SAUSAGE, { ActualWeight = 0.2 })) == R.sausageSmokehouse)

local ledger = T.getLedger()
for _ = 1, 8 do T.hangPiece(rack, fish(PRESSED, 2.5), "Open", ledger, hours) end
check("a frame holds 20 kg", T.rackCount(rack) == 8 and near(T.rackWeight(rack), 20)
    and T.rackRefusal(rack, FRAME, "Open", fish(PRESSED, 0.1)) == R.frameFull)
local gantry = {}
for _ = 1, 12 do T.hangPiece(gantry, fish(PRESSED, 0.1), "Open", ledger, hours) end
check("a Gantry holds 12 pieces, however light", T.rackRefusal(gantry, GANTRY, "Open", fish(PRESSED, 0.1)) == R.frameFull)

-- A piece dries as a stack of one did, through the same weather and places.
local MILD = { temperature = 20, humidity = 0.4, precipitation = 0 }
local RAINY = { temperature = 12, humidity = 0.9, precipitation = 1 }
local HOT = { temperature = 30, humidity = 0.6, precipitation = 0 }

-- steps: { hours, weather, place }. Returns the stack's modData and the piece.
local function sideBySide(item, starts, updates, steps)
    local stackItem = newFood(item.fullType, { ActualWeight = item.values.ActualWeight }, item.modelIndex)
    for key, value in pairs(item:getModData()) do stackItem:getModData()[key] = value end
    local stack = newRecipeData({ stackItem })
    starts(stack)
    local onRack = {}
    local piece = T.hangPiece(onRack, item, "Open", ledger, hours)
    for _, step in ipairs(steps) do
        hours = hours + step[1]
        T.advance(ledger, hours, step[2])
        stack.modData.place = step[3]
        updates(stack)
        T.updateRack(onRack, step[3], ledger, hours)
    end
    return stack.modData, piece, onRack
end

local function same(stack, piece)
    local state = piece.state
    return near(stack.dried, state.dried) and near(stack.spoiled or 0, state.spoiled or 0)
        and near(stack.underSpoiled or 0, state.underSpoiled or 0)
end

local WEEK = { { 24, MILD, "Open" }, { 12, RAINY, "Open" }, { 30, HOT, "Open" }, { 48, MILD, "Covered" },
    { 24, MILD, "Sheltered" }, { 40, HOT, "AiredRoom" }, { 20, RAINY, "Covered" } }

local stack, piece = sideBySide(fish(PRESSED, 1.2), T.onDryStart, T.onDryUpdate, WEEK)
check("salt fish: dried and spoiled as a stack", same(stack, piece) and stack.dried > 0 and not T.pieceDone(piece))
check("its share done is the stack's", near(T.pieceProgress(piece), T.stackProgress(stack, T.DRY_HOURS)))

stack, piece = sideBySide(fish(GUTTED, 1.5), T.onColdDryStart, T.onColdDryUpdate,
    { { 48, { temperature = 3, humidity = 0.5, precipitation = 0 }, "Open" }, { 24, { temperature = -8, humidity = 0.5, precipitation = 0 }, "Open" },
      { 24, { temperature = 4, humidity = 0.8, precipitation = 1 }, "Open" }, { 30, { temperature = 12, humidity = 0.5, precipitation = 0 }, "Covered" } })
check("cold fish: dried and spoiled as a stack", same(stack, piece) and stack.dried > 0 and stack.spoiled > 0)

stack, piece = sideBySide(newFood(MEAT, { ActualWeight = 0.4 }, 1), T.onCharqueStart, T.onCharqueUpdate, WEEK)
check("charque: dried and spoiled as a stack", same(stack, piece) and stack.dried > 0)
local cured = newFood(MEAT, { ActualWeight = 0.8 }, 0)
cured:getModData().longCure = true
stack, piece = sideBySide(cured, T.onCharqueStart, T.onCharqueUpdate, { { 100, MILD, "Covered" }, { 200, { temperature = 8, humidity = 0.5, precipitation = 0 }, "Covered" } })
check("Country Cured in the shade dry cures as a stack", same(stack, piece) and T.dryCuring(piece.state)
    and piece.state.cureNeed == stack.cureNeed and stack.dried > 0)

-- Done, and what comes off.
local salt = {}
local hung = fish(PRESSED, 1)
hung.values.Calories = 300
local saltPiece = T.hangPiece(salt, hung, "Open", ledger, hours)
local early = T.rackOutput(saltPiece, hours + 24)
check("taken early, a piece comes off as hung, aged since", early.fullType == PRESSED and near(early:getAge(), 1))
hours = hours + T.DRY_HOURS + 10
T.advance(ledger, hours, MILD)
T.updateRack(salt, "Open", ledger, hours)
check("in good weather it is done in its hours, and stops there", T.pieceDone(saltPiece) and saltPiece.doneHour == hours
    and near(T.pieceProgress(saltPiece), 1))
local dried = saltPiece.state.dried
hours = hours + 48
T.advance(ledger, hours, MILD)
T.updateRack(salt, "Open", ledger, hours)
check("a done piece dries no further", saltPiece.state.dried == dried)
check("it is listed done", #T.pieceIds(salt, true) == 1 and T.pieceIds(salt, true)[1] == saltPiece.id)
local out = T.rackOutput(saltPiece, hours)
check("it comes off Salt Dried, with its food", out.fullType == T.SALT_DRIED and out:getCalories() > 0
    and out:getModData().style == saltPiece.state.style)
check("aged on the rack since it finished, at vanilla's pace", near(out:getAge(), (saltPiece.state.spoiled or 0) * 120 + 2))

local rotten = {}
local rotPiece = T.hangPiece(rotten, fish(PRESSED, 1), "Open", ledger, hours)
rotPiece.state.spoiled = 1
T.updateRack(rotten, "Open", ledger, hours)
local lost = T.rackOutput(rotPiece, hours)
check("a rotted piece is done, and comes off as what was hung, rotten", T.pieceDone(rotPiece) and lost.fullType == PRESSED
    and lost:getAge() == 180)

local shade = {}
local ham = newFood(MEAT, { ActualWeight = 0.8 }, 0)
ham:getModData().longCure = true
local hamPiece = T.hangPiece(shade, ham, "Covered", ledger, hours)
hamPiece.state.dried = hamPiece.state.cureNeed
T.updateRack(shade, "Covered", ledger, hours)
local dryCured = T.rackOutput(hamPiece, hours)
check("Country Cured meat dried in the shade comes off Dry Cured, air dried", T.pieceDone(hamPiece)
    and dryCured.fullType == T.DRY_CURED and dryCured:getModData().airDried == true)

-- Taking pieces off, by id.
local three = {}
for i = 1, 3 do T.hangPiece(three, fish(PRESSED, i * 0.5), "Open", ledger, hours) end
local ids = T.pieceIds(three)
check("each piece has its own id, in hang order", #ids == 3 and ids[1] < ids[2] and ids[2] < ids[3])
local third = T.takePiece(three, ids[3])
check("a piece comes off by its id, the rest stay in order", third and math.abs(third.weight - 1.5) < 1e-6
    and T.rackCount(three) == 2 and three.pieces[1].id == ids[1] and three.pieces[2].id == ids[2])
check("asking again for a piece taken gives nothing", T.takePiece(three, ids[3]) == nil and T.rackCount(three) == 2)
T.hangPiece(three, fish(PRESSED, 0.2), "Open", ledger, hours)
check("a new piece never reuses an id", three.pieces[3].id > ids[3])
three.pieces[1].id, three.pieces[1].doneHour = nil, hours
T.updateRack(three, "Open", ledger, hours)
check("a piece hung without an id gets a new one at the next look, and is listed done", three.pieces[1].id > three.pieces[3].id
    and #T.pieceIds(three, true) == 1 and T.pieceIds(three, true)[1] == three.pieces[1].id)

H.done()
