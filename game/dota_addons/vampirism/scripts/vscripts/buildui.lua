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
  --print('callmenu')
    local caster = keys.caster
    local playerID = caster:GetMainControllingPlayer()

    --print(caster:GetAbilityCount())
    for i = 0, caster:GetAbilityCount() do
      --print(i)
      if caster:GetAbilityByIndex(i) ~= nil then
        --print(i)
        local ability = caster:GetAbilityByIndex(i):GetAbilityName()
        local buildName = ABILITY_KV[ability]['UnitName']
        --print('this is '..ability..' buildname')
        --print(buildName)
        if buildName ~= nil then
          --print('callmenu get req')
          TechTree:GetRequired(buildName, playerID, true)
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

    print('buildui chosen')

    --ONLY FOR TESTING IN SINGLE, NOT WORKING IN MULTIPLAYER.
    --SHOULD BE local caster = playerCasters[playerID]
    --local caster = playerCasters[playerID]
    local caster = playerCasters[playerID]
    local ability = caster:FindAbilityByName(building)

    print(caster:GetUnitName())
    print(ability:GetAbilityName())
    caster:CastAbilityNoTarget(ability, caster:GetMainControllingPlayer())
    --ability:OnSpellStart()
    print(ability:GetChannelTime())
    --ability:SetChanneling(true)
    --if caster:IsChanneling() then
    -- caster:CastAbilityNoTarget(caster:FindAbilityByName('build_cancel'), caster:GetMainControllingPlayer())
   -- else
    --  ability:SetChanneling(true)
    --end
    --find a better way of doing this..(like getting it out of the kv.)
    --local buildName = ABILITY_KV[ability]['UnitName']

    -- print(TechTree:GetRequired(tech, playerID, true))
    -- print('player casted ability')
    --caster:CastAbilityNoTarget(ability, playerID)
end