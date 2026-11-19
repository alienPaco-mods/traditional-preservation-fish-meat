-- Traditional Preservation (Fish & Meat): the curing rules shared by the recipes and the world.
-- Weather is the same everywhere, so one running total in global ModData tells every frame
-- how much drying it has had, including while its chunk was unloaded.
TraditionalPreservationFishMeat = TraditionalPreservationFishMeat or {}
local F = TraditionalPreservationFishMeat
local Weather = require "TraditionalPreservationCore/Weather"
local Tiles = require "TraditionalPreservationFishMeat/Tiles"
require "TraditionalPreservationFishMeat/Common"
local Doors = require "TraditionalPreservationCore/Doors"
local StoneHearth = require "TraditionalPreservationCore/StoneHearth"
local Station = require "TraditionalPreservationCore/Station"
local Smokehouse = require "TraditionalPreservationCore/Smokehouse"

F.MOD_DATA_KEY = "TraditionalPreservationFishMeat"

-- Pots on the hob (Core's Stone Hearth sets its pot in the hole for them): fat rendering, potting, stocks, soups and
-- stews, poached sausage. The pudding pans are oven food.
for _, pot in ipairs({ "PorkFat", "Suet", "MeatInFat", "BoneBroth", "ChickenStock", "BoneBrothSoup", "BoneBrothStew",
    "ChickenSoup", "ChickenStew", "Sausage", "BloodSausage", "FishHeadStock", "FishHeadSoup", "FishHeadStew" }) do
    StoneHearth.cooksOn(StoneHearth.STOVE, "TraditionalPreservationFishMeat.PotOf" .. pot, "TraditionalPreservationFishMeat.PotForged" .. pot)
end

-- Hours in the tub at most, and hours on the frame at a drying rate of 1. These set the recipes' times.
F.PRESS_HOURS = 48
F.DRY_HOURS = 288
F.COLD_DRY_HOURS = 768

-- A batch is pressed when the salt has gone through its thickest fish, so the heaviest fish sets the time:
-- PRESS_MIN_HOURS if every fish is up to PRESS_SMALL_WEIGHT (about 0.5 kg), PRESS_HOURS if any is
-- PRESS_BIG_WEIGHT (about 1 kg) or more, and in between by weight.
F.PRESS_MIN_HOURS = 24
F.PRESS_SMALL_WEIGHT = 1.1
F.PRESS_BIG_WEIGHT = 2.2

-- The most weight of fish a tub takes, with room for a few bigger fish.
F.TUB_CAPACITY = 50
-- Fish too, so a tub can't be filled with fillets. A tub built with more slots still stops here.
F.TUB_MAX_ITEMS = 35
-- Each press of Craft hangs one stack, with one sprite and one timer, and every stack is limited
-- by weight alone. A full frame holds 20. MAX_STACKS is the frame's spots, from the Tiles.lua that
-- tools/build_tileset.py writes.
F.STACK_WEIGHT = 2.5
F.MAX_STACKS = Tiles.HANGERS.frame.stacks
-- Every station that hangs fish, by its first sprite: its first hanging tile (spotSprite) and its spots (stacks), from
-- Tiles.lua, and the old stacks' weight and pieces (the Smokehouse's slots still go by them).
-- The Smokehouse chamber is TP Core's (Smokehouse.lua): closed, nothing hangs in sight; F.CHAMBER_HANGER below.
local STACK_WEIGHTS = { frame = F.STACK_WEIGHT, medium = 15, large = 50, chamber = 15 }
-- And the most pieces in each stack, fish or meat alike (0.4.20): the Beam and the Gantry are for bigger fish, not
-- more of them. 25 is the slot every station is built with.
local STACK_PIECES = { frame = 25, medium = 12, large = 6, chamber = 25 }
F.HANGERS = {}
for name, tileHanger in pairs(Tiles.HANGERS) do
    local hanger = { name = name, spotSprite = tileHanger.spotSprite, stacks = tileHanger.stacks, stackWeight = STACK_WEIGHTS[name], stackPieces = STACK_PIECES[name], closed = tileHanger.closed }
    for _, base in ipairs(tileHanger.bases or { tileHanger.base }) do F.HANGERS[base] = hanger end
end
F.CHAMBER_HANGER = { name = "chamber", stacks = Smokehouse.STACKS, stackWeight = STACK_WEIGHTS.chamber, stackPieces = STACK_PIECES.chamber, closed = true }

-- Vanilla's rules for cutting a fish: over this weight, into two fillets of this share of its
-- weight (more in spawning season, when part goes to roe), each with half its food.
F.MIN_SLICE_WEIGHT = 0.6
-- The game keeps a weight as a float, so a fish set to 0.6 reads 0.6000000238: a limit is passed only by more than this.
F.WEIGHT_SLACK = 1e-4
F.FILLET_WEIGHT = 0.05
-- These are already cut, so vanilla doesn't slice them.
F.UNSLICEABLE = { ["Base.FishFillet"] = true, ["Base.Salmon"] = true }
-- Vanilla's guts: only a fish it could cut has them, and they are this share of its weight.
F.GUTS_WEIGHT = 0.1
-- A fillet vanilla cut weighs a twentieth of its fish and holds half its food. Salted, it counts as what it
-- holds, half the gutted fish: it pays that much salt and comes out of the salt that heavy.
F.FILLET_FOOD_WEIGHT = (1 - F.GUTS_WEIGHT) * 0.5 / F.FILLET_WEIGHT
-- Salting takes SALT_PER_STEP salt for each SALT_STEP of a piece's weight in the tub, to the nearest step, and never
-- less than SALT_MIN a piece. Quarter steps since 0.4.18: a started half weight made a
-- Steak pay a Beef's salt and a small panfish a big one's.
F.SALT_STEP = 0.25
F.SALT_PER_STEP = 2
F.SALT_MIN = 2
-- A fish over this weight is too thick to salt whole, as on the Volga: gut and split it first. Halves always go in.
F.SALT_WHOLE_MAX = 4.5
-- Gut Fish takes the head off too, as stockfish did, and a fish over HEAD_MIN_WEIGHT gives a Fish
-- Head for the pot: this share of its weight and of its food. The limit is above the guts' so small
-- fish can't be farmed for heads. Salted fish keep their heads.
F.HEAD_MIN_WEIGHT = 1.0
F.HEAD_WEIGHT = 0.1
F.HEAD_FOOD = 0.06
-- Charque (phase 3b): the meat cuts that go in the salt as vanilla gives them, in the order of the meat stages'
-- IconsForTexture. Pork, Pork Chop and the Leg of Pork came with 6a, for the Smokehouse only: pork fat goes rancid
-- in sun and wind (meatRefusal).
-- Chicken, turkey and rabbit came with 0.4.34: hot smoke only (F.HOT_ONLY_INDICES).
F.MEAT_CUTS = { "Base.Beef", "Base.Steak", "Base.MuttonChop", "Base.Venison", "Base.Pork", "Base.PorkChop",
    F.LEG_OF_PORK,
    "Base.Chicken", "Base.ChickenWings", "Base.ChickenFillet", "Base.ChickenWhole",
    "Base.TurkeyLegs", "Base.TurkeyWings", "Base.TurkeyFillet", "Base.TurkeyWhole", "Base.Rabbitmeat" }
-- The pork cuts' and the leg's model indices.
F.PORK_INDICES = { [4] = true, [5] = true, [6] = true }
F.LEG_INDEX = 6
-- Poultry and rabbit (0.4.34): brined lightly and hot smoked, nothing else. Lean bird fat goes rancid
-- and raw poultry carries salmonella, rabbit tularemia, which only cooking kills: no charque, dry cure or cold smoke.
-- Their Corned keeps HOT_ONLY_DAYS (a light brine, not a salting), and in the Smokehouse they never dry: a stack waits
-- for its hot run and spoils as under-salted meat does, HOT_ONLY_UNDER_RATE times as fast (Corned's keeping, 14 / 6).
F.HOT_ONLY_INDICES = { [7] = true, [8] = true, [9] = true, [10] = true, [11] = true, [12] = true, [13] = true,
    [14] = true, [15] = true }
F.HOT_ONLY_DAYS = { 3, 6 }
F.HOT_ONLY_UNDER_RATE = 14 / 6
-- Above freezing a waiting stack is rotten within HOT_ONLY_MAX_DAYS of thawed hours (brined poultry keeps about two
-- weeks in a cold larder); frozen hours keep the slow curve, as a bird hung in a hard frost kept all winter.
F.HOT_ONLY_MAX_DAYS = 14
-- A whole bird is hollow: the salt and the heat go through no more than a thick cut's depth. It counts as this weight
-- for the cure and the cook (a chicken 38 hours in the tub and 7 stoked, a turkey 48 and 8).
-- The whole birds' MEAT_CUTS indices.
F.WHOLE_CHICKEN, F.WHOLE_TURKEY = 10, 14
F.TIMING_WEIGHTS = { [F.WHOLE_CHICKEN] = 0.4, [F.WHOLE_TURKEY] = 0.5 }
-- A whole bird hot smoked is carved as vanilla's Cut Chicken / Cut Turkey cuts a raw one: 2 legs, 2 wings, 2
-- fillets, by index; their food is shared by the vanilla cuts' script hunger, their weight from it x0.9 (vanilla's
-- RecipeCodeOnCreate.cutChicken).
F.WHOLE_BIRDS = { [F.WHOLE_CHICKEN] = { 7, 8, 9 }, [F.WHOLE_TURKEY] = { 11, 12, 13 } }
F.CARVE_BIRD_SHARE = 0.9
-- The meat stages, which take their icon from MEAT_CUTS' index.
F.MEAT_STAGES = {
    [F.CURED_MEAT] = true,
    [F.CHARQUE] = true, [F.SOAKED_CHARQUE] = true,
    [F.HOT_MEAT] = true, [F.DRY_CURED] = true,
    [F.COUNTRY_HAM] = true,
    [F.HOT_SLICE] = true, [F.DRY_CURED_SLICE] = true,
    [F.HAM_SLICE] = true,
}

function F.isMeatStage(fullType)
    return F.MEAT_STAGES[fullType] == true
end
-- A cut is pressed when the salt has reached its middle: PRESS_HOURS for a MEAT_PRESS_WEIGHT cut (a Beef or a
-- Venison), less by weight (a Steak about 29 hours), never under PRESS_MIN_HOURS. The heaviest cut sets the batch.
F.MEAT_PRESS_WEIGHT = 0.5
-- The long cure (6a), Country Cure Salted Meat: the salt goes all through, for meat that dries for weeks in the
-- Smokehouse. LONG_CUT_HOURS for cuts, LONG_LEG_HOURS for a batch with a leg in it. A leg takes only this one.
F.LONG_CUT_HOURS = 240
F.LONG_LEG_HOURS = 504
-- A leg takes half fish's salt, as a country ham's dry cure (about 8%): LEG_SALT_PER_STEP for each SALT_STEP.
F.LEG_SALT_PER_STEP = 1
-- What a frame cold dries.
F.COLD_FISH = { [F.GUTTED_FISH] = true, [F.FISH_HALF] = true }

-- How many stages a hanging piece shows, from fresh to done, and its styles. A piece picks a style at random when
-- it is hung, so a rack doesn't look all alike; each style draws as one of a spot's four looks (F.styleLook). All from
-- Tiles.lua.
F.DRYING_STAGES = Tiles.DRYING_STAGES
F.STYLE_SALT = Tiles.STYLES.SALT
F.STYLE_GUTTED = Tiles.STYLES.GUTTED
F.STYLE_HALF = Tiles.STYLES.HALF
F.STYLE_SALT_GUTTED = Tiles.STYLES.SALT_GUTTED
F.STYLE_SALT_HALF = Tiles.STYLES.SALT_HALF
F.SALT_STYLES = { 0, 0, 3, 4 }
F.COLD_STYLES = { 1, 1, 2 }
F.STYLE_MEAT = Tiles.STYLES.MEAT
-- A spot's tiles (0.4.76): a look at a stage (look x DRYING_STAGES + stage), then a rotten one a kind (ROTTEN_TILE plus
-- the kind).
F.LOOKS = Tiles.LOOKS
F.ROTTEN_LOOKS = Tiles.ROTTEN_LOOKS
F.ROTTEN_TILE = Tiles.ROTTEN_TILE
F.SPOT_TILES = Tiles.SPOT_TILES

-- The look a style draws as: a salt gutted fish as a whole salt fish, a cold half as a gutted fish.
local STYLE_LOOKS = { [F.STYLE_SALT] = F.LOOKS.SALT, [F.STYLE_SALT_GUTTED] = F.LOOKS.SALT,
    [F.STYLE_SALT_HALF] = F.LOOKS.SALT_HALF, [F.STYLE_GUTTED] = F.LOOKS.GUTTED, [F.STYLE_HALF] = F.LOOKS.GUTTED,
    [F.STYLE_MEAT] = F.LOOKS.MEAT }

function F.styleLook(style)
    return STYLE_LOOKS[style] or F.LOOKS.SALT
end

-- A spot's tile: the style's look at a stage, or rotten.
function F.spotTile(style, stage, rotten)
    if rotten then return F.ROTTEN_TILE + F.rottenLook(style) end
    return F.styleLook(style) * F.DRYING_STAGES + stage
end

-- The rotten look for a style: cold dried fish, meat, or salt fish.
function F.rottenLook(style)
    if style == F.STYLE_GUTTED or style == F.STYLE_HALF then return F.ROTTEN_LOOKS.COLD end
    if style == F.STYLE_MEAT then return F.ROTTEN_LOOKS.MEAT end
    return F.ROTTEN_LOOKS.SALT
end

-- Air above DRY_AIR_HUMIDITY slows drying, down to DAMP_AIR_RATE in saturated air.
F.DRY_AIR_HUMIDITY = 0.5
F.DAMP_AIR_RATE = 0.4
-- Weather can slow a frame this far and no further, so a batch takes MAX_DRY_DAYS at most, plus rain.
F.MAX_DRY_DAYS = 27
F.MIN_DRY_RATE = F.DRY_HOURS / (F.MAX_DRY_DAYS * 24)
-- Indoors the fish stays dry and the air moves less. People dried fish indoors with the
-- windows open, so it's slower but a fair choice. Under a roof with no room round it (a porch, an
-- open shed) salt fish dries as in the open air, in the shade and out of the rain.
F.SHELTERED_RATE = 0.65

-- Cold drying runs at full rate from 0 C to COLD_BEST, slows to COLD_MIN_RATE at COLD_LIMIT and stops
-- above that. Below freezing the water has to leave as vapour from ice, which is slower: down to
-- FROST_RATE at HARD_FROST, and HARD_FROST_RATE below it.
F.COLD_BEST = 5
F.COLD_LIMIT = 10
F.COLD_MIN_RATE = 0.67
F.HARD_FROST = -5
F.FROST_RATE = 0.8
F.HARD_FROST_RATE = 0.6
-- Stockfish dries in the wind: half speed in still air, up to WINDY_RATE in a breeze of WIND_GOOD
-- (ClimateManager's wind intensity, 0 to 1). Live wind averages about 0.11 on dry days.
F.WIND_GOOD = 0.25
F.CALM_RATE = 0.5
F.WINDY_RATE = 1.2
-- An open shed's roof breaks some of the wind, so cold drying there runs at this share, rain or not; through an
-- aired room's open window less of it still.
F.COVERED_COLD_RATE = 0.75
F.AIRED_COLD_RATE = 0.6
-- Fresh fish suffers most. Until it is FRESH_UNTIL dried and has formed a dry skin, hard frost breaks
-- the flesh and lying wet above freezing starts it going off. Each adds a little to its spoilage,
-- scaled by how wet the fish still is: FREEZE_DAMAGE_HOURS of hard frost on a fresh stack add
-- FREEZE_DAMAGE, WET_DAMAGE_HOURS wet add WET_DAMAGE. Together they never take it past DAMAGE_CAP.
F.FRESH_UNTIL = 0.3
F.FREEZE_DAMAGE_HOURS = 72
F.FREEZE_DAMAGE = 0.1
F.WET_DAMAGE_HOURS = 48
F.WET_DAMAGE = 0.05
F.DAMAGE_CAP = 0.25

-- Spoilage follows the season, not the day: it reads a running average of the weather over the
-- core's Weather.SEASON_HOURS, so a warm afternoon in January does nothing.
-- Unsalted fish spoils once the season is above RAW_SPOIL_ABOVE, and rots on the frame after
-- RAW_SPOIL_HOURS of that. Each 10 degrees more adds as much again
-- (twice as fast at +10, three times at +20).
F.RAW_SPOIL_ABOVE = 10
F.RAW_SPOIL_HOURS = 48
-- Salt fish only suffers in a hot, muggy season. SALT_SPOIL_HOURS of that is a rotten stack, and
-- less takes the same share off how long it keeps.
F.SALT_SPOIL_ABOVE = 22
F.SALT_SPOIL_HUMIDITY = 0.4
F.SALT_SPOIL_HOURS = 480
-- A tub in a warm season: the flesh by the spine spoils (bone taint) before the salt reaches it. Above WARM_CURE_ABOVE
-- (the season's mean) the batch picks up spoilage at WARM_CURE_SHARE of RAW_SPOIL_HOURS' rate, and each
-- 10 degrees more adds as much again. The pressed fish carries it onto the frame.
F.WARM_CURE_ABOVE = 20
F.WARM_CURE_SHARE = 0.25
-- The long cure wants the cold (0.4.14): its salt takes weeks to reach the middle, so the meat sours at the bone
-- unless the season stays cool, which is why hog killing waited for frost. Above LONG_CURE_ABOVE (the season's mean)
-- a Country Cure batch spoils in step with the warmth, and is rotten after LONG_CURE_ROT_HOURS (a leg's cure) at
-- LONG_CURE_ROT_AT. At 12 C a leg loses two fifths of its keeping and cuts a fifth. On top of the warm cure above.
F.LONG_CURE_ABOVE = 10
F.LONG_CURE_ROT_AT = 15
F.LONG_CURE_ROT_HOURS = 504
-- The tub in the cold (realism pass): salt moves slowly near freezing, and the old rule added a day
-- of cure for each day the meat froze. The cure goes by the tub's place temperature, { C, speed } joined by straight
-- lines: full from 2 C, half at -5, a quarter from -10 (a brine doesn't freeze solid).
F.TUB_CURE_POINTS = { { -10, 0.25 }, { -5, 0.5 }, { 2, 1 } }
-- Salt fish hangs in the shade. In open sun above HEAT_ABOVE (the temperature now), until it is
-- SALT_FRESH_UNTIL dried, the skin hardens over wet flesh and the fat rusts: HEAT_DAMAGE_HOURS of that on
-- a fresh stack add HEAT_DAMAGE to its spoilage, scaled by how wet it still is, within DAMAGE_CAP.
F.HEAT_ABOVE = 25
F.SALT_FRESH_UNTIL = 0.5
F.HEAT_DAMAGE_HOURS = 24
F.HEAT_DAMAGE = 0.05
-- Stockfish matures in storage, as it did in the warehouses after the racks: MATURE_DAYS on its own food clock
-- (a fridge slows it, a freezer stops it). Rehydrated, a ripe fish lifts the mood by MATURE_UNHAPPY and a
-- fresh-off-the-frame one lowers it as much; halfway is neither. A dish takes on the share it gets.
F.MATURE_DAYS = 60
F.MATURE_UNHAPPY = 10
-- Dry cured meat ages after it has dried (6c), on its own food clock as stockfish matures: a cut AGE_CUT_DAYS, a
-- Country Ham AGE_HAM_DAYS. Left hanging where it dried it takes HANG_AGE_SHARE of that; once down it can't go
-- back up. It is good to eat before; Aged, a whole cut lifts the mood by AGED_CUT_UNHAPPY and a whole ham by
-- AGED_HAM_UNHAPPY, and the ham takes AGED_HAM_BOREDOM off the boredom: the ham's reward, with its slices.
F.AGE_CUT_DAYS = 30
F.AGE_HAM_DAYS = 90
F.HANG_AGE_SHARE = 0.75
F.AGED_CUT_UNHAPPY = -8
F.AGED_HAM_UNHAPPY = -40
F.AGED_HAM_BOREDOM = -20
-- Rinsing Salt Cured fish, as on the Volga: the excess salt soaked off before it hangs. Optional. It takes
-- RINSE_LITRES of water a fish, leaves RINSED_THIRST of the thirst, and the fish keeps RINSED_KEEPING as long
-- (less salt, less protection). A Salt Dried fish from it loses its sharp tang too (unhappiness 3 to 0).
F.RINSE_LITRES = 0.15
F.RINSED_THIRST = 2 / 3
F.RINSED_KEEPING = 0.9
F.RINSE_REACH = 3
F.RINSE_TICKS = 60

-- The Stockfish Pallet: stockfish on it ripens faster where the warehouses kept it, dry and airy. An aired room (TP
-- Core's: a window open) PALLET_AIRED times the food clock, a shut room PALLET_ROOM; covered, outdoors or a basement
-- ("too damp") no faster than a shelf. Its stack shows a third, two thirds or full by the weight on it.
F.PALLET_AIRED = 2
F.PALLET_ROOM = 1.5
F.PALLET_CAPACITY = 20
F.PALLET_LEVELS = 3
-- A Stockfish Bale: stockfish tied up for carrying and storing, as it was shipped from the Lofoten. It holds
-- BALE_CAPACITY weight of stockfish (the script's Capacity) and nothing else; the fish keep their own clocks.
-- It is tied with one use of Twine or a Rope, and untying gives the cord back; the bale weighs what tied it.
F.BALE_CAPACITY = 10
F.BALE_CORDS = {
    { type = "Base.Twine", key = "twine", uses = 1, weight = 0.1 },
    { type = "Base.Rope", key = "rope", weight = 0.8 },
}
F.BALE_TIE_TICKS = 120
F.BALE_UNTIE_TICKS = 60

-- Cold smoke (5d, TraditionalPreservationFishMeatSmokehouse.lua): fire hours count only on a day at or under
-- COLD_SMOKE_MAX (a banked smoulder lifts the shed BANKED_LIFT, 15 C; over 30 C at the meat it cooks rather than
-- smokes; 20 C until 0.4.12, when the lift grew from 10 to 15). Stacks in
-- a Smokehouse, by stackId, as the World last saw them (not saved); a finished one waits at SHED_WAIT until seen.
F.COLD_SMOKE_MAX = 15
-- The smoulder's warmth: while the Stone Hearth burns, a Smokehouse stack dries as if the shed were this much warmer than
-- outdoors, banked or stoked, and the warmed air holds the same water, so its humidity halves every 10 C (F.liftedRates).
-- A stack's modData.burning holds the fire's mode, Core's Fire.STOKED or BANKED.
F.BANKED_LIFT = 15
F.STOKED_LIFT = 20
F.smokeStations = {}
-- Every hanging stack's station, by stackId, as the World last saw it (not saved): a stack that rots comes down as
-- what was hung, not as the finished thing (F.rottenOutputs).
F.stackStations = {}
F.SHED_WAIT = 0.999

-- Charque (phase 3c): Salt Cured meat dried in the summer sun, as in Brazil's charqueadas. CHARQUE_HOURS at a rate of
-- 1, which takes CHARQUE_FULL_HEAT and up (heat helps, and does no harm), nothing at 0 C or below, in between by
-- the temperature; damp air slows it as salt fish (airRate). Still air dries at CHARQUE_CALM_RATE, a breeze of
-- WIND_GOOD at CHARQUE_WINDY_RATE. Under an open roof it dries as in the open without the rain; indoors at
-- CHARQUE_INDOORS_RATE with no wind. On an open frame, CHARQUE_RAIN_HOURS of rain take back CHARQUE_REWET of the
-- progress. Spoilage is salt fish's hot and muggy rule only. Numbers from tools/charque_report.lua.
F.CHARQUE_HOURS = 120
F.CHARQUE_FULL_HEAT = 25
F.CHARQUE_CALM_RATE = 0.65
F.CHARQUE_WINDY_RATE = 1.2
F.CHARQUE_INDOORS_RATE = 0.65
F.CHARQUE_REWET = 0.1
F.CHARQUE_RAIN_HOURS = 6
-- The sandbox's Charque switch: off, meat can't go in the Salting Tub nor hang.
F.CHARQUE_ON = true

-- Dry curing (6b): meat hung in the Smokehouse never comes out Charque. It dries slowly in cool air, as a ham or a
-- side of suho meso does: its need is by the heaviest piece (DRY_CURE_HOURS: three weeks at a rate of 1 for a Beef,
-- six for a Leg of Pork, a Steak about 19 days), and its rate is full from DRY_CURE_FULL_HEAT (a cellar's
-- 12 C) and never under DRY_CURE_FROST_RATE (frost only slows it), times the air's (airRate). The fire's warmth
-- lifts the shed as it does for fish (F.liftedRates).
F.DRY_CURE_HOURS = { { 0.45, 504 }, { 2.25, 1008 } }
F.DRY_CURE_FULL_HEAT = 12
F.DRY_CURE_FROST_RATE = 0.25
-- Country Cured meat also dry cures on a Frame, Beam or Gantry in the shade (0.4.15): under a roof or indoors as in the shed
-- with the fire out, and in a basement, the curing cellar, by the basement's own temperature (Weather.basementTemperature)
-- times DRY_CURE_BASEMENT_RATE (the still air takes a third): about 76 days a cut in January, 32 from June to September.
-- An under-salted stack there spoils by that temperature. Always air dried: smoke is the Smokehouse's.
F.DRY_CURE_BASEMENT_RATE = 2 / 3
-- Under-salted (6b): Corned meat has salt for a few days, not for weeks in the shed. Until a hot cook is done it
-- picks up spoilage by the shed's temperature: rotten in UNDER_CURE_HOURS at UNDER_CURE_AT, UNDER_CURE_TENFOLD times
-- faster for every 10 C more (and slower for less), no faster than at UNDER_CURE_MAX. Near freezing it ends about
-- half spoiled; in a shed at 10 C and up, or by a banked fire, it rots before it has dried.
F.UNDER_CURE_HOURS = 672
F.UNDER_CURE_AT = 10
F.UNDER_CURE_TENFOLD = 5
F.UNDER_CURE_MAX = 30
-- Realism pass: above freezing, under-salted red meat is rotten within UNDER_CURE_MAX_DAYS of thawed
-- hours, however cool (bone taint: the middle sours before the salt gets there); frozen hours keep the slow curve. A
-- rinsed piece lost surface salt too: it spoils 1 / RINSED_KEEPING as fast.
F.UNDER_CURE_MAX_DAYS = 42

-- The fish each IconsForTexture entry in the item scripts belongs to, in the same order.
F.FISH_ICONS = {
    "Base.FishFillet", "Base.Salmon", "Base.LargemouthBass", "Base.SmallmouthBass", "Base.SpottedBass",
    "Base.StripedBass", "Base.Walleye", "Base.Sauger", "Base.BlackCrappie", "Base.WhiteCrappie",
    "Base.Bluegill", "Base.RedearSunfish", "Base.GreenSunfish", "Base.BlueCatfish", "Base.ChannelCatfish",
    "Base.FlatheadCatfish", "Base.Muskellunge", "Base.WhiteBass", "Base.YellowPerch", "Base.FreshwaterDrum",
    "Base.AligatorGar", "Base.Paddlefish",
}

-- Each fish's and each raw cut's icon index (0-based), looked up rather than searched for.
local function indexOf(list)
    local found = {}
    for index, fullType in ipairs(list) do found[fullType] = found[fullType] or index - 1 end
    return found
end
local FISH_ICON_INDEX, CUT_INDEX = indexOf(F.FISH_ICONS), indexOf(F.MEAT_CUTS)

-- What each stage keeps of the item it was made from. With a maxWeight, each fish keeps a
-- random share between weight and maxWeight. Soaking gives back the bulk drying took (hunger 0.7).
-- A prep stage names the fish itself (Gutted Walleye, Walleye Half); the others go in brackets after it.
F.STAGES = {
    [F.PRESSED_FISH] = { name = "IGUI_TraditionalPreservationFishMeat_Pressed", weight = 0.88, maxWeight = 0.93, nutrition = 1, hunger = 1, salty = true },
    [F.SALT_DRIED] = { name = "IGUI_TraditionalPreservationFishMeat_Dried", weight = 0.45, nutrition = 0.9, hunger = 0.7, salty = true, rinsedUnhappy = 0 },
    [F.SOAKED_SALT_FISH] = { name = "IGUI_TraditionalPreservationFishMeat_SoakedSalt", weight = 1.8, nutrition = 1, hunger = 1 / 0.7 },
    [F.GUTTED_FISH] = { name = "IGUI_TraditionalPreservationFishMeat_Gutted", weight = 1, nutrition = 1, hunger = 1, gutted = true, headless = true, prep = true },
    [F.FISH_HALF] = { weight = 1, nutrition = 1, hunger = 1, prep = true },
    [F.COLD_DRIED] = { name = "IGUI_TraditionalPreservationFishMeat_ColdDried", weight = 0.22, nutrition = 0.95, hunger = 0.7, matures = true },
    [F.SOAKED_COLD_FISH] = { name = "IGUI_TraditionalPreservationFishMeat_SoakedCold", weight = 3, nutrition = 1, hunger = 1 / 0.7, ripened = true },
    [F.CURED_MEAT] = { name = "IGUI_TraditionalPreservationFishMeat_Cured", weight = 0.88, maxWeight = 0.93, nutrition = 1, hunger = 1, salty = true },
    -- About half the raw cut's weight (0.55 of the cured), as salt fish keeps its food. Soaked, it gets back about as much.
    [F.CHARQUE] = { name = "IGUI_TraditionalPreservationFishMeat_Charque", weight = 0.55, nutrition = 0.9, hunger = 0.7, salty = true },
    -- Hot smoked (the Smokehouse, 5c): cooked, still moist, about 70% of the raw weight (0.78 of the cured).
    [F.HOT_FISH] = { name = "IGUI_TraditionalPreservationFishMeat_HotSmoked", weight = 0.78, nutrition = 1, hunger = 1, salty = true },
    [F.HOT_MEAT] = { name = "IGUI_TraditionalPreservationFishMeat_HotSmoked", weight = 0.78, nutrition = 1, hunger = 1, salty = true },
    [F.SOAKED_CHARQUE] = { name = "IGUI_TraditionalPreservationFishMeat_SoakedCharque", weight = 1.6, nutrition = 1, hunger = 1 / 0.7, salty = true },
    -- Cold smoked (the Smokehouse, 5d): dried in smoky air, as dry as Salt Dried fish or charque. Meat smoked so is no
    -- longer charque but the start of the Dry Cured line, named by the animal ("Beef (Cold Smoked)").
    [F.COLD_FISH_OUT] = { name = "IGUI_TraditionalPreservationFishMeat_ColdSmoked", weight = 0.45, nutrition = 0.9, hunger = 0.7, salty = true },
    [F.DRY_CURED] = { name = "IGUI_TraditionalPreservationFishMeat_ColdSmoked", weight = 0.55, nutrition = 0.9, hunger = 0.7, salty = true, dryCured = true, ages = true },
    -- A Leg of Pork dried in the Smokehouse (6b): Dry Cured meat's shares, an item of its own for its longer keeping.
    [F.COUNTRY_HAM] = { name = "IGUI_TraditionalPreservationFishMeat_ColdSmoked", weight = 0.55, nutrition = 0.9, hunger = 0.7, salty = true, dryCured = true, ages = true, ham = true },
    -- Slices (6c, TraditionalPreservationFishMeatSlices.lua): named by the piece they were cut from (modData.cut).
    [F.HOT_SLICE] = { slice = true, hot = true },
    [F.DRY_CURED_SLICE] = { slice = true },
    [F.HAM_SLICE] = { slice = true },
}

-- The animal each of MEAT_CUTS comes from, by model index, for the finished meat's names.
F.MEAT_ANIMALS = { "Beef", "Beef", "Mutton", "Venison", "Pork", "Pork", "Pork",
    "Chicken", "Chicken", "Chicken", "Chicken", "Turkey", "Turkey", "Turkey", "Turkey", "Rabbit" }

-- Hours in the tub for a batch whose heaviest fish weighs this much.
function F.pressHours(heaviest)
    local share = (heaviest - F.PRESS_SMALL_WEIGHT) / (F.PRESS_BIG_WEIGHT - F.PRESS_SMALL_WEIGHT)
    share = math.min(math.max(share, 0), 1)
    return F.PRESS_MIN_HOURS + share * (F.PRESS_HOURS - F.PRESS_MIN_HOURS)
end

-- Hours in the tub for a batch of meat whose heaviest cut weighs this much.
function F.meatPressHours(heaviest)
    return math.min(math.max(F.PRESS_HOURS * heaviest / F.MEAT_PRESS_WEIGHT, F.PRESS_MIN_HOURS), F.PRESS_HOURS)
end

-- Hours of the long cure: a leg's if the batch has one.
function F.longCureHours(leg)
    return leg and F.LONG_LEG_HOURS or F.LONG_CUT_HOURS
end

-- A Leg of Pork, raw or at any stage.
function F.isLeg(item)
    if item:getFullType() == F.LEG_OF_PORK then return true end
    return F.isMeatStage(item:getFullType()) and item:getModelIndex() == F.LEG_INDEX
end

-- Pork or a leg at any meat stage, by its model index.
function F.isPork(item)
    return F.isMeatStage(item:getFullType()) and F.PORK_INDICES[item:getModelIndex()] == true
end

-- A cut's MEAT_CUTS index, raw (by its type) or at a meat stage (by its model index), or nil.
function F.cutIndex(item)
    local fullType = item:getFullType()
    if F.isMeatStage(fullType) then return item:getModelIndex() end
    return CUT_INDEX[fullType]
end

-- Poultry or rabbit, raw or at any meat stage: hot smoke only.
function F.isHotOnly(item)
    return F.HOT_ONLY_INDICES[F.cutIndex(item) or -1] == true
end

-- The weight a piece counts as for the cure's and the cook's hours: its own, or a whole bird's TIMING_WEIGHTS.
function F.timingWeight(item)
    return F.TIMING_WEIGHTS[F.cutIndex(item) or -1] or item:getActualWeight()
end

-- Why a drying station refuses an item, as translation keys (the *Refusal functions, F.mixedMeat; Fresh Sausage's
-- in ...Sausage).
F.REFUSALS = {
    needsPressed = "IGUI_TraditionalPreservationFishMeat_NeedsPressed",
    charqueOff = "IGUI_TraditionalPreservationFishMeat_CharqueOff",
    sausageSmokehouse = "IGUI_TraditionalPreservationFishMeat_SausageSmokehouse",
    sausageFried = "IGUI_TraditionalPreservationFishMeat_SausageFried",
    countryCuredSmokehouse = "IGUI_TraditionalPreservationFishMeat_CountryCuredSmokehouse",
    porkSmokehouse = "IGUI_TraditionalPreservationFishMeat_PorkSmokehouse",
    hotOnlySmokehouse = "IGUI_TraditionalPreservationFishMeat_HotOnlySmokehouse",
    mixedMeat = "IGUI_TraditionalPreservationFishMeat_MixedMeat",
    frameFull = "IGUI_TraditionalPreservationFishMeat_FrameFull",
    tooHeavy = "IGUI_TraditionalPreservationFishMeat_TooHeavy",
    stackFull = "IGUI_TraditionalPreservationFishMeat_StackFull",
    noColdIndoors = "IGUI_TraditionalPreservationFishMeat_NoColdIndoors",
    freshSausageSmokehouse = "IGUI_TraditionalPreservationFishMeat_FreshSausageSmokehouse",
    freshSausageCooked = "IGUI_TraditionalPreservationFishMeat_FreshSausageCooked",
}

function F.hasRoom(capacity, storedWeight, weight)
    return storedWeight + weight <= capacity
end

-- Vanilla slots take any item and leave Craft greyed out, so each drying station names what it hangs.
function F.fishRefusal(fullType)
    if fullType ~= F.PRESSED_FISH and not F.COLD_FISH[fullType] and fullType ~= F.CURED_MEAT
            and fullType ~= F.BLOOD_SAUSAGE and fullType ~= F.FRESH_SAUSAGE then
        return F.REFUSALS.needsPressed
    end
    if fullType == F.CURED_MEAT and not F.CHARQUE_ON then return F.REFUSALS.charqueOff end
    return nil
end

-- Blood sausage hangs in the Smokehouse only, boiled and never fried (Smoked Blood Sausage); Fresh Sausage there
-- only too, raw (F.freshSausageRefusal, Smoked Sausage).
function F.sausageRefusal(hanger, item)
    if item:getFullType() == F.FRESH_SAUSAGE then return F.freshSausageRefusal(hanger, item) end
    if item:getFullType() ~= F.BLOOD_SAUSAGE then return nil end
    if not hanger.closed then return F.REFUSALS.sausageSmokehouse end
    if F.wasFried(item) then return F.REFUSALS.sausageFried end
    return nil
end

-- Meat a drying station refuses, by where it stands (Weather.placeOf; in the Smokehouse Smokehouse.PLACE). The Smokehouse takes
-- all. Country Cured meat, pork too, dry cures in the shade: a Frame, Beam or Gantry under a roof, a Frame or Beam
-- indoors or in a basement, never in the open (sun and rain are charque's). Corned pork has only its hot cook: in
-- sun and wind its fat goes rancid, and it has too little salt to hang.
function F.meatRefusal(hanger, place, item)
    if hanger.closed then return nil end
    if item:getFullType() == F.CURED_MEAT and item:getModData().longCure then
        if place == "Open" then return F.REFUSALS.countryCuredSmokehouse end
        return nil
    end
    if F.isPork(item) then return F.REFUSALS.porkSmokehouse end
    if F.isHotOnly(item) then return F.REFUSALS.hotOnlySmokehouse end
    return nil
end

-- One stack of meat is red meat or hot-smoke-only meat (poultry, rabbit), never both: they finish differently.
function F.mixedMeat(stored, item)
    if stored:getFullType() ~= F.CURED_MEAT or item:getFullType() ~= F.CURED_MEAT then return nil end
    if F.isHotOnly(stored) ~= F.isHotOnly(item) then return F.REFUSALS.mixedMeat end
    return nil
end

-- What hangs in a stack: "salt" fish, "cold" fish, "meat", "sausage" (Smoked Blood Sausage) or "freshSausage"
-- (Smoked Sausage). One stack is one method.
function F.hangMethod(fullType)
    if F.COLD_FISH[fullType] then return "cold" end
    if fullType == F.CURED_MEAT then return "meat" end
    if fullType == F.BLOOD_SAUSAGE then return "sausage" end
    if fullType == F.FRESH_SAUSAGE then return "freshSausage" end
    return "salt"
end

-- A tileset can't hold more than 512 tiles, so everything from FIRST_SHEET_SIZE on is in a second
-- one, and the rotten stacks in a third (0.4.21). Sprites are numbered straight through them.
F.FIRST_SHEET_SIZE = Tiles.FIRST_SHEET_SIZE
local SHEET_STARTS = {}
do
    local start = 0
    for n, sheet in ipairs(Tiles.SHEETS) do
        SHEET_STARTS[n] = start
        start = start + sheet.tiles
    end
end

function F.spriteName(index)
    for n = #SHEET_STARTS, 1, -1 do
        if index >= SHEET_STARTS[n] then return Tiles.SHEETS[n].prefix .. (index - SHEET_STARTS[n]) end
    end
end

-- The number of one of this mod's sprites, or nil for any other.
function F.spriteIndex(name)
    local sheet, index = string.match(name or "", "^traditionalpreservationfishmeat_0(%d)_(%d+)$")
    local start = sheet and SHEET_STARTS[tonumber(sheet)]
    if not start then return nil end
    return tonumber(index) + start
end

-- The number of a station's own sprite, or nil for anything that isn't one of this mod's stations. A table
-- lookup: the slot rules ask this of every crafting station's slot.
local STATION_INDEX = {}
for _, name in ipairs(Tiles.STATIONS) do STATION_INDEX[name] = F.spriteIndex(name) end

function F.stationIndex(isoObject)
    local sprite = isoObject and isoObject:getSprite()
    local name = sprite and sprite:getName()
    return name and STATION_INDEX[name]
end

-- The Hanging Beam and the Gantry go up anywhere but in front of a door (TP Core's Doors: the Stone Hearth's mouth,
-- the Stone Hearth's door, the Smokehouse's). In a shut room what hangs on them waits for a window.
function F.doorFree(params)
    local name = params.tileInfo and params.tileInfo:getSpriteName()
    return Doors.fits(params.square, name)
end

-- The hanger a station's sprite belongs to, whichever way it faces, or nil for a tub.
function F.hangerFor(spriteIndex)
    return F.HANGERS[spriteIndex - spriteIndex % 2]
end

-- The hanger of a station: one of this mod's, or either tile of TP Core's Smokehouse; nil for a tub or anything else.
function F.hangerOf(isoObject)
    local index = F.stationIndex(isoObject)
    if index then return F.hangerFor(index) end
    if Smokehouse.isChamber(isoObject) then return F.CHAMBER_HANGER end
end

-- Whether an object is a Salting Tub (its first two sprites, one a face).
function F.isTub(isoObject)
    local index = F.stationIndex(isoObject)
    return index ~= nil and index < Tiles.FRAME
end

-- Whether an object is one of the stations this mod works: its own, or the Smokehouse.
function F.isStation(isoObject)
    return F.stationIndex(isoObject) ~= nil or Smokehouse.isChamber(isoObject)
end

-- Whether an item is this mod's to judge in the Smokehouse's slots: anything of its own module.
function F.ownsItem(item)
    return string.find(item:getFullType(), "^TraditionalPreservationFishMeat%.") ~= nil
end

-- Why a fish can't join the stack waiting on a frame, as a translation key, or nil if it can.
-- busyStacks is what is already hanging: running stacks and finished ones not yet taken. waitingPieces is how many
-- pieces already wait in the stack (nil counts as none).
function F.frameRefusal(hanger, busyStacks, waitingWeight, weight, waitingPieces)
    if busyStacks >= hanger.stacks then return F.REFUSALS.frameFull end
    if weight > hanger.stackWeight then return F.REFUSALS.tooHeavy end
    if (waitingPieces or 0) >= hanger.stackPieces
            or not F.hasRoom(hanger.stackWeight, waitingWeight, weight) then
        return F.REFUSALS.stackFull
    end
    return nil
end

-- Cold drying needs moving air: a basement or the Smokehouse (Smokehouse.PLACE; else place is Weather.placeOf's)
-- refuses gutted fish. A room takes them: aired it dries them, shut it waits for a window. The Smokehouse doesn't
-- list the recipe either.
local COLD_PLACES = { Open = true, Covered = true, AiredRoom = true, Sheltered = true }

function F.coldRefusal(place)
    if not COLD_PLACES[place] then return F.REFUSALS.noColdIndoors end
    return nil
end

-- A random hanging look for a new stack, kept in its modData so it doesn't change.
function F.pickStyle(styles)
    return styles[ZombRand(#styles) + 1]
end

-- The style to show for an item: its stack's, or for fish still waiting, what it is.
function F.fishStyle(item)
    local style = item:getModData().style
    if style then return style end
    local fullType = item:getFullType()
    if fullType == F.FISH_HALF then return F.STYLE_HALF end
    if fullType == F.GUTTED_FISH or fullType == F.COLD_DRIED then return F.STYLE_GUTTED end
    if fullType == F.CURED_MEAT or fullType == F.CHARQUE then return F.STYLE_MEAT end
    return F.STYLE_SALT
end

-- The look for a fish still drying. The last stage is kept for fish that have finished.
function F.dryingStage(progress)
    local running = F.DRYING_STAGES - 1
    return math.min(math.floor(progress * running), running - 1)
end

-- What a warm cure took from a stack's fish, by weight.
function F.stackCureSpoiled(fish)
    local weight, spoiled = 0, 0
    for i = 0, fish:size() - 1 do
        local item = fish:get(i)
        weight = weight + item:getActualWeight()
        spoiled = spoiled + item:getActualWeight() * (item:getModData().cureSpoiled or 0)
    end
    return weight > 0 and spoiled / weight or 0
end

-- Recipe data is pooled with its ModData (ENGINE_NOTES): a new stack starts from nothing, so it can't inherit an old
-- one's place, shed or smoke.
local function startStack(craftRecipeData)
    local ledger = F.getLedger()
    local modData = craftRecipeData:getModData()
    F.clearModData(modData)
    modData.dried = 0
    modData.spoiled = F.stackCureSpoiled(craftRecipeData:getAllInputItemsWithFlag("ItemCount"))
    modData.stackId = getGameTime():getWorldAgeHours()
    F.markStack(modData, ledger)
end

-- How far a stack's hot cook has come in the stoked run now counting, 0 to 1; nil with no run counting (not in a
-- joined Smokehouse, the fire banked or out over an hour, or a leg in the stack). A broken run takes it back to nil.
function F.cookShare(modData)
    if not modData.hotSmokeHoursNeeded or modData.noHotSmoke or (modData.hotSmokeHours or 0) <= 0 then return nil end
    return math.min(modData.hotSmokeHours / modData.hotSmokeHoursNeeded, 1)
end

-- The stack's bar: how far it has dried, or its hot cook while that is further along (a run that breaks off drops
-- it back to the drying). The cook itself ends the stack only through the World (F.hotStations).
function F.stackProgress(modData, hours)
    local progress = math.min(modData.dried / hours, 1)
    local cook = F.cookShare(modData)
    if cook and cook > progress then progress = math.min(cook, F.SHED_WAIT) end
    return progress
end

-- Whether a hanging stack is lost as a whole. Under-salting ends a stack only when every piece in it is Corned:
-- Country Cured pieces dry on, and the stack keeps its drying look.
function F.stackRotten(modData)
    return (modData.spoiled or 0) + (modData.allUnder and (modData.underSpoiled or 0) * (modData.underScale or 1) or 0) >= 1
end

-- What under-salting has taken from one hung piece: none from a Country Cured one; a rinsed Corned piece lost surface
-- salt too, and spoils 1 / RINSED_KEEPING as fast (realism pass).
function F.underLoss(piece, modData)
    local pieceModData = piece:getModData()
    if pieceModData.longCure then return 0 end
    return (modData.underSpoiled or 0) * (pieceModData.rinsed and 1 / F.RINSED_KEEPING or 1)
end

-- Shows a stack's progress, and ends it early if it has rotted or its hot smoking is done (the Smokehouse). A stack
-- in a Smokehouse waits at the end until the World has seen its shed since the load, so OnCreate can swap in Cold
-- Smoked outputs (F.smokeStations).
local function showProgress(craftRecipeData, modData, hours)
    local time = craftRecipeData:getRecipe():getTime()
    local rotten = F.stackRotten(modData)
    local progress = (rotten or F.hotStations[modData.stackId]) and 1 or F.stackProgress(modData, hours)
    if progress >= 1 and F.inShed(modData) and not F.smokeStations[modData.stackId] then progress = F.SHED_WAIT end
    -- A dry-curing stack on a frame waits for the World too, which swaps its Charque for dry cured meat.
    if progress >= 1 and not F.inShed(modData) and F.dryCuring(modData) and not F.stackStations[modData.stackId] then progress = F.SHED_WAIT end
    craftRecipeData:setElapsedTime(progress * time)
end

-- OnStart for salted fish on a frame: marks the ledger and picks a look.
function F.onDryStart(craftRecipeData)
    startStack(craftRecipeData)
    F.startSmoke(craftRecipeData:getModData(), craftRecipeData:getAllInputItemsWithFlag("ItemCount"), false)
    craftRecipeData:getModData().style = F.pickStyle(F.SALT_STYLES)
end

function F.onDryUpdate(craftRecipeData)
    local modData = craftRecipeData:getModData()
    if not modData.dried then return end
    F.saltStep(modData, F.getLedger())
    showProgress(craftRecipeData, modData, F.DRY_HOURS)
end

-- OnStart for unsalted fish on a cold frame.
function F.onColdDryStart(craftRecipeData)
    startStack(craftRecipeData)
    craftRecipeData:getModData().style = F.pickStyle(F.COLD_STYLES)
end

function F.onColdDryUpdate(craftRecipeData)
    local modData = craftRecipeData:getModData()
    if not modData.dried then return end
    F.coldStep(modData, F.getLedger())
    showProgress(craftRecipeData, modData, F.COLD_DRY_HOURS)
end

-- OnStart for Salt Cured meat on a frame (charque) or in the Smokehouse (dry curing).
function F.onCharqueStart(craftRecipeData)
    startStack(craftRecipeData)
    F.startSmoke(craftRecipeData:getModData(), craftRecipeData:getAllInputItemsWithFlag("ItemCount"), true)
    craftRecipeData:getModData().style = F.STYLE_MEAT
end

function F.onCharqueUpdate(craftRecipeData)
    local modData = craftRecipeData:getModData()
    if not modData.dried then return end
    F.charqueStep(modData, F.getLedger())
    showProgress(craftRecipeData, modData, F.meatHours(modData))
end

-- A fish from another mod isn't in the list, and keeps the stage's own icon.
function F.iconIndex(source)
    local fullType = source:getFullType()
    -- Stages after these list their icons three times over: whole, gutted, then half.
    if fullType == F.GUTTED_FISH then return source:getModelIndex() + #F.FISH_ICONS end
    if fullType == F.FISH_HALF then return source:getModelIndex() + #F.FISH_ICONS * 2 end
    if source:getModelIndex() >= 0 then return source:getModelIndex() end
    return FISH_ICON_INDEX[fullType] or CUT_INDEX[fullType] or -1
end

-- Whether a piece weighs more than a limit, past the float's rounding (WEIGHT_SLACK).
function F.heavierThan(item, limit)
    return item:getActualWeight() > limit + F.WEIGHT_SLACK
end

-- Whether vanilla could cut this fish, which is what gives guts.
function F.hasGuts(fish)
    return fish:hasTag(ItemTag.UNCUT_FISH) and not F.UNSLICEABLE[fish:getFullType()]
        and F.heavierThan(fish, F.MIN_SLICE_WEIGHT)
end

-- Whether gutting this fish gives a Fish Head.
function F.hasHead(fish)
    return F.hasGuts(fish) and F.heavierThan(fish, F.HEAD_MIN_WEIGHT)
end

-- A fillet vanilla cut counts as the food it holds; anything else, a loot fillet included, as what it weighs.
function F.foodWeight(fish)
    if fish:getFullType() == "Base.FishFillet" and fish:isCustomWeight() then
        return fish:getActualWeight() * F.FILLET_FOOD_WEIGHT
    end
    return fish:getActualWeight()
end

-- What a fish weighs in the salt: gutted if it has guts, and a fillet by its food.
function F.packedWeight(fish)
    if F.hasGuts(fish) then return fish:getActualWeight() * (1 - F.GUTS_WEIGHT) end
    return F.foodWeight(fish)
end

-- The salt this fish or cut takes in the Salting Tub.
function F.saltFor(fish)
    local steps = math.floor(F.packedWeight(fish) / F.SALT_STEP + 0.5 + 1e-6)
    -- Poultry and rabbit take a leg's half too: a light brine's salt, not charque's.
    local light = fish:getFullType() == F.LEG_OF_PORK or F.isHotOnly(fish)
    local perStep = light and F.LEG_SALT_PER_STEP or F.SALT_PER_STEP
    return math.max(F.SALT_MIN, perStep * steps)
end

-- A whole or gutted fish over SALT_WHOLE_MAX, which has to be split before it goes in the salt.
function F.tooBigToSaltWhole(fish)
    local whole = fish:hasTag(ItemTag.UNCUT_FISH) and not F.UNSLICEABLE[fish:getFullType()]
    local gutted = fish:getFullType() == F.GUTTED_FISH
    return (whole or gutted) and fish:getActualWeight() > F.SALT_WHOLE_MAX
end

function F.isMeatCut(fullType)
    return CUT_INDEX[fullType] ~= nil
end

-- Hands a share of a fish's food to another item; hungerShare defaults to share.
-- Eating lowers HungChange and leaves BaseHunger, so a part-eaten fish stays part-eaten.
local function copyFood(from, to, share, hungerShare)
    hungerShare = hungerShare or share
    to:setCalories(from:getCalories() * share)
    to:setProteins(from:getProteins() * share)
    to:setLipids(from:getLipids() * share)
    to:setCarbohydrates(from:getCarbohydrates() * share)
    to:setBaseHunger(from:getBaseHunger() * hungerShare)
    to:setHungChange(from:getHungChange() * hungerShare)
end

F.copyFood = copyFood

-- Gives the next stage of a fish its share of the last stage's food, less the head if this stage takes it off.
function F.carry(source, target)
    local stage = F.STAGES[target:getFullType()]
    local headless = stage.headless and F.hasHead(source)
    -- The head takes its share of the food with it.
    local kept = headless and 1 - F.HEAD_FOOD or 1
    copyFood(source, target, stage.nutrition * kept, stage.hunger * kept)
    local keptWeight = stage.maxWeight and ZombRandFloat(stage.weight, stage.maxWeight) or stage.weight
    local cut = 0
    if stage.gutted and F.hasGuts(source) then cut = F.GUTS_WEIGHT end
    if headless then cut = cut + F.HEAD_WEIGHT end
    keptWeight = keptWeight * (1 - cut)
    target:setActualWeight(F.foodWeight(source) * keptWeight)
    target:setCustomWeight(true)

    -- The display name has the fish's size, as in Small Black Crappie, and a trailing space from vanilla.
    -- A stage item that never had a species (one spawned in) keeps its plain name, so a Salt Dried
    -- Fish doesn't become a Rehydrated Salt Dried Salt Dried Fish.
    local sourceData, targetData = source:getModData(), target:getModData()
    local fishName = sourceData.fishName
    if not fishName and not F.STAGES[source:getFullType()] then
        fishName = string.gsub(source:getDisplayName(), "%s+$", "")
    end
    if fishName then targetData.fishName = fishName end

    if sourceData.fishName then
        targetData.sliceable = sourceData.sliceable
    else
        targetData.sliceable = not F.UNSLICEABLE[source:getFullType()] and F.heavierThan(source, F.MIN_SLICE_WEIGHT)
    end

    if sourceData.rinsed then
        targetData.rinsed = true
        F.applyRinse(target)
    end

    -- After the icon, which tells whether the fish was gutted.
    target:setModelIndex(F.iconIndex(source))
    F.rename(target)
end

-- Salt Cured fish, and Salt Cured meat as the charqueadas washed it before the sun.
F.RINSE_TYPES = { [F.PRESSED_FISH] = true, [F.CURED_MEAT] = true }

-- Only Salt Cured fish or meat not rinsed yet: a dried one has lost the water that lets the salt out.
function F.canRinse(item)
    return F.RINSE_TYPES[item:getFullType()] == true and not item:getModData().rinsed
end

-- What rinsing does to a salty stage, from its script values: less thirst, a little less keeping. A stage
-- made from a rinsed fish gets it again, as its values come fresh from its own script.
function F.applyRinse(item)
    local stage = F.STAGES[item:getFullType()]
    if not stage or not stage.salty then return end
    item:setThirstChange(item:getThirstChange() * F.RINSED_THIRST)
    if stage.rinsedUnhappy then item:setUnhappyChange(stage.rinsedUnhappy) end
    item:setOffAge(math.floor(item:getOffAge() * F.RINSED_KEEPING + 0.5))
    item:setOffAgeMax(math.floor(item:getOffAgeMax() * F.RINSED_KEEPING + 0.5))
end

function F.rinse(item)
    if not F.canRinse(item) then return false end
    item:getModData().rinsed = true
    F.applyRinse(item)
    F.rename(item)
    return true
end

-- The Rinse recipe's OnTest, which runs for every input: only the fish is checked.
function F.canRinseInput(item)
    if not F.RINSE_TYPES[item:getFullType()] then return true end
    return F.canRinse(item)
end

-- The Rinse recipe gives back the same fish, so each one hands over everything it is, then is rinsed.
function F.onCreateRinsed(craftRecipeData)
    local fish = craftRecipeData:getAllInputItemsWithFlag("ItemCount")
    local created = craftRecipeData:getAllCreatedItems()
    for i = 0, math.min(fish:size(), created:size()) - 1 do
        local source, target = fish:get(i), created:get(i)
        copyFood(source, target, 1)
        target:setActualWeight(source:getActualWeight())
        target:setCustomWeight(true)
        local targetModData = target:getModData()
        for key, field in pairs(source:getModData()) do targetModData[key] = field end
        target:setModelIndex(source:getModelIndex())
        F.rinse(target)
        target:setAge(source:getAge())
    end
end

-- The nearest sink, bathtub, barrel or well of clean water within RINSE_REACH on the character's floor with at least litres.
function F.findWaterSource(character, litres)
    return Station.nearAt(math.floor(character:getX()), math.floor(character:getY()), math.floor(character:getZ()), F.RINSE_REACH, function(waterSource)
        return waterSource:hasWater() and not waterSource:isTaintedWater() and waterSource:getFluidAmount() >= litres
    end)[1]
end

-- How far a stockfish has matured, 0 to 1, by the days on its own food clock since it came off the frame.
-- One spawned with no stamp (the debug Item List, loot) counts as ripe; a rehydrated one keeps what it had.
function F.ripeness(item)
    local modData = item:getModData()
    if F.STAGES[item:getFullType()].ripened then return modData.ripeness end
    if not modData.matureAge then return 1 end
    return math.max(0, math.min((item:getAge() - modData.matureAge) / F.MATURE_DAYS, 1))
end

-- The days a piece of dry cured meat takes to age, nil for anything that doesn't.
function F.ageDays(item)
    local stage = F.STAGES[item:getFullType()]
    if not stage or not stage.ages then return nil end
    return stage.ham and F.AGE_HAM_DAYS or F.AGE_CUT_DAYS
end

-- How far a piece of dry cured meat has aged, 0 to 1, by the days on its food clock since it dried (agedFrom; one
-- spawned without it, from the debug Item List or loot, counts all its days). Once Aged it stays so.
function F.agedness(item)
    local days = F.ageDays(item)
    if not days then return 0 end
    local modData = item:getModData()
    if modData.aged then return 1 end
    return math.max(0, math.min((item:getAge() - (modData.agedFrom or 0)) / days, 1))
end

-- The share of a food item not yet eaten or carved off: both lower HungChange and leave BaseHunger.
function F.shareLeft(item)
    local base = item:getBaseHunger()
    if not base or base == 0 then return 1 end
    return math.max(0, math.min(item:getHungChange() / base, 1))
end

-- Marks a piece Aged the first time it is seen so, and gives what is left of it the aged meat's mood.
function F.applyAged(item)
    local modData = item:getModData()
    if modData.aged or F.agedness(item) < 1 then return end
    modData.aged = true
    local left = F.shareLeft(item)
    if F.STAGES[item:getFullType()].ham then
        item:setUnhappyChange(F.AGED_HAM_UNHAPPY * left)
        item:setBoredomChange(F.AGED_HAM_BOREDOM * left)
    else
        item:setUnhappyChange(F.AGED_CUT_UNHAPPY * left)
    end
end

-- A piece left hanging where it dried (a finished stack in its station's slots) ages faster: once an hour it
-- gets the extra days since the last look, by moving its stamp back. Taken down, it ages at the shelf's pace.
function F.ageHanging(item, now)
    if not F.ageDays(item) then return end
    local modData = item:getModData()
    local last = modData.hungHour
    if last and now - last < 1 then return end
    modData.hungHour = now
    if not last or modData.aged then return end
    modData.agedFrom = (modData.agedFrom or 0) - (now - last) / 24 * (1 / F.HANG_AGE_SHARE - 1)
    F.rename(item)
end

-- Whether a later stage came from a Gutted Fish (headless). A small fish salted whole keeps its head, so it isn't
-- (nor one packed whole before 0.4.66). The icon already says which: stages list theirs whole, gutted, then half.
function F.wasGutted(item)
    local index, count = item:getModelIndex(), #F.FISH_ICONS
    return index >= count and index < count * 2
end

-- A hung piece that rotted before it was done: the same stage again, as it went up, rotten ("Beef (Corned)", not
-- "Beef (Dry Cured)"; a Gutted Walleye, not a Stockfish).
-- stack is the stack's modData, if it came off a station: the piece keeps its stack, so the station still counts it
-- and draws it with the rest.
function F.rottenStage(source, stack)
    local rotten = instanceItem(source:getFullType())
    copyFood(source, rotten, 1)
    rotten:setActualWeight(source:getActualWeight())
    rotten:setCustomWeight(true)
    local sourceData, rottenData = source:getModData(), rotten:getModData()
    for _, key in ipairs({ "fishName", "sliceable", "longCure", "rinsed", "cureSpoiled" }) do rottenData[key] = sourceData[key] end
    if sourceData.rinsed then F.applyRinse(rotten) end
    rotten:setModelIndex(source:getModelIndex())
    F.rename(rotten)
    if stack then rottenData.stackId, rottenData.style = stack.stackId, stack.style end
    rotten:setAge(rotten:getOffAgeMax())
    return rotten
end

-- Hot smoked pork is vanilla's Ham (6b), with the cut's own food and Hot Smoked's share of its weight, so Slice Ham
-- and every ham dish take it. Vanilla names and keeps it.
function F.carryHam(source, ham)
    local stage = F.STAGES[F.HOT_MEAT]
    copyFood(source, ham, stage.nutrition, stage.hunger)
    ham:setActualWeight(F.foodWeight(source) * stage.weight)
    ham:setCustomWeight(true)
end

-- InheritFood would copy the first fish onto all of them, and a batch can mix sizes, so each
-- fish hands its own values to one output.
function F.onCreateCured(craftRecipeData)
    local fish = craftRecipeData:getAllInputItemsWithFlag("ItemCount")
    local created = craftRecipeData:getAllCreatedItems()
    for i = 0, math.min(fish:size(), created:size()) - 1 do
        F.carry(fish:get(i), created:get(i))
    end
end

-- Soaking a stockfish fixes how ripe it was, and with it how the fish lifts or lowers the mood.
function F.onCreateSoaked(craftRecipeData)
    local fish = craftRecipeData:getAllInputItemsWithFlag("ItemCount")
    local created = craftRecipeData:getAllCreatedItems()
    for i = 0, math.min(fish:size(), created:size()) - 1 do
        local soaked = created:get(i)
        local ripeness = F.ripeness(fish:get(i))
        soaked:getModData().ripeness = ripeness
        soaked:setUnhappyChange(F.MATURE_UNHAPPY * (1 - 2 * ripeness))
        F.carry(fish:get(i), soaked)
    end
end

-- A part cut from a fish, scaled to it as vanilla's guts are.
local function cutFrom(fish, fullType, weightShare, foodShare)
    local part = instanceItem(fullType)
    part:setActualWeight(fish:getActualWeight() * weightShare)
    part:setWeight(part:getActualWeight())
    part:setCustomWeight(true)
    part:setBaseHunger(fish:getBaseHunger() * foodShare)
    part:setHungChange(fish:getHungChange() * foodShare)
    return part
end

-- The head keeps the fish's name and age.
function F.fishHead(fish)
    local share = F.HEAD_FOOD
    local head = cutFrom(fish, F.FISH_HEAD, F.HEAD_WEIGHT, share)
    copyFood(fish, head, share)
    head:setAge(fish:getAge())
    local fishName = fish:getModData().fishName or string.gsub(fish:getDisplayName(), "%s+$", "")
    F.nameAs(head, getText("IGUI_TraditionalPreservationFishMeat_Head", fishName))
    return head
end

-- For recipes that clean a fish. A recipe can't leave an output out, so the guts and head go
-- straight in the inventory. The guts keep the fish's age, as the head does: a stale fish's guts are stale.
function F.onCreateGutted(craftRecipeData, character)
    local fish = craftRecipeData:getAllInputItemsWithFlag("ItemCount"):get(0)
    local stage = F.STAGES[craftRecipeData:getAllCreatedItems():get(0):getFullType()]
    F.onCreateCured(craftRecipeData)
    if not F.hasGuts(fish) then return end

    local share = F.GUTS_WEIGHT
    local inventory = (character or craftRecipeData:getCharacter()):getInventory()
    local guts = cutFrom(fish, "Base.FishGuts", share, share)
    guts:setAge(fish:getAge())
    inventory:AddItem(guts)
    if stage.headless and F.hasHead(fish) then
        inventory:AddItem(F.fishHead(fish))
    end
end

-- OnTest sees every input, so the knife passes here too.
function F.canSplit(item, character)
    if item:getFullType() ~= F.GUTTED_FISH then return true end
    return item:getActualWeight() > F.STACK_WEIGHT
end

-- Each half keeps half the weight, not a fillet's share, so halves can't stack deep on a frame.
function F.onCreateSplit(craftRecipeData)
    local fish = craftRecipeData:getAllInputItemsWithFlag("ItemCount"):get(0)
    local created = craftRecipeData:getAllCreatedItems()
    local halfName = getText("IGUI_TraditionalPreservationFishMeat_Half", fish:getModData().fishName)
    for i = 0, created:size() - 1 do
        local half = created:get(i)
        copyFood(fish, half, 0.5)
        half:setActualWeight(fish:getActualWeight() / 2)
        half:setCustomWeight(true)

        local modData = half:getModData()
        modData.fishName = halfName
        modData.sliceable = false
        F.nameAs(half, halfName)
        half:setModelIndex(fish:getModelIndex())
    end
end

-- OnTest sees every input, so the knife passes here too.
function F.canSlice(item, character)
    if not F.STAGES[item:getFullType()] then return true end
    return item:getModData().sliceable == true
end

-- Slicing keeps the stage, so a Salt Cured fish gives Salt Cured fillets. A cured fish has no guts left
-- to lose, so each fillet keeps half its weight with half its food, not vanilla's raw share.
function F.onCreateSliced(craftRecipeData)
    local fish = craftRecipeData:getAllInputItemsWithFlag("ItemCount"):get(0)
    local created = craftRecipeData:getAllCreatedItems()
    local filletName = getItemNameFromFullType("Base.FishFillet")
    for i = 0, created:size() - 1 do
        local fillet = created:get(i)
        copyFood(fish, fillet, 0.5)
        fillet:setActualWeight(fish:getActualWeight() / 2)
        fillet:setCustomWeight(true)

        local modData = fillet:getModData()
        modData.fishName = filletName
        modData.sliceable = false
        modData.matureAge = fish:getModData().matureAge
        modData.ripeness = fish:getModData().ripeness
        if fish:getModData().rinsed then
            modData.rinsed = true
            F.applyRinse(fillet)
        end
        fillet:setModelIndex(0)
        F.rename(fillet)
    end
end

-- Marks the fish of a stack, so a frame can tell its finished stacks apart, and ages it by what
-- the season took out of it. A stack hot smoked in the Smokehouse comes out Hot Smoked instead, and one that had
-- its hours of smoke there (F.smokeHours) Cold Smoked. Meat dried in the shed is Dry Cured either way, never Charque.
function F.onCreateDried(craftRecipeData)
    local modData = craftRecipeData:getModData()
    local hung = modData.stackId and F.stackStations[modData.stackId]
    if hung then F.stackStations[modData.stackId] = nil end
    if hung and (modData.spoiled or 0) >= 1 and F.rottenOutputs(craftRecipeData, hung) then
        F.hotStations[modData.stackId], F.smokeStations[modData.stackId] = nil, nil
        return
    end
    local station = F.hotStations[modData.stackId]
    if station then
        F.hotStations[modData.stackId] = nil
        if F.smokedOutputs(craftRecipeData, station, F.HOT_FISH, F.HOT_MEAT) then return end
    end
    -- Meat dry cured on a Frame or Beam in the shade: air dried, as from the shed with no smoke.
    if hung and modData.smokeMeat and not F.inShed(modData) and F.dryCuring(modData) and F.smokedOutputs(craftRecipeData, hung, F.COLD_FISH_OUT, F.DRY_CURED, true) then return end
    station = modData.stackId and F.smokeStations[modData.stackId]
    if station then F.smokeStations[modData.stackId] = nil end
    if station then
        local smoked = F.coldDone(modData)
        -- Meat from the shed is always Dry Cured, smoked or air dried (6b); fish only with its share of smoke.
        if (smoked or modData.smokeMeat) and F.smokedOutputs(craftRecipeData, station, F.COLD_FISH_OUT, F.DRY_CURED, not smoked) then return end
    end
    F.onCreateCured(craftRecipeData)
    local spoiled = modData.spoiled or 0
    local created = craftRecipeData:getAllCreatedItems()
    for i = 0, created:size() - 1 do
        local fish = created:get(i)
        fish:getModData().stackId = modData.stackId
        fish:getModData().style = modData.style
        fish:setAge(spoiled >= 1 and fish:getOffAgeMax() or fish:getOffAge() * spoiled)
        if F.STAGES[fish:getFullType()].matures then
            fish:getModData().matureAge = fish:getAge()
            F.rename(fish)
        end
    end
end

-- What the sandbox's spoilage setting does to the limits: off, forgiving, normal and harsh.
local SPOILAGE_SCALES = { math.huge, 2, 1, 0.5 }
local RAW_SPOIL_HOURS, SALT_SPOIL_HOURS = F.RAW_SPOIL_HOURS, F.SALT_SPOIL_HOURS
local FREEZE_DAMAGE_HOURS, WET_DAMAGE_HOURS, HEAT_DAMAGE_HOURS = F.FREEZE_DAMAGE_HOURS, F.WET_DAMAGE_HOURS, F.HEAT_DAMAGE_HOURS
local UNDER_CURE_HOURS, LONG_CURE_ROT_HOURS = F.UNDER_CURE_HOURS, F.LONG_CURE_ROT_HOURS
local UNDER_CURE_MAX_DAYS, HOT_ONLY_MAX_DAYS = F.UNDER_CURE_MAX_DAYS, F.HOT_ONLY_MAX_DAYS
-- Small fish press for the same share of the biggest fish's time, whatever the sandbox sets it to.
local PRESS_MIN_SHARE = F.PRESS_MIN_HOURS / F.PRESS_HOURS

-- Reads the sandbox options into the drying, pressing and maturing times and the spoilage limits. Each time is
-- its own option (up to 0.3.6 cold drying followed DryDays at 8/3); their defaults are the times in this file.
function F.applySandbox()
    local options = SandboxVars and SandboxVars.TraditionalPreservationFishMeat
    if not options then return end
    if options.DryDays then F.DRY_HOURS = options.DryDays * 24 end
    if options.ColdDryDays then F.COLD_DRY_HOURS = options.ColdDryDays * 24 end
    if options.MatureDays then F.MATURE_DAYS = options.MatureDays end
    if options.AgeCutDays then F.AGE_CUT_DAYS = options.AgeCutDays end
    if options.AgeHamDays then F.AGE_HAM_DAYS = options.AgeHamDays end
    if options.PressDays then
        F.PRESS_HOURS = options.PressDays * 24
        F.PRESS_MIN_HOURS = F.PRESS_HOURS * PRESS_MIN_SHARE
    end
    if options.CharqueDays then F.CHARQUE_HOURS = options.CharqueDays * 24 end
    if options.Charque ~= nil then F.CHARQUE_ON = options.Charque end
    if options.MaxDryDays then F.MAX_DRY_DAYS = math.max(options.MaxDryDays, F.DRY_HOURS / 24) end
    F.MIN_DRY_RATE = F.DRY_HOURS / (F.MAX_DRY_DAYS * 24)
    local scale = SPOILAGE_SCALES[options.Spoilage] or 1
    F.RAW_SPOIL_HOURS = RAW_SPOIL_HOURS * scale
    F.SALT_SPOIL_HOURS = SALT_SPOIL_HOURS * scale
    F.FREEZE_DAMAGE_HOURS = FREEZE_DAMAGE_HOURS * scale
    F.WET_DAMAGE_HOURS = WET_DAMAGE_HOURS * scale
    F.HEAT_DAMAGE_HOURS = HEAT_DAMAGE_HOURS * scale
    -- Under-salted Corned meat and the long cure's cold rule (0.4.14) go by the setting too: off, they never spoil.
    F.UNDER_CURE_HOURS = UNDER_CURE_HOURS * scale
    F.LONG_CURE_ROT_HOURS = LONG_CURE_ROT_HOURS * scale
    -- The thawed-hours limits (realism pass) with them.
    F.UNDER_CURE_MAX_DAYS = UNDER_CURE_MAX_DAYS * scale
    F.HOT_ONLY_MAX_DAYS = HOT_ONLY_MAX_DAYS * scale
end

local function applyRecipeTime(name, hours)
    Weather.setRecipeHours(name, hours, "TraditionalPreservationFishMeat")
end

-- Sets each slow recipe's script time to the sandbox's, so the crafting window shows the right length.
function F.applyRecipeTimes()
    F.applySandbox()
    applyRecipeTime("TraditionalPreservationFishMeat.HangFishToDry", F.DRY_HOURS)
    applyRecipeTime("TraditionalPreservationFishMeat.HangFishToColdDry", F.COLD_DRY_HOURS)
    applyRecipeTime("TraditionalPreservationFishMeat.HangMeatToDry", F.CHARQUE_HOURS)
end

Events.OnInitGlobalModData.Add(F.applyRecipeTimes)

-- The parts in their own files: the weather's totals and what they do to stacks and tubs, the Salting Tub, the names,
-- the stocks, and the stockfish's pallet and bales.
require "TraditionalPreservationFishMeatLedger"
require "TraditionalPreservationFishMeatTub"
require "TraditionalPreservationFishMeatRack"
require "TraditionalPreservationFishMeatNames"
require "TraditionalPreservationFishMeatStock"
require "TraditionalPreservationFishMeatStockfish"
