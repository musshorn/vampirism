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
	--[[Convars:RegisterConvar('tech_query', string defaultValue, string helpText, int flags) --[[Returns:void
	RegisterConvar(name, defaultValue, helpString, flags): register a new console variable.
	]]
	for i = 0, 9 do
		playerTrees[i] = {}
	end
end

--Check if a unit requires a missing tech, and return the missing tech(s) if any.
function TechTree:GetRequired(unitName, playerID)
	print('GETREQUIRED')
	print(unitName)
	print(playerID)

	local techlist = {}

	if UNIT_KV[unitName] ~= nil then
		if UNIT_KV[unitName].NeedTech ~= nil then
			local reqs = tostring(UNIT_KV[unitName].NeedTech)
			--print(reqs..'- REQS')
			for tech in string.gmatch(reqs, "%S+") do
				--print(tech..'- TECH ADDED TO TECHLIST')
				if tech ~= nil then
					table.insert(techlist, tech)
				end
			end
		else
			--print('unit needs no techs shrek')
			return true
		end
	end

	if table.getn(techlist) == 0 then
		--print('we think theres nothing in techlist')
		return false
	end

	if techlist ~= nil then
		for i = 1, table.getn(techlist) do
			local check = tostring(techlist[i])
			print(check)
			if playerTrees[playerID][check] ~= nil then
				if playerTrees[playerID][check] < 1 then
					FireGameEvent("tech_return", {player_ID = playerID, building = unitName, available = false})
					return false
				end
			else
				return false
			end
		end
	end

	FireGameEvent("tech_return", {player_ID = playerID, building = unitName, available = true})
	return true
end

--Adds a unit to the TechTree table, and increments the count of units in the table.
function TechTree:AddTech(unitName, playerID)
	local tech = unitName

	if playerTrees[playerID][tech] ~= nil then
		playerTrees[playerID][tech] = playerTrees[playerID][tech] + 1
	else
		playerTrees[playerID][tech] = 1
	end
end

function TechTree:AddTechAbility(keys)
	local ability = keys
	local tech = keys:GetAbilityName()
	local playerID = ability:GetCaster():GetMainControllingPlayer()

	if playerTrees[playerID][tech] == nil then
		playerTrees[playerID][tech] = 1
		PrintTable(playerTrees)
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
	else
		print('TECH ' .. tech .. ' is already 0!')
	end
end