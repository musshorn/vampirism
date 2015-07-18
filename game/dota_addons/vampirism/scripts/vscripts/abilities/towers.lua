--[[Mana drain and damage part of Mana Break
  Author: Pizzalol
  Date: 16.12.2014.
  NOTE: Currently works on magic immune enemies, can be fixed by checking for magic immunity before draining mana and dealing damage]]
function ManaBreak( keys )
  local target = keys.target
  local caster = keys.caster
  local ability = keys.ability
  local manaBurn = ability:GetLevelSpecialValueFor("mana_per_hit", (ability:GetLevel() - 1))
  local manaDamage = ability:GetLevelSpecialValueFor("damage_per_burn", (ability:GetLevel() - 1))

  local damageTable = {}
  damageTable.attacker = caster
  damageTable.victim = target
  damageTable.damage_type = ability:GetAbilityDamageType()
  damageTable.ability = ability
  damageTable.damage_flags = DOTA_UNIT_TARGET_FLAG_NONE -- Doesnt seem to work?

  -- Checking the mana of the target and calculating the damage
  if(target:GetMana() >= manaBurn) then
    damageTable.damage = manaBurn * manaDamage
    target:ReduceMana(manaBurn)
  else
    damageTable.damage = target:GetMana() * manaDamage
    target:ReduceMana(manaBurn)
  end

  ApplyDamage(damageTable)
end

function bloodArmor(keys)
  local target = keys.target
  local ability = keys.ability

  target:SetModifierStackCount("modifier_blood_armor_1", ability, target:GetModifierStackCount("modifier_blood_armor_1", ability) + 1)
end

function HolyBloodArmor(keys)
  local target = keys.target
  local ability = keys.ability

  target:SetModifierStackCount("modifier_blood_armor_2", ability, target:GetModifierStackCount("modifier_blood_armor_2", ability) + 1)
end

function calciteBuff( keys )
  local caster = keys.caster
  local target = keys.target
  local ability = keys.ability
  local attackGain = ability:GetLevelSpecialValueFor("tower_calcite_t1_speed_gain", (ability:GetLevel() -1))
  local gainDuration = ability:GetLevelSpecialValueFor("duration", (ability:GetLevel()))
  local maxStacks = ability:GetLevelSpecialValueFor("max_stacks", ability:GetLevel() -1)

  if caster:GetModifierStackCount("modifier_calcite_stack", ability) < maxStacks then
    caster:SetModifierStackCount("modifier_calcite_stack", ability, caster:GetModifierStackCount("modifier_calcite_stack", ability) + 1)
  end
end

function trueSight(keys)
  print('called')
    keys.caster:AddNewModifier(keys.caster, nil, "modifier_truesight", {})

    Timers:CreateTimer(1, function ()
       if keys.caster:HasModifier("modifier_truesight") then
         print('has trueSight')
       end
       return 1
    end)

end
