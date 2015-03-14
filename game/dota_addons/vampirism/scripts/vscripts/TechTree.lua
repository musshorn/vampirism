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

  Convars:RegisterCommand("tech_query", function(name, p)
   local cmdPlayer = Convars:GetCommandClient()
   if cmdPlayer then
      local playerID = cmdPlayer:GetPlayerID()
    --print(playerID)
      TechTree:GetRequired(p, playerID)
      return 0
    end
  end, "tech query made", 0)  
end

--Check if a unit requires a missing tech, and return the missing tech(s) if any.
function TechTree:GetRequired(unitName, playerID)
	--print('GETREQUIRED')
	--print(unitName)
	--print(playerID)

	--PrintTable(PlayerTrees)
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
			FireGameEvent("tech_return", {player_ID = playerID, building = 'build_'..unitName, buildable = true})
			return true
		end
	end

	if techlist ~= nil then
		for i = 1, table.getn(techlist) do
			local check = tostring(techlist[i])
			--print(check)
			if playerTrees[playerID][check] ~= nil then
				if playerTrees[playerID][check] < 1 then
					--print('hit here')
					FireGameEvent("tech_return", {player_ID = playerID, building = 'build_'..unitName, buildable = false})
					return false
				end
			else
				FireGameEvent("tech_return", {player_ID = playerID, building = 'build_'..unitName, buildable = false})
				--print('exited here')
				return false
			end
		end
	end

	--print('made it')
	FireGameEvent("tech_return", {player_ID = playerID, building = 'build_'..unitName, buildable = true})
	return true
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

function TechTree:AddTechAbility(keys)
	local ability = keys
	local tech = keys:GetAbilityName()
	local playerID = ability:GetCaster():GetMainControllingPlayer()

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