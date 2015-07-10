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
  if GOLD[pID] < goldCost then
    print(goldCost)
    caster:Stop()
    FireGameEvent( 'custom_error_show', { player_ID = pID, _error = "You need more gold" } )
    return
  end

  -- Player is ok to commence research, deduct resources
  ChangeWood(pID, -1 * lumberCost)
  ChangeGold(pID, -1 * goldCost)
    --used to temporarily hide research as it is being made, to ensure it is only done from
    --one research center at a time. 
  FireGameEvent('build_ui_hide', {player_ID = pID, ability_name = keys.ability:GetAbilityName(), builder = caster:GetUnitName(), tier = keys.level})
  TechTree:AddTechAbility(pID, keys.ability:GetAbilityName())
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
  ChangeWood(playerID, lumberCost)
  ChangeGold(playerID, goldCost)

  --Show the hidden icon in flash
  FireGameEvent('build_ui_show', {player_ID = playerID, ability_name = ability:GetAbilityName(), builder = caster:GetUnitName(), tier = keys.level})
end

-- Used to catch if cancelled by casting another ability
function Finished(keys)
  local caster = keys.caster
  local pID = caster:GetMainControllingPlayer()
  local player = PlayerResource:GetPlayer(pID)
  if keys.interrupted == 1 then
    Cancelled(keys)
  end
  Notifications:Bottom(pID, "Research Complete", 5, nil, {color="yellow", ["font-size"]="24px"})
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
  local ability = keys.ability
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
  local ability = keys.ability
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
  local ability = keys.ability

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
  slayer:SetMaxHealth(slayer:GetMaxHealth() + 10000)
  slayer:SetHealth(slayer:GetHealth() + 10000)

  table.insert(SLAYERS[playerID]['health'], 10000)
  table.insert(SLAYERS[playerID]['damage'], 1000)
end 

-- formerly GemQuality
function SpireQuality(keys)
  local caster = keys.caster
  local playerID = caster:GetMainControllingPlayer()
  local level = keys.level
end

-- Grants and extra skill point to the players vampire (up to 33)
function VampiricSkills( keys )
  local caster = keys.caster
  local playerID = caster:GetMainControllingPlayer()
  local vampire = VAMPIRES[playerID]
  local ability = keys.ability

  if vampire.VampiricSkills == nil then
    vampire.VampiricSkills = 0
  end

  vampire:SetAbilityPoints(vampire:GetAbilityPoints() + 1)
  vampire.VampiricSkills = vampire.VampiricSkills + 1

  if vampire.VampiricSkills == 33 then
    caster:RemoveAbility('research_vampiric_skills')
  else
    FireGameEvent('build_ui_show', {player_ID = playerID, ability_name = ability:GetAbilityName(), builder = caster:GetUnitName(), tier = 0})
  end
end

-- Give the vampire an extra 100 damage.
function VampiricDamage( keys )
  local caster = keys.caster
  local playerID = caster:GetMainControllingPlayer()
  local vampire = VAMPIRES[playerID]
  local ability = keys.ability

  if vampire.VampiricDamage == nil then
    vampire.VampiricDamage = 0
  end

  vampire:SetBaseDamageMin(vampire:GetBaseDamageMin() + 100)
  vampire:SetBaseDamageMax(vampire:GetBaseDamageMax() + 100)
  vampire.VampiricDamage = vampire.VampiricDamage + 1

  if vampire.VampiricDamage == 50 then
    caster:RemoveAbility('research_vampiric_damage')
  else
    FireGameEvent('build_ui_show', {player_ID = playerID, ability_name = ability:GetAbilityName(), builder = caster:GetUnitName(), tier = 0})
  end
end

-- Give the vampire an extra 300 to all stats.
function VampiricStats( keys )
  local caster = keys.caster
  local playerID = caster:GetMainControllingPlayer()
  local vampire = VAMPIRES[playerID]
  local ability = keys.ability

  if vampire.VampiricStats == nil then
    vampire.VampiricStats = 0
  end

  vampire:SetBaseStrength(vampire:GetBaseStrength() + 300)
  vampire:SetBaseAgility(vampire:GetBaseAgility() + 300)
  vampire:SetBaseIntellect(vampire:GetBaseIntellect() + 300)
  vampire.VampiricStats = vampire.VampiricStats + 1

  if vampire.VampiricStats == 50 then
    caster:RemoveAbility('research_vampiric_stats')
  else
    FireGameEvent('build_ui_show', {player_ID = playerID, ability_name = ability:GetAbilityName(), builder = caster:GetUnitName(), tier = 0})
  end
end

-- Give the vampire an extra 2000 to all stats and 500 damage.
function PowerUnderworld( keys )
  local caster = keys.caster
  local playerID = caster:GetMainControllingPlayer()
  local vampire = VAMPIRES[playerID]
  local ability = keys.ability

  if vampire.PowerUnderworld == nil then
    vampire.PowerUnderworld = 0
  end

  vampire:SetBaseStrength(vampire:GetBaseStrength() + 2000)
  vampire:SetBaseAgility(vampire:GetBaseAgility() + 2000)
  vampire:SetBaseIntellect(vampire:GetBaseIntellect() + 2000)
  vampire:SetBaseDamageMax(vampire:GetBaseDamageMax() + 500)
  vampire:SetBaseDamageMin(vampire:GetBaseDamageMin() + 500) 
  vampire.PowerUnderworld = vampire.PowerUnderworld + 1

  if vampire.PowerUnderworld == 30 then
    caster:RemoveAbility('research_power_underworld')
  else
    FireGameEvent('build_ui_show', {player_ID = playerID, ability_name = ability:GetAbilityName(), builder = caster:GetUnitName(), tier = 0})
  end
end

-- Give the vampire an extra 300 strength.
function VampiricStrength( keys )
  local caster = keys.caster
  local playerID = caster:GetMainControllingPlayer()
  local vampire = VAMPIRES[playerID]
  local ability = keys.ability

  if vampire.VampiricStrength == nil then
    vampire.VampiricStrength = 0
  end

  vampire:SetBaseStrength(vampire:GetBaseStrength() + 300) 
  vampire.VampiricStrength = vampire.VampiricStrength + 1

  if vampire.VampiricStrength == 50 then
    caster:RemoveAbility('research_vampiric_strength')
  else
    FireGameEvent('build_ui_show', {player_ID = playerID, ability_name = ability:GetAbilityName(), builder = caster:GetUnitName(), tier = 0})
  end
end

-- Give the vampire an extra 300 agility.
function VampiricAgility( keys )
  local caster = keys.caster
  local playerID = caster:GetMainControllingPlayer()
  local vampire = VAMPIRES[playerID]
  local ability = keys.ability

  if vampire.VampiricAgility == nil then
    vampire.VampiricAgility = 0
  end

  vampire:SetBaseAgility(vampire:GetBaseAgility() + 300)
  vampire.VampiricAgility = vampire.VampiricAgility + 1

  if vampire.VampiricAgility == 50 then
    caster:RemoveAbility('research_vampiric_agility') 
  else
    FireGameEvent('build_ui_show', {player_ID = playerID, ability_name = ability:GetAbilityName(), builder = caster:GetUnitName(), tier = 0})
  end
end

-- Give the vampire an extra 300 intellect.
function VampiricIntellect( keys )
  local caster = keys.caster
  local playerID = caster:GetMainControllingPlayer()
  local vampire = VAMPIRES[playerID]
  local ability = keys.ability

  if vampire.VampiricIntellect == nil then
    vampire.VampiricIntellect = 0
  end

  vampire:SetBaseIntellect(vampire:GetBaseIntellect() + 300)
  vampire.VampiricIntellect = vampire.VampiricIntellect + 1

  if vampire.VampiricIntellect == 50 then
    caster:RemoveAbility('research_vampiric_intellect')
  else
   FireGameEvent('build_ui_show', {player_ID = playerID, ability_name = ability:GetAbilityName(), builder = caster:GetUnitName(), tier = 0})
 end
end

function HumanSurvival( keys )
  local caster = keys.caster
  local playerID = caster:GetMainControllingPlayer()
  local human = HUMANS[playerID]

  Timers:CreateTimer(.03, function ()
      human:SetMaxHealth(human:GetMaxHealth() + 400)
      human:SetHealth(human:GetHealth() + 400)
      return nil
  end)
end

-- Sets the level of armor bonus
WALL_PLATING_SCALE = {
  wall_t1 = 1,
  wall_t2 = 2,
  wall_t3 = 3,
  wall_t4 = 4,
  wall_t5 = 5,
  wall_t6 = 5,
  wall_t7 = 6,
  wall_t8 = 6,
  wall_t9 = 7,
  wall_t10 = 8
}

function TechPlating( keys )
  local caster = keys.caster
  local playerID = caster:GetMainControllingPlayer()
  local wallName = caster:GetUnitName()
  local abilityName = keys.ability:GetAbilityName() 
  
  Timers:CreateTimer(.03, function ()
    local armorLevel = WALL_PLATING_SCALE[wallName]
    caster:FindAbilityByName(abilityName):SetLevel(armorLevel)
    return nil
  end)
end

-- Adds human teleport.
function AddTeleport( keys )
  local caster = keys.caster
  local playerID = caster:GetMainControllingPlayer()

  local human = HUMANS[playerID]

  human:FindAbilityByName('human_teleport'):SetLevel(1)
end

function TechUpgrade( keys )
  local caster = keys.caster
  local playerID = caster:GetMainControllingPlayer()
  local ability = keys.ability
  local abilityName = ability:GetAbilityName()
  local techMod = ABILITY_KV[abilityName]['GiveModifier']
  local level = keys.NextLevel
  local baseAbility = keys.BaseAbility

  --get all alive entities

  local ents = Entities:FindAllByClassname('npc_dota_creature')
  for k, v in pairs(ents) do
    -- is this unit effected by the research?
    if v:IsAlive() then
      local unitName = v:GetUnitName()      
      if UNIT_KV[playerID][unitName]['TechModifiers'] ~= nil then
        for i, mod in pairs(UNIT_KV[playerID][unitName]['TechModifiers']) do
          if mod == abilityName and v:GetMainControllingPlayer() == playerID then
            v:AddAbility(techMod)
            v:FindAbilityByName(techMod):SetLevel(1)
            --v:FindAbilityByName(techMod):OnUpgrade()
            v = nil
          end
        end
      end
    end
  end

  if level ~= nil then
    print('upgrading, ', baseAbility, level, abilityName)
    FireGameEvent("build_ui_upgrade", {player_ID = playerID, ability_name = baseAbility, builder = caster:GetUnitName(), tier = level}) 
  end
end

function AddHealthUpgrade( keys )
  local caster = keys.caster
  local amount = keys.Amount

  -- yeah this is how it should be
  Timers:CreateTimer(.03, function ()
    caster:SetMaxHealth(caster:GetMaxHealth() + amount)
    --SNIPPET PLS, if finished, add hp if not dont.
    if caster.state == "complete" then
      caster:SetHealth(caster:GetHealth() + amount)
    end
    return nil
  end)
end