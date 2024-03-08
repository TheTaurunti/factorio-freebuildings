-- =============
-- Load Settings
-- =============

local RECIPE_TIME = 0.01
local ITEM_OUTPUT_AND_STACK_MULT = settings.startup["FreeBuildings-item-mult"].value

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

-- =================
-- Utility Functions
-- =================

local function get_recipe_result(recipe)
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
  local variants = {
    recipe,
    recipe.normal,
    recipe.expensive
  }

  for _, variant in ipairs(variants) do
    if (variant)
    then
      variant.ingredients = {}
      variant.energy_required = RECIPE_TIME
    end
  end

  -- This "crafting" category should allow most everything to make it, including the player.
  if (recipe.category)
  then
    recipe.category = "crafting"
  end
end

local function mult_recipe_output(recipe)
  local variants = {
    recipe,
    recipe.normal,
    recipe.expensive
  }

  for _, variant in ipairs(variants) do
    if (variant)
    then
      if (variant.results)
      then
        variant.results[1].amount = variant.results[1].amount * ITEM_OUTPUT_AND_STACK_MULT
      else
        variant.result_count = (variant.result_count or 1) * ITEM_OUTPUT_AND_STACK_MULT
      end
    end
  end
end

-- Non-local for mod compats
function Mult_Item_Stack_Size(item)
  item.stack_size = item.stack_size * ITEM_OUTPUT_AND_STACK_MULT
end

-- ==========
-- Mod Compat
-- ==========

Mult_Item_Stack_Size(data.raw["rail-planner"]["rail"])

require("compatibility.data-final-fixes.space-exploration")


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
      Mult_Item_Stack_Size(thing)
    end
  end
end


local recipes = data.raw["recipe"]
for _, recipe in pairs(recipes) do
  local result = get_recipe_result(recipe)

  if (Recipe_ForceList[recipe.name] or (result and items_to_be_free[result]))
  then
    make_recipe_free(recipe)
    mult_recipe_output(recipe)
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
