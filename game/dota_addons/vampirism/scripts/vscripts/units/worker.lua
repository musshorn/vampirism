VECTOR_BUMP = Vector(50, 0, 0)

if Worker == nil then
  Worker = {}
end

function Worker:Worker1(vPos, hOwner, unitName)
  local worker = CreateUnitByName(unitName, vPos + VECTOR_BUMP, true, nil, nil, hOwner:GetTeam())
  worker:SetControllableByPlayer(hOwner:GetMainControllingPlayer() , true)  
  worker:SetHullRadius(8)
  worker.thinking = false
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

    worker.thinking = true
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
					worker:CastAbilityNoTarget(ability, worker:GetMainControllingPlayer())
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
						if drop:GetMainControllingPlayer()  == worker:GetMainControllingPlayer()  then
							local workerV = worker:GetAbsOrigin()
							local testDrop = drop:GetAbsOrigin()

							local dist = CalcDistanceBetweenEntityOBB(worker, drop)
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

				--[[ Drop lumber off at the house and alert Flash then move back to the tree
				Proof of concept, timer checks to ensure that a worker is facing the house before
				it drops off lumber. So endTime needs to be based off the units turn speed, not sure
				what that number should actually be but .25 is working normally.
				Currently using .25 under the assumption that its turn rate of .5 means 360 in
				one second.]]
				Timers:CreateTimer({
					endTime = .25,
					callback = function ()
						if Entities:FindByModelWithin(nil, "models/house1.vmdl", worker:GetAbsOrigin(), 180) ~= nil and worker:GetModifierStackCount("modifier_carrying_lumber", carryTotal) > 0 then
							print(worker:GetModifierStackCount("modifier_carrying_lumber", carryTotal))
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

							local pid = worker:GetMainControllingPlayer() 
							WOOD[pid] = WOOD[pid] + currentLumber

							FireGameEvent('vamp_wood_changed', { player_ID = pid, wood_total = WOOD[pid]})
							print(WOOD[pid])

							worker:SetModifierStackCount("modifier_carrying_lumber", carryTotal, 0)
							worker:MoveToPosition(worker.treepos)
							return nil
						end
					end
					})
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
  if unit.thinking == false then
	 unit:Think()
  end
end

function LeftTree(keys)
	local unit = keys.activator
	unit.inTriggerZone = false
end

function ChoppedLumber( keys )
  local worker = keys.caster
  local carryTotal= worker:FindAbilityByName("carrying_lumber")
  local currentLumber = worker:GetModifierStackCount("modifier_carrying_lumber", carryTotal)

  worker:SetModifierStackCount("modifier_carrying_lumber", carryTotal, (currentLumber + 1))
  worker.housePos = nil
end