data:extend({
	{
		type = "int-setting",
		name = "FreeBuildings-item-mult",
		setting_type = "startup",
		default_value = 1,
		minimum_value = 1
	},
	{
		type = "bool-setting",
		name = "FreeBuildings-include-modules",
		setting_type = "startup",
		default_value = false
	},
	{
		type = "string-setting",
		name = "FreeBuildings-recipe-decomposition",
		setting_type = "startup",
		default_value = "Full",
		allowed_values = { "Full", "Once", "None" }
	}
})
