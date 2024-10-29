if mods["quality"] then
	local recipes = data.raw["recipe"]
	for _, recipe in pairs(recipes) do
		if (recipe.category == "recycling")
		then
			Bad_Recycle_Recipes[recipe.name] = true
		end
	end
end
