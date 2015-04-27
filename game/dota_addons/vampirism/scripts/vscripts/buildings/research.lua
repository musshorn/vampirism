function Research( keys )
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
  PlayerResource:ModifyGold(pID, -1 * goldCost, true, 9)
end

function ImproveLumber(keys)
  local ability = keys.ability
  local caster = keys.caster
  local pID = caster:GetMainControllingPlayer()
  local level = keys.Level

  -- This research only applies to t1 workers so we don't need to search for any worker
  if level == 1 then
    UNIT_KV[pID]["worker_t1"].MaximumLumber = 10
    FireGameEvent("build_ui_upgrade", {player_ID = pID, ability_name = 'research_improved_lumber_harvesting', builder = caster:GetUnitName(), tier = level})
  elseif level == 2 then
    UNIT_KV[pID]["worker_t1"].MaximumLumber = 15
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

      -- Increase the health of all the players harvesters
      for i = 1,table.getn(models) do
        local wall = models[i]
        if wall:GetMainControllingPlayer() == pID then
          local increasedHP = 0
          if level == 1 then
            wall.baseMaxHP = wall:GetMaxHealth()
            increasedHP = wall:GetMaxHealth() * 1.2  - wall:GetHealth()
            UNIT_KV[pID][key].HealthModifier = 1.2
          end
          if level == 2 then
            increasedHP = wall.baseMaxHP * 1.4  - wall:GetHealth()
            UNIT_KV[pID][key].HealthModifier = 1.4
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
end