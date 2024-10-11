function Add_Or_Increment_Table_Value(table, key, value)
	if (table[key] == nil) then table[key] = 0 end
	table[key] = table[key] + value
end

-- Ensures I don't have to deal with the shorthand form of item definitions
function Format_Item_Definition_Standard(input)
	local input_type = "item"
	if (input.type and input.type == "fluid")
	then
		input_type = "fluid"
	end

	return {
		type = input_type,
		name = (input.name or input[1]),
		amount = (input.amount or input[2])
	}
end

function Get_Recipe_Ingredients(recipe)
	local ret = {}

	local recipe_standard = recipe.normal or recipe
	for _, ingred in ipairs(recipe_standard.ingredients) do
		table.insert(ret, Format_Item_Definition_Standard(ingred))
	end

	return ret
end

function Get_Recipe_Result(recipe)
	local recipe_standard = recipe.normal or recipe
	local results = recipe_standard.results

	-- ensuring the return variable itself isn't nil
	local ret = {
		name = nil,
		amount = nil
	}

	if (not results)
	then
		return {
			name = recipe_standard.result,
			amount = recipe_standard.result_count or 1
		}
	end

	if (#results > 1) then return ret end

	if (results[1])
	then
		return {
			name = (results[1].name or results[1][1]),
			amount = (results[1].amount or results[1][2])
		}
	end

	return ret
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
end

function Mult_Recipe_Output(recipe)
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
				local first_result = variant.results[1]
				if (first_result.amount)
				then
					first_result.amount = first_result.amount * ITEM_OUTPUT_AND_STACK_MULT
				else
					first_result[1] = first_result[1] * ITEM_OUTPUT_AND_STACK_MULT
				end
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

function Remove_Recipe_Results(recipe)
	local recipe_standard = recipe.normal or recipe

	if (recipe_standard.results)
	then
		recipe_standard.results = {}
	else
		recipe_standard.result = nil
		recipe_standard.result_count = 0
	end
end

function Make_Recipe_Output_Coin(recipe)
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

function Breakdown_Recipe_Ingredients(recipe, breakdown_table)
	local working_ingredients = Get_Recipe_Ingredients(recipe)
	local any_breakdown_done = false

	local needs_processing = true
	while (needs_processing) do
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

		local recipe_standard = recipe.normal or recipe
		recipe_standard.ingredients = working_ingredients
	end
end
