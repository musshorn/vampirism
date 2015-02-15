Slayers_list = {}

function Activate()
  Timers:CreateTimer(0, --Start the timer for the slayer leveling pool
    function()
      for i=0, 9 do
        if PlayerResource:GetTeam(i) == DOTA_TEAM_GOODGUYS then
          if Slayers_list[i] ~= nil then
            Slayers_list[i]:HeroLevelUp(true)
          end
        end
      end
      return 0
    end
  )
end


-- Change omni to invoker or whatever the slayer becomes
function OnStartTouch( trigger )
  if trigger.activator:GetName() == "npc_dota_hero_omniknight" then
    Slayers_list[trigger.activator:GetPlayerOwnerID()] = trigger.activator
    local hero  = trigger.activator
    local ability = hero:FindAbilityByName("build_house_t1")
    FireGameEvent('build_ui_called', {player_ID = pid, panel_ID = 0})
  end
end

function OnEndTouch( trigger )
  if trigger.activator:GetName() == "npc_dota_hero_omniknight" then
    Slayers_list[trigger.activator:GetPlayerOwnerID()] = nil
  end
end