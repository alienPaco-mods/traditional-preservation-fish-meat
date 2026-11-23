-- Checks fishing by season (TraditionalPreservationFishMeatFishing.lua): vanilla's bite factor by the air is replaced
-- by one by TP Core's season temperature, vanilla's hot-air slump still counts, the sandbox off leaves vanilla's, and
-- the wrap reaches the nested Fishing.Utils. Run from the mod folder: luajit tests/test_fishing.lua
local H = dofile((os.getenv("TPCORE") or "../TraditionalPreservationCore") .. "/tests/harness.lua")
local check, near = H.check, H.near
H.useModPaths()
H.installClock(0)
H.installModData()
H.installEvents()
ItemTag = { UNCUT_FISH = "uncut", FISH_MEAT = "fishmeat" }

-- Vanilla's own rule (Fishing.Utils.getTemperatureParams, 42.22), the air where the player stands as player.air.
local function vanillaParams(player)
    local temperature, coeff = player.air, 1
    if temperature >= 30 and temperature < 40 or temperature >= 0 and temperature < 15 then
        coeff = 0.75
    elseif temperature >= 40 or temperature > -10 and temperature < 0 then
        coeff = 0.5
    elseif temperature <= -10 then
        coeff = 0.25
    end
    return { temperature = temperature, coeff = coeff }
end
Fishing = { Utils = { getTemperatureParams = vanillaParams } }

dofile("42/media/lua/shared/TraditionalPreservationFishMeat.lua")
local F = TraditionalPreservationFishMeat
local Weather = require "TraditionalPreservationCore/Weather"
local Wrap = require "TraditionalPreservationCore/Wrap"
local weather = Weather.weatherModData()

check("the wrap reaches Fishing.Utils", Wrap.applied("Fishing.Utils", "getTemperatureParams")
    and Fishing.Utils.getTemperatureParams ~= vanillaParams)

local function bite(air, season)
    weather.seasonTemperature = season
    return Fishing.Utils.getTemperatureParams({ air = air })
end

check("summer water: the full rate, whatever the morning's air", near(bite(12, 20).coeff, 1) and bite(12, 20).seasonTemperature == 20)
check("May to September (season 14 C and up): full", near(bite(18, 14).coeff, 1))
check("October's 7.3 C: about half (0.56)", near(bite(15, 7.3).coeff, 0.3 + 0.3 * 4.3 / 5))
check("a winter season (0 C and below): a fifth, even on a mild afternoon", near(bite(16, -4).coeff, 0.2))
check("3 C, the turnover's cold end: 0.3", near(bite(5, 3).coeff, 0.3))
check("vanilla's hot-air slump still counts", near(bite(33, 22).coeff, 0.75) and near(bite(41, 22).coeff, 0.5))
check("vanilla's temperature passes through", bite(12, 20).temperature == 12)

weather.seasonTemperature = nil
check("no season yet: vanilla's", near(Fishing.Utils.getTemperatureParams({ air = 5 }).coeff, 0.75))

SandboxVars = { TraditionalPreservationFishMeat = { FishingBySeason = false } }
check("the sandbox off: vanilla's by the air", near(bite(5, -4).coeff, 0.75) and bite(5, -4).seasonTemperature == nil)
SandboxVars = nil

H.done()
