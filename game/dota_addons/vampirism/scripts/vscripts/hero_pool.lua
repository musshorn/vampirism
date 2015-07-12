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
      return 60
    end
  )
end

function OnStartTouch( trigger )
  if trigger.activator:GetName() == "npc_dota_hero_Invoker" then
    Slayers_list[trigger.activator:GetMainControllingPlayer()] = trigger.activator
  end
end

function OnEndTouch( trigger )
  if trigger.activator:GetName() == "npc_dota_hero_Invoker" then
    Slayers_list[trigger.activator:GetMainControllingPlayer()] = nil
  end
end