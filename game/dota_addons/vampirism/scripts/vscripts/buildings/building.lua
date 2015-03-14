function TrainUnit( keys )
  local building = keys.caster
  local unitToSpawn = keys.SpawnUnit  

  -- Parity with WC3 behaviour
  if UNIT_KV[unitToSpawn].ConsumesFood ~= nil then
    local requestingFood = UNIT_KV[unitToSpawn].ConsumesFood
    if TOTAL_FOOD[building:GetMainControllingPlayer()] >= CURRENT_FOOD[building:GetMainControllingPlayer() ] + requestingFood then
        table.insert(building.queue, keys)
    else
      FireGameEvent( 'custom_error_show', { player_ID = building:GetMainControllingPlayer() , _error = "Build more farms" } )
      building:RemoveModifierByName(building.workHandler:GetName())
      building.workHandler:SetChanneling(false)
      building.doingWork = false
    end
  end
end

function Cancel( keys )
  local caster = keys.caster
  local pid = caster:GetMainControllingPlayer()
  if (caster.workHandler ~= nil) then
    Timers:RemoveTimer(caster.uniqueName)
    caster.workHandler:SetChanneling(false)
    caster.doingWork = false
    caster:RemoveModifierByName(caster.workHandler:GetName())
    caster.workHandler = nil
  end

  if caster.oldModel ~= nil then
    caster:Stop()
    caster:SetModel(caster.oldModel)
    PlayerResource:ModifyGold(pid, caster.refundGold, true, 9)
    WOOD[pid] = WOOD[pid] + caster.refundLumber
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
  local targetModel = UNIT_KV[targetUnit].Model

  -- This may be undefined for some upgrades
  if goldCost == nil then
    goldCost = 0
  end
  if lumberCost == nil then
    lumberCost = 0
  end
  
  -- Check if the player can upgrade
  if PlayerResource:GetGold(pid) < goldCost then
    caster:Stop()
    FireGameEvent( 'custom_error_show', { player_ID = pid, _error = "You need more gold" } )
  end
  if WOOD[pid] < lumberCost then
    caster:Stop()
    FireGameEvent( 'custom_error_show', { player_ID = pid, _error = "You need more wood" } )
  end

  -- Deduct resources
  PlayerResource:ModifyGold(pid, -1 * goldCost, true, 9) -- idk what the 4th param is
  WOOD[pid] = WOOD[pid] - lumberCost

  -- Change the model
  if caster.oldModel == nil then
    caster.oldModel = caster:GetModelName()
  end
  caster.refundGold = goldCost
  caster.refundLumber = lumberCost
  caster:SetModel(targetModel)
end

function FinishUpgrade( keys )
  local caster = keys.caster
  local targetUnit = keys.TargetUnit
  local pos = caster:GetAbsOrigin()
  local player = caster:GetMainControllingPlayer()
  local team = caster:GetTeam()

  caster:Destroy()
  local unit = CreateUnitByName(targetUnit, pos, false, nil, nil, team)
  unit:SetControllableByPlayer(player, true)

end