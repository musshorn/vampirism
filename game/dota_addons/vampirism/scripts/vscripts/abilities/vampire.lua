--[[
    Author: space-jam-
    Date: 3.3.2015
    Vampire abilities, specifically Shadow Sight, Health Beam.
]]

--Creates dummy units, depending on the level of the ability.
function ShadowSight(keys)
  local caster = keys.caster
  local target = keys.target_points[1]
  local ability = keys.ability
  local playerID = caster:GetMainControllingPlayer()

  if ability:GetLevel() == 1 then
    CreateUnitByName("vampire_vision_dummy_1", target, false, caster, PlayerResource:GetPlayer(playerID), PlayerResource:GetTeam(playerID))
  elseif ability:GetLevel() == 2 then
    CreateUnitByName("vampire_vision_dummy_2", target, false, caster, PlayerResource:GetPlayer(playerID), PlayerResource:GetTeam(playerID))
  end
end

--Called when the dummy is created, and destroys it on time.
function VisionDummy(keys)
  local dummy = keys
	local lock = dummy:FindAbilityByName("vampire_vision_dummy_lock")

  --The level of the reveal dummy
  local level = tonumber(string.sub(dummy:GetUnitName(), -1))

  --Determine the amount of time the dummy should stay alive.
  if level == 1 then
    Timers:CreateTimer(10, function ()
        dummy:RemoveSelf()
    end)
  elseif level == 2 then
    Timers:CreateTimer(20, function ()
        dummy:RemoveSelf()
    end)
  end
end

--[[Heal beam that jumps to a number of units, but not the original caster, unless cast on self.
    Credit to Pizzalol and Noya for the original lua. (SpellLibrary)
    Tweaked so that it does no damage, and only heals the caster if it is targeted.]]

function HealthBeam( keys )
  local caster = keys.caster
  local caster_location = caster:GetAbsOrigin()
  local target = keys.target
  local target_location = target:GetAbsOrigin()
  local ability = keys.ability
  local ability_level = ability:GetLevel() - 1

  -- Ability variables
  local bounce_radius = ability:GetSpecialValueFor("bounce_radius")
  local max_targets = ability:GetLevelSpecialValueFor("max_targets", ability_level)
  local heal = ability:GetLevelSpecialValueFor("heal", ability_level)
  local unit_healed = false

  -- Particles
  local shadow_wave_particle = keys.shadow_wave_particle

  -- Setting up the hit table
  local hit_table = {}

  if target == caster then
    target:Heal(heal, caster)
    max_targets = max_targets - 1
  end 
  
  -- Priority is Hurt Heroes > Hurt Units > Heroes > Units
  -- we start from 2 first because we healed 1 target already
  for i = 0, max_targets - 1 do
    print('CHECKING FOR TARGETS')
    -- Helper variable to keep track if we healed a unit already
    unit_healed = false

    -- Find all the heroes in bounce radius
    local heroes = FindUnitsInRadius(caster:GetTeam(), target_location, nil, bounce_radius, ability:GetAbilityTargetTeam(), DOTA_UNIT_TARGET_HERO, 0, FIND_CLOSEST, false)

    -- HURT HEROES --
    -- First we check for hurt heroes
    for _,unit in pairs(heroes) do
      if unit ~= caster then
        local check_unit = 0  -- Helper variable to determine if a unit has been hit or not

        -- Checking the hit table to see if the unit is hit
        for c = 0, #hit_table do
          if hit_table[c] == unit then
            check_unit = 1
          end
        end

        -- If its not hit then check if the unit is hurt
        if check_unit == 0 then
          if unit:GetHealth() ~= unit:GetMaxHealth() then
            -- After we find the hurt hero unit then we insert it into the hit table to keep track of it
            -- and we also get the unit position
            table.insert(hit_table, unit)
            local unit_location = unit:GetAbsOrigin()

            -- Create the particle for the visual effect
            local particle = ParticleManager:CreateParticle(shadow_wave_particle, PATTACH_CUSTOMORIGIN, caster)
            ParticleManager:SetParticleControlEnt(particle, 0, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target_location, true)
            ParticleManager:SetParticleControlEnt(particle, 1, unit, PATTACH_POINT_FOLLOW, "attach_hitloc", unit_location, true)

            -- Set the unit as the new target
            target = unit
            target_location = unit_location

            -- Heal it
            target:Heal(heal, caster)

            -- Set the helper variable to true
            unit_healed = true

            -- Exit the loop for finding hurt heroes
            break
          end
        end
      end
    end

    -- Find all the units in bounce radius
    local units = FindUnitsInRadius(caster:GetTeam(), target_location, nil, bounce_radius, ability:GetAbilityTargetTeam(), DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_MECHANICAL, 0, FIND_CLOSEST, false)
    
    -- HURT UNITS --
    -- check for hurt units if we havent healed a unit yet
    if not unit_healed then
      for _,unit in pairs(units) do
        local check_unit = 0  -- Helper variable to determine if the unit has been hit or not

        -- Checking the hit table to see if the unit is hit
        for c = 0, #hit_table do
          if hit_table[c] == unit then
            check_unit = 1
          end
        end

        -- If its not hit then check if the unit is hurt
        if check_unit == 0 then
          if unit:GetHealth() ~= unit:GetMaxHealth() then
            -- After we find the hurt hero unit then we insert it into the hit table to keep track of it
            -- and we also get the unit position
            table.insert(hit_table, unit)
            local unit_location = unit:GetAbsOrigin()

            -- Create the particle for the visual effect
            local particle = ParticleManager:CreateParticle(shadow_wave_particle, PATTACH_CUSTOMORIGIN, caster)
            ParticleManager:SetParticleControlEnt(particle, 0, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target_location, true)
            ParticleManager:SetParticleControlEnt(particle, 1, unit, PATTACH_POINT_FOLLOW, "attach_hitloc", unit_location, true)

            -- Set the unit as the new target
            target = unit
            target_location = unit_location

            -- Heal it
            target:Heal(heal, caster)

            -- Set the helper variable to true
            unit_healed = true

            -- Exit the loop for finding hurt heroes
            break
          end
        end
      end
    end

    -- HEROES --
    -- In this loop we search for valid heroes regardless if it is hurt or not
    -- Search only if we havent healed a unit yet
    if not unit_healed then
      for _,unit in pairs(heroes) do
        local check_unit = 0  -- Helper variable to determine if a unit has been hit or not

        -- Checking the hit table to see if the unit is hit
        for c = 0, #hit_table do
          if hit_table[c] == unit then
            check_unit = 1
          end
        end

        -- If its not hit then do the bounce
        if check_unit == 0 then
          -- Insert the found unit into the hit table
          -- and we also get the unit position
          table.insert(hit_table, unit)
          local unit_location = unit:GetAbsOrigin()

          -- Create the particle for the visual effect
          local particle = ParticleManager:CreateParticle(shadow_wave_particle, PATTACH_CUSTOMORIGIN, caster)
          ParticleManager:SetParticleControlEnt(particle, 0, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target_location, true)
          ParticleManager:SetParticleControlEnt(particle, 1, unit, PATTACH_POINT_FOLLOW, "attach_hitloc", unit_location, true)

          -- Set the unit as the new target
          target = unit
          target_location = unit_location

          -- Heal it
          target:Heal(heal, caster)

          -- Set the helper variable to true
          unit_healed = true

          -- Exit the loop
          break       
        end
      end
    end

    -- UNITS --
    -- Search for units regardless if it is hurt or not
    -- Search only if we havent healed a unit yet
    if not unit_healed then
      for _,unit in pairs(units) do
        local check_unit = 0  -- Helper variable to determine if a unit has been hit or not

        -- Checking the hit table to see if the unit is hit
        for c = 0, #hit_table do
          if hit_table[c] == unit then
            check_unit = 1
          end
        end

        -- If its not hit then do the bounce
        if check_unit == 0 then
          -- Insert the found unit into the hit table
          -- and we also get the unit position
          table.insert(hit_table, unit)
          local unit_location = unit:GetAbsOrigin()

          -- Create the particle for the visual effect
          local particle = ParticleManager:CreateParticle(shadow_wave_particle, PATTACH_CUSTOMORIGIN, caster)
          ParticleManager:SetParticleControlEnt(particle, 0, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target_location, true)
          ParticleManager:SetParticleControlEnt(particle, 1, unit, PATTACH_POINT_FOLLOW, "attach_hitloc", unit_location, true)

          -- Set the unit as the new target
          target = unit
          target_location = unit_location

          -- Heal it
          target:Heal(heal, caster)

          -- Set the helper variable to true
          unit_healed = true

          -- Exit the loop for finding hurt heroes
          break       
        end
      end
    end
  end
end

function ChainOfDeath(keys)
  local caster = keys.caster
  local caster_location = caster:GetAbsOrigin()
  local target = keys.target
  local target_location = target:GetAbsOrigin()
  local ability = keys.ability
  local ability_level = ability:GetLevel() - 1

  -- Ability variables
  local bounce_radius = ability:GetSpecialValueFor("bounce_radius")
  local max_targets = ability:GetLevelSpecialValueFor("max_targets", ability_level)
  local s_damage = ability:GetLevelSpecialValueFor("damage", ability_level)
  local unit_damaged = false

  print(bounce_radius)
  print(max_targets)
  print(s_damage)

  print(target:GetTeam())
  print(target_location)
  print(ability:GetAbilityTargetTeam())


  -- Particles
  local chain_of_death_particle = keys.chain_of_death_particle

  -- Setting up the hit table
  local hit_table = {}

  local count = 0
  
  --No priority unlike in heal beam, just find nearest
  Timers:CreateTimer(function ()
    if count < max_targets then
      count = count + 1
      --print('OUTER RUNNING')
      -- Helper variable to keep track if we damaged a unit already
      unit_damaged = false
  
      -- Find all the units in bounce radius
      local units = FindUnitsInRadius(caster:GetTeam(), target_location, nil, bounce_radius, ability:GetAbilityTargetTeam(), DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO, 0, FIND_CLOSEST, false)
      PrintTable(units)
      -- HURT HEROES --
      -- First we check for hurt heroes
      for _,unit in pairs(units) do
        print(unit:GetUnitName())
        if unit ~= caster then
          local check_unit = 0  -- Helper variable to determine if a unit has been hit or not
  
          -- Checking the hit table to see if the unit is hit
          for c = 0, #hit_table do
            if hit_table[c] == unit then
              check_unit = 1
            end
          end
  
          -- If its not hit then check if the unit has been hit
          if check_unit == 0 then
  
            table.insert(hit_table, unit)
            local unit_location = unit:GetAbsOrigin()
  
            -- Create the particle for the visual effect
            local particle = ParticleManager:CreateParticle(chain_of_death_particle, PATTACH_CUSTOMORIGIN, caster)
            ParticleManager:SetParticleControlEnt(particle, 0, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target_location, true)
            ParticleManager:SetParticleControlEnt(particle, 1, unit, PATTACH_POINT_FOLLOW, "attach_hitloc", unit_location, true)
  
            -- Set the unit as the new target
            target = unit
            target_location = unit_location
  
            local damageTable = {
              victim = unit,
              attacker = caster,
              damage = s_damage,
              damage_type = DAMAGE_TYPE_MAGICAL,
            }
            ApplyDamage(damageTable)
  
            -- Set the helper variable to true
            unit_damaged = true
            break
          end
        end
      end
    end
  return .25
  end)
end

function CykaSpeed(keys)
  local caster = keys.caster
  local ability = keys.ability
  local ability_level = ability:GetLevel() - 1
  local duration = ability:GetLevelSpecialValueFor("duration", ability_level)

  caster:AddNewModifier(caster, ability, "modifier_invisible", {duration = duration})
  caster:AddNewModifier(caster, ability, "modifier_bloodseeker_thirst_speed", {duration = duration, visibility_threshold_pct = 100, invis_threshold_pct = 100, bonus_movement_speed = 1, bonus_damage = 0})
  caster:AddNewModifier(caster, ability, "modifier_item_orb_of_venom_slow", {duration = duration, slow = -42})
end