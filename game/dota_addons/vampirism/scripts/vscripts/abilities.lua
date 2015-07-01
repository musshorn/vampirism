function build( keys )
  local caster = keys.caster
  local player = keys.caster:GetPlayerOwner()
  local pID = keys.caster:GetMainControllingPlayer()
  local sourceItem = keys.ItemBuilding

  local buildName = ABILITY_KV[keys.ability:GetAbilityName()][UnitName]
  --print("CALLED THE BUILD")
  if buildName ~= nil then
    if TechTree:GetRequired(buildName, pID, "building") == false then
      return
    end
  end
  -- Check if player has enough resources here. If he doesn't they just return this function.

  local returnTable = BuildingHelper:AddBuilding(keys)

  keys:OnBuildingPosChosen(function(vPos)
    --print("OnBuildingPosChosen")
    -- in WC3 some build sound was played here.
    --BuildingHelper:AddBuilding(keys)
  end)

  keys:OnConstructionStarted(function(unit)
    if Debug_BH then
      print("Started construction of " .. unit:GetUnitName())
    end
    -- Unit is the building be built.
    -- Play construction sound
    -- FindClearSpace for the builder
    FindClearSpaceForUnit(keys.caster, keys.caster:GetAbsOrigin(), true)
    -- start the building with 0 mana.
    unit:AddNewModifier(silencer, nil, "modifier_silence", {duration=10000})
    unit:AddNewModifier(silencer, nil, "modifier_disarmed", {duration=10000})
    unit:SetMana(0)

    if sourceItem ~= nil then
      for i = 0, caster:GetNumItemsInInventory() do
        local item = caster:GetItemInSlot(i)
        if item ~= nil then
          if item:GetName() == sourceItem then
            caster:RemoveItem(item)
          end
        end
      end
    end
  end)

  keys:OnConstructionCompleted(function(unit)
    --print("Completed construction of " .. unit:GetUnitName())
    -- Play construction complete sound.  
    -- Give building its abilities
    -- add the mana
    unit:SetMana(unit:GetMaxMana())

    House1:Init(unit)

    -- Check if the building will create units, if so, give it a unit creation timer
    if UNIT_KV[pID][unit:GetUnitName()].SpawnsUnits == "true" then
      unit:UnitSpawner()
    end

    -- If the building provides food, how much? Also alert the UI for an update
    if UNIT_KV[pID][unit:GetUnitName()].ProvidesFood ~= nil then
      local food = tonumber(UNIT_KV[pID][unit:GetUnitName()].ProvidesFood)
      if (TOTAL_FOOD[pID] < 300) then
        TOTAL_FOOD[pID] = TOTAL_FOOD[pID] + food
        FireGameEvent("vamp_food_cap_changed", { player_ID = pID, food_cap = TOTAL_FOOD[pID]})
      end
    end

    if UNIT_KV[pID][unit:GetUnitName()].IsTech ~= nil then
      TechTree:AddTech(unit:GetUnitName(), unit:GetMainControllingPlayer())
    end

    if UNIT_KV[pID][unit:GetUnitName()].RecievesLumber ~= nil then
      if UNIT_KV[pID][unit:GetUnitName()].RecievesLumber == "true" then
        table.insert(LUMBER_DROPS, unit)
      end
    end

    if SLAYERS[pID] ~= nil then
      print("Player has a slayer", SLAYERS[pID].level, unit.unitName)
      if SLAYERS[pID].level ~= nil and unit.unitName == "slayer_tavern" then
        unit:FindAbilityByName("slayer_respawn"):SetLevel(SLAYERS[pID].level)
      end
    end

    if UNIT_KV[pID][unit:GetUnitName()].ShopType ~= nil then
      local shopEnt = Entities:FindByName(nil, "human_shop") -- entity name in hammer
      local newshop = SpawnEntityFromTableSynchronous('trigger_shop', {origin = unit:GetAbsOrigin(), shoptype = 1, model=shopEnt:GetModelName()}) -- shoptype is 0 for a "home" shop, 1 for a side shop and 2 for a secret shop
      unit.ShopEnt = newshop -- This needs to be removed if the shop is destroyed
    end

    --Remove Building Silence, Disarm
    if unit:HasModifier("modifier_silence") then
      unit:RemoveModifierByName("modifier_silence")
    end
    if unit:HasModifier("modifier_disarmed") then
      unit:RemoveModifierByName("modifier_disarmed")
    end

    --lazy fix for making graves work properly.
    if unit:GetUnitName() == 'massive_grave' then
      unit:AddAbility('grave_aura')
      unit:FindAbilityByName('grave_aura'):OnUpgrade()
    end
  end)

  -- These callbacks will only fire when the state between below half health/above half health changes.
  -- i.e. it won't unnecessarily fire multiple times.
  keys:OnBelowHalfHealth(function(unit)
    if Debug_BH then
      print(unit:GetUnitName() .. " is below half health.")
    end
  end)

  keys:OnAboveHalfHealth(function(unit)
    if Debug_BH then
      print(unit:GetUnitName() .. " is above half health.")
    end
  end)

  keys:OnConstructionFailed(function( unit )
    local lumberCost = unit.buildingTable.LumberCost
    local goldCost = unit.buildingTable.GoldCost

    if lumberCost ~= nil then
      WOOD[pID] = WOOD[pID] + lumberCost
      FireGameEvent('vamp_wood_changed', { player_ID = pID, wood_total = WOOD[pID]})
    end

    if goldCost ~= nil then
      GOLD[pID] = GOLD[pID] + goldCost
      FireGameEvent('vamp_gold_changed', { player_ID = pID, gold_total = GOLD[pID]})
    end

  end)

  --[[keys:OnCanceled(function()
    print(keys.ability:GetAbilityName() .. " was canceled.")
  end)]]

  -- Have a fire effect when the building goes below 50% health.
  -- It will turn off it building goes above 50% health again.
  keys:EnableFireEffect("modifier_jakiro_liquid_fire_burn")
end

function building_canceled( keys )
  BuildingHelper:CancelBuilding(keys)
end

function create_building_entity( keys )
  local caster = keys.caster
  local pID = keys.caster:GetMainControllingPlayer()
  local builderWork = keys.attacker.work
  local lumberCost = builderWork.buildingTable.LumberCost
  local goldCost = builderWork.buildingTable.GoldCost
  print(builderWork.name)

  local lumberOK = false
  local goldOK = false

  -- Check that the player can afford the building
  if lumberCost ~= nil then
    if lumberCost > WOOD[pID] then
      FireGameEvent( 'custom_error_show', { player_ID = caster:GetMainControllingPlayer() , _error = "You need more lumber" } )
    else
      lumberOK = true
    end
  else
    lumberOK = true
  end

  if goldCost ~= nil then
    if goldCost > GOLD[pID] then
      FireGameEvent( 'custom_error_show', { player_ID = caster:GetMainControllingPlayer() , _error = "You need more gold" } )
    else
      goldOK = true
    end
  else
    goldOK = true
  end

  -- If they cant afford it then stop building, otherwise resume
  if lumberOK == false or goldOK == false then
    return
  else
    if lumberCost == nil then
      lumberCost = 0
    end
    if goldCost == nil then
      goldCost = 0
    end

    -- Deduct resources and start constructing
    GOLD[pID] = GOLD[pID] - goldCost
    WOOD[pID] = WOOD[pID] - lumberCost
    FireGameEvent('vamp_wood_changed', { player_ID = pID, wood_total = WOOD[pID]})
    FireGameEvent('vamp_gold_changed', {player_ID = pID, gold_total = GOLD[pID]})

    BuildingHelper:InitializeBuildingEntity(keys)
  end
end

function harvest_t1(keys)
  local caster = keys.caster
  local point = keys.target:GetAbsOrigin()
  caster:MoveToPosition(point)
end

function human_blink(keys)
  --DeepPrintTable(keys)
  local caster = keys.caster
  local point = keys.target_points[1]
  local casterpos = caster:GetAbsOrigin()

  local diff = point - casterpos

  if diff:Length2D() > 1000 then
    point = casterpos + (point - casterpos):Normalized() * 1000
  end

  FindClearSpaceForUnit(caster, point, false)
end

function WorkerDet( keys )
  local caster = keys.caster
  local pID = caster:GetMainControllingPlayer()

  -- Tidy up the Timers
  if caster.moveTimer ~= nil then 
    Timers:RemoveTimer(caster.moveTimer)
  end

  -- Refund any food if any
  if UNIT_KV[pID][caster:GetUnitName()].ConsumesFood ~= nil then
    local returnfood = tonumber(UNIT_KV[pID][caster:GetUnitName()].ConsumesFood)
    CURRENT_FOOD[pID] = CURRENT_FOOD[pID] - returnfood
    FireGameEvent('vamp_food_changed', { player_ID = pID, food_total = CURRENT_FOOD[pID]})
  end

  Timers:CreateTimer(0.03, function ()
    caster:Destroy()
    return nil
  end)
end

function BuildingQ( keys )

  local ability = keys.ability
  local caster = keys.caster  
  local kvref = ABILITY_KV[keys.ability:GetAbilityName()]

  if caster.ProcessingBuilding ~= nil then
    -- caster is probably a builder, stop them
    player = PlayerResource:GetPlayer(caster:GetMainControllingPlayer())
    player.activeBuilder:ClearQueue()
    player.activeBuilding = nil
    player.activeBuilder:Stop()
    player.activeBuilder.ProcessingBuilding = false
  end
end

function SpawnGargoyle( keys )
  local caster = keys.caster
  local pID = caster:GetMainControllingPlayer()

  local unit = CreateUnitByName("human_gargoyle", caster:GetAbsOrigin(), false, nil, nil, caster:GetTeam())
  unit:SetControllableByPlayer(pID, true)

  caster:RemoveSelf()
end

function BecomeVampire( keys )
  local caster = keys.caster
  local pID = caster:GetMainControllingPlayer()

  PlayerResource:UpdateTeamSlot(pID, DOTA_TEAM_BAD_GUYS, true)
  
  local vamp = CreateUnitByName("npc_dota_hero_queenofpain", caster:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_BAD_GUYS)
  vamp:SetControllableByPlayer(pID, true)

  caster:RemoveSelf()
end

function VerifyAttacker( keys )
  local attacker = keys.attacker
  local target = keys.caster
  local attackerPID = attacker:GetMainControllingPlayer()
  local targetPID = target:GetMainControllingPlayer()

  -- if you're attacking a unit that's not yours but in your base then its ok, otherwise stop the attacker
  if attacker:GetUnitName() ~= "npc_dota_hero_night_stalker" then
    if attackerPID ~= targetPID then
      if  Bases.Owners[targetPID] ~= nil then
        if target.inBase ~=  Bases.Owners[targetPID].BaseID then
          attacker:Stop()
          FireGameEvent( 'custom_error_show', { player_ID = attackerPID , _error = "You may only destroy other players buildings in your own base!" } )
        end
      end
    end
  end
end

function worker_debug( keys )
  local worker = keys.caster
  print(worker.moving)
  print(worker.skipTicks)
  print(worker.inTriggerZone)
  print(worker.thinking)
end
