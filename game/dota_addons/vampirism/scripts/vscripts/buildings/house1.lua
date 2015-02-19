--initialize the class
if House1 == nil then
	House1 = {}
	House1.__index = House1
end

function House1:Init(unit)

	Timers:CreateTimer(function()
		if not unit:IsAlive() then
			return nil
		end
		
		return .1
	end)
end