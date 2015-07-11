--initialize the class
if House1 == nil then
	House1 = {}
	House1.__index = House1
end

function House1:Init(unit)
	local house1 = unit
	house1.queue = {} -- Queue of work to do, can be workers or research
	house1.doingWork = false -- Flag to indicate if the queue is currently in use
	house1.workHandler = nil -- Handle of the ability currently channeling
	house1.uniqueName = DoUniqueString("WorkTimer") -- Unique name for the work timer for this building
	house1.spawnName = DoUniqueString("SpawnTimer") -- Unique name for the work timer for this building
	house1.rallyPoint = nil -- Location to send units trained by this building

	-- If the building can spawn units this is invoked
	function unit:UnitSpawner()
		Timers:CreateTimer(house1.spawnName, {
			callback = function()
		if not unit:IsAlive() then
			return nil
		end

		
		-- Check if there is units in the queue and the queue is free
		-- Note the maximum displayable buffs seems to be 7, any more are not shown.
		if table.getn(house1.queue) > 0  and house1.doingWork == false then
			local keys = house1.queue[1]
			local caster =  keys.caster
			local abilityName = keys.AddToQueue
			local unitToSpawn = keys.SpawnUnit
			local requestingFood = nil
			local playerID = caster:GetMainControllingPlayer()
			house1.workHandler = caster:FindAbilityByName(abilityName)
	
			-- Check if the worker will fit in the food cap
			if UNIT_KV[playerID][unitToSpawn].ConsumesFood ~= nil then
				requestingFood = UNIT_KV[playerID][unitToSpawn].ConsumesFood
			else
				requestingFood = 0
			end


			if TOTAL_FOOD[playerID] >= CURRENT_FOOD[playerID ] + requestingFood then
				house1.workHandler:SetChanneling(true)
				local spawnTime = house1.workHandler:GetChannelTime()

				house1.doingWork = true

				-- Create a timer on a delay to create the worker
				Timers:CreateTimer(house1.uniqueName, {
							endTime = spawnTime,
							callback = function()
								if TOTAL_FOOD[playerID] >= CURRENT_FOOD[playerID] + requestingFood then
									if CURRENT_FOOD[playerID] + requestingFood <= 250 then
										local unit = Worker:Worker1(caster:GetAbsOrigin(), caster, unitToSpawn)
										
										CURRENT_FOOD[playerID] = CURRENT_FOOD[playerID] + requestingFood
										FireGameEvent('vamp_food_changed', { player_ID = playerID , food_total = CURRENT_FOOD[playerID]})
										
										caster:RemoveModifierByName(house1.workHandler:GetName())
										house1.workHandler:SetChanneling(false)
										house1.doingWork = false
	
										-- If a rally point is set for this building then move the worker to it.
										-- Needs a delay as movement cant happen on the same frame as spawn
										-- If a rally point is not set then the worker will move to the nearest tree
										if house1.rallyPoint ~= nil then
											Timers:CreateTimer(0.05, function()
												unit:MoveToPosition(house1.rallyPoint)
												return nil
											end)
										else
  											local tree = Entities:FindByClassnameNearest("ent_dota_tree",unit:GetAbsOrigin(),1000)
  											if tree ~= nil then
	  											Timers:CreateTimer(0.05, function()
														unit:MoveToPosition(tree:GetAbsOrigin())
														return nil
													end)
	  										end
										end
									else
										FireGameEvent( 'custom_error_show', { player_ID = playerID , _error = "Food cap reached" } )
										table.remove(house1.queue)
										caster:RemoveModifierByName(house1.workHandler:GetName())
										house1.workHandler:SetChanneling(false)
										house1.doingWork = false
									end
								else
									FireGameEvent( 'custom_error_show', { player_ID = playerID , _error = "Build more farms" } )
									table.remove(house1.queue)
									caster:RemoveModifierByName(house1.workHandler:GetName())
									house1.workHandler:SetChanneling(false)
									house1.doingWork = false
								end
							
							return nil
						end})
				-- Unit was created, pop the queue
				table.remove(house1.queue)
			else
				FireGameEvent( 'custom_error_show', { player_ID = playerID , _error = "Build more farms" } )
				table.remove(house1.queue)
				caster:RemoveModifierByName(house1.workHandler:GetName())
				house1.workHandler:SetChanneling(false)
				house1.doingWork = false
			end
		end
		return .1
	end})

	end
end