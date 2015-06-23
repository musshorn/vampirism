--[[table structure

playerIDs--building name
           building name -- count]]

if TechTree == nil then
  TechTree = {}
end

if playerTrees == nil then
	playerTrees = {}
end

function TechTree:Init()
	for i = 0, 9 do
		playerTrees[i] = {}
	end

  --[[
  Convars:RegisterCommand("tech_query", function(name, p)
   local cmdPlayer = Convars:GetCommandClient()
   if cmdPlayer then
      local playerID = cmdPlayer:GetPlayerID()
    --print(playerID)
      if ABILITY_KV[p][UnitName] == nil then
      	TechTree:GetRequired(p, playerID, true)
      	return 0
      end
    end
  end, "tech query made", 0)  ]]
end

--Check if a unit requires a missing tech, and return the missing tech(s) if any.
function TechTree:GetRequired(unitName, playerID, sType)
	--PrintTable(PlayerTrees)
	if sType == "building" then
		local techlist = {}
		if UNIT_KV[playerID][unitName] ~= nil then
			if UNIT_KV[playerID][unitName].NeedTech ~= nil then
				local reqs = tostring(UNIT_KV[playerID][unitName].NeedTech)
				for tech in string.gmatch(reqs, "%S+") do
					if tech ~= nil then
						table.insert(techlist, tech)
					end
				end
			else
				FireGameEvent("tech_return", {player_ID = playerID, building = 'build_'..unitName, buildable = true})
				return true
			end
		end
	
		if techlist ~= nil then
			for i = 1, table.getn(techlist) do
				local check = tostring(techlist[i])
				if playerTrees[playerID][check] ~= nil then
					if playerTrees[playerID][check] < 1 then
						FireGameEvent("tech_return", {player_ID = playerID, building = 'build_'..unitName, buildable = false})
						--print('missing tech for '..tostring(unitName))
						return false
					end
				else
					--print('missing tech for '..tostring(unitName).. ' (none in tree)')
					FireGameEvent("tech_return", {player_ID = playerID, building = 'build_'..unitName, buildable = false})
					return false
				end
			end
		end
		--print(tostring(unitName)..' is buildable!')
		FireGameEvent("tech_return", {player_ID = playerID, building = 'build_'..unitName, buildable = true})
		return true
	elseif sType == "ability" then
		local techlist = {}
		if ABILITY_KV[unitName] ~= nil then
			if ABILITY_KV[unitName].NeedTech ~= nil then
				local reqs = tostring(ABILITY_KV[unitName].NeedTech)
				for tech in string.gmatch(reqs, "%S+") do
					if tech ~= nil then
						table.insert(techlist, tech)
					end
				end
			else
				--print('no techs needed for '..tostring(unitName))
				FireGameEvent("tech_return", {player_ID = playerID, building = unitName, buildable = true})
				return true
			end
		end
	
		if techlist ~= nil then
			for i = 1, table.getn(techlist) do
				local check = tostring(techlist[i])
				if playerTrees[playerID][check] ~= nil then
					if playerTrees[playerID][check] < 1 then
						--print('missing tech for '..tostring(unitName))
						FireGameEvent("tech_return", {player_ID = playerID, building = unitName, buildable = false})
						return false
					end
				else
					--print('missing tech for '..tostring(unitName).. ' (none in tree)')
					FireGameEvent("tech_return", {player_ID = playerID, building = unitName, buildable = false})
					return false
				end
			end
		end
		--print(tostring(unitName)..' is buildable!')
		FireGameEvent("tech_return", {player_ID = playerID, building = unitName, buildable = true})
		return true
	elseif sType == "item" then
		local techlist = {}
		if ITEM_KV[unitName] ~= nil then
			if ITEM_KV[unitName].NeedTech ~= nil then
				local reqs = tostring(ITEM_KV[unitName].NeedTech)
				for tech in string.gmatch(reqs, "%S+") do
					if tech ~= nil then
						table.insert(techlist, tech)
					end
				end
			else
				FireGameEvent("tech_return", {player_ID = playerID, building = 'build_'..unitName, buildable = true})
				return true
			end
		end
	
		if techlist ~= nil then
			for i = 1, table.getn(techlist) do
				local check = tostring(techlist[i])
				if playerTrees[check] ~= nil then
					if playerTrees[check] < 1 then
						FireGameEvent("tech_return", {player_ID = playerID, building = 'build_'..unitName, buildable = false})
						--print('missing tech for '..tostring(unitName))
						return false
					end
				else
					--print('missing tech for '..tostring(unitName).. ' (none in tree)')
					FireGameEvent("tech_return", {player_ID = playerID, building = 'build_'..unitName, buildable = false})
					return false
				end
			end
		end
		--print(tostring(unitName)..' is buildable!')
		FireGameEvent("tech_return", {player_ID = playerID, building = 'build_'..unitName, buildable = true})
		return true
	end
end

--Adds a unit to the TechTree table, and increments the count of units in the table.
function TechTree:AddTech(unitName, playerID)
	local tech = unitName
	--print('adding tech '..tostring(playerID))

	if playerTrees[playerID][tech] ~= nil then
		playerTrees[playerID][tech] = playerTrees[playerID][tech] + 1
		--print('added')
		--PrintTable(PlayerTrees)
	else
		playerTrees[playerID][tech] = 1
		--print('added')
		--PrintTable(PlayerTrees)
	end
end

function TechTree:AddTechAbility(playerID, tech)
	if playerTrees[playerID][tech] == nil then
		playerTrees[playerID][tech] = 1
	else
		playerTrees[playerID][tech] = playerTrees[playerID][tech] + 1
	end
end

--[[Check if a building was the last to be destroyed, if so remove it from the tree.]]

function TechTree:RemoveTech(unitName, playerID)
	local tech = unitName

	if playerTrees[playerID][tech] == nil then
		return
	end

	if playerTrees[playerID][tech] > 0 then
		playerTrees[playerID][tech] = playerTrees[playerID][tech] - 1
	--else
		--print('TECH ' .. tech .. ' is already 0!')
	end
end

-- Quick check if a player has a given tech, used for checking tech modifiers.
function TechTree:HasTech(playerID, tech)
	for k, v in pairs(playerTrees) do
		if v[tech] ~= nil then
			return true
		end
	end
	return false
end