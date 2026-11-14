-- Traditional Preservation (Fish & Meat): stocks and broths, from fish heads, bones and chicken parts. Required by TraditionalPreservationFishMeat.lua, whose F it adds
-- to.
TraditionalPreservationFishMeat = TraditionalPreservationFishMeat or {}
local F = TraditionalPreservationFishMeat

-- The stock carries the head's calories, not its hunger (every stock reads hunger -5: a design decision of the
-- user's), and lists the head among its ingredients, as a vanilla stew lists what went in.
function F.onCreateHeadStock(craftRecipeData)
    local head
    local inputs = craftRecipeData:getAllInputItemsWithFlag("ItemCount")
    for i = 0, inputs:size() - 1 do
        if inputs:get(i):getFullType() == F.FISH_HEAD then head = inputs:get(i) end
    end
    local stock = craftRecipeData:getAllCreatedItems():get(0)
    if not head or not stock then return end
    F.setNutrients(stock, F.foodOf(head))
    stock:addExtraItem(head:getFullType())
end

-- What a bone gives a pot of Bone Broth. Two Animal Bones, one Large or six Small make a pot: about 80 kcal,
-- mostly gelatin, the Large's marrow more. Kept small on purpose: a stock is worth its taste (the stock pots'
-- unhappiness and boredom, a design decision of the user's), not its calories.
F.STOCK_BONES = {
    ["Base.AnimalBone"] = { calories = 40, proteins = 5, lipids = 1.5 },
    ["Base.LargeAnimalBone"] = { calories = 150, proteins = 10, lipids = 12 },
    ["Base.SmallAnimalBone"] = { calories = 80 / 6, proteins = 10 / 6, lipids = 0.5 },
}

-- What a Chicken Stock's parts give it: a foot its gelatin, a head a little (vanilla's heads have no food). Neither
-- adds hunger: every stock reads hunger -5, and the feet are spent in the pot (a design decision of the user's).
F.STOCK_FOOT = { calories = 35, proteins = 7, lipids = 0.8 }
F.STOCK_HEAD = { calories = 15, proteins = 2, lipids = 1 }

-- What a Chicken Stock's parts give it, by type. A Bone Broth and a Chicken Stock list one icon for the stock
-- (F.STOCK_ICONS), as Fish Head Stock lists its head; neither icon nor part can be added to a dish, so the naming
-- skips every one in the list. The Fish Head can be added, so its rule is its own.
F.STOCK_ICONS = {
    bone = "TraditionalPreservationFishMeat.BoneBrothIngredient",
    chicken = "TraditionalPreservationFishMeat.ChickenStockIngredient",
}
F.STOCK_PARTS = {
    [F.STOCK_ICONS.bone] = { calories = 0, proteins = 0, lipids = 0 },
    [F.STOCK_ICONS.chicken] = { calories = 0, proteins = 0, lipids = 0 },
    ["Base.ChickenFoot"] = F.STOCK_FOOT,
    ["Base.Chicken_Chick_Head"] = F.STOCK_HEAD,
    ["Base.Chicken_Hen_Brown_Head"] = F.STOCK_HEAD,
    ["Base.Chicken_Hen_White_Head"] = F.STOCK_HEAD,
    ["Base.Chicken_Rooster_Head_Brown"] = F.STOCK_HEAD,
    ["Base.Chicken_Rooster_Head_White"] = F.STOCK_HEAD,
    ["Base.Turkey_Hen_Head"] = F.STOCK_HEAD,
    ["Base.Turkey_Gobbler_Head"] = F.STOCK_HEAD,
    ["Base.Turkey_Poult_Head"] = F.STOCK_HEAD,
}

-- A bone gives its stock once. Other inputs pass.
function F.canBoil(item)
    if not F.STOCK_BONES[item:getFullType()] then return true end
    return not item:getModData().boiled
end

local function setStockFood(stock, calories, proteins, lipids)
    F.setNutrients(stock, { calories = calories, proteins = proteins, lipids = lipids, carbohydrates = 0 })
end

-- "Boiled Animal Bone": still good for every tool, no more stock.
local function markBoiled(bone)
    bone:getModData().boiled = true
    F.nameAs(bone, getText("IGUI_TraditionalPreservationFishMeat_BoiledBone", getItemNameFromFullType(bone:getFullType())))
end

-- The bones are kept: they come back boiled, clean for carving, and can't make stock again.
function F.onCreateBoneBroth(craftRecipeData)
    local stock = craftRecipeData:getAllCreatedItems():get(0)
    local bones = craftRecipeData:getAllInputItemsWithFlag("ItemCount")
    local calories, proteins, lipids = 0, 0, 0
    for i = 0, bones:size() - 1 do
        local bone = bones:get(i)
        local gives = F.STOCK_BONES[bone:getFullType()]
        if gives then
            calories = calories + gives.calories
            proteins = proteins + gives.proteins
            lipids = lipids + gives.lipids
            markBoiled(bone)
        end
    end
    if stock then
        setStockFood(stock, calories, proteins, lipids)
        stock:addExtraItem(F.STOCK_ICONS.bone)
    end
end

-- Smashing a boiled bone gives boiled pieces, or the same bone would make stock twice. Vanilla's Smash Bone
-- has no OnCreate; F.hookSmashBone gives it this one. Load renames the recipe to the name it is given and looks
-- up its translation by it, so it gets the recipe's own name ("SmashBone"), not the full one.
function F.onCreateSmashedBone(craftRecipeData)
    local boiled = false
    local inputs = craftRecipeData:getAllInputItems()
    for i = 0, inputs:size() - 1 do
        if inputs:get(i):getModData().boiled then boiled = true end
    end
    if not boiled then return end
    local pieces = craftRecipeData:getAllCreatedItems()
    for i = 0, pieces:size() - 1 do
        local piece = pieces:get(i)
        if F.STOCK_BONES[piece:getFullType()] then
            markBoiled(piece)
        end
    end
end

function F.hookSmashBone()
    local recipe = ScriptManager.instance:getCraftRecipe("Base.SmashBone")
    if recipe then recipe:Load(recipe:getName(), "{ OnCreate = TraditionalPreservationFishMeat.onCreateSmashedBone, }") end
end

Events.OnInitGlobalModData.Add(F.hookSmashBone)

-- Each part gives what F.STOCK_PARTS says; the stock lists one chicken icon.
function F.onCreateChickenStock(craftRecipeData)
    local stock = craftRecipeData:getAllCreatedItems():get(0)
    if not stock then return end
    local parts = craftRecipeData:getAllInputItemsWithFlag("ItemCount")
    local calories, proteins, lipids = 0, 0, 0
    for i = 0, parts:size() - 1 do
        local part = parts:get(i)
        local gives = F.STOCK_PARTS[part:getFullType()]
        if gives then
            calories = calories + gives.calories
            proteins = proteins + gives.proteins
            lipids = lipids + gives.lipids
        end
    end
    setStockFood(stock, calories, proteins, lipids)
    stock:addExtraItem(F.STOCK_ICONS.chicken)
end
