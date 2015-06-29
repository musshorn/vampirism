function AddAvernal( keys )
	print('addavernal')
	local caster = keys.caster
	local casterIndex = caster:entindex()
	local playerID = caster:GetMainControllingPlayer()
	print('addavernal', playerID)
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
	GOLD[playerID] = GOLD[playerID] - goldCost
	FireGameEvent('vamp_gold_changed', {player_ID = playerID, gold_total = GOLD[playerID]})
end

function AvernalInvis( keys )
	keys.caster:AddNewModifier(keys.caster, nil, "modifier_invisible", {})
end

-- Stops avernal from attacking non-buildings
function AvernalRangedAttack( keys )
	local caster = keys.caster
	local target = keys.target

	if not target:HasAbility('is_a_building') then
		caster:Interrupt()
	end
end

-- Disables HP regen on wall towers and gold mines for 5 seconds.
function CorruptingBreath( keys )
	local caster = keys.caster
	local target = keys.target

	local targetName = target:GetUnitName()

	if string.find(targetName, "tower_wall") ~= nil or string.find(targetName, "gold_mine") then
		local hpRegen = target:GetHealthRegen()
		target:SetBaseHealthRegen(0)
		Timers:CreateTimer(5, function ()
			target:SetBaseHealthRegen(hpRegen)
		end)
	end
end

function FreezingBreath( keys )
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.target

	if target:HasAbility('is_a_building') then
		ability:ApplyDataDrivenModifier(caster, target, 'modifier_freezing_breath_effect', {duration = 3})
	end
end

function AvernalParticles( keys )
	local caster = keys.caster

	local aFire =  ParticleManager:CreateParticle("particles/avernal/avernal_ambient.vpcf", PATTACH_POINT_FOLLOW, caster)
	ParticleManager:SetParticleControlEnt(aFire, 0, caster, PATTACH_POINT_FOLLOW, "attach_mouthFire", caster:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(aFire, 1, caster, PATTACH_POINT_FOLLOW, "attach_mane1", caster:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(aFire, 2, caster, PATTACH_POINT_FOLLOW, "attach_mane2", caster:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(aFire, 3, caster, PATTACH_POINT_FOLLOW, "attach_mane3", caster:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(aFire, 4, caster, PATTACH_POINT_FOLLOW, "attach_mane4", caster:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(aFire, 5, caster, PATTACH_POINT_FOLLOW, "attach_mane5", caster:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(aFire, 6, caster, PATTACH_POINT_FOLLOW, "attach_mane6", caster:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(aFire, 7, caster, PATTACH_POINT_FOLLOW, "attach_mane7", caster:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(aFire, 8, caster, PATTACH_POINT_FOLLOW, "attach_mane8", caster:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(aFire, 10, caster, PATTACH_POINT_FOLLOW, "attach_hand_r", caster:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(aFire, 11, caster, PATTACH_POINT_FOLLOW, "attach_hand_l", caster:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(aFire, 12, caster, PATTACH_POINT_FOLLOW, "attach_mouthFire", caster:GetAbsOrigin(), true)
end