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
-- NOTE: Mods which do recycling are handled after main script execution.
-- >> This field is available NOW so that mods which add 1 or 2 bad recipes can simply add them.
Bad_Recycle_Recipes = {}

Mult_Item_Stack_Size(data.raw["rail-planner"]["rail"])

require("compatibility.A_Total_Automization_Infantry_Edition")
require("compatibility.elevated-rails")
require("compatibility.IndustrialRevolution3")
require("compatibility.LunarLandings")
require("compatibility.space-age")
require("compatibility.space-exploration")


-- ============
-- Script Setup
-- ============
-- Gathering information on what items should be free to craft.

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

-- Considering modules, for the startup setting.
if (MAKE_MODULES_FREE)
then
	for _, module in pairs(data.raw["module"]) do
		items_to_be_free[module.name] = true
		Mult_Item_Stack_Size(module)
	end
end


-- =====================
-- Script Main Execution
-- =====================

-- Prep for breakdown feature
-- >> Bonus: Recycling-style mods can use this as a list of...
-- ... items to mark as "bad recycle recipes".
Item_Made_Free_Ingredients = {}

-- Checking all recipes
local recipes = data.raw["recipe"]
for _, recipe in pairs(recipes) do
	local result = Get_Recipe_Result(recipe)

	local result_name = nil
	local result_amount = nil
	if (result)
	then
		result_name = result.name
		result_amount = result.amount
	end

	if (Recipe_ForceList[recipe.name] or (result_name and items_to_be_free[result_name]))
	then
		if (result_name)
		then
			-- Good practice to not overwrite the recipe ingredients, even though...
			-- ... you are removing them altogether afterwards.
			local new_ingreds = {}

			-- key step to ensure accuracy of broken-down ingredients
			for _, ingredient in ipairs(recipe.ingredients) do
				-- This covers some edge cases, such as gleba crop seeds which get a...
				-- ... generated recipe from recycling which returns itself.
				if (ingredient.name ~= result_name)
				then
					local new_ingredient = table.deepcopy(ingredient)
					new_ingredient.amount = new_ingredient.amount / result_amount
					table.insert(new_ingreds, new_ingredient)
				end
			end

			if (#new_ingreds > 0)
			then
				Item_Made_Free_Ingredients[result_name] = new_ingreds
			end
		end

		Make_Recipe_Free(recipe)
		Mult_Recipe_Output(recipe)
	end
end


-- ======================================
-- Script Cleanup - Recycling & Breakdown
-- ======================================

require("compatibility.quality")

-- Prevent free resources from recipes that recycle stuff
for _, recipe in pairs(recipes) do
	if (Bad_Recycle_Recipes[recipe.name])
	then
		recipe.results = {}
	end
end

-- Now check for recipes that *use* buildings (which have been made free)
-- .. and decompose those buildings into the ingredients that they would've
-- .. normally needed! Doing this maintains the actual cost of things like research
-- .. but allows for free buildings nonetheless

-- To maintain actual costs for things like research, we break down...
-- ... things which were made "free"
-- To avoid errors, we need a secondary loop for this.

-- Needs to happen in a secondary loop, since the first
-- ... figures out what free things are made of
if (INGREDIENT_BREAKDOWN)
then
	for _, recipe in pairs(recipes) do
		Breakdown_Recipe_Ingredients(recipe, Item_Made_Free_Ingredients)
	end
end
