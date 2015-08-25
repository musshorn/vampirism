  --[[ Worker AI v3, Worker Stacking.
]]

VECTOR_BUMP = Vector(50, 0, 0)

if Worker == nil then
  Worker = {}
end

function Worker:Worker1(vPos, hOwner, unitName, isHero)
  local worker = nil
  local pID = hOwner:GetMainControllingPlayer()
  if isHero then
    worker = CreateHeroForPlayer(unitName, PlayerResource:GetPlayer(pID))
    worker:SetAbilityPoints(0)
    for i=0, worker:GetAbilityCount() do
      local ability = worker:GetAbilityByIndex(i)
      if ability ~= nil then
        ability:SetLevel(1)
      end
    end
    local newPos = FindGoodSpaceForUnit(worker, vPos, 200, 50)
    if newPos ~= nil then
      worker:SetAbsOrigin(newPos)
    end
  else
    worker = CreateUnitByName(unitName, vPos + VECTOR_BUMP, true, nil, nil, hOwner:GetTeam())
  end
  worker:SetControllableByPlayer(hOwner:GetMainControllingPlayer() , true)

  -- If health techs have been researched, apply them
  worker:SetMaxHealth(UNIT_KV[pID][unitName].StatusHealth)
  worker:SetHealth(worker:GetMaxHealth())
  worker:SetHullRadius(9)
  
  worker.workTimer = DoUniqueString("WorkTimer")
  worker.moveTimer = DoUniqueString("MoveTimer")
  worker.pos = worker:GetAbsOrigin()
  worker.moving = false
  worker.housePos = nil

  worker.skipTicks = 0 -- If this is > 0 the worker will ignore this many ticks
  worker.stackAbility = worker:FindAbilityByName('worker_stack')
  worker.stackAbility:ApplyDataDrivenModifier( worker, worker, "modifier_worker_stack", {})
  worker:SetModifierStackCount("modifier_worker_stack", worker.stackAbility, WORKER_STACKS[unitName])
  worker.currentStacks = WORKER_STACKS[unitName]
  worker.ability = worker:FindAbilityByName("find_lumber")
  worker.harvest = worker:FindAbilityByName("harvest_channel")
  worker.playerID = pID
  worker.unitName = worker:GetUnitName()
  worker.carryTotal = worker:FindAbilityByName("carrying_lumber")
  worker.dropAbiltiy = worker:FindAbilityByName("drop_lumber")
  worker.currentLumber = 0

  --attach fire spawn particles.
  if unitName == 'worker_t4' then
    local wAmb = ParticleManager:CreateParticle("particles/units/heroes/hero_invoker/invoker_forge_spirit_ambient.vpcf", PATTACH_POINT_FOLLOW , worker)
    local wPos = worker:GetAbsOrigin()
    ParticleManager:SetParticleControlEnt(wAmb, 0, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", wPos, true)
    ParticleManager:SetParticleControlEnt(wAmb, 1, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", wPos, true)
  end

  if UNIT_KV[pID][unitName].AnnounceUnit == 1 and UNIQUE_TABLE[unitName] == nil then
    local playerName = PlayerResource:GetPlayerName(worker:GetMainControllingPlayer())
    GameRules:SendCustomMessage(ColorIt(playerName, IDToColour(pID))..' has completed a '..UNIT_NAMES[unitName]..'!', 0, 1)
    UNIQUE_TABLE[unitName] = pID
  end

  worker.ability:ToggleAutoCast() 

  Timers:CreateTimer(worker.moveTimer, {callback = function()
    if worker:IsNull() then
      return nil
    end

    if worker.pos ~= worker:GetAbsOrigin() then
      worker.moving = true
      worker.pos = worker:GetAbsOrigin()
    else
      worker.moving = false
    end

    return 0.1
  end})

  function worker:Think()

    worker.thinking = true
    Timers:CreateTimer(function ()
      if worker:IsNull() then
        return nil
      end

      -- Check all possible values for nils.
      if tostring(worker.workTimer) == 'nil' then SendNil( worker,  "worker.workTimer" ) end
      if tostring(worker.moveTimer) == 'nil' then SendNil( worker, "worker.moveTimer" ) end
      if tostring(worker.pos) == 'nil' then SendNil( worker, "worker.pos" ) end
      if tostring(worker.moving) == 'nil' then SendNil( worker, "worker.moving" ) end
      if tostring(worker.skipTicks) == 'nil' then SendNil( worker, "worker.skipTicks" ) end
      if tostring(worker.stackAbility) == 'nil' then SendNil( worker, "worker.stackAbility" ) end
      if tostring(worker.currentStacks) == 'nil' then SendNil( worker, "worker.currentStacks" ) end
      if tostring(worker.ability) == 'nil' then SendNil( worker, "worker.ability" ) end
      if tostring(worker.harvest) == 'nil' then SendNil( worker, "worker.harvest" ) end
      if tostring(worker.playerID) == 'nil' then SendNil( worker, "worker.playerID" ) end
      if tostring(worker.unitName) == 'nil' then SendNil( worker, "worker.unitName" ) end
      if tostring(worker.carryTotal) == 'nil' then SendNil( worker, "worker.carryTotal" ) end
      if tostring(worker.dropAbiltiy) == 'nil' then SendNil( worker, "worker.dropAbiltiy" ) end
      if tostring(worker.currentLumber) == 'nil' then SendNil( worker, "worker.currentLumber" ) end
      if tostring(LUMBER_DROPS) == 'nil' then SendNil( worker, "LUMBER_DROPS" ) end



      worker.currentLumber = worker:GetModifierStackCount("modifier_carrying_lumber", worker.carryTotal)
      if worker.ability:GetAutoCastState() then 
        if (worker.moving == false and worker.currentLumber < UNIT_KV[worker.playerID][worker.unitName].MaximumLumber * worker.currentStacks) then
          -- If they are not working, start them working
          if (worker.harvest:IsChanneling() == false) then
            local tree = Entities:FindByClassnameNearest("ent_dota_tree", worker:GetAbsOrigin(), 1000)
            if tostring(tree) == 'nil' then SendNil(worker,  "tree" ) end
            worker:CastAbilityOnTarget(tree, worker.harvest, worker:GetMainControllingPlayer())
          end
        end
      end

      -- If the worker has all the lumber they can carry, dump it at the nearest house and update the UI
      if (worker.currentLumber >= UNIT_KV[worker.playerID][worker.unitName].MaximumLumber * worker.currentStacks) then
        -- This occurs sometimes from sharpened hatchets, resets to default if it goes over.
        if worker.currentLumber > UNIT_KV[worker.playerID][worker.unitName].MaximumLumber * worker.currentStacks then
          worker:SetModifierStackCount("modifier_carrying_lumber", worker.carryTotal, UNIT_KV[worker.playerID][worker.unitName].MaximumLumber * worker.currentStacks)
        end
        -- Search for the nearest unit that can recieve lumber and is owned by the correct player
        if worker.housePos == nil then
          local bestDrop = nil
          local bestDist = 99999
          for k, v in pairs(LUMBER_DROPS) do
            if tostring(v) == 'nil' then SendNil(LUMBER_DROPS, "LUMBER_DROPS." .. tostring(k) .. ".v" ) end
            local dist = CalcDistanceBetweenEntityOBB(worker, v)
            if dist < bestDist and v:GetMainControllingPlayer() == worker:GetMainControllingPlayer() then
              bestDrop = v
              bestDist = dist
            end
          end
          if bestDrop ~= nil then
            worker.housePos = bestDrop:GetAbsOrigin()
            worker:CastAbilityOnTarget(bestDrop, worker.dropAbiltiy, worker:GetMainControllingPlayer())
          else
            worker:Stop()
          end
        end
      end
      return 0.1
    end)
  end

  worker:Think()

  return worker
end

function FindLumber( keys )
  local worker = keys.caster
  local pID = worker:GetMainControllingPlayer()
  local unitName = worker:GetUnitName()

  worker.currentLumber = worker:GetModifierStackCount("modifier_carrying_lumber", worker.carryTotal)
  if (worker.moving == false and worker.currentLumber < UNIT_KV[pID][unitName].MaximumLumber * worker.currentStacks) then

    -- If they are not working, start them working
    if (worker.harvest:IsChanneling() == false) then
      local tree = Entities:FindByClassnameNearest("ent_dota_tree", worker:GetAbsOrigin(), 1000)
      if tostring(tree) == 'nil' then SendNil( worker, "tree" ) end
      worker:CastAbilityOnTarget(tree, ability, worker:GetMainControllingPlayer())
    end
  end
end

-- Fired when the harvest_channel ability has finished channelling
function ChoppedLumber( keys )
  local worker = keys.caster
  worker.currentLumber = worker:GetModifierStackCount("modifier_carrying_lumber", worker.carryTotal)
  local pID = worker:GetMainControllingPlayer()
  local unitName = worker:GetUnitName()

  if worker.currentLumber + UNIT_KV[pID][unitName].LumberPerChop <= UNIT_KV[pID][unitName].MaximumLumber * worker.currentStacks then
    worker:SetModifierStackCount("modifier_carrying_lumber", worker.carryTotal, (worker.currentLumber + UNIT_KV[pID][unitName].LumberPerChop * worker.currentStacks))
    worker.housePos = nil
  end
end

-- Stop the worker getting stuck if you want to get them away from the trees
function Interrupted( keys )
  local worker = keys.caster
  worker.skipTicks = 3
end

function DropLumber( keys )
  local worker = keys.caster
  worker.currentLumber = worker:GetModifierStackCount("modifier_carrying_lumber", worker.carryTotal)
  local targetHouse = nil
  local searchRange = 180

  if HOST_LOW_BANDWIDTH == true then
    searchRange = 300
  end

  for k, v in pairs(LUMBER_DROPS) do
    if CalcDistanceBetweenEntityOBB(worker, v) < searchRange and v:GetMainControllingPlayer() == worker:GetMainControllingPlayer() then
      targetHouse = v
    end
  end

  if targetHouse ~= nil then
    if worker.currentLumber > 0 then
      local pfxPath = string.format("particles/msg_fx/msg_damage.vpcf", pfx)
      local pidx = ParticleManager:CreateParticle(pfxPath, PATTACH_ABSORIGIN_FOLLOW, worker)

      local digits = 0
      local number = worker.currentLumber
      if number ~= nil then
        digits = #tostring(number)
      end

      digits = digits + 1

      ParticleManager:SetParticleControl(pidx, 1, Vector(0, tonumber(number), 0))
      ParticleManager:SetParticleControl(pidx, 2, Vector(1, digits, 0))
      ParticleManager:SetParticleControl(pidx, 3, Vector(0, 255, 0))

      local pid = worker:GetMainControllingPlayer() 
      ChangeWood(pid, worker.currentLumber)

      worker:SetModifierStackCount("modifier_carrying_lumber", worker.carryTotal, 0)
      worker.currentLumber = 0
      if worker.ability:GetAutoCastState() then
        worker:CastAbilityNoTarget(ability, pid)
      end
    end
  end
end

function StackAttacked( keys )
  local caster = keys.caster
  caster:SetHealth(caster:GetMaxHealth())
end

function SendNil(state, sName )
  if state.loggedIssue == nil then
    state.loggedIssue = true
    local requestTable = state
    requestTable.ErrorTag = sName
    SendDebugTable(requestTable)
  end
end