function AddAvernal( keys )
	local caster = keys.caster
	local casterIndex = caster:entindex()
	local playerID = caster:GetMainControllingPlayer()

	table.insert(AVERNALS[playerID], casterIndex)

	-- Add hp, damage based off vampire's level
	local vampLevel = VAMPIRES[playerID]:GetLevel()
	local baseHP = caster:GetMaxHealth()
	
	local hpBonus = vampLevel * 50
	caster:SetMaxHealth(baseHP + hpBonus)
	caster:SetHealth(caster:GetMaxHealth())

	local dmgBonus = vampLevel * 10
	caster:SetBaseDamageMin(caster:GetBaseDamageMin() + dmgBonus)
	caster:SetBaseDamageMax(caster:GetBaseDamageMax() + dmgBonus)
end

-- Removes an Avernal from global table on death.
function RemoveAvernal( keys )
	local caster = keys.caster
	local casterIndex = caster:entindex()
	local playerID = caster:GetMainControllingPlayer()

	for k, v in pairs(AVERNALS[playerID]) do
		if v:entindex() == casterIndex then
			table.remove(AVERNALS[playerID], k)
		end
	end
end

-- Upgrades Avernal to another type. TODO: Avernals requiring tech etc.
function UpgradeAvernal(keys)
	local caster = keys.caster
	local playerID = keys.playerID
	local newAvernal = keys.UpgradeTo
	local goldCost = keys.GoldCost
	local woodCost = keys.WoodCost
	local foodCost = keys.FoodCost

	if goldCost < GOLD[playerID] then
		FireGameEvent('custom_error_show', {player_ID = playerID, _error = 'Not enough gold!'})
		return
	end
	if woodCost < WOOD[playerID] then
		FireGameEvent('custom_error_show', {player_ID = playerID, _error = 'Not enough wood!'}) 
		return
	end
	if foodCost < CURRENT_FOOD[playerID] then
		FireGameEvent('custom_error_show', {player_ID = playerID, _error = 'Not enough food!'})
		return
	end
end