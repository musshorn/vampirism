function TrainUnit( keys )
  local caster = keys.caster
  table.insert(caster.queue, keys)
end

function Cancel( keys )
  local caster = keys.caster
  if (caster.workHandler ~= nil) then
    Timers:RemoveTimer(caster.uniqueName)
    caster.workHandler:SetChanneling(false)
    caster.doingWork = false
    caster:RemoveModifierByName(caster.workHandler:GetName())
    caster.workHandler = nil
  end
end

function SetRallyPoint( keys )
  local caster = keys.caster
  caster.rallyPoint = keys.target_points[1]
end

function Upgrade( keys )
  local caster = keys.caster
  local lumberCost = keys.LumberCost
  local goldCost = keys.GoldCost
  local targetUnit = keys.TargetUnit
  local pid = caster:GetMainControllingPlayer()

  if goldCost == nil then
    goldCost = 0
  end

  if lumberCost == nil then
    lumberCost = 0
  end
  
  if PlayerResource:GetGold(pid) < goldCost then
    caster:Stop()
    FireGameEvent( 'custom_error_show', { player_ID = pid, _error = "You need more gold" } )
  end

  if WOOD[pid] < lumberCost then
    caster:Stop()
    FireGameEvent( 'custom_error_show', { player_ID = pid, _error = "You need more wood" } )
  end
end