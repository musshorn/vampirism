function Research( keys )
  print('research called XDDD')
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
    --used to temporarily hide research as it is being made, to ensure it is only done from
    --one research center at a time. 
    FireGameEvent('build_ui_hide', {player_ID = pID, ability_name = keys.ability:GetAbilityName(), builder = caster:GetUnitName(), tier = keys.level})
  PlayerResource:ModifyGold(pID, -1 * goldCost, true, 9)
end

-- Research was cancelled. Show the icon again, return cost to player.
function Cancelled(keys)
  local caster = keys.caster
  local ability = keys.ability
  local lumberCost = ABILITY_KV[ability:GetAbilityName()].AbilityLumberCost
  local goldCost = ABILITY_KV[ability:GetAbilityName()].AbilityGoldCost
  local playerID = caster:GetMainControllingPlayer()

  if goldCost == nil then
    goldCost = 0
  end
  if lumberCost == nil then
    lumberCost = 0
  end

  -- Return the cost of the research
  WOOD[playerID] = WOOD[playerID] + lumberCost
  FireGameEvent('vamp_wood_changed', {player_ID = playerID, wood_total = WOOD[playerID]})
  PlayerResource:ModifyGold(playerID, goldCost, true, 9)

  --Show the hidden icon in flash
  FireGameEvent('build_ui_show', {player_ID = playerID, ability_name = ability:GetAbilityName(), builder = caster:GetUnitName(), tier = keys.level})
end

-- Used to catch if cancelled by casting another ability
function Finished(keys)
  if keys.interrupted == 1 then
    Cancelled(keys)
  end
end

function ImproveLumber(keys)
  print('improve lumber')
  local ability = keys.ability
  local caster = keys.caster
  local pID = caster:GetMainControllingPlayer()
  local level = keys.Level

  -- This research only applies to t1 workers so we don't need to search for any worker
  if level == 1 then
    UNIT_KV[pID]["worker_t1"].MaximumLumber = 10
    -- On completed, send the "parent" key of the ability to flash, along with the tier of the next tech.
    FireGameEvent("build_ui_upgrade", {player_ID = pID, ability_name = 'research_improved_lumber_harvesting', builder = caster:GetUnitName(), tier = level})
  elseif level == 2 then
    UNIT_KV[pID]["worker_t1"].MaximumLumber = 15
    FireGameEvent("build_ui_upgrade", {player_ID = pID, ability_name = 'research_improved_lumber_harvesting', builder = caster:GetUnitName(), tier = level})
  elseif level == 3 then
    UNIT_KV[pID]["worker_t1"].MaximumLumber = 20
  end
end

function SharpenedHatchets(keys)
  local caster = keys.caster
  local pID = caster:GetMainControllingPlayer()
  
  -- This research only applies to t1 workers so we don't need to search for any worker
  UNIT_KV[pID]["worker_t1"].LumberPerChop = 2
end

function Rifles(keys)
  local caster = keys.caster
  local ability = keys.ability
  local pID = caster:GetMainControllingPlayer()
  local phandle = PlayerResource:GetPlayer(pID)
  local hero = phandle:GetAssignedHero()

  ability:ApplyDataDrivenModifier(caster, hero, "rifle_attack_range", nil)
end

function ImprovedWorkerMotivation(keys)
  local caster = keys.caster
  local pID = caster:GetMainControllingPlayer()
  
  -- Find all units with "MaximumLumber" not nil, these are all the harvesters
  for key, value in pairs(UNIT_KV[pID]) do
    if UNIT_KV[pID][key].MaximumLumber ~= nil then
      models = Entities:FindAllByModel(UNIT_KV[pID][key].Model)

      -- Increase the health of all the players harvesters
      for i = 1,table.getn(models) do
        local worker = models[i]
        if worker:GetMainControllingPlayer() == pID then
          worker:SetMaxHealth(worker:GetMaxHealth() + 300)
          worker:SetHealth(worker:GetHealth() + 300)
        end
      end

      -- Also increase the hp on any future units created
      UNIT_KV[pID][key].StatusHealth = UNIT_KV[pID][key].StatusHealth + 300
    end
  end
end

function GemQuality(keys)
  local caster = keys.caster
  local pID = caster:GetMainControllingPlayer()
  local level = keys.Level

  -- Find all units with "AffectedByGemUpgrades" not nil, these are all the walls
  for key, value in pairs(UNIT_KV[pID]) do
    if UNIT_KV[pID][key].AffectedByGemUpgrades ~= nil then
      models = Entities:FindAllByModel(UNIT_KV[pID][key].Model)

      -- Increase the health of all walls
      for i = 1,table.getn(models) do
        local wall = models[i]
        if wall:GetMainControllingPlayer() == pID then
          local increasedHP = 0
          if level == 1 then
            wall.baseMaxHP = wall:GetMaxHealth()
            increasedHP = wall:GetMaxHealth() * 1.2  - wall:GetHealth()
            UNIT_KV[pID][key].HealthModifier = 1.2
            FireGameEvent("build_ui_upgrade", {player_ID = pID, ability_name = 'research_improved_gem_quality', builder = caster:GetUnitName(), tier = level})
          end
          if level == 2 then
            increasedHP = wall.baseMaxHP * 1.4  - wall:GetHealth()
            UNIT_KV[pID][key].HealthModifier = 1.4
            FireGameEvent("build_ui_upgrade", {player_ID = pID, ability_name = 'research_improved_gem_quality', builder = caster:GetUnitName(), tier = level})
          end
          if level == 3 then
            increasedHP = wall.baseMaxHP * 1.6  - wall:GetHealth()
            UNIT_KV[pID][key].HealthModifier = 1.6
          end
          wall:SetMaxHealth(wall.baseMaxHP + increasedHP)
          wall:SetHealth(wall:GetHealth() + increasedHP)
        end
      end
    end
  end
end

function HumanDamage(keys)
  local caster = keys.caster
  local playerID = caster:GetMainControllingPlayer()
  local level = keys.Level
  local human = PlayerResource:GetPlayer(playerID):GetAssignedHero()

  if level == 1 then
    human:SetBaseDamageMin(human:GetBaseDamageMin() + 100)
    human:SetBaseDamageMax(human:GetBaseDamageMax() + 100)
    print(human:GetBaseAttackTime())
    human:SetBaseAttackTime(human:GetBaseAttackTime() + 0.1)
    FireGameEvent("build_ui_upgrade", {player_ID = pID, ability_name = 'upgrade_human_damage_1', builder = caster:GetUnitName(), tier = level}) 
  end
  if level == 2 then
    human:SetBaseDamageMin(human:GetBaseDamageMin() + 100)
    human:SetBaseDamageMax(human:GetBaseDamageMax() + 100)
    human:SetBaseAttackTime(human:GetBaseAttackTime() + 0.1)
    FireGameEvent("build_ui_upgrade", {player_ID = pID, ability_name = 'upgrade_human_damage_1', builder = caster:GetUnitName(), tier = level}) 
  end
  if level == 3 then
    human:SetBaseDamageMin(human:GetBaseDamageMin() + 100)
    human:SetBaseDamageMax(human:GetBaseDamageMax() + 100)
    human:SetBaseAttackTime(human:GetBaseAttackTime() + 0.1)
    FireGameEvent("build_ui_upgrade", {player_ID = pID, ability_name = 'upgrade_human_damage_1', builder = caster:GetUnitName(), tier = level}) 
  end
  if level == 4 then
    human:SetBaseDamageMin(human:GetBaseDamageMin() + 100)
    human:SetBaseDamageMax(human:GetBaseDamageMax() + 100)
    human:SetBaseAttackTime(human:GetBaseAttackTime() + 0.1)
    FireGameEvent("build_ui_upgrade", {player_ID = pID, ability_name = 'upgrade_human_damage_1', builder = caster:GetUnitName(), tier = level}) 
  end
  if level == 5 then
    human:SetBaseDamageMin(human:GetBaseDamageMin() + 100)
    human:SetBaseDamageMax(human:GetBaseDamageMax() + 100)
    human:SetBaseAttackTime(human:GetBaseAttackTime() + 0.1)
    FireGameEvent("build_ui_upgrade", {player_ID = pID, ability_name = 'upgrade_human_damage_1', builder = caster:GetUnitName(), tier = level}) 
  end
  if level == 6 then
    human:SetBaseDamageMin(human:GetBaseDamageMin() + 100)
    human:SetBaseDamageMax(human:GetBaseDamageMax() + 100)
    human:SetBaseAttackTime(human:GetBaseAttackTime() + 0.1)
    FireGameEvent("build_ui_upgrade", {player_ID = pID, ability_name = 'upgrade_human_damage_1', builder = caster:GetUnitName(), tier = level}) 
  end
  if level == 7 then
    human:SetBaseDamageMin(human:GetBaseDamageMin() + 100)
    human:SetBaseDamageMax(human:GetBaseDamageMax() + 100)
    human:SetBaseAttackTime(human:GetBaseAttackTime() + 0.1)
    FireGameEvent("build_ui_upgrade", {player_ID = pID, ability_name = 'upgrade_human_damage_1', builder = caster:GetUnitName(), tier = level}) 
  end
  if level == 8 then
    human:SetBaseDamageMin(human:GetBaseDamageMin() + 100)
    human:SetBaseDamageMax(human:GetBaseDamageMax() + 100)
    human:SetBaseAttackTime(human:GetBaseAttackTime() + 0.1)
    FireGameEvent("build_ui_upgrade", {player_ID = pID, ability_name = 'upgrade_human_damage_1', builder = caster:GetUnitName(), tier = level}) 
  end
  if level == 9 then
    human:SetBaseDamageMin(human:GetBaseDamageMin() + 100)
    human:SetBaseDamageMax(human:GetBaseDamageMax() + 100)
    human:SetBaseAttackTime(human:GetBaseAttackTime() + 0.1)
    FireGameEvent("build_ui_upgrade", {player_ID = pID, ability_name = 'upgrade_human_damage_1', builder = caster:GetUnitName(), tier = level}) 
  end
  if level == 10 then
    human:SetBaseDamageMin(human:GetBaseDamageMin() + 100)
    human:SetBaseDamageMax(human:GetBaseDamageMax() + 100)
    human:SetBaseAttackTime(human:GetBaseAttackTime() + 0.1)
    FireGameEvent("build_ui_upgrade", {player_ID = pID, ability_name = 'upgrade_human_damage_1', builder = caster:GetUnitName(), tier = level}) 
  end

end