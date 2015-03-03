function TrainUnit( keys )
  local caster = keys.caster
  table.insert(caster.queue, keys)
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
  caster:SetModel(keys.TargetModel)
end

function FinishUpgrade( keys )
  BuildingHelper:UpgradeBuildingEntity(keys)
end