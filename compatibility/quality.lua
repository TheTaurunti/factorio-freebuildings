if mods["quality"] then
  local recipes = data.raw["recipe"]

  for item_name, _ in pairs(Item_Made_Free_Ingredients) do
    local recycling_name = item_name .. "-recycling"

    -- For the Quality mod, we will make these things recycle into themselves.
    -- >> When buildings are free it is actually harder to get the higher tiers because...
    -- ... you are relying purely on the %/10/10/10.../10 chance on initial build to get the...
    -- ... tier you want. By letting them recycle into themselves, you get the chance to uptier...
    -- ... which lets the players utilize this mechanic still.
    if (recipes[recycling_name])
    then
      recipes[recycling_name].results = { { type = "item", name = item_name, amount = 1, probability = 0.25 } }
      recipes[recycling_name].energy_required = RECIPE_TIME
      Recipes_To_Skip_Breakdown[recycling_name] = true
    end
  end
end
