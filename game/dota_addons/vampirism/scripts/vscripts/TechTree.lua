--[[table structure

playerIDs--building name
           building name -- count]]

if TechTree == nil then
  TechTree = {}
end

if playerTrees == nil then
	playerTrees = {}
end

for i = 0, 9 do
	playerTrees[i] = {}
end

function TechTree:Init()
	--[[Convars:RegisterConvar('tech_query', string defaultValue, string helpText, int flags) --[[Returns:void
	RegisterConvar(name, defaultValue, helpString, flags): register a new console variable.
	]]
end

--Check if a unit requires a missing tech, and return the missing tech(s) if any.
function TechTree:GetRequired(unitName, playerID)
	print('GETREQUIRED')
	--local unit = EntIndexToHScript(keys.entindex)
	--local playerID = unit:GetMainControllingPlayer()


	if playerTrees[playerID] == nil then
		print('PLAYER HAS NO TECH')
		--player has no tech
		FireGameEvent("tech_return", {player_ID = playerID, available = false})
		return false
	end

	local techlist = {}

	if UNIT_KV[unitName] ~= nil then
		local reqs = tostring(UNIT_KV[unitName].NeedTech)
		if reqs == nil then
			print('unit has no reqs')
		else
			print(reqs..'- REQS')
			for tech in string.gmatch(reqs, "%S+") do
				print(tech..'- TECH ADDED TO TECHLIST')
				table.insert(techlist, tech)
			end
		end
	end

	if techlist ~= nil then
		for i = 1, #techlist do
			print(techlist[i])
			print('ITEM IN TECHLIST')
		end
	end

	print('XPLICIT CHECK')
	print(playerTrees[playerID].house_t1)

	--PrintTable(playerTrees)
	PrintTable(playerTrees[playerID])


	if techlist ~= nil then
		for i = 1, #techlist do
			local check = tostring(techlist[i])
			if playerTrees[playerID].check == nil or playerTrees[playerID].check < 1 then
				print(tostring(playerTrees[playerID].check)..' this tech was empty or less than 1')
				FireGameEvent("vamp_tech_check_return", {player_ID = playerID, available = false})
				print(check)
				return false
			end
		end
	end

	print('you have tech')

	FireGameEvent("vamp_tech_check_return", {player_ID = playerID, available = true})
	return true
end

--Adds a unit to the TechTree table, and increments the count of units in the table.
function TechTree:AddTech(unitName, playerID)
	local tech = unitName
	print('adding '..tech)
	if playerTrees[playerID].tech == nil then
		playerTrees[playerID].tech = 1
		print('making new tech index'..tech..tostring(playerID))
		print(playerTrees[playerID].tech)
	else
		playerTrees[playerID].tech = playerTrees[playerID].tech + 1

		print('adding tech to extisting index'..tech..tostring(playerID))
	end

	print('added tech')
end

function TechTree:AddTechAbility(keys)
	local ability = keys
	local tech = keys:GetAbilityName()
	local playerID = ability:GetCaster():GetMainControllingPlayer()

	if playerTrees[playerID].tech == nil then
		playerTrees[playerID].tech = 1
		print('making new tech index'..tech..tostring(playerID))
		print(playerTrees[playerID].tech)
	else
		playerTrees[playerID].tech = playerTrees[playerID].tech + 1
		print('adding tech to extisting index'..tech..tostring(playerID))
	end
end

--[[Check if a building was the last to be destroyed, if so remove it from the tree.]]

function TechTree:RemoveTech(unitName, playerID)
	local tech = unitName
	print('Removing tech')

	if playerTrees[playerID].tech == nil then
		print('nil tech bro')
		return
	end

	if playerTrees[playerID].tech > 0 then
		playerTrees[playerID].tech = playerTrees[playerID].tech - 1
		print('removed a kek')
		print(playerTrees[playerID].tech)
	else
		print('TECH ' .. tech .. ' is already 0!')
	end
end