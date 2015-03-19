VECTOR_BUMP = Vector(50, 0, 0)

if Worker == nil then
  Worker = {}
end

function Worker:Worker1(vPos, hOwner, unitName)
  local worker = CreateUnitByName(unitName, vPos + VECTOR_BUMP, true, nil, nil, hOwner:GetTeam())
  local pID = hOwner:GetMainControllingPlayer()
  worker:SetControllableByPlayer(hOwner:GetMainControllingPlayer() , true)

  -- If health techs have been researched, apply them
  worker:SetMaxHealth(UNIT_KV[pID][unitName].StatusHealth)
  worker:SetHealth(worker:GetMaxHealth())
  worker:SetHullRadius(8)
  
  worker.thinking = false
  worker.inTriggerZone = true -- Flag set true if worker is near trees

  worker.treepos = nil
  worker.workTimer = DoUniqueString("WorkTimer")
  worker.pos = worker:GetAbsOrigin()
  worker.moving = false
  worker.housePos = nil

  worker.skipTicks = 0 -- If this is > 0 the worker will ignore this many ticks


  Timers:CreateTimer(function()
  	if worker.pos ~= worker:GetAbsOrigin() then
  		worker.moving = true
  		worker.pos = worker:GetAbsOrigin()
  	else
  		worker.moving = false
  	end

  	return 0.1
  end)

	function worker:Think()

    worker.thinking = true
		Timers:CreateTimer(function ()
			if not worker:IsAlive() then
				return nil
			end
      if worker.skipTicks > 0 then
        worker.skipTicks = worker.skipTicks - 1
        return 0.1
      end

			-- Check if the worker is in the trigger zone and not moving
			-- Additonally, store this location for the next trip
			local carryTotal= worker:FindAbilityByName("carrying_lumber")
			local currentLumber = worker:GetModifierStackCount("modifier_carrying_lumber", carryTotal)
			if (worker.inTriggerZone and worker.moving == false and currentLumber < UNIT_KV[pID][unitName].MaximumLumber) then
				worker.treepos = worker:GetAbsOrigin()
				local ability = worker:FindAbilityByName("harvest_channel")

				-- If they are not working, start them working
				if (ability:IsChanneling() == false) then
          local tree = Entities:FindByClassnameNearest("ent_dota_tree", worker:GetAbsOrigin(), 200)
          worker:CastAbilityOnTarget(tree, ability, worker:GetMainControllingPlayer())
				end
			end


			-- If the worker has all the lumber they can carry, dump it at the nearest house and update the UI
			if (currentLumber == UNIT_KV[pID][unitName].MaximumLumber) then
		
				-- Search for the nearest unit that can recieve lumber and is owned by the correct player
				if (worker.housePos == nil) then
					local bestDrop = nil
          local bestDist = 99999
          for k, v in pairs(LUMBER_DROPS) do
            local dist = CalcDistanceBetweenEntityOBB(worker, v)
            if dist < bestDist and v:GetMainControllingPlayer() == worker:GetMainControllingPlayer() then
              bestDrop = v
              bestDist = dist
            end
          end
					worker.housePos = bestDrop:GetAbsOrigin()
          local drop_ability = worker:FindAbilityByName("drop_lumber")
          worker:CastAbilityOnTarget(bestDrop, drop_ability,  worker:GetMainControllingPlayer())
        end
			end
			return .1
		end)
	end

  return worker
end

-- Fired when the worker is near trees
function AtTree(keys)
	local unit = keys.activator
	unit.treepos = unit:GetAbsOrigin()
	unit.inTriggerZone = true
  if unit.thinking == false then
	 unit:Think()
  end
end

-- Fired when the worker leaves the trees
function LeftTree(keys)
	local unit = keys.activator
	unit.inTriggerZone = false
end

-- Fired when the harvest_channel ability has finished channelling
function ChoppedLumber( keys )
  local worker = keys.caster
  local carryTotal= worker:FindAbilityByName("carrying_lumber")
  local currentLumber = worker:GetModifierStackCount("modifier_carrying_lumber", carryTotal)
  local pID = worker:GetMainControllingPlayer()
  local unitName = worker:GetUnitName()

  worker:SetModifierStackCount("modifier_carrying_lumber", carryTotal, (currentLumber + UNIT_KV[pID][unitName].LumberPerChop))
  worker.housePos = nil
end

-- Stop the worker getting stuck if you want to get them away from the trees
function Interrupted( keys )
  local worker = keys.caster
  worker.skipTicks = 3
end

function DropLumber( keys )
  local worker = keys.caster
  local carryTotal = worker:FindAbilityByName("carrying_lumber")
  local currentLumber = worker:GetModifierStackCount("modifier_carrying_lumber", carryTotal)
  local targetHouse = nil

  for k, v in pairs(LUMBER_DROPS) do
    if CalcDistanceBetweenEntityOBB(worker, v) < 180 and v:GetMainControllingPlayer() == worker:GetMainControllingPlayer() then
      targetHouse = v
    end
  end

  if targetHouse ~= nil then
    if currentLumber > 0 then
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
    end
  end
end