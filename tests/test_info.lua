-- Checks the rows Rack Info and Smokehouse Info are made of outside the game: a station's place rows and one piece's
-- bar with its notes (Info.placeRows, Info.batch).
-- Run from the mod folder: luajit tests/test_info.lua
local H = dofile((os.getenv("TPCORE") or "../TraditionalPreservationCore") .. "/tests/harness.lua")
local check = H.check
H.useModPaths()
H.installClock(1000)
H.installModData()
H.installEvents()
H.installGetText()

-- The mod's own modules and TP Core's load for real, vanilla's are left out.
local realRequire = require
require = function(name)
    if name:find("^TraditionalPreservation") then return realRequire(name) end
end
H.installMenus()

dofile("42/media/lua/shared/TraditionalPreservationFishMeat.lua")
dofile("42/media/lua/shared/TraditionalPreservationFishMeatPotted.lua")
dofile("42/media/lua/shared/TraditionalPreservationFishMeatSmokehouse.lua")
dofile("42/media/lua/client/TraditionalPreservationFishMeatInfo.lua")
local Info = TraditionalPreservationFishMeatInfo

local function valueOf(rows, label)
    for _, row in ipairs(rows) do
        if row[1] == "IGUI_TraditionalPreservationFishMeat_" .. label then return row[2] end
    end
end

local function hasNote(row, text)
    for _, note in ipairs(row.notes) do
        if note:find(text, 1, true) then return true end
    end
    return false
end

-- A rack in the open on a dry summer day: a salt fish two thirds dried, and a gutted fish that can't dry.
local ledger = { temperature = 22, seasonTemperature = 19, wind = 0.3, wetness = 0, coldWetness = 0, openRate = 1,
    coveredRate = 1, shelteredRate = 0.65, coldRate = 0, coldCoveredRate = 0, rawSpoilOn = true, rawSpoilOpenOn = true, saltSpoilOn = false }
local rows = Info.placeRows("Open", ledger, "3 pieces")
check("the place and what it holds", valueOf(rows, "Place") == "Open air" and valueOf(rows, "InfoHolds") == "3 pieces")
check("the air now and over the season", valueOf(rows, "InfoAir") == "22°C now, 19°C over the season")
check("wind and wetness in the open", valueOf(rows, "Wind") == "Good drying wind" and valueOf(rows, "InfoWetness") == "0%")
check("no Stone Hearth line off the Smokehouse", valueOf(rows, "InfoFire") == nil)

local salt = Info.batch("salt", { dried = 192, spoiled = 0 }, ledger, 1000)
check("a salt fish's bar: its share and time left", getText(salt.name) == "Salt fish" and H.near(salt.progress, 192 / 288)
    and salt.progressText == "67%, 4 d 0 h left" and salt.weather and not salt.slow)
local cold = Info.batch("cold", { dried = 0, spoiled = 0.2 }, ledger, 1000)
check("a gutted fish says why it stands still", getText(cold.name) == "Stockfish" and cold.progressText == "0%, Stopped (Too warm)"
    and cold.slow)
check("and its spoilage", hasNote(cold, "Spoiling (Warm season), 20%"))
check("no line passed a percentage to the translator", #H.textWarnings == 0)

-- Under an open roof there is wind but no wetness; in a basement neither.
local covered = Info.placeRows("Covered", ledger)
check("under a roof: wind, no wetness", valueOf(covered, "Wind") ~= nil and valueOf(covered, "InfoWetness") == nil
    and valueOf(covered, "Place") == "Under an open roof" and valueOf(covered, "InfoHolds") == nil)
local cellar = Info.placeRows("Basement", ledger)
check("a basement: its name, no wind", valueOf(cellar, "Place") == "Basement" and valueOf(cellar, "Wind") == nil)
check("its air is the basement's own, not the day's", valueOf(cellar, "InfoAir") == require("TraditionalPreservationCore/UI").placeText("Basement",
    10 + 0.4 * (ledger.seasonTemperature - 10)))

-- The Smokehouse: Corned meat with a stoked run on it, and its smoke.
local cool = { temperature = 8, seasonTemperature = 6, dryCureRate = 0.7, dryCureStokedRate = 1, dryCureBankedRate = 0.9, saltSpoilOn = false }
local Fire = require "TraditionalPreservationCore/Fire"
local shedRows = Info.placeRows("Smokehouse", cool, nil, "stoked")
check("the Smokehouse's fire", valueOf(shedRows, "InfoFire") == "Stoked (hot)" and valueOf(shedRows, "Wind") == nil)
check("the Smokehouse is its own word, by an aired room's air (the hour's with no day mean yet, 1 C over in the cold)",
    valueOf(shedRows, "Place") == "In the Smokehouse" and valueOf(shedRows, "InfoAir") == "9°C (In the Smokehouse)")
local meat = Info.batch("meat", { place = "Smokehouse", dried = 100, spoiled = 0, underSpoiled = 0.1, cureNeed = 504,
    underCured = true, burning = Fire.STOKED, hotSmokeHours = 3, hotSmokeHoursNeeded = 8, coldSmokeHours = 12, smokeNeed = 60,
    smokeFrom = 7, smokeMeat = true }, cool, 1000)
check("meat in the shed dry cures", getText(meat.name) == "Dry cure")
check("the cook is called out", hasNote(meat, "Hot smoking, 3.0 of 8 h stoked in a row: it comes out Hot Smoked"))
check("and the smoke so far", hasNote(meat, "12.0 of 60 h of smoke"))
check("and the under-salting", hasNote(meat, "Spoiling (28°C where it hangs)"))
check("no fire joined", valueOf(Info.placeRows("Smokehouse", cool, nil, "none"), "InfoFire") == "None joined")
check("still no percentage passed to the translator", #H.textWarnings == 0)

H.done()
