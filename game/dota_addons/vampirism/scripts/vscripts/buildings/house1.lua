--initialize the class
if House1 == nil then
	House1 = {}
	House1.__index = House1
end

function House1:Init(unit)
	local house1 = unit
	house1.queue = {} -- Queue of work to do, can be workers or research
	local doingWork = false -- Flag to indicate if the queue is currently in use

	Timers:CreateTimer(function()
		if not unit:IsAlive() then
			return nil
		end

		--Check if there is units in the queue and the queue is free
		--Note the maximum displayable buffs seems to be 7, any more are not shown.
		if table.getn(house1.queue) > 0  and doingWork == false then
			local keys = house1.queue[1]
			local caster =  keys.caster
			local abilityName = keys.AddToQueue
						
			local ability = caster:FindAbilityByName(abilityName)
			unitNameToBeCreated = ability

			ability:SetChanneling(true)
			local spawnTime = ability:GetChannelTime()

			doingWork = true
			
			-- Create a timer on a delay to create the worker
			Timers:CreateTimer(spawnTime, function()
					local unit = Worker:Worker1(caster:GetAbsOrigin(), caster)
					if unit.think then
						unit:Think()
					end
					caster:RemoveModifierByName(ability:GetName())
					ability:SetChanneling(false)
					doingWork = false
				return nil
			end)
			table.remove(house1.queue)
		end

		return .1
	end)
end