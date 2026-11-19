-- A food stand-in for the racks' tests: the getters and setters the curing code reads and writes, and an icon.
-- local newFood = dofile("tests/standins/food.lua")
return function(fullType, values, modelIndex)
    local food = { fullType = fullType, values = values or {}, modelIndex = modelIndex }
    for _, name in ipairs({ "Calories", "Proteins", "Lipids", "Carbohydrates", "BaseHunger", "HungChange", "ActualWeight" }) do
        food["get" .. name] = function(self) return self.values[name] or 0 end
        food["set" .. name] = function(self, value) self.values[name] = value end
    end
    function food:getFullType() return self.fullType end
    function food:getDisplayName() return self.name or "Fish" end
    function food:setTooltip() end
    function food:setUnhappyChange(value) self.unhappy = value end
    function food:setBoredomChange(value) self.boredom = value end
    function food:setCustomWeight(customWeight) self.customWeight = customWeight end
    function food:isCustomWeight() return self.customWeight == true end
    function food:getModData() self.modData = self.modData or {}; return self.modData end
    function food:setName(name) self.name = name end
    function food:setCustomName() end
    function food:getModelIndex() return self.modelIndex or -1 end
    function food:setModelIndex(modelIndex) self.modelIndex = modelIndex end
    function food:hasTag() return false end
    function food:setWeight(weight) self.weight = weight end
    function food:getOffAge() return 120 end
    function food:getOffAgeMax() return 180 end
    function food:setOffAge() end
    function food:setOffAgeMax() end
    function food:getThirstChange() return self.thirst or 0 end
    function food:setThirstChange(value) self.thirst = value end
    function food:setAge(age) self.age = age end
    function food:getAge() return self.age or 0 end
    function food:isRotten() return false end
    function food:isFrozen() return false end
    function food:isCooked() return self.cooked == true end
    function food:setCooked(cooked) self.cooked = cooked end
    function food:isBurnt() return false end
    function food:getTexture() return "icon:" .. self.fullType end
    return food
end
