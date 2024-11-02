function Add_Or_Increment_Table_Value(table, key, value)
	if (table[key] == nil) then table[key] = 0 end
	table[key] = table[key] + value
end

function Get_Recipe_Result(recipe)
	if (recipe.results and #recipe.results == 1)
	then
		return recipe.results[1]
	end
	return nil
end

function Make_Recipe_Free(recipe)
	recipe.ingredients = {}
	recipe.energy_required = RECIPE_TIME

	-- The "crafting" category allows the player to craft the item.
	-- >> As a side effect, all assemblers should also be able to craft the item.
	if (recipe.category)
	then
		recipe.category = "crafting"
	end

	-- For similar reasons, removing surface restrictions for crafting buildings is desired.
	if (recipe.surface_conditions)
	then
		recipe.surface_conditions = nil
	end
end

function Mult_Recipe_Output(recipe)
	if (#recipe.results < 1) then return end
	local first_result = recipe.results[1]
	first_result.amount = first_result.amount * ITEM_OUTPUT_AND_STACK_MULT
end

-- Non-local for mod compats
function Mult_Item_Stack_Size(item)
	item.stack_size = item.stack_size * ITEM_OUTPUT_AND_STACK_MULT
end

function Breakdown_Recipe_Ingredients(recipe, breakdown_table)
	local working_ingredients = recipe.ingredients
	if (not working_ingredients) then return end

	-- 100 iterations is more than enough to catch infinite loops (Yumako soil???)
	local max_iterations = 100
	local iterations_done = 0

	local any_breakdown_done = false

	local needs_processing = true
	while (needs_processing and iterations_done < max_iterations) do
		needs_processing = false

		local fluid_inputs = {}
		local item_inputs = {}

		for _, ingred in ipairs(working_ingredients) do
			if (ingred.type == "fluid")
			then
				fluid_inputs[ingred.name] = ingred.amount
			else
				local breakdown_ingreds = breakdown_table[ingred.name]
				if (breakdown_ingreds == nil)
				then
					-- item is not a building, add without changes
					Add_Or_Increment_Table_Value(item_inputs, ingred.name, ingred.amount)
				else
					-- item is a (free) building, time to decompose
					needs_processing = true
					any_breakdown_done = true
					for _, broken in ipairs(breakdown_ingreds) do
						-- Only adding items, so as to not
						-- .. overwhelm fluid input ports
						if (broken.type == "item")
						then
							Add_Or_Increment_Table_Value(item_inputs, broken.name, broken.amount * ingred.amount)
						end
					end
				end
			end
		end

		-- check if any ingredient breakdown occured
		-- .. if so, need to reconstruct ingredients for recipe
		if (needs_processing)
		then
			local new_ingredients = {}

			for fluid_name, fluid_amount in pairs(fluid_inputs) do
				table.insert(new_ingredients, { type = "fluid", name = fluid_name, amount = fluid_amount })
			end

			for item_name, item_amount in pairs(item_inputs) do
				table.insert(new_ingredients, { type = "item", name = item_name, amount = item_amount })
			end

			working_ingredients = new_ingredients
		end

		iterations_done = iterations_done + 1
	end

	if (iterations_done >= max_iterations)
	then
		local error_msg = "FreeBuildings error - Caught in loop breaking down recipe: " .. recipe.name
		log(error_msg)
		log(item_name)
		for _, ingredient in pairs(working_ingredients) do
			log("Type: " .. ingredient.type .. ", Name: " .. ingredient.name .. ", Amount: " .. ingredient.amount)
		end
		log("FreeBuildings: Breakdown Error. Please report this along with your factorio-current.log file." + 0)
	end

	if (any_breakdown_done)
	then
		for _, ingred in ipairs(working_ingredients) do
			ingred.amount = math.max(1, math.floor(ingred.amount + 0.5))
		end

		recipe.ingredients = working_ingredients
	end
end
