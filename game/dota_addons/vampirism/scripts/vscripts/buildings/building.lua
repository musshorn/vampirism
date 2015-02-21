function TrainUnit( keys )
  local caster = keys.caster
  table.insert(caster.queue, keys)
end

function Cancel( keys )
  local caster = keys.caster
  if (caster.workHandler ~= nil) then
    Timers:RemoveTimer(caster.uniqueName)
    caster.workHandler:SetChanneling(false)
    caster.doingWork = false
    caster:RemoveModifierByName(caster.workHandler:GetName())
    caster.workHandler = nil
  end
end

function SetRallyPoint( keys )
  local caster = keys.caster
  caster.rallyPoint = keys.target_points[1]
end
