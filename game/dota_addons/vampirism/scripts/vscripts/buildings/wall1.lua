function Building:Wall1(vPoint, hOwner)
	local wall1 = Building:new(vPoint, 1.2, hOwner, "npc_wall1", 2, 1.2, nil)
	if wall1 ~= nil then
		wall1.buildSuccess = true
	else
		return
	end
	--table.insert(hOwner.)
end