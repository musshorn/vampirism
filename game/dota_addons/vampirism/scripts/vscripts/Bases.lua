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
    GameRules:SendCustomMessage(ColorIt(name, IDToColour(pID)) .. " has claimed base " .. baseID, 0, 0)
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
          WOOD[pID] = WOOD[pID] + lumberCost
          FireGameEvent('vamp_wood_changed', { player_ID = pID, wood_total = WOOD[pID]})
        end

        if goldCost ~= nil then
          PlayerResource:ModifyGold(pID, goldCost, true, 9)
          FireGameEvent('vamp_gold_changed', { player_ID = pID, gold_total = PlayerResource:GetGold(pID)})
        end

        FireGameEvent( 'custom_error_show', { player_ID = pID, _error = name .. ' has claimed this base!' } )
        unit:RemoveBuilding(true)
      else
        unit.inBase = baseID
      end
    end
  end
end
