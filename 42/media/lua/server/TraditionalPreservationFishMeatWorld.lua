-- Traditional Preservation (Fish & Meat): keeps the weather totals, and shows what is in each tub and frame.
-- SpriteOverlayConfig can't show a tub waiting to start or one sprite per fish, so this reads
-- each station and layers sprites itself.
if isClient() then return end

TraditionalPreservationFishMeatWorld = TraditionalPreservationFishMeatWorld or {}
local Station = require "TraditionalPreservationCore/Station"
local Weather = require "TraditionalPreservationCore/Weather"
local Smokehouse = require "TraditionalPreservationCore/Smokehouse"
local Tiles = require "TraditionalPreservationFishMeat/Tiles"
local CoreTiles = require "TraditionalPreservationCore/Tiles"
local F = TraditionalPreservationFishMeat

local FACE_COUNT = Tiles.FACE_COUNT

local TUB_FILLED_SPRITE, TUB_WEIGHTED_SPRITE, TUB_MEAT_SPRITES = Tiles.TUB_FILLED, Tiles.TUB_WEIGHTED, Tiles.TUB_MEAT
local FRAME_SPRITE = Tiles.FRAME
local STAGE_FRESH = 0

-- Furthest along first; two stacks as far along go by when they were hung, so the order (and the sprites) never
-- depends on the order the engine lists them in (rule 9).
local function furthestFirst(a, b)
    if a.progress ~= b.progress then return a.progress > b.progress end
    return (a.stackId or 0) < (b.stackId or 0)
end

-- How many fish, how many stacks, each stack's style, and the items in slot order (the last in last). Finished dry cured meat still hanging (hangingSince, the
-- hour) ages faster as it is counted (F.ageHanging). rotten[n] is true when any piece of the nth stack has rotted.
local function countItems(resources, group, io, hangingSince)
    local count, stacks = 0, 0
    local seen, styles, all, rotten = {}, {}, {}, {}
    local items = Station.itemSlots(resources, group, io)
    for i = 0, items:size() - 1 do
        local stored = items:get(i):getStoredItems()
        count = count + stored:size()
        for j = 0, stored:size() - 1 do
            table.insert(all, stored:get(j))
            if hangingSince then F.ageHanging(stored:get(j), hangingSince) end
            local stackId = tostring(stored:get(j):getModData().stackId)
            if not seen[stackId] then
                stacks = stacks + 1
                seen[stackId] = stacks
                table.insert(styles, F.fishStyle(stored:get(j)))
            end
            if stored:get(j):isRotten() then rotten[seen[stackId]] = true end
        end
    end
    return count, stacks, styles, all, rotten
end

-- One sprite per stack. Driest first: finished stacks, then running ones by progress, then the
-- stack waiting to start. Each style has its own run of stages. A rotted stack shows its rotten look
-- (F.FIRST_ROTTEN_LOOK on): a running one when it is lost as a whole, a finished one when any piece in it rotted.
function TraditionalPreservationFishMeatWorld.stackLooks(waitingStyle, batches, finishedStyles, finishedRotten)
    local stages = F.DRYING_STAGES
    local looks = {}
    for n, style in ipairs(finishedStyles) do
        local rotten = finishedRotten and finishedRotten[n]
        table.insert(looks, rotten and F.FIRST_ROTTEN_LOOK + F.rottenLook(style) or style * stages + stages - 1)
    end

    table.sort(batches, furthestFirst)
    for _, batch in ipairs(batches) do
        table.insert(looks, batch.rotten and F.FIRST_ROTTEN_LOOK + F.rottenLook(batch.style)
            or batch.style * stages + F.dryingStage(batch.progress))
    end

    if waitingStyle then table.insert(looks, waitingStyle * stages + STAGE_FRESH) end
    return looks
end

-- What shows in an uncovered tub: fish (nil), or the meat on top, the last put in (a tub holds fish or meat, and
-- cuts of any kind together). A leg always shows: it fills the tub.
function TraditionalPreservationFishMeatWorld.tubMeat(items)
    local last = items[#items]
    if not last or not F.isMeatStage(last:getFullType()) then return nil end
    for _, item in ipairs(items) do
        if F.isLeg(item) then return "leg" end
    end
    return F.isPork(last) and "pork" or "meat"
end

-- The board and stones stay on until the pressed fish is taken out. Before that the top layer shows: fish or meat.
function TraditionalPreservationFishMeatWorld.tubSprite(waiting, batches, finished, meat)
    if #batches > 0 or finished > 0 then return TUB_WEIGHTED_SPRITE end
    if waiting > 0 then return meat and TUB_MEAT_SPRITES[meat] or TUB_FILLED_SPRITE end
    return nil
end

-- place is the station's (TP Core's word, the Smokehouse Enclosed).
-- In the Smokehouse each stack also counts the joined Stone Hearth's fire (F.smokeStep); a done cook is noted for its
-- OnUpdate to finish, and every stack's shed for OnCreate's Cold Smoked swap (F.smokeStations). Another mod's stacks
-- in the shed are its own: only counted, as they take room (others).
local function readBatch(station, craftData, modData, logic, place, smoking, fire, ledger)
    -- TP Core's place word: the Smokehouse is Enclosed. The totals each place goes by are the ledger's (F.TOTALS).
    modData.place = place
    if modData.stackId then F.stackStations[modData.stackId] = station end
    if smoking then
        F.smokeStep(modData, fire, ledger)
        if modData.stackId then F.smokeStations[modData.stackId] = station end
        if F.hotDone(modData) then F.hotStations[modData.stackId] = station end
    end
    return { progress = logic:getProgress(craftData), style = modData.style or F.STYLE_SALT, rotten = F.stackRotten(modData),
        stackId = modData.stackId }
end

local function readBatches(station, sessionState, logic, uiLogic, place)
    local batches, others = {}, 0
    local smoking = sessionState.hanger and sessionState.hanger.closed
    local fire = smoking and Smokehouse.fireOf(station)
    local ledger = smoking and F.getLedger()
    for craftData, _ in pairs(uiLogic:getItemsInProgress()) do
        local modData = craftData:getModData()
        if smoking and not F.ownsStack(modData) then
            others = others + 1
        else
            table.insert(batches, readBatch(station, craftData, modData, logic, place, smoking, fire, ledger))
        end
    end
    return batches, others
end

local function showSprites(station, sessionState, signature, sprites)
    local names = {}
    for slot, index in ipairs(sprites) do names[slot] = F.spriteName(index) end
    Station.showSprites(station, sessionState, signature, names)
end

local function refreshTub(tub, sessionState, faceIndex, waiting, _, batches, finishedStyles, waitingItems)
    local sprite = TraditionalPreservationFishMeatWorld.tubSprite(waiting, batches, #finishedStyles,
        TraditionalPreservationFishMeatWorld.tubMeat(waitingItems))
    showSprites(tub, sessionState, tostring(sprite), sprite and { sprite + faceIndex } or {})
end

-- The same numbering as fish_index in tools/build_tileset.py. Meat has its own run of tiles, one per stage, and
-- rotted stacks theirs, one per rotten look.
function TraditionalPreservationFishMeatWorld.hangingSprite(hanger, look, slot, faceIndex)
    local first = hanger.fishSprite
    local firstMeatLook = F.STYLE_MEAT * F.DRYING_STAGES
    if look >= F.FIRST_ROTTEN_LOOK then
        first, look = hanger.rottenSprite, look - F.FIRST_ROTTEN_LOOK
    elseif look >= firstMeatLook then
        first, look = hanger.meatSprite, look - firstMeatLook
    end
    return first + (look * hanger.stacks + slot - 1) * FACE_COUNT + faceIndex
end

local function refreshFrame(frame, sessionState, faceIndex, _, waitingStyle, batches, finishedStyles, _, finishedRotten)
    local looks = TraditionalPreservationFishMeatWorld.stackLooks(waitingStyle, batches, finishedStyles, finishedRotten)
    local sprites = {}
    for slot, look in ipairs(looks) do
        table.insert(sprites, TraditionalPreservationFishMeatWorld.hangingSprite(sessionState.hanger, look, slot, faceIndex))
    end
    showSprites(frame, sessionState, table.concat(looks, ","), sprites)
end

local function refresh(station, sessionState)
    local resources = station:getComponent(ComponentType.Resources)
    local logic = station:getComponent(sessionState.logicType)
    local sprite = station:getSprite()
    if not resources or not logic or not sprite then return end
    local uiLogic = Station.uiLogic(station, sessionState, logic)
    if not uiLogic then return end

    local waiting, _, waitingStyles, waitingItems = countItems(resources, logic:getInputsGroupName(), ResourceIO.Input)
    local _, finishedStacks, finishedStyles, _, finishedRotten = countItems(resources, logic:getOutputsGroupName(), ResourceIO.Output,
        sessionState.hanger and getGameTime():getWorldAgeHours())
    local batches, others = readBatches(station, sessionState, logic, uiLogic, sessionState.place or Weather.placeOf(station))
    sessionState.busyStacks = finishedStacks + #batches + others
    sessionState.show(station, sessionState, sessionState.faceIndex, waiting, waitingStyles[1], batches, finishedStyles, waitingItems, finishedRotten)
end

-- TP Core's Smokehouse is tracked here too, for this mod's stacks in it: Core draws its look and sets its recipe tag.
-- Inside the chamber's walls and roof it is always Enclosed (TP Core's shed in the outside air), wherever it stands.
local function newSessionState(station)
    if Smokehouse.isChamber(station) then
        return { hanger = F.CHAMBER_HANGER, faceIndex = 0, logicType = ComponentType.DryingCraftLogic,
            show = function() end, place = "Enclosed" }
    end
    local index = F.stationIndex(station)
    if not index then return nil end

    local isFrame = index >= FRAME_SPRITE
    return {
        hanger = F.hangerFor(index),
        faceIndex = index % FACE_COUNT,
        logicType = isFrame and ComponentType.DryingCraftLogic or ComponentType.CraftLogic,
        show = isFrame and refreshFrame or refreshTub,
    }
end

local sprites = {}
for _, name in ipairs(Tiles.STATIONS) do table.insert(sprites, name) end
for _, name in ipairs(CoreTiles.CHAMBERS) do table.insert(sprites, name) end

local tracker = Station.tracker({ sprites = sprites, newSessionState = newSessionState, refresh = refresh })

TraditionalPreservationFishMeatWorld.track = tracker.track

-- Redraws a tracked station now, without waiting for the next tick, e.g. after a player adds fish.
function TraditionalPreservationFishMeatWorld.refresh(station)
    local sessionState = tracker.sessionStateOf(station)
    if sessionState then refresh(station, sessionState) end
end

-- The stacks on a station that are past its input slots: running, or finished and not yet taken.
function TraditionalPreservationFishMeatWorld.busyStacks(station)
    local sessionState = tracker.sessionStateOf(station)
    return sessionState and sessionState.busyStacks or 0
end

-- What a station holds now, for its Info window: its hanger (nil for a tub) and place, the items waiting in its
-- input slots, the finished ones and their stacks, and the running batches, furthest along first, each with its
-- recipe data and progress. Either tile of a Smokehouse answers for the one with the slots, and lists this mod's
-- stacks only. Nil for anything else, or before there is a player.
function TraditionalPreservationFishMeatWorld.inspect(station)
    if Smokehouse.isChamber(station) then station = Smokehouse.slotTile(station) end
    local sessionState = tracker.track(station)
    if not sessionState then return nil end
    local resources = station:getComponent(ComponentType.Resources)
    local logic = station:getComponent(sessionState.logicType)
    local uiLogic = resources and logic and Station.uiLogic(station, sessionState, logic)
    if not uiLogic then return nil end

    local _, _, _, waiting = countItems(resources, logic:getInputsGroupName(), ResourceIO.Input)
    local finished, finishedStacks = countItems(resources, logic:getOutputsGroupName(), ResourceIO.Output)
    local batches = {}
    local closed = sessionState.hanger and sessionState.hanger.closed
    for craftData, _ in pairs(uiLogic:getItemsInProgress()) do
        if not closed or F.ownsStack(craftData:getModData()) then
            table.insert(batches, { craftRecipeData = craftData, progress = logic:getProgress(craftData),
                stackId = craftData:getModData().stackId })
        end
    end
    table.sort(batches, furthestFirst)
    return { station = station, hanger = sessionState.hanger, place = sessionState.place or Weather.placeOf(station),
        waiting = waiting, finished = finished, finishedStacks = finishedStacks, batches = batches }
end

Weather.onReading(function(now, climate)
    F.advance(F.getLedger(), now, {
        temperature = climate:getTemperature(),
        humidity = climate:getHumidity(),
        precipitation = climate:getPrecipitationIntensity(),
        isSnow = climate:getPrecipitationIsSnow(),
        wind = climate:getWindIntensity(),
    })
    F.recordPotted(now, climate:getTemperature())
    F.recordBlood(now, climate:getTemperature())
end)


tracker.start()
