function Building:House1(vPoint, hOwner)
	--creates house, identical to your towers.lua from powertowers.
	local house1 = Building:new(vPoint, 2, hOwner, "house_t1", 1, 0.7, nil)
	--house1:SetUnitName("house_t1")
	--print("NAME ON CREATION"..house1:GetUnitName())
	if house1 ~= nil then
		house1.buildSuccess = true
	else
		return
	end

	house1.think = true

	function house1:Think()
		house1.generationTimer = 
		Timers:CreateTimer(function ()

			if not house1:IsAlive() then
				return nil
			end

			if house1:GetMana() >= 120 then
				removeStack(house1:GetEntityIndex())
			end

			return .1
			-- body
		end)
	end

	--Spwan worker ability that can be called by each house
	function spawnWorkerT1(keys)
		if keys.caster:GetModifierStackCount("spawn_t1", keys.caster) < 7 then
			print(keys.caster:GetName())
			keys.caster:SetBaseManaRegen(120)
			keys.caster:SetModifierStackCount("spawn_t1", keys.caster, keys.caster:GetModifierStackCount("spawn_t1", keys.caster) + 1)
		end
	end

	function removeStack(entindex)
		local house = EntIndexToHScript(entindex)
		local stacks = house:GetModifierStackCount("spawn_t1", house)
		local playerid = house:GetPlayerOwnerID() + 1
		if stacks > 0 then
			house:SetModifierStackCount("spawn_t1", house, stacks - 1)
			local unit = Worker:Worker1(house:GetAbsOrigin(), house)
			if unit.think then
				unit:Think()
			end
			house:SetMana(0)
			if house:GetModifierStackCount("spawn_t1", house) == 0  then
				house:SetBaseManaRegen(0)
			end
		end
		print(house:GetUnitName())
	end

	return house1
end