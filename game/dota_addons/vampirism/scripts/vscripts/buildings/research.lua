function Research( keys )
  local caster = keys.caster
  local ability = keys.ability
  local lumberCost = ABILITY_KV[ability:GetAbilityName()].AbilityLumberCost
  local goldCost = ABILITY_KV[ability:GetAbilityName()].AbilityGoldCost
  local pID = caster:GetMainControllingPlayer()

  -- Not all research requires lumber or gold
  if lumberCost == nil then
    lumberCost = 0
  end
  if goldCost == nil then
    goldCost = 0
  end

  -- Check that the player can afford the upgrade, if not break out of the function
  if WOOD[pID] < lumberCost then
    caster:Stop()
    FireGameEvent( 'custom_error_show', { player_ID = pID, _error = "You need more wood" } )
    return
  end
  if PlayerResource:GetGold(pID) < goldCost then
    caster:Stop()
    FireGameEvent( 'custom_error_show', { player_ID = pID, _error = "You need more gold" } )
    return
  end

  -- Player is ok to commence research, deduct resources
  WOOD[pID] = WOOD[pID] - lumberCost
  FireGameEvent('vamp_wood_changed', { player_ID = pID, wood_total = WOOD[pID]})
  PlayerResource:ModifyGold(pID, -1 * goldCost, true, 9)

end

function ImproveLumber(keys)
  local caster = keys.caster
  local pID = caster:GetMainControllingPlayer()
  local level = keys.Level

  -- I think this research only applies to t1 workers so we don't need to search for any worker
  if level == 1 then
    UNIT_KV[pID]["worker_t1"].MaximumLumber = 10
  elseif level == 2 then
    UNIT_KV[pID]["worker_t1"].MaximumLumber = 15
  elseif level == 3 then
    UNIT_KV[pID]["worker_t1"].MaximumLumber = 20
  end
end