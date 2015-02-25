abilTemp = {}
OUT_OF_BOUNDS = Vector(-8099.68798828125,-7962.6953125,256.0000610351563)
silencer = CreateUnitByName("util_silencer", OUT_OF_BOUNDS, false, nil, nil, 0)

function build( keys )
  local player = keys.caster:GetPlayerOwner()
  local pID = player:GetPlayerID()
  local returnTable = BuildingHelper:AddBuilding(keys)

  local tempAbilities = {}

  -- handle errors if any
  if TableLength(returnTable) > 0 then
    --PrintTable(returnTable)
    if returnTable["error"] == "not_enough_resources" then
      local resourceTable = returnTable["resourceTable"]
      -- resourceTable is like this: {["lumber"] = 3, ["stone"] = 6}
      -- so resourceName = cost-playersResourceAmount
      -- the api searches for player[resourceName]. you need to keep this number updated
      -- throughout your game
      local firstResource = nil
      for k,v in pairs(resourceTable) do
        if not firstResource then
          firstResource = k
        end
        print("P:" .. pID .. " needs " .. v .. " more " .. k .. ".")
      end
      local capitalLetter = firstResource:sub(1,1):upper()
      firstResource = capitalLetter .. firstResource:sub(2)
      FireGameEvent( 'custom_error_show', { player_ID = pID, _error = "Not enough " .. firstResource .. "." } )
      return
    end
  end

  keys:OnConstructionStarted(function(unit)
    --print("Started construction of " .. unit:GetUnitName())
    -- Unit is the building be built.
    -- Play construction sound
    -- FindClearSpace for the builder
    FindClearSpaceForUnit(keys.caster, keys.caster:GetAbsOrigin(), true)
    --Silence the unit while it is being built
    unit:AddNewModifier(silencer, nil, "modifier_silence", {duration=10000})
    unit:SetMana(0)
  end)

  keys:OnConstructionCompleted(function(unit)
    --print("Completed construction of " .. unit:GetUnitName())
    -- Play construction complete sound.  
    -- Give building its abilities
    -- add the mana
    unit:SetMana(unit:GetMaxMana())

    
    House1:Init(unit)

    -- Check if the building will create units, if so, give it a unit creation timer
    if UNIT_KV[unit.unitName].SpawnsUnits == "true" then
      House1:UnitSpawner()
    end

    -- If the building provides food, how much? Also alert the UI for an update
    if UNIT_KV[unit.unitName].ProvidesFood ~= nil then
      local food = tonumber(UNIT_KV[unit.unitName].ProvidesFood)
      if (TOTAL_FOOD[pID] < 300) then
        TOTAL_FOOD[pID] = TOTAL_FOOD[pID] + food
        print(TOTAL_FOOD[pID])
        FireGameEvent("vamp_food_cap_changed", { player_ID = pID, food_cap = TOTAL_FOOD[pID]})
      end
    end

    --Remove Building Silence.
    if unit:HasModifier("modifier_silence") then
      unit:RemoveModifierByName("modifier_silence")
    end
  end)

  -- These callbacks will only fire when the state between below half health/above half health changes.
  -- i.e. it won't unnecessarily fire multiple times.
  keys:OnBelowHalfHealth(function(unit)
    print(unit:GetUnitName() .. " is below half health.")
  end)

  keys:OnAboveHalfHealth(function(unit)
    print(unit:GetUnitName() .. " is above half health.")
  end)

  --[[keys:OnCanceled(function()
    print(keys.ability:GetAbilityName() .. " was canceled.")
  end)]]

  -- Have a fire effect when the building goes below 50% health.
  -- It will turn off it building goes above 50% health again.
  keys:EnableFireEffect("modifier_jakiro_liquid_fire_burn")
end

function create_building_entity( keys )
  BuildingHelper:InitializeBuildingEntity(keys)
end

function harvest_t1(keys)
  local caster = keys.caster
  local point = keys.target:GetAbsOrigin()
  caster:MoveToPosition(point)
end

function human_blink(keys)
  --DeepPrintTable(keys)
  local caster = keys.caster
  local point = keys.target_points[1]

  if not GridNav:IsBlocked(point) then
    caster:SetAbsOrigin(point)
  end
end

function slayer_attribute_bonus(keys)
  local caster = keys.caster
  caster:SetBaseStrength(caster:GetBaseStrength() + 3)
  caster:SetBaseAgility(caster:GetBaseAgility() + 3)
  caster:SetBaseIntellect(caster:GetBaseIntellect() + 3)
end

function uitest(keys)
  local ability = keys.caster:FindAbilityByName("build_house_t1")
  local caster = keys.caster
  caster:CastAbilityOnPosition(Vector(1091.630737, -426.264648, 255.999939), ability, -1) 
  --[[ 
  FlashUtil:GetCursorWorldPos(caster:GetPlayerID(), function(pID, cursor_position)
  caster:CastAbilityOnPosition(cursor_position, ability, 0)
  print(cursor_position)
  end)
]]
end

function why( keys )
  print('does this happen')
end