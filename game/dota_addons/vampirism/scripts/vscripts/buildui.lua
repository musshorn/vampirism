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
    local unitName = caster:GetUnitName()

    --print(caster:GetAbilityCount())

    if caster:GetUnitName() == "npc_dota_hero_omniknight" then
      for k, v in pairs(ABILITY_HOLDERS[unitName]) do
        if ABILITY_KV[v]['UnitName'] ~= nil then -- if its not a research
          local tech = ABILITY_KV[v]['UnitName']
          TechTree:GetRequired(tech, playerID, "building")
        end
      end
    end

    if ABILITY_HOLDERS[unitName] ~= nil then
      for k, v in pairs(ABILITY_HOLDERS[unitName]) do
        if ABILITY_KV[v]['UnitName'] ~= nil then
          local tech = ABILITY_KV[v]['UnitName']
          TechTree:GetRequired(tech, playerID, "building")
        else
          --assuming its research
          local tech = v
          TechTree:GetRequired(tech, playerID, "building")
        end
      end
    else -- caster is not using ability holders
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
            TechTree:GetRequired(buildName, playerID, "ability")
          end
        end
      end
    end 

    FireGameEvent("build_ui_called", {player_ID = playerID, builder = caster:GetUnitName()})

    --ONLY FOR TESTING IN SINGLE, NOT WORKING IN MULTIPLAYER.
    --SHOULD BE playerCasters[playerID] = caster
    playerCasters[playerID] = caster
    --playerCasters[playerID] = caster
end

function BuildUI:BuildChosen(building, playerID)

    local caster = playerCasters[playerID]

    if caster:FindAbilityByName(building) ~= nil then
      local ability = caster:FindAbilityByName(building)
      caster:CastAbilityNoTarget(ability, caster:GetMainControllingPlayer())
    else
      for k, v in ipairs(ABILITY_HOLDERS[caster:GetUnitName()]) do
        if building == v then
          caster:AddAbility(v)
          local ability = caster:FindAbilityByName(v)
          ability:SetLevel(1)
          caster:CastAbilityNoTarget(ability, caster:GetMainControllingPlayer())
          if ABILITY_KV[ability:GetAbilityName()]['UnitName'] ~= nil then
            caster:RemoveAbility(v)
          end
        end
      end
    end
end