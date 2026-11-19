-- Traditional Preservation (Fish & Meat): keeps the weather totals, brings each Salting Tub's batch and the pieces on
-- each rack (Drying Frame, Hanging Beam, Gantry) and in each Smokehouse up to now, and shows what is in each tub and
-- rack. SpriteOverlayConfig can't show one sprite per fish, so this reads each station and layers sprites itself.
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

-- TP Core's Smokehouse: its pieces brought up to now (F.rackNow: its place and the joined Stone Hearth's fire) on the
-- back left tile, the one that keeps the record (Smokehouse.recordTile), so the shed steps once. It is closed: Core
-- draws its look, the door's finished pieces from this mod's count (Smokehouse.countsFinished).
local function refreshChamber(station)
    local _, part, col = Smokehouse.tileOf(station)
    if part == 0 and col == 0 then F.rackNow(station) end
end

local function refresh(station, sessionState)
    if sessionState.tub then return refreshTub(station, sessionState) end
    if sessionState.chamber then return refreshChamber(station) end
    return refreshRack(station, sessionState)
end

local function newSessionState(station)
    if Smokehouse.isChamber(station) then return { chamber = true } end
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

-- Redraws a tracked station now, without waiting for the next tick, e.g. after a player hangs a piece. One built this
-- session is tracked from here on: it hasn't been through the map loader.
function TraditionalPreservationFishMeatWorld.refresh(station)
    local sessionState = F.isStation(station) and tracker.track(station) or tracker.sessionStateOf(station)
    if sessionState then refresh(station, sessionState) end
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
