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
	-- excluding fluids because it adds complexity i don't want to think about right now
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

	if (not results) then return recipe_standard.result end
	if (#results > 1) then return nil end

	if (results[1])
	then
		return results[1].name or results[1][1]
	end

	return nil
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
