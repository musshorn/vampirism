function Research( keys )
  local caster = keys.caster
  local ability = keys.ability
  local lumberCost = ABILITY_KV[ability:GetAbilityName()].LumberCost
  local goldCost = ABILITY_KV[ability:GetAbilityName()].GoldCost
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
    print(goldCost)
    caster:Stop()
    FireGameEvent( 'custom_error_show', { player_ID = pID, _error = "You need more gold" } )
    return
  end

  -- Player is ok to commence research, deduct resources
  WOOD[pID] = WOOD[pID] - lumberCost
  PlayerResource:ModifyGold(pID, -1 * goldCost, true, 9)
  FireGameEvent('vamp_wood_changed', { player_ID = pID, wood_total = WOOD[pID]})
  FireGameEvent('vamp_gold_changed', { player_ID = pID, gold_total = PlayerResource:GetGold(pID)})
    --used to temporarily hide research as it is being made, to ensure it is only done from
    --one research center at a time. 
  FireGameEvent('build_ui_hide', {player_ID = pID, ability_name = keys.ability:GetAbilityName(), builder = caster:GetUnitName(), tier = keys.level})
  print('resarch gold')
  print(PlayerResource:GetGold(pID))
end

-- Research was cancelled. Show the icon again, return cost to player.
function Cancelled(keys)
  local caster = keys.caster
  local ability = keys.ability
  local lumberCost = ABILITY_KV[ability:GetAbilityName()].LumberCost
  local goldCost = ABILITY_KV[ability:GetAbilityName()].GoldCost
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
  print(PlayerResource:GetGold(playerID))
  FireGameEvent('vamp_gold_changed', { player_ID = playerID, gold_total = PlayerResource:GetGold(playerID)})

  --Show the hidden icon in flash
  FireGameEvent('build_ui_show', {player_ID = playerID, ability_name = ability:GetAbilityName(), builder = caster:GetUnitName(), tier = keys.level})
end

-- Used to catch if cancelled by casting another ability
function Finished(keys)
  if keys.interrupted == 1 then
    Cancelled(keys)
  end
end

--Research center upgrades

function ImproveLumber(keys)
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

  if ABILITY_HOLDERS[caster:GetUnitName()] ~= nil then
    caster:RemoveAbility(ability:GetAbilityName())
  end
end

function SharpenedHatchets(keys)
  local caster = keys.caster
  local pID = caster:GetMainControllingPlayer()
  
  -- This research only applies to t1 workers so we don't need to search for any worker
  UNIT_KV[pID]["worker_t1"].LumberPerChop = 2

  if ABILITY_HOLDERS[caster:GetUnitName()] ~= nil then
    caster:RemoveAbility(ability:GetAbilityName())
  end
end

function Rifles(keys)
  local caster = keys.caster
  local ability = keys.ability
  local pID = caster:GetMainControllingPlayer()
  local phandle = PlayerResource:GetPlayer(pID)
  local hero = phandle:GetAssignedHero()

  ability:ApplyDataDrivenModifier(caster, hero, "rifle_attack_range", nil)

  if ABILITY_HOLDERS[caster:GetUnitName()] ~= nil then
    caster:RemoveAbility(ability:GetAbilityName())
  end
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

  if ABILITY_HOLDERS[caster:GetUnitName()] ~= nil then
    caster:RemoveAbility(ability:GetAbilityName())
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

  if ABILITY_HOLDERS[caster:GetUnitName()] ~= nil then
    caster:RemoveAbility(ability:GetAbilityName())
  end
end 

function HealingTower(keys)
  local caster = keys.caster
  local pID = caster:GetMainControllingPlayer()
  local ability = caster:FindAbilityByName("heal_tower_heal_aura")

  ability:SetLevel(2)

  -- Note there needs to be a flag set for all future heal towers built to auto level this
end

-- Human Vault Researches

function HumanDamage(keys)
  local caster = keys.caster
  local playerID = caster:GetMainControllingPlayer()
  local level = keys.Level
  local human = PlayerResource:GetPlayer(playerID):GetAssignedHero()
  local ability = caster:FindAbilityByName('upgrade_human_damage_'..level)

  human:SetBaseDamageMin(human:GetBaseDamageMin() + 100)
  human:SetBaseDamageMax(human:GetBaseDamageMax() + 100)
  human:SetBaseAttackTime(human:GetBaseAttackTime() + 0.1)
  FireGameEvent("build_ui_upgrade", {player_ID = pID, ability_name = 'upgrade_human_damage_1', builder = caster:GetUnitName(), tier = level}) 

  if ABILITY_HOLDERS[caster:GetUnitName()] ~= nil then
    caster:RemoveAbility(ability:GetAbilityName())
  end
end 

function SlayerGodlike(keys)
  local caster = keys.caster
  local playerID = caster:GetMainControllingPlayer()
  local ability = keys.ability

  local slayer = SLAYERS[playerID].handle
  slayer:SetBaseDamageMax(slayer:GetBaseDamageMax() + 1000)
  slayer:SetBaseDamageMin(slayer:GetBaseDamageMin() + 1000)
  slayer:SetBaseMaxHealth(slayer:GetBaseMaxHealth() + 10000)

  table.insert(SLAYERS[playerID]['upgrades'], ability)
end 

-- formerly GemQuality
function SpireQuality(keys)
  local caster = keys.caster
  local playerID = caster:GetMainControllingPlayer()
  local level = keys.level
end