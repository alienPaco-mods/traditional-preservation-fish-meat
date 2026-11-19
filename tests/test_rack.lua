-- Checks the racks' record (TraditionalPreservationFishMeatRack.lua) outside the game: what a rack takes, and that a
-- piece hung on its own dries, spoils and comes off as a one-piece stack did on the old recipe, through the same
-- weather (the stack's figures, fixed here). Run from the mod folder: luajit tests/test_rack.lua
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
H.installEvents()
ScriptManager = { instance = { getCraftRecipe = function() return { Load = function() end } end } }
dofile("42/media/lua/shared/TraditionalPreservationFishMeat.lua")
dofile("42/media/lua/shared/TraditionalPreservationFishMeatSmokehouse.lua")
-- The sausages' code (the Smokehouse's links), without vanilla's animal tables.
AnimalDefinitions, AnimalPartsDefinitions = { animals = {} }, { animals = {} }
for _, name in ipairs({ "Cow", "Pig", "Sheep", "Deer", "AnimalParts" }) do package.loaded["Definitions/animal/" .. name .. "Definitions"] = true end
dofile("42/media/lua/shared/TraditionalPreservationFishMeatBlood.lua")
dofile("42/media/lua/shared/TraditionalPreservationFishMeatSausage.lua")
local T = TraditionalPreservationFishMeat

local function near(a, b) return math.abs(a - b) < 1e-6 end

local newFood = dofile("tests/standins/food.lua")
function instanceItem(fullType) return newFood(fullType) end

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

-- steps: { hours, weather, place }. Returns the piece and its rack.
local function hungThrough(item, steps)
    local onRack = {}
    local piece = T.hangPiece(onRack, item, "Open", ledger, hours)
    for _, step in ipairs(steps) do
        hours = hours + step[1]
        T.advance(ledger, hours, step[2])
        T.updateRack(onRack, step[3], ledger, hours)
    end
    return piece, onRack
end

-- The piece's state against the figures a one-piece stack on the old recipe gave through the same weather (the two
-- were checked side by side until the stacks went, Smokehouse S4): dried, spoiled, under-salted, its bar.
local function gave(piece, dried, spoiled, under, progress)
    local state = piece.state
    return near(state.dried, dried) and near(state.spoiled or 0, spoiled) and near(state.underSpoiled or 0, under)
        and near(T.pieceProgress(piece), progress)
end

local WEEK = { { 24, MILD, "Open" }, { 12, RAINY, "Open" }, { 30, HOT, "Open" }, { 48, MILD, "Covered" },
    { 24, MILD, "Sheltered" }, { 40, HOT, "AiredRoom" }, { 20, RAINY, "Covered" } }

local piece = hungThrough(fish(PRESSED, 1.2), WEEK)
check("salt fish: dried and spoiled as a stack did", gave(piece, 142.4888889, 0.1072916667, 0, 0.4947530864) and not T.pieceDone(piece))
piece = hungThrough(fish(GUTTED, 1.5),
    { { 48, { temperature = 3, humidity = 0.5, precipitation = 0 }, "Open" }, { 24, { temperature = -8, humidity = 0.5, precipitation = 0 }, "Open" },
      { 24, { temperature = 4, humidity = 0.8, precipitation = 1 }, "Open" }, { 30, { temperature = 12, humidity = 0.5, precipitation = 0 }, "Covered" } })
check("cold fish: dried and spoiled as a stack did", gave(piece, 62.4, 0.6872949219, 0, 0.08125))
piece = hungThrough(newFood(MEAT, { ActualWeight = 0.4 }, 1), WEEK)
check("charque: dried, and under-salted in the room, as a stack did", gave(piece, 120.544, 0, 0.2113703637, 1) and piece.state.cureNeed == 490)
local cured = newFood(MEAT, { ActualWeight = 0.8 }, 0)
cured:getModData().longCure = true
piece = hungThrough(cured, { { 100, MILD, "Covered" }, { 200, { temperature = 8, humidity = 0.5, precipitation = 0 }, "Covered" } })
check("Country Cured in the shade dry cures as a stack did", gave(piece, 233.3333333, 0, 0, 0.3875968992) and T.dryCuring(piece.state)
    and piece.state.cureNeed == 602)

-- Done, and what comes off.
local salt = {}
local hung = fish(PRESSED, 1)
hung.values.Calories = 300
local saltPiece = T.hangPiece(salt, hung, "Open", ledger, hours)
local early = T.rackOutput(saltPiece, hours + 24)
check("taken early, a piece comes off as hung, the hours on the rack not ageing it", early.fullType == PRESSED and early:getAge() == 0)
saltPiece.state.spoiled = 0.25
check("what the hanging spoiled comes off its keeping", near(T.rackOutput(saltPiece, hours + 24):getAge(), 120 * 0.25))
saltPiece.data.cureSpoiled = 0.1
check("but not what the tub had already taken", near(T.rackOutput(saltPiece, hours + 24):getAge(), 120 * 0.15))
saltPiece.state.spoiled, saltPiece.data.cureSpoiled = 1.2, nil
check("all its keeping gone, it comes off rotten", T.rackOutput(saltPiece, hours + 24):getAge() == 180)
saltPiece.state.spoiled = 0
-- Stalled hours age it: a rack is no cold store (user, session 53).
local shutRack = {}
local shut = T.hangPiece(shutRack, fish(PRESSED, 1), "Sheltered", ledger, hours)
local drying = T.hangPiece(shutRack, fish(PRESSED, 1), "Sheltered", ledger, hours)
hours = hours + 48
T.advance(ledger, hours, MILD)
T.updateRack(shutRack, "Sheltered", ledger, hours)
check("in a shut room a piece doesn't dry, and counts the hours as stalled", shut.state.dried == 0 and shut.stalled == 48)
check("taken off, it has aged those days at the normal pace", near(T.rackOutput(shut, hours):getAge(), 2))
check("and asking twice ages it once", near(T.rackOutput(shut, hours):getAge(), 2))
local openRack = {}
local dryingPiece = T.hangPiece(openRack, fish(PRESSED, 1), "Open", ledger, hours)
hours = hours + 48
T.advance(ledger, hours, MILD)
T.updateRack(openRack, "Open", ledger, hours)
check("one drying in the open counts nothing stalled, and comes off unaged", dryingPiece.state.dried > 0
    and (dryingPiece.stalled or 0) == 0 and T.rackOutput(dryingPiece, hours):getAge() == 0)
T.updateRack(openRack, "Open", ledger, hours)
check("a second look at the same hour adds nothing", (dryingPiece.stalled or 0) == 0)
local cornedPiece = T.hangPiece({}, newFood(MEAT, { ActualWeight = 0.4 }, 1), "Sheltered", ledger, hours)
cornedPiece.state.underSpoiled = 0.5
check("a Corned piece's under-salting counts too", near(T.rackOutput(cornedPiece, hours):getAge(), 120 * 0.5))
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
local hungOn = T.rackOutput(hamPiece, hours + 67.5 * 24)
check("left hanging where it dried it ages on faster: 67.5 days add 22.5 to its ageing", near(dryCured:getModData().agedFrom, 0)
    and near(hungOn:getModData().agedFrom, -22.5))

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

-- The Smokehouse (S1): its pieces count the joined fire on their own, and come off as its stacks did.
local Fire = require "TraditionalPreservationCore/Fire"
local SHED = require("TraditionalPreservationCore/Smokehouse").PLACE
local COOL = { temperature = 8, humidity = 0.4, precipitation = 0 }
local chamber, shedFire = {}, {}
local CHAMBER = T.CHAMBER_HANGER
check("the Smokehouse takes 90 kg, 150 pieces, 12 kg at most, and sausages", T.rackRefusal({}, CHAMBER, SHED, fish(PRESSED, 12)) == nil
    and T.rackRefusal({}, CHAMBER, SHED, fish(PRESSED, 12.1)) == R.tooHeavy
    and T.rackRefusal({}, CHAMBER, SHED, newFood(T.FRESH_SAUSAGE, { ActualWeight = 0.2 })) == nil
    and T.rackRefusal({}, CHAMBER, SHED, fish(GUTTED, 1)) == R.noColdIndoors)
Fire.logFire(shedFire, hours, nil, nil)
local hot = T.hangPiece(chamber, fish(PRESSED, 1), SHED, ledger, hours)
T.updateRack(chamber, SHED, ledger, hours, shedFire)
Fire.logFire(shedFire, hours + 0.5, Fire.STOKED, hours + 30)
Fire.logFire(shedFire, hours + 8, Fire.STOKED, hours + 30)
hours = hours + 8
T.advance(ledger, hours, MILD)
T.updateRack(chamber, SHED, ledger, hours, shedFire)
check("a stoked run long enough cooks a salt fish: done, Hot Smoked", T.pieceDone(hot) and hot.state.cooked
    and T.rackOutput(hot, hours).fullType == T.HOT_FISH)
check("a rack's piece never counts a fire", not T.pieceDone(T.hangPiece({}, fish(PRESSED, 1), "Open", ledger, hours)))

local smokehouse, banked = {}, {}
Fire.logFire(banked, hours, nil, nil)
local link = newFood(T.BLOOD_SAUSAGE, { ActualWeight = 0.2 })
link.cooked = true
local sausage = T.hangPiece(smokehouse, link, SHED, ledger, hours)
local beef = newFood(MEAT, { ActualWeight = 0.4 }, 0)
beef:getModData().longCure = true
local cured = T.hangPiece(smokehouse, beef, SHED, ledger, hours)
T.updateRack(smokehouse, SHED, ledger, hours, banked)
check("a sausage piece takes the sausages' counters", sausage.state.sausage == true and sausage.state.smokeNeed == T.SMOKED_SAUSAGE_HOURS
    and T.pieceProgress(sausage) == 0)
for _ = 1, 10 do
    Fire.logFire(banked, hours + 0.5, Fire.BANKED, hours + 200)
    hours = hours + 12
    Fire.logFire(banked, hours, Fire.BANKED, hours + 200)
    T.advance(ledger, hours, COOL)
    T.updateRack(smokehouse, SHED, ledger, hours, banked)
end
check("banked on cool days, the blood sausage has its smoke and is done", T.pieceDone(sausage) and sausage.state.smokedAt ~= nil)
check("it comes off Smoked Blood Sausage", T.rackOutput(sausage, hours).fullType == T.SMOKED_BLOOD_SAUSAGE)
check("the Country Cured beef counts its own smoke", (cured.state.coldSmokeHours or 0) > 0 and not T.pieceDone(cured))
cured.state.dried = cured.state.cureNeed
T.updateRack(smokehouse, SHED, ledger, hours, banked)
check("dried with its smoke: Beef (Cold Smoked), not Charque", T.pieceDone(cured) and T.coldDone(cured.state)
    and T.rackOutput(cured, hours).fullType == T.DRY_CURED and T.rackOutput(cured, hours):getModData().airDried == nil)
local airDried = T.hangPiece({}, beef, SHED, ledger, hours)
airDried.state.dried, airDried.doneHour = airDried.state.cureNeed, hours
check("short of its smoke it comes off air dried", T.rackOutput(airDried, hours):getModData().airDried == true)
check("the Take Done icon's kind: Hot Smoked, Smoked Blood Sausage, Dry Cured; Salt Dried on a frame",
    T.pieceOutputType(hot) == T.HOT_FISH and T.pieceOutputType(sausage) == T.SMOKED_BLOOD_SAUSAGE
    and T.pieceOutputType(cured) == T.DRY_CURED and T.pieceOutputType(T.hangPiece({}, fish(PRESSED, 1), "Open", ledger, hours)) == T.SALT_DRIED)
local stale = T.hangPiece({}, link, SHED, ledger, hours)
stale.state.staleAt = hours
check("a link gone stale before its smoke shows as itself", T.pieceOutputType(stale) == T.BLOOD_SAUSAGE)
check("the Smokehouse is no rack for the World yet (S4)", T.CHAMBER_HANGER.closed and T.RACK_LIMITS.chamber ~= nil)

H.done()
