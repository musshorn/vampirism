function call_menu(keys)
    
    local caster = keys.caster
    print("found "..caster:GetUnitName())
    local ability = caster:FindAbilityByName("build_house_t1") 
    print("abilityname is "..ability:GetAbilityName())

    FireGameEvent("build_ui_called", {player_ID = caster:GetPlayerOwnerID(), panel_ID = 0}) --[[Returns:void
    Fire a pre-defined event, which can be found either in custom_events.txt or in dota's resource/*.res
    ]]

--[[
    FlashUtil:GetCursorWorldPos(caster:GetPlayerOwnerID(), function ( position )
        print(position)
        local test = FlashUtil:ParseVector(position)
        print(test)

     caster:CastAbilityOnPosition(Vector(0,0,0), ability, 0)
     end)
]]
    --[[ HOW 2 CALL FLASH UTIL FOR REAL 
    FlashUtil:GetCursorWorldPos(caster:GetPlayerID(), function(pID, cursor_position)
    caster:CastAbilityOnPosition(cursor_position, ability, 0)
        end)
    --print(caster:GetPlayerOwnerID())
    --caster:CastAbilityOnPosition(cursor, ability, 1) 
    ]]
end