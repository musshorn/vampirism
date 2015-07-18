if SlayerPool == nil then
  SlayerPool = {}
end

function SlayerPool:ActivatePool()
  Timers:CreateTimer(50, function()
      for i=0, 9 do
        if PlayerResource:GetTeam(i) == DOTA_TEAM_GOODGUYS then
          if SLAYERS[i] ~= nil then
            if SLAYERS[i].handle ~= nil then
              if SLAYERS[i].handle.inPool ~= nil then
                SLAYERS[i].handle:HeroLevelUp(true)
              end
            end
          end
        end
      end
      return 60
    end
  )
end

function OnStartTouch( trigger )
  if trigger.activator:GetName() == "npc_dota_hero_invoker" then
    trigger.activator.inPool = true
  end
end

function OnEndTouch( trigger )
  if trigger.activator:GetName() == "npc_dota_hero_invoker" then
    trigger.activator.inPool = nil
  end
end