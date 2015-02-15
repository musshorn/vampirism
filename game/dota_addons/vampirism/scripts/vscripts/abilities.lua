function build(keys)
  local building = nil
  if name == "build_wall1" then
    building = Building:Wall1(point, keys.caster:GetPlayerOwner())
  end
  if name == "build_house_t1" then   
    building = Building:House1(point, keys.caster:GetPlayerOwner())
  end
  if building == nil or not building.buildSuccess then
    return
  end

  -- Valid building at this point.
  if building.think then
    building:Think()
  end
end

function harvest_t1(keys)
  local caster = keys.caster
  local point = keys.target:GetAbsOrigin()
  caster:MoveToPosition(point)
end

function human_blink(keys)
  --DeepPrintTable(keys)
  local caster = keys.caster
  local point = keys.target_points[1]
  caster:SetAbsOrigin(point)
end

function slayer_attribute_bonus(keys)
  local caster = keys.caster
  caster:SetBaseStrength(caster:GetBaseStrength() + 3)
  caster:SetBaseAgility(caster:GetBaseAgility() + 3)
  caster:SetBaseIntellect(caster:GetBaseIntellect() + 3)
end

function uitest(keys)
  local ability = keys.caster:FindAbilityByName("build_house_t1")
  local caster = keys.caster
  caster:CastAbilityOnPosition(Vector(1091.630737, -426.264648, 255.999939), ability, -1) 
  --[[ 
  FlashUtil:GetCursorWorldPos(caster:GetPlayerID(), function(pID, cursor_position)
  caster:CastAbilityOnPosition(cursor_position, ability, 0)
  print(cursor_position)
  end)
]]
end
