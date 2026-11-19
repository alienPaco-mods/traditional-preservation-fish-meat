-- Traditional Preservation (Fish & Meat): the weather's totals (the mod's ledger) and what they do to a hanging stack or a tub: the rates by
-- temperature, wind and damp, each place's totals, the stacks' and tubs' steps and their popups' status. Required by TraditionalPreservationFishMeat.lua, whose F it adds
-- to.
TraditionalPreservationFishMeat = TraditionalPreservationFishMeat or {}
local F = TraditionalPreservationFishMeat
local Weather = require "TraditionalPreservationCore/Weather"
local Fire = require "TraditionalPreservationCore/Fire"
local Smokehouse = require "TraditionalPreservationCore/Smokehouse"

-- From DryingCraftLogic, so the frame's wetness readout tells the truth.
local RAIN_WETTING = 0.001  -- per game second, at full intensity
local SNOW_WETTING = 0.5
local WET_DRYING_OFF = 0.0002  -- per game second, at a temperature rate of 1
local SECONDS_PER_HOUR = 3600

-- The low end of DryingCraftLogic's curve: nothing at freezing, 1 at 20 C. It stops there, so
-- heat can't finish a batch in under DRY_HOURS.
function F.temperatureRate(celsius)
    local rate = math.max(0, math.min(celsius, 20)) / 20
    return rate * rate
end

-- Cold drying (unsalted fish in frost and wind) by temperature: full speed from 0 C to COLD_BEST,
-- slowing to COLD_MIN_RATE at COLD_LIMIT, nothing above it. Frost slows it to FROST_RATE at HARD_FROST,
-- and harder frost to HARD_FROST_RATE.
function F.coldRate(celsius)
    if celsius > F.COLD_LIMIT then return 0 end
    if celsius < F.HARD_FROST then return F.HARD_FROST_RATE end
    if celsius < 0 then return 1 - celsius / F.HARD_FROST * (1 - F.FROST_RATE) end
    if celsius <= F.COLD_BEST then return 1 end
    local warmth = (celsius - F.COLD_BEST) / (F.COLD_LIMIT - F.COLD_BEST)
    return 1 - warmth * (1 - F.COLD_MIN_RATE)
end

-- A rate from calm in still air rising to windy at WIND_GOOD. A reading without wind leaves the rate as it is.
local function breezeRate(wind, calm, windy)
    if not wind then return 1 end
    local breeze = math.min(math.max(wind, 0) / F.WIND_GOOD, 1)
    return calm + breeze * (windy - calm)
end

-- What the wind does to cold drying: CALM_RATE in still air, rising to WINDY_RATE at WIND_GOOD.
function F.windRate(wind)
    return breezeRate(wind, F.CALM_RATE, F.WINDY_RATE)
end

-- What the wind does to charque: CHARQUE_CALM_RATE in still air, rising to CHARQUE_WINDY_RATE at WIND_GOOD.
function F.charqueWindRate(wind)
    return breezeRate(wind, F.CHARQUE_CALM_RATE, F.CHARQUE_WINDY_RATE)
end

-- The value at x on the straight line through two points { x, value }, carried on past them.
function F.lineThrough(points, x)
    local low, high = points[1], points[2]
    return low[2] + (x - low[1]) * (high[2] - low[2]) / (high[1] - low[1])
end

-- Damp air slows open drying: full speed up to DRY_AIR_HUMIDITY, down to DAMP_AIR_RATE in saturated air.
function F.airRate(humidity)
    local dryAir = F.DRY_AIR_HUMIDITY
    if humidity <= dryAir then return 1 end
    local dampness = math.min((humidity - dryAir) / (1 - dryAir), 1)
    return 1 - dampness * (1 - F.DAMP_AIR_RATE)
end

-- Charque's rate by temperature: nothing at 0 C or below, full from CHARQUE_FULL_HEAT.
function F.charqueWarmRate(celsius)
    return math.max(0, math.min(celsius / F.CHARQUE_FULL_HEAT, 1))
end

-- How fast a tub cures at this temperature, 0.25 to 1 (TUB_CURE_POINTS).
function F.tubCureRate(celsius)
    return Weather.curve(F.TUB_CURE_POINTS, celsius)
end

-- Dry curing's rate by temperature: DRY_CURE_FROST_RATE at its lowest, full from DRY_CURE_FULL_HEAT.
function F.dryCureRate(celsius)
    return math.max(F.DRY_CURE_FROST_RATE, math.min(celsius / F.DRY_CURE_FULL_HEAT, 1))
end

-- The hours at a rate of 1 a stack of meat needs in the Smokehouse, by its heaviest piece: straight between the two
-- points and on below them, no more than the leg's.
function F.dryCureHours(heaviest)
    return math.min(F.lineThrough(F.DRY_CURE_HOURS, heaviest), F.DRY_CURE_HOURS[2][2])
end

-- The share of itself under-salted meat loses an hour at this temperature in the shed: the curve, and above freezing
-- never slower than rotting in maxDays (UNDER_CURE_MAX_DAYS for red meat). scale speeds the curve (poultry's).
function F.underCureRate(celsius, scale, maxDays)
    local warmth = (math.min(celsius, F.UNDER_CURE_MAX) - F.UNDER_CURE_AT) / 10
    local rate = F.UNDER_CURE_TENFOLD ^ warmth / F.UNDER_CURE_HOURS * (scale or 1)
    if celsius > 0 then rate = math.max(rate, 1 / ((maxDays or F.UNDER_CURE_MAX_DAYS) * 24)) end
    return rate
end

-- Poultry's and rabbit's (hot-smoke only) under-salted spoiling: faster, and within HOT_ONLY_MAX_DAYS above freezing.
function F.hotOnlyUnderRate(celsius)
    return F.underCureRate(celsius, F.HOT_ONLY_UNDER_RATE, F.HOT_ONLY_MAX_DAYS)
end

-- Salt fish's and charque's drying rates in air warmed by lift C (the Smokehouse with the fire burning): the
-- temperature lifted, the humidity halved for every 10 C of it, the wind as outdoors. Then dry curing's rate and
-- under-salted meat's spoiling in the same air (no wind in the shed).
function F.liftedRates(weather, lift)
    local humidity = weather.humidity * 0.5 ^ (lift / 10)
    local air = F.airRate(humidity)
    local celsius = weather.temperature + lift
    return math.max(F.temperatureRate(celsius) * air, F.MIN_DRY_RATE),
        F.charqueWarmRate(celsius) * air * F.charqueWindRate(weather.wind),
        F.dryCureRate(celsius) * air, F.underCureRate(celsius), F.hotOnlyUnderRate(celsius)
end

-- Where a stack or a tub is: TP Core's place word, as the World last saw it (modData.place), the open air before its
-- first look; inside TP Core's Smokehouse its word (Smokehouse.PLACE). Each place's totals in the ledger go by Core's
-- temperature there: the open air and a roof (Covered) by the hour's, the Smokehouse (Shed: an aired room's air, the
-- day's mean, still and out of the rain), an aired room (Aired), a shut room (Room) and a basement by their own.
local LEDGER_PLACES = { Open = "Open", Covered = "Covered", Sheltered = "Room", AiredRoom = "Aired",
    Basement = "Basement", [Smokehouse.PLACE] = "Shed" }
-- The Core place word each ledger place reads its temperature from.
local PLACE_WORDS = { Covered = "Covered", Room = "Sheltered", Aired = "AiredRoom", Basement = "Basement",
    Shed = Smokehouse.PLACE }

function F.placeWord(modData)
    return modData.place or Weather.NEW_RUN_PLACE
end

-- The ledger place a stack or tub goes by: Open, Covered, Shed, Room, Aired or Basement.
function F.ledgerPlace(modData)
    return LEDGER_PLACES[modData.place] or "Open"
end

-- In the Smokehouse.
function F.inShed(modData)
    return modData.place == Smokehouse.PLACE
end

-- In still air: a shut room, a basement or the Smokehouse. An aired room is a roof's air (moving, out of the rain).
function F.sheltered(modData)
    local place = modData.place
    return place ~= nil and place ~= "Open" and place ~= "Covered" and place ~= "AiredRoom"
end

-- In a shut room, where everything that dries by air stands still until a window is opened.
function F.shut(modData)
    return modData.place == "Sheltered"
end

-- The ledger's totals, by family and place: the key each place's total is kept under, or one key for every place.
-- A place a family leaves out has none (cold fish doesn't dry in still air; dry curing doesn't in the open; muggy
-- spoiling needs still air). Families: dry, salt fish drying; charque; cure, dry curing; under, under-salted meat
-- spoiling; cold, unsalted fish drying; hardFrost and coldWet, frost and wet on fresh cold fish (a room the open
-- air's); rawSpoil, unsalted fish spoiling by Core's temperature (the open air, a roof and the Smokehouse by the
-- hour's, a shut room, an aired room and a basement by their own); saltSpoil, salt fish in
-- a muggy season in still air (the Smokehouse by the season, a shut room and a basement by their own temperature);
-- warmCure, longCure and tubCure, a tub's (a roof by the hour); heat, hot sun; charqueRain, rain on open charque;
-- hotOnly, poultry and rabbit waiting in the shed.
local ROOF = "Covered"
F.TOTALS = {
    dry = { Open = "open", Covered = "covered", Shed = "sheltered", Room = "roomSheltered", Aired = "aired",
        Basement = "basementSheltered" },
    charque = { Open = "charque", Covered = "charqueCovered", Shed = "charqueSheltered", Room = "charqueRoom",
        Aired = "charqueAired", Basement = "charqueBasement" },
    cure = { Shed = "dryCure", Covered = "dryCureCovered", Room = "dryCureRoom", Aired = "dryCureAired",
        Basement = "dryCureBasement" },
    under = { Open = "underCureOpen", Shed = "underCure", Covered = "underCureCovered", Room = "underCureRoom",
        Aired = "underCureAired", Basement = "underCureBasement" },
    cold = { Open = "cold", Covered = "coldCovered", Aired = "coldAired", Room = "coldRoom" },
    hardFrost = { Open = "hardFrost", Covered = "hardFrostCovered", Shed = "hardFrost", Room = "hardFrost",
        Aired = "hardFrostAired", Basement = "hardFrost" },
    rawSpoil = { Open = "rawSpoil", Covered = "rawSpoil", Shed = "rawSpoil", Room = "rawSpoilRoom", Aired = "rawSpoilAired",
        Basement = "rawSpoilBasement" },
    saltSpoil = { Shed = "saltSpoil", Room = "saltSpoilRoom", Basement = "saltSpoilBasement" },
    warmCure = { Open = "warmCureOpen", Covered = "warmCure", Shed = "warmCure", Room = "warmCureRoom",
        Aired = "warmCureAired", Basement = "warmCureBasement" },
    longCure = { Open = "longCureOpen", Covered = "longCureSpoil", Shed = "longCureSpoil", Room = "longCureRoom",
        Aired = "longCureAired", Basement = "longCureBasement" },
    tubCure = { Open = "tubCureOpen", Covered = "tubCure", Shed = "tubCure", Room = "tubCureRoom",
        Aired = "tubCureAired", Basement = "tubCureBasement" },
    heat = "heat", coldWet = "coldWet", charqueRain = "charqueRain", hotOnly = "hotOnlyUnder",
}

-- A family's key at a place, or nil.
function F.totalKey(family, place)
    local keys = F.TOTALS[family]
    if type(keys) == "string" then return keys end
    return keys[place]
end

-- Every key of a family, each once, in a fixed order.
local FAMILY_KEYS = {}
for family, keys in pairs(F.TOTALS) do
    local familyKeys, seen = {}, {}
    if type(keys) == "string" then keys = { Open = keys } end
    for _, place in ipairs({ "Open", "Covered", "Shed", "Room", "Aired", "Basement" }) do
        local key = keys[place]
        if key and not seen[key] then seen[key], familyKeys[#familyKeys + 1] = true, key end
    end
    FAMILY_KEYS[family] = familyKeys
end
F.FAMILY_KEYS = FAMILY_KEYS

-- A stack's or tub's mark for a total: what the total stood at its last look ("open" is marked as lastOpen).
local MARKS = setmetatable({}, { __index = function(marks, key)
    local mark = "last" .. string.upper(string.sub(key, 1, 1)) .. string.sub(key, 2)
    marks[key] = mark
    return mark
end })
F.markOf = function(key) return MARKS[key] end

-- What a family's total at a place has added since the stack's last look (a mark not yet set counts from now).
function F.gain(modData, ledger, family, place)
    local key = F.totalKey(family, place)
    if not key then return 0 end
    local total = ledger[key] or 0
    return total - (modData[MARKS[key]] or total)
end

-- Marks every total of the families named, at every place, so the next look adds only what came since, wherever
-- the stack stands by then.
function F.mark(modData, ledger, families)
    for _, family in ipairs(families) do
        for _, key in ipairs(FAMILY_KEYS[family]) do modData[MARKS[key]] = ledger[key] end
    end
end

-- The weather totals, by F.TOTALS, each with its rate now (key .. "Rate") and, for a spoiling one, whether it is
-- spoiling now (key .. "On"); the wetness rain left on open frames and on cold ones; for cold smoke (5d) all hours
-- and the cool ones; salt fish's, charque's, dry curing's and under-salted meat's in a Smokehouse warmed by a banked
-- or a stoked fire; and the season's running means (TP Core's).
function F.newLedger(now)
    local ledger = { lastHour = now, wetness = 0, coldWetness = 0, clock = 0, smokeCool = 0, smokeBanked = 0,
        smokeStoked = 0, charqueBanked = 0, charqueStoked = 0, dryCureBanked = 0, dryCureStoked = 0, underCureBanked = 0,
        underCureStoked = 0, hotOnlyUnderBanked = 0, hotOnlyUnderStoked = 0 }
    for _, keys in pairs(FAMILY_KEYS) do
        for _, key in ipairs(keys) do ledger[key] = 0 end
    end
    return ledger
end
-- The last total a new ledger has: getLedger fills in a table without it.
local NEWEST_TOTAL = "rawSpoilBasement"

-- Adds rate x hours to a total and keeps its rate.
local function add(ledger, key, rate, hours)
    ledger[key .. "Rate"] = rate
    ledger[key] = (ledger[key] or 0) + rate * hours
end

-- A tub's cure at a place and its rate now (TUB_CURE_POINTS).
local function addTubCure(ledger, place, celsius, hours)
    add(ledger, F.TOTALS.tubCure[place], F.tubCureRate(celsius), hours)
end

-- A tub's warm cure and long cure at a place at this temperature, and whether each is spoiling now.
local function addCureSpoil(ledger, place, celsius, hours)
    local warmKey, longKey = F.TOTALS.warmCure[place], F.TOTALS.longCure[place]
    local warmth = celsius - F.WARM_CURE_ABOVE
    if warmth > 0 then ledger[warmKey] = (ledger[warmKey] or 0) + (1 + warmth / 10) * hours end
    local longWarmth = celsius - F.LONG_CURE_ABOVE
    if longWarmth > 0 then
        ledger[longKey] = (ledger[longKey] or 0) + longWarmth / (F.LONG_CURE_ROT_AT - F.LONG_CURE_ABOVE) / F.LONG_CURE_ROT_HOURS * hours
    end
    ledger[warmKey .. "On"], ledger[longKey .. "On"] = warmth > 0, longWarmth > 0
end

-- A place's temperature: TP Core's, the same figure every mod reads there.
function F.ownTemperature(ledger, place)
    return Weather.placeTemperature(ledger, place)
end

-- Adds unsalted fish's warm spoiling at a temperature to a total, and whether it is spoiling now (key .. "On"):
-- RAW_SPOIL_HOURS of it rots a stack, each 10 degrees over RAW_SPOIL_ABOVE as much again.
local function addRawSpoil(ledger, key, celsius, hours)
    local warmth = celsius - F.RAW_SPOIL_ABOVE
    ledger[key .. "On"] = warmth > 0
    if warmth > 0 then ledger[key] = (ledger[key] or 0) + (1 + warmth / 10) * hours end
end

-- Adds a salt stack's muggy-season spoiling since its last look, by its place, and marks every place's total.
local function addSaltSpoil(modData, ledger, exempt)
    local spoil = F.gain(modData, ledger, "saltSpoil", F.ledgerPlace(modData))
    F.mark(modData, ledger, { "saltSpoil" })
    return exempt and 0 or spoil / F.SALT_SPOIL_HOURS
end

-- Adds one stretch of weather to the totals. Open frames dry nothing until the rain has gone
-- and the wetness it left has dried off. Cold drying only minds rain, as snow doesn't wet frozen fish.
function F.advance(ledger, now, weather)
    local hours = now - ledger.lastHour
    if hours <= 0 then return end
    ledger.lastHour = now

    local minRate = F.MIN_DRY_RATE
    local temperatureRate = F.temperatureRate(weather.temperature)
    local seconds = hours * SECONDS_PER_HOUR
    local dryingOff = WET_DRYING_OFF * math.max(temperatureRate, minRate) * seconds
    if weather.precipitation > 0 then
        local wetting = RAIN_WETTING * weather.precipitation * (weather.isSnow and SNOW_WETTING or 1)
        ledger.wetness = math.min(ledger.wetness + wetting * seconds, 1)
    else
        ledger.wetness = math.max(ledger.wetness - dryingOff, 0)
    end
    local raining = weather.precipitation > 0 and not weather.isSnow
    if raining then
        ledger.coldWetness = math.min(ledger.coldWetness + RAIN_WETTING * weather.precipitation * seconds, 1)
    else
        ledger.coldWetness = math.max(ledger.coldWetness - dryingOff, 0)
    end

    -- The open air, by the day's temperature; and the Smokehouse's fire, which warms the day's air.
    local air = F.airRate(weather.humidity)
    local rate = temperatureRate * air
    add(ledger, "open", ledger.wetness <= 0 and math.max(rate, minRate) or 0, hours)
    local coldRate = F.coldRate(weather.temperature) * F.windRate(weather.wind)
    add(ledger, "cold", ledger.coldWetness <= 0 and coldRate or 0, hours)
    local charqueRate = F.charqueWarmRate(weather.temperature) * air
    add(ledger, "charque", ledger.wetness <= 0 and charqueRate * F.charqueWindRate(weather.wind) or 0, hours)
    if raining then ledger.charqueRain = ledger.charqueRain + hours end
    ledger.clock = ledger.clock + hours
    if weather.temperature <= F.COLD_SMOKE_MAX then ledger.smokeCool = ledger.smokeCool + hours end
    local bankedRate, charqueBanked, cureBanked, underBanked, hotOnlyBanked = F.liftedRates(weather, F.BANKED_LIFT)
    local stokedRate, charqueStoked, cureStoked, underStoked, hotOnlyStoked = F.liftedRates(weather, F.STOKED_LIFT)
    add(ledger, "dryCureBanked", cureBanked, hours)
    add(ledger, "dryCureStoked", cureStoked, hours)
    add(ledger, "underCureOpen", F.underCureRate(weather.temperature), hours)
    add(ledger, "underCureBanked", underBanked, hours)
    add(ledger, "underCureStoked", underStoked, hours)
    -- Poultry and rabbit hang in the Smokehouse only: by a banked and a stoked fire (the fire out: below).
    add(ledger, "hotOnlyUnderBanked", hotOnlyBanked, hours)
    add(ledger, "hotOnlyUnderStoked", hotOnlyStoked, hours)
    -- The smoulder's warmth: bankedRate and stokedRate are salt fish's in the warmed shed (smokeBanked, smokeStoked).
    ledger.bankedRate, ledger.stokedRate = bankedRate, stokedRate
    ledger.smokeBanked = ledger.smokeBanked + bankedRate * hours
    ledger.smokeStoked = ledger.smokeStoked + stokedRate * hours
    add(ledger, "charqueBanked", charqueBanked, hours)
    add(ledger, "charqueStoked", charqueStoked, hours)
    ledger.temperature = weather.temperature
    ledger.wind = weather.wind
    if weather.temperature < F.HARD_FROST then ledger.hardFrost = ledger.hardFrost + hours end
    if ledger.coldWetness > 0 and weather.temperature > 0 then ledger.coldWet = ledger.coldWet + hours end
    if weather.temperature > F.HEAT_ABOVE then ledger.heat = ledger.heat + hours end

    -- The season (TP Core's running means). Unsalted fish's spoiling and a tub's cures in the open, under a roof and in
    -- the Smokehouse by the hour's temperature (Core's for all three, step I).
    Weather.seasonTemperature(ledger, weather.temperature, hours)
    Weather.seasonHumidity(ledger, weather.humidity, hours)
    local roof = Weather.placeTemperature(ledger, PLACE_WORDS.Covered)
    addRawSpoil(ledger, F.TOTALS.rawSpoil.Covered, roof, hours)
    addCureSpoil(ledger, ROOF, roof, hours)
    addTubCure(ledger, ROOF, roof, hours)
    addTubCure(ledger, "Open", weather.temperature, hours)
    addCureSpoil(ledger, "Open", weather.temperature, hours)

    -- A shut room, an aired room and a basement by Core's temperature there; a tub there minds it for its cures.
    -- A shut room's still air dries nothing (salt fish, charque, dry curing, cold drying wait for a window); a
    -- basement keeps its still-air rates (salt fish at SHELTERED_RATE, charque at CHARQUE_INDOORS_RATE, dry curing at
    -- DRY_CURE_BASEMENT_RATE: a cellar's cold and its vent are where hams cured); an aired room dries as a roof
    -- (below), cold drying at AIRED_COLD_RATE of the wind.
    local temperatures = {}
    for _, place in ipairs({ "Basement", "Room", "Aired" }) do
        local celsius = Weather.placeTemperature(ledger, PLACE_WORDS[place])
        temperatures[place] = celsius
        add(ledger, F.TOTALS.under[place], F.underCureRate(celsius), hours)
        addRawSpoil(ledger, F.TOTALS.rawSpoil[place], celsius, hours)
        addCureSpoil(ledger, place, celsius, hours)
        addTubCure(ledger, place, celsius, hours)
    end
    local cellar = temperatures.Basement
    add(ledger, F.TOTALS.dry.Basement, math.max(F.temperatureRate(cellar) * air * F.SHELTERED_RATE, minRate), hours)
    add(ledger, F.TOTALS.charque.Basement, F.charqueWarmRate(cellar) * air * F.CHARQUE_INDOORS_RATE, hours)
    add(ledger, F.TOTALS.cure.Basement, F.dryCureRate(cellar) * F.DRY_CURE_BASEMENT_RATE, hours)
    for _, family in ipairs({ "dry", "charque", "cure", "cold" }) do add(ledger, F.TOTALS[family].Room, 0, hours) end
    local aired = temperatures.Aired
    add(ledger, F.TOTALS.dry.Aired, math.max(F.temperatureRate(aired) * air, minRate), hours)
    add(ledger, F.TOTALS.charque.Aired, F.charqueWarmRate(aired) * air * F.charqueWindRate(weather.wind), hours)
    add(ledger, F.TOTALS.cure.Aired, F.dryCureRate(aired) * air, hours)
    add(ledger, F.TOTALS.cold.Aired, F.coldRate(aired) * F.windRate(weather.wind) * F.AIRED_COLD_RATE, hours)
    if aired < F.HARD_FROST then ledger.hardFrostAired = (ledger.hardFrostAired or 0) + hours end
    -- Under a roof (step I) by Core's covered temperature, the hour's, with the outdoor air and wind; cold drying at
    -- COVERED_COLD_RATE of the wind, and its hard frost.
    add(ledger, "covered", math.max(F.temperatureRate(roof) * air, minRate), hours)
    add(ledger, "charqueCovered", F.charqueWarmRate(roof) * air * F.charqueWindRate(weather.wind), hours)
    add(ledger, "dryCureCovered", F.dryCureRate(roof) * air, hours)
    add(ledger, "underCureCovered", F.underCureRate(roof), hours)
    add(ledger, "coldCovered", F.coldRate(roof) * F.windRate(weather.wind) * F.COVERED_COLD_RATE, hours)
    if roof < F.HARD_FROST then ledger.hardFrostCovered = (ledger.hardFrostCovered or 0) + hours end
    -- The Smokehouse with the fire out: an aired room's air, the day's mean (TP Core's), but still (salt fish at
    -- SHELTERED_RATE, charque at CHARQUE_INDOORS_RATE) and out of the rain.
    local shed = Weather.placeTemperature(ledger, PLACE_WORDS.Shed)
    add(ledger, "sheltered", math.max(F.temperatureRate(shed) * air * F.SHELTERED_RATE, minRate), hours)
    add(ledger, "charqueSheltered", F.charqueWarmRate(shed) * air * F.CHARQUE_INDOORS_RATE, hours)
    add(ledger, "dryCure", F.dryCureRate(shed) * air, hours)
    add(ledger, "underCure", F.underCureRate(shed), hours)
    add(ledger, "hotOnlyUnder", F.hotOnlyUnderRate(shed), hours)
    -- A muggy season spoils salt fish and charque in still air only: moving air (the open, a roof, an aired room)
    -- keeps the skin dry. The Smokehouse by the season's mean (mould and rancid fat come of days of damp warmth, not
    -- one hot afternoon), a shut room (22 C on the grid is not over the limit) and a basement (never) by their own.
    local humid = ledger.seasonHumidity > F.SALT_SPOIL_HUMIDITY
    ledger.saltSpoilOn = ledger.seasonTemperature > F.SALT_SPOIL_ABOVE and humid
    if ledger.saltSpoilOn then ledger.saltSpoil = ledger.saltSpoil + hours end
    for _, place in ipairs({ "Room", "Basement" }) do
        local key = F.TOTALS.saltSpoil[place]
        ledger[key .. "On"] = humid and temperatures[place] > F.SALT_SPOIL_ABOVE
        if ledger[key .. "On"] then ledger[key] = (ledger[key] or 0) + hours end
    end
end

-- The totals a tub batch reads, marked at its start.
local TUB_FAMILIES = { "warmCure", "longCure", "tubCure" }

-- Whether a fresh salt stack is in open sun in a heat wave.
function F.scorching(modData, temperature)
    return F.placeWord(modData) == "Open" and temperature > F.HEAT_ABOVE
        and (modData.dried or 0) < F.SALT_FRESH_UNTIL * F.DRY_HOURS
end

-- A total's rate now at a stack's place, 0 if the family has none there.
local function rateAt(ledger, family, place)
    local key = F.totalKey(family, place)
    return key and ledger[key .. "Rate"] or 0
end

-- The rate by a burning fire in the Smokehouse, when it beats the shed's own: a stack's modData.burning holds the
-- fire's mode, Core's Fire.STOKED or BANKED.
local function fireRate(modData, rate, stoked, banked)
    if not modData.burning then return rate end
    return math.max(rate, (modData.burning == Fire.STOKED and stoked or banked) or 0)
end

-- Whether salt fish and charque at a ledger place are in a muggy season now (still air only).
function F.muggy(ledger, place)
    local key = F.totalKey("saltSpoil", place)
    return key ~= nil and ledger[key .. "On"] == true
end

-- How a hanging stack is doing right now, for its popup. reason says why it isn't drying, and
-- hoursLeft assumes the weather stays as it is.
function F.stackStatus(isCold, modData, ledger)
    local hours = isCold and F.COLD_DRY_HOURS or F.DRY_HOURS
    local place, word = F.ledgerPlace(modData), F.placeWord(modData)
    -- Under a roof and in a room cold drying goes by Core's temperature there.
    local temperature = isCold and PLACE_WORDS[place] and Weather.placeTemperature(ledger, PLACE_WORDS[place])
        or ledger.temperature or 0
    local rate, reason
    if F.shut(modData) then
        rate, reason = 0, "Shut"
    elseif isCold and F.sheltered(modData) then
        rate, reason = 0, "Roof"
    elseif isCold and temperature > F.COLD_LIMIT then
        rate, reason = 0, "TooWarm"
    elseif isCold then
        rate = rateAt(ledger, "cold", place)
        if rate <= 0 and place == "Open" then reason = "Rain" end
    else
        -- A burning Stone Hearth warms a Smokehouse stack's air (F.smokeStep).
        rate = rateAt(ledger, "dry", place)
        if F.sheltered(modData) then rate = fireRate(modData, rate, ledger.stokedRate, ledger.bankedRate) end
        if rate <= 0 and place == "Open" then reason = "Rain" end
    end
    local dried = modData.dried or 0
    return {
        progress = math.min(dried / hours, 1),
        rate = rate,
        reason = reason,
        hoursLeft = rate > 0 and math.max(hours - dried, 0) / rate or nil,
        spoiled = math.min(modData.spoiled or 0, 1),
        -- Unsalted fish by the totals its step reads, each by its place's temperature.
        spoiling = (isCold and ledger[F.totalKey("rawSpoil", place) .. "On"]
            or not isCold and F.muggy(ledger, place)) == true,
        scorching = not isCold and F.scorching(modData, temperature),
    }
end

-- The popup's words for a hanging stack's spoilage, temperature and wind, as translation keys (F.spoilWarning,
-- the *TemperatureWord functions, F.windWord).
F.WORDS = {
    spoilingWarm = "IGUI_TraditionalPreservationFishMeat_SpoilingWarm",
    spoilingMuggy = "IGUI_TraditionalPreservationFishMeat_SpoilingMuggy",
    spoilingSun = "IGUI_TraditionalPreservationFishMeat_SpoilingSun",
    spoiled = "IGUI_TraditionalPreservationFishMeat_Spoiled",
    tempTooWarm = "IGUI_TraditionalPreservationFishMeat_TempTooWarm",
    tempMild = "IGUI_TraditionalPreservationFishMeat_TempMild",
    tempGoodCold = "IGUI_TraditionalPreservationFishMeat_TempGoodCold",
    tempFrost = "IGUI_TraditionalPreservationFishMeat_TempFrost",
    tempHardFrost = "IGUI_TraditionalPreservationFishMeat_TempHardFrost",
    tempHot = "IGUI_TraditionalPreservationFishMeat_TempHot",
    tempGoodWarm = "IGUI_TraditionalPreservationFishMeat_TempGoodWarm",
    tempCool = "IGUI_TraditionalPreservationFishMeat_TempCool",
    tempHotGood = "IGUI_TraditionalPreservationFishMeat_TempHotGood",
    tempTooCold = "IGUI_TraditionalPreservationFishMeat_TempTooCold",
    tempGoodCure = "IGUI_TraditionalPreservationFishMeat_TempGoodCure",
    tempFrostSlow = "IGUI_TraditionalPreservationFishMeat_TempFrostSlow",
    windGood = "IGUI_TraditionalPreservationFishMeat_WindGood",
    windLight = "IGUI_TraditionalPreservationFishMeat_WindLight",
    windCalm = "IGUI_TraditionalPreservationFishMeat_WindCalm",
}

-- The popup's Spoilage line for a hanging stack's status, a translation key taking the share spoiled, or nil with
-- nothing to say: what is spoiling it now (the season, or hot sun), else just how much has gone.
function F.spoilWarning(status, isCold)
    if status.spoiling then
        return isCold and F.WORDS.spoilingWarm or F.WORDS.spoilingMuggy
    end
    if status.scorching then return F.WORDS.spoilingSun end
    if status.spoiled > 0 then return F.WORDS.spoiled end
    return nil
end

-- The popup's word for the temperature, a translation key: good, cool, mild, too warm, frost or hard frost,
-- or for salt fish in the sun, too hot (exposed: no roof over it).
function F.temperatureWord(isCold, celsius, exposed)
    if isCold then
        if celsius > F.COLD_LIMIT then return F.WORDS.tempTooWarm end
        if celsius > F.COLD_BEST then return F.WORDS.tempMild end
        if celsius >= 0 then return F.WORDS.tempGoodCold end
        if celsius >= F.HARD_FROST then return F.WORDS.tempFrost end
        return F.WORDS.tempHardFrost
    end
    if exposed and celsius > F.HEAT_ABOVE then return F.WORDS.tempHot end
    if celsius >= 20 then return F.WORDS.tempGoodWarm end
    if celsius > 0 then return F.WORDS.tempCool end
    return F.WORDS.tempFrost
end

-- How a hanging charque stack is doing right now, for its popup, as stackStatus.
function F.charqueStatus(modData, ledger)
    -- Poultry and rabbit (0.4.34) never dry: the bar is the cook, which runs only while the Stone Hearth is stoked.
    if modData.hotOnly then
        local burning = modData.burning
        local stoked = burning == Fire.STOKED
        return {
            progress = F.cookShare(modData) or 0,
            rate = stoked and 1 or 0,
            reason = not stoked and "NeedsStoking" or nil,
            hoursLeft = stoked and math.max((modData.hotSmokeHoursNeeded or 0) - (modData.hotSmokeHours or 0), 0) or nil,
            spoiled = math.min((modData.spoiled or 0) + (modData.underSpoiled or 0), 1),
            spoiling = false,
            scorching = false,
            dryCuring = false,
            hotOnly = true,
            underSalted = true,
            shedTemperature = burning and (ledger.temperature or 0) + (stoked and F.STOKED_LIFT or F.BANKED_LIFT)
                or F.ownTemperature(ledger, Smokehouse.PLACE),
        }
    end
    local rate, reason
    local curing = F.dryCuring(modData)
    local lift = 0
    local place = F.ledgerPlace(modData)
    if curing and place == "Open" then
        rate, reason = 0, "NeedsRoof"
    elseif F.shut(modData) then
        rate, reason = 0, "Shut"
    elseif curing then
        rate = rateAt(ledger, "cure", place)
        if place == "Shed" and modData.burning then
            rate = fireRate(modData, rate, ledger.dryCureStokedRate, ledger.dryCureBankedRate)
            lift = modData.burning == Fire.STOKED and F.STOKED_LIFT or F.BANKED_LIFT
        end
    else
        rate = rateAt(ledger, "charque", place)
        if place == "Shed" then rate = fireRate(modData, rate, ledger.charqueStokedRate, ledger.charqueBankedRate) end
        if place == "Open" and rate <= 0 and (ledger.wetness or 0) > 0 then reason = "Rain" end
    end
    if rate <= 0 and not reason then reason = "TooCold" end
    local dried, hours = modData.dried or 0, F.meatHours(modData)
    return {
        progress = math.min(dried / hours, 1),
        rate = rate,
        reason = reason,
        hoursLeft = rate > 0 and math.max(hours - dried, 0) / rate or nil,
        spoiled = math.min((modData.spoiled or 0) + (modData.underSpoiled or 0), 1),
        spoiling = not curing and F.muggy(ledger, place),
        scorching = false,
        dryCuring = curing,
        -- Corned meat in the shed, and the shed's temperature it spoils by: the place's own (Core's; the
        -- Smokehouse's an open roof's), or with the fire burning the day's and the fire's.
        underSalted = curing and modData.underCured == true,
        shedTemperature = curing and lift == 0 and PLACE_WORDS[place] and F.ownTemperature(ledger, PLACE_WORDS[place])
            or (ledger.temperature or 0) + lift,
    }
end

-- The popup's word for the temperature on a charque stack: hot sun is good, then warm, cool and too cold.
function F.charqueTemperatureWord(celsius)
    if celsius >= F.CHARQUE_FULL_HEAT then return F.WORDS.tempHotGood end
    if celsius >= 15 then return F.WORDS.tempGoodWarm end
    if celsius > 0 then return F.WORDS.tempCool end
    return F.WORDS.tempTooCold
end

-- The popup's word for the temperature on meat in the Smokehouse: cool air is right, frost only slows it.
function F.dryCureTemperatureWord(celsius)
    if celsius >= F.DRY_CURE_FULL_HEAT then return F.WORDS.tempGoodCure end
    if celsius > 0 then return F.WORDS.tempCool end
    return F.WORDS.tempFrostSlow
end

-- The popup's word for the wind on a cold frame: calm, a light breeze or a good drying wind.
function F.windWord(wind)
    wind = wind or 0
    if wind >= F.WIND_GOOD then return F.WORDS.windGood end
    if wind >= F.WIND_GOOD / 3 then return F.WORDS.windLight end
    return F.WORDS.windCalm
end

-- The ledger is the mod's global ModData table itself, so its keys are the ones in every save. A new save's table
-- (or one without the newest total) gets the totals it lacks.
function F.getLedger()
    local fishMeatModData = ModData.getOrCreate(F.MOD_DATA_KEY)
    if fishMeatModData[NEWEST_TOTAL] == nil then
        for key, field in pairs(F.newLedger(getGameTime():getWorldAgeHours())) do
            if fishMeatModData[key] == nil then fishMeatModData[key] = field end
        end
    end
    return fishMeatModData
end

-- The totals each kind of stack reads, marked at its start and at every look.
local SALT_FAMILIES = { "dry", "saltSpoil", "heat" }
local COLD_FAMILIES = { "cold", "hardFrost", "rawSpoil", "coldWet" }
local MEAT_FAMILIES = { "charque", "charqueRain", "saltSpoil", "cure", "under", "hotOnly" }
local STACK_FAMILIES = { "dry", "saltSpoil", "heat", "cold", "hardFrost", "rawSpoil", "coldWet", "charque", "charqueRain",
    "cure", "under", "hotOnly" }

-- Marks every total a new stack reads, and every total a new tub batch reads.
function F.markStack(modData, ledger)
    F.mark(modData, ledger, STACK_FAMILIES)
end

function F.markTub(modData, ledger)
    F.mark(modData, ledger, TUB_FAMILIES)
end

-- The share of its keeping a batch has lost to a warm cure so far, by its tub's place; a long cure (Country Cure)
-- also minds a place over LONG_CURE_ABOVE.
function F.cureSpoiled(modData, ledger)
    local place = F.ledgerPlace(modData)
    local warm = F.gain(modData, ledger, "warmCure", place)
    local long = modData.countryCure and F.gain(modData, ledger, "longCure", place) or 0
    return math.min(warm * F.WARM_CURE_SHARE / F.RAW_SPOIL_HOURS + long, 1)
end

-- Whether a tub batch is spoiling now: a warm cure, or a long cure over LONG_CURE_ABOVE, by its place.
function F.tubSpoiling(modData, ledger)
    local place = F.ledgerPlace(modData)
    return ledger[F.totalKey("warmCure", place) .. "On"] == true
        or modData.countryCure == true and ledger[F.totalKey("longCure", place) .. "On"] == true
end

-- A batch's cure so far, in hours at full speed, and its rate now: by the tub's place since the last look.
function F.pressDone(modData, ledger)
    local key = F.totalKey("tubCure", F.ledgerPlace(modData))
    return modData.tubDone + F.gain(modData, ledger, "tubCure", F.ledgerPlace(modData)), ledger[key .. "Rate"] or 1
end

-- How far a batch in the tub is, for its popup.
function F.pressStatus(modData, ledger)
    local hours = modData.pressHours
    local done, rate = F.pressDone(modData, ledger)
    local left = math.max(hours - done, 0)
    return { progress = math.min(done / hours, 1), hoursLeft = rate > 0 and left / rate or nil, rate = rate,
        spoiled = F.cureSpoiled(modData, ledger),
        spoiling = F.tubSpoiling(modData, ledger) }
end

-- Adds what the weather has done to a salt stack since it was last looked at. It goes by the frame's
-- place now, so a roof built over a running frame counts from then on. Heat in open sun harms a stack
-- under SALT_FRESH_UNTIL dried, weighed by how wet it still is, as cold frames weigh frost.
function F.saltStep(modData, ledger)
    local place = F.ledgerPlace(modData)
    local heat = F.gain(modData, ledger, "heat", place)
    local vulnerability = 1 - math.min(modData.dried / F.DRY_HOURS, 1)
    local damage = 0
    if place == "Open" and vulnerability > 1 - F.SALT_FRESH_UNTIL then
        damage = heat / F.HEAT_DAMAGE_HOURS * F.HEAT_DAMAGE * vulnerability
    end
    modData.dried = modData.dried + F.gain(modData, ledger, "dry", place)
    local spoiled = (modData.spoiled or 0) + addSaltSpoil(modData, ledger)
    if damage > 0 and spoiled < F.DAMAGE_CAP then spoiled = math.min(spoiled + damage, F.DAMAGE_CAP) end
    modData.spoiled = spoiled
    F.mark(modData, ledger, SALT_FAMILIES)
end

-- Adds what the weather has done to a cold stack since it was last looked at. Indoors the air is
-- still, so unsalted fish doesn't dry there; it can still spoil. An open shed's roof keeps the rain
-- off and some of the wind. Rot, early hard frost and wet weigh
-- by how wet the fish still is, taken at this update (a stack catching up after its chunk was
-- unloaded uses its progress from then).
function F.coldStep(modData, ledger)
    local place = F.ledgerPlace(modData)
    local vulnerability = 1 - math.min(modData.dried / F.COLD_DRY_HOURS, 1)
    local frost = F.gain(modData, ledger, "hardFrost", place)
    local wet = F.gain(modData, ledger, "coldWet", place)
    local damage = 0
    if vulnerability > 1 - F.FRESH_UNTIL then
        damage = frost / F.FREEZE_DAMAGE_HOURS * F.FREEZE_DAMAGE
        if place == "Open" then damage = damage + wet / F.WET_DAMAGE_HOURS * F.WET_DAMAGE end
    end
    modData.dried = modData.dried + F.gain(modData, ledger, "cold", place)
    local warmSpoil = F.gain(modData, ledger, "rawSpoil", place)
    -- Warmth rots the wet flesh: once a skin has formed and the fish dries on, it does less and less (step I:
    -- by its wetness squared, so a half-dry stack takes a quarter and a nearly dry one almost none).
    local spoiled = modData.spoiled + warmSpoil / F.RAW_SPOIL_HOURS * vulnerability * vulnerability
    if spoiled < F.DAMAGE_CAP then spoiled = math.min(spoiled + damage * vulnerability, F.DAMAGE_CAP) end
    modData.spoiled = spoiled
    F.mark(modData, ledger, COLD_FAMILIES)
end

-- Whether a stack of meat dry cures: any in a Smokehouse, a shut room or a basement (still air: charque is the sun's
-- and the wind's, so Corned meat there is under-salted meat drying, as in the shed), and under an open roof or in an
-- aired room one with Country Cured meat in it (longStack, from F.startSmoke). Then the hours at a rate of 1 a stack of meat needs.
function F.dryCuring(modData)
    return (F.sheltered(modData) or modData.longStack == true) and modData.cureNeed ~= nil
end

function F.meatHours(modData)
    return F.dryCuring(modData) and modData.cureNeed or F.CHARQUE_HOURS
end

-- Where a dry-curing stack hangs: "Shed", "Basement", "Shade" (a Frame or Beam under a roof or in a room) or "Open"
-- (its roof is gone: it waits).
function F.curePlace(modData)
    local place = F.ledgerPlace(modData)
    if place == "Room" or place == "Covered" or place == "Aired" then return "Shade" end
    return place
end

-- Meat in the Smokehouse dry cures (6b): the shed's cool-air drying with the fire out (F.smokeStep adds the fire's
-- hours), and for Corned meat the spoiling of the under-salted. In the shade, a basement, an aired room, a shut room
-- and a roof each have their own totals (by Core's temperature there; a shut room's dry nothing); in the open nothing
-- dries, and Corned meat spoils as in the shed.
local function dryCureStep(modData, ledger)
    local place = F.ledgerPlace(modData)
    local dried = F.gain(modData, ledger, "cure", place)
    local under = F.gain(modData, ledger, "under", place)
    -- Poultry and rabbit never dry: they wait for a cook, spoiling faster than red meat.
    if modData.hotOnly then dried, under = 0, F.gain(modData, ledger, "hotOnly", place) end
    modData.dried = modData.dried + dried
    if modData.underCured then modData.underSpoiled = (modData.underSpoiled or 0) + under end
end

-- Adds what the weather has done to a charque stack since it was last looked at, by the frame's place now. Rain on
-- an open frame takes back a share of what it had first; it doesn't dry while wet anyway.
function F.charqueStep(modData, ledger)
    local place = F.ledgerPlace(modData)
    if F.dryCuring(modData) then
        dryCureStep(modData, ledger)
    elseif modData.hotOnly then
        -- Poultry and rabbit hang only in the Smokehouse and never dry; before the World's first look, nothing.
    else
        local rain = F.gain(modData, ledger, "charqueRain", place)
        if place == "Open" and rain > 0 then modData.dried = modData.dried * (1 - F.CHARQUE_REWET) ^ (rain / F.CHARQUE_RAIN_HOURS) end
        modData.dried = modData.dried + F.gain(modData, ledger, "charque", place)
    end
    -- Dry curing is spared a muggy season (step I): country hams aged through the summer's heat.
    modData.spoiled = (modData.spoiled or 0) + addSaltSpoil(modData, ledger, F.dryCuring(modData))
    F.mark(modData, ledger, MEAT_FAMILIES)
end
