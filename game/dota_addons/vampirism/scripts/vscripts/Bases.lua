function EnterBase( keys )
  local unit = keys.activator
  local ent = keys.caller
  local pID = unit:GetMainControllingPlayer()

  local baseID = ent:Attribute_GetIntValue("BaseID", 0)

  if unit:GetUnitName() == "human_flag" then

    -- Check claim to this base
    for k, v in pairs(Bases.Owners) do
      if type(v) ~= "function" then
        if v.BaseID == baseID then
          FireGameEvent( 'custom_error_show', { player_ID = pID, _error = "This base has already been claimed!" } )
          return
        end
      end
    end

    -- Remove any existing claims to a base (if any)
    Bases.Owners[pID] = {}   

    -- Add claim to this base
    Bases.Owners[pID].BaseID = baseID
    Bases.Owners[pID].SharedBuilders = {}

    local name = PlayerResource:GetPlayerName(pID)
    Notifications:BottomToTeam(unit:GetTeam(), name .. " has claimed base " .. baseID, 5, nil, {color="yellow", ["font-size"]="24px"})
  else

    -- Check the unit is a building
    if unit:HasAbility("is_a_building") then


      -- Check the unit is allowed to be built in this base
      local valid = true
      local ownerPID = 0

      for k, v in pairs(Bases.Owners) do
        if type(v) ~= "function" then
          if v.BaseID == baseID and v.SharedBuilders[pID] == nil and k ~= pID then
            valid = false
          end
          if v.BaseID == baseID then
            ownerPID = k
          end
        end
      end

      -- Remove it if not, and refund the cost
      if valid == false then
        local name = PlayerResource:GetPlayerName(ownerPID)
        local lumberCost = unit.buildingTable.LumberCost
        local goldCost = unit.buildingTable.GoldCost

        if lumberCost ~= nil then
          ChangeWood(pID, lumberCost)
        end

        if goldCost ~= nil then
          ChangeGold(pID, goldCost)
        end

        FireGameEvent( 'custom_error_show', { player_ID = pID, _error = name .. ' has claimed this base!' } )
        unit:RemoveBuilding(true)
      else
        unit.inBase = baseID
      end
    end
  end
end

-- Called when a unit enters the center of the map. (Vampire's home).
function InVampireHome( keys )
  local unit = keys.activator
  unit.onBlight = true

  if unit:GetUnitName() == 'merc_meat_carrier' then
    unit:AddNewModifier(unit, nil, 'modifier_invulnerable', {})
  end
end

-- Called when a unit leaves the center of the map.
function OutVampireHome( keys )
  local unit = keys.activator
  unit.onBlight = false

  if unit:GetUnitName() == 'merc_meat_carrier' then
    if unit:HasModifier('modifier_invulnerable') then
      unit:RemoveModifierByName('modifier_invulnerable')
    end
  end
end

-- List of vectors that a teleport exits at.
TELEPORT_EXITS = {
  Vector(-2656, 4128, 272),
  Vector(7840, 2400, 400),
  Vector(-4704, -5600, 528),
  Vector(7968, -5536, 16),
  Vector(-4640, 6112, 160)
}

-- Called when a unit enters a teleporter.
function BaseTeleport( keys )
  local unit = keys.activator
  local trigger = keys.caller
  local teleID = trigger:Attribute_GetIntValue("tele_ID", 0)

  if unit:HasAbility('is_a_building') ~= true and teleID ~= 5 then
    FindClearSpaceForUnit(unit, TELEPORT_EXITS[teleID], true)
  end
  if unit:HasAbility('is_a_building') ~= true and teleID == 5 and unit:GetTeam() ~= DOTA_TEAM_BADGUYS then
    FindClearSpaceForUnit(unit, TELEPORT_EXITS[teleID], true)
  end
end