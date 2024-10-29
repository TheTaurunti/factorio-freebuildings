if mods["elevated-rails"] then
	Recipe_ForceList["rail-ramp"] = true
	Mult_Item_Stack_Size(data.raw["rail-planner"]["rail-ramp"])
end
