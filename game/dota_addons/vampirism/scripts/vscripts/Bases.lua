BASE_OWNERSHIP = {}     -- Access by owner pID, has int value baseID and a table of shared builders pIDs

function EnterBase( keys )
  local unit = keys.activator
  local ent = keys.caller
  local pID = unit:GetMainControllingPlayer()

  local baseID = ent:Attribute_GetIntValue("BaseID", 0)

  if unit:GetUnitName() == "human_flag" then

    -- Check claim to this base
    for k, v in pairs(BASE_OWNERSHIP) do
      if v.BaseID == baseID then
        FireGameEvent( 'custom_error_show', { player_ID = pID, _error = "This base has already been claimed!" } )
        return
      end
    end

    -- Remove any existing claims to a base (if any)
    BASE_OWNERSHIP[pID] = {}   

    -- Add claim to this base
    BASE_OWNERSHIP[pID].BaseID = baseID
    BASE_OWNERSHIP[pID].SharedBuilders = {}

    local name = PlayerResource:GetPlayerName(pID)
    GameRules:SendCustomMessage(name .. " has claimed base " .. baseID, 0, 0) 
  else

    -- Check the unit is a building
    if unit:HasAbility("is_a_building") then


      -- Check the unit is allowed to be built in this base
      local valid = true

      for k, v in pairs(BASE_OWNERSHIP) do
        if v.BaseID == baseID and v.SharedBuilders[pID] == nil then
          valid = false
        end
      end

      -- Remove it if not
      if valid == false then
        FireGameEvent( 'custom_error_show', { player_ID = pID, _error = "You cannot build here! Ask for permission." } )
        unit:RemoveSelf()
      end
    end
  end
end