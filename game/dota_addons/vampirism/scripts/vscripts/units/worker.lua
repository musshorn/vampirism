VECTOR_BUMP = Vector(50, 0, 0)

if Worker == nil then
  Worker = {}
end

function Worker:Worker1(vPos, hOwner, unitName)
  local worker = CreateUnitByName(unitName, vPos + VECTOR_BUMP, true, nil, nil, hOwner:GetTeam())
  worker:SetControllableByPlayer(hOwner:GetPlayerOwnerID() + 1, true)  
  worker:SetHullRadius(8)

  worker.inTriggerZone = true -- Flag set true if worker is near trees

  worker.treepos = nil
  worker.workTimer = DoUniqueString("WorkTimer")
  worker.pos = worker:GetAbsOrigin()
  worker.moving = false
  worker.maxLumber = UNIT_KV.worker_t1.MaximumLumber
  worker.housePos = nil

  Timers:CreateTimer(function()
  	if worker.pos ~= worker:GetAbsOrigin() then
  		local ability = worker:FindAbilityByName("harvest_channel")
  		if (ability:IsChanneling()) then
  			ability:SetChanneling(false)
  		end
  		
  		worker.moving = true
  		worker.pos = worker:GetAbsOrigin()
  	else
  		worker.moving = false
  	end
  	return 0.1
  end)

	function worker:Think()

		worker.generationTimer = 
		Timers:CreateTimer(function ()

			if not worker:IsAlive() then
				return nil
			end

			-- Check if the worker is in the trigger zone and not moving
			-- Additonally, store this location for the next trip
			local carryTotal= worker:FindAbilityByName("carrying_lumber")
			local currentLumber = worker:GetModifierStackCount("modifier_carrying_lumber", carryTotal)

			if (worker.inTriggerZone and worker.moving == false and currentLumber < worker.maxLumber) then
				worker.treepos = worker:GetAbsOrigin()
				local ability = worker:FindAbilityByName("harvest_channel")

				-- If they are not working, start them working
				if (ability:IsChanneling() == false) then
					worker:CastAbilityNoTarget(ability, worker:GetPlayerOwnerID() )
					local chopTime = ability:GetChannelTime()

					-- Timer that increments the lumber stack count
					Timers:CreateTimer(worker.workTimer,{
							endTime = chopTime,
							callback = function()
								worker:SetModifierStackCount("modifier_carrying_lumber", carryTotal, (currentLumber + 1))
								ability:SetChanneling(false)
								worker.housePos = nil

								return nil
							end})
				end
			end


			-- If the worker has all the lumber they can carry, dump it at the nearest house and update the UI
			if (currentLumber == worker.maxLumber) then
				
				-- Find all dota creatures, check if they can recieve lumber and that they are owned by the correct player
				-- This function is relativly expensive so we only call it when needed.
				if (worker.housePos == nil) then
					local drop = Entities:FindByModel(nil, "models/house1.vmdl")
					local minDist = 9999999
					local bestDrop = nil
					while drop ~= nil do
						if drop:GetPlayerOwnerID() == worker:GetPlayerOwnerID() then
							local workerV = worker:GetAbsOrigin()
							local testDrop = drop:GetAbsOrigin()

							-- Dirty distance function, avoid sqrt as it's expensive.
							local dist = ((workerV.x - testDrop.x) ^ 2 + (workerV.y - testDrop.y) ^ 2 + (workerV.z - testDrop.z) ^ 2)
							if (dist < minDist) then
								bestDrop = drop
								minDist = dist
							end
						end
						drop = Entities:FindByModel(drop, "models/house1.vmdl")
					end
					worker.housePos = bestDrop:GetAbsOrigin()
					worker:MoveToPosition(worker.housePos)
				end

				-- Drop lumber off at the house and alert Flash then move back to the tree
				if Entities:FindByModelWithin(nil, "models/house1.vmdl", worker:GetAbsOrigin(), 180) ~= nil then
					local pfxPath = string.format("particles/msg_heal.vpcf", "heal")
					local pidx = ParticleManager:CreateParticle("particles/msg_heal.vpcf", PATTACH_ABSORIGIN_FOLLOW, worker)

					local digits = 0
					local number = currentLumber
					if number ~= nil then
						digits = #tostring(number)
					end

					digits = digits + 1

					ParticleManager:SetParticleControl(pidx, 1, Vector(0, tonumber(number), tonumber(nil)))
					ParticleManager:SetParticleControl(pidx, 2, Vector(1, digits, 0))
					ParticleManager:SetParticleControl(pidx, 3, Vector(0, 255, 0))

					local pid = worker:GetPlayerOwnerID() + 1
					WOOD[pid] = WOOD[pid] + currentLumber

					FireGameEvent('vamp_wood_changed', { player_ID = pid, wood_total = WOOD[pid]})
					print(WOOD[pid])

					worker:SetModifierStackCount("modifier_carrying_lumber", carryTotal, 0)
					worker:MoveToPosition(worker.treepos)
				end
			end
			return .1
		end)
	end
	return worker
end

function AtTree(keys)
	local unit = keys.activator
	unit.treepos = unit:GetAbsOrigin()
	unit.inTriggerZone = true
	unit:Think()
end

function LeftTree(keys)
	local unit = keys.activator
	unit.inTriggerZone = false
end