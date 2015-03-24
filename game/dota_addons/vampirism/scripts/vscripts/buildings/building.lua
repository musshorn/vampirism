function TrainUnit( keys )
  local building = keys.caster
  local unitToSpawn = keys.SpawnUnit
  local pID = building:GetMainControllingPlayer()

  -- Parity with WC3 behaviour
  if UNIT_KV[pID][unitToSpawn].ConsumesFood ~= nil then
    local requestingFood = UNIT_KV[pID][unitToSpawn].ConsumesFood
    if TOTAL_FOOD[building:GetMainControllingPlayer()] >= CURRENT_FOOD[building:GetMainControllingPlayer() ] + requestingFood then
      if table.getn(building.queue) <= 7 then
        table.insert(building.queue, keys)
      else
        FireGameEvent( 'custom_error_show', { player_ID = building:GetMainControllingPlayer() , _error = "Too many units in queue" } )
        building:RemoveModifierByName(keys.AddToQueue)
      end
    else
      FireGameEvent( 'custom_error_show', { player_ID = building:GetMainControllingPlayer() , _error = "Build more farms" } )
      building:RemoveModifierByName(keys.AddToQueue)
      building.doingWork = false
    end
  end
end

function Cancel( keys )
  local caster = keys.caster
  local pID = caster:GetMainControllingPlayer()
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
    PlayerResource:ModifyGold(pID, caster.refundGold, true, 9)
    WOOD[pID] = WOOD[pID] + caster.refundLumber
    FireGameEvent('vamp_wood_changed', { player_ID = pID, wood_total = WOOD[pID]})
    caster:SetMaxHealth(caster.originalMaxHP)
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
  local pID = caster:GetMainControllingPlayer()
  local targetModel = UNIT_KV[pID][targetUnit].Model

  -- This may be undefined for some upgrades
  if goldCost == nil then
    goldCost = 0
  end
  if lumberCost == nil then
    lumberCost = 0
  end

  -- Check if the player can upgrade
  if PlayerResource:GetGold(pID) < goldCost then
    caster:Stop()
    FireGameEvent( 'custom_error_show', { player_ID = pID, _error = "You need more gold" } )
  end
  if WOOD[pID] < lumberCost then
    caster:Stop()
    FireGameEvent( 'custom_error_show', { player_ID = pID, _error = "You need more wood" } )
  end

  -- Deduct resources
  PlayerResource:ModifyGold(pID, -1 * goldCost, true, 9) -- idk what the 4th param is
  WOOD[pID] = WOOD[pID] - lumberCost
  FireGameEvent('vamp_wood_changed', { player_ID = pID, wood_total = WOOD[pID]})

  -- Change the model
  if caster.oldModel == nil then
    caster.oldModel = caster:GetModelName()
  end
  caster.refundGold = goldCost
  caster.refundLumber = lumberCost
  caster:SetModel(targetModel)

  -- If the unit has a HealthModifier (gem upgrades) then they gain the bonus of the targets HP straight away
  -- "Muh Parity" - Space Germ, 2015
  caster.originalMaxHP = caster:GetMaxHealth()
  if UNIT_KV[pID][caster:GetUnitName()].HealthModifier ~= nil then
    local maxHPOffset = UNIT_KV[pID][targetUnit].StatusHealth * UNIT_KV[pID][caster:GetUnitName()].HealthModifier - UNIT_KV[pID][targetUnit].StatusHealth
    caster.originalMaxHP = caster:GetMaxHealth()

    caster:SetMaxHealth(caster:GetMaxHealth() + maxHPOffset)
    caster:SetHealth(caster:GetHealth() + maxHPOffset)
  end
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
  if keys.Scale ~= nil then
    unit:SetModelScale(keys.Scale)
  end

end

-- Repairing is hard.
function RepairAutocast( keys )
  local caster = keys.caster
  local ability = keys.ability
  local target = keys.target

  if ability:GetAutoCastState() then
    if not ability:IsChanneling() then
      caster:CastAbilityOnTarget(target, ability, caster:GetMainControllingPlayer())
    end
  end
end

function Repair( keys )
  local caster = keys.caster
  local pID = caster:GetMainControllingPlayer()
  local target = keys.target
  local targetName = target:GetUnitName()
  local repairTimeRatio = keys.RepairTimeRatio
  local ability = keys.ability

  if not ability:IsChanneling() then
    if target:FindAbilityByName("is_a_building") ~= nil then
      if UNIT_KV[pID][targetName].RepairTime ~= nil then

        local maxHP = target:GetMaxHealth()
        local hpPerSec = maxHP / (UNIT_KV[pID][targetName].RepairTime * repairTimeRatio)
        local repairTickRate = 0.03  -- No idea what it actually is, Just going to adjust HP/Sec to suit
        local HPPerTick = repairTickRate * hpPerSec
        local smallHPPerTick = HPPerTick - math.floor(HPPerTick)
        HPPerTick = math.floor(HPPerTick)
        local smallHPAdjustment = 0

        local timerName = DoUniqueString("Repair")
        Timers:CreateTimer(timerName,{
          endtime = 0.03,
          callback = function ()
            if target:GetHealth() < target:GetMaxHealth() then
              target:SetHealth(target:GetHealth() + HPPerTick)
              smallHPAdjustment = smallHPAdjustment + smallHPPerTick
              if smallHPAdjustment > 1 then
                target:SetHealth(target:GetHealth() + 1)
                smallHPAdjustment = smallHPAdjustment - 1
              end
            else
              caster:Stop()
              return nil
            end
            return 0.03
          end
        })
        target.RepairTimer = timerName

      end
    end
  end
end

function RepairStop( keys )
  local caster = keys.caster
  local pID = caster:GetMainControllingPlayer()
  local target = keys.target
  
  Timers:RemoveTimer(target.RepairTimer)
  caster:Stop()
end