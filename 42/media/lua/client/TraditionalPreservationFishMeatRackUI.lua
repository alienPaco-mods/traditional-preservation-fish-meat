-- Traditional Preservation (Fish & Meat): the right-click menu of a Drying Frame, a Hanging Beam, a Gantry or TP Core's
-- Smokehouse (what it holds, Info, a Hang submenu a group (Salt Fish, Gutted Fish, Corned Meat, Country Cured Meat,
-- Sausages) with a row for each kind carried, One / All, Take Done, Take Everything Off; TPFMRack does the hand
-- jobs) and Rack Info, its info window (TP Core's InfoWindow, its pieces in TP Core's scrolling list). The place rows (Info.placeRows), what the rack holds,
-- then one row a piece: its bar and text from the stack status it always had (Info.batch on the piece's own state),
-- its process for the by-process sort, and a popup with its method, what it comes out as, the time left and any
-- warning. Opening it brings the rack up to now, as the World's look does. Smokehouse Info adds the joined Stone
-- Hearth's fire to the place rows and each piece's own smoke under its bar.
require "TraditionalPreservationFishMeatInfo"
require "TimedActions/TPFMRack"
local InfoWindow = require "TraditionalPreservationCore/InfoWindow"
local PiecesUI = require "TraditionalPreservationCore/PiecesUI"
local UI = require "TraditionalPreservationCore/UI"
local Smokehouse = require "TraditionalPreservationCore/Smokehouse"
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
-- A hot run counting (always for poultry, rabbit and Fresh Sausage), then its cold smoke against its need, and a
-- link's days to stale until it is smoked.
function RackUI.smokeNote(piece, now)
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
        if not state.hotOnly and state.smokeNeed then hours("ColdSmokeNeed", state.coldSmokeHours, state.smokeNeed) end
    end
    return #parts > 0 and table.concat(parts, ", ") or nil
end

-- One list row for a piece (TP Core's PieceList row). A done piece reads Done (or Rotten) and sorts first. Its tab
-- is its Hang group's (Salt Fish, Gutted Fish, Corned Meat, Country Cured Meat, Sausages), in the menu's order. In
-- the Smokehouse each row has its smoke under the bar.
function RackUI.pieceRow(piece, ledger, now)
    local batch = Info.batch(piece.method == "freshSausage" and "sausage" or piece.method, piece.state, ledger, now)
    local progress, rotten = F.pieceProgress(piece)
    local group = RackUI.pieceGroup(piece)
    local row = { name = piece.name, tab = getText(KEY .. "RackTab_" .. group), tabOrder = RackUI.GROUP_ORDER[group],
        share = progress, text = batch.progressText,
        colour = batch.slow and Info.SLOW_COLOUR or Info.GOOD_COLOUR, weather = batch.weather,
        note = F.inShed(piece.state) and RackUI.smokeNote(piece, now) or nil,
        popup = function(tooltip) drawPopup(tooltip, piece, ledger, now) end }
    if rotten then
        row.text, row.colour = getText(KEY .. "OutcomeRotten"), ROTTEN_COLOUR
    elseif F.pieceDone(piece) then
        row.text, row.colour, row.weather = getText(KEY .. "RackDone"), DONE_COLOUR, nil
    end
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
        row.icon = iconOf(piece)
        table.insert(pieces, row)
        weather = weather or row.weather == true
        if F.pieceDone(piece) then done = done + 1 end
    end
    if done > 0 then table.insert(notes, UI.say(KEY .. "RackDoneNote", tostring(done))) end
    if weather then table.insert(notes, getText(KEY .. "InfoWeather")) end
    if #pieces == 0 then table.insert(notes, getText(KEY .. "InfoEmpty")) end
    return { rows = Info.placeRows(place, ledger, holds, fire), pieces = pieces, notes = notes,
        doneIds = F.pieceIds(rack, true), allIds = F.pieceIds(rack), waitText = RackUI.waitText(rack, ledger) }
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
    return RackUI.view(rack, F.hangerOf(station), place, F.getLedger(), getGameTime():getWorldAgeHours(), fireOf(station))
end

local RackWindow = InfoWindow:derive("TraditionalPreservationFishMeatRackWindow")

function RackWindow:new(playerObj, station)
    local o = InfoWindow.new(self, playerObj, station)
    o.title = getText(KEY .. "RackInfo_" .. F.hangerOf(station).name)
    return o
end

function RackWindow:refresh()
    self.rackView = viewOf(self.station)
end

function RackWindow:render()
    ISCollapsableWindow.render(self)
    if self.isCollapsed or not self.rackView then return end
    local rackView = self.rackView
    local y = self:top()
    for _, row in ipairs(rackView.rows) do y = self:row(y, row[1], row[2]) end
    y = self:pieceList(y, KEY .. "RackHanging", rackView.pieces)
    local station, playerObj = self.station, self.playerObj
    -- Take Done and Take All, as the menu's rows: greyed with the reason when there is nothing to take.
    local done, all = rackView.doneIds, rackView.allIds
    y = self:buttonRow(y, {
        { title = UI.say("ContextMenu_TraditionalPreservationFishMeat_RackTakeDone", tostring(#done)), enabled = #done > 0,
          tooltip = #done == 0 and rackView.waitText or nil, onClick = function() RackUI.take(playerObj, station, done) end },
        { title = UI.say("ContextMenu_TraditionalPreservationFishMeat_RackTakeAllCount", tostring(#all)), enabled = #all > 0,
          tooltip = #all > #done and getText(KEY .. "RackTakeAllHelp") or nil, onClick = function() RackUI.take(playerObj, station, all) end },
    })
    y = self:dropZone(y, getText(KEY .. (Smokehouse.isChamber(station) and "RackDropIdleChamber" or "RackDropIdle")), function(items)
        local rack, place = F.rackNow(station)
        return RackUI.dropJudge(rack, F.hangerOf(station), place, items)
    end, function(take) RackUI.hang(playerObj, station, take) end)
    self:drawNotes(y, rackView.notes)
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

-- What Rack Info's drop square makes of a dragged selection (TP Core's DropZone judge): the pieces it would hang,
-- lightest first so the most fit, by the menu's rules; the lines to show; and why the rest won't hang.
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
    if #take == 0 then return { take = take, lines = { refused or getText(KEY .. "RackFull") }, refused = refused } end
    local lines = { UI.say(KEY .. "RackDropHang", tostring(#take), tostring(#items)),
        UI.say(KEY .. "RackDropRoom", string.format("%.1f", limits.total - weight)) }
    if #take < #items then table.insert(lines, getText(KEY .. "RackDropSome")) end
    return { take = take, lines = lines, refused = #take < #items and refused or nil }
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

-- Each rack's own icon, by its hanger's name; a script item's icon by its full type.
local RACK_ICONS = { frame = "media/textures/Item_DryingFrame.png", medium = "media/textures/Item_DryingBeamMedium.png",
    large = "media/textures/Item_DryingBeamLarge.png", chamber = "media/textures/Item_SmokehouseChamber.png" }

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
