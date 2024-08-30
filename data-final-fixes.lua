-- =============
-- Load Settings
-- =============

RECIPE_TIME = 0.01
ITEM_OUTPUT_AND_STACK_MULT = settings.startup["FreeBuildings-item-mult"].value
MAKE_MODULES_FREE = settings.startup["FreeBuildings-include-modules"].value
INGREDIENT_BREAKDOWN = settings.startup["FreeBuildings-recipe-breakdown"].value

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

-- Recipes whose output should be removed, to prevent the creation of free resources
-- > Might be obsolete, with the breakdown feature
Bad_Recycle_Recipes = {}


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

require("utils")

-- ==========
-- Mod Compat
-- ==========

Mult_Item_Stack_Size(data.raw["rail-planner"]["rail"])

require("compatibility.space-exploration")
require("compatibility.IndustrialRevolution3")


-- ================
-- Script Execution
-- ================

local item_check_groups = {
	"item",
	"item-with-entity-data"
}

-- Collecting names of items which need to be free

local items_to_be_free = {}

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

if (MAKE_MODULES_FREE)
then
	for _, module in pairs(data.raw["module"]) do
		items_to_be_free[module.name] = true
		Mult_Item_Stack_Size(module)
	end
end

-- Figure out which recipes take buildings as ingredients, and decompose those into their
-- ... component parts (so that things like green/purple science are not made free)
local item_made_free_ingredients = {}

local recipes = data.raw["recipe"]
for _, recipe in pairs(recipes) do
	local result = Get_Recipe_Result(recipe)

	local result_name = result.name
	local result_amount = result.amount

	if (Recipe_ForceList[recipe.name] or (result_name and items_to_be_free[result_name]))
	then
		if (result_name)
		then
			local ingreds = Get_Recipe_Ingredients(recipe)

			-- key step to ensure accuracy of broken-down ingredients
			for _, ingredient in ipairs(ingreds) do
				ingredient.amount = ingredient.amount / result_amount
			end

			item_made_free_ingredients[result_name] = ingreds
		end

		Make_Recipe_Free(recipe)
		Mult_Recipe_Output(recipe)
	end

	-- Prevent free resources from recipes that recycle stuff
	if (Bad_Recycle_Recipes[recipe.name])
	then
		Remove_Recipe_Results(recipe)
	end
end


-- Now check for recipes that *use* buildings (which have been made free)
-- .. and decompose those buildings into the ingredients that they would've
-- .. normally needed! Doing this maintains the actual cost of things like research
-- .. but allows for free buildings nonetheless

-- Needs to happen in a secondary loop, since the first
-- ... figures out what free things are made of
if (INGREDIENT_BREAKDOWN)
then
	for _, recipe in pairs(recipes) do
		Breakdown_Recipe_Ingredients(recipe, item_made_free_ingredients)
	end
end
