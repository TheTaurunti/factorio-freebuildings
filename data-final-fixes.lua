-- =============
-- Load Settings
-- =============

RECIPE_TIME = 0.01
ITEM_OUTPUT_AND_STACK_MULT = settings.startup["FreeBuildings-item-mult"].value
MAKE_MODULES_FREE = settings.startup["FreeBuildings-include-modules"].value
RECIPE_DECOMPOSITION = settings.startup["FreeBuildings-recipe-decomposition"].value

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

	if (Recipe_ForceList[recipe.name] or (result and items_to_be_free[result]))
	then
		if (result)
		then
			item_made_free_ingredients[result] = Get_Recipe_Ingredients(recipe)
		end
		Make_Recipe_Free(recipe)
		Mult_Recipe_Output(recipe)
	end

	-- Trying to prevent free resources from recipes that recycle stuff
	if (Coin_Recipes[recipe.name])
	then
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
					variant.results = { { type = "item", name = "coin", amount = 1 } }
				else
					variant.result = "coin"
					variant.result_count = 1
				end
			end
		end
	end
end

-- RECIPE_DECOMPOSITION // "Full", "Once", "None"
local remaining_decomp_iterations = 0
if (RECIPE_DECOMPOSITION == "Full") then
	-- should be more than enough
	remaining_decomp_iterations = 20
elseif (RECIPE_DECOMPOSITION == "Once") then
	remaining_decomp_iterations = 1
end

-- Now check for recipes that *use* buildings (which have been made free)
-- .. and decompose those buildings into the ingredients that they would've
-- .. normally needed! Doing this maintains the actual cost of things like research
-- .. but allows for free buildings nonetheless

-- Using a while loop for decomposition is wasteful in terms of computer resources
-- ... but is a very simple way to make sure things are decomposed properly
local any_recipe_needed_decomposition = true
while (any_recipe_needed_decomposition and remaining_decomp_iterations > 0) do
	for _, recipe in pairs(recipes) do
		local ingredients = Get_Recipe_Ingredients(recipe)

		local fluid_inputs = {}
		local item_inputs = {}

		local this_recipe_had_decomp = false
		for _, ingred in ipairs(ingredients) do
			if (ingred.type == "fluid")
			then
				fluid_inputs[ingred.name] = ingred.amount
			else
				local decomp_ingredients = item_made_free_ingredients[ingred.name]
				if (decomp_ingredients == nil)
				then
					-- item is not a building, add without changes
					Add_Or_Increment_Table_Value(item_inputs, ingred.name, ingred.amount)
				else
					-- item is a (free) building, time to decompose
					this_recipe_had_decomp = true
					any_recipe_needed_decomposition = true
					for _, decomp in ipairs(decomp_ingredients) do
						if (decomp.type == "item")
						then
							Add_Or_Increment_Table_Value(item_inputs, decomp.name, decomp.amount * ingred.amount)
						end
					end
				end
			end
		end

		if (this_recipe_had_decomp)
		then
			local new_ingredients = {}

			for fluid_name, fluid_amount in pairs(fluid_inputs) do
				table.insert(new_ingredients, { type = "fluid", name = fluid_name, amount = fluid_amount })
			end

			for item_name, item_amount in pairs(item_inputs) do
				table.insert(new_ingredients, { type = "item", name = item_name, amount = item_amount })
			end

			local recipe_standard = recipe.normal or recipe
			recipe_standard.ingredients = new_ingredients
		end
	end

	remaining_decomp_iterations = remaining_decomp_iterations - 1
end -- while
