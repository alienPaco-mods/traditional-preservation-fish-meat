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

-- One action a piece (false: an action with none); carry is brought into the inventory first (the board and stone).
local function queue(playerObj, station, mode, items, carry, method)
    if not ISEntityUI.WalkToEntity(playerObj, station) then return end
    for _, item in ipairs(carry or {}) do ISInventoryPaneContextMenu.transferIfNeeded(playerObj, item) end
    for _, item in ipairs(items or { false }) do
        if item then ISInventoryPaneContextMenu.transferIfNeeded(playerObj, item) end
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

-- The temperature the tub's cure goes by at its place (the ledger's tubCure totals): the day's in the open, the
-- season's under a roof or in the Smokehouse, Core's figure in a room, a loft or a basement.
local function tubTemperature(ledger, place)
    if place == "Open" then return ledger.temperature or 0 end
    if place == "Sheltered" or place == "Loft" or place == "Basement" then return F.ownTemperature(ledger, place) end
    return ledger.seasonTemperature or ledger.temperature or 0
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

-- Tub Info: the stage, what is in it, the place and its heat, the cure and what a warm one takes, kept up to date
-- while open.
local CURE_COLOUR, SLOW_COLOUR = { 0.35, 0.6, 0.3 }, { 0.75, 0.55, 0.2 }
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

function TubWindow:refresh()
    local tub = tubNow(self.station)
    self.tubView = { tub = tub, status = statusOf(tub) }
end

function TubWindow:render()
    ISCollapsableWindow.render(self)
    if self.isCollapsed or not self.tubView then return end
    local tub, status = self.tubView.tub, self.tubView.status
    local y = self:top()
    y = self:row(y, KEY .. "TubInfoStage", stageText(tub))
    y = self:row(y, KEY .. "InfoHolds", contentsText(tub))
    y = self:row(y, KEY .. "Place", UI.placeText(status.place, status.temperature))
    local notes = {}
    if status.stage == "Curing" then
        local slow = status.spoiling or not status.hoursLeft
        y = self:bar(y, METHOD_NAMES[tub.method], status.progress, slow and SLOW_COLOUR or CURE_COLOUR, UI.percent(status.progress))
        y = self:row(y, KEY .. "TubInfoSpeed", UI.percent(status.rate))
        if status.spoiling or status.spoiled > 0 then
            table.insert(notes, say(status.spoiling and KEY .. "SpoilingWarmCure" or KEY .. "Spoiled", UI.percent(status.spoiled)))
        end
    elseif status.stage == "Done" and (tub.spoiled or 0) > 0 then
        table.insert(notes, say(KEY .. "Spoiled", UI.percent(tub.spoiled)))
    end
    y = self:row(y, KEY .. "TubInfoNext", nextText(tub, status))
    table.insert(notes, getText(KEY .. "TubNote" .. status.stage))
    self:drawNotes(y, notes)
end

-- Clicking a tub opens Tub Info, as clicking a door opens it.
InfoWindow.clickOpens(F.isTub, function(playerObj, station)
    if TraditionalPreservationFishMeatWorld then TraditionalPreservationFishMeatWorld.track(station) end
    TubWindow.open(playerObj, station)
end)

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
