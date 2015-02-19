function TrainUnit( keys )
  local caster = keys.caster
  table.insert(caster.queue, keys)
end
function Cancel( keys )
  local caster = keys.caster
  Timers:RemoveTimer("WorkTimer")
  caster.workHandler:SetChanneling(false)
  caster.doingWork = false
  caster:RemoveModifierByName(caster.workHandler:GetName())
end