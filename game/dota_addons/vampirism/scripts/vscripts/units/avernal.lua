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
	
		local dmgBonus = vampLevel * 10
		caster:SetBaseDamageMin(caster:GetBaseDamageMin() + dmgBonus)
		caster:SetBaseDamageMax(caster:GetBaseDamageMax() + dmgBonus)
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
end

function AvernalInvis( keys )
	keys.caster:AddNewModifier(keys.caster, nil, "modifier_invisible", {})
end