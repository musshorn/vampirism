function AddAvernal( keys )
	local caster = keys.caster
	local casterIndex = caster:entindex()
	local playerID = caster:GetMainControllingPlayer()
	AVERNALS[playerID][casterIndex] = caster

	-- Add hp, damage based off vampire's level. Needs frameskip.
	Timers:CreateTimer(0.03, function ()
		local vampLevel = VAMPIRES[playerID]:GetLevel()
		local baseHP = caster:GetMaxHealth()
		local hpBonus = vampLevel * 50
		caster:SetMaxHealth(baseHP + hpBonus)
		caster:SetHealth(caster:GetMaxHealth())
		
		if caster:HasAbility('avernal_dmg_growth') then
			local dmgBonus = vampLevel * 10
			caster:SetBaseDamageMin(caster:GetBaseDamageMin() + dmgBonus)
			caster:SetBaseDamageMax(caster:GetBaseDamageMax() + dmgBonus)
		end
	end)
end

-- Removes an Avernal from global table on death.
function RemoveAvernal( keys )
	local caster = keys.caster
	local casterIndex = caster:entindex()
	local playerID = caster:GetMainControllingPlayer()

	table.remove(AVERNALS[playerID], casterIndex)
end

-- Upgrades Avernal to another type. TODO: Avernals requiring tech etc.
function UpgradeAvernal(keys)
	local caster = keys.caster
	local playerID = caster:GetMainControllingPlayer()
	local newAvernal = keys.UpgradeTo
	print(newAvernal)
	local goldCost = keys.GoldCost
	local woodCost = keys.WoodCost
	local foodCost = keys.FoodCost

	if goldCost > GOLD[playerID] then
		FireGameEvent('custom_error_show', {player_ID = playerID, _error = 'Not enough gold!'})
		return
	end
	if woodCost > WOOD[playerID] then
		FireGameEvent('custom_error_show', {player_ID = playerID, _error = 'Not enough wood!'}) 
		return
	end
	if foodCost > CURRENT_FOOD[playerID] then
		FireGameEvent('custom_error_show', {player_ID = playerID, _error = 'Not enough food!'})
		return
	end

	local currentHP = caster:GetHealth()
	local casterPos = caster:GetAbsOrigin()
	table.remove(AVERNALS[playerID], caster:entindex())
	caster:Destroy()
	local newUnit = CreateUnitByName(newAvernal, casterPos, true, VAMPIRES[playerID], PlayerResource:GetPlayer(playerID), PlayerResource:GetTeam(playerID))
	newUnit:SetControllableByPlayer(playerID, true)
	Timers:CreateTimer(0.09, function ()
		newUnit:SetHealth(currentHP)
		return nil
	end)
	ChangeGold(playerID, -1 * goldCost)
end

function AvernalInvis( keys )
	keys.caster:AddNewModifier(keys.caster, nil, "modifier_invisible", {})
end

-- Stops avernal from attacking non-buildings
function AvernalRangedAttack( keys )
	local caster = keys.caster
	local target = keys.target

	if not target:HasAbility('is_a_building') then
		caster:AddNewModifier(caster, ability, 'modifier_disarmed', {duration = 0.1})
		FireGameEvent('custom_error_show', {player_ID = caster:GetMainControllingPlayer(), _error = 'Unit may only attack buildings!'})
	end
end

-- Stops avernal from attacking non-harvesters
function AvernalMeteorAttack( keys )
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	if not target:HasAbility('harvest_channel') then
		caster:AddNewModifier(caster, ability, 'modifier_disarmed', {duration = 0.1})
		FireGameEvent('custom_error_show', {player_ID = caster:GetMainControllingPlayer(), _error = 'Unit may only attack workers!'})
	end
end

-- Check whether the unit should be effected by corruption.
function CorruptingBreath( keys )
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability

	local targetName = target:GetUnitName()

	if string.find(targetName, "tower_wall") ~= nil or string.find(targetName, "gold_mine") then
		target:ApplyDataDrivenModifier(caster, target, 'modifier_corrupting_effect', {})
	end
end

-- Disables HP regen on wall towers and gold mines for 5 seconds.
function ApplyCorrupting( keys )
	local caster = keys.caster
	local target = keys.target

	target:SetBaseHealthRegen(0)
end

-- Give unit back their regen, based on what is in the KV's. (May need to change if other effects alter this.)
function RemoveCorrupting( keys )
	local caster = keys.caster
	local target = keys.target
	local playerID = caster:GetMainControllingPlayer()

	local hpRegen = UNIT_KV[playerID][target:GetUnitName()]['StatusHealthRegen']

	target:SetBaseHealthRegen(hpRegen)
end

-- Stops building from being repaired
function FreezingBreath( keys )
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.target

	if target:HasAbility('is_a_building') then
		ability:ApplyDataDrivenModifier(caster, target, 'modifier_freezing_breath_effect', {duration = 3})
	end
end

function MeteorDestruction( keys )
	local caster = keys.caster
	local target = keys.target
	local targetPos = target:GetAbsOrigin()
	local ability = keys.ability
	local targetTeam = ability:GetAbilityTargetTeam()
	local targetType = ability:GetAbilityTargetType()

	local nearUnits = FindUnitsInRadius(caster:GetTeam(), targetPos, nil, 200, targetTeam, targetType, 0, FIND_CLOSEST, false)

	for k, v in pairs(nearUnits) do
		if v:HasAbility('harvest_channel') then
			ApplyDamage({victim = v, attacker = caster, damage = v:GetMaxHealth(), damage_type = DAMAGE_TYPE_PURE}) 
		end
	end

	caster:Destroy()
end

-- Adds particles to correct avernal.
function AvernalParticles( keys )
	local caster = keys.caster

	if caster:GetUnitName() == 'merc_avernal' or caster:GetUnitName() == 'merc_avernal_invisible' or caster:GetUnitName() == 'merc_avernal_ranged' or caster:GetUnitName() == 'merc_avernal_corrupted' then
		local aFire =  ParticleManager:CreateParticle("particles/units/heroes/hero_warlock/golem_ambient.vpcf", PATTACH_POINT_FOLLOW, caster)
		local casterPos = caster:GetAbsOrigin()
		ParticleManager:SetParticleControlEnt(aFire, 0, caster, PATTACH_POINT_FOLLOW, "attach_mouthFire", casterPos, true)
		ParticleManager:SetParticleControlEnt(aFire, 1, caster, PATTACH_POINT_FOLLOW, "attach_mane1", casterPos, true)
		ParticleManager:SetParticleControlEnt(aFire, 2, caster, PATTACH_POINT_FOLLOW, "attach_mane2", casterPos, true)
		ParticleManager:SetParticleControlEnt(aFire, 3, caster, PATTACH_POINT_FOLLOW, "attach_mane3", casterPos, true)
		ParticleManager:SetParticleControlEnt(aFire, 4, caster, PATTACH_POINT_FOLLOW, "attach_mane4", casterPos, true)
		ParticleManager:SetParticleControlEnt(aFire, 5, caster, PATTACH_POINT_FOLLOW, "attach_mane5", casterPos, true)
		ParticleManager:SetParticleControlEnt(aFire, 6, caster, PATTACH_POINT_FOLLOW, "attach_mane6", casterPos, true)
		ParticleManager:SetParticleControlEnt(aFire, 7, caster, PATTACH_POINT_FOLLOW, "attach_mane7", casterPos, true)
		ParticleManager:SetParticleControlEnt(aFire, 8, caster, PATTACH_POINT_FOLLOW, "attach_mane8", casterPos, true)
		ParticleManager:SetParticleControlEnt(aFire, 10, caster, PATTACH_POINT_FOLLOW, "attach_hand_r", casterPos, true)
		ParticleManager:SetParticleControlEnt(aFire, 11, caster, PATTACH_POINT_FOLLOW, "attach_hand_l", casterPos, true)
		ParticleManager:SetParticleControlEnt(aFire, 12, caster, PATTACH_POINT_FOLLOW, "attach_mouthFire", casterPos, true)
	end
	if caster:GetUnitName() == 'merc_avernal_frozen' then
		local aFire =  ParticleManager:CreateParticle("particles/econ/items/warlock/warlock_golem_obsidian/golem_ambient_obsidian.vpcf", PATTACH_POINT_FOLLOW, caster)
		local casterPos = caster:GetAbsOrigin()
		ParticleManager:SetParticleControlEnt(aFire, 0, caster, PATTACH_POINT_FOLLOW, "attach_mouthFire", casterPos, true)
		ParticleManager:SetParticleControlEnt(aFire, 2, caster, PATTACH_POINT_FOLLOW, "attach_mouthFire", casterPos, true)
		ParticleManager:SetParticleControlEnt(aFire, 5, caster, PATTACH_POINT_FOLLOW, "attach_mouthFire", casterPos, true)
		ParticleManager:SetParticleControlEnt(aFire, 12, caster, PATTACH_POINT_FOLLOW, "attach_mouthFire", casterPos, true)
	end
	if caster:GetUnitName() == 'merc_avernal_meteor' then
		local aFire =  ParticleManager:CreateParticle("particles/units/heroes/hero_phoenix/phoenix_supernova_egg_glow.vpcf", PATTACH_POINT_FOLLOW, caster)
		local casterPos = caster:GetAbsOrigin()
		ParticleManager:SetParticleControlEnt(aFire, 0, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", casterPos, true)
		ParticleManager:SetParticleControlEnt(aFire, 3, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", casterPos, true)
		local bFire =  ParticleManager:CreateParticle("particles/units/heroes/hero_phoenix/phoenix_supernova_egg_ground_ring_energy.vpcf", PATTACH_POINT_FOLLOW, caster)
		ParticleManager:SetParticleControlEnt(bFire, 0, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", casterPos, true)
		local cFire =  ParticleManager:CreateParticle("particles/units/heroes/hero_phoenix/phoenix_supernova_egg_lava.vpcf", PATTACH_POINT_FOLLOW, caster)
		ParticleManager:SetParticleControlEnt(cFire, 0, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", casterPos, true)
		local dFire =  ParticleManager:CreateParticle("particles/units/heroes/hero_phoenix/phoenix_supernova_egg_steam.vpcf", PATTACH_POINT_FOLLOW, caster)
		ParticleManager:SetParticleControlEnt(dFire, 0, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", casterPos, true)
	end
end