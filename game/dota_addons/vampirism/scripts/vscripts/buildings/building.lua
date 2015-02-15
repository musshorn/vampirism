if Building == nil then
  Building = {}
  --Building.__index = Building
end

function Building:new(vPoint, nSize, hOwner, sBuilding, nBuildTime, fScale, sModel)
	local point = BuildingHelper:AddBuildingToGrid(vPoint, nSize, hOwner)
	if point ~= -1 then
		local building = CreateUnitByName(sBuilding, point, false, nil, nil, hOwner:GetTeam())
		if sModel ~= nil then
			Timers:CreateTimer(function()
				building:SetModel(sModel)
				BuildingHelper:AddBuilding(building)
				building:UpdateHealth(nBuildTime,true,fScale)
			end)
		else
			BuildingHelper:AddBuilding(building)
			building:UpdateHealth(nBuildTime,true,fScale)
		end

		--setmetatable(building, building)
		return building
		
	else
		return nil
	end

	function building:SellBack()
		building:RemoveBuilding(true)
	end
end