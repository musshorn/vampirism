function TrainUnit( keys )
  local caster = keys.caster
  table.insert(caster.queue, keys)
end
function Cancel( keys )
  local caster = keys.caster
  local ability = caster:GetAbilityByIndex(1) -- Dont know if this will always be true
  if (ability:IsChanneling() == true) then
    caster:Stop()
    caster:RemoveAbility(ability:GetName())
    caster:RemoveModifierByName(keys.cancel) 
    print("Removed ability?")
  end
end
function spawnWorkerT1( keys )
  PrintTable(keys)
  print("RED HOT MAYMAYS")
end