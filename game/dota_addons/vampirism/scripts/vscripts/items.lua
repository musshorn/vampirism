function CheckLumber( keys )
	print('checking lumber for item')
	PrintTable(keys)
end

function CoinUsed(keys)
	local user = keys.caster
	local coin = keys.ability

	if user:IsRealHero() then
    if keys.Type == "small" then
		  user:SetGold(user:GetGold() + 1, true)
    end
    if keys.Type == "large" then
      user:SetGold(user:GetGold() + 1, true)
    end
	end
end

function ItemMoveSpeed( keys )
	--do this later hehe
end

function SphereDoom( keys )
	local caster = keys.caster
	local ability = keys.ability
	local point = keys.target_points[1]

	-- Move a "test unit", find the distance between them and see if it's ok then move the vamp
	FindClearSpaceForUnit(caster, point, false)

	local dist = CalcDistanceBetweenEntityOBB(caster, caster)

	if dist < gooddist then
		FindClearSpaceForUnit(caster, point, false)
	else
		FireGameEvent("custom_error_show", {player_ID = caster:GetMainControllingPlayer(), _error = "Vampire doesn't fit here!"}) 
	end
end

function SpawnEngineers( keys )
	local caster = keys.caster
	local playerID = caster:GetMainControllingPlayer()
	local ability = keys.ability

	for i = 1, 4 do
		local engi = CreateUnitByName("toolkit_engineer", caster:GetAbsOrigin(), true, nil, nil, 0)
		engi:SetControllableByPlayer(playerID, true)
	end
end