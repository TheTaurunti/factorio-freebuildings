-- =============
-- Load Settings
-- =============

local RECIPE_TIME = 0.01

-- ===========================================
-- Blacklisting & Forcing Item/Recipe Freebies
-- ===========================================

Item_Blacklist = {
  ["land-mine"] = true,
  ["logistic-robot"] = true,
  ["construction-robot"] = true
}

Item_Forcelist = {
  ["artillery-wagon"] = true
}

Recipe_ForceList = {
  ["rail"] = true
}

-- Recipes to replace output with a (useless) coin item.
-- >> The point of this is to avoid free resources from things that recycle / break down buildings.
Coin_Recipes = {}


local blacklist_groups = {
  "solar-panel",
  "accumulator",

  "car",
  "spider-vehicle"
}
for _, group in ipairs(blacklist_groups) do
  for _, thing in pairs(data.raw[group]) do
    Item_Blacklist[thing.name] = true
  end
end


local whitelist_groups = {
  --"rail-planner", -- Sadly does not work
  "locomotive",
  "cargo-wagon",
  "fluid-wagon"
}
for _, group in ipairs(whitelist_groups) do
  for _, thing in pairs(data.raw[group]) do
    Item_Forcelist[thing.name] = true
  end
end

-- ==========
-- Mod Compat
-- ==========

require("compatibility.data-final-fixes.space-exploration")

-- =================
-- Utility Functions
-- =================

local function get_recipe_result(recipe)
  -- Could check each result, instead of just the first one.
  -- >> Seems unnecessary, as building tend to not have byproducts when constructed.

  local recipe_standard = recipe.normal or recipe
  local results = recipe_standard.results

  if (not results) then return recipe_standard.result end
  if (#results > 1) then return nil end

  if (results[1])
  then
    return results[1].name or results[1][1]
  end

  return nil
end

local function make_recipe_free(recipe)
  if (recipe.normal)
  then
    recipe.normal.ingredients = {}
    recipe.normal.energy_required = RECIPE_TIME
  end

  if (recipe.expensive)
  then
    recipe.expensive.ingredients = {}
    recipe.expensive.energy_required = RECIPE_TIME
  end

  recipe.ingredients = {}
  recipe.energy_required = RECIPE_TIME

  -- This "crafting" category should allow most everything to make it, including the player.
  if (recipe.category)
  then
    recipe.category = "crafting"
  end
end

-- ================
-- Script Execution
-- ================

local items_to_be_free = {}
local item_check_groups = {
  "item",
  "item-with-entity-data"
}


for _, group in ipairs(item_check_groups) do
  for _, thing in pairs(data.raw[group]) do
    if (
          Item_Forcelist[thing.name]
          or (thing.place_result and not Item_Blacklist[thing.name])
        )
    then
      items_to_be_free[thing.name] = true
    end
  end
end


local recipes = data.raw["recipe"]
for _, recipe in pairs(recipes) do
  local result = get_recipe_result(recipe)

  if (Recipe_ForceList[recipe.name] or (result and items_to_be_free[result]))
  then
    make_recipe_free(recipe)
  end

  -- Set coin result for naughty recipes (recycling things that are free)
  if (Coin_Recipes[recipe.name])
  then
    local recipe_standard = recipe.normal or recipe

    if (recipe_standard.results)
    then
      recipe_standard.results = nil
    end

    recipe.result = "coin"
    recipe.result_count = 1
  end
end
