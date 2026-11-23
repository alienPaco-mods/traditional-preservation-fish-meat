-- Traditional Preservation (Fish & Meat): fish bite by the season (user, 2026-11-23: winter fishing as real winter
-- fishing, so the summer's fish has to be put by). Vanilla's bite chance takes a factor from the air where you stand
-- (Fishing.Utils.getTemperatureParams: 1 at 15 to 30 C, 0.75 at 0 to 15, 0.5 below), so a frosty morning in July
-- bites worse than a mild afternoon in January, and a winter day still lands about 60% of a summer day. Fish feel the
-- water, and the water follows the season: cold water slows them until they barely feed. Here the factor goes by TP
-- Core's season temperature (the ten-day mean of the air, Weather's seasonTemperature) on BITE_CURVE: the full rate
-- from May to September, about half in April and October, a fifth from November to February. Vanilla's hot-air slump
-- (above 30 C, when fish go deep) still counts on top. Rain, dawn and dusk, hooks and the fish in the water stay
-- vanilla's. Sandbox Fishing by season (on). Required by TraditionalPreservationFishMeat.lua.
require "TraditionalPreservationFishMeat/Common"
TraditionalPreservationFishMeat = TraditionalPreservationFishMeat or {}
local F = TraditionalPreservationFishMeat
local Weather = require "TraditionalPreservationCore/Weather"
local Wrap = require "TraditionalPreservationCore/Wrap"

-- { season C, bite factor }: winter's cold water a fifth of summer's bite (the perch, crappie and sauger that still
-- feed under the cold), the spring and autumn turnover in between, the full rate once the water is warm.
F.BITE_CURVE = { { 0, 0.2 }, { 3, 0.3 }, { 8, 0.6 }, { 14, 1 } }
F.HOT_AIR_C = 30   -- vanilla's: from here its own factor (0.75, 0.5 from 40 C) still counts, fish lying deep

function F.fishingBySeason()
    return F.optionOn("FishingBySeason")
end

-- The bite factor for a season temperature.
function F.seasonBite(seasonC)
    return Weather.curve(F.BITE_CURVE, seasonC)
end

-- Vanilla's temperature params with the factor by season: { temperature, coeff, seasonTemperature }. Vanilla's own
-- when the option is off or there is no season yet.
function F.fishingTemperature(data)
    if not F.fishingBySeason() then return data end
    local season = Weather.weatherModData().seasonTemperature
    if season == nil then return data end
    local hot = data.temperature ~= nil and data.temperature >= F.HOT_AIR_C and data.coeff or 1
    data.seasonTemperature = season
    data.coeff = F.seasonBite(season) * hot
    return data
end

Wrap.method("Fishing.Utils", "getTemperatureParams", function(vanilla, player)
    return F.fishingTemperature(vanilla(player))
end)
