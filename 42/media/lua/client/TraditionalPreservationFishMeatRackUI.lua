-- Traditional Preservation (Fish & Meat): the right-click menu of a Drying Frame, a Hanging Beam, a Gantry or TP Core's
-- Smokehouse (what it holds, Info, a Hang submenu a group (Salt Fish, Gutted Fish, Corned Meat, Country Cured Meat,
-- Sausages) with a row for each kind carried, One / All, Take Done, Take Everything Off; TPFMRack does the hand
-- jobs) and Rack Info, its info window (TP Core's InfoWindow, its pieces in TP Core's scrolling list). A rack's window
-- is on the settled look (all_info_mock): a band with its state, the Station rows, the load as cells (what is dragged
-- onto them hangs) with the racks' lore, then one row a piece: its bar and text from the stack status it always had
-- (Info.batch on the piece's own state), what holds it back as its warning, its process for the by-process sort, and
-- a popup with its method, what it comes out as, the time left and any warning. Opening it brings the rack up to
-- now, as the World's look does. Smokehouse Info is the same window with the joined Stone Hearth's fire as its band
-- (TP Core's SmokehouseUI.band), the farm smokehouse's lore, and each piece's own smoke under its bar.
require "TraditionalPreservationFishMeatInfo"
require "TimedActions/TPFMRack"
local InfoWindow = require "TraditionalPreservationCore/InfoWindow"
local PiecesUI = require "TraditionalPreservationCore/PiecesUI"
local UI = require "TraditionalPreservationCore/UI"
local Smokehouse = require "TraditionalPreservationCore/Smokehouse"
local SmokehouseUI = require "TraditionalPreservationCore/SmokehouseUI"
local F = TraditionalPreservationFishMeat
local Info = TraditionalPreservationFishMeatInfo

TraditionalPreservationFishMeatRackUI = TraditionalPreservationFishMeatRackUI or {}
local RackUI = TraditionalPreservationFishMeatRackUI

local KEY = "IGUI_TraditionalPreservationFishMeat_"
local DONE_COLOUR, ROTTEN_COLOUR = { 0.35, 0.7, 0.35 }, { 0.6, 0.3, 0.25 }
local METHOD_NAMES = { salt = KEY .. "MethodSalt", cold = KEY .. "MethodCold", meat = KEY .. "MethodCharque" }

-- An ArrayList of one, for F.stackOutcome.
local function listOf(item)
    return { size = function() return 1 end, get = function() return item end }
end

-- Each piece's icon, made once from its kept item (a weak table: a piece taken off lets it go).
local icons = setmetatable({}, { __mode = "k" })
local function iconOf(piece)
    local icon = icons[piece]
    if icon == nil then
        icon = F.itemFromKept(piece):getTexture() or false
        icons[piece] = icon
    end
    return icon or nil
end

-- A done piece's name and icon: what it comes off as (F.rackOutput's item: Dry Cured, Cold Smoked, Hot Smoked, a ham,
-- Aged; user, session 72: a Country Cured beef reads as the Dry Cured beef it has become). Made from the kept piece,
-- which it leaves as it is, at most once a game hour (the name ages with it); a weak table, as the icons.
local doneLooks = setmetatable({}, { __mode = "k" })
local function doneLook(piece, now)
    local hour = math.floor(now or piece.doneHour or 0)
    local known = doneLooks[piece]
    if not known or known.hour ~= hour then
        local item = F.rackOutput(piece, now)
        known = { hour = hour, name = item and string.gsub(item:getDisplayName(), "%s+$", "") or piece.name,
            icon = item and item:getTexture() or nil }
        doneLooks[piece] = known
    end
    return known
end

-- Each rack's own icon, by its hanger's name: the menu's item icons, and Rack Info's outline (TP Core
-- tools/station_icons.py; the Smokehouse's is TP Core's).
local RACK_ICONS = { frame = "media/textures/Item_DryingFrame.png", medium = "media/textures/Item_DryingBeamMedium.png",
    large = "media/textures/Item_DryingBeamLarge.png", chamber = "media/textures/Item_SmokehouseChamber.png" }
local STATION_ICONS = { frame = "media/textures/TPStation_DryingFrame.png", medium = "media/textures/TPStation_HangingBeam.png",
    large = "media/textures/TPStation_Gantry.png", chamber = "media/textures/TPStation_Smokehouse.png" }

-- The icon of what the first done piece comes off as (Salt Dried, Stockfish, Charque ...), for Take Done; else
-- vanilla's crafted icon.
local CRAFTED_ICON, RETURNED_ICON = "media/ui/Entity/Icon_Crafted_48x48.png", "media/ui/Entity/Icon_Returned_48x48.png"
local function firstDoneIcon(rack)
    for _, piece in ipairs(rack.pieces or {}) do
        if F.pieceDone(piece) then
            local script = getScriptManager():FindItem(F.pieceOutputType(piece))
            if script then return script:getNormalTexture() end
        end
    end
    return CRAFTED_ICON
end

-- A link's popup: its smoking, what it comes down as, what the fire does for it, and when it goes stale.
local function drawSausagePopup(tooltip, piece, ledger, now)
    local status = F.sausageStatus(piece.state, ledger, now)
    UI.drawTooltip(tooltip, function(layout)
        UI.addLine(layout, KEY .. "Method", getText(status.hot and KEY .. "MethodSmokedSausage" or KEY .. "MethodSausage"))
        UI.addLine(layout, KEY .. "ComesOutAs", getItemNameFromFullType(F.pieceOutputType(piece)))
        if F.pieceDone(piece) then
            UI.addLine(layout, KEY .. "TimeLeft", getText(KEY .. "RackDone"))
        else
            UI.addLine(layout, KEY .. "InfoFire", getText(KEY .. "Sausage" .. status.fireEffect),
                status.fireEffect ~= (status.hot and "Cooking" or "Smoking") and UI.SLOW_COLOUR or nil)
        end
        if status.staleDays then
            UI.addLine(layout, KEY .. "Spoilage", UI.say(KEY .. (status.hot and "FreshSausageStaleIn" or "SausageStaleIn"),
                string.format("%.1f", status.staleDays)), UI.WARNING_COLOUR)
        end
    end)
end

-- The popup: method, what it comes out as, time left (or why it stopped) and its warnings. The place and the
-- weather are the window's rows.
local function drawPopup(tooltip, piece, ledger, now)
    if F.RACK_METHODS[piece.method].sausage then return drawSausagePopup(tooltip, piece, ledger, now) end
    local state, method = piece.state, piece.method
    local isCold, isMeat = method == "cold", method == "meat"
    local status = isMeat and F.charqueStatus(state, ledger) or F.stackStatus(isCold, state, ledger)
    UI.drawTooltip(tooltip, function(layout)
        UI.addLine(layout, KEY .. "Method", getText(status.hotOnly and KEY .. "MethodHotOnly"
            or status.dryCuring and KEY .. "MethodDryCure" or METHOD_NAMES[method]))
        UI.addLine(layout, KEY .. "ComesOutAs", F.stackOutcome(state, listOf(F.keptItem(piece)), method))
        if F.pieceDone(piece) then
            UI.addLine(layout, KEY .. "TimeLeft", getText(KEY .. "RackDone"))
        elseif status.reason then
            UI.addLine(layout, KEY .. "TimeLeft", getText(KEY .. "Stopped" .. status.reason), UI.SLOW_COLOUR)
        else
            UI.addLine(layout, KEY .. "TimeLeft", status.hoursLeft and UI.timeText(status.hoursLeft, KEY .. "Time")
                or getText(KEY .. "Paused"))
        end
        local warning = F.spoilWarning(status, isCold)
        if warning then
            UI.addLine(layout, KEY .. "Spoilage", UI.say(warning, UI.percent(status.spoiled)), UI.WARNING_COLOUR)
        end
        if status.underSalted then
            UI.addLine(layout, KEY .. "UnderSalted", UI.say(status.hotOnly and KEY .. "UnderSaltedHotOnly" or KEY .. "UnderSaltedShed",
                string.format("%.0f", status.shedTemperature)), UI.WARNING_COLOUR)
        end
    end)
end

-- The Smokehouse's line under a piece's bar (panel C of art/rack_window_mock.png): its own smoke since it was hung.
-- A hot run counting (always for poultry, rabbit and Fresh Sausage), then its cold smoke against its need (with a
-- fire joined on a day over F.COLD_SMOKE_MAX, too warm to count), and a link's days to stale until it is smoked.
function RackUI.smokeNote(piece, now, ledger)
    local state, parts = piece.state, {}
    local function hours(key, have, need)
        table.insert(parts, UI.say(KEY .. key, string.format("%.1f", have or 0), string.format("%.0f", need)))
    end
    if F.RACK_METHODS[piece.method].sausage then
        local smoke, need = F.sausageSmoke(state)
        hours(state.sausage == "pork" and "HotSmokeHours" or "ColdSmokeNeed", smoke, need)
        if not state.smokedAt and state.staleAt and state.staleAt > now then
            table.insert(parts, UI.say(KEY .. "RackStaleIn", string.format("%.1f", (state.staleAt - now) / 24)))
        end
    else
        if state.hotSmokeHoursNeeded and not state.noHotSmoke and (state.hotOnly or F.cookShare(state)) then
            hours("HotSmokeHours", state.hotSmokeHours, state.hotSmokeHoursNeeded)
        end
        if not state.hotOnly and state.smokeNeed then
            hours("ColdSmokeNeed", state.coldSmokeHours, state.smokeNeed)
            if state.smokeFrom and ledger and (ledger.temperature or 0) > F.COLD_SMOKE_MAX then
                table.insert(parts, UI.say(KEY .. "RackTooWarm", tostring(F.COLD_SMOKE_MAX)))
            end
        end
    end
    return #parts > 0 and table.concat(parts, ", ") or nil
end

-- What holds a piece back, for its row's warning (amber, right) and the band: spoiling (the season, hot sun or too
-- little salt for the warmth) before stopped (its status's reason: rain, a shut room, too warm ...). Returns the
-- warning text, whether it is spoiling, and the reason it stopped, or nil. A done piece and a link have none.
local function holdBack(piece, ledger)
    if F.pieceDone(piece) or F.RACK_METHODS[piece.method].sausage then return nil end
    local status = piece.method == "meat" and F.charqueStatus(piece.state, ledger)
        or F.stackStatus(piece.method == "cold", piece.state, ledger)
    if status.spoiling or status.scorching then
        return UI.say(KEY .. "RackWarnSpoiling", UI.percent(status.spoiled)), true
    end
    if status.underSalted then return getText(KEY .. "RackWarnUnderSalted"), true end
    if status.reason then return getText(KEY .. "RackWarn_" .. status.reason), false, status.reason end
    return nil
end

-- One list row for a piece (TP Core's PieceList row). A done piece reads Done (or Rotten) and sorts first, named as it
-- comes off. Its tab
-- is its Hang group's (Salt Fish, Gutted Fish, Corned Meat, Country Cured Meat, Sausages), in the menu's order. In
-- the Smokehouse each row has its smoke under the bar. What holds it back is its warning (spoiling, or stopped: then
-- the bar reads its share alone, the warning says why).
function RackUI.pieceRow(piece, ledger, now)
    local batch = Info.batch(piece.method == "freshSausage" and "sausage" or piece.method, piece.state, ledger, now)
    local progress, rotten = F.pieceProgress(piece)
    local group = RackUI.pieceGroup(piece)
    local row = { name = piece.name, tab = getText(KEY .. "RackTab_" .. group), tabOrder = RackUI.GROUP_ORDER[group],
        share = progress, text = batch.progressText,
        colour = batch.slow and Info.SLOW_COLOUR or Info.GOOD_COLOUR, weather = batch.weather,
        note = F.inShed(piece.state) and RackUI.smokeNote(piece, now, ledger) or nil,
        popup = function(tooltip) drawPopup(tooltip, piece, ledger, now) end }
    row.warning, row.spoiling, row.stopped = holdBack(piece, ledger)
    if row.stopped then row.text = UI.percent(progress) end
    if rotten then
        row.text, row.colour, row.spoiling = getText(KEY .. "OutcomeRotten"), ROTTEN_COLOUR, true
    elseif F.pieceDone(piece) then
        row.text, row.colour, row.weather = getText(KEY .. "RackDone"), DONE_COLOUR, nil
    end
    if F.pieceDone(piece) then row.name = doneLook(piece, now).name end
    return row
end

-- Everything Rack Info shows: { rows (label key, value), pieces (list rows), notes }. hanger is the rack's
-- (F.hangerOf), place where it stands; fire the Smokehouse's (Info.fireWord), nil for a rack.
function RackUI.view(rack, hanger, place, ledger, now, fire)
    local limits = F.RACK_LIMITS[hanger.name]
    local holds = UI.say(KEY .. "RackHolds", tostring(F.rackCount(rack)), tostring(limits.pieces),
        string.format("%.1f", F.rackWeight(rack)), tostring(limits.total), tostring(limits.heaviest))
    local pieces, notes, weather, done = {}, {}, false, 0
    for _, piece in ipairs(rack.pieces or {}) do
        local row = RackUI.pieceRow(piece, ledger, now)
        row.icon = F.pieceDone(piece) and doneLook(piece, now).icon or iconOf(piece)
        table.insert(pieces, row)
        weather = weather or row.weather == true
        if F.pieceDone(piece) then done = done + 1 end
    end
    if done > 0 then table.insert(notes, UI.say(KEY .. "RackDoneNote", tostring(done))) end
    if weather then table.insert(notes, getText(KEY .. "InfoWeather")) end
    if #pieces == 0 then table.insert(notes, getText(KEY .. "InfoEmpty")) end
    return { rows = Info.placeRows(place, ledger, holds, fire), pieces = pieces, notes = notes,
        doneIds = F.pieceIds(rack, true), allIds = F.pieceIds(rack), waitText = RackUI.waitText(rack, ledger),
        place = place, temperature = F.ownTemperature(ledger, place), stationRows = RackUI.stationRows(hanger, place, ledger),
        holding = RackUI.holding(rack, hanger), band = { RackUI.band(pieces, place, ledger) } }
end

-- Rack Info's own Station rows under Place and Season (TP Core's stationBlock; label key, value): the wind where it
-- reaches, the wetness in the open, and the heaviest piece the rack takes.
function RackUI.stationRows(hanger, place, ledger)
    local rows = {}
    if place == "Open" or place == "Covered" or place == "AiredRoom" then
        table.insert(rows, { KEY .. "Wind", getText(F.windWord(ledger.wind)) })
    end
    if place == "Open" then table.insert(rows, { KEY .. "InfoWetness", UI.percent(ledger.wetness or 0) }) end
    table.insert(rows, { KEY .. "RackPieces", UI.say(KEY .. "RackPiecesValue", tostring(F.RACK_LIMITS[hanger.name].heaviest)) })
    return rows
end

-- The band (all_info_mock), the worst first: empty; a piece spoiling or rotted; all done; a piece stopped (the first
-- one's reason); else drying, with the wind where it reaches. pieces are the view's rows. Returns the word's key,
-- the finished text and the colours.
function RackUI.band(pieces, place, ledger)
    local count, done, spoiling, stopped, reason = #pieces, 0, 0, 0, nil
    for _, row in ipairs(pieces) do
        if row.spoiling then spoiling = spoiling + 1 end
        if row.stopped then stopped, reason = stopped + 1, reason or row.stopped end
        if row.colour == DONE_COLOUR then done = done + 1 end
    end
    if count == 0 then return KEY .. "RackBandEmpty", getText(KEY .. "RackBandEmptyText"), InfoWindow.BAND_IDLE end
    if spoiling > 0 then
        return KEY .. "TubBandSpoiling", UI.say(KEY .. "RackBandSpoilingText", tostring(spoiling), tostring(count)), InfoWindow.BAND_AT_RISK
    end
    if done == count then return KEY .. "RackDone", UI.say(KEY .. "RackBandDoneText", tostring(done)), InfoWindow.BAND_WORKING end
    if stopped > 0 then
        return KEY .. "RackBandStopped", UI.say(KEY .. "RackBandStoppedText", getText(KEY .. "RackBandWhy_" .. reason),
            tostring(stopped), tostring(count)), InfoWindow.BAND_WAITING
    end
    if place == "Open" or place == "Covered" or place == "AiredRoom" then
        local wind = string.gsub(F.windWord(ledger.wind), "^.*_Wind", "")
        return KEY .. "RackBandDrying", UI.say(KEY .. "RackBandDryingWindText", getText(KEY .. "RackBandWind_" .. wind),
            tostring(done), tostring(count)), InfoWindow.BAND_WORKING
    end
    return KEY .. "RackBandDrying", UI.say(KEY .. "RackBandDryingText", tostring(done), tostring(count)), InfoWindow.BAND_WORKING
end

-- The load's cells (tools/cell_patterns.py in TP Core): fish, meat and links each in their pattern, by weight.
local LOAD_COLOUR = { 0.59, 0.51, 0.39 }
local PATTERNS = { salt = "media/textures/TPCell_Fish.png", cold = "media/textures/TPCell_Fish.png",
    meat = "media/textures/TPCell_Meat.png", sausage = "media/textures/TPCell_Sausage.png",
    freshSausage = "media/textures/TPCell_Sausage.png" }
RackUI.PATTERNS = PATTERNS

-- The share of the rack taken: by weight or by count, whichever is fuller.
local function loadShare(limits, count, weight)
    return math.max(count / limits.pieces, weight / limits.total)
end

-- The load as Holds' cells: its weight against the rack's, its pieces against its count, in parts by pattern.
function RackUI.holding(rack, hanger)
    local limits = F.RACK_LIMITS[hanger.name]
    local count, weight = F.rackCount(rack), F.rackWeight(rack)
    local byPattern, parts = {}, {}
    for _, piece in ipairs(rack.pieces or {}) do
        local pattern = PATTERNS[piece.method]
        if not byPattern[pattern] then
            byPattern[pattern] = { pattern = pattern, weight = 0 }
            table.insert(parts, byPattern[pattern])
        end
        byPattern[pattern].weight = byPattern[pattern].weight + piece.weight
    end
    return { kind = "cells", name = getText(KEY .. "RackLoad"),
        amount = UI.say(KEY .. "RackLoadWeight", string.format("%.1f", weight), tostring(limits.total)),
        state = UI.say(KEY .. "RackLoadPieces", tostring(count), tostring(limits.pieces)),
        share = loadShare(limits, count, weight), colour = LOAD_COLOUR, parts = #parts > 0 and parts or nil }
end

-- Why Take Done is greyed: nothing hangs, or when the next piece will be done (or that nothing dries now).
function RackUI.waitText(rack, ledger)
    if F.rackCount(rack) == 0 then return getText(KEY .. "RackNothingHanging") end
    local soonest = RackUI.soonestHours(rack, ledger)
    return soonest and UI.say(KEY .. "RackNoneFinished", UI.durationText(soonest)) or getText(KEY .. "RackNoneFinishedStopped")
end

-- The Smokehouse's fire word (Info.fireWord), nil for a rack.
local function fireOf(station)
    return Smokehouse.isChamber(station) and Info.fireWord(station) or nil
end

-- The rack brought up to now at its place, and what the window shows.
local function viewOf(station)
    local rack, place = F.rackNow(station)
    local rackView = RackUI.view(rack, F.hangerOf(station), place, F.getLedger(), getGameTime():getWorldAgeHours(), fireOf(station))
    rackView.doneIcon = firstDoneIcon(rack)
    -- Cold smoke counts only on a cool day (F.COLD_SMOKE_MAX): the Smokehouse's band says when it doesn't.
    rackView.tooWarm = (F.getLedger().temperature or 0) > F.COLD_SMOKE_MAX
    return rackView
end

local RackWindow = InfoWindow:derive("TraditionalPreservationFishMeatRackWindow")

function RackWindow:new(playerObj, station)
    local o = InfoWindow.new(self, playerObj, station)
    local hanger = F.hangerOf(station).name
    o.title = getText(KEY .. "RackTitle_" .. hanger)
    o.widthKey = "TraditionalPreservationFishMeat." .. hanger   -- each rack keeps its own width
    return o
end

-- What is dragged onto the load's cells hangs, by the menu's rules.
local function rackDrop(window)
    local function judge(items)
        local rack, place = F.rackNow(window.station)
        return RackUI.dropJudge(rack, F.hangerOf(window.station), place, items)
    end
    local function drop(take) RackUI.hang(window.playerObj, window.station, take) end
    return { judge = judge, drop = drop }
end

function RackWindow:refresh()
    self.rackView = viewOf(self.station)
    self.drop = self.drop or rackDrop(self)
end

-- The notes under a rack's window: done pieces keep, times assume the weather, and how to hang.
local function rackNotes(rackView, chamber)
    local notes = {}
    for _, note in ipairs(rackView.notes) do
        if note ~= getText(KEY .. "InfoEmpty") then table.insert(notes, note) end
    end
    table.insert(notes, getText(KEY .. (chamber and "SmokehouseNoteDrag" or "RackNoteDrag")))
    return notes
end

-- Rack Info and Smokehouse Info on the settled look (all_info_mock): a band (a rack's state; the Smokehouse's joined
-- Stone Hearth's fire, TP Core's SmokehouseUI.band), the Station block, the load as cells with their lore beside them
-- (what is dragged onto them hangs), the pieces hanging (in the Smokehouse each with its smoke under its bar), Take
-- Done and Take All, then notes.
function RackWindow:render()
    ISCollapsableWindow.render(self)
    if self.isCollapsed or not self.rackView then return end
    local rackView = self.rackView
    local chamber = Smokehouse.isChamber(self.station)
    local y
    if chamber then
        y = SmokehouseUI.band(self, self.station, rackView.tooWarm)
    else
        local band = rackView.band
        y = self:band(getText(band[1]), band[2], band[3][1], band[3][2])
    end
    y = self:stationBlock(y, STATION_ICONS[F.hangerOf(self.station).name], rackView.place, rackView.temperature,
        rackView.stationRows)
    y = self:section(y, "IGUI_TraditionalPreservationCore_SectionHolds")
    local holding = rackView.holding
    holding.drop = self.drop
    y = self:holds(y, { holding }, getText(KEY .. (chamber and "SmokehouseLore" or "RackLore")))
    if #rackView.pieces > 0 then
        y = self:pieceListBlock(y, KEY .. "RackHanging", UI.say(KEY .. "RackListCount", tostring(#rackView.pieces)),
            rackView.pieces)
    end
    local station, playerObj = self.station, self.playerObj
    local done, all = rackView.doneIds, rackView.allIds
    y = self:buttonRow(y, {
        { title = UI.say("ContextMenu_TraditionalPreservationFishMeat_RackTakeDone", tostring(#done)), icon = rackView.doneIcon,
          enabled = #done > 0, tooltip = #done == 0 and rackView.waitText or nil,
          onClick = function() RackUI.take(playerObj, station, done) end },
        { title = UI.say("ContextMenu_TraditionalPreservationFishMeat_RackTakeAllCount", tostring(#all)), icon = RETURNED_ICON,
          enabled = #all > 0, tooltip = #all > #done and getText(KEY .. "RackTakeAllHelp") or nil,
          onClick = function() RackUI.take(playerObj, station, all) end },
    })
    self:drawNotes(y, rackNotes(rackView, chamber))
end

-- Opens Rack Info on a Drying Frame, Hanging Beam or Gantry, or Smokehouse Info on any tile of the Smokehouse.
function RackUI.open(playerObj, station)
    InfoWindow.open(RackWindow, playerObj, station)
end

RackUI.isRack = F.isRack

-- What this menu and window serve: the three racks and the Smokehouse.
function RackUI.isHanger(isoObject)
    return F.isRack(isoObject) or Smokehouse.isChamber(isoObject)
end

-- The menu

-- A refusal as the menu says it: too heavy names the piece's weight and every rack's limit.
function RackUI.refusalText(refusal, hanger, item)
    if refusal ~= F.REFUSALS.tooHeavy then return getText(refusal) end
    local limits = F.RACK_LIMITS
    if hanger.closed then
        return UI.say(KEY .. "RackTooHeavyChamber", string.format("%.1f", item:getActualWeight()), tostring(limits.chamber.heaviest))
    end
    return UI.say(KEY .. "RackTooHeavy", getText(KEY .. "RackWord_" .. hanger.name), string.format("%.1f", item:getActualWeight()),
        tostring(limits.frame.heaviest), tostring(limits.medium.heaviest), tostring(limits.large.heaviest))
end

-- A Hang row for each kind carried (by name, in name order; labelled with the name, under its group's submenu), as
-- Core's PiecesUI.row takes it: the pieces that would
-- go on, lightest first so the most fit, and how many fit now; a kind none of whose pieces this rack takes is refused
-- with the first one's reason. items are the carried pieces of any kind the racks hang.
function RackUI.hangRows(rack, hanger, place, items)
    local kinds, names = {}, {}
    for _, item in ipairs(items) do
        local name = UI.itemName(item)
        if not kinds[name] then
            kinds[name] = {}
            table.insert(names, name)
        end
        table.insert(kinds[name], item)
    end
    table.sort(names)
    local limits = F.RACK_LIMITS[hanger.name]
    local count, weight = F.rackCount(rack), F.rackWeight(rack)
    local rows = {}
    for _, name in ipairs(names) do
        local takes, refusal, carriedWeight = {}, nil, 0
        for _, item in ipairs(kinds[name]) do
            carriedWeight = carriedWeight + item:getActualWeight()
            local why = F.rackRefusal({}, hanger, place, item)
            if why then
                refusal = refusal or RackUI.refusalText(why, hanger, item)
            else
                table.insert(takes, item)
            end
        end
        table.sort(takes, function(a, b) return a:getActualWeight() < b:getActualWeight() end)
        local fits, fitWeight = {}, weight
        for _, item in ipairs(takes) do
            if count + #fits >= limits.pieces or fitWeight + item:getActualWeight() > limits.total then break end
            table.insert(fits, item)
            fitWeight = fitWeight + item:getActualWeight()
        end
        local row = { label = name, icon = kinds[name][1]:getTexture(),
            pieces = #fits > 0 and fits or takes, room = #fits, refusal = #takes == 0 and refusal or nil,
            noRoom = getText(KEY .. "RackFull") }
        row.help = table.concat({
            UI.say(KEY .. "RackHangCarried", tostring(#kinds[name]), name, string.format("%.1f", carriedWeight)),
            UI.say(KEY .. "RackHangFits", tostring(#fits), string.format("%.1f", limits.total - weight)),
            getText(KEY .. "RackHangClock") }, " <LINE> ")
        table.insert(rows, row)
    end
    return rows
end

-- The menu's Hang groups, in menu order: what a piece is decides its group (a meat's cure, Corned or Country Cured).
RackUI.GROUPS = { "salt", "cold", "corned", "country", "sausage" }
local METHOD_GROUPS = { salt = "salt", cold = "cold", sausage = "sausage", freshSausage = "sausage" }

local function groupFor(method, longCure)
    if method == "meat" then return longCure and "country" or "corned" end
    return METHOD_GROUPS[method]
end

function RackUI.groupOf(item)
    return groupFor(F.hangMethod(item:getFullType()), item:getModData().longCure)
end

-- A hanging piece's group, as its item's was: Rack Info's tab for it (TP Core's PieceList).
function RackUI.pieceGroup(piece)
    return groupFor(piece.method, piece.data and piece.data.longCure)
end
-- Each group's place in the menu, for the tabs' order.
RackUI.GROUP_ORDER = {}
for index, group in ipairs(RackUI.GROUPS) do RackUI.GROUP_ORDER[group] = index end

-- The Hang groups that have something carried: { group, label, rows (RackUI.hangRows of its pieces), refusal (the
-- first row's reason when no row is open) }.
function RackUI.hangGroups(rack, hanger, place, items)
    local byGroup = {}
    for _, item in ipairs(items) do
        local group = RackUI.groupOf(item)
        byGroup[group] = byGroup[group] or {}
        table.insert(byGroup[group], item)
    end
    local groups = {}
    for _, group in ipairs(RackUI.GROUPS) do
        if byGroup[group] then
            local rows, refusal, open = RackUI.hangRows(rack, hanger, place, byGroup[group]), nil, false
            for _, row in ipairs(rows) do
                if row.refusal then refusal = refusal or row.refusal else open = true end
            end
            table.insert(groups, { group = group, label = getText("ContextMenu_TraditionalPreservationFishMeat_RackHang_" .. group),
                rows = rows, refusal = not open and refusal or nil })
        end
    end
    return groups
end

-- The soonest hours left of any piece still hanging, or nil (none, or every one stopped). A link's smoke has no
-- hours left to tell: it waits on the fire.
function RackUI.soonestHours(rack, ledger)
    local soonest
    for _, piece in ipairs(rack.pieces or {}) do
        if not F.pieceDone(piece) and not F.RACK_METHODS[piece.method].sausage then
            local status = piece.method == "meat" and F.charqueStatus(piece.state, ledger)
                or F.stackStatus(piece.method == "cold", piece.state, ledger)
            if status.hoursLeft and (not soonest or status.hoursLeft < soonest) then soonest = status.hoursLeft end
        end
    end
    return soonest
end

-- What Rack Info makes of a selection dragged onto its cells (TP Core's DropZone judge): the pieces it would hang,
-- lightest first so the most fit, by the menu's rules; the lines to show; why the rest won't hang; and the cells
-- they would fill, in the first one's pattern.
function RackUI.dropJudge(rack, hanger, place, items)
    local limits = F.RACK_LIMITS[hanger.name]
    local count, weight = F.rackCount(rack), F.rackWeight(rack)
    local takes, refused = {}, nil
    for _, item in ipairs(items) do
        local why = F.rackRefusal({}, hanger, place, item)
        if why then refused = refused or RackUI.refusalText(why, hanger, item) else table.insert(takes, item) end
    end
    table.sort(takes, function(a, b) return a:getActualWeight() < b:getActualWeight() end)
    local take, takeWeight = {}, weight
    for _, item in ipairs(takes) do
        if count + #take >= limits.pieces or takeWeight + item:getActualWeight() > limits.total then
            refused = refused or getText(KEY .. "RackFull")
            break
        end
        table.insert(take, item)
        takeWeight = takeWeight + item:getActualWeight()
    end
    if #take == 0 then return { take = take, lines = { refused or getText(KEY .. "RackFull") }, refused = refused, cells = 0 } end
    local lines = { UI.say(KEY .. "RackDropHang", tostring(#take), tostring(#items)),
        UI.say(KEY .. "RackDropRoom", string.format("%.1f", limits.total - weight)) }
    if #take < #items then table.insert(lines, getText(KEY .. "RackDropSome")) end
    local Holds = require "TraditionalPreservationCore/Holds"
    local cells = Holds.filledCells({ share = loadShare(limits, count + #take, takeWeight) })
        - Holds.filledCells({ share = loadShare(limits, count, weight) })
    return { take = take, lines = lines, refused = #take < #items and refused or nil, cells = cells,
        pattern = PATTERNS[F.hangMethod(take[1]:getFullType())] }
end

-- Every carried piece of a kind some rack hangs (the rest of the rules are the rack's to say).
local function hangable(item)
    return instanceof(item, "Food") and F.fishRefusal(item:getFullType()) == nil
end

-- Moves the pieces into the inventory (from a loot window, a bag; not equipped), then walks to the rack and queues a hang a piece:
-- vanilla's order, so a crate left behind is no matter.
function RackUI.hang(playerObj, station, items)
    if #items == 0 then return end
    for _, item in ipairs(items) do ISInventoryPaneContextMenu.transferIfNeeded(playerObj, item) end
    if not UI.walkTo(playerObj, station) then return end
    for _, item in ipairs(items) do ISTimedActionQueue.add(TPFMRack:new(playerObj, station, "hang", item)) end
end
local onHang = RackUI.hang

-- A script item's icon by its full type.

local function iconOfType(fullType)
    local script = ScriptManager.instance:getItem(fullType)
    return script and script:getNormalTexture()
end

-- The piece first in hang order that is done (doneOnly) or any, or nil.
local function firstPiece(rack, doneOnly)
    for _, piece in ipairs(rack.pieces or {}) do
        if not doneOnly or F.pieceDone(piece) then return piece end
    end
end

-- Walks to the rack and queues a take a piece, by id.
function RackUI.take(playerObj, station, ids)
    if #ids == 0 or not UI.walkTo(playerObj, station) then return end
    for _, id in ipairs(ids) do ISTimedActionQueue.add(TPFMRack:new(playerObj, station, "take", nil, id)) end
end
local onTake = RackUI.take

local function addRackMenu(context, playerObj, station)
    local rack, place = F.rackNow(station)
    local hanger = F.hangerOf(station)
    local limits = F.RACK_LIMITS[hanger.name]
    local rackIcon = getTexture(RACK_ICONS[hanger.name])
    local option = context:addOption(getText(KEY .. "RackName_" .. hanger.name))
    option.iconTexture = rackIcon
    local menu = context:getNew(context)
    context:addSubMenu(option, menu)

    local status = menu:addOption(UI.say(KEY .. "RackMenuHolds", tostring(F.rackCount(rack)),
        string.format("%.1f", F.rackWeight(rack)), tostring(limits.total)))
    status.isDisabled = true
    status.iconTexture = rackIcon
    local fire = fireOf(station)
    UI.tooltip(status, fire and UI.placeName(place) .. " <LINE> " .. getText(KEY .. "InfoFire") .. ": "
        .. getText(KEY .. "InfoFire" .. string.upper(string.sub(fire, 1, 1)) .. string.sub(fire, 2)) or UI.placeName(place))
    local info = menu:addOption(getText(KEY .. "RackInfo_" .. hanger.name), playerObj, RackUI.open, station)
    info.iconTexture = rackIcon
    UI.topInfo(context, getText(KEY .. "RackInfo_" .. hanger.name), rackIcon, playerObj, RackUI.open, station)

    for _, group in ipairs(RackUI.hangGroups(rack, hanger, place, UI.findItems(playerObj, hangable))) do
        local groupOption = menu:addOption(group.label)
        groupOption.iconTexture = group.rows[1].icon
        local sub = menu:getNew(menu)
        menu:addSubMenu(groupOption, sub)
        if group.refusal then UI.refuse(groupOption, group.refusal) end
        for _, row in ipairs(group.rows) do
            -- A refused or full row stays clickable, to read why: clicking it does nothing.
            local hangOption = PiecesUI.row(sub, row, function(chosen)
                if row.room > 0 then onHang(playerObj, station, chosen) end
            end)
            hangOption.iconTexture = row.icon
        end
    end

    -- Take Done is always there: greyed until a piece is done, saying when the next will be.
    local done, all = F.pieceIds(rack, true), F.pieceIds(rack)
    local finished = menu:addOption(UI.say("ContextMenu_TraditionalPreservationFishMeat_RackTakeDone", tostring(#done)),
        playerObj, onTake, station, done)
    -- What the first finished piece comes off as (Salt Dried, Stockfish, Charque, Hot Smoked ...); greyed, the rack's own.
    local firstDone = firstPiece(rack, true)
    finished.iconTexture = firstDone and iconOfType(F.pieceOutputType(firstDone)) or rackIcon
    if #done == 0 then UI.disable(finished, RackUI.waitText(rack, F.getLedger())) end
    if #all > #done then
        local takeAll = menu:addOption(getText("ContextMenu_TraditionalPreservationFishMeat_RackTakeAll"), playerObj, onTake, station, all)
        takeAll.iconTexture = iconOfType(firstPiece(rack).fullType)
        UI.tooltip(takeAll, getText(KEY .. "RackTakeAllHelp"))
    end
end

-- One menu a rack, and one for the Smokehouse whichever of its tiles were clicked (counted by its record tile).
local function onFillContextMenu(playerNum, context, worldobjects, test)
    local seen = {}
    for _, isoObject in ipairs(worldobjects) do
        local key = Smokehouse.isChamber(isoObject) and Smokehouse.recordTile(isoObject) or isoObject
        if RackUI.isHanger(isoObject) and not seen[key] then
            if test then return ISWorldObjectContextMenu.setTest() end
            seen[key] = true
            addRackMenu(context, getSpecificPlayer(playerNum), isoObject)
        end
    end
end

Events.OnFillWorldObjectContextMenu.Add(onFillContextMenu)

-- A rack or a Smokehouse with anything on it stays where it is (no station moves mid-process); the Smokehouse's
-- record is on one of its tiles.
UI.keepInPlace(function(isoObject)
    if not RackUI.isHanger(isoObject) then return nil end
    if Smokehouse.isChamber(isoObject) then isoObject = Smokehouse.recordTile(isoObject) end
    if not isoObject:hasModData() then return nil end
    local modData = isoObject:getModData().movableData
    local rack = modData and modData[F.RACK_KEY]
    return (rack ~= nil and F.rackCount(rack) > 0) or nil
end)
