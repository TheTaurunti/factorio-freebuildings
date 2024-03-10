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
  Coin_Recipes["se-recycle-small-electric-pole"] = true
  Coin_Recipes["se-recycle-small-iron-electric-pole"] = true
  Coin_Recipes["se-recycle-medium-electric-pole"] = true
  Coin_Recipes["se-recycle-big-electric-pole"] = true
  Coin_Recipes["se-recycle-substation"] = true
  Coin_Recipes["se-recycle-radar"] = true
end
