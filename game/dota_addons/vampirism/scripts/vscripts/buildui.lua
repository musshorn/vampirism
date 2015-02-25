playerCasters = {}

if BuildUI == nil then
    BuildUI = {}
    BuildUI.__index = BuildUI
end

function BuildUI:Init()
  Convars:RegisterCommand("buildui_chosen", function(name, p)
   local cmdPlayer = Convars:GetCommandClient()
   print(cmdPlayer:GetPlayerID()) 
   if cmdPlayer then
     print('this happened')
      local playerID = cmdPlayer:GetPlayerID()
      BuildUI:BuildChosen(p, playerID)
      return 0
    end
  end, "building chosen", 0)  

  Convars:RegisterCommand("check_select", function(name, p)
    local cmdPlayer = Convars:GetCommandClient()
    print('ITS CRAAAZY')
    if cmdPlayer then
        print(p)
        index = tonumber(p)
        print(index)
        local ent = EntIndexToHScript(index) 
        print(ent:GetUnitName())
    end
  end, "checking selected unit", 0)
end

function CallMenu(keys)
    local caster = keys.caster
    local playerID = caster:GetPlayerOwnerID()

    FireGameEvent("build_ui_called", {player_ID = playerID, builder = caster:GetUnitName()})

    --ONLY FOR TESTING IN SINGLE, NOT WORKING IN MULTIPLAYER.
    --SHOULD BE playerCasters[playerID] = caster
    playerCasters[0] = caster

end

function BuildUI:BuildChosen(building, playerID)

    --ONLY FOR TESTING IN SINGLE, NOT WORKING IN MULTIPLAYER.
    --SHOULD BE local caster = playerCasters[playerID]
    local caster = playerCasters[0]
    local ability = caster:FindAbilityByName(building)

    caster:CastAbilityNoTarget(ability, 0)
end