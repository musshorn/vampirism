function TrainUnit( keys )
  local building = keys.caster
  local unitToSpawn = keys.SpawnUnit
  local pID = building:GetMainControllingPlayer()
  local requestingFood = nil

  -- Parity with WC3 behaviour
  if UNIT_KV[pID][unitToSpawn].ConsumesFood ~= nil then
    requestingFood = UNIT_KV[pID][unitToSpawn].ConsumesFood
  else
      requestingFood = 0    
  end

  if UNIT_KV[pID][unitToSpawn].IsUnique ~= nil then
    local modelName = UNIT_KV[pID][unitToSpawn]['Model']
    local ents = Entities:FindAllByModel(modelName)
    for k, v in pairs(ents) do
      if v:GetUnitName() == unitToSpawn and v:GetMainControllingPlayer() == pID and v:IsAlive() then
        FireGameEvent( 'custom_error_show', { player_ID = building:GetMainControllingPlayer() , _error = "You cannot have more than one!" } )
        building:RemoveModifierByName(keys.AddToQueue)
      return
      end
    end
  end

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

-- A building upgrade is cancelled.
function Cancel( keys )
  local caster = keys.caster
  local pID = caster:GetMainControllingPlayer()

  if caster.workHandler ~= nil then
    Timers:RemoveTimer(caster.uniqueName)
    caster.workHandler:SetChanneling(false)
    caster.doingWork = false
    caster:RemoveModifierByName(caster.workHandler:GetName())
    caster.workHandler = nil
  end

  if caster.oldModel ~= nil then
    caster:Stop()
    caster:SetModel(caster.oldModel)
    
    for k,v in pairs(ABILITY_KV) do
      if v.UnitName ~= nil then
        if v.UnitName == caster:GetUnitName() then
          if v.MaxScale ~= nil then
            caster:SetModelScale(v.MaxScale)
          else
            print("[VAMP] There's problems in the KV's: model doesnt define a max scale")
          end
        end
      end
    end
    ChangeGold(pID, caster.refundGold)
    ChangeWood(pID, caster.refundLumber)
    caster.refundLumber = 0
    caster.refundGold = 0
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
  local canUpgrade = true

  -- This may be undefined for some upgrades
  if goldCost == nil then
    goldCost = 0
  end
  if lumberCost == nil then
    lumberCost = 0
  end

  -- Check if the player can upgrade
  if GOLD[pID] < goldCost then
    caster:Stop()
    FireGameEvent( 'custom_error_show', { player_ID = pID, _error = "You need more gold" } )
    canUpgrade = false
  end
  if WOOD[pID] < lumberCost then
    caster:Stop()
    FireGameEvent( 'custom_error_show', { player_ID = pID, _error = "You need more wood" } )
    canUpgrade = false
  end

  if TechTree:GetRequired(targetUnit, pID, caster:GetUnitName(), "building") == false then
    caster:Stop()
    FireGameEvent('custom_error_show', {player_ID = pID, _error = "You are missing tech for this!"})
    canUpgrade = false
  end

  if canUpgrade == true then
    -- Deduct resources
    ChangeGold(pID, -1 * goldCost)
    ChangeWood(pID, -1 * lumberCost)
  
    -- Change the model
    if caster.oldModel == nil then
      caster.oldModel = caster:GetModelName()
    end
    caster.refundGold = goldCost
    caster.refundLumber = lumberCost
    caster:SetModel(targetModel)
    
    if UNIT_KV[pID][targetUnit].ModelScale ~= nil then
      caster:SetModelScale(UNIT_KV[pID][targetUnit].ModelScale)
    end

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
end

function FinishUpgrade( keys )
  local caster = keys.caster
  local targetUnit = keys.TargetUnit
  local casterName = caster:GetUnitName()
  local pos = caster:GetAbsOrigin()
  local pID = caster:GetMainControllingPlayer()
  local team = caster:GetTeam()

  if UNIT_KV[pID][caster:GetUnitName()].RecievesLumber ~= nil then -- remove old unit from the lumber drops if applicable
    if UNIT_KV[pID][caster:GetUnitName()].RecievesLumber == "true" then
      for k,v in pairs(LUMBER_DROPS) do
        if v == caster then
          LUMBER_DROPS[k] = nil
        end
      end
    end
  end
  
  if UNIT_KV[pID][caster:GetUnitName()].SpawnsUnits == "true" then
    Timers:RemoveTimer(caster.spawnName)
  end

  local blockers = caster.blockers


  caster:Destroy()
  local unit = CreateUnitByName(targetUnit, pos, false, nil, nil, team)
  unit.blockers = blockers
  unit:SetControllableByPlayer(pID, true)
  if keys.Scale ~= nil then
    unit:SetModelScale(keys.Scale)
  end

  House1:Init(unit)

  if UNIT_KV[pID][targetUnit].ProvidesFood ~= nil then
    if UNIT_KV[pID][casterName].ProvidesFood ~= nil then
      TOTAL_FOOD[pID] = TOTAL_FOOD[pID] + UNIT_KV[pID][targetUnit].ProvidesFood - UNIT_KV[pID][casterName].ProvidesFood
    else
      TOTAL_FOOD[pID] = TOTAL_FOOD[pID] + UNIT_KV[pID][targetUnit].ProvidesFood
    end
    FireGameEvent("vamp_food_cap_changed", { player_ID = pID, food_cap = TOTAL_FOOD[pID]})
  end

  if UNIT_KV[pID][unit:GetUnitName()].RecievesLumber ~= nil then -- add new unit to the lumber drops if applicable
    if UNIT_KV[pID][unit:GetUnitName()].RecievesLumber == "true" then
      table.insert(LUMBER_DROPS, unit)
    end
  end

  if UNIT_KV[pID][unit:GetUnitName()].SpawnsUnits == "true" then
    unit:UnitSpawner()
  end

  function unit:RemoveBuilding( bForcedKill )
    -- Thanks based T__
    for k, v in pairs(unit.blockers) do
      DoEntFireByInstanceHandle(v, "Disable", "1", 0, nil, nil)
      DoEntFireByInstanceHandle(v, "Kill", "1", 1, nil, nil)
    end

    if bForcedKill then
      unit:ForceKill(bForcedKill)
    end
  end

  -- Give it tech modifiers.
  if UNIT_KV[pID][targetUnit]['TechModifiers'] ~= nil then
    local modTable = UNIT_KV[pID][targetUnit]['TechModifiers']
    print('building.lua')
    for k, v in pairs(modTable) do
      if TechTree:HasTech(pID, v) then
        local modName =  ABILITY_KV[v]['GiveModifier']
        unit:AddAbility(modName)
        local addedMod = unit:FindAbilityByName(modName)
        addedMod:SetLevel(1)
        --addedMod:OnUpgrade()
      end
    end
  end

  TechTree:AddTech(targetUnit, pID)
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
        if not target:HasModifier('modifier_freezing_breath_effect') then
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
        else
          FireGameEvent('custom_error_show', {player_ID = pID, _error = "Can't repair a frozen building!"})
          caster:Hold()
        end
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