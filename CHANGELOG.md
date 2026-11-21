# Changelog: Traditional Preservation (Fish & Meat)

## 0.4.96
- **In TP Core's station report** (written on each save, for the long-save log): the Rack, Smokehouse (once, by its record tile) and Salting Tub windows take part
  (`StationReport.add`). Needs TP Core 0.1.56.

## 0.4.95
- **The Stockfish Pallet's own loot-window icon** (user, session 77; `art/container_icons_mock.png`): its button shows
  the pallet (`Container_StockfishPallet.png`, from `tools/build_tileset.py`), not vanilla's shelves. Needs TP Core
  0.1.53 (`UI.containerIcon`).

## 0.4.94
- **Frost keeps raw meat and fish** (the natural freezer): loose raw meat and fish (carried, in a container, on the
  ground) age nothing in the hours at or below -2 C where they are, as in a freezer; above it, vanilla's clock as
  before. Vanilla's raw fish and cuts, the Leg of Pork, Gutted Fish, Fish Half, Fish Head, Fresh Sausage, raw Blood
  Sausage, Raw Casings, Pork Fat, Mutton Fat, Beef Suet and the soaked stages; cooked or burnt pieces keep vanilla's
  clock. By TP Core's place temperature on its frost ledger (`Frost.point(-2)`): a basement never freezes, a powered
  fridge never, a fire nearby keeps the frost off. Each piece keeps a frost record (`modData.tpfmFrost`), looked at
  through TP Core's `PlaceKeepingUI`; a piece hung on a rack or packed in the tub leaves its record behind. New
  sandbox option **Frost keeps meat** (`FrostKeepsMeat`, on).
- **Dry curing stops at -2 C and below** (`F.dryCureRate` 0): frozen meat takes no salt. Above it as before (a
  quarter in a light frost, full from 12 C); a fire's warmth in the Smokehouse keeps it going. The popup's
  temperature word reads *Too cold* there.
  With no fire a winter start now takes longer (a scratch run on the forecasts, the Smokehouse with the fire
  out): a Beef hung in November 75 to 129 days, in January about 78 to 93; a Leg of Pork in November 147 to 170;
  basements and March on unchanged. README and guide figures updated (cuts 3 to 18 weeks, a ham up to 6 months).
- Console: `TPFM.frost(hours)` also gives the loose raw meat and fish on you or within 4 tiles that many hours of
  frost; `TPFM.food()` shows a raw piece's hours frozen. Tests in `tests/test_frost.lua`.
- Needs TP Core 0.1.52.

## 0.4.93
- **A done piece's row is named and drawn as it comes off** (user, session 72): on the racks and in the Smokehouse, a
  piece done reads the name, with the icon, of what Take Done gives (*Beef (Country Cured)* hung reads *Beef (Dry Cured)*, *Cold Smoked* or
  *Hot Smoked*; a salt fish *Bluegill (Salt Dried)*; pork hot smoked *Ham*; a smoked link *Smoked Blood Sausage*;
  ageing shows, *Aged*), worked out from the kept piece at most once a game hour. A piece still drying keeps the name
  it was hung with.
- Docs: Smokehouse Info's band carries the joined hearth's Bank / Stoke and Light / Put Out buttons (TP Core 0.1.42).

## 0.4.92
- **Smokehouse Info built to the approved mock**, on the racks' window: the joined Stone Hearth's fire as its band
  (TP Core 0.1.41's `SmokehouseUI.band`, the Light / Put Out button with it), the Station block with the Smokehouse's
  outline icon (Place, Season, the heaviest piece), the load as cells with the farm smokehouse's lore beside them, the
  list with each piece's smoke under its bar, Take Done and Take All with icons. The drop square is gone: what is
  dragged onto the load's cells hangs, as on the racks. The Fire row moves into the band. On a day over 15°C (`F.COLD_SMOKE_MAX`) a banked fire's band reads
  "too warm for cold smoke".

## 0.4.91
- **Drying Frame, Hanging Beam and Gantry Info built to the approved mock** (TP Core 0.1.39's pieces): a state band
  under the title (Empty; Spoiling with how many pieces; Done; Stopped with the first piece's reason, as wet from
  rain; Drying with the wind where it reaches and how many are done; the worst first), TP Core 0.1.40's Station block
  (the rack's outline icon, Place, Season, then the wind, the wetness in the open and the heaviest piece the rack
  takes), the load as five cells by weight or count, split into fish, meat and sausage
  patterns by weight, with a line of history beside them (Lofoten's stockfish racks). The Holds row and the drop
  square are gone: fish or meat dragged onto the cells hangs, as the menu would, the cells it would fill shown in its
  pattern.
- Each piece's row says what holds it back in amber at its right: spoiling with the share gone, under-salted, or why it
  stopped (Wet: rain, Too warm, Still air, Shut room, Too cold, Needs a roof); a stopped piece's bar reads its share
  alone. The Smokehouse's rows get the same.
- Take Done (n) and Take All (n) carry an icon: what the first done piece comes off as (vanilla's crafted icon when
  none is done) and vanilla's returned icon.
- Salting Tub Info's Station block is TP Core 0.1.40's: the tub's outline icon, Place and Season.
- `TPStation_SaltingTub`, `TPStation_DryingFrame`, `TPStation_HangingBeam` and `TPStation_Gantry`, the Info windows'
  outline icons, from TP Core's `tools/station_icons.py`. The menus keep the item icons.
- The Hanging list folds (TP Core 0.1.40's `pieceListBlock`), each rack type keeping its own fold.
- Smokehouse Info keeps its present layout until its own turn.

## 0.4.90
- Salting Tub Info's cells are drawn in big fish scales or marbled meat by what the tub holds (TP Core 0.1.39), a drag's cells
  in what it puts in. `TPCell_Fish`, `TPCell_Meat` and `TPCell_Sausage` (the Smokehouse's, for its window) from Core's
  `tools/cell_patterns.py`.

## 0.4.89
- **Salting Tub Info built to the approved mock** (TP Core 0.1.37's pieces): a state band under the title (Empty,
  Packing with the salt it wants, Curing with the time left, Spoiling in a warm season, Cured with the pieces left;
  the worst first), the Station block with the place's icon, Holds as five cells by weight or count with a line of
  history beside them (salt cod for fish, corned beef for meat), and the cure's bar under Working ("60%, 100% speed").
  The Stage, Next and Cure Speed rows are gone (the band and the bar say it).
- Raw fish or meat dragged from the inventory onto the tub's cells goes in while it is packing, as Put in Tub would
  (one kind, room by count and weight); the hint by the mouse says how many, or why not.
- **Buttons in the window** (tub_buttons_mock B): while packing, the start for what is in the tub (Cure Fish; Corn the Meat and Country Cure for meat), greyed with the reason as the menu's rows, and **Unpack (n)**; once cured, **Take One** and **Take All (n)** with the cured piece's icon. None while it cures or once empty (TP Core 0.1.38 hides buttons a row no longer has).

## 0.4.88
- Temperatures in the game's text read with the degree sign ("12°C", was "12 C"), as TP Core 0.1.37's. Its tests expect the new text.

## 0.4.87
- The rack's and the Smokehouse's drop squares show an icon of what they take (a Yellow Perch, a Steak).
- Drying Frame, Hanging Beam, Gantry and Smokehouse Info each keep their own width when resized (Core 0.1.36).

## 0.4.86
- The window rows read the station's full name and Info (Salting Tub Info, Drying Frame Info, Hanging Beam Info, Gantry Info, Smokehouse Info), as vanilla's Fireplace Info and
  Generator Info; the window's title is the bare name. The short "Vessel Info", "Tub Info" and the like are gone.

## 0.4.85
- **Hand recipes work from the floor** (series recipe audit, 2026-11-19): every hand recipe but Packing has
  `CanBeDoneFromFloor`, so its inputs aren't carried into the inventory first (vanilla moves them otherwise): Rinse Salted Fish, Soak Salt Fish, Soak Cold Fish, Soak Charque.
- **The game's names**: Ceramic Jar, Glazed Ceramic Jar and Ceramic Pot (was "Clay Jar", "Clay Pot") for Pack Potted
  Meat in the README, Workshop text, guide, DEVHELP and the Pot of Meat in Fat tooltip.

## 0.4.84
- **Smokehouse step S5: docs and checks** (ROADMAP section 12). README, DEVHELP, Workshop text and the guide describe
  the racks and the Smokehouse as they are now (pieces, Info, tabs; no crafting window). The racks' build tooltips
  give their real limits (Frame 20 kg, none over 2.5; Beam 60 kg, none over 5; Gantry 100 kg in 12 pieces, none over
  12, anywhere but in front of a door). A full rack now says *Full: no room left for it*; Stone Hearth Info's flue
  note speaks of salt fish and salted meat and a day or more of smoke. `F.mixedMeat` (a stack's poultry-or-red-meat
  rule, unused since S4) and its string are gone. The console's help and messages say pieces. Smokehouse Info's line
  under a fish's or meat's bar adds *too warm to count (over 15 C)* with a fire joined on a warmer day (the old slot
  popup's line; `RackUI.smokeNote(piece, now, ledger)`).

## 0.4.83
- **Rack Info and Smokehouse Info have tabs** (TP Core 0.1.31's piece list): All, then one for each Hang group hanging
  (Salt Fish, Gutted Fish, Corned Meat, Country Cured Meat, Sausages, in the menu's order) with its count. Take Done and
  Take All stay whole-station. `RackUI.pieceGroup(piece)`, `RackUI.GROUP_ORDER`.

## 0.4.82
- **Smokehouse step S4: the switch-over** (ROADMAP section 12). The Smokehouse has no crafting window: hang and take
  from its right-click menu or Smokehouse Info. The World steps its pieces from the record tile (`F.rackNow`), once a
  shed. Gone with the recipes: Hang Salt Cured Fish to Dry, Hang Gutted Fish to Cold Dry, Hang Salted Meat to Dry, Hang
  Sausage to Smoke and their callbacks (`onDryStart` ... `onCreateDried`, the sausages' `canSmokeSausage`,
  `onSausageSmokeStart` / `Update`, `onCreateSmokedSausage`), the output swaps (`smokedOutputs`, `rottenOutputs`),
  `F.stackStations` / `smokeStations` / `hotStations`, the Smokehouse's slot rules and slot popups, the crafting-window
  Info block (`Info.rows`, `World.inspect`, `busyStacks`), `F.frameRefusal`, `F.fishStyle`, `F.ageHanging` and the
  hangers' stack weights; their translations. `TPFM.smoke`, `TPFM.addSmoke`, `TPFM.stoke` and `TPFM.bank` work on
  pieces. A link's bar no longer waits short of the end for the World. Tests that drove the old stacks now hang
  pieces; the side-by-side checks keep the stacks' figures.

## 0.4.81
- **Smokehouse step S3: its menu and Smokehouse Info** (ROADMAP section 12). Right-click any tile of the Smokehouse:
  a Smokehouse submenu as the racks have (what it holds, Info, Hang groups with Hang Sausages, poultry and rabbit under
  Hang Corned Meat, Take Done, Take Everything Off), with the joined Stone Hearth's fire on the status row's hover.
  Smokehouse Info is Rack Info with a Fire row, each piece's own smoke under its bar (a hot run counting, cold smoke
  against its need, a link's days to stale), a link's own popup, the buttons and the drop square. The crafting window
  stays until S4; pieces hung from the new menu are counted when the menu or Info looks (the World steps them from S4).
  `F.rackPlace` gives the Smokehouse's place to the hang check too, and Take Done's icon shows what the first finished
  piece comes off as (`F.pieceOutputType`: Hot Smoked, Cold Smoked, Dry Cured, the smoked links).

## 0.4.80
- **Smokehouse step S2** (nothing changes in game yet): its record on TP Core's record tile, and its finished pieces
  counted for the shed's door look. The Smokehouse's build is TP Core's: Carpentry 5 and 2 large hooks now (docs).

## 0.4.79
- **Items move into the inventory before the walk** (user, session 53; vanilla's order): hanging on a rack (the menu
  and the drop square) and the Salting Tub move every piece from a crate or a bag first, then walk (TP Core's `UI.walkTo`, keeping the queue), then act.
- **The Smokehouse's pieces, step S1** (ROADMAP section 12; nothing changes in game yet): the chamber in the rack
  record (90 kg, 150 pieces, 12 kg at most), its pieces counting the joined fire on their own (`F.smokeStep`), cooked
  pieces Hot Smoked, dried ones Cold Smoked or air dried, sausages on their own code; a kept piece keeps whether it
  was cooked (a boiled link).

## 0.4.78
- **A rack is no cold store** (user, session 53): a piece counts the hours it hangs without drying at all (a shut room,
  the wrong place, frost, rain; `piece.stalled`, each look), and taken off early it is aged by them at vanilla's pace,
  on top of what the hanging spoiled. Hours spent drying still don't age it.

## 0.4.77
- **Split Fish takes a gutted fish at its later stages too** (user, session 53): a Salt Cured one over 2.5 kg (so it
  hangs on a frame), a Salt Dried one or a Stockfish over 0.6 kg, each split into two halves of its stage (the
  recipe's `halfStage` mapper), keeping the stage's marks (rinsed, maturing, the cure's spoilage) with a half's icon
  and name. A fish salted whole with its guts, a half and a fillet don't split.
- **A piece taken off before it is done** (Take Everything Off, Take All; user, session 53) comes back as it was hung,
  with only what the hanging spoiled taken off its keeping (its spoiling since it went up, and a Corned piece's
  under-salting; all of it, rotten), as a finished piece's spoilage is; the hours on the rack no longer age it by the
  clock (`F.earlyOutput`).
- **Take Done (n) and Take All (n) buttons in Rack Info** (user, session 53), under the list: the same actions and
  hovers as the menu's rows (`RackUI.take`, `RackUI.waitText`).
- **Docs for the racks** (ROADMAP section 12, R6): README (the drying stations, the station table with each rack's
  total, pieces and heaviest piece, the developer table and tests), the guide's drying stations chapter and its
  rack mentions, `Balance/BuildingRecipes.md` (the racks' holds; the Gantry builds in a room, only not in front of a
  door), TESTING_GUIDE steps 52 (the racks), 53 (Rack Info) and the rack wording in 45, 46, 54, 55, 57, 59, 60, 84.

## 0.4.76
- **The racks' new hanging tiles** (ROADMAP section 12, R5; mock `art/rack_tiles_mock.png`): 15 tiles a spot and
  face, four looks (salt fish, salt fish half, gutted fish, meat) at three stages (fresh, half dry, dry) and a rotten
  one a kind (salt, gutted, meat): 420 tiles for the frame's 8 spots, the Beam's 4 and the Gantry's 2, where there
  were 924. A piece's style draws as a look (`F.styleLook`: a salt gutted fish as whole salt fish, a cold half as
  gutted fish); `F.spotTile` numbers a spot's tile, `hangingSprite` places it. The frame's tiles start at 8, the
  Beam's at 412, the Gantry's at 532; station tiles keep their numbers and the third tile sheet (the stacks' rotten
  looks) is gone. Hanging tiles are drawn anew from each rack's record, so nothing needs carrying over.

## 0.4.75
- **A mixed rack shows every kind** (user, session 53): the spots in use (as many as the weight hung fills) are
  shared by kind, salt fish, gutted fish and meat: each kind gets a spot, the rest go to the kind with the most
  weight a spot; a rack with more kinds than spots (a Gantry's 2) shows its heaviest. Kinds stand in the order first
  hung; within a kind pieces fill its spots by weight in hang order, so a piece joins a spot of its kind that isn't
  full. Three Corned Steaks on a frame of fish now show as meat.

## 0.4.74
- **The Drying Frame, Hanging Beam and Gantry are off CraftLogic** (ROADMAP section 12, R4): their entity scripts keep
  the build and the look (no window, `uiEnabled = false`, as the Salting Tub); vanilla's second menu entry and the
  crafting window are gone. The World tracks each rack: its pieces come up to now at its place on every look, and its
  spots draw from the piece record (`F.rackSpots`: a spot each total / spots kg, in hang order, at the least dry
  piece's stage, rotten if any piece rotted), from today's tiles until the new ones (R5). Dry cured meat left
  hanging when done ages faster, as a finished stack did. The old frame drawing (`stackLooks`) is gone; the
  Smokehouse keeps its crafting window until its own move. Old stacks are not carried over.
- **Icons on every row of a rack's menu**: the rack's own on its entry, status and Info rows (and the main menu's
  Info), what the first finished piece becomes on Take Done, the first piece hung on Take Everything Off; the Hang rows
  carry their item's. `test_rack_menu` checks every row has one.

## 0.4.73
- **Hanging and taking down use vanilla's take-down-curtain animation** (`RemoveCurtain`, hands empty), not the loot one (user, session 53).
- **Rack Info's drop square** (TP Core's DropZone): drag a selection from the inventory or a loot window onto it to
  hang what the rack takes, lightest first, one hang action a piece, by the menu's rules (`RackUI.dropJudge`).
- **Info in the main menu too** (user, session 53): every station's Info row is also at the bottom of the main right-click menu, besides its submenu (TP Core's `UI.topInfo`). Tub Info and Rack Info.

## 0.4.72
- **Info windows open from the right-click menu only** (user, session 53): a left click on a station is vanilla's again, as for every vanilla workstation (a container opens its loot window). Tub Info is in the tub's menu.
- **Racks off CraftLogic, first steps** (ROADMAP section 12, R1-R3; the racks' crafting window still runs beside it until R4):
  - **A piece record** (`TraditionalPreservationFishMeatRack.lua`, movableData `tpfmRack`): each piece hung on a Drying Frame, Hanging Beam or Gantry keeps its item (`F.keptPiece`, now shared with the Salting Tub: `keptPiece`, `keptItem`, `itemFromKept`) and its own clock, the state a stack used to keep, so `saltStep`, `coldStep`, `charqueStep` and the outputs run a piece at a time. Each rack takes up to a total weight, a count and a heaviest piece: frame 20 kg, 200 pieces, 2.5 kg; Beam 60, 48, 5; Gantry 100, 12, 12. Done pieces wait on the rack, ageing as food does.
  - **Rack Info** (`TraditionalPreservationFishMeatRackUI.lua`): place rows, what it holds, and a row a piece in TP Core's scrolling list (process for the sort, a popup with method, outcome, time left and warnings). `Info.placeRows` split out of `Info.rows`.
  - **The rack's menu**: what it holds, Info, a Hang submenu a group (Salt Fish, Gutted Fish, Corned Meat, Country Cured Meat, Sausages) with a row a kind carried (One / All, lightest first so the most fit; a refused kind says why, too heavy with every rack's limit; a group with nothing open is red with the reason), Take Done (n) (always there: greyed until a piece is done, its hover says when the next is), Take Everything Off (pieces not done come off as hung); `TPFMRack` hangs or takes one piece an action. A rack holding pieces can't be picked up.
  - **Console:** `TPFM.kit("rack")`, `TPFM.rackHang()`, `TPFM.rackInfo()`. Tests: `test_rack.lua` (each method side by side with a one-piece stack), `test_rack_info.lua`, `test_rack_menu.lua`; the food stand-in in `tests/standins/food.lua`.

## 0.4.71
- **A Salting Tub with anything in it can't be picked up** (2026-11-19): pieces waiting, curing or cured keep it
  where it is, and its time goes by its place; empty, it picks up as before.

## 0.4.70
- **Shut rooms, aired rooms, moving air** (2026-11-19, TP Core 0.1.15). Needs TP Core 0.1.15.
  - **A shut room stands still:** salt fish, charque, dry curing and cold drying wait for a window (*Stopped (Shut
    room: open a window)*). A tub, Corned meat's spoiling and unsalted fish's rot still go by the room's temperature.
  - **An aired room dries as an open roof** (salt fish, charque with the wind, dry curing), by its own temperature;
    stockfish there at 0.6 of the wind (`AIRED_COLD_RATE`; a roof 0.75). Gutted fish may hang in any room (a shut one
    waits), never in a basement or the Smokehouse. **The Gantry may stand in a room** (`Tiles.OUTDOOR` and
    `F.notInRoom` are gone; the Large beam's build checks only the doors).
  - **Under a roof by the hour's air** (Core's Covered): drying, the tub's cures and spoiling, Corned meat.
  - **Muggy spoiling needs still air:** salt fish and charque in a muggy season spoil only in the Smokehouse (by the
    season's mean), a shut room and a basement; the open air, a roof and an aired room keep the skin dry
    (`F.muggy`, `F.TOTALS.saltSpoil`).
  - **Unsalted fish rots by its place's temperature** (was the season's mean everywhere but the open air): the open,
    a roof and the Smokehouse the hour's (`rawSpoil`), a shut room, an aired room and a basement their own. Stockfish
    under a roof or by an open window is now a January job, February a gamble, as in the open (real stockfish hung
    on open racks): roof rot Feb 28%, Oct all; aired Feb 67%.
  - The Stockfish Pallet: x2 in an aired room (`PALLET_AIRED`), x1.5 in a shut room (`PALLET_ROOM`).
  - **The Smokehouse with the fire out goes by its own air** (TP Core's: an aired room's, the day's mean, never the
    grid's 22 C), not the roof's hour: drying, dry curing and the waiting Corned meat, poultry and rabbit keep
    0.4.69's damped afternoons. Its muggy spoiling still reads the season's mean.
  - `tools/season_report.lua` runs the year round, so November and December stacks finish: stockfish from November to
    January, 50 to 56 days in the open, none rotted.
  - Basement keeps its still-air rates. Loft totals and words are gone. `tools/season_report.lua`: shut room and aired
    room columns, rot under a roof and by an open window.

## 0.4.69
- **The Smokehouse goes by an open roof's temperature** (2026-11-19, TP Core 0.1.14): with the fire out, a stack
  inside dries, dry cures and spoils (Corned meat, poultry and rabbit waiting for their cook) by the season's mean, as
  under an open roof, not the day's; its air is still a room's (salt fish and charque at 0.65), out of the rain and
  wind. The fire's warmth still lifts the day's air. Seasonal check: drying and dry curing move a few days at most;
  a waiting Corned or poultry stack spoils about half as fast in April and May (no afternoon peaks). Stacks carry TP
  Core's `Smokehouse.PLACE` (was `"Enclosed"`); the window reads *In the Smokehouse* and the shed's own temperature.
  Corned meat on an open frame keeps the day's, on its own total (`underCureOpen`). Needs TP Core 0.1.14.

## 0.4.68
- **Docs and tests for TP Core 0.1.13's 2 x 2 Smokehouse** (2026-11-19): nothing changes in this mod's play. The shed
  is four tiles, the two in front of its doors stay clear, and a piece hangs by the door for every two finished stacks
  (Core counts them by this mod's `stackId`). test_world and test_ui read the shed's tiles from Core's `Tiles.CHAMBERS`.
  README, guide, Workshop text.

## 0.4.67
- **Fixed** (2026-11-18, found in game): a whole fish of exactly 0.6 weight was refused by the Salting Tub ("gutted first") and gave Fish Guts, though 0.6 is the limit it may go in whole at. The game keeps weights as floats, so 0.6 reads 0.6000000238; the weight limits (guts, head, Slice Fish) are now passed only by more than `F.WEIGHT_SLACK` (`F.heavierThan`). test_curing.
- **Tub Info** (2026-11-19): the cure's speed row reads **Cure Speed** (it borrowed the drying stations' "Drying Rate"), and Next reads the time left in days past two days, "Cured in about 21 days" (TP Core 0.1.12's `UI.durationText`).

## 0.4.66
- **The Salting Tub is worked from its right-click menu** (2026-11-18), as the kraut barrel is, with a **Tub Info** window (from the menu, or click the tub); no crafting window. **Put \<fish or meat\> in the Tub** (All, then One): raw fish whole up to 0.6 weight (a small fish keeps its guts), gutted, halved or filleted; a bigger whole fish is gutted first, one over 4.5 split; meat as vanilla cuts it. The first piece decides fish or meat. **Unpack** gives it all back before the start, aged as it would be lying out. **Cure Fish**, **Corn the Meat** and **Country Cure** salt the batch at the start (each piece's salt, the old rule) and press it under a **Plank and a Flat Stone**; each row says in red why it can't start. **Take Out** (All, One) when cured; the last piece gives the plank and stone back. Cured pieces left in the tub go off as they would lying out.
- **Same cure:** hours by the heaviest piece, the cold curve, the warm and long cure spoilage, places, weights, food and names. The batch lives in the tub's movableData (`F.TUB_KEY`, `TraditionalPreservationFishMeatTub.lua`, `TPFMSaltingTub`, `...TubUI.lua`).
- **Removed:** Salt Packed Fish and Salt Packed Meat, Pack Fish / Gutted Fish / Meat in Salt, Cure Salted Fish, Corn Salted Meat and Country Cure Salted Meat as recipes, and Carve Chicken / Turkey (Salt Packed). A tub built before keeps its old crafting components in a save (the engine re-creates them on load): rebuild it.
- Console: `TPFM.kit("tub")`, `TPFM.tubCure(hours)`. Tests: test_tub (menu and actions), test_curing, test_world, test_ui, test_info, test_aged.

## 0.4.65
- **Carve a packed or corned bird** (2026-11-18): **Carve Chicken / Turkey (Salt Packed)** and **(Corned)**, a knife on a surface, cut a whole bird packed in salt or corned into 2 legs, 2 wings and 2 fillets at its stage, as the hot smoked carve does (food by vanilla's cut hunger, 90% of the weight). Each cut keeps the bird's age and a copy of its whole modData (the cure and spoilage record), so it goes on in the tub or the Smokehouse in a cut's times. `F.canCarvePackedChicken` and the rest, `F.onCreateBirdCarved`; test_aged. README, guide.

## 0.4.64
- **Docs** (2026-11-17): the Stone Hearth beside the Smokehouse takes 12 Clay (TP Core 0.1.9; was 2). README.

## 0.4.63
- **Fixed** (2026-11-17, found in the long save): the Fish Guts from Gut Fish and from Pack Fish in Salt came out fresh from a stale fish; they now keep the fish's age, as the head already did (`F.onCreateGutted`). test_curing checks both recipes.

## 0.4.62
- **Docs** (2026-11-16): the Stone Hearth beside the Smokehouse is built of 12 Stone Blocks, 2 Clay and a trowel (TP Core 0.1.7; was 8 Clay Bricks). README only; nothing changes in game.

## 0.4.61
- **Grain's season in the guide** (2026-11-16): the almanac and "What the base game gives" now say wheat, barley and rye are sown August to October (best in September) and take about three and a half months to ripen; were "nothing is sown after summer" and "October to January: nothing may be sown" (vanilla 42.22 `farming_vegetableconf_vegetables.lua`). Guide 1 only; nothing changes in game.

## 0.4.60
- **Pork Fat (Raw, Fresh) and Suet (Raw, Fresh)** (2026-11-16): anything that goes off shows *(Fresh)* in its good state, so raw fat in the cauldron says it can go rancid; were Pork Fat (Raw) and Suet (Raw). Fluid names only.
- **Animal Blood (Cured, Fresh)** (2026-11-16): cured blood still spoils (3 days at 20 C, 7 in a fridge), so it shows *(Fresh)* too; was Animal Blood (Cured). README, DEVHELP, guide 1.

## 0.4.59
- **Naming sweep** (2026-11-16, TP Core's DEVGUIDE "How code is named"): a stack's drying `method` (`F.hangMethod`, was `hangKind`), its sprite's `look` (`F.FIRST_ROTTEN_LOOK`, `ROTTEN_LOOKS`, `F.rottenLook`, `stackLooks`), `tubMeat`, `F.sausageOf`, the sausage popup's `fireEffect`; blood's `F.BLOOD_FLUID_KIND` and `F.BLOOD_PROCESS`; `F.clearModData`. The tile builder's names follow (`ROTTEN_COLOURS`, `TUB_MEATS`): rerun, the tiles, pack and Tiles.lua come out byte-identical. Tests and golden results unchanged; nothing changes in game. Saved keys follow TP Core's renames (`workHours`, `marks`, the Smokehouse stack's hours): pre-release, an old test save's stations read as new, so test on a fresh save.

## 0.4.58
- **Wraps through TP Core's `Wrap`** (2026-11-16): `ISAddItemInRecipe.complete` and `checkName` go in late and guarded. Nothing changes in game.

## 0.4.57
- **Refusal and status keys as constants** (2026-11-16): the keys the drying and tub rules return are `F.REFUSALS`, the popup's spoilage, temperature and wind words `F.WORDS` (TP Core's DEVGUIDE "Translation keys"). Same keys, nothing changes in game.

## 0.4.56
- **Smash Bone left as vanilla's** (2026-11-16): a boiled bone still smashes into boiled pieces, but the mark is now passed after the hand craft (`F.onSmashBone`, on TP Core's `Handcraft`) instead of by giving vanilla's recipe an OnCreate at load (`F.hookSmashBone` is gone). Another mod that gives Smash Bone its own OnCreate no longer replaces ours or is replaced by it. test_curing.

## 0.4.55
- **One or All** (2026-11-16, TP Core's `PiecesUI` and `TPPutPieces`): Put Fat in the Cauldron puts one piece (the nearest to going off) or all that fit, the oldest first; before, every piece carried went in. test_fat_ui.

## 0.4.54
- **Console** (2026-11-16): `TPFM.crocks` and `TPFM.keep` find crocks through TP Core's `PlaceKeepingUI.near` (the same search, moved to Core so Dairy's butter shares it). Nothing changes.
- **Potted Meat under Clarified Butter** (2026-11-15): with Dairy on, Put Meat in Fat (was Put Meat in Lard or Tallow) also takes Dairy's Clarified Butter, a block like Lard. The line is widened at load (`F.applyPottedButter`, TP Core's `Recipes.addItems`), so without Dairy nothing changes. Tooltip. test_potted. In-game step in TP Core's `TESTING_GUIDE.md` (butter).
- **Refactor: Put Fat in the Cauldron on TP Core's shared pieces** (2026-11-15): the menu is `CauldronUI.addPieces`, the job TP Core's `TPCauldronPieces` (`TPFMFatCauldron` is gone), `F.cauldronFatRoom` and `F.putFatInCauldron` call `CauldronFluid.pieceRoom` / `putPieces`. Same rows, texts, room and rancid hour. test_fat_ui checks the core's job. Nothing changes in game.
- **Refactor: Potted Meat keeps by place through TP Core's `PlaceKeeping`** (2026-11-15): `F.POTTED` is the keeper; `F.keepCrock`, `F.pottedLedger`, `F.recordPotted`, `F.pottedRate`, `F.POTTED_AGEING` and the curve, ledger and modData keys are as before. `TPFM.crocks` and `TPFM.keep` use the keeper's `describe` and `age`. `F.pottedTemperature` is gone (Weather's own). Nothing changes in game; tests and golden results unchanged.

## 0.4.53
- **Guide checked against the code** (2026-11-15): salt counts from anything in reach, not only what you carry; a cow takes 150 salt, a pig about 100, a sheep 44 (a Steak or chop takes 2); the Almanac's August and September loft days; stockfish's 32 days and charque's 5 are a fair breeze's (a good drying wind about 27 for stockfish); a full frame of stockfish is about 4.4 weight; rabbit is over four times a chicken leg's calories; Pack Meat in Salt lists poultry and rabbit. Nothing changes in game.
- **Guide shortened** (2026-11-15): the Smokehouse's joining rules point to TP Core's guide; repeated secrets, tips and Logbook entries cut; the two carry tables merged; no history notes (the old-save stockfish row, the Smokehouse's move). Nothing changes in game.
- **README and DEVHELP say what is** (2026-11-15): no version tags, step labels or dev-machine paths. Nothing changes in game.
- **Docs and comments** (2026-11-15): decisions are stated plainly, without attributions (CHANGELOG, comments, scripts, README, tests). Nothing changes in game.
- **README** (2026-11-15): the opening table adds rendered fat, the stocks and fresh sausage, and Potted Meat's poultry and rabbit.
- **README and guide** (2026-11-15): the README heading names 0.4.53 (was 0.4.30), as mod.info does; the guide drops three "(0.4.35)" history tags.
Refactor with TP Core's Stone Hearth split (2026-11-15): the fat's cauldron rules are TP Core's `CauldronFluid.*` and `Cauldron.of`, stove food goes through `StoneHearth.cooksOn`, the Smokehouse's notes through `FireUI.addNotes`; the fat cauldron action's fire is `action.fire`. Nothing changes in game.

## 0.4.52
Refactor with TP Core's names (2026-11-15): TP Core's `Hearth` is `Fire` and the Firebox is the Stone Hearth in the code (`Fire.isStoneHearth`, `joinedStoneHearth`, the `stone` kit); comments and docs say Stone Hearth. Nothing changes in game.

## 0.4.51
Refactor with Vinegar's (2026-11-15): a stack or tub not yet seen by the World reads TP Core's `Weather.NEW_RUN_PLACE` (`F.placeWord`; the open air, as before). Nothing changes in game; tests and golden results unchanged.

## 0.4.50
Refactor (refactor pass step c, Fish & Meat): nothing changes in game but five fixes, each agreed first.
**The main file split in five** (it was 2,568 lines): `TraditionalPreservationFishMeatLedger.lua` (the rates, the weather totals and what they do to stacks and tubs, the popups' status), `...Names.lua`, `...Stock.lua`, `...Stockfish.lua` (pallet and bale), required at the main file's end; and `TraditionalPreservationFishMeat/Common.lua`, required by every file that uses it: **every item the code names as a constant** (`F.GUTTED_FISH`, `F.HOT_MEAT`, `F.BLOOD_SAUSAGE`... gathered from four files; the type strings typed out across the mod are gone) and the shared helpers (`F.setNutrients`, `F.scaleNutrients`, `F.foodOf`, `F.nameAs`, `F.isEmptyPot`, `F.optionOn`, `F.setPartRow`, `F.clearData`).
**One place word per stack:** the World saves TP Core's place (`modData.place`) where it set five flags (`sheltered`, `covered`, `basement`, `loft`, `inShed`); `F.placeWord`, `F.ledgerPlace`, `F.sheltered`, `F.covered`, `F.inShed` read it. **One table of the ledger's totals:** `F.TOTALS` names each family's key at each place (the keys themselves keep their names), `F.gain` and `F.mark` read and mark them, `F.advance` adds a basement, a loft and a room in one loop, and the steps, the tub's cure and the popups read `F.TOTALS` where each had its own branch per place. A stack's start clears the pooled recipe data (`F.clearData`, as the sausage's did) and marks every total (`F.markStack`; the hand list of 40 marks and 25 nils is gone). The ledger's spoiling flags are `key .. "On"` (`warmCureOn`, `rawSpoilOpenOn`...; were `warmCuring`, `openWarmCuring`...); a tub batch marks a long cure with `countryCure`; marks follow their key (`lastDryCureBasement`, was `lastCureBasement`). `TPFM.age` and `TPFM.spoil` loop over the table.
**Say it once:** `breezeRate` (cold drying's and charque's wind), `F.lineThrough` (the dry cure's and the cook's hours), `F.smokeHours` is `Weather.curve`; lookups for the cuts and icons, built once; `F.WHOLE_CHICKEN` / `F.WHOLE_TURKEY`. One look through a container renames its stages and keeps its crocks (was a search per stage type, about 25, at every inventory refresh; `F.keepCrocksIn` gone). **Core's helpers:** `UI.selectedItems` (was `selectedFish`), `UI.refuse` (Tie a Bale with no cord, Fat with no room), `UI.tooltip`, `Action.removeItem`, `Action.addXp`, `Hearth.redraw`, `FluidTreat.litresIn`. **Test-build leftovers gone:** the press clock for batches before 0.4.34 (`pressStartHour`, `OLD_PRESS_HOURS`; `F.pressStatus(modData, ledger)` and `F.pressDone(modData, ledger)` take no hour), a tub's "no mark" fallback, `toDryCure` (shed meat before 6b), `coldNeed`'s fallback, the ledger's upgrade (a table without the newest total is filled in); spawned stockfish, dry cured meat and bales with no stamp keep their rule, now said as such. Stale guards gone (`F.STAGES and`, `F.MEAT_FAT_POTS and`, `getScriptManager and`, `and addXp`). Comments put back above their functions.
**Fixed:** **B1** dry curing in a loft is slowed by damp air as a room's is (it went without the air's rate; only that changes in game); **B2** a Leg of Pork takes the newest Pork pieces in the inventory's order (it went by `pairs`, rule 9); **B3** items taken out by Tie a Bale, Untie, a Leg of Pork and Put Fat in the Cauldron leave the hands (TP Core's `Action.removeItem` now uses vanilla's `Remove`); **B4** `TPFM.age` also spoils poultry and rabbit waiting in the shed; **B5** two stacks as far along keep one order (by when they were hung), so their sprites don't swap. Tests: test_pork, test_world, test_smokehouse, test_console, test_ui new checks; fixtures use the place word; golden results unchanged. **Also (after the findings):** `TPFM.kit()` lists its kits in name order (was `pairs` order, rule 9); an unsalted stack's popup warns of spoiling by the totals its step reads (the season's anywhere but the open air; it read the day's for one indoors, while the stack spoiled by the season's). test_console, test_curing; test stand-in containers have `Remove`. In-game step 158 of TP Core's `TESTING_GUIDE.md` (INGAME_PASS 157).

## 0.4.49
Refactor with TP Core's small shared helpers tidy (2026-11-14): `F.bloodIn` calls `getFluidContainer` without checking the method is there (every item has it). Nothing changes in game. Test stand-ins given the methods the engine has (test_blood `sendSyncEntity` and `getWorldItem`, test_curing `getWorldItem` and the salt empties through `Uses.onEmptied`, test_ui `getCurrentRecipe`); tests and golden results unchanged.

## 0.4.48
**Bug fixed: raw fat in the cauldron and vanilla's Food Spoilage**: a piece's days left were counted as real days, but its age runs at the game's Food Spoilage speed, so on Very Slow fat went rancid in the cauldron 2.5 times sooner than on the shelf, and on Very Fast later. `F.fatHoursLeft` divides by TP Core's `FluidAgeing.foodRotSpeed`; Normal changes nothing. test_fat. In-game step 150 of TP Core's `TESTING_GUIDE.md` passed (INGAME_PASS 149).

## 0.4.47
Refactor with TP Core's Weather.lua tidy (2026-11-14): the Potted Meat ledger is totalled by `Weather.advance` (`F.recordPotted` was a copy of its loop; same keys, `pottedOpen` and the rest); the main ledger asks `Weather.seasonTemperature` and `Weather.seasonHumidity` (was `Weather.season`); a crock with no place goes by `Weather.DEFAULT_PLACE`. **Names:** the crock's curve is `F.POTTED_AGE_CURVE` (was `POTTED_KEEPING`), its spec `F.POTTED_AGEING` (was `POTTED_KEEP`, three letters from the curve), the rate `ageRate` (was `keepRate`: higher means it ages faster), the ledger's kinds `POTTED_LEDGER_KINDS`; vanilla's Food Spoilage setting is TP Core's `FluidAgeing.foodRotSpeed` for Potted Meat and blood (blood borrowed Potted Meat's, behind a load-order guard; its local `spoilSpeed` is gone). Nothing changes in game; tests and golden results unchanged.

## 0.4.46
**Bug fixed: Firebox Info's smoke note never showed** (found in TP Core's HearthUI tidy): *Stoked for 4 to 8 hours in a row, it hot smokes the salt stacks in the shed...* read the fire's old `flue` field, gone since the flue became a Hearth connection; it now shows on any Stone Hearth joined to the Smokehouse. Also, with TP Core's tidy: *Put Fat in the Cauldron* and the fat notes come through `CauldronUI.addMenu` / `addNotes` and read the cauldron as `info.part`. test_fat_ui: the fat note and the smoke note, joined and not. In-game step 148 of TP Core's `TESTING_GUIDE.md` passed (INGAME_PASS 147).

## 0.4.45
**No station in front of a door** (after TP Core's in-game step 146b): the Drying Frame, the Salting Tub and the Stockfish Pallet (at any fill) can't be built or put down on the tile in front of a door any more (the Stone Hearth's mouth, a Smokehouse's door; TP Core's `Doors`), as the Hanging Beam and the Gantry already couldn't. Their build recipes ask `TraditionalPreservationCore.doorFits`; `UI.keepDoorsFree(Tiles.STATIONS)` and the pallet's sprites for putting down. test_curing. In-game step 147 of TP Core's `TESTING_GUIDE.md` passed (INGAME_PASS 146).

## 0.4.44
Refactor with TP Core's copper-to-cauldron rename (2026-11-14): the action is `TPFMFatCauldron` (was `TPFMFatCopper`), the menu key `FatInCauldron`, and `F.putFatInCauldron`, `F.CAULDRON_FATS`, `F.cauldronFatRoom`; comments and tests say cauldron. Nothing changes in game; tests and golden results unchanged.

## 0.4.43
Docs pass after TP Core's Stone Hearth hub: the guide, README, DEVHELP and Workshop text say Stone Hearth and Forged Cauldron (Firebox, Hearth and copper gone), the Smokehouse's flat roof and low clay pipe, and that the hole stays lidded and the cauldron fits while it smokes. DEVHELP's cold smoke limit corrected to 15 C (`F.COLD_SMOKE_MAX`). Console help and outputs (`TPFM.smoke`, `stoke`, `bank`) say Stone Hearth.

## 0.4.42
TP Core's Hearth kettle is the Forged Cauldron: texts say Cauldron (Put Fat in the Cauldron, the fat's notes, the fat tooltips). A Stone Hearth joined to the Smokehouse can have the Cauldron fitted too (TP Core's two slots); the shed's smoke note shows on a fitted one (reads `info.state`). Needs this TP Core. In-game step 128 of `TESTING_GUIDE.md` (INGAME_PASS 127), passed.

## 0.4.41
Its pots on the hob are TP Core's stove food (`Hearth.cooksOn`): fat, potted meat, stocks, soups, stews and poached sausage, in a pot or a forged pot, so the Stone Hearth sets its pot in the hole for them; the pudding pans stay oven food. Firebox reads Stone Hearth in its texts. Needs this TP Core (the Stone Hearth hub, step ii).

## 0.4.40
TP Core's Hearth keeps the copper's state under its own key (`tpHearth.copper`, the Stone Hearth hub's step i). Needs this TP Core. Put Fat in the Copper reads it with `Hearth.copperState` (`TPFMFatCopper`); `test_fat_ui.lua` loads Core's `CopperUI` and builds the new state. Nothing changes in game.

## 0.4.39
The Smokehouse is TP Core's (before Dairy, so its smoked cheeses share it). Needs this TP Core. Old saves are ignored: a Smokehouse built before this is gone on load, build a new one. In-game step 125 of `TESTING_GUIDE.md` (INGAME_PASS 124), passed.
- **Moved to TP Core:** the chamber entity, its art and build icon, Connect / Disconnect the Firebox (menu and action, was `TPFMFlue`), the flue kits, the door, the flue's entry and the ham by the door, the recipe tag, the fire's two counters (`Smokehouse.fireStep`) and their texts. Hot and cold smoking, dry curing, sausage and what comes out stay here and work as before; `F.smokeStep` adds the fire's warmth to Core's counters.
- **Only its own stacks:** a stack this mod hangs records it (`F.OWNER`, through Core's `startCounters`); the World steps, shows and finishes only those, and Smokehouse Info lists only those. Another mod's stacks count against the shed's 6. In the shed's slots this mod judges only its own items (Core's `UI.slotRules` `owns`).
- Tiles 856-869 left empty, so no other tile moves. Firebox Info's note on smoking is in `...SmokehouseUI.lua`.
- Console: `TPFM.smokehouse()` and `TPFM.kit("flue")` are now `TPC.smokehouse()` and `TPC.kit("flue")`; `TPC.kit("smokehouse")` is new. `TPFM.smoke()`, `stoke`, `bank`, `addSmoke` stay.

## 0.4.38
Smoked Sausage, kielbasa style (ROADMAP). In-game step 124 of `TESTING_GUIDE.md` (INGAME_PASS 123), passed. Needs this TP Core (`Season`).
- **Stuff Sausages**: two raw Pork or Pork Chop, a third piece of Pork, Pork Chop, Beef, Steak or Venison, a whole Pork Fat or half a Lard (12 uses), a Salt use and a Salted Casings: **6 Fresh Sausage**, uncooked, 0.25, 525 kcal (a sixth of what goes in, about 3,150 kcal a batch), hunger 30, fresh 2 / rotten 4 as vanilla's sausage.
- **Seasoning, afterwards, as a stew's**: right-click a Fresh Sausage, a raw or a boiled Blood Sausage, **Season**: Garlic, Onion, Pepper, Oregano (the game has no marjoram), Thyme or Sage, fresh, dried or the spice jar. Each kind goes in once, as many kinds as you like, taking what a stew takes (a use; half an onion), and makes the link -2 unhappiness and -2 boredom, as vanilla's spice in a stew (`F.SEASONING_UNHAPPY`, `F.SEASONING_BOREDOM`); its icon shows on the link's tooltip. It stays with the link through the pot, the pan, the smoke and the knife (TP Core's `Season`; the pot keeps each link's, `tpLinks`). Black Pudding takes none.
- **Fresh:** fried as it is, *Fresh Sausage (Fried)*; **Put Sausages in Water** (a pot with 1.5 L), 30 minutes at the boil, **Take Out Sausages**: *Fresh Sausage (Boiled)*. Both keep the raw 2 / 4.
- **Hang Sausage to Smoke** (the Smokehouse only) is now **one recipe for both sausages**: it replaces 0.4.37's Hang Blood Sausage to Smoke, and its tooltip says it takes Blood Sausage or Fresh Sausage. One kind to a stack; the recipe tests each link (`F.canSmokeSausage`: blood sausage boiled and never fried, fresh sausage raw) and the stack takes its kind from its links. A blood sausage stack still hanging from 0.4.37 names a recipe that is gone and may not survive the update: take it down first. Raw fresh links: A **hot run**, 6 hours stoked in a row (`F.SAUSAGE_HOT_HOURS`, the Smokehouse's hot counter), cooks them through in the smoke in any weather; a banked fire doesn't, and a broken run starts again. Cooked in time: **Smoked Sausage**, 0.22, 525 kcal, hunger 30, **14 / 30 days**, as fresh a share of that as they were of their two days; any that went off first come down raw. **Slice Smoked Sausage**: 4 rounds, 14 / 30.
- The blood sausage's stack code now serves both (`F.sausageSmoke` picks the cold counter or the hot run; `modData.sausage` is `true` for blood, as stacks already hanging have it, or `"pork"`); the popup and the info block say which.
- Own icons and models: a pink flecked raw link, a brown fried one, a red-brown smoked link and flecked slices (`tools/build_meat_icons.py`).
- Console: `TPFM.give("freshSausage", n, "seasoned" | "stale")`, `"smokedSausage"` (`"seasoned"`: garlic, pepper, oregano), `TPFM.kit("sausage")` (with a seasoning of each kind); `TPFM.smoke()` names a sausage stack's kind. Tests in `test_blood.lua`.

## 0.4.37
Smoked Blood Sausage (ROADMAP). In-game step 123 of `TESTING_GUIDE.md` (INGAME_PASS 122), passed.
- **Hang Blood Sausage to Smoke** (the Smokehouse only): boiled links, a stack of their own (no fish or meat with them; a link fried after boiling is refused, on the drop and by the recipe). They take **24 hours of the Firebox's smoke** (`F.SMOKED_SAUSAGE_HOURS`), banked or stoked, on the Smokehouse's cold counter: only on days of 15 C or less, and a stoked run is smoke at once, never a cook. Banked all day in a cool month, a day.
- **The links keep their boiled week while they hang** (a day a day, by the Food Spoilage setting). Smoked in time they come down **Smoked Blood Sausage**: 0.22 a link (0.25 boiled), 538 kcal, hunger 30, **21 / 40 days**, as fresh a share of that as they were of their week. Any that went stale first come down *Blood Sausage (Boiled)*, aged by the days they hung; with no fire the stack ends when its links do. A part-eaten link keeps its share.
- A smoked link is cooked: eat it cold, fry it, or put it in a dish. **Slice Smoked Blood Sausage**: 4 rounds, 21 / 40.
- Hover the stack (or the Smokehouse's info block): its smoke against the 24 h, what the fire is doing for it (smoking, too warm, no fire) and the days its links have left.
- Own icons and models, browner and darker than the boiled link (`tools/build_meat_icons.py`, `SMOKED_BLOOD`).
- Console: `TPFM.give("bloodSausage", n, "stale")` (boiled links are now given cooked, as the pot makes them; "stale" 0.1 days short of the week), `"smokedBloodSausage"`; `TPFM.kit("blood")` adds 6 boiled links and a smoked one. Tests in `test_blood.lua`.

## 0.4.36
Blood (ROADMAP section 7). Needs this TP Core (fluid states, the treat menu, `Uses`, `OnCreateCooked`, the gather-blood wrap). Salt charging (`F.chargeSalt`, `F.saltCarried`) now goes through Core's `Uses`, same behaviour. In-game step 121 of `TESTING_GUIDE.md` (INGAME_PASS 120).
- **Blood by weight.** Vanilla bleeds a pig or a sheep of 8 to 25 L, four to six times a real sticking. Each animal now gives 3.5 cl a kg of its weight (about half its blood): a 100 kg pig 3.5 L, a 600 kg cow 20 L; pigs 4-12 L, ewes 2-4, rams 3-7, deer 4-7, cattle 12.5-33, bulls up to 45 (`F.realBlood`, applied to vanilla's animal table as it loads).
- **Blood goes off** through TP Core's fluid ageing (kind `blood`, `F.BLOOD_SPEC`, its own weather ledger): fresh, a day at 20 C, three in a fridge, stopped frozen, then *Blood (Spoiled)* (mildly poisonous). No soured stage.
- **Cure Blood** (in the container's own submenu, *Bucket > Cure Blood > Salt (n) / Vinegar (n)*, n what you carry, the tooltip saying what it takes; greyed with the reason when it can't be done) stirs a use into the blood for each 2 L, in place. Salt or vinegar, it becomes *Animal Blood (Cured)* (one state), 3 days at 20 C, 7 in a fridge (its own cold curve, ledger kind `bloodCured`); cured mixed with cured stays cured, fresh mixed in makes it fresh; blood gathered onto treated blood makes the lot fresh (Core's wrap of `ISGatherBloodFromAnimal.updateBucket`; the menu is Core's treat menu). New fluids `CuredBlood`, `SpoiledBlood`.
- **Casings.** Pigs, cattle, sheep, deer and their young get a *Raw Casings* row in vanilla's butchering tables (on the Hook a pig about 3, cattle 4, a sheep or deer 2, a young animal 1); raw they go off in a day. **Clean and Salt Casings** (0.5 L of water, a Salt use): *Salted Casings*, a year.
- **Black Pudding.** **Mix Black Pudding**: a Baking Pan or Roasting Pan, 1 L of blood (fresh or cured), one filler, any of them: a quarter bag of Oats or Rice (12 uses) or, renewable, 12 grains of Barley, Rye or Wheat, on one line charged by TP Core's `Charge` (the craft window shows the real amount; anything in reach counts), half a Lard or Tallow or a piece of raw fat (12 uses), a Salt use. Bake 60 minutes, **Turn Out Black Pudding** (the pan back), **Slice Black Pudding**: 6 slices of 0.25, 538 kcal, hunger 30, fresh 5 / rotten 10.
- **Blood Sausage.** **Stuff Blood Sausages**: the same mix in a Salted Casings, 6 *Blood Sausage* links, *Uncooked*; fried as they are they become *Blood Sausage (Fried)*, keeping their raw 1 / 2 days; **Put Blood Sausages in Water** (a pot with 1.5 L), 30 minutes at the boil, **Take Out Blood Sausages**: 6 *Blood Sausage (Boiled)*, 0.25, 538 kcal, hunger 30, fresh 7 / rotten 14. A boiled link fried 5 minutes more becomes *Blood Sausage (Boiled, Fried)* (TP Core's `OnHeat`). **Slice Blood Sausage** (knife, a cooked link): 4 *Blood Sausage Slices*, cooked. Slices and links go into soups, stews, stir fries, sandwiches, burgers, rice and pasta.
- **Sounds:** the pots of blood sausages and every stock, soup and stew pot play TP Core's `TPBoiling` (vanilla's BoilingFood sizzled); the black pudding pans bake silently, as vanilla's bread dough.
- **Names and looks:** fresh blood reads *Animal Blood (Fresh)* (vanilla's name overridden), spoiled *Animal Blood (Spoiled)*. Black Pudding, its slices and Blood Sausage are made cooked (*Cooked* in the name; they can be warmed or fried again). Own icons and ground models (`tools/build_meat_icons.py`): a near-black flecked loaf and square slices, a dark red raw link and a near-black cooked one (`Item_BloodSausage_Cooked`, which the game picks for a cooked item). Casings and pans keep vanilla's icons.
- Console: `TPFM.give("blood", n, state)` (a Bucket of 4 L; `"cured"`, `"spoiled"`), `TPFM.animals()` (nearby animals' weight and blood, carcasses' blood left; the game's info window shows no weight), `"casings"`, `"saltedCasings"`, `"blackPudding"`, `"bloodSausage"`; `TPFM.kit("blood")` (every filler, 12 grains each); `TPFM.blood(hours)`. Tests in `test_blood.lua`.

## 0.4.35
- **Fix** (2026-11-13): `IGUI_TraditionalPreservationFishMeat_DryCured` was in `IG_UI.json` twice (a stale "Dry Cured %1" from 0.4.22); the game refuses the whole file on a duplicate key, so every IGUI text of the mod showed as its key. The stale line removed.
Realism pass, part one (numbers skewed to acceptable realism, every method kept viable; ROADMAP).
- **Under-salted meat above freezing.** Corned red meat hung to dry (the Smokehouse, a room, a basement) used to last about 140 days near 0 C. Above freezing it now rots within **6 weeks** of thawed hours however cool (the middle sours before the salt gets there: `F.UNDER_CURE_MAX_DAYS`), and in 4 at 10 C as before; frozen hours keep the slow curve, so meat hung in a hard frost freeze-dries slowly. The long cure is the way to a long hang.
- **Poultry and rabbit:** the 14 days a waiting stack lasts now count only hours above freezing (`F.hotOnlyUnderRate`); frozen, a bird keeps, as farms hung them all winter. Both rules are hourly ledger totals by the shed's temperature, the fire's lift included (`hotOnlyUnder`, `...Banked`, `...Stoked`), and scale with the Spoilage sandbox setting.
- **A rinsed Corned piece** spoils 1 / 0.9 as fast while under-salted (it lost surface salt; `F.underLoss`); a stack goes as a whole only when its slowest piece does.
- **The tub in the cold:** curing goes by the tub's place temperature, full speed from 2 C, half at −5 C, a quarter from −10 C (`F.TUB_CURE_POINTS`; a brine doesn't freeze solid, and the old rule added a day of cure for each freezing day). A January tub outdoors takes about twice as long; a basement tub never slows. Its popup and the info block count the time left at today's speed. A batch already running keeps the clock.
- **Potted Meat frozen** keeps as in a freezer: from 0.5 at 4 C down to nothing at −2 C (`F.POTTED_KEEPING`). No damage to the jar.
- **Dishes name meat by its animal:** hot smoked, dry cured and soaked charque meat and their slices went into dishes as "Beef" (one script item for every animal). Each piece's entry in the dish is now the stand-in of its stage and animal, with vanilla's food type and name: *Venison Stew*, *Chicken Soup*, *Pork Stew* (dry cured), with its own icon. 28 stand-ins, written by `tools/build_standins.py`. Dishes made before keep their names.
- **Dry cured meat named as every other stage**: *Beef (Dry Cured)* and *Beef (Cold Smoked)* (was Dry Cured Beef and Smoked Dry Cured Beef), the same for mutton, venison and pork; slices *Beef Slice (Dry Cured)*; aged *Beef (Cold Smoked, Aged)*, one bracket. Their dish stand-ins too, with Cold Smoked ones of their own (dry cured meat with its smoke had shared the Dry Cured stand-in; `F.standinFor` takes the piece's `airDried`), so a stew lists *Beef (Cold Smoked)* as the piece is named. Dishes made before keep the entry they have. Charque (*Beef Charque*), Country Ham and Smoked Country Ham keep their names. Only the shown name changes; pieces already made rename themselves. README, Workshop text and `Balance/CraftingRecipes.md` lose the last regional names (Suho Meso, Mutton Ham, Jerked Venison, Bresaola) the 0.4.34 rename missed.
- TP Core's warmer winter room (+2 C at a season of 10 C or below): `test_potted.lua`'s room checks moved to match; the season report's loft column shifts a degree in April, August and September.
- Dry curing keeps its quarter-speed floor in frost (freeze-drying is real: *Bündnerfleisch*, stockfish). Tests in `test_smokehouse.lua`, `test_curing.lua`, `test_potted.lua`. In-game step 116 of `TESTING_GUIDE.md`.

## 0.4.34
- **Hot smoked chicken, turkey and rabbit** (ROADMAP section 7). Vanilla's six poultry cuts, a whole Chicken or Turkey and Rabbit Meat go into **Pack Meat in Salt** (half red meat's salt, a brine's: a whole chicken 5) and **Corn Salted Meat** only: *Chicken Leg (Corned)*, *Turkey (Whole) (Corned)*. Country Cure refuses them (the tub says why), and so do charque, the shade and the cellar: they hang in the **Smokehouse** alone. Real practice: poultry and rabbit were brined and hot smoked, never dried; lean bird fat goes rancid, raw poultry carries salmonella and rabbit tularemia, which only cooking kills.
  - **Corned poultry and rabbit keep 3 / 6 days** (a light brine), not red meat's 7 / 14.
  - **A whole bird counts as 0.4 (chicken) or 0.5 (turkey) for timing** (`F.TIMING_WEIGHTS`, `F.timingWeight`): it is hollow, so the salt and the heat go no deeper than a thick cut's. A whole chicken cures 38 hours and cooks 7 stoked hours, a turkey 48 and 8; a cut cures about 29 and cooks about 5.7, on the meat curve as it is.
  - **In the Smokehouse a poultry stack only waits for its cook** (`modData.hotOnly`): it never dries or takes smoke, a broken run starts again, and it spoils as under-salted Corned meat does, 14 / 6 times as fast (`F.HOT_ONLY_UNDER_RATE`): about 12 days at 10 C, 2.4 at 20 C, and never more than 14 days even in frost (`F.HOT_ONLY_MAX_DAYS`). Poultry and rabbit hang apart from red meat. Its popup and the info block say *Hot smoking only*, the cook's hours or *Waiting (Needs a stoked Firebox)*, and the spoiling.
  - **Hot Smoked poultry keeps its cut's name** (*Turkey Wing (Hot Smoked)*, *Chicken (Whole) (Hot Smoked)*): Hot Smoked meat's values otherwise, vanilla's food carried over. It isn't sliced. **Carve Chicken (Hot Smoked)** and **Carve Turkey (Hot Smoked)** cut a whole smoked bird as vanilla's Cut Chicken does a raw one: 2 legs, 2 wings, 2 fillets, sharing its food by vanilla's cut hunger, 90% of its weight.
  - New icons for the nine cuts at every meat stage (`tools/build_meat_icons.py`).
- **Plain names for the dry cured meats**: Suho Meso is now **Smoked Dry Cured Beef**, Mutton Ham **Smoked Dry Cured Mutton**, Jerked Venison **Smoked Dry Cured Venison**, Bresaola **Dry Cured Beef**. Country Ham, Smoked Country Ham, Charque and Stockfish keep their names. Only the shown name changes; items already made rename themselves.
- `TPFM.meat` gives poultry and rabbit at the "corned" and "hotSmoked" stages; `TPFM.kit("poultry")` (both whole birds, every cut, Rabbit Meat, a Steak, 2 Salt, a Kitchen Knife). Tests in `test_smokehouse.lua`, `test_curing.lua`, `test_aged.lua`. In-game step 115 of `TESTING_GUIDE.md`.

## 0.4.33
- **Potted chicken, turkey and rabbit** (ROADMAP section 7): vanilla's Chicken (leg), Chicken Wings, Chicken Fillet, Turkey Legs, Turkey Wings, Turkey Fillet and Rabbit Meat go into Put Meat in Lard or Tallow, Put Meat in the Melted Fat and Add Meat to the Pot, in any mix with red meat (`F.POTTED_GAME`). Their food is vanilla's, so a rabbit portion is about 2,000 calories with its fat. One Crock of Potted Meat for all of them; the cut count, cooking time and keeping are unchanged. Poultry and rabbit still go nowhere else (no salting, charque or dry curing). A whole bird is cut first with vanilla's Cut Chicken or Cut Turkey.
- **The crock's name stays plain**: no more "(3 portions)". It eats like any food and weighs less as it empties (`Portions.weigh`, TP Core); a crock from an older build loses its suffix the next time it is eaten from. The first portion taken still costs a third of its keeping.
- `TPFM.meat` lists and gives the new cuts (raw only; a stage skips them). `TPFM.kit("potted")` adds a second Pot and Lard, a Chicken leg, Turkey Legs, Turkey Wings and Rabbit Meat. Tests in `test_potted.lua`. In-game step 114 of `TESTING_GUIDE.md`.

## 0.4.32
- **Stocks become soups or stews**. A stock's first ingredient makes it a soup or a stew, as in a real kitchen: right-click offers both (vanilla's Soup and Stew templates, so soup takes greens, roe and ramen, stew red meat), with 6 ingredients free. *Fish Head Soup with Carrots*, *Bone Broth Stew with Beef*, *Chicken Soup*. Soup cooks 50 minutes, stew 70. Divide Food into Bowls gives Soup Bowls for a stock or soup, Stew Bowls for a stew. Fish Head Stock was a stew from the start; a pot of it that already holds ingredients stays as it is.
- **Meat stocks** (ROADMAP section 7), built like Fish Head Stock: a Pot or Forged Pot with 1.5 L of water and the parts.
  - **Bone Broth**: **Make Bone Broth** takes 2 Animal Bones, 1 Large Animal Bone or 6 Small Animal Bones. About 80 kcal, mostly protein; 150 from the Large's marrow. The bones are kept and come back as *Boiled Animal Bone*: every tool recipe still takes them, but they make no more broth, and vanilla's Smash Bone now passes the mark to its pieces (an OnCreate given at load).
  - **Chicken Stock**: **Make Chicken Stock** takes 2 parts, Chicken Feet and chicken or turkey heads in any mix: 35 kcal a foot, 15 a head. Bone Broth's and Chicken Stock's soups and stews list one icon for their stock (a pile of bones, a chicken foot), as Fish Head Stock's list the head: never named, taking no slot.
- **Every stock, and its soup and stew, starts at hunger -5, -10 unhappiness and -10 boredom**, Fish Head Stock too (was -20, no boredom, and the head's hunger on top). A design decision: a stock is worth its taste, not its calories. A test holds the numbers. The soup or stew keeps the stock's mood and listed parts (`F.carryStock`: vanilla's addItem drops both).
- **Bowls are named after the dish**: Divide Food into Bowls gave *Bowl of Pot of Fish Head Stock* from a stock with nothing added (vanilla names a bowl after the pot). Now *Bowl of Fish Head Stock*, *Bowl of Bone Broth Soup with Carrots* (`F.onCreateStockBowls`).
- `TPFM.give("boneBroth")`, `TPFM.give("chickenStock")`, `TPFM.give("soups")` (each stock's soup and stew), `TPFM.kit("stock")` (the parts of every stock, the Fish Head too, 5 Pots and 4 Bowls). Tests in `test_curing.lua`. In-game step 113 of `TESTING_GUIDE.md`.

## 0.4.31
- **What a stack comes out as**. One recipe still hangs each kind, so its output picture shows Charque (or Salt Dried) whatever the stack will be. A hanging stack's hover now has a **Comes out as** line: what it would come down as now, by `F.onCreateDried`'s rules (`F.stackOutcome`), named as the items will be: *Beef Charque*, *Bresaola, Country Ham*, *Venison (Hot Smoked), Ham*, *Suho Meso*, *Rotten* for a lost piece. In the Smokehouse it gives the likeliest result now: Hot Smoked while a stoked run counts, smoked once the stack has its hours of smoke, air dried otherwise. Tests in `test_smokehouse.lua` and `test_ui.lua`.
- **The window's Output slot**: its popup said *Charque* (or *Salt Dried*) whatever the stack would be. For Hang Salted Meat to Dry and Hang Salt Cured Fish to Dry it now lists every end and where it comes from (Charque, Dry Cured meat, Country Ham, Hot Smoked, smoked dry cured; Salt Dried, Hot and Cold Smoked Fish), through TP Core's new `UI.outputTooltips`; the icon stays the script's. Needs this Core.
- The three Hang recipes' tooltips list every end: Corned meat (Charque in sun or under a roof, dry cured indoors), Country Cured meat (dry cured in the shade), the Smokehouse's three; salt fish's Hot and Cold Smoked; Stockfish.
- Guide: chapter 22, **The Yearly Plan**: each process (cold drying, salt drying, charque, the long cure, smoked and air dry curing, cold and hot smoking, potting and rendering) as the game's planting seasons: season, best and poor months, out of season, where and how long at best, from the season tools, and a table of what a stack turns into by where it hangs. The Tester's Toolkit is now chapter 23. The station table notes that Corned meat in a Smokehouse with no fire dry cures, under-salted. In-game step 109 of `TESTING_GUIDE.md`.

## 0.4.30
- **Docs pass, sweep step G** (2026-11-12): `tools/season_report.lua` gains a loft column (salt fish days and keeping lost: two thirds in a July loft); `tools/charque_report.lua` now steps each stack through `F.charqueStep` on the ledger, so a roof goes by the season's mean as since step I (slower in winter, quicker in October); its room column is gone (meat there dry cures). Guide: loft column in the almanac, the charque table's roof column, a loft row for Potted Meat, `TPFM.weather()`'s loft line. README: season and charque tables from the tools, the Hanging Beam builds anywhere, `Weather.placeOf(station)`, the room-heating caveat. Workshop text: the Beam anywhere, the Smokehouse *In a shed*, Potted Meat 2 to 4 months in a basement.
- **Fix: Eat 1/4 on a Crock of Potted Meat from the debug Item List ate the whole crock**. A
  crock not packed by Pack Potted Meat had no portion record, so after any bite it read as empty and the rest went
  with the jar. Such a crock now holds what its script gives, one portion in a plain Clay Jar, written down at its
  first bite (`F.adoptCrock`). Packed crocks were never affected (in game: a quarter of four portions left three).
  Test in `test_potted.lua`. In-game step 107 of `TESTING_GUIDE.md`.

## 0.4.29
- **Carpentry only** (2026-11-12, sweep step F): the Salting Tub, Drying Frame, Hanging Beam and Gantry no longer ask
  Fishing 2 (it dated from when the mod was fish only; a charque maker needed it for a tub). The Smokehouse gives 15
  Carpentry XP (was 30), five a level as the other stations.
- **Make Fish Head Stock** (was Create Fish Head Stock), the series' verb for a recipe that makes a thing; the
  recipe's id is unchanged.
- Needs Build 42.22 or newer (`versionMin`, was 42.20: everything is checked on 42.22). Guide, README, Workshop text.

## 0.4.28
- **The Smokehouse is *In a shed*** (2026-11-12; TP Core's new Enclosed place). Its window and its stacks' hovers
  say *In a shed* where they said *Indoors*. Nothing else changes: it already went by the day's temperature, out of
  the rain and wind, with no stockfish. In the code the chamber's World entry is `"Enclosed"` instead of
  `"Sheltered"`, and the checks that read "Sheltered, but not the shed" now read the place. Stacks keep
  `modData.sheltered` and `modData.inShed` and the ledger keeps its keys, so stacks already hanging keep counting.
  The Flue's help text ("Out, they dry in the shed by the day's air"). Tests in `test_world.lua` (an old stack
  keeps its marks) and `test_info.lua`. Guide (the places, the Smokehouse's table) and README. In-game step 105 of
  `TESTING_GUIDE.md`.

## 0.4.27
- **On TP Core's shared modules** (2026-11-12; nothing a player sees): the Crock of Potted Meat's portions, name,
  weight and empty vessel go through Core's `Portions` (its `onEat` in place of the mod's own wrap of the eat
  action; the crock's texts are Core's), an OnCreate's items come from Core's `Recipes.created` and
  `Recipes.consumed`, and Rinse at Sink finds its water with Core's `Station.nearAt`. Save keys are unchanged.
  In-game steps 10 and 101 of `TESTING_GUIDE.md`.
- Guide, README and DEVHELP (2026-11-12): checked line by line against the code. Hot smoking's hours go by the
  heaviest piece as it weighs cured and run on past 2.2 weight (about 8 for a walleye caught at 4, a Steak about
  6, a Beef about 7½); a muggy spell is read off the last ten days in the open air, under a roof and in the
  Smokehouse, off the place's own temperature in a room, a loft and a basement; a July pantry keeps a crock about
  17 days (14 only at 25 C and over); straining asks nothing of the cloth but that it is one; Disconnect wants
  the tool again; `TPFM.longCure`, `TPFM.addSmoke` and `TPFM.underSalt` are in the lists, and `TPFM.here` names
  the Loft. One form for margin notes, no version numbers in the player's text, a Credits page.


## 0.4.26
- **Rooms and roofs go by TP Core's temperature** (2026-11-12, consistency sweep step I; the rule one place,
  one temperature). A room is the season's mean, 22 C while the grid is on; under an open roof the season's mean.
  Salt fish, charque and dry curing hung in a room (`roomSheltered`, `charqueRoom`, `dryCureRoom`) or under a roof
  (`covered`, `charqueCovered`, `dryCureCovered`) dry by it, Corned meat spoils by it (`underCureRoom`,
  `underCureCovered`), and a Salting Tub in a room minds it for its warm and long cures (`warmCureRoom`,
  `longCureRoom`; a batch started before keeps the season's). On the grid a room dries everything at summer speed
  but a press there warm cures (about 30% on two days) and a long cure rots: the tub's 20 C and 10 C limits are
  kept. The Smokehouse is a shed in the outside air and keeps the day's temperature. Cold drying
  under a roof goes by the season's mean too (55 to 60 days, November and March hangs finish;
  `hardFrostCovered`), and a tub in the open air by the day's (`warmCureOpen`, `longCureOpen`; afternoons
  over 20 C warm cure it May to September). Gutted fish in the open air spoils by the day's temperature
  (`rawSpoilOpen`), and every stockfish stack's warm rot is weighted by its wetness squared (the skin): open
  frames November to February, a roof October to March. Muggy-season spoiling of salt fish and charque goes by the
  place's temperature (`saltSpoilRoom`, `saltSpoilLoft`, `saltSpoilBasement`; a July loft spoils, a cellar never),
  and dry curing is spared it. Popup and station window show the room's temperature; `TPFM.weather()` prints
  Room and roof lines, `TPFM.age`, `warmCure` and `longCure` reach them. Season report golden updated, tests, README,
  guide.

## 0.4.25
- **The loft goes by its own temperature** (2026-11-12, consistency sweep step H, TP Core's new place: the top
  storey). Salt fish, charque and dry curing hung there dry by the loft's temperature, not the day's (`loftSheltered`,
  `charqueLoft`, `dryCureLoft`; dry curing with a room's air, no cellar's two thirds), Corned meat spoils by it
  (`underCureLoft`), and a Salting Tub there minds it for its warm and long cures (`warmCureLoft`, `longCureLoft`; a
  batch started before keeps the season's). While the grid is on a loft is 22 C, as Core says. The popup's Place and
  the station window's Air row say Loft. Potted Meat keeps by it through Core (about 15 days in a July loft against
  20 in a room).
- **Stockfish Pallet**: its x2 is Core's loft now (`F.palletSpeed(place)`), so only the top storey counts; any other
  room above ground gives x1.5 (the menu line reads "a room below the top storey"). `TPFM.weather()` prints a Loft
  line, `TPFM.age` moves loft stacks. Tests, README, guide, tooltip.

## 0.4.24
- Debug console (2026-11-12): `TPFM.fish` takes the stages `"dried"`, `"hotSmoked"` and `"coldSmoked"`, `TPFM.meat`
  `"charque"` and `"hotSmoked"`, each made as its station makes it from a cured piece. Test, DEVHELP, guide.
- Guide: no emojis (2026-11-12): the decorative bullets and margin-note marks are gone, warning signs read **Warning:**.
- **Whatever dries in a basement goes by the basement** (2026-11-12, consistency sweep step D): salt fish dries there
  indoors at the basement's own temperature (TP Core's ground mean, a month behind the season), not the day's: about
  27 days a batch all year, the slowest the mod allows (a cellar is for keeping salt fish). Charque the same.
  **Dry curing** in a basement is `F.dryCureRate(basement) x 2/3`, no longer a steady two thirds: a cut 9 to 11
  weeks hung December to February, 32 days June to October; a leg 17 to 19 weeks and 9.
- **The Salting Tub reads its place**: in a basement its warm cure and long cure go by the basement's temperature
  (`warmCureBasement`, `longCureBasement`, `F.tubSpoiling`; a batch pressed before this keeps the season's). No warm
  cure in a basement ever; a leg's long cure loses about 4% in May against rotting upstairs, a third to two thirds
  June to September, 18% in October.
- **Fix:** the stack popup's Place line showed a raw translation key since 0.4.23 (Fish & Meat's own place keys
  were removed with step C). It uses TP Core's place words now, Basement included, and a basement stack's
  temperature word reads the basement.
- Station Info's **Air** row below ground shows the basement's own temperature ("13 C (Basement)"), not the day's
  and the season's.
- Guide (places, dry curing, the tub, the year), README, Workshop text, tests.

## 0.4.23
- **TP Core's new places** (2026-11-12, consistency sweep step C): `Weather.placeOf` gives Covered by itself (the
  `true` flag is gone from every call). Potted Meat keeps by Core's place temperature (`F.pottedTemperature` is a
  plain call): a room the season's mean, 22 C while the grid is on, a basement about 5 C in January and 14 C in July
  (110 to 64 days fresh). Under-salted meat in a basement stack spoils by the basement's own temperature, and its
  popup shows it. Station Info's place words are Core's. Dry cure's basement rate is unchanged (step D). README,
  guide, DEVHELP, sandbox tooltip.

## 0.4.22
- **Debug console by the series' convention** (2026-11-12, consistency sweep; no old names kept, the mod was never
  released): `TPFM.fish(name, n, weight, stage)` (the count now comes before the weight; stage `"cured"` or
  `"stockfish"`; `"all"` gives each fish), `TPFM.meat(name, n, stage)` (`"all"`; stage `"corned"`, `"country"`,
  `"dryCured"`), `TPFM.give(name, n, option)` (head, stock, salt, fat, fatPot, crock), `TPFM.kit("potted" | "flue")`
  and `TPFM.here()`. Gone: `cured`, `curedFish`, `dryCured`, `stockfish`, `heads`, `stock`, `salt`, `fat`, `fatPot`,
  `potted`, `crock(n)`, `flueKit`. Tests, DEVHELP, guide.
- **Names follow one rule** (2026-11-12, consistency sweep): a state a piece passes through goes in brackets after
  its name, as vanilla's do, on meat as on fish: *Steak (Corned)*, *Steak (Country Cured)*, *Beef (Hot Smoked)*,
  *Beef Slice (Hot Smoked)*; finished goods keep their own names (Charque, Bresaola, Country Ham). No hyphens in a
  state: Hot Smoked, Dry Cured. Fluids *Lard (Melted)*, *Tallow (Melted)*, *Fat (Rancid)*; *Salt Dried Fish
  (Soaked)*; the recipes are **Soak Fish** and **Soak Charque**. Display text only: no item, fluid or save key
  changed. Tests, README, guide, Workshop text.
- Guide (external review): the stockfish row no longer says it must be cooked; charque's opening says an open roof
  does as well as the sun; the salt table's column is the salting weight, with why a fillet counts as half its fish.

## 0.4.21
- **Rotted stacks look rotten** (2026-11-12, from the external review): a grey-green, mottled, mouldy look for each
  kind (salt fish, cold dried fish, meat) on the Drying Frame, Hanging Beam and Gantry, 84 tiles on a new third tile
  sheet (the first two keep their numbers, so saves keep their sprites). A running stack shows it when it is lost
  as a whole; a mixed Corned and Country Cured stack dries on and keeps its look. A finished stack shows it when
  any piece in it rotted. The Smokehouse shows nothing hanging, as before.
- Fixed: a rotted piece lost its stack, so a finished mixed stack counted as two on the station and could block
  its last spot.

## 0.4.20
- **Fewer pieces a stack on the Hanging Beam and the Gantry** (2026-11-12, from the external review): a Beam stack
  takes 12 pieces and a Gantry stack 6, fish or meat alike; the weight caps (15, 50) stay. They are meant for bigger
  fish, not more fish. The Drying Frame and the Smokehouse keep 25. A full stack says "This stack is full: press
  Craft to hang it".

## 0.4.19
- **Station info in the station's own window** (2026-11-12, from the external review): the Salting Tub, the Drying
  Frame, the Hanging Beam, the Gantry and the Smokehouse show, under In Progress, Done and Take All: the place, the
  stacks in use and what each may weigh (the tub: weight and pieces against its limits), the air now and over the
  season, wind and wetness where they reach it, the joined Firebox's fire, then a bar for every running batch with
  its share and time left or why it stands still, and under them what is spoiling a batch, a hot cook under way,
  the smoke so far, pieces loaded but not started and finished ones waiting. The tub's one bar is named for its
  cure (Fish cure, Corning, Country cure) and has no number. It reads the popups' own status
  (`F.stackStatus`, `F.charqueStatus`, `F.pressStatus`; `Info.rows` in `client/TraditionalPreservationFishMeatInfo.lua`,
  the World's `inspect`), so nothing is simulated twice. TP Core's new `StationInfo`. (A first build had it as a
  separate window on the right-click; it belongs in the window.)
- **The Fish Drying Frame, Fish Hanging Beam and Fish Gantry are the Drying Frame, the Hanging Beam and the Gantry**
  (they hang meat too). Display names only; entities, sprites and saves are untouched.
- Wording brought in line with the code ("for Corned, not Salt Cured, meat"): Hang Salted Meat to Dry's
  tooltip (Corned meat for charque, Country Cured meat in the shade), the tub's, frame's, Beam's, Gantry's and
  Smokehouse's build tooltips (fish or meat; the long cure), the cured fish, gutted fish, cured meat, rinse, Corn
  and Country Cure tooltips, a Country Ham's (it need not dry in the Smokehouse), the refusals "Take the cured
  batch out first", "It can't take that much" and "No spots left", the sandbox's Salt cure time tooltip, the
  sandbox switch **Charque** renamed **Salting meat** (it turns all meat salting off; the option's key is
  unchanged), and the mod's description in the mod list.
- Fixed: **the long cure never finished on time** (since 0.4.14). The tub's bar ran at the short press's speed
  against the long cure's 21-day recipe, so 10 days of cuts took about 105 and a leg's 21 about 220, spoiling all
  the while. `F.onPressUpdate` now goes by the recipe's own time. A batch already in the tub finishes when its
  hours are up (at once, if they are).
- Fixed: a **Country Cure** batch in the tub had vanilla's popup, not the mod's (time left by its own hours, the warm
  season's spoilage).
- Internal: the popup's Spoilage line picks its text in `F.spoilWarning`.

## 0.4.18
- **Salt by the quarter weight** (2026-11-12, the fish and meat against salt check): packing takes 2 salt for
  each quarter weight of the packed piece, to the nearest quarter and never under 2, where it took 4 for each
  started half weight. Still about 15%. A Steak, Mutton Chop or Pork Chop takes 2 (was 4, a Beef's salt), a panfish
  under about 0.4 weight 2 (was 4), a 4 weight walleye 28 (was 32), a 4.5 weight one 32 (was 36); a Beef, Venison,
  Pork, a half-weight fish and a Leg of Pork (10) pay what they did (`F.SALT_STEP` 0.25, `F.SALT_PER_STEP` 2,
  `F.LEG_SALT_PER_STEP` 1, `F.saltFor` rounds).
- A crock moved between places is looked at through TP Core's `Transfer.before` (2026-11-12) instead of Fish & Meat's
  own wrap of `transferItem`. No change in play.
- Guide chapter 14, **At the Table** (2026-11-12): what each fish and meat stage is eaten as, its cook and burn
  times, the dishes it goes into and the recipe that moves it on. README title says 0.4.17.

## 0.4.17
- **The Salting Tub shows what is in it**: uncovered and waiting, a tub of meat no longer draws fish. Red cuts for
  beef, mutton and venison, pale pink for pork, and one Leg of Pork filling the tub, each lying in the salt
  (`Tiles.TUB_MEAT`, tiles 870-875, `W.tubKind`). Mixed cuts show the last put in, the top layer;
  a leg always shows, as it fills the tub. The board and stones still cover any
  tub that is pressing or done. Tests in `tests/test_world.lua`.

## 0.4.16
- **Ageing (6c)**: Dry-Cured meat and the Country Ham age after they have dried, on the item's own food clock: a cut
  **30 days**, a ham **90** (`F.AGE_CUT_DAYS`, `F.AGE_HAM_DAYS`, `F.agedness`; `modData.agedFrom`, older pieces
  count all their days). The name gains **"(Aged)"** and the tooltip counts the tenths. Aged, a cut's mood goes from
  -3 to **-8**, a Country Ham's from -10 (was -3) to **-40 with Boredom -20** (`F.applyAged`, by the share left).
- **Left hanging it ages in three quarters of the time** (`F.HANG_AGE_SHARE`, `F.ageHanging`): a finished stack still
  on the station where it dried. A piece taken down can't be hung again; a hanging one holds its stack.
- **Slices**: **Slice Dry-Cured Meat** and **Slice Hot-Smoked Meat** (slices of about hunger 14, as many as the cut
  holds: `F.sliceCount`, 2 to 6), **Carve Country Ham** (5 slices, the ham kept and lighter) and **Carve the Last of
  the Country Ham**: 15 slices from a leg in three carvings (`...Slices.lua`). Slices are named by the piece
  ("Suho Meso Slice", "Country Ham Slice (Aged)"), take its share of food and mood, keep half its days (60 / 90,
  90 / 180, 3 / 7), and go into vanilla's Ham Slice dishes. Vanilla's Ham Slices icon and model.
- **Hot smoking shows on the stack**: while a stoked run is cooking a stack its bar follows the cook when that is
  ahead of the drying (`F.cookShare`, `F.stackProgress`), and a small Hot Smoked icon sits in the slot's bottom
  left corner, where salt stacks show their salt. A run broken for over an hour drops both.
- Sandbox: **Dry-cured meat ageing time** (30) and **Country Ham ageing time** (90).
- Dev: `TPFM.mature(days)` ages carried dry-cured meat too; `TPFM.dryCured(n)`; `TPFM.food()` prints each carried
  piece's hunger, unhappiness, boredom, thirst, age and ageing. Tests: `tests/test_aged.lua`.

## 0.4.15
- **Dry curing without the Smokehouse**: Country Cured meat, pork too, hangs on a **Frame, Beam or Gantry under a
  roof, or a Frame or Beam in a room or a basement** (`F.meatRefusal`; not in the open) and dry cures there to air dried
  meat: Bresaola, Dry-Cured Mutton / Venison / Pork, Country Ham. Under a roof or indoors as the shed with the fire
  out; in a basement at a steady two thirds all year (`F.DRY_CURE_BASEMENT_RATE`: about 32 days a cut, 63 a leg); a
  stack that loses its roof waits. Smoke, hot smoking and the fire's warmth stay the Smokehouse's. Corned pork still
  hangs in the Smokehouse only.
- **The Hanging Beam can be built in a room or a basement** (`F.doorFree`; the Gantry and the Smokehouse stay
  outdoors: `Tiles.OUTDOOR`, with `Tiles.DOOR_KEPT` for the door rule).
- **No charque indoors**: in a room or a basement every meat stack dry cures; Corned meat there is under-salted, as
  in the Smokehouse. Charque is the open air's and the open roof's.
- **Spoilage strictness** now reaches 0.4.14's two rules: under-salted Corned meat (`F.UNDER_CURE_HOURS`) and the long
  cure's cold rule (`F.LONG_CURE_ROT_HOURS`) are scaled as the older ones (off: never; forgiving x2; harsh x0.5).
- Air dried meat's tooltip no longer speaks of smoke at all.
- **Guide pass**: chapter 3 is every road on one page (when to start, the cure, where, how long, yield, keeping, and what it costs in salt and fuel); dry curing has its own chapter 11; the Almanac has the year month by month, when each larder runs out and what the base game's garden and fishing do; new chapter 16, Three Larders: a house with one freezer, a farm, a river camp. Charque's indoor column is gone (no charque indoors).
- **The ham by the Smokehouse door** hangs on the door's other side, a third larger, a little past the shed's corner,
  with a slice taken off its round end (`paint_chamber_ham`; same tile numbers). Painted as vanilla's Ham icon is: a
  few tones in small patches, lit from one side, a pale mottled cut with a lighter middle, a dark line round it.

## 0.4.14
- **Dry curing in the Smokehouse** (phase 6b): meat hung in the shed never comes out Charque. It dries on its own
  need by the heaviest piece (`F.dryCureHours`: 3 weeks at full rate for a Beef, 6 for a Leg of Pork) in cool air
  (`F.dryCureRate`: full from 12 C, a quarter in frost, damp air as salt fish, no wind), with the fire's warmth as
  before (ledger totals `dryCure`, `dryCureBanked`, `dryCureStoked`). With its smoke it is
  **Suho Meso, Mutton Ham, Jerked Venison, Smoked Dry-Cured Pork**; with less, air dried: **Bresaola, Dry-Cured
  Mutton / Venison / Pork** (`modData.airDried`). Charque comes from the frames only. A stack hung before this
  keeps its share of progress on the new need.
- **Country Ham**: a Leg of Pork dries to a new item, `CountryHam` (**Smoked Country Ham** or **Country Ham**),
  keeping 180 / 365 days. A stack with a leg takes no hot cook: its stoked hours are smoke.
- **Hot smoked pork is vanilla's Ham** (`F.carryHam`), with the cut's own food and weight, so Slice Ham and ham
  dishes take it. Never a leg.
- **Under-salted**: Corned meat (the short cure) left to dry in the shed spoils by the shed's temperature
  (`F.underCureRate`: rotten in 4 weeks at 10 C, five times faster per 10 C more, the fire's lift counted) until a
  hot cook is done; Country Cured pieces in the same stack don't. Popup line "Under-salted".
- Popup in the shed: Method "Dry curing", the shed's temperature word, no Hot Smoke line for a stack with a leg.
- **A rotted stack comes down as what was hung** (`F.rottenStage`, `F.rottenOutputs`, `F.stackStations`): Corned Beef
  (Rotten), a pressed or gutted fish, not Bresaola, Salt Dried or Stockfish. In a mixed stack only the Corned pieces
  rot and the stack dries on (`modData.allUnder`). Air dried meat has its own tooltip, which doesn't speak of smoke at all.
- **Smoke by fixed hours** (`F.smokeHours`, `modData.smokeNeed`), for fish and meat alike: by the heaviest piece, fish
  24 hours (up to 1.1 weight) to 48 (2.2), meat 60 (a cut) to 120 (a leg). It was a third of the hours hung, which
  the slow dry cure turned into weeks of fire. Popup: *x of y h of smoke*.
- **"(Soaked)"** on rehydrated fish too (*Walleye Stockfish (Soaked)*, *Medium Walleye (Soaked, Salt Dried)*), as
  charque. Stockfish tooltips: "Keeps for about a year", "Matured stockfish".
- **The long cure wants the cold**: above a season mean of 10 C (`F.LONG_CURE_ABOVE`) a Country Cure batch spoils in
  step with the warmth, rotten after a leg's 21 days at 15 C (ledger `longCureSpoil`). Without it, the cool-air rule
  made summer the quickest season for ham. The short cure and fish keep the 20 C rule. `TPFM.longCure(hours)`.
- **Stockfish keeps 365 / 540 days** (was 730), so a winter's fish reaches the next winter but two don't stack.

## 0.4.13
- **Pork in the salt** (phase 6a): Pack Meat in Salt takes **Pork, Pork Chop and the new Leg of Pork**. Salt Cured
  pork hangs in the **Smokehouse only** (`F.porkRefusal`): a frame, Beam or Gantry refuses it, as pork fat goes rancid
  in sun and wind; so does **Country Cured** meat, whose long cure is for dry-cured meat, not charque. Icons and ground models for the three in every meat stage (`F.MEAT_CUTS` now seven).
- **Leg of Pork** (`TraditionalPreservationFishMeatPork.lua`): an adult pig gives some of its Pork as whole legs, 2.5
  weight. A wrapper on `ButcheringUtil.addAnimalPart` lets vanilla give the Pork, then makes 5 of those pieces into one
  leg with their food (`F.fillLeg`), at most half the Pork and 3 legs (`F.legsFrom`). No table row and no trim, so a
  pig's meat stays vanilla's at any size, meat ratio, skill or roadkill (a fixed row was simulated first and lost
  meat on a typical pig). About 1-2 on the Hook, usually none from the ground. Sandbox **Butchering gives legs of
  pork** (on). Icon and model: vanilla's Ham pulled to raw pink. A leg takes half fish's salt, 10 for 2.5 (~8%).
- **Two meat cures.** **Corn Salted Meat** (was Cure Salted Meat), the short one for charque and hot smoking, gives
  **Corned** meat. A leg gets the red border while Corn is selected, and Craft refuses if one is in the tub (`F.recipeRefusal` through Core's new `recipeRefusal` slot rule: in game, OnTest alone let vanilla start and leave the leg in its slot). **Country Cure Salted Meat** (new, `CountryCureMeat`), the long
  one for the Smokehouse's dry-cured meat and country ham: **10 days** for cuts, **21** with a leg
  (`F.LONG_CUT_HOURS`, `F.LONG_LEG_HOURS`), marks `longCure` (6b reads it). The warm-cure rule applies unchanged, so
  the long cure is a cold-season job.
- **Names** (display only; keys and indices kept, old items rename on load): the name says what it is now, a bracket
  only for a changing state. Meat: *Steak (Salt Packed)*, *Corned Steak*, *Country Cured Leg of Pork*, *Beef Charque*,
  *Beef Charque (Soaked)*, *Hot-Smoked Mutton*; cold smoked *Suho Meso* (beef), *Mutton Ham*, *Jerked Venison*,
  *Smoked Dry-Cured Pork*, *Smoked Country Ham* (air-dried names ready for 6b: Bresaola, Dry-Cured X, Country Ham).
  Vanilla's *(Prime Cut)* no longer follows a cut into the salt. Stockfish: *Walleye Stockfish*, *(Matured)*,
  *(Rehydrated)*, without size or Gutted; other fish names unchanged. Hang Salt Cured Meat to Dry is now *Hang
  Salted Meat to Dry*.
- **Wording:** fish and meat never sour. The tub popup reads *Spoiling (Warm cure)*; guide, README and Workshop say
  the flesh "starts to spoil by the spine (bone taint)"; a rinsed Salt Dried fish loses its "sharp tang".
- `TPFM.meat` gives the pork cuts and a leg; `TPFM.cured(n, long)`; tests `test_pork`, pork, leg, long-cure and name
  checks; `test_curing` reads the real EN texts. README's stoked lift corrected to 20 C.
- **Not released alone:** 6b (the Smokehouse routes: no charque from the shed, Ham, Country Ham) ships with it.

## 0.4.12
- **Cold smoke counts on days of 15 C or less** (was 20 C; `F.COLD_SMOKE_MAX`). With the banked smoulder now lifting
  the shed 15 C (0.4.11), a 20 C day read 35 C, past the 30 C where smoke cooks rather than cures (side-agent
  flag). Popup's "Too warm to count" says why; guide, README, Workshop and Balance follow.

## 0.4.11
- **The smoulder's warmth** (ROADMAP §7): with the Firebox burning, a Smokehouse stack dries as if the shed were
  **15 C warmer banked, 20 C warmer stoked** than outdoors, and the warmed air drier (its humidity halved per 10 C);
  charque keeps the outdoor wind. Before, a fire dried at the Covered rate, which gave nothing under about 13 C, so
  cold smoke's season barely gained. Salt fish at 2.3 C outdoors: 27 days Sheltered, about 16 banked, 12 stoked (if the
  fire burned every hour); banked helps from about -2 C, stoked from about -7 C (banked was +10 first, which gave
  nothing under about 3 C: step 80, +15 picked). Cold smoke's "cool day" test still reads the outdoor temperature.
- Ledger totals `smokeBanked`, `smokeStoked`, `charqueBanked`, `charqueStoked` (`F.liftedRates`, `F.BANKED_LIFT`,
  `F.STOKED_LIFT`); a save without them gets them at load. A stack's `burning` holds the fire's mode (Core's
  `Hearth.STOKED` / `BANKED`), and its popup rate follows it; a stack saved before starts its warm totals at its
  next look. `TPFM.weather()` and `TPFM.age()` show and feed the new totals.

## 0.4.10
- **Cold smoke** (ROADMAP §7, phase 5d): a salt stack in a Smokehouse joined to a Firebox comes out **Cold Smoked**
  when it has dried, if its smoke counter reached **a third of its clock hours** in the shed (smoked-dried fish,
  balyk, suho meso: a few hours of smoke a day over the drying). Smoke = banked hours plus stoked sessions that broke
  off before a hot cook. **Fire hours count only on days of 20 C or less** (the smoulder lifts the meat 10-15 C; over
  30 C it cooks rather than cures), stoked or banked: the ledger keeps all hours (`clock`) and the cool ones
  (`smokeCool`), and a stack reads the share since its last look; a stack's hot hours keep their cool part
  (`hotCool`) for when the session breaks off. Short of the third it ends as Salt Dried / Charque, as before.
- **Fire dries faster:** every hour of fire, stoked or banked, dries the stack at the Covered rate instead of
  Sheltered's: up to 1.5x for salt fish, only over about 13 C (below, both sit at the 27-day floor); charque gains
  only with wind.
- **Cold Smoked Fish** (keeps 120 / 180 days like Salt Dried, edible as it is, thirst 25, mood +3) and
  **Dry-Cured Meat** (no longer charque once smoked: "Dry-Cured Beef / Mutton / Venison (Cold Smoked)", named by the
  cut's animal, keeps 120 / 180 like Charque, edible, thirst 25, mood +3; phase 6 adds ripening). In soups, stews,
  rice, pasta, sandwiches and salads, with dish stand-ins. Icons: Salt Dried fish pulled to smoky bronze, cuts to
  burgundy (`build_meat_icons.py`).
- A finished stack in a Smokehouse waits at the end until the World has seen its shed since the load
  (`F.smokeStations`, not saved), so OnCreate can swap in the Cold Smoked outputs (`F.smokedOutputs`, which
  `F.hotSmokeOutputs` became).
- Stack popup: "Smoke: x h, y h needed so far (a third of the hours hung)", or "Too warm to count" over 20 C. Firebox Info's flue line
  says what burning and cold smoke do. Dev: `TPFM.bank(hours)`; `TPFM.smoke()` shows the smoke need and each
  stack's heaviest piece (`heaviest`).
- Drying Rate in a Smokehouse shows the Covered rate while the Firebox burns (`burning`, set by `F.smokeStep`).
- A new stack clears the shed and smoke fields (recipe data is pooled with its ModData), so a frame stack after a
  shed stack can't wait at the end or read an old baseline.

## 0.4.9
- **Hot smoking** (ROADMAP §7, phase 5c): a salt stack in the Smokehouse (Salt Cured fish, or charque from Salt Cured
  meat) joined to a Firebox counts the fire on two counters. **Hot** = the Firebox's stoked session now running
  (TP Core's `Hearth.logFire`: unbroken stoking, up to 1 h without it allowed). Reaching the stack's need finishes it at
  once as **Hot Smoked Fish / Hot Smoked Meat**: fish 4 h (to 1.1 weight) to 6 h (2.2 and up), meat 6 h (a 0.3 cut) to
  8 h (0.5), by the heaviest piece, 4 to 12 h. **Cold** (smoke) = banked hours plus stoked sessions that broke off; it is
  kept for Cold Smoked (5d) and changes nothing yet. Short of a cook, a stack dries on as Sheltered, as before.
  Hours come from Core's record, so a fire that burns out while you're away counts only to when its wood ran out.
- Hot Smoked Fish and Meat: cooked and ready to eat, 7 / 14 days, 0.78 of the cured weight (about 70% of raw), food
  carried from each piece (`F.carry`), a little salt (thirst 15), mood +5; in soups, stews, rice, pasta, sandwiches and
  salads, with dish stand-ins. Icons: Salt Dried fish pulled to gold, meat cuts to mahogany (`build_meat_icons.py`).
  The engine puts a drying station's outputs in its slots before OnCreate (`CraftLogicSystem.stop`), so OnCreate swaps
  them there (`F.hotSmokeOutputs`); a done cook is noted by the World each look (`F.hotStations`, not saved) and its
  OnUpdate ends the stack.
- **A ham hangs by the Smokehouse door** while finished stacks wait inside: tiles 868-869, on the door's
  tile (`F.hamSprite`).
- Stack popup: "Hot Smoke: x of y h stoked in a row" in a joined shed, "Smoke: x h" once there is any.
- Firebox Info's flue line now says what a joined Firebox does (stoked 4 to 8 hours in a row it hot smokes the
  stacks; banked or out they dry as Sheltered) instead of "Smoking comes in a later version".
- Docs: the player guide, README and Workshop text rewritten as one Fish & Meat manual, by process (cleaning table,
  Salting Tub, drying stations, Salt Dried fish, Charque, Stockfish, Smokehouse and hot smoking, fat, Potted Meat),
  checked against the code; history follows the Volga, Lofoten, the charqueadas, kavurma and the Kentucky smokehouse
  (no salt cod or biltong). README splits player notes from a code map for modders.
- Dev: `TPFM.smoke()` (the joined Firebox's record and each stack's counters), `TPFM.stoke(hours)` (adds stoked hours
  to the running session), `TPFM.curedFish(name, n)` (Salt Cured fish, default Walleye).

## 0.4.8
- **Connect the Firebox** (ROADMAP §7, phase 5b-2b): TP Core's Firebox joins the Smokehouse chamber beside it, with a
  **clay pipe** (2 Clay Pipe Segments + 1 Clay, Mason's Trowel kept) or a **stone trench** (3 Flat Stones + 2 Clay,
  a shovel or spade kept: `DIG_GRAVE`). No skill, a little Masonry XP. On the Firebox's menu (Core's
  `HearthUI.addFireboxMenu`) and the chamber's right-click. The Firebox may stand by either long side or the back gable,
  never at the door's end, and never with its own door towards the shed (`Hearth.flueSideTo`); one Firebox a shed, and
  not while its fire burns (lit or banked). **Disconnect** gives the pipe segments or flat stones back, the clay is lost.
  Neither the Firebox nor the shed picks up while joined. The link lives on the Firebox alone (Core's `flue`,
  `flueSide`). Firebox Info says where its flue goes. Smoke does nothing yet (5c, 5d): the shed still dries as Sheltered.
- Where the flue enters, on the long side the camera sees: a pipe stub in a collar of clay, or the trench's mouth under
  the sill (hidden by the Firebox itself). Tiles 860-867 (sheet 2 grows to 58 rows), `Tiles.CHAMBER_ENTRY`; the
  World draws them on either chamber tile. Rules in `TraditionalPreservationFishMeatSmokehouse.lua`, per chamber tile,
  so a bigger shed can reuse them. Dev: `TPFM.flueKit()`, `TPFM.smokehouse()`. Tests: `test_smokehouse.lua`.
- The Smokehouse's door needs its front tile free, and nothing of TP's (Firebox, Hearth, beams, another shed) goes up
  or is put down in front of it (Core's `Doors`: the door tiles registered in `...FishMeatSmokehouse.lua`;
  `F.notInRoom` asks `Doors.fits`; `UI.keepDoorsFree(Tiles.OUTDOOR)`). Found after step 75: a Firebox could be built
  at the shed's door end, and with its own door against the shed.

## 0.4.7
- **Smokehouse chamber** (ROADMAP §7, phase 5b-2a): a plank shed two tiles long under one roof slope, its door on the
  high end with a smoke slot under the eave (a two-tile entity like vanilla's Drying Rack: `SpriteGridPos`,
  `ForceSingleItem`). Carpentry 3, 14 Planks, 20 Nails, hammer kept. Holds 6 stacks of up to 15 weight of salt fish,
  Cold Dried fish or Salt Cured meat (charque), on the frame's recipes. Open air or under an open roof, not in a
  room. With no fire it is always **Sheltered** inside, wherever it stands (still air, no rain; cold fish doesn't
  dry), and nothing hangs in sight. Tiles 856-859 (sheet 2, 448-451), `Tiles.HANGERS.chamber` (`bases` for its two
  facings, `closed`). Connecting the Core Firebox comes in 5b-2b. Tests.
- The Smokehouse offers only Hang Salt Cured Fish and Hang Salt Cured Meat (recipe tag `Smokehouse`, added beside
  `DryingFrame`); cold drying needs moving air. A shed keeps its recipe tag in the save, so one built before gets
  the new tag when first seen.
- **Gutted fish is refused indoors**: the slot of any frame, beam or Smokehouse in a room, a basement or the
  Smokehouse turns away fish for cold drying, with the reason (`F.coldRefusal`). Stacks already hanging indoors
  stay, stopped as before.
- A stack's popup no longer shows Wetness indoors (a room or the Smokehouse): it is the rain on open frames.
- Charque's method reads **Salt drying (charque)**, in the popup and the recipe tooltip (was Sun drying).

## 0.4.6
- **Potted Meat keeps by place** (ROADMAP §7, phase 4c): a crock carries its own clock on a new weather ledger
  (global ModData `TraditionalPreservationFishMeatPotted`, kind `potted`) and catches up when next seen, at the place
  it was seen in last (Core's FluidAgeing record and place rules). A cellar's 15 C keeps the script's 60 / 90 days;
  a powered fridge or 4 C and colder 120 / 180; 14 / 21 at 25 C and up; a room goes by the season's mean (not the drying stations' season + 10, which made every pantry 25 C from spring to autumn); a powered freezer stops it.
  Vanilla's Food Spoilage setting scales it. **The first portion taken** costs a third of the days it has left,
  once (`tpfmOpened`). Looked at every hour on the player, when a loot window shows it and as it is moved. Sandbox
  **Potted Meat keeps by place** (on); off, a crock is plain food again. `TPFM.crocks()`, `TPFM.keep(days)`; tests.

## 0.4.5
- **Potted Meat** (ROADMAP §7, phase 4b): **Put Meat in Lard or Tallow** (an empty Pot, a block of Lard or Tallow,
  a cut, Salt) or **Put Meat in the Melted Fat** (a pot of 0.5 L Melted Lard or Tallow, as Pour Off leaves it) gives
  a **Pot of Meat in Fat**; **Add Meat to the Pot** puts in up to four cuts (a block covers four). Beef, Steak,
  Mutton Chop, Venison, and pork (Pork, Pork Chop): under fat and out of the sun, pork keeps. It cooks in two hours
  on any stove or fire and can burn (Scrape Out Burnt Fat). **Pack Potted Meat** into a vanilla Clay Jar, Glazed
  Clay Jar or Clay Pot: a **Crock of Potted Meat**, a portion a cut with a quarter block of fat each; vanilla's Eat
  takes portions, the name counts them, and the jar or pot comes back with the last bite. Keeps 60 / 90 days for
  now; keeping by place and the first opening's loss come in 4c. `TPFM.potted()`, `tests/test_potted.lua`, icons
  from `tools/build_meat_icons.py`.

## 0.4.4
- **"Salt Pressed" is now "Salt Cured"** for fish as for meat, and the tub recipes are **Cure Salted Fish** and
  **Cure Salted Meat** (were Press Salted ...); **Hang Salt Cured Fish to Dry**; sandbox "Salt cure time". Display
  names only: item and recipe IDs (`SaltPressedFish`, `PressSaltedFish`, `PressSaltedMeat`) and the `PressDays`
  option keep their names, so saves are unchanged.
- **Charque** (ROADMAP §7, phase 3c, the second half). **Hang Salt Cured Meat to Dry** on the Fish Drying Frame,
  the Fish Hanging Beam or the Fish Gantry: the summer sun dries it in 5 days at full rate. Full speed from 25 C up,
  nothing at 0 C or below, slowed by damp air; still air 0.65, a good breeze 1.2; under an open roof as in the open
  without the rain, indoors 0.65 with no wind. On an open frame it waits while wet, and each 6 hours of rain take
  back a tenth of what it had. No heat damage; only salt fish's hot and muggy season spoils it. Kentucky: about
  7-11 days in summer under a roof, weeks in spring and autumn, nearly nothing in winter (tools/charque_report.lua).
- **Charque** ("Steak (Charque)") keeps 120 / 180 days at about half the raw weight with 90% of the food, and
  **can't be eaten until soaked**: **Rehydrate Charque** (1 L of water) gives **Rehydrated Charque**, cookable, a
  little salty (thirst 10), spoils as fresh meat and goes into dishes.
- **Cold Dried fish can't be eaten until soaked either**, as Lofoten stockfish always is. Salt Dried fish stays
  edible as it is.
- **Salt Cured meat can be rinsed** (Rinse Off Salt, Rinse at Sink), as the charqueadas washed it before the sun:
  it keeps a tenth less long, and the rehydrated charque is less salty (thirst about 7).
- A stack is one kind: salted fish, gutted fish or meat ("A stack is one kind: ..."); one frame can hold all three.
- Sandbox: **Charque** (on/off: off, meat isn't packed in salt nor hung) and **Charque drying time** (5 days).
- Hanging charque: 140 new tiles at the end of the second sheet (vanilla's loin, steak and venison icons, cured red
  to deep brown); no station tile moved. Icons for Charque and Rehydrated Charque from build_meat_icons.py.
- Dev: `TPFM.cured(n)` (Salt Cured cuts), `TPFM.rain(hours)`; `TPFM.age` and `TPFM.weather` cover charque.

## 0.4.3
- **Meat in the Salting Tub** (ROADMAP §7, phase 3b, the first half of Charque). **Pack Meat in Salt** (in hand, no
  knife) takes a Beef, Steak, Mutton Chop or Venison as vanilla gives it, with fish's salt rule: 4 for each started
  half weight, about 15%, as charque. It gives **Salt Packed Meat**, named and drawn after its cut. Pork is left out
  on purpose: its fat goes rancid in the sun, so it waits for Country Ham.
- **Press Salted Meat** in the Salting Tub: 2 days for a 0.5 cut, less by weight (a Steak about 29 hours), never
  under a day; the heaviest cut sets the batch. A warm season costs keeping as it does for fish. It gives **Salt
  Cured Meat** ("Steak (Salt Cured)"), which keeps 7 / 14 days and cooks; the Drying Frame takes it in phase 3c.
- A tub salts fish or meat, never both at once ("A tub salts fish or meat, not both at once").
- Icons from `tools/build_meat_icons.py` (vanilla's cut icons, salted and cured). Dev: `TPFM.meat(n)`.

## 0.4.2
- **Fat renders in the Hearth's copper** (ROADMAP §7, 2d), many pieces at once. **Put Fat in the Copper** on the
  Hearth's menu puts in every carried piece of one kind (Pork Fat, or Beef Suet and Mutton Fat together), 0.25 L a
  piece, up to 240. Over a lit fire, an hour of steaming (85 C or more) melts it to **Melted Lard** or **Melted
  Tallow**, a fluid that Fill from Copper puts in any pot, bucket or jar. **Strain Lard** / **Strain Tallow** take
  half a litre for a block and a Cracklings: two pieces a block, as in a pot. The copper never burns fat.
- Raw fat stays in the copper, and goes to **Rancid Fat** there when its oldest piece would have rotted; only Empty
  the Copper takes that. Melted fat keeps.
- **Pots follow the same rule: raw fat is an item, over heat it becomes the fluid.** Pour Off Lard / Pour Off
  Tallow on a cooked pot now give the pot back holding 0.5 L of Melted Lard or Melted Tallow (hot), not the block;
  Strain gives the block and Cracklings, and its Cooking XP. A pot still burns if left on the heat (150 minutes).
- Straining needs a cloth or a Strainer, kept: a Cheese Cloth, Dish Towel, clean Rag, Sheet or Strainer.
- Hearth Info says how long the fat has to go and when it would go rancid. New fluids `RawPorkFat`, `RawSuet`,
  `MeltedLard`, `MeltedTallow`, `RancidFat`; `tests/test_fat_ui.lua`. Needs TP Core with `Hearth.turnsHot`.

## 0.4.1
- **Fat from butchering** (ROADMAP §7, phase 2). Pigs give **Pork Fat**, cattle **Beef Suet** and sheep **Mutton
  Fat**: one row each in vanilla's butchering parts tables, added when a world starts, so vanilla's own rules scale
  it (size, meat ratio, x2.8 on a Butchering Hook, x0.6 on the ground, skill, roadkill, an old carcass). A pig on
  the Hook gives 5 to 7 pieces, a cow 8 to 10, a sheep 2 to 4; on the ground 1 or 2. Young animals and deer give none.
- **Rendering** on any stove or fire, no station: Put Pork Fat in a Pot / Put Suet in a Pot (an empty Pot or Forged
  Pot, 2 raw pieces), cook 60 minutes, then Pour Off Lard (vanilla's Lard) or Pour Off Tallow, each with
  **Cracklings** and the pot back. Burnt fat gives nothing: Scrape Out Burnt Fat returns the pot.
- New items: Pork Fat, Beef Suet, Mutton Fat (raw, 2 / 4 days), **Tallow** (vanilla Lard's values and baking tag),
  Cracklings, and the four pots of fat. Icons from `tools/build_meat_icons.py`.
- Sandbox: **Butchering gives fat** (on).
- Console: `TPFM.fat(n)`, `TPFM.fatPot(state)`, `TPFM.fatRows()`.
- Internal: meat has its own files (`TraditionalPreservationFishMeatFat.lua`, `..._Meat.txt`, `tests/test_fat.lua`);
  fish code and goldens untouched. Butchering gives a little more Butchering XP, as each piece of fat counts as a part.

## 0.4.0
- **Renamed to Traditional Preservation (Fish & Meat)**, ahead of the meat routes (ROADMAP §7, phase 1). Mod ID
  `TraditionalPreservationFishMeat` (was `TraditionalPreservationFish`), debug console `TPFM` (was `TPF`), timed
  actions `TPFM...` (were `TPFish...`). The script module, so every item's and recipe's full type, the Lua table
  and files, translation keys, sandbox options (`SandboxVars.TraditionalPreservationFishMeat`), ledger and modData
  keys, the texture pack, tileset and sprite names all follow. Tiledef number 5129 stays. No change in play: tests
  and the season and storage goldens are the same, and the pack and tiles differ from 0.3.7 only by the name.
- **Not save compatible with 0.3.7** (nothing is released): a save made with the old ID loses its stations and
  cured fish. Enable the new mod in place of the old one.
- Entries below keep the names of their day (`TPF`, `TPFish...`, `TraditionalPreservationFish`).
- Internal: the guide is `1_FishMeat_Guide.md`; a stray tracked `tools/__pycache__` file is out of git.

## 0.3.7
- **Defaults and sandbox options** (ROADMAP §6, decisions 14 and 15). The season report confirms the defaults as
  they are: stockfish hung from late October to January dries outdoors in 50-55 days (32 at rate 1), February is
  a gamble (52-93), March rots; salt fish 15-34 days; maturing 60; press 1-2 days. No value changed.
- New sandbox options, defaults equal to the old fixed values: **Stockfish drying time** (`ColdDryDays`, 32),
  **Stockfish maturing time** (`MatureDays`, 60), **Salt press time** (`PressDays`, 2: a big fish's time; small
  fish keep half of it, `PRESS_MIN_HOURS`). Stockfish drying no longer follows Salt drying time at 8/3: a save
  that had changed DryDays gets 32 days for cold drying unless it sets the new option.

## 0.3.6
- **Stockfish Bale** (ROADMAP §6, pallet pitch C, 2026-11-11: capacity 10, weight reduction 30, new icon
  and new world model, tie and untie from the right-click menu). A container item (`StockfishBale`, the pallet's
  `F.BALE_TYPE`) that takes only stockfish (`AcceptItemFunction = TraditionalPreservationFish.acceptBale`, any
  Cold Dried fish, gutted or half). Fish in it keep their own clocks and ripen on a pallet as loose ones do.
- **Tie a Bale** in the fish's submenu on selected stockfish: up to 10 weight of them (`F.baleLoad`, the rest stay
  out) with one use of Twine, or a Rope if there's no Twine (`F.findCord`); greyed out with "Needs Twine or a Rope"
  otherwise. **Untie Bale** on a bale: its fish and the cord come back (a Twine of one use, or the Rope). The bale
  records the cord (`cord` in its modData; a bale without one gives back Twine) and weighs it (0.1 or 0.8, saved
  as a custom weight). Timed actions `TPFishTieBale` (120 ticks) and `TPFishUntieBale` (60).
- Art: `tools/build_model.py` (new) writes the bale's ground model `Models_X/StockfishBale.glb` (seven stockfish in
  three layers, heads and tails alternating, two twine bands; FuelBarrel's glb writer), its texture and its icon
  (three Cold Dried fish icons stacked under a band). In-game size: `scale` of `StockfishBaleGround`.
- Tests: bale rules and cords in `test_pallet.lua`, the menus in `test_ui.lua` (its event stand-in now chains
  handlers as the game does).

## 0.3.5
- **Stockfish Pallet** (ROADMAP §6, from a photo of stockfish maturing stacked on pallets): built from
  the build menu (hammer and saw kept, 3 planks, 6 nails, Carpentry 2). A 20 weight container from its tile
  (`container = stockfishpallet`, vanilla's Empty Pallet art copied, tile `_02_304`). Cold Dried fish on it, and in
  bales on it, ripens faster by place: a loft (a room on floor 1 or up) ×2 (`PALLET_LOFT`, 30 days), a ground-floor
  room ×1.5 (`PALLET_GROUND`, 40 days); covered, outdoors or a basement ×1, never worse than a shelf. Done once an
  in-game hour by moving each fish's `matureAge` back (`F.ripenOnPallet`), counting time the area was unloaded; the
  hour last counted is on the pallet (`palletHour`), so a moved pallet starts afresh. No new item key.
- The pallet shows a stack of stockfish (necks out, layers crossed) at a third, two thirds or full by the weight on
  it (`F.palletLevel`, tiles `_02_305`-`_307`), only while it holds nothing but stockfish (or bales of it).
- No window (like vanilla's crates): right-clicking it says what it does where it stands, *Stockfish Pallet: ripens
  stockfish x2 (loft)*, *x1.5 (ground-floor room)* or *no faster than a shelf here*, with the places on hover.
- Debug: `TPF.stockfish(n)` spawns unripe Cold Dried fish; `TPF.pallet()` reports the pallet near you.

## 0.3.4
- Optional rinse (ROADMAP §6, 2026-11-11, from an Astrakhan vobla account: the excess salt is soaked off after
  pressing). **Rinse Off Salt** is a craft recipe (`RinseSaltedFish`) on Salt Pressed fish: 0.15 L of clean
  carried water each (`RINSE_LITRES`), so it sits in the fish's recipe submenu and the Craft window can do many at
  once, and works in the dark (`CanBeDoneInDark`). It gives back the same fish (`onCreateRinsed`: food, weight, age and mod data carried) marked `rinsed`.
  Near a sink, bathtub, barrel or well of clean water (3 tiles, same floor, `F.findWaterSource`), **Rinse at Sink**
  joins the same submenu (a lone vanilla recipe option is turned into that submenu in place) and rinses every
  selected fish there (`TPFishRinse`, `RINSE_TICKS`), walking over first. Tainted water is refused both ways, as
  the soaking recipes already refuse it.
- A rinsed fish has two thirds of the thirst and keeps a tenth less long (`RINSED_THIRST`, `RINSED_KEEPING`: less
  salt, less protection); the Salt Dried fish made from it gets the same from its own script (thirst 30 to 20) and
  loses its sour note (unhappiness 3 to 0). Slices keep it; soaking doesn't apply it again. Names show it:
  *Medium Walleye (Salt Dried, Rinsed)*. Skipping the rinse changes nothing.

## 0.3.3
- Stockfish matures (ROADMAP §6, decisions 5 and 6): Cold Dried fish ripens over 60 days
  (`MATURE_DAYS`) on its own food clock, so a fridge slows it and a freezer stops it; no station, any container.
  `onCreateDried` stamps `matureAge` (item modData); a fish with no stamp (made before 0.3.3) counts as ripe.
- Rehydrate Fish on stockfish now runs `onCreateSoaked`: the soaked fish keeps `ripeness` and its unhappiness
  goes from +10 unripe through 0 halfway to -10 ripe (`MATURE_UNHAPPY`); a dish takes on its share, as vanilla does.
- Names: the stage goes in brackets after the fish, and vanilla's (Fresh) / (Stale) follows: *Gutted Medium Walleye
  (Salt Pressed)*, *Fish Half (Cold Dried, Unripe)*, *Medium Walleye (Rehydrated, Cold Dried, Ripe)*. Gutted and
  Half stay part of the fish's name; "Gutted" shows on every later stage of a fish that went through Gut Fish
  (packing takes the guts but leaves the fish whole), read from its headless icon (`F.wasGutted`), so old saves too. `F.stageName`, `F.rename`; slices carry the ripeness.
- Names and the stockfish's tooltip ("Maturing: 40 percent", one Tooltip key per tenth, `..._ColdDried_40`, as the game neither saves a per-item tooltip nor formats one) update
  every in-game hour for the player's own things and whenever the inventory windows show a container. Fish from
  older saves take the new names the same way.
- Debug: `TPF.mature(days)` ages the Cold Dried fish you carry.

## 0.3.2
- Realism (ROADMAP §6, decision 16): salt per fish doubled to 4 uses per started half weight
  (`SALT_PER_STEP`), about 15% of the fish's weight, the Volga figure (was about 7%).
- A warm cure: while the season averages above 20 C (`WARM_CURE_ABOVE`), a tub batch picks up spoilage at a quarter
  of raw fish's rate (`WARM_CURE_SHARE`), plus as much again per 10 degrees over (a day at 21 C ~14%, two at 25 C
  ~38%). The press's OnCreate is now `onCreatePressed`: each pressed fish carries `cureSpoiled` and is aged by it, and
  a frame stack starts from its fish's share by weight. The tub's popup shows it. Presses from before count from now.
- Hot sun: above 25 C (`HEAT_ABOVE`, live temperature), an open salt stack under half dried (`SALT_FRESH_UNTIL`)
  takes 0.05 per 24 h (`HEAT_DAMAGE`, `HEAT_DAMAGE_HOURS`, scaled by the Spoilage option) times how wet it still is,
  within `DAMAGE_CAP`. Salt stacks now go through `F.saltStep`. Popup: "Too hot in the sun" and "Spoiling (Hot sun)".
- Covered: a roof with no room round it (porch, open shed; Core `Weather.placeOf(station, true)`)
  is its own place. Salt fish dries at the open rate there, never rained on, in the shade; cold fish at 75%
  (`COVERED_COLD_RATE`), never rained on, no wet damage. A room (map or player-built: walled all round and fully
  roofed, the engine's `isInARoom`) is indoors as before: salt 65%, cold stops. New stack key `covered`; new ledger
  totals `covered`, `coldCovered`, `warmCure`, `heat` (older saves gain them at 0). Popup shows the Place.
- The Fish Hanging Beam and Gantry may stand under an open roof; only a room refuses them (`F.notInRoom`, Core
  `UI.notInRooms`; was outdoors only).
- Season report runs salt stacks through `saltStep` in all three places and adds covered cold drying and a 2-day
  press column; golden updated. README, guide, Workshop text and tooltips updated.

## 0.3.1
- Realism (ROADMAP §6, decision 9): the press follows the batch's heaviest fish, as the salt has to reach through the
  thickest one. 1 day if every fish is up to 1.1 weight (about 0.5 kg, `PRESS_SMALL_WEIGHT`), 2 days with any fish of
  2.2 weight (about 1 kg, `PRESS_BIG_WEIGHT`) or more, in between by weight (was 12 hours for any batch; Volga
  practice: about 2 days at most). The recipe's time is the longest press (`PRESS_HOURS` 48); a lighter batch's
  bar runs faster (new `pressHours` on the recipe data). A press already running from an older version keeps its
  12 hours. Tooltip, guide, README and Workshop text updated.
- The tub gets the mod's own hover popup on a running batch (Progress, Time Remaining from its own hours), as
  vanilla's counts down from the recipe's 2 days (step 58: a small batch read 1d 23h at the start).

## 0.3.0
- Realism (ROADMAP §6, cold-frame model): cold drying follows frost and wind. Full speed 0 to 5 C; 80% at -5 C
  and 60% below (`HARD_FROST`); wind from `ClimateManager:getWindIntensity()` gives 50% in still air up to 120% at
  0.25 (`WIND_GOOD`). Base cold drying is 32 days (`COLD_DRY_HOURS` 768, was 480), so a stack hung November to
  January takes 50 to 55 days (a 55-day gameplay compromise). Rain wets cold frames with their own wetness (`coldWetness`, snow doesn't), and drying waits
  until it is gone. Until a stack is 30% dried, hard frost (0.1 per 72 h) and lying wet above 0 C (0.05 per 48 h)
  add a little to its spoilage (at most a quarter, `DAMAGE_CAP`): about 10% of the keeping for a November hang,
  20% for January; rot from a warm season is scaled by how wet the stack still is. New ledger
  totals `hardFrost`, `coldWet`, `coldWetness`, `wind`; older ledgers and running stacks carry on.
- Popup: a Wind line on cold stacks (calm, light breeze, good drying wind), "Frost" and "Hard frost" for cold
  stacks, and the cold frame's own wetness. Debug: `TPF.frost(hours)`; `TPF.weather()` shows wind, cold
  wetness and the new totals; `TPF.dry()` clears both wetnesses.
- Season report: reads `tools/climate_wind.csv` (forecast wind x0.65 on dry days, x1.3 in rain), runs each cold
  stack through `F.coldStep`, and adds the keeping lost. 

## 0.2.9
- Realism (ROADMAP §6, Volga salting): Pack Fish in Salt refuses a whole or gutted fish over 4.5 weight (about 2 kg,
  `SALT_WHOLE_MAX`): gut and split it, then pack the halves. Smaller fish still go in whole with their heads, and
  gutting is unchanged. The tooltip, guide and README say so.
- Debug: `TPF.wind()` logs the live wind every 10 minutes, then prints it on dry and wet spells beside the
  forecast's wind, for setting the cold-drying wind curve. `tools/climate_wind.csv` holds a year of the game's
  forecast wind (one headless world per start month) for the season report.

## 0.2.8
- Docs (2026-11-11 pass against the code): the season tables in the README and guide match `tools/season_report.lua`
  again (a day's difference in seven months; April's 3% of cold batches finish in 33 days); Fish Head Stock's
  tooltip and the Workshop text say it starts as tasty as a plain stew (they said tastier, from before -20);
  fillets no longer "stack deep" (a salted fillet weighs as the food it holds); the Workshop's "one batch packs
  about 12 fish" and the DEVHELP salt check (`TPF.salt(5)`) follow salt by size. Tooltip text only: no change in play.
- Balance (series pass, F3): Pack Fish in Salt takes salt by the fish's size, 2 for each started half weight of the
  packed fish (at least 2; past the first 2 it must be carried), part-used salt first; the Salt mod's empties come
  back for what it uses up. A fillet vanilla cut counts as the food it holds (half its gutted fish) for salt and
  for its salted weight; fillets sliced from a cured fish weigh half of it, not 5%. Rehydrating carries the dried
  fish's freshness over as a share instead of starting fresh. The recipe's tooltip gives the rule.
- Balance (series pass, F1): Salting Tub takes 4 planks (was 2) and a saw, kept; Drying Frame takes 4 twine
  (was 2). Packing fish in salt gives Cooking 3 (was 10), gutting Butchering 10 (was 15), vanilla's figures.
  Fish Head Stock starts at vanilla stew's -20 unhappiness (was -30). Rehydrated fish fill as the fresh fish did
  (soaking gives back the 30% of hunger drying took); calories unchanged.
- Internal: new `tests/test_console.lua` loads the debug console (TPF) and calls every command, so one can't
  break unseen.
- Changed: the season's mean temperature and humidity (raw and salt spoilage) are the series' own, kept once by TP
  Core, so Fish added to a running save agrees with the other mods from its first day. Save keys unchanged.
- Internal: a station is told by a table lookup on its sprite's name (`F.stationIndex`), not a pattern match.
- Docs: README and Workshop text say the mod needs TP Core (they said "no other mods"); the comment on raw
  spoilage says what the code does (twice as fast at +10 C, three times at +20, not doubling each time).
- Internal: `test_ui.lua` stubs `instanceof`, which the core's slot rules now call.
- Now requires the **TP Core** mod (`TraditionalPreservationCore`), which loads first. The mod's own copy of the
  shared core (`TraditionalPreservationFish/Core/`: Weather, Station, UI) is gone; the code loads
  `TraditionalPreservationCore/...` instead. Same rules, same timers, same save keys, items and entities: existing
  saves carry on unchanged.
- Internal: the synced core copies name the core's new source path (TP Core is now a mod). Comment line only.
- Internal: the shared core's folder is now `TraditionalPreservationCore` (was `_tpcore`): comments and test
  paths only. No change in play.

## 0.2.7
- Internal: comments on the public functions that lacked one and on the evolved-recipe wraps, and an updated copy
  of the shared core (comments only). No change in play.

## 0.2.6
- Fixed: a Spoilage sandbox value outside the four choices stopped the mod's settings loading; it now counts as Normal.
- Internal: the fish-to-item food copying (cured stages, head, halves, fillets) is one local `copyFood`; the code uses
  a `local F` alias for `TraditionalPreservationFish`. Public names unchanged, no change in play.

## 0.2.5
- Internal: the tub's and frames' slot rules (adding, green border, refused-drop message) run on the shared core's
  `UI.slotRules`. Same rules, same messages.

## 0.2.4
- Internal: recipe times are set through the shared core (`Weather.setRecipeHours`). No change in play.

## 0.2.3
- Internal: tile numbers come from a `Tiles.lua` the art builder writes, instead of hand-kept numbers. Same art.

## 0.2.2
- Internal: the press timer uses the shared core's clock (`Weather.startClock/showClock`). Same timing.

## 0.2.1
- Fixed: a drying frame, beam or tub in a chunk that had just unloaded could still be updated, so its changes were
  lost or went to a stale chunk. Stations are now checked against the live cell.
- Changed: Time Remaining in the popup rounds up instead of down, as in the other TP mods.
- Fixed: the popup's Spoilage line could show the wrong text (a percentage was passed to the translator).
- Internal: runs on the shared Traditional Preservation core (weather, station tracking, popups).
