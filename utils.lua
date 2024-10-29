function Add_Or_Increment_Table_Value(table, key, value)
	if (table[key] == nil) then table[key] = 0 end
	table[key] = table[key] + value
end

function Get_Recipe_Result(recipe)
	if (not #recipe.results == 1) then return nil end
	return recipe.results[1]
end

function Make_Recipe_Free(recipe)
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
		log("FreeBuildings workable error - Max iterations reached breaking down recipe: " + recipe.name)
	end

	if (any_breakdown_done)
	then
		for _, ingred in ipairs(working_ingredients) do
			ingred.amount = math.floor(ingred.amount + 0.5)

			-- simpler to safeguard against this here, and helps
			-- ... to maintain appropriate level of recipe complexity
			if (ingred.amount == 0)
			then
				ingred.amount = 1
			end
		end

		recipe.ingredients = working_ingredients
	end
end
