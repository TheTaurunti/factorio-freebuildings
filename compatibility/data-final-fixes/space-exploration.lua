if mods["space-exploration"]
then
  Item_Blacklist["se-cargo-rocket-cargo-pod"] = true
  Item_Blacklist["se-space-capsule"] = true

  Recipe_ForceList["se-space-rail"] = true

  -- Space Exploration defines a function "reverse_recipe()"
  -- >> Look for that when updating compatibility here.
  Coin_Recipes["recycle-small-electric-pole"] = true
  Coin_Recipes["recycle-small-iron-electric-pole"] = true
  Coin_Recipes["recycle-medium-electric-pole"] = true
  Coin_Recipes["recycle-big-electric-pole"] = true
  Coin_Recipes["recycle-substation"] = true
  Coin_Recipes["recycle-radar"] = true
end
