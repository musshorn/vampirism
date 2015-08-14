function Research( keys )
  local caster = keys.caster
  local ability = keys.ability
  local lumberCost = ABILITY_KV[ability:GetAbilityName()].LumberCost
  local goldCost = ABILITY_KV[ability:GetAbilityName()].GoldCost
  local pID = caster:GetMainControllingPlayer()
  local ability = keys.ability
  local abilityName = ability:GetAbilityName()
  local unitName = caster:GetUnitName()

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
    caster.goldCost = 0
    caster.lumberCost = 0
    FireGameEvent( 'custom_error_show', { player_ID = pID, _error = "You need more wood" } )
    return
  end
  if GOLD[pID] < goldCost then
    caster:Stop()
    caster.goldCost = 0
    caster.lumberCost = 0
    FireGameEvent( 'custom_error_show', { player_ID = pID, _error = "You need more gold" } )
    return
  end

  caster.lumberCost = lumberCost
  caster.goldCost = goldCost

  -- Player is ok to commence research, deduct resources
  ChangeWood(pID, -1 * lumberCost)
  ChangeGold(pID, -1 * goldCost)
    --used to temporarily hide research as it is being made, to ensure it is only done from
    --one research center at a time. 
  FireGameEvent('build_ui_hide', {player_ID = pID, ability_name = keys.ability:GetAbilityName(), builder = caster:GetUnitName(), tier = keys.level})

  -- Find all other buildings with this ability, hide it on those too. (only checking abilityholders. (which all research buildings are using at this point.))
  for name, table in pairs(ABILITY_HOLDERS) do
    if name ~= unitName then
      for k, v in pairs(ABILITY_HOLDERS[name]) do
        -- another unit had this ability, hide it.
        if v == abilityName then
          FireGameEvent('build_ui_hide', {player_ID = pID, ability_name = abilityName, builder = name, tier = keys.level})
        end
      end
    end
  end
end

-- Research was cancelled. Show the icon again, return cost to player.
function Cancelled(keys)
  local caster = keys.caster
  local ability = keys.ability
  local lumberCost = caster.lumberCost
  local goldCost = caster.goldCost
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

  -- Find all other buildings with this ability, show it on those too.
  for name, table in pairs(ABILITY_HOLDERS) do if name ~= unitName then
      for k, v in pairs(ABILITY_HOLDERS[name]) do
        -- another unit had this ability, hide it.
        if v == abilityName then
          FireGameEvent('build_ui_show', {player_ID = playerID, ability_name = ability:GetAbilityName(), builder = name, tier = keys.level})
        end
      end
    end
  end  
end

-- Used to catch if cancelled by casting another ability. Don't use this for when a reseach completes
-- by finishing channeling.
function Finished(keys)
  local caster = keys.caster
  local pID = caster:GetMainControllingPlayer()
  local player = PlayerResource:GetPlayer(pID)
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
    Notifications:Bottom(pID, {text = "Researched: Improved Lumber Havesting", duration = 5, nil, style = {color="yellow", ["font-size"]="24px"}})
  elseif level == 2 then
    UNIT_KV[pID]["worker_t1"].MaximumLumber = 15
    FireGameEvent("build_ui_upgrade", {player_ID = pID, ability_name = 'research_improved_lumber_harvesting', builder = caster:GetUnitName(), tier = level})
    Notifications:Bottom(pID, {text = "Researched: Advanced Lumber Havesting", duration =  5, nil, style = {color="yellow", ["font-size"]="24px"}})
  elseif level == 3 then
    UNIT_KV[pID]["worker_t1"].MaximumLumber = 20
    Notifications:Bottom(pID, {text = "Researched: Insane Lumber Havesting", duration = 5, nil, style = {color="yellow", ["font-size"]="24px"}})
  end

  TechTree:AddTechAbility(pID, ability:GetAbilityName())

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
  Notifications:Bottom(pID, {text = "Researched: Sharpened Hatchets", duration = 5, nil, style = {color="yellow", ["font-size"]="24px"}})
  TechTree:AddTechAbility(pID, ability:GetAbilityName())

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
  TechTree:AddTechAbility(pID, ability:GetAbilityName())

  ability:ApplyDataDrivenModifier(caster, hero, "rifle_attack_range", nil)
  Notifications:Bottom(pID, {text = "Researched: Rifles", duration = 5, nil, style = {color="yellow", ["font-size"]="24px"}})

  if ABILITY_HOLDERS[caster:GetUnitName()] ~= nil then
    caster:RemoveAbility(ability:GetAbilityName())
  end
end

function ImprovedWorkerMotivation(keys)
  local caster = keys.caster
  local ability = keys.ability
  local pID = caster:GetMainControllingPlayer()
  TechTree:AddTechAbility(pID, ability:GetAbilityName())
  
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

  Notifications:Bottom(pID, {text = "Researched: Improved Worker Motivation", duration = 5, nil, style = {color="yellow", ["font-size"]="24px"}})

  if ABILITY_HOLDERS[caster:GetUnitName()] ~= nil then
    caster:RemoveAbility(ability:GetAbilityName())
  end
end

function GemQuality(keys)
  local caster = keys.caster
  local pID = caster:GetMainControllingPlayer()
  local level = keys.Level
  local ability = keys.ability
  TechTree:AddTechAbility(pID, ability:GetAbilityName())

  -- Find all units with "AffectedByGemUpgrades" not nil, these are all the walls
  for key, value in pairs(UNIT_KV[pID]) do
    if UNIT_KV[pID][key].AffectedByGemUpgrades ~= nil then
      models = Entities:FindAllByModel(UNIT_KV[pID][key].Model)

      -- Set healthmodifier of all walls.
      UNIT_KV[pID][key].HealthModifier = level

      -- Increase the health of all alive walls
      for k,v in pairs(models) do
        GameMode:CheckGemQuality(v)
      end
   end
  end

  if level == 1 then
    Notifications:Bottom(pID, {text = "Researched: Improved Gem Quality", duration = 5, nil, style = {color="yellow", ["font-size"]="24px"}})
  end
  if level == 2 then
    Notifications:Bottom(pID, {text = "Researched: Advanced Gem Quality", duration = 5, nil, style = {color="yellow", ["font-size"]="24px"}})
  end
  if level == 3 then
    Notifications:Bottom(pID, {text = "Researched: Insane Gem Quality", duration = 5, nil, style = {color="yellow", ["font-size"]="24px"}})
  end

  if level < 3 then
    FireGameEvent("build_ui_upgrade", {player_ID = pID, ability_name = 'research_improved_gem_quality', builder = caster:GetUnitName(), tier = level})
  end

  if ABILITY_HOLDERS[caster:GetUnitName()] ~= nil then
    caster:RemoveAbility(ability:GetAbilityName())
  end
end 

function HealingTower(keys)
  local caster = keys.caster
  local pID = caster:GetMainControllingPlayer()
  local ability = caster:FindAbilityByName("heal_tower_heal_aura")
  TechTree:AddTechAbility(pID, ability:GetAbilityName())

  ability:SetLevel(2)

  Notifications:Bottom(pID, {text = "Researched: Mana Regeneration", duration = 5, nil, style = {color="yellow", ["font-size"]="24px"}})

  -- Note there needs to be a flag set for all future heal towers built to auto level this
end

-- Human Damage Researches
function HumanDamage(keys)
  local caster = keys.caster
  local playerID = caster:GetMainControllingPlayer()
  local level = keys.Level
  local human = PlayerResource:GetPlayer(playerID):GetAssignedHero()
  local ability = caster:FindAbilityByName('upgrade_human_damage_'..level)
  TechTree:AddTechAbility(playerID, ability:GetAbilityName())

  human:SetBaseDamageMin(human:GetBaseDamageMin() + 100)
  human:SetBaseDamageMax(human:GetBaseDamageMax() + 100)
  human:SetBaseAttackTime(human:GetBaseAttackTime() + 0.1)

  FireGameEvent("build_ui_upgrade", {player_ID = playerID, ability_name = 'upgrade_human_damage_1', builder = caster:GetUnitName(), tier = level}) 

  -- Find all other buildings with this and set their level to the right one too.
  for name, table in pairs(ABILITY_HOLDERS) do
    if name ~= unitName then
      for k, v in pairs(ABILITY_HOLDERS[name]) do
        -- another unit had this ability, hide it.
        if v == abilityName then
          FireGameEvent('build_ui_upgrade', {player_ID = playerID, ability_name = 'upgrade_human_damage_1', builder = name, tier = level})
        end
      end
    end
  end

  Notifications:Bottom(playerID, {text = "Researched: Human Damage "..level, duration = 5, nil, style = {color="yellow", ["font-size"]="24px"}})

  if ABILITY_HOLDERS[caster:GetUnitName()] ~= nil then
    caster:RemoveAbility(ability:GetAbilityName())
  end
end 

function SlayerGodlike(keys)
  local caster = keys.caster
  local playerID = caster:GetMainControllingPlayer()
  local ability = keys.ability

  TechTree:AddTechAbility(playerID, ability:GetAbilityName())
  local slayer = SLAYERS[playerID].handle
  slayer:SetBaseDamageMax(slayer:GetBaseDamageMax() + 1000)
  slayer:SetBaseDamageMin(slayer:GetBaseDamageMin() + 1000)
  slayer:SetMaxHealth(slayer:GetMaxHealth() + 10000)
  slayer:SetHealth(slayer:GetHealth() + 10000)

  Notifications:Bottom(playerID, {text = "Researched: Slayer Godlike Training", duration = 5, nil, style = {color="yellow", ["font-size"]="24px"}})

  table.insert(SLAYERS[playerID]['health'], 10000)
  table.insert(SLAYERS[playerID]['damage'], 1000)
end 

-- formerly GemQuality
function SpireQuality(keys)
  local caster = keys.caster
  local playerID = caster:GetMainControllingPlayer()
  local level = keys.level
  local ability = keys.ability
  TechTree:AddTechAbility(pID, ability:GetAbilityName())

  Notifications:Bottom(playerID, {text = "Researched: Spire Quality "..level, duration = 5, nil, style = {color="yellow", ["font-size"]="24px"}})
end

-- Grants and extra skill point to the players vampire (up to 33)
function VampiricSkills( keys )
  local caster = keys.caster
  local playerID = caster:GetMainControllingPlayer()
  local vampire = VAMPIRES[playerID]
  local ability = keys.ability
  TechTree:AddTechAbility(playerID, ability:GetAbilityName())

  if vampire.VampiricSkills == nil then
    vampire.VampiricSkills = 0
  end

  vampire:SetAbilityPoints(vampire:GetAbilityPoints() + 1)
  vampire.VampiricSkills = vampire.VampiricSkills + 1

  Notifications:Bottom(playerID, {text = "Researched: Vampiric Skills", duration = 5, nil, style = {color="yellow", ["font-size"]="24px"}})

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

  Notifications:Bottom(playerID, {text = "Researched: Vampiric Damage", duration = 5, nil, style = {color="yellow", ["font-size"]="24px"}})

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

  Notifications:Bottom(playerID, {text = "Researched: Vampiric Stats", duration = 5, nil, style = {color="yellow", ["font-size"]="24px"}})

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

  Notifications:Bottom(playerID, {text = "Researched: Power of the Underworld", duration = 5, nil, style = {color="yellow", ["font-size"]="24px"}})

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

  Notifications:Bottom(playerID, {text = "Researched: Vampiric Strength", duration = 5, nil, style = {color="yellow", ["font-size"]="24px"}})

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

  Notifications:Bottom(playerID, {text = "Researched: Vampiric Agility", duration = 5, nil, style = {color="yellow", ["font-size"]="24px"}})

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

  Notifications:Bottom(playerID, {text = "Researched: Vampiric Intellect", duration = 5, nil, style = {color="yellow", ["font-size"]="24px"}})

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
  local amount = keys.Amount
  local ability = keys.ability
  TechTree:AddTechAbility(playerID, ability:GetAbilityName())

  Notifications:Bottom(playerID, {text= "Researched: Basic Human Survival", duration = 5, nil, style = {color="yellow", ["font-size"]="24px"}})

  Timers:CreateTimer(.03, function ()
      human:SetMaxHealth(human:GetMaxHealth() + amount)
      human:SetHealth(human:GetHealth() + amount)
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
  TechTree:AddTechAbility(playerID, abilityName)

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
  local ability = keys.ability

  local human = HUMANS[playerID]
  TechTree:AddTechAbility(playerID, ability:GetAbilityName())

  Notifications:Bottom(playerID, {text = "Researched: Human Teleport", duration = 5, nil, style = {color="yellow", ["font-size"]="24px"}})

  human:FindAbilityByName('human_teleport'):SetLevel(1)
end

-- Upgrades the blink of super tower builders
function AddBlinkExtension( keys )
  local caster = keys.caster
  local playerID = caster:GetMainControllingPlayer()
  local ability = keys.ability
  TechTree:AddTechAbility(playerID, ability:GetAbilityName())

  caster:RemoveAbility('human_blink')
  caster:AddAbility('super_blink')
  caster:FindAbilityByName('super_blink'):SetLevel(1)

  Notifications:Bottom(playerID, {text = "Researched: Blink Extension", duration = 5, nil, style = {color="yellow", ["font-size"]="24px"}})
end

-- Adds Holy Upgrade to lantern towers.
function AddEssence( keys )
  local caster = keys.caster
  local playerID = caster:GetMainControllingPlayer()

  caster:AddAbility('upgrade_to_tower_lantern_t2')
end

-- Levels up the heal ability on heal towers
function ManaRegeneration( keys )
  local caster = keys.caster
  caster:FindAbilityByName('heal_tower_heal_aura'):SetLevel(2)
end

function TechUpgrade( keys )
  local caster = keys.caster
  local playerID = caster:GetMainControllingPlayer()
  local ability = keys.ability
  local abilityName = ability:GetAbilityName()
  local techMod = ABILITY_KV[abilityName]['GiveModifier']
  local level = keys.NextLevel
  local baseAbility = keys.BaseAbility
  TechTree:AddTechAbility(playerID, abilityName)

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
    FireGameEvent("build_ui_upgrade", {player_ID = playerID, ability_name = baseAbility, builder = caster:GetUnitName(), tier = level})
    -- Find all other buildings with this and set their level to the right one too.
    for name, table in pairs(ABILITY_HOLDERS) do
      if name ~= unitName then
        for k, v in pairs(ABILITY_HOLDERS[name]) do
          -- another unit had this ability, hide it.
          if v == abilityName then
            FireGameEvent('build_ui_upgrade', {player_ID = playerID, ability_name = baseAbility, builder = name, tier = level})
          end
        end
      end
    end
  end

  Notifications:Bottom(playerID, {text = "Researched: "..ABILITY_NAMES[abilityName], duration = 5, nil, style = {color="yellow", ["font-size"]="24px"}})
end

function AddHealthUpgrade( keys )
  local caster = keys.caster
  local amount = keys.Amount
  -- yeah this is how it should be
  Timers:CreateTimer(.09, function ()
    caster:SetMaxHealth(caster:GetMaxHealth() + amount)
    if caster:HasAbility('is_a_building') then
      if caster.state == "complete" then
        caster:Heal(amount, caster)
      end
    else
      caster:Heal(amount, caster)
    end
    return nil
  end)
end