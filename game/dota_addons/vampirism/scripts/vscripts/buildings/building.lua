function TrainUnit( keys )
  local building = keys.caster
  local unitToSpawn = keys.SpawnUnit
  local pID = building:GetMainControllingPlayer()
  local requestingFood = nil
  local goldCost = keys.GoldCost
  local woodCost = keys.WoodCost
  local affordWood = true
  local affordGold = true

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

  -- Adjust food and resource needs based off worker stacking.
  if WORKER_STACKS[unitToSpawn] ~= nil then
    if goldCost ~= nil then goldCost = goldCost * WORKER_STACKS[unitToSpawn] end
    if woodCost ~= nil then woodCost = woodCost * WORKER_STACKS[unitToSpawn] end
    if requestingFood ~= nil then requestingFood = requestingFood * WORKER_STACKS[unitToSpawn] end
  end
  
  if goldCost ~= nil then
    if goldCost > GOLD[pID] then
      FireGameEvent('custom_error_show', {player_ID = pID, _error = 'Need more gold!'})
      building:RemoveModifierByName(keys.AddToQueue)
      affordGold = false
      return
    end
  else
    goldCost = 0
  end

  if woodCost ~= nil then
    if woodCost > WOOD[pID] then
      FireGameEvent('custom_error_show', {player_ID = pID, _error = 'Need more wood!'})
      building:RemoveModifierByName(keys.AddToQueue)
      affordWood = false
      return
    end
  else
    woodCost = 0
  end

  if TOTAL_FOOD[building:GetMainControllingPlayer()] >= CURRENT_FOOD[building:GetMainControllingPlayer() ] + requestingFood and affordWood and affordGold and requestingFood <= 250 then
    if #building.queue < 6 then
      table.insert(building.queue, keys)
      ChangeGold(pID, -1 * goldCost)
      ChangeWood(pID, -1 * woodCost)
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

-- A building upgrade is cancelled. Also cancels workers in queue?
function Cancel( keys )
  local caster = keys.caster
  local pID = caster:GetMainControllingPlayer()

  if caster.workHandler ~= nil then
    Timers:RemoveTimer(caster.uniqueName)
    caster.workHandler:SetChanneling(false)
    caster.doingWork = false
    caster:RemoveModifierByName(caster.workHandler:GetName())
    caster.workHandler = nil
    -- handle worker refunds... gj le snip man.
    local workerGold = caster.popped.GoldCost
    local workerWood = caster.popped.WoodCost

    if workerGold ~= nil then
      ChangeGold(pID, workerGold)
    end
    if workerWood ~= nil then
      ChangeWood(pID, workerWood)
    end
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

  local hasTech = TechTree:GetRequired(targetUnit, pID, caster:GetUnitName(), "building")
  if hasTech ~= true then
    caster:Stop()
    FireGameEvent('custom_error_show', {player_ID = pID, _error = "You are missing "..hasTech.."!"})
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
    --[[ "Muh Parity" - Space Germ, 2015
    caster.originalMaxHP = UNIT_KV[pID][caster:GetUnitName()].StatusHealth
    if UNIT_KV[pID][caster:GetUnitName()].HealthModifier ~= nil then
      local maxHPOffset = UNIT_KV[pID][targetUnit].StatusHealth * UNIT_KV[pID][caster:GetUnitName()].HealthModifier - UNIT_KV[pID][targetUnit].StatusHealth
      caster.originalMaxHP = caster:GetMaxHealth()
  
      caster:SetMaxHealth(caster:GetMaxHealth() + maxHPOffset)
      caster:SetHealth(caster:GetHealth() + maxHPOffset)
    end]]
  end
end

function FinishUpgrade( keys )
  local caster = keys.caster
  local targetUnit = keys.TargetUnit
  local casterName = caster:GetUnitName()
  local pos = caster:GetAbsOrigin()
  local pID = caster:GetMainControllingPlayer()
  local team = caster:GetTeam()

  caster:AddNewModifier(caster, nil, "modifier_disarmed", {duration=10000})

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
  unit:AddNewModifier(unit, nil, "modifier_disarmed", {duration=0.1})
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
    if TOTAL_FOOD[pID] > 250 then
      FireGameEvent("vamp_food_cap_changed", { player_ID = pID, food_cap = 250})
    end
    if TOTAL_FOOD[pID] < 20 then
      TOTAL_FOOD[pID] = 20
      FireGameEvent("vamp_food_cap_changed", { player_ID = pID, food_cap = 20})
    end
  end

  if UNIT_KV[pID][targetUnit].AnnounceUnit == 1 and UNIQUE_TABLE[targetUnit] == nil then
    local playerName = PlayerResource:GetPlayerName(unit:GetMainControllingPlayer())
    GameRules:SendCustomMessage(ColorIt(playerName, IDToColour(pID))..' has completed a '..UNIT_NAMES[targetUnit]..'!', 0, 1)
    UNIQUE_TABLE[targetUnit] = pID
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

-- Scans for damaged buildings
function RepairAutocastScan( keys )
  local ability = keys.ability
  local caster = keys.caster
  local casterTeam = caster:GetTeam()
  local playerID = caster:GetMainControllingPlayer()

  if ability:GetAutoCastState() then
    local nearBuildings = FindUnitsInRadius(casterTeam, caster:GetAbsOrigin(), nil, 900, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_BASIC, 0, FIND_CLOSEST, false)
    if caster:IsChanneling() == false then
      local repairAbility = caster:FindAbilityByName('human_repair')
      for k,v in pairs(nearBuildings) do
        if v:HasAbility('is_a_building') and v:GetHealthDeficit() > 0 then
          caster:CastAbilityOnTarget(v, repairAbility, playerID)
          return
        end
      end
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