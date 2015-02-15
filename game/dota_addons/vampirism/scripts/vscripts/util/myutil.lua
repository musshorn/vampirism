-- examples on how to do things:
--abil:ApplyDataDrivenModifier(GlobalDummy, unit, "no_collision", {})

function tableContains(list, element)
  if list == nil then return false end
  for i=1,#list do
    if list[i] == element then
      return true
    end
  end
  return false
end

function getIndex(list, element)
  if list == nil then return false end
  for i=1,#list do
    if list[i] == element then
      return i
    end
  end
  return -1
end

function VectorString(v)
  return 'x: ' .. v.x .. ' y: ' .. v.y .. ' z: ' .. v.z
end

function AddAbilityToUnit(hUnit, sName)
  if not hUnit then return end
  
  if not hUnit:HasAbility(sName) then
   hUnit:AddAbility(sName)
 end
  local abil = hUnit:FindAbilityByName(sName)
  abil:SetLevel(1)

  return abil
end

function RotateVector2D(v,theta)
  local xp = v.x*math.cos(theta)-v.y*math.sin(theta)
  local yp = v.x*math.sin(theta)+v.y*math.cos(theta)
  return Vector(xp,yp,v.z):Normalized()
end

function getOppositeTeam( unit )
  if unit:GetTeam() == DOTA_TEAM_GOODGUYS then
    return DOTA_TEAM_BADGUYS
  else
    return DOTA_TEAM_GOODGUYS
  end
end

function isPointWithinSquare(p, sqCenter)
  --if math.pow(player.hero:GetAbsOrigin().x,2) + math.pow(player.hero:GetAbsOrigin().y,2) <= math.pow(platformRadius-20,2)
  if (p.x > sqCenter.x-64 and p.x < sqCenter.x+64) and (p.y > sqCenter.y-64 and p.y < sqCenter.y+64) then
    return true
  else
    return false
  end
end

function shallowcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = orig_value
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end