function build( keys )
  local caster = keys.caster
  local player = keys.caster:GetPlayerOwner()
  local pID = keys.caster:GetMainControllingPlayer()
  local sourceItem = keys.ItemBuilding

  local buildName = ABILITY_KV[keys.ability:GetAbilityName()][UnitName]
  --print("CALLED THE BUILD")
  if buildName ~= nil then
    if TechTree:GetRequired(buildName, pID, caster:GetUnitName(), "building") ~= true then
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

    -- FindClearSpaceForUnit does not play nice with large hull units. Using this till a better solution is found.
    local nearVamps = FindUnitsInRadius(caster:GetTeam(), unit:GetAbsOrigin(), nil, 100, DOTA_TEAM_BADGUYS, DOTA_UNIT_TARGET_HERO, 0, FIND_CLOSEST, false)
    for k, v in pairs(nearVamps) do
      if v:GetUnitName() == "npc_dota_hero_night_stalker" then
        v:AddNewModifier(caster, nil, "modifier_item_forcestaff_active", {push_length = 200})
      end
    end
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
      if (TOTAL_FOOD[pID] < 250) then
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

    --adds invulnerable to vamp res center
    if unit:GetUnitName() == 'research_center_vampire' then
      unit:AddNewModifier(unit, nil, 'modifier_invulnerable', {})
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
    ChangeGold(pID, -1 * goldCost)
    ChangeWood(pID, -1 * lumberCost)

    BuildingHelper:InitializeBuildingEntity(keys)
  end
end

function harvest_t1(keys)
  local caster = keys.caster
  local point = keys.target:GetAbsOrigin()
  caster:MoveToPosition(point)
end

function HumanBlink(keys)
  --DeepPrintTable(keys)
  local caster = keys.caster
  local point = keys.target_points[1]
  local casterpos = caster:GetAbsOrigin()

  local diff = point - casterpos

  if diff:Length2D() > 2000 then
    point = casterpos + (point - casterpos):Normalized() * 2000
  end

  FindClearSpaceForUnit(caster, point, false)
end

function WorkerDet( keys )
  local caster = keys.caster
  local pID = caster:GetMainControllingPlayer()

  if caster:HasModifier('modifier_worker_stack') then
    local stackAbility = caster:FindAbilityByName('worker_stack') 
    local stacks = caster:GetModifierStackCount("modifier_worker_stack", stackAbility)

    if stacks > 1 then
      -- Refund any food if any
      if UNIT_KV[pID][caster:GetUnitName()].ConsumesFood ~= nil then
        local returnfood = tonumber(UNIT_KV[pID][caster:GetUnitName()].ConsumesFood)
        CURRENT_FOOD[pID] = CURRENT_FOOD[pID] - returnfood
        FireGameEvent('vamp_food_changed', { player_ID = pID, food_total = CURRENT_FOOD[pID]})
        caster:SetModifierStackCount('modifier_worker_stack', stackAbility, stacks - 1)
        return
      end
    else
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
  else
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
  local player = PlayerResource:GetPlayer(pID)

  if caster.onBlight ~= nil then
    if caster.onBlight == true then
      player:SetTeam(DOTA_TEAM_BADGUYS)
      PlayerResource:UpdateTeamSlot(pID, DOTA_TEAM_BADGUYS, true)

      local vamp = PlayerResource:ReplaceHeroWith(pID, "npc_dota_hero_life_stealer", 0, 0)
      vamp:SetControllableByPlayer(pID, true)
      vamp:SetAbsOrigin(caster:GetAbsOrigin())

      caster:RemoveSelf()
    else
      FireGameEvent( 'custom_error_show', { player_ID = pID , _error = "You must be on Blight to do that!" } )
    end
  else
    FireGameEvent( 'custom_error_show', { player_ID = pID , _error = "You must be on Blight to do that!" } )
  end
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

function BuildCancel( keys )
  local caster = keys.caster
  caster:Stop()
end

-- Human teleport ability.
function HumanTeleport( keys )
  local caster = keys.caster
  local playerID = caster:GetMainControllingPlayer()
  local target = keys.target
  local ability = keys.ability

  if not target:HasAbility('is_a_building') then
    ability:EndCooldown() 
    ability:RefundManaCost()
    caster:Stop()
    FireGameEvent('custom_error_show', {player_ID = playerID, _error = "May only teleport to buildings!"})
    return
  end

  local pStart = ParticleManager:CreateParticle("particles/items2_fx/teleport_start.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)

  local casterPos = caster:GetAbsOrigin()
  ParticleManager:SetParticleControl(pStart, 0, casterPos)
  ParticleManager:SetParticleControl(pStart, 1, Vector(0,0,255))
  ParticleManager:SetParticleControl(pStart, 2, casterPos)
  ParticleManager:SetParticleControl(pStart, 3, casterPos)
  ParticleManager:SetParticleControl(pStart, 4, casterPos)
  ParticleManager:SetParticleControl(pStart, 5, casterPos)
  ParticleManager:SetParticleControl(pStart, 6, casterPos)

  local pEnd = ParticleManager:CreateParticle("particles/items2_fx/teleport_end.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
  ParticleManager:SetParticleControl(pEnd, 0, target:GetAbsOrigin())
  ParticleManager:SetParticleControl(pEnd, 1, target:GetAbsOrigin())
  ParticleManager:SetParticleControl(pEnd, 2, Vector(0,0,255))
  Timers:CreateTimer(3, function ()
    ParticleManager:DestroyParticle(pStart, false)
    ParticleManager:DestroyParticle(pEnd, false)
  end)
end

function TeleportFinish( keys )
  local caster = keys.caster
  local target = keys.target

  FindClearSpaceForUnit(caster, target:GetAbsOrigin(), false)
end

function HolyAttack( keys )
  local caster = keys.caster
  local playerID = caster:GetMainControllingPlayer()
  local ability = keys.ability

  local avernals = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, 1300, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_BASIC, 0, FIND_CLOSEST, false)

  local count = 8
  for k, v in pairs(avernals) do
    if v:HasAbility('avernal_particles') and count > 0 then
      local attack_projectile = {
        Target = v,
        Source = caster,
        Ability = ability,  
        EffectName = "particles/items_fx/ethereal_blade.vpcf",
        vSpawnOrigin = caster:GetAbsOrigin(),
        bHasFrontalCone = false,
        bReplaceExisting = false,
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
        iUnitTargetType = DOTA_UNIT_TARGET_BASIC,
        bDeleteOnHit = true,
        iMoveSpeed = 1800,
        bProvidesVision = false,
        bDodgeable = false,
        iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_HITLOCATION
      }
      projectile = ProjectileManager:CreateTrackingProjectile(attack_projectile)
      local damage_table = {
        victim = v,
        attacker = caster,
        damage = caster:GetBaseDamageMax(),
        damage_type = DAMAGE_TYPE_PHYSICAL
      }
      ApplyDamage(damage_table)
      count = count - 1
    end
  end
end

TOWER_PARTICLES = {
  tower_flame = "particles/world_environmental_fx/fire_torch.vpcf"
}

-- Attach ambient particles to certain towers.
function AmbientParticles( keys )
  local tower = keys.caster
  local towerName = tower:GetUnitName()
  local towerPos = tower:GetAbsOrigin()
  local partcile = TOWER_PARTICLES[towerName]

  if particle == nil then
    for k, v in pairs(TOWER_PARTICLES) do
      print(k, v)
      print(string.find(k, towerName), string.find(towerName, k))
      if string.find(towerName, k) then
        print('fouind')
        particle = v
      end
    end
  end

  -- Its a flame tower
  if string.find(towerName, 'flame') then
    print('its fire')
    local ambient = ParticleManager:CreateParticle(particle, PATTACH_POINT_FOLLOW, tower)
    ParticleManager:SetParticleControlEnt(ambient, 0, tower, PATTACH_POINT_FOLLOW, "attach_attack1", towerPos, true)
  end
end