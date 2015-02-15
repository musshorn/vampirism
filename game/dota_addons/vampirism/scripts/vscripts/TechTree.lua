--[[table structure

playerIDs--building name
           building name -- count]]

if TechTree == nil then
  TechTree = {}
end

if playerTrees == nil then
	playerTrees = {}
end

for i = -1, 9 do
	playerTrees[i] = {}
end

--Check if a unit requires a missing tech, and return the missing tech(s) if any.
function TechTree:GetRequired (keys)
	local unit = EntIndexToHScript(keys.entindex)
	local playerID = unit:GetPlayerOwnerID()
	if playerTrees[playerID] == nil then
		print('YOU HAVE NO TECH')
		return
	end

	local techlist = {}

	--populate a list with required techs.
	for i = 0, unit:GetAbilityCount() - 1 do
		if unit:GetAbilityByIndex(i) ~= nil then
			--print(unit:GetAbilityByIndex(i):GetAbilityName())
			if string.match(unit:GetAbilityByIndex(i):GetAbilityName(), '_tt_') then
				print('assinging tech')
				techlist[i] = string.sub(unit:GetAbilityByIndex(i):GetAbilityName(), 5)
			end
		end
	end

	local missing = nil

	for k, v in pairs(techlist) do
		if playerTrees[playerID][v] == nil or playerTrees[playerID][v] <= 0 then
			if missing ~= nil then
				missing = missing .. v .. ' '
			else
				missing = v .. ' '
			end
		end
	end
	
	if missing ~= nil then
		print('YOU ARE MISSING ' .. missing)
	else
		print('GO AHEAD MY SON')
	end
end

--Adds a unit to the TechTree table if it is the first a player has built.
function TechTree:AddTech(keys)
	local unit = EntIndexToHScript(keys.entindex)
	local tech = unit:GetUnitName()
	local playerID = unit:GetPlayerOwnerID()
	print(playerID)
	if playerTrees[playerID][tech] == nil then
		playerTrees[playerID][tech] = 1
	else
		playerTrees[playerID][tech] = playerTrees[playerID][tech] + 1
	end

	--[[
	if not string.match(playerTrees[playerID], tech) then
		playerTrees[playerID] = playerTrees[playerID] .. tech .. ' '
		end
	else
		playerTrees[playerID] = tech .. ' '
		]]
end


--REWRITE, CHANGE TO TRACKING ALL PLAYER BUILDINGS. / make timer to check 1 second later to be sure, scale back to .1
--[[Check if a building was the last to be destroyed, if so remove it from the tree.]]

function TechTree:RemoveTech(unitName, playerID)
	local tech = unitName
	print('i got called')

	if playerTrees[playerID][tech] == nil then
		print('nil tech bro')
		return
	end

	if playerTrees[playerID][tech] > 0 then
		playerTrees[playerID][tech] = playerTrees[playerID][tech] - 1
		print('removed a kek')
		print(playerTrees[playerID][tech])
	else
		print('TECH ' .. tech .. ' is already 0!')
	end
end