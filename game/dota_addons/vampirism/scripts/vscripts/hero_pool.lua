if SlayerPool == nil then
  SlayerPool = {}
end

function SlayerPool:ActivatePool()
  Timers:CreateTimer(function()
      for i=0, 9 do
        if PlayerResource:GetTeam(i) == DOTA_TEAM_GOODGUYS then
          if SLAYERS[i] ~= nil then
            if SLAYERS[i].handle ~= nil then
              if SLAYERS[i].handle.inPool ~= nil then
                SLAYERS[i].handle:HeroLevelUp(true)
                local level = SLAYERS[i].handle:GetLevel()
                if level == 5 or level == 10 or level == 11 or level == 15 or level == 20 then
                  if SLAYERS[i].handle.AbilityPoints ~= nil then
                    SLAYERS[i].handle.AbilityPoints = SLAYERS[i].handle.AbilityPoints + 1
                    SLAYERS[i].handle:SetAbilityPoints(SLAYERS[i].handle.AbilityPoints)
                  else
                    SLAYERS[i].handle.AbilityPoints = 1
                  end
                else
                  if SLAYERS[i].handle.AbilityPoints ~= nil then
                    SLAYERS[i].handle:SetAbilityPoints(SLAYERS[i].handle.AbilityPoints)
                  else
                    SLAYERS[i].handle.AbilityPoints = 0
                    SLAYERS[i].handle:SetAbilityPoints(SLAYERS[i].handle.AbilityPoints)
                  end
                end
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