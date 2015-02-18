--initialize the class
if House1 == nil then
	House1 = {}
	House1.__index = House1
end


function House1:Init(unit)
	local house1 = unit
	house1.queue = {}

	Timers:CreateTimer(function()
		if not unit:IsAlive() then
			return nil
		end

		if table.getn(house1.queue) > 0 then
			local keys = house1.queue[1]
			local caster =  keys.caster
			local abilityName = keys.AddToQueue

			caster:AddAbility(abilityName)
			
			ability = caster:FindAbilityByName(abilityName)
			ability:SetLevel(1)
			ability:CastAbility() 			
			house1.queue[1] = nil
		end
		return .1
	end)
end