VECTOR_BUMP = Vector(50, 0, 0)

if Worker == nil then
  Worker = {}
end

function Worker:Worker1(vPos, hOwner)
  local worker = CreateUnitByName("worker_t1", vPos + VECTOR_BUMP, true, nil, nil, hOwner:GetTeam())
  worker:SetControllableByPlayer(hOwner:GetPlayerOwnerID() + 1, true)
  worker:FindAbilityByName("harvest_t1"):SetLevel(1)
  worker:SetMana(0)
  worker:SetHullRadius(8)

  worker.maxmana = 10
  worker.treepos = nil

  worker.think = true

	function worker:Think()

		worker.generationTimer = 
		Timers:CreateTimer(function ()

			if not worker:IsAlive() then
				return nil
			end

			--TODO: check if the player who owns the house is the same player who owns the worker.
			if worker:GetMana() >= 1 then
				if Entities:FindByModelWithin(nil, "models/house1.vmdl", worker:GetAbsOrigin(), 120) ~= nil then
					print("found")
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
			end

			return .1
		end)
	end

  function worker:Harvest()
  	--print(unit.harvesting)
	local harvest = worker:FindAbilityByName("harvest_channel")
	worker:CastAbilityNoTarget(harvest, worker:GetPlayerOwnerID())
	--("npc_dota_creature", unit:GetAbsOrigin(), 10000000)
	--[[
	local vector = Vector(house:GetAbsOrigin())
	print(vector)
	unit:MoveToPosition(vector)]]
  	-- body
  end

  return worker
end

function AtTree(keys)
	local unit = keys.activator
	unit:Harvest()
	unit.treepos = unit:GetAbsOrigin()
	local phase = unit:FindAbilityByName("harvest_phase")
	--unit:CastAbilityNoTarget(phase, unit:GetPlayerOwnerID())
end

function TreeLoop(keys)
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
