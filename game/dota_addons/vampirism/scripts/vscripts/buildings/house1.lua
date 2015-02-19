--initialize the class
if House1 == nil then
	House1 = {}
	House1.__index = House1
end

function House1:Init(unit)
	local house1 = unit
	house1.queue = {} -- Queue of work to do, can be workers or research
	house1.workTimer = nil -- Handle to the inner timer, used to cancel the current job
	house1.doingWork = false -- Flag to indicate if the queue is currently in use
	house1.workHandler = nil -- Handle of the ability currently channeling

	Timers:CreateTimer(function()
		if not unit:IsAlive() then
			return nil
		end

		--Check if there is units in the queue and the queue is free
		--Note the maximum displayable buffs seems to be 7, any more are not shown.
		if table.getn(house1.queue) > 0  and house1.doingWork == false then
			local keys = house1.queue[1]
			local caster =  keys.caster
			local abilityName = keys.AddToQueue
						
			house1.workHandler = caster:FindAbilityByName(abilityName)

			house1.workHandler:SetChanneling(true)
			local spawnTime = house1.workHandler:GetChannelTime()

			house1.doingWork = true
			
			-- Create a timer on a delay to create the worker
			house1.workTimer = Timers:CreateTimer("WorkTimer", {
					endTime = spawnTime,
					callback =  function()
						local unit = Worker:Worker1(caster:GetAbsOrigin(), caster)
						if unit.think then
							unit:Think()
						end
						caster:RemoveModifierByName(house1.workHandler:GetName())
						house1.workHandler:SetChanneling(false)
						house1.doingWork = false
						return nil
				end})
			table.remove(house1.queue)
		end

		return .1
	end)
end