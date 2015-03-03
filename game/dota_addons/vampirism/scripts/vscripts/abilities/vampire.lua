--[[
    Author: space-jam-
    Date: 3.3.2015
    Creates a vision dummy for the vampires, and deletes it after
    a set amount of time.
]]

--Creates dummy units, depending on the level of the ability.
function shadow_sight(keys)
  local caster = keys.caster
  local target = keys.target_points[1]
  local ability = keys.ability
  local playerID = caster:GetMainControllingPlayer()

  if ability:GetLevel() == 1 then
    CreateUnitByName("vampire_vision_dummy_1", target, false, caster, PlayerResource:GetPlayer(playerID), PlayerResource:GetTeam(playerID))
  elseif ability:GetLevel() == 2 then
    CreateUnitByName("vampire_vision_dummy_2", target, false, caster, PlayerResource:GetPlayer(playerID), PlayerResource:GetTeam(playerID))
  end
end

--Called when the dummy is created, and destroys it on time.
function vision_dummy(keys)
  local dummy = keys
	local lock = dummy:FindAbilityByName("vampire_vision_dummy_lock")

  --The level of the reveal dummy
  local level = tonumber(string.sub(dummy:GetUnitName(), -1))

  --Determine the amount of time the dummy should stay alive.
  if level == 1 then
    Timers:CreateTimer(10, function ()
        dummy:RemoveSelf()
    end)
  elseif level == 2 then
    Timers:CreateTimer(20, function ()
        dummy:RemoveSelf()
    end)
  end
end