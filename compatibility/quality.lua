if mods["quality"] then
	local recipes = data.raw["recipe"]

	for item_name, _ in pairs(Item_Made_Free_Ingredients) do
		local recycling_name = item_name .. "-recycling"

		if (recipes[recycling_name])
		then
			Bad_Recycle_Recipes[recycling_name] = true
		end
	end
end
