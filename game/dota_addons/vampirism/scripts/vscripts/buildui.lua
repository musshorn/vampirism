playerCasters = {}

if BuildUI == nil then
    BuildUI = {}
    BuildUI.__index = BuildUI
end

function BuildUI:Init()
  Convars:RegisterCommand("buildui_chosen", function(name, p)
   local cmdPlayer = Convars:GetCommandClient()
   --print(cmdPlayer:GetPlayerID()) 
   if cmdPlayer then
     --print('this happened')
      local playerID = cmdPlayer:GetPlayerID()
      BuildUI:BuildChosen(p, playerID)
      return 0
    end
  end, "building chosen", 0)  

  Convars:RegisterCommand("check_select", function(name, p)
    local cmdPlayer = Convars:GetCommandClient()
    --print('ITS CRAAAZY')
    if cmdPlayer then
        --print(p)
        index = tonumber(p)
        --print(index)
        local ent = EntIndexToHScript(index) 
        --print(ent:GetUnitName())
    end
  end, "checking selected unit", 0)
end

function CallMenu(keys)
    local caster = keys.caster
    local playerID = caster:GetMainControllingPlayer()

    --print(caster:GetAbilityCount())
    for i = 0, caster:GetAbilityCount() do
      --print(i)
      if caster:GetAbilityByIndex(i) ~= nil then
        local tech = caster:GetAbilityByIndex(i):GetAbilityName()
        if string.match(tech, "build_") then
         tech = string.sub(tech, 7)
          TechTree:GetRequired(tech, playerID)
        end
      end
    end 

    FireGameEvent("build_ui_called", {player_ID = playerID, builder = caster:GetUnitName()})

    --ONLY FOR TESTING IN SINGLE, NOT WORKING IN MULTIPLAYER.
    --SHOULD BE playerCasters[playerID] = caster
    playerCasters[playerID] = caster
   -- playerCasters[playerID] = caster

end

function BuildUI:BuildChosen(building, playerID)

    --ONLY FOR TESTING IN SINGLE, NOT WORKING IN MULTIPLAYER.
    --SHOULD BE local caster = playerCasters[playerID]
    --local caster = playerCasters[playerID]
    local caster = playerCasters[playerID]
    local ability = caster:FindAbilityByName(building)

    --find a better way of doing this..(like getting it out of the kv.)
    local tech = string.sub(building, 7)

    print(TechTree:GetRequired(tech, playerID))

    caster:CastAbilityNoTarget(ability, 0)
end