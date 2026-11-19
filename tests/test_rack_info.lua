-- Checks Rack Info's view outside the game (TraditionalPreservationFishMeatRackUI.lua): the place rows and what the
-- rack holds, a list row for each piece with its process, done and rotten pieces, the notes, and the popup's lines.
-- Run from the mod folder: luajit tests/test_rack_info.lua
local H = dofile((os.getenv("TPCORE") or "../TraditionalPreservationCore") .. "/tests/harness.lua")
local check = H.check
H.useModPaths()
H.installClock(1000)
H.installModData()
H.installEvents()
H.installGetText()

local realRequire = require
require = function(name)
    if name:find("^TraditionalPreservation") then return realRequire(name) end
end
H.installMenus()
ISPanel = H.class("ISPanel")
ISCollapsableWindow = H.class("ISCollapsableWindow")
ISWidgetCraftLogicOutputProgress = { createDynamicChildren = function() end, calculateLayout = function() end }
ItemTag = ItemTag or {}
ItemTag.UNCUT_FISH, ItemTag.SALT, ItemTag.FISH_MEAT = "uncut", "salt", "fishmeat"
function ZombRand() return 0 end
function getItemNameFromFullType(fullType) return (fullType:gsub("^[^.]*%.", "")) end

local newFood = dofile("tests/standins/food.lua")
function instanceItem(fullType) return newFood(fullType) end

dofile("42/media/lua/shared/TraditionalPreservationFishMeat.lua")
dofile("42/media/lua/shared/TraditionalPreservationFishMeatSmokehouse.lua")
-- The sausages' code (the Smokehouse's links), without vanilla's animal tables.
AnimalDefinitions, AnimalPartsDefinitions = { animals = {} }, { animals = {} }
for _, name in ipairs({ "Cow", "Pig", "Sheep", "Deer", "AnimalParts" }) do package.loaded["Definitions/animal/" .. name .. "Definitions"] = true end
dofile("42/media/lua/shared/TraditionalPreservationFishMeatBlood.lua")
dofile("42/media/lua/shared/TraditionalPreservationFishMeatSausage.lua")
dofile("42/media/lua/client/TraditionalPreservationFishMeatRackUI.lua")
local F, RackUI = TraditionalPreservationFishMeat, TraditionalPreservationFishMeatRackUI
local KEY = "IGUI_TraditionalPreservationFishMeat_"

local function valueOf(shown, label)
    for _, row in ipairs(shown.rows) do
        if row[1] == KEY .. label then return row[2] end
    end
end
local function hasNote(shown, text)
    for _, note in ipairs(shown.notes) do
        if note:find(text, 1, true) then return true end
    end
    return false
end

-- A frame in the open on a dry summer day.
local frame = F.HANGERS[6]
local ledger = F.getLedger()
ledger.temperature, ledger.seasonTemperature, ledger.wind, ledger.wetness = 22, 19, 0.3, 0
ledger.openRate, ledger.coldRate = 1, 1
local rack = {}
local function fish(fullType, weight, name)
    local item = newFood(fullType, { ActualWeight = weight, Calories = 100 })
    item.name = name
    return item
end
local salt = F.hangPiece(rack, fish(F.PRESSED_FISH, 1.5, "Walleye (Salt Cured)"), "Open", ledger, 1000)
local cold = F.hangPiece(rack, fish(F.GUTTED_FISH, 1, "Walleye (Gutted)"), "Open", ledger, 1000)
local done = F.hangPiece(rack, fish(F.PRESSED_FISH, 0.5, "Bluegill (Salt Cured)"), "Open", ledger, 1000)
salt.state.dried = F.DRY_HOURS * 0.6
done.doneHour, done.state.dried = 1000, F.DRY_HOURS

local shown = RackUI.view(rack, frame, "Open", ledger, 1000)
check("the place rows come first, with what it holds", shown.rows[1][1] == KEY .. "Place" and valueOf(shown, "Place") == "Open air"
    and valueOf(shown, "InfoHolds") == "3 of 200 pieces, 3.0 of 20 kg, up to 2.5 kg each")
check("air, wind and wetness in the open", valueOf(shown, "InfoAir") ~= nil and valueOf(shown, "Wind") ~= nil
    and valueOf(shown, "InfoWetness") == "0%")
check("a row a piece, by its name, with its icon", #shown.pieces == 3 and shown.pieces[1].name == "Walleye (Salt Cured)"
    and shown.pieces[1].icon == "icon:" .. F.PRESSED_FISH)
check("its share and its process", math.abs(shown.pieces[1].share - 0.6) < 1e-6 and shown.pieces[1].group == "Salt fish"
    and shown.pieces[2].group == "Stockfish")
check("a running piece's bar says its time left", shown.pieces[1].text:find("left", 1, true) ~= nil)
check("a done piece reads Done, full", shown.pieces[3].text == "Done" and shown.pieces[3].share == 1)
check("the done note, and the weather's", hasNote(shown, "1 done") and hasNote(shown, "weather holds"))
check("the window's take lists: done ids and every id, and why Take Done waits", #shown.doneIds == 1 and shown.doneIds[1] == done.id
    and #shown.allIds == 3 and type(shown.waitText) == "string")
check("an empty rack's wait says nothing hangs", RackUI.view({}, frame, "Open", ledger, 1000).waitText == "Nothing hangs on it.")
check("every row has a popup", type(shown.pieces[1].popup) == "function" and type(shown.pieces[3].popup) == "function")

local rotten = F.hangPiece(rack, fish(F.PRESSED_FISH, 0.5, "Perch (Salt Cured)"), "Open", ledger, 1000)
rotten.state.spoiled, rotten.doneHour = 1, 1000
local row = RackUI.pieceRow(rotten, ledger, 1000)
check("a rotted piece reads Rotten", row.text == "Rotten" and row.share == 1)

local basement = RackUI.view({}, F.HANGERS[410], "Basement", ledger, 1000)
check("an empty Gantry in a basement: its own limits, no wind, the empty note", valueOf(basement, "InfoHolds") == "0 of 12 pieces, 0.0 of 100 kg, up to 12 kg each"
    and valueOf(basement, "Wind") == nil and valueOf(basement, "InfoWetness") == nil and hasNote(basement, "Nothing in it"))

-- The popup: method, what it comes out as, time left, and a spoilage warning when there is one.
local lines = {}
local layout = { addItem = function()
    local line = {}
    table.insert(lines, line)
    return { setLabel = function(_, text) line.label = text end, setValue = function(_, text) line.value = text end }
end, render = function() return 10 end }
local tooltip = { getFont = function() end, DrawText = function() end, adjustWidth = function() end, getLineSpacing = function() return 10 end,
    beginLayout = function() return layout end, endLayout = function() end, setHeight = function() end, setWidth = function() end,
    getWidth = function() return 100 end }
shown.pieces[1].popup(tooltip)
check("the popup says method, outcome and time left", #lines >= 3 and lines[1].value == "Salt drying"
    and lines[2].value == "SaltDriedFish" and lines[3].value:find("if the weather holds", 1, true) ~= nil)
lines = {}
shown.pieces[3].popup(tooltip)
check("a done piece's popup says Done", lines[3].value == "Done")

-- The menu's Hang rows: a row a kind by name, lightest first so the most fit, refusals with their reason.
local named = fish
local carried = { named(F.PRESSED_FISH, 0.5, "Bluegill (Salt Cured)"), named(F.PRESSED_FISH, 0.4, "Bluegill (Salt Cured)"),
    named(F.PRESSED_FISH, 3.1, "Walleye (Salt Cured)"), named(F.GUTTED_FISH, 1, "Perch (Gutted)") }
local rows = RackUI.hangRows({}, frame, "Open", carried)
check("a row a kind, by its name, in name order", #rows == 3 and rows[1].label == "Bluegill (Salt Cured)"
    and rows[2].label == "Perch (Gutted)" and rows[3].label == "Walleye (Salt Cured)")
local corned, country = newFood(F.CURED_MEAT, { ActualWeight = 0.4 }, 1), newFood(F.CURED_MEAT, { ActualWeight = 0.8 }, 0)
corned.name, country.name = "Steak (Corned)", "Beef (Country Cured)"
country:getModData().longCure = true
local sausage = newFood(F.BLOOD_SAUSAGE, { ActualWeight = 0.2 })
sausage.name = "Blood Sausage"
local groups = RackUI.hangGroups({}, frame, "Open", { country, carried[3], sausage, carried[1], carried[4], corned, carried[2] })
local function groupNames()
    local out = {}
    for _, group in ipairs(groups) do table.insert(out, group.group) end
    return table.concat(out, ",")
end
check("Hang groups in menu order: salt, gutted, corned, country, sausages", groupNames() == "salt,cold,corned,country,sausage"
    and groups[1].label == "Hang Salt Fish" and groups[4].label == "Hang Country Cured Meat")
check("a group holds its kinds", #groups[1].rows == 2 and groups[1].rows[1].label == "Bluegill (Salt Cured)" and #groups[2].rows == 1)
check("a group with a kind open isn't refused; one with none open is, with the reason", groups[1].refusal == nil
    and groups[4].refusal == getText(F.REFUSALS.countryCuredSmokehouse) and groups[5].refusal == getText(F.REFUSALS.sausageSmokehouse))
check("the pieces lightest first, all fitting", rows[1].room == 2 and rows[1].pieces[1]:getActualWeight() == 0.4
    and rows[1].refusal == nil)
check("its hover says what is carried and what fits", rows[1].help:find("2 Bluegill (Salt Cured) carried, 0.9 kg.", 1, true) ~= nil
    and rows[1].help:find("2 fit: it has room for 20.0 kg more.", 1, true) ~= nil)
check("a kind too heavy for a frame is refused, with every rack's limit", rows[3].room == 0
    and rows[3].refusal == "Too heavy for a frame: 3.1 kg. A frame takes pieces up to 2.5 kg, a Beam up to 5 kg, a Gantry up to 12 kg.")
local cellar = RackUI.hangRows({}, frame, "Basement", { named(F.GUTTED_FISH, 1, "Perch (Gutted)") })
check("gutted fish in a basement is refused for its still air", cellar[1].room == 0
    and cellar[1].refusal == getText(F.REFUSALS.noColdIndoors))
local nearlyFull = {}
for _ = 1, 7 do F.hangPiece(nearlyFull, fish(F.PRESSED_FISH, 2.5, "Big"), "Open", ledger, 1000) end
rows = RackUI.hangRows(nearlyFull, frame, "Open", { named(F.PRESSED_FISH, 2, "Walleye (Salt Cured)"),
    named(F.PRESSED_FISH, 2, "Walleye (Salt Cured)"), named(F.PRESSED_FISH, 0.4, "Walleye (Salt Cured)") })
check("only what fits the room left: 2.5 kg takes the 0.4 and one 2", rows[1].room == 2 and #rows[1].pieces == 2
    and rows[1].pieces[1]:getActualWeight() == 0.4)
F.hangPiece(nearlyFull, fish(F.PRESSED_FISH, 2.5, "Big"), "Open", ledger, 1000)
rows = RackUI.hangRows(nearlyFull, frame, "Open", { named(F.PRESSED_FISH, 0.4, "Walleye (Salt Cured)") })
check("a full frame: the row has no room, says so", rows[1].room == 0 and rows[1].refusal == nil and rows[1].noRoom == "Full: no room for another piece.")

-- The drop square's judgement: what it hangs (lightest first, by the menu's rules), its lines, and why the rest won't.
local judged = RackUI.dropJudge({}, frame, "Open", { fish(F.PRESSED_FISH, 0.5, "Bluegill (Salt Cured)"),
    fish(F.PRESSED_FISH, 0.4, "Bluegill (Salt Cured)") })
check("a drop it all takes: both, lightest first, no warning", #judged.take == 2 and judged.take[1]:getActualWeight() == 0.4
    and judged.lines[1] == "Drop to hang 2 of 2" and judged.lines[2] == "Room for 20.0 kg more" and #judged.lines == 2
    and judged.refused == nil)
judged = RackUI.dropJudge({}, frame, "Open", { fish(F.PRESSED_FISH, 0.5, "Bluegill (Salt Cured)"),
    fish(F.PRESSED_FISH, 3.1, "Walleye (Salt Cured)") })
check("a mixed drop: what it takes, and the line that some will be rejected", #judged.take == 1
    and judged.lines[1] == "Drop to hang 1 of 2" and judged.lines[3] == "Some items will be rejected."
    and judged.refused:find("Too heavy for a frame: 3.1 kg.", 1, true) == 1)
judged = RackUI.dropJudge({}, frame, "Open", { fish(F.PRESSED_FISH, 3.1, "Walleye (Salt Cured)") })
check("nothing it takes: the reason is the line", #judged.take == 0 and judged.lines[1]:find("Too heavy", 1, true) == 1)
local almost = {}
for _ = 1, 7 do F.hangPiece(almost, fish(F.PRESSED_FISH, 2.5, "Big"), "Open", ledger, 1000) end
judged = RackUI.dropJudge(almost, frame, "Open", { fish(F.PRESSED_FISH, 2, "A"), fish(F.PRESSED_FISH, 2, "B"), fish(F.PRESSED_FISH, 0.4, "C") })
check("more than the room: the lightest that fit, the rest refused as full", #judged.take == 2 and judged.take[1]:getActualWeight() == 0.4
    and judged.refused == "Full: no room for another piece." and judged.lines[3] == "Some items will be rejected.")

-- Smokehouse Info (S3): the fire among the place rows, each piece's own smoke under its bar, a link's popup.
local SHED = require("TraditionalPreservationCore/Smokehouse").PLACE
local CHAMBER = F.CHAMBER_HANGER
local shed = {}
local smoked = F.hangPiece(shed, fish(F.PRESSED_FISH, 1, "Walleye (Salt Cured)"), SHED, ledger, 1000)
smoked.state.coldSmokeHours = 12
local cooking = F.hangPiece(shed, fish(F.PRESSED_FISH, 1, "Pike (Salt Cured)"), SHED, ledger, 1000)
cooking.state.hotSmokeHours = 2
local link = newFood(F.BLOOD_SAUSAGE, { ActualWeight = 0.2, OffAge = 5 })
link.name, link.cooked = "Blood Sausage", true
local hung = F.hangPiece(shed, link, SHED, ledger, 1000)
shown = RackUI.view(shed, CHAMBER, SHED, ledger, 1000, "stoked")
check("Smokehouse Info: what it holds by the Smokehouse's limits, and the fire", valueOf(shown, "InfoHolds") == "3 of 150 pieces, 2.2 of 90 kg, up to 12 kg each"
    and valueOf(shown, "InfoFire") == "Stoked (hot)")
check("a rack has no fire row", valueOf(RackUI.view({}, frame, "Open", ledger, 1000), "InfoFire") == nil)
check("a fish's smoke under its bar", shown.pieces[1].note == "12.0 of 24 h of smoke")
check("a run cooking it comes first", shown.pieces[2].note:find("^2%.0 of %d+ h stoked in a row, 0%.0 of 24 h of smoke$") ~= nil)
check("a link's smoke and its days to stale", shown.pieces[3].note:find("^0%.0 of %d+ h of smoke, stale in %d") ~= nil
    and shown.pieces[3].group == "Smoked blood sausage")
check("a rack's piece has no line under its bar", RackUI.pieceRow(salt, ledger, 1000).note == nil)
lines = {}
shown.pieces[3].popup(tooltip)
check("a link's popup: its smoking, what it comes down as, the fire, when it goes stale", lines[1].value == "Cold smoking (blood sausage)"
    and lines[2].value == "BloodSausage" and lines[3].label == "Stone Hearth:" and lines[4].value:find("goes stale in", 1, true) ~= nil)
groups = RackUI.hangGroups(shed, CHAMBER, SHED, { named(F.GUTTED_FISH, 1, "Perch (Gutted)"), sausage, country })
check("the Smokehouse's Hang groups: gutted fish refused for its still air, Country Cured and sausages open", groupNames() == "cold,country,sausage"
    and groups[1].refusal == getText(F.REFUSALS.noColdIndoors) and groups[2].refusal == nil and groups[3].refusal == nil)
check("too heavy for the Smokehouse names its own limit", RackUI.refusalText(F.REFUSALS.tooHeavy, CHAMBER, fish(F.PRESSED_FISH, 12.5))
    == "Too heavy for the Smokehouse: 12.5 kg. It takes pieces up to 12 kg.")
check("a link has no hours left to wait on", RackUI.soonestHours({ pieces = { hung } }, ledger) == nil)

H.done()
