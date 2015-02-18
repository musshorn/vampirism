function TrainUnit( keys )
  local caster = keys.caster
  table.insert(caster.queue, keys)
end
function Cancel( keys )
  -- Soon (tm)
end