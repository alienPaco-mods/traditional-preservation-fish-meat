-- Traditional Preservation (Fish & Meat): the Salting Tub's right-click menu (put fish or meat in, unpack, the three
-- start rows, take the cured pieces out) and its Info window (TP Core's InfoWindow), opened from the menu or by
-- clicking the tub. The rules are TraditionalPreservationFishMeatTub.lua's; the hand jobs TPFMSaltingTub's.
local UI = require "TraditionalPreservationCore/UI"
local InfoWindow = require "TraditionalPreservationCore/InfoWindow"
local Uses = require "TraditionalPreservationCore/Uses"
local F = TraditionalPreservationFishMeat

local say = UI.say
local tooltipFor, refuse, findItems = UI.tooltip, UI.refuse, UI.findItems
local KEY = "IGUI_TraditionalPreservationFishMeat_"
local MENU = "ContextMenu_TraditionalPreservationFishMeat_"
local TUB_ICON = "media/textures/Item_SaltingTub.png"
-- What each start row gives, for its icon.
local START_ITEMS = { fish = F.PRESSED_FISH, corn = F.CURED_MEAT, long = F.CURED_MEAT }
-- Refusals with a key of their own elsewhere in the mod; the rest are Tub<refusal>.
local REFUSAL_KEYS = { CharqueOff = KEY .. "CharqueOff", Mixed = KEY .. "MixedTub", Full = KEY .. "Full",
    LegNeedsLongCure = KEY .. "LegNeedsLongCure", HotOnlyShortCure = KEY .. "HotOnlyShortCure" }
local TubWindow -- the info window, below the menu
TraditionalPreservationFishMeatTubUI = {}
local TubUI = TraditionalPreservationFishMeatTubUI

-- An item type's icon.
local function iconOf(fullType)
    local script = ScriptManager.instance:getItem(fullType)
    return script and script:getNormalTexture()
end

local function refusalText(refusal, tub)
    return say(REFUSAL_KEYS[refusal] or KEY .. "Tub" .. refusal, F.tubSalt(tub), F.MIN_SLICE_WEIGHT, F.SALT_WHOLE_MAX)
end

local function tubNow(station)
    if TraditionalPreservationFishMeatWorld then return TraditionalPreservationFishMeatWorld.updateTub(station) end
    return F.tubOf(station)
end

-- One action a piece (false: an action with none). Everything is moved into the inventory first (carry: the
-- board and stone), then the walk, then the actions: vanilla's order.
local function queue(playerObj, station, mode, items, carry, method)
    for _, item in ipairs(carry or {}) do ISInventoryPaneContextMenu.transferIfNeeded(playerObj, item) end
    for _, item in ipairs(items or {}) do
        if item then ISInventoryPaneContextMenu.transferIfNeeded(playerObj, item) end
    end
    if not UI.walkTo(playerObj, station) then return end
    for _, item in ipairs(items or { false }) do
        ISTimedActionQueue.add(TPFMSaltingTub:new(playerObj, station, mode, item or nil, method))
    end
end

-- What is in reach that the tub could take, by type, oldest first, with the first reason a type is refused anywhere
-- (a whole fish to gut, one to split). Spoilt pieces are left out.
local function piecesByType(playerObj)
    local byType, order = {}, {}
    local found = findItems(playerObj, function(item)
        return instanceof(item, "Food") and F.tubKindOf(item) ~= nil and F.tubItemRefusal(item) ~= "Spoilt"
    end)
    for _, item in ipairs(found) do
        local fullType = item:getFullType()
        local row = byType[fullType]
        if not row then
            row = { fullType = fullType, pieces = {}, refused = {} }
            byType[fullType] = row
            table.insert(order, row)
        end
        local refusal = F.tubItemRefusal(item)
        table.insert(refusal and row.refused or row.pieces, refusal or item)
    end
    for _, row in ipairs(order) do table.sort(row.pieces, function(a, b) return a:getAge() > b:getAge() end) end
    return order
end

-- As many of these as the tub takes now, in order: by count and weight.
local function fitting(tub, pieces)
    local count, weight, fit = F.tubCount(tub), F.tubWeight(tub), {}
    for _, item in ipairs(pieces) do
        local itemWeight = F.packedWeight(item)
        if count >= F.TUB_MAX_ITEMS then break end
        if F.hasRoom(F.TUB_CAPACITY, weight, itemWeight) then
            table.insert(fit, item)
            count, weight = count + 1, weight + itemWeight
        end
    end
    return fit
end

-- One row a type held: All (as many as fit) and One, or in red with the reason.
local function addPutRow(menu, playerObj, station, tub, row)
    local label = say(MENU .. "TubPut", getItemNameFromFullType(row.fullType))
    local option = menu:addOption(label)
    option.iconTexture = iconOf(row.fullType)
    if #row.pieces == 0 then return refuse(option, refusalText(row.refused[1], tub)) end
    local refusal = F.tubRefusal(tub, F.tubKindOf(row.pieces[1]), F.packedWeight(row.pieces[1]))
    if refusal then return refuse(option, refusalText(refusal, tub)) end
    local fit = fitting(tub, row.pieces)
    local sub = menu:getNew(menu)
    menu:addSubMenu(option, sub)
    if #fit > 1 then
        sub:addOption(say(MENU .. "TubAll", #fit), playerObj, queue, station, "put", fit)
    end
    sub:addOption(getText(MENU .. "TubOne"), playerObj, queue, station, "put", { fit[1] })
    if #row.refused > 0 then tooltipFor(option, refusalText(row.refused[1], tub)) end
end

-- The board and stone in reach, and the salt's uses.
local function startKit(playerObj)
    local function first(fullType)
        return findItems(playerObj, function(item) return item:getFullType() == fullType end)[1]
    end
    return { board = first(F.TUB_BOARD), stone = first(F.TUB_STONE), salt = Uses.count(playerObj, ItemTag.SALT) }
end

local function onStart(playerObj, station, method, kit)
    queue(playerObj, station, "start", nil, { kit.board, kit.stone }, method)
end

local function addStartRows(menu, playerObj, station, tub)
    local kit = startKit(playerObj)
    for _, method in ipairs(F.TUB_METHODS) do
        local option = menu:addOption(say(MENU .. "TubStart_" .. method, F.tubSalt(tub)), playerObj, onStart, station, method, kit)
        option.iconTexture = iconOf(START_ITEMS[method])
        local refusal = F.startRefusal(tub, method, kit)
        if refusal then
            refuse(option, refusalText(refusal, tub))
        else
            tooltipFor(option, say(KEY .. "TubStartHelp_" .. method, UI.hoursText(F.tubHours(tub, method))))
        end
    end
end

local function addTakeRow(menu, playerObj, station, tub)
    local left = F.tubCount(tub)
    local option = menu:addOption(say(MENU .. "TubTake", left))
    option.iconTexture = iconOf(START_ITEMS[tub.method])
    local sub = menu:getNew(menu)
    menu:addSubMenu(option, sub)
    if left > 1 then
        local all = {}
        for i = 1, left do all[i] = false end
        sub:addOption(say(MENU .. "TubAll", left), playerObj, queue, station, "take", all)
    end
    sub:addOption(getText(MENU .. "TubOne"), playerObj, queue, station, "take", { false })
end

-- The temperature the tub's cure goes by at its place (the ledger's tubCure totals): the hour's in the open, under a
-- roof or in the Smokehouse, Core's figure in a room or a basement.
local function tubTemperature(ledger, place)
    if place == "Sheltered" or place == "AiredRoom" or place == "Basement" then return F.ownTemperature(ledger, place) end
    return ledger.temperature or 0
end

local function stageText(tub)
    return getText(KEY .. "TubStage" .. F.tubStage(tub))
end

local function contentsText(tub)
    if F.tubStage(tub) == "Empty" then return getText(KEY .. "InfoEmpty") end
    return say(KEY .. "TubContents_" .. tub.kind, F.tubCount(tub), string.format("%.1f", F.tubWeight(tub)), F.TUB_CAPACITY)
end

local function statusOf(tub)
    local ledger = F.getLedger()
    local place = F.placeWord(tub)
    local status = { place = place, temperature = tubTemperature(ledger, place), stage = F.tubStage(tub) }
    if status.stage == "Curing" then
        for key, value in pairs(F.pressStatus(tub, ledger)) do status[key] = value end
    end
    return status
end

-- What happens next and when, for the menu's hover and the window.
local function nextText(tub, status)
    if status.stage == "Curing" then
        if not status.hoursLeft then return getText(KEY .. "Paused") end
        return say(KEY .. "TubReadyIn", UI.durationText(status.hoursLeft))
    end
    return say(KEY .. "TubHelp" .. status.stage, F.tubSalt(tub))
end

local function addTubMenu(context, playerObj, station)
    local tub = tubNow(station)
    local stage = F.tubStage(tub)
    local option = context:addOption(getText("IGUI_CraftingWindow_SaltingTub"))
    option.iconTexture = getTexture(TUB_ICON)
    local menu = context:getNew(context)
    context:addSubMenu(option, menu)

    local status = statusOf(tub)
    local statusOption = menu:addOption(stageText(tub) .. ": " .. contentsText(tub))
    statusOption.isDisabled = true
    tooltipFor(statusOption, UI.placeText(status.place, status.temperature) .. " <LINE> " .. nextText(tub, status))
    local info = menu:addOption(getText(MENU .. "TubInfo"), playerObj, TubWindow.open, station)
    info.iconTexture = getTexture(TUB_ICON)
    UI.topInfo(context, getText(MENU .. "TubInfo"), getTexture(TUB_ICON), playerObj, TubWindow.open, station)

    if stage == "Empty" or stage == "Packing" then
        local rows = piecesByType(playerObj)
        for _, row in ipairs(rows) do addPutRow(menu, playerObj, station, tub, row) end
        if #rows == 0 then refuse(menu:addOption(getText(MENU .. "TubPutNothing")), getText(KEY .. "TubNoneCarried")) end
        if stage == "Packing" then
            addStartRows(menu, playerObj, station, tub)
            local unpack = menu:addOption(getText(MENU .. "TubUnpack"), playerObj, queue, station, "unpack", nil)
            tooltipFor(unpack, getText(KEY .. "TubUnpackHelp"))
        end
    elseif stage == "Done" then
        addTakeRow(menu, playerObj, station, tub)
    end
end

-- Salting Tub Info (all_info_mock): a band with the tub's state, the place, what it holds as cells with a line of
-- history beside them (what is dragged onto them goes in while it is packing), the cure's bar while it runs, then
-- notes. Kept up to date while open.
local CURE_COLOUR, SLOW_COLOUR = { 0.35, 0.6, 0.3 }, { 0.75, 0.55, 0.2 }
local LOAD_COLOUR = { 0.59, 0.51, 0.39 }
-- The cells' pattern by what the tub holds (tools/cell_patterns.py in TP Core).
local PATTERNS = { fish = "media/textures/TPCell_Fish.png", meat = "media/textures/TPCell_Meat.png" }
local METHOD_NAMES = { fish = KEY .. "InfoCure", corn = KEY .. "InfoCorn", long = KEY .. "InfoLongCure" }

TubWindow = InfoWindow:derive("TraditionalPreservationFishMeatTubWindow")

function TubWindow:new(playerObj, station)
    local o = InfoWindow.new(self, playerObj, station)
    o.title = getText("IGUI_CraftingWindow_SaltingTub")
    return o
end

function TubWindow.open(playerObj, station)
    InfoWindow.open(TubWindow, playerObj, station)
end

-- The band: empty, packing, spoiling, paused, curing or cured; the worst first. Returns the word's key, the finished
-- text and the colours.
function TubUI.band(tub, status)
    local stage = status.stage
    if stage == "Empty" then
        return KEY .. "TubStageEmpty", getText(KEY .. "TubBandEmptyText"), InfoWindow.BAND_IDLE
    elseif stage == "Packing" then
        return KEY .. "TubStagePacking", say(KEY .. "TubBandPackingText", F.tubSalt(tub)), InfoWindow.BAND_WAITING
    elseif stage == "Done" then
        return KEY .. "TubStageDone", say(KEY .. "TubBandDoneText", F.tubCount(tub)), InfoWindow.BAND_WORKING
    end
    if status.spoiling then
        return KEY .. "TubBandSpoiling", say(KEY .. "TubBandSpoilingText", UI.percent(status.spoiled)), InfoWindow.BAND_AT_RISK
    end
    if not status.hoursLeft then
        return KEY .. "Paused", getText(KEY .. "TubBandPausedText"), InfoWindow.BAND_WAITING
    end
    return KEY .. "TubStageCuring", say(KEY .. "TubBandCuringText", UI.durationText(status.hoursLeft)), InfoWindow.BAND_WORKING
end

-- The share of the tub taken: by weight or by count, whichever is fuller.
local function fullShare(count, weight)
    return math.max(count / F.TUB_MAX_ITEMS, weight / F.TUB_CAPACITY)
end

-- What is dragged onto the tub's cells: the pieces it takes now, in order, as Put in Tub would (one kind, room by
-- count and weight), with the first reason a piece is left out. Returns DropZone's { take, lines, refused } and
-- cells, the cells the pieces would fill.
function TubUI.judgeDrop(tub, items)
    local judged = { take = {}, lines = {} }
    local stage = F.tubStage(tub)
    local kind, count, weight = tub.kind, F.tubCount(tub), F.tubWeight(tub)
    local refusal
    for _, item in ipairs(items) do
        local why = (stage ~= "Empty" and stage ~= "Packing") and "Busy" or F.tubItemRefusal(item)
        local itemKind, itemWeight = nil, 0
        if not why then
            itemKind, itemWeight = F.tubKindOf(item), F.packedWeight(item)
            if kind and kind ~= itemKind then why = "Mixed"
            elseif count >= F.TUB_MAX_ITEMS or not F.hasRoom(F.TUB_CAPACITY, weight, itemWeight) then why = "Full" end
        end
        if why then
            refusal = refusal or why
        else
            table.insert(judged.take, item)
            kind, count, weight = itemKind, count + 1, weight + itemWeight
        end
    end
    local Holds = require "TraditionalPreservationCore/Holds"
    judged.cells = Holds.filledCells({ share = fullShare(count, weight) })
        - Holds.filledCells({ share = fullShare(F.tubCount(tub), F.tubWeight(tub)) })
    if #judged.take > 0 then
        table.insert(judged.lines, say(KEY .. "TubDropPut", #judged.take))
        judged.pattern = PATTERNS[kind]
    end
    if refusal then
        judged.refused = refusalText(refusal, tub)
        if #judged.take == 0 then judged.lines = { judged.refused } end
    end
    return judged
end

local function tubDrop(window)
    local function judge(items) return TubUI.judgeDrop(tubNow(window.station), items) end
    local function drop(take) queue(window.playerObj, window.station, "put", take) end
    return { judge = judge, drop = drop }
end

-- The cells: what the tub holds, by count and weight, the drop while it is packing.
function TubUI.holding(tub, drop)
    local count, weight, stage = F.tubCount(tub), F.tubWeight(tub), F.tubStage(tub)
    local kind = tub.kind or "empty"
    return { kind = "cells", name = getText(KEY .. "TubHoldsName_" .. kind),
        amount = stage == "Empty" and getText(KEY .. "TubHoldsNone") or say(KEY .. "TubHoldsCount_" .. kind, count),
        state = say(KEY .. "TubHoldsWeight", string.format("%.1f", weight), F.TUB_CAPACITY),
        share = fullShare(count, weight), colour = LOAD_COLOUR, pattern = PATTERNS[tub.kind],
        drop = (stage == "Empty" or stage == "Packing") and drop or nil }
end

-- The window's buttons (tub_buttons_mock B): while packing, the start rows for what is in the tub (greyed with the
-- reason, as the menu's) and Unpack (n); once cured, Take One and Take All (n). act(mode, pieces, method) does it.
local RETURNED_ICON = "media/ui/Entity/Icon_Returned_48x48.png"

function TubUI.buttons(tub, kit, act)
    local stage, left = F.tubStage(tub), F.tubCount(tub)
    local buttons = {}
    if stage == "Packing" then
        for _, method in ipairs(F.TUB_METHODS) do
            if F.TUB_METHOD[method].kind == tub.kind then
                local refusal = F.startRefusal(tub, method, kit)
                table.insert(buttons, { title = getText(KEY .. "TubButtonStart_" .. method), icon = iconOf(START_ITEMS[method]),
                    enabled = refusal == nil, tooltip = refusal and refusalText(refusal, tub)
                        or say(KEY .. "TubStartHelp_" .. method, UI.hoursText(F.tubHours(tub, method))),
                    onClick = function() act("start", nil, method) end })
            end
        end
        table.insert(buttons, { title = say(KEY .. "TubButtonUnpack", left), icon = RETURNED_ICON, enabled = true,
            tooltip = getText(KEY .. "TubUnpackHelp"), onClick = function() act("unpack") end })
    elseif stage == "Done" then
        local icon, all = iconOf(START_ITEMS[tub.method]), {}
        for i = 1, left do all[i] = false end
        table.insert(buttons, { title = getText(KEY .. "TubButtonOne"), icon = icon, enabled = left > 0,
            onClick = function() act("take", { false }) end })
        table.insert(buttons, { title = say(KEY .. "TubButtonAll", left), icon = icon, enabled = left > 0,
            onClick = function() act("take", all) end })
    end
    return buttons
end

function TubWindow:tubButtons(y)
    local playerObj, station = self.playerObj, self.station
    local buttons = TubUI.buttons(self.tubView.tub, self.tubView.kit, function(mode, pieces, method)
        if mode == "start" then return onStart(playerObj, station, method, startKit(playerObj)) end
        queue(playerObj, station, mode, pieces)
    end)
    return self:buttonRow(y, buttons)
end

function TubWindow:refresh()
    local tub = tubNow(self.station)
    self.tubView = { tub = tub, status = statusOf(tub), kit = F.tubStage(tub) == "Packing" and startKit(self.playerObj) or {} }
    self.drop = self.drop or tubDrop(self)
end

function TubWindow:render()
    ISCollapsableWindow.render(self)
    if self.isCollapsed or not self.tubView then return end
    local tub, status = self.tubView.tub, self.tubView.status
    local word, text, look = TubUI.band(tub, status)
    local y = self:band(getText(word), text, look[1], look[2])
    y = self:section(y, "IGUI_TraditionalPreservationCore_SectionStation")
    y = self:placeRow(y, KEY .. "Place", status.place, status.temperature)
    y = self:section(y, "IGUI_TraditionalPreservationCore_SectionHolds")
    y = self:holds(y, { TubUI.holding(tub, self.drop) }, getText(KEY .. "TubLore_" .. (tub.kind or "fish")))
    y = self:tubButtons(y)
    local notes = {}
    if status.stage == "Curing" then
        local slow = status.spoiling or not status.hoursLeft
        y = self:section(y, "IGUI_TraditionalPreservationCore_SectionWorking")
        y = self:bar(y, METHOD_NAMES[tub.method], status.progress, slow and SLOW_COLOUR or CURE_COLOUR,
            say(KEY .. "TubBarText", UI.percent(status.progress), UI.percent(status.rate)))
        if status.spoiling or status.spoiled > 0 then
            table.insert(notes, say(status.spoiling and KEY .. "SpoilingWarmCure" or KEY .. "Spoiled", UI.percent(status.spoiled)))
        end
    elseif status.stage == "Done" and (tub.spoiled or 0) > 0 then
        table.insert(notes, say(KEY .. "Spoiled", UI.percent(tub.spoiled)))
    end
    if status.stage == "Empty" or status.stage == "Packing" then table.insert(notes, getText(KEY .. "TubNoteDrag")) end
    table.insert(notes, getText(KEY .. "TubNote" .. status.stage))
    self:drawNotes(y, notes)
end

-- Clicking a tub opens Tub Info, as clicking a door opens it.
local function onFillContextMenu(playerNum, context, worldobjects, test)
    local seen = {}
    for _, isoObject in ipairs(worldobjects) do
        if F.isTub(isoObject) and not seen[isoObject] then
            -- Vanilla's probe for a controller's prompt: say there is a menu, do no work.
            if test then return ISWorldObjectContextMenu.setTest() end
            seen[isoObject] = true
            -- A tub built or placed this session isn't tracked until its area reloads, so its menu starts it.
            if TraditionalPreservationFishMeatWorld then TraditionalPreservationFishMeatWorld.track(isoObject) end
            addTubMenu(context, getSpecificPlayer(playerNum), isoObject)
        end
    end
end

Events.OnFillWorldObjectContextMenu.Add(onFillContextMenu)
