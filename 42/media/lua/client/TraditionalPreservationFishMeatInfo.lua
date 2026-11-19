-- Traditional Preservation (Fish & Meat): the rows Rack Info and Smokehouse Info are made of (...RackUI.lua): a
-- station's place rows (where it stands, what it holds, the weather, the Smokehouse's fire) and one piece's bar with
-- what is stopping or spoiling it. It reads the same status the popups do (F.stackStatus, F.charqueStatus,
-- F.sausageStatus), so the two agree, and nothing is simulated here.
local UI = require "TraditionalPreservationCore/UI"
local Fire = require "TraditionalPreservationCore/Fire"
local Smokehouse = require "TraditionalPreservationCore/Smokehouse"
local F = TraditionalPreservationFishMeat

TraditionalPreservationFishMeatInfo = TraditionalPreservationFishMeatInfo or {}
local Info = TraditionalPreservationFishMeatInfo

local KEY = "IGUI_TraditionalPreservationFishMeat_"
-- Places with a word of their own (TP Core's); anything else under a roof reads as indoors.
local PLACES = { Open = true, Covered = true, Sheltered = true, AiredRoom = true, Basement = true, [Smokehouse.PLACE] = true }
local METHOD_NAMES = { salt = KEY .. "InfoSalt", cold = KEY .. "InfoCold", meat = KEY .. "InfoCharque",
    sausage = KEY .. "InfoSausage", freshSausage = KEY .. "InfoSmokedSausage" }
local GOOD_COLOUR, SLOW_COLOUR = { 0.35, 0.6, 0.3 }, { 0.75, 0.55, 0.2 }
Info.GOOD_COLOUR, Info.SLOW_COLOUR = GOOD_COLOUR, SLOW_COLOUR

-- A stack of blood sausage or Fresh Sausage (F.sausageStatus): smoke only (a hot run for Fresh Sausage), no drying or
-- spoiling of its own.
function Info.sausageBatch(modData, ledger, now)
    local status = F.sausageStatus(modData, ledger, now)
    local good = status.hot and "Cooking" or "Smoking"
    local row = { name = status.hot and METHOD_NAMES.freshSausage or METHOD_NAMES.sausage, progress = status.progress,
        notes = {}, slow = status.fireEffect ~= good }
    row.progressText = UI.say(KEY .. "InfoShare", UI.percent(status.progress), getText(KEY .. "Sausage" .. status.fireEffect))
    table.insert(row.notes, UI.say(status.hot and KEY .. "HotSmokeHours" or KEY .. "ColdSmokeNeed",
        string.format("%.1f", status.cold), string.format("%.0f", status.need)))
    if status.staleDays then
        table.insert(row.notes, UI.say(KEY .. (status.hot and "FreshSausageStaleIn" or "SausageStaleIn"), string.format("%.1f", status.staleDays)))
    end
    return row
end

-- One hanging piece: its name (a key), progress, the text on its bar, whether something holds it back, and the
-- lines to say about it below. method is F.hangMethod's ("sausage" for either link).
function Info.batch(method, modData, ledger, now)
    if method == "sausage" then return Info.sausageBatch(modData, ledger, now) end
    local isCold, isMeat = method == "cold", method == "meat"
    local status = isMeat and F.charqueStatus(modData, ledger) or F.stackStatus(isCold, modData, ledger)
    local row = { name = status.hotOnly and KEY .. "InfoHotOnly" or status.dryCuring and KEY .. "InfoDryCure" or METHOD_NAMES[method],
        progress = status.progress, notes = {} }
    local share = UI.percent(status.progress)
    if status.reason then
        row.progressText, row.slow = UI.say(KEY .. "InfoShare", share, getText(KEY .. "Stopped" .. status.reason)), true
    elseif status.hoursLeft then
        local hours = math.ceil(status.hoursLeft)
        row.progressText = UI.say(KEY .. "InfoLeft", share, tostring(math.floor(hours / 24)), tostring(hours % 24))
        row.weather = true
    else
        row.progressText, row.slow = UI.say(KEY .. "InfoShare", share, getText(KEY .. "Paused")), true
    end

    local warning = F.spoilWarning(status, isCold)
    if warning then
        table.insert(row.notes, UI.say(warning, UI.percent(status.spoiled)))
        row.slow = true
    end
    if status.underSalted then
        table.insert(row.notes, UI.say(KEY .. (status.hotOnly and "UnderSaltedHotOnly" or "UnderSaltedShed"), string.format("%.0f", status.shedTemperature)))
        row.slow = true
    end
    -- In a Smokehouse joined to a Stone Hearth: a stoked run that is cooking the stack, and its smoke so far.
    if F.cookShare(modData) then
        table.insert(row.notes, UI.say(KEY .. "InfoCooking", string.format("%.1f", modData.hotSmokeHours), string.format("%.0f", modData.hotSmokeHoursNeeded)))
    end
    if not modData.hotOnly and (modData.smokeFrom or (modData.coldSmokeHours or 0) > 0) then
        table.insert(row.notes, UI.say(KEY .. "ColdSmokeNeed", string.format("%.1f", modData.coldSmokeHours or 0), string.format("%.0f", F.coldNeed(modData))))
    end
    return row
end

-- A station's place rows, label key and value: Place, then holds (a value, or nil to leave the row out), Air, Wind
-- where wind reaches, Wetness in the open, and the fire for a Smokehouse ("none", "out", "banked" or "stoked").
function Info.placeRows(place, ledger, holds, fire)
    local rows = {}
    table.insert(rows, { KEY .. "Place", UI.placeName(PLACES[place] and place or "Sheltered") })
    if holds then table.insert(rows, { KEY .. "InfoHolds", holds }) end
    local temperature = ledger.temperature or 0
    -- Below ground, in a room and in the Smokehouse the stacks go by the place's own temperature (the Smokehouse's is
    -- an open roof's, the hour's).
    if place == "Basement" or place == "AiredRoom" or place == "Sheltered" or place == Smokehouse.PLACE then
        table.insert(rows, { KEY .. "InfoAir", UI.placeText(place, F.ownTemperature(ledger, place)) })
    else
        table.insert(rows, { KEY .. "InfoAir", UI.say(KEY .. "InfoAirValue", UI.degrees(temperature),
            UI.degrees(ledger.seasonTemperature or temperature)) })
    end
    -- Wind reaches a hanger in the open, under an open roof and through an open window.
    if place == "Open" or place == "Covered" or place == "AiredRoom" then
        table.insert(rows, { KEY .. "Wind", getText(F.windWord(ledger.wind)) })
    end
    if place == "Open" then
        table.insert(rows, { KEY .. "InfoWetness", UI.percent(ledger.wetness or 0) })
    end
    if fire then
        table.insert(rows, { KEY .. "InfoFire", getText(KEY .. "InfoFire" .. string.upper(string.sub(fire, 1, 1)) .. string.sub(fire, 2)) })
    end
    return rows
end

-- The fire of the Stone Hearth joined to a Smokehouse tile, as Info.placeRows takes it: "none", "out", "banked" or
-- "stoked".
function Info.fireWord(chamberTile)
    local stoneHearth = Smokehouse.joinedStoneHearth(chamberTile)
    if not stoneHearth then return "none" end
    if Fire.isBanked(stoneHearth) then return "banked" end
    return Fire.isBurning(stoneHearth) and "stoked" or "out"
end
