VECTOR_BUMP = Vector(50, 0, 0)

if Worker == nil then
  Worker = {}
end

function Worker:Worker1(vPos, hOwner)
  local worker = CreateUnitByName("worker_t1", vPos + VECTOR_BUMP, true, nil, nil, hOwner:GetTeam())
  worker:SetControllableByPlayer(hOwner:GetPlayerOwnerID() + 1, true)
  --worker:FindAbilityByName("harvest_t1"):SetLevel(1)
  worker:SetHullRadius(8)

  worker.inTriggerZone = true -- Flag set true if worker is near trees

  worker.treepos = nil
  worker.workTimer = DoUniqueString("WorkTimer")
  worker.pos = worker:GetAbsOrigin()
  worker.moving = false

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

	-- Check if worker is stationary in a tree zone

	function worker:Think()

		worker.generationTimer = 
		Timers:CreateTimer(function ()

			if not worker:IsAlive() then
				return nil
			end

			-- Check if the worker is in the trigger zone and not moving
			if (worker.inTriggerZone and worker.moving == false) then
				local ability = worker:FindAbilityByName("harvest_channel")
				if (ability:IsChanneling() == false) then
					
					ability:SetChanneling(true)
					
					local chopTime = ability:GetChannelTime()

					-- Timer that increments the lumber stack count
					Timers:CreateTimer(worker.workTimer,{
							endTime = chopTime,
							callback = function()
								local carryTotal= worker:FindAbilityByName("carrying_lumber")
								local currentLumber = worker:GetModifierStackCount("modifier_carrying_lumber", carryTotal)
								worker:SetModifierStackCount("modifier_carrying_lumber", carryTotal, (currentLumber + 1))
								ability:SetChanneling(false)

								return nil
							end})
				end
			end


			--[[TODO: check if the player who owns the house is the same player who owns the worker.
			if worker:GetMana() >= 1 then
				if Entities:FindByModelWithin(nil, "models/house1.vmdl", worker:GetAbsOrigin(), 120) ~= nil then
					print("found house")
					local pfxPath = string.format("particles/msg_fx/msg_%s.vpcf", "heal")
					local pidx = ParticleManager:CreateParticle(pfxPath, PATTACH_ABSORIGIN_FOLLOW, worker)

					local digits = 0
					local number = worker:GetMana()
					if number ~= nil then
						digits = #tostring(number)
					end

					digits = digits + 1

					ParticleManager:SetParticleControl(pidx, 1, Vector(0, tonumber(number), tonumber(nil)))
					ParticleManager:SetParticleControl(pidx, 2, Vector(1, digits, 0))
					ParticleManager:SetParticleControl(pidx, 3, Vector(0, 255, 0))

					local pid = worker:GetPlayerOwnerID() + 1
					WOOD[pid] = WOOD[pid] + worker:GetMana()
					print(pid)

					FireGameEvent('vamp_wood_changed', { player_ID = pid, wood_amount = worker:GetMana()})

					worker:SetMana(0)
					worker:MoveToPosition(worker.treepos)
				end
			end]]--

			return .1
		end)
	end

  function worker:Harvest()
		local harvest = worker:FindAbilityByName("harvest_channel")
		worker:CastAbilityNoTarget(harvest, worker:GetPlayerOwnerID())
	  end
  return worker
end

function AtTree(keys)
	print("At the tree")
	local unit = keys.activator
	unit.treepos = unit:GetAbsOrigin()
	unit.inTriggerZone = true
	unit:Think()
end

function LeftTree(keys)
	print("Left the tree")
	local unit = keys.activator
	unit.inTriggerZone = false
end

function TreeLoop(keys)
	print("In the meme loop?")
	local unit = keys.caster
	local harvest = unit:FindAbilityByName("harvest_channel")
	local phase = unit:FindAbilityByName("harvest_phase")

	if unit:GetMana() < 1 then
		unit:CastAbilityNoTarget(harvest, unit:GetPlayerOwnerID())
		--unit:CastAbilityNoTarget(phase, unit:GetPlayerOwnerID())
	else
		unit:InterruptChannel()

		local drop = Entities:FindByModel(nil, "models/house1.vmdl")

		unit:MoveToPosition(drop:GetAbsOrigin())
		--test = Entities:FindByName(nil, "npc_dota_creature")
		--print(test)
		--DeepPrintTable(test)
	end
end
