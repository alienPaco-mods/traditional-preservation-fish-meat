-- Traditional Preservation (Fish & Meat): keeps the weather totals, brings each Salting Tub's batch and each rack's
-- pieces (Drying Frame, Hanging Beam, Gantry) up to now, and shows what is in each tub and rack. SpriteOverlayConfig can't show one sprite per fish, so this reads each station
-- and layers sprites itself.
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

-- What shows in an uncovered tub: fish (nil), or the meat on top, the last put in (a tub holds fish or meat, and
-- cuts of any kind together). A leg always shows: it fills the tub.
function TraditionalPreservationFishMeatWorld.tubMeat(tub)
    local pieces = tub.pieces or {}
    local last = pieces[#pieces]
    if not last or last.kind ~= "meat" then return nil end
    for _, piece in ipairs(pieces) do
        if piece.leg then return "leg" end
    end
    return last.pork and "pork" or "meat"
end

-- The board and stone stay on until the last cured piece is taken out. Before that the top layer shows: fish or meat.
function TraditionalPreservationFishMeatWorld.tubSprite(tub)
    local stage = F.tubStage(tub)
    if stage == "Curing" or stage == "Done" then return TUB_WEIGHTED_SPRITE end
    if stage == "Packing" then
        local meat = TraditionalPreservationFishMeatWorld.tubMeat(tub)
        return meat and TUB_MEAT_SPRITES[meat] or TUB_FILLED_SPRITE
    end
    return nil
end

-- Brings a tub's batch up to now: where it stands now counts for the time since the last look, as the old crafting
-- station's did (F.pressDone). Returns the tub's record.
function TraditionalPreservationFishMeatWorld.updateTub(station)
    local tub = F.tubOf(station)
    tub.place = Weather.placeOf(station)
    F.updateTub(tub, F.getLedger(), getGameTime():getWorldAgeHours())
    return tub
end

-- place is the station's (TP Core's word; inside the Smokehouse, Smokehouse.PLACE).
-- In the Smokehouse each stack also counts the joined Stone Hearth's fire (F.smokeStep); a done cook is noted for its
-- OnUpdate to finish, and every stack's shed for OnCreate's Cold Smoked swap (F.smokeStations). Another mod's stacks
-- in the shed are its own: only counted, as they take room (others).
local function readBatch(station, craftData, modData, logic, place, smoking, fire, ledger)
    -- TP Core's place word, or the Smokehouse's. The totals each place goes by are the ledger's (F.TOTALS).
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

local function refreshTub(station, sessionState)
    local sprite = TraditionalPreservationFishMeatWorld.tubSprite(TraditionalPreservationFishMeatWorld.updateTub(station))
    showSprites(station, sessionState, tostring(sprite), sprite and { sprite + sessionState.faceIndex } or {})
end

-- A spot's tile (F.spotTile) on a rack, numbered as spot_index in tools/build_tileset.py.
function TraditionalPreservationFishMeatWorld.hangingSprite(hanger, tile, slot, faceIndex)
    return hanger.spotSprite + (tile * hanger.stacks + slot - 1) * FACE_COUNT + faceIndex
end

-- A rack: its pieces brought up to now at its place, each spot drawn by F.rackSpots (empty spots draw nothing).
local function refreshRack(station, sessionState)
    local hanger = sessionState.hanger
    local looks = F.rackSpots(F.rackNow(station), hanger)
    local sprites, signature = {}, {}
    for slot = 1, hanger.stacks do
        local look = looks[slot]
        signature[slot] = tostring(look)
        if look then table.insert(sprites, TraditionalPreservationFishMeatWorld.hangingSprite(hanger, look, slot, sessionState.faceIndex)) end
    end
    showSprites(station, sessionState, table.concat(signature, ","), sprites)
end

local function refresh(station, sessionState)
    if sessionState.tub then return refreshTub(station, sessionState) end
    if sessionState.rack then return refreshRack(station, sessionState) end
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
-- Inside the chamber's walls and roof it is always Smokehouse.PLACE (an open roof's air, still), wherever it stands.
local function newSessionState(station)
    if Smokehouse.isChamber(station) then
        return { hanger = F.CHAMBER_HANGER, faceIndex = 0, logicType = ComponentType.DryingCraftLogic,
            show = function() end, place = Smokehouse.PLACE }
    end
    local index = F.stationIndex(station)
    if not index then return nil end

    if index < FRAME_SPRITE then return { tub = true, faceIndex = index % FACE_COUNT } end
    return { rack = true, hanger = F.hangerFor(index), faceIndex = index % FACE_COUNT }
end

local sprites = {}
for _, name in ipairs(Tiles.STATIONS) do table.insert(sprites, name) end
for _, name in ipairs(CoreTiles.CHAMBERS) do table.insert(sprites, name) end

local tracker = Station.tracker({ sprites = sprites, newSessionState = newSessionState, refresh = refresh })

TraditionalPreservationFishMeatWorld.track = tracker.track

-- Redraws a tracked station now, without waiting for the next tick, e.g. after a player adds fish. A tub or a rack is
-- tracked from here on: one built this session hasn't been through the map loader.
function TraditionalPreservationFishMeatWorld.refresh(station)
    local sessionState = (F.isTub(station) or F.isRack(station)) and tracker.track(station) or tracker.sessionStateOf(station)
    if sessionState then refresh(station, sessionState) end
end

-- The stacks on a station that are past its input slots: running, or finished and not yet taken.
function TraditionalPreservationFishMeatWorld.busyStacks(station)
    local sessionState = tracker.sessionStateOf(station)
    return sessionState and sessionState.busyStacks or 0
end

-- What a drying station holds now, for its Info window: its hanger and place, the items waiting in its
-- input slots, the finished ones and their stacks, and the running batches, furthest along first, each with its
-- recipe data and progress. Either tile of a Smokehouse answers for the one with the slots, and lists this mod's
-- stacks only. Nil for a tub (its own Info window) or anything else, or before there is a player.
function TraditionalPreservationFishMeatWorld.inspect(station)
    if Smokehouse.isChamber(station) then station = Smokehouse.slotTile(station) end
    local sessionState = tracker.track(station)
    if not sessionState or sessionState.tub or sessionState.rack then return nil end
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
