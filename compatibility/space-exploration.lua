if mods["space-exploration"]
then
	Item_Blacklist["se-cargo-rocket-cargo-pod"] = true
	Item_Blacklist["se-space-capsule"] = true

	Recipe_ForceList["se-space-rail"] = true
	Mult_Item_Stack_Size(data.raw["rail-planner"]["se-space-rail"])
	Recipe_ForceList["se-spaceship-console"] = true
	Recipe_ForceList["se-spaceship-floor"] = true

	-- Space Exploration defines a function "reverse_recipe()"
	-- >> Look for that when updating compatibility here.
	Recipes_To_Set_No_Output["se-recycle-small-electric-pole"] = true
	Recipes_To_Set_No_Output["se-recycle-small-iron-electric-pole"] = true
	Recipes_To_Set_No_Output["se-recycle-medium-electric-pole"] = true
	Recipes_To_Set_No_Output["se-recycle-big-electric-pole"] = true
	Recipes_To_Set_No_Output["se-recycle-substation"] = true
	Recipes_To_Set_No_Output["se-recycle-radar"] = true
end
