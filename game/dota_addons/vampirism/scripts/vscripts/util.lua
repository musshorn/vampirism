-- GREAT UTILITY FUNCTIONS

--[[ Find a clear space for a unit, depending on its HullSize. (Used to replace FindClearSpaceForUnit)
	 Author: space jam
	 Date: 31.07.2015 
	 unit 		 : The handle of the unit you are moving.
	 vTargetPos  : The target Vector you want to move this unit too.
	 searchLimit : The furthest we should look for a clear space.
	 initRadius  : Must be less than searchLimit, allows us to start further out from the initial vector. Can also be nil to not specify.]]
function FindGoodSpaceForUnit( unit, vTargetPos, searchLimit, initRadius )
	local startPos = unit:GetAbsOrigin()
	local unitSize = unit:GetHullRadius()
	local gridSize = math.ceil(unitSize / 32)
	local x = vTargetPos.x
	local y = vTargetPos.y

	local goodSpace = {}

	local initBlocked = false
	if initRadius == nil then
		for i=1,360 do
			local rad = math.rad(i)
			local cx = x + unitSize * math.cos(rad)
			local cy = y + unitSize * math.sin(rad)
			local cz = GetGroundPosition(Vector(cx, cy, 1000), unit).z
			local pos = Vector(cx, cy, cz)
	
			-- Check first if the initial space is a good one.	
			local units = FindUnitsInRadius(unit:GetTeam(), pos, nil, unitSize, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
			if #units > 0 then
				-- There was a unit other than the unit in that space. Its blocked.
				--DebugDrawCircle(pos, Vector(0,0,255), 1, unitSize, true, 5)
				initBlocked = true
			end
			if GridNav:IsBlocked(pos) or GridNav:IsTraversable(pos) == false then
				initBlocked = true
				--DebugDrawCircle(pos, Vector(255,0,0), 1, unitSize, true, 5)
			end
		end
		-- The inital space was good, return it.
		if initBlocked == false then
			--DebugDrawCircle(vTargetPos, Vector(255,0,0), 1, unitSize, true, 5)
			return vTargetPos
		end
		initRadius = unitSize
	end

	local radius = initRadius
	while radius < searchLimit do
		local isBlocked = false
		local pos = Vector(0, 0, 0)
		local spaceIndex = 1

		-- Draw a circle, find the LEAST blocked space in that circle.
		for i = 1, 360 do
			isBlocked = false
			local rad = math.rad(i)

			-- Start at target point, works its way out.
			local cx = x + radius * math.cos(rad)
			local cy = y + radius * math.sin(rad)

			local cz = GetGroundPosition(Vector(cx, cy, 1000), unit).z
			pos = Vector(cx, cy, cz)
			
			--DebugDrawCircle(Vector(cx, cy, cz), RandomVector(50), 1, unitSize, true, 5)
			if GridNav:IsBlocked(pos) or GridNav:IsTraversable(pos) == false then
				isBlocked = true
				--DebugDrawCircle(pos, Vector(255,0,0), 1, unitSize, true, 5)
			end
			-- We found an empty space, add to current candidate.
			if isBlocked == false then
				if goodSpace[spaceIndex] == nil then goodSpace[spaceIndex] = {} end
				table.insert(goodSpace[spaceIndex], pos) 
			else
				if goodSpace[spaceIndex] ~= nil then
					spaceIndex = spaceIndex + 1
				end
			end
		end

		-- Grab the best candidate.
		local candidate = {}
		for k,v in pairs(goodSpace) do
			-- The table with the most verticies represents the longest unbroken section of clear space in the search radius.
			if #v > #candidate then
				candidate = v
			end
		end

		-- Get the middle point on the candidate space, assume this to be the most likely point to find a clear unit space.
		local bestVec = candidate[math.floor(#candidate / 2)]
		if bestVec ~= nil then
			local validSpace = true
			-- Trace around that point a circle the size of the unit, if we find something the point is blocked.
			for i = 1, 360 do
				local rad = math.rad(i)
	
				local cx = bestVec.x + unitSize * math.cos(rad)
				local cy = bestVec.y + unitSize * math.sin(rad)
				local newVec = Vector(cx, cy, pos.z)
				-- If any point on this circle is blocked, we haven't found a good spot.
				if GridNav:IsBlocked(newVec) or GridNav:IsTraversable(newVec) == false then
					validSpace = false
					--DebugDrawCircle(newVec, Vector(0,255,255), 1, unitSize, true, 5)
				end
			end
	
			if validSpace == true then
				local units = FindUnitsInRadius(unit:GetTeam(), bestVec, nil, unitSize, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
				--DebugDrawCircle(bestVec, Vector(0,255,0), 1, unitSize, true, 5)
				if #units > 0 then
					validSpace = false
				end
				if validSpace == true then
					return bestVec
				end
			end
		end
		radius = radius + unitSize / 4
		--DebugDrawCircle(Vector(x, y, pos.z), Vector(255,255,255), 1, radius, true, 5)
	end
	return false			
end

-- Finds the unit nearest from another unit, within a given range.
function FindNearestUnit(sFindUnit, hFromUnit, fRange)
	local nearestEnt = nil
	local nearEnts = Entities:FindAllInSphere(hFromUnit:GetAbsOrigin(), fRange)
	for k, v in pairs(nearEnts) do
		if v:GetClassname() == 'npc_dota_creature' then
			if v:GetUnitName() == sFindUnit then
				nearestEnt = v
			end
		end
	end
	return nearestEnt --returns the found unit (nil if not found)
end

-- Remove all abilities on a unit.
function ClearAbilities( unit )
	for i=0, unit:GetAbilityCount()-1 do
		local abil = unit:GetAbilityByIndex(i)
		if abil ~= nil then
			unit:RemoveAbility(abil:GetAbilityName())
		end
	end
	-- we have to put in dummies and remove dummies so the ability icon changes.
	-- it's stupid but volvo made us
	for i=1,6 do
		unit:AddAbility("pokemonworld_empty" .. tostring(i))
	end
	for i=0, unit:GetAbilityCount()-1 do
		local abil = unit:GetAbilityByIndex(i)
		if abil ~= nil then
			unit:RemoveAbility(abil:GetAbilityName())
		end
	end
end

-- goes through a unit's abilities and sets the abil's level to 1,
-- spending an ability point if possible.
function InitAbilities( hero )
	for i=0, hero:GetAbilityCount()-1 do
		local abil = hero:GetAbilityByIndex(i)
		if abil ~= nil then
			if hero:GetAbilityPoints() > 0 then
				hero:UpgradeAbility(abil)
			else
				abil:SetLevel(1)
			end
		end
	end
end

-- adds ability to a unit, sets the level to 1, then returns ability handle.
function AddAbilityToUnit(unit, abilName)
	if not unit:HasAbility(abilName) then
		unit:AddAbility(abilName)
	end
	local abil = unit:FindAbilityByName(abilName)
	abil:SetLevel(1)
	return abil
end

function GetOppositeTeam( unit )
	if unit:GetTeam() == DOTA_TEAM_GOODGUYS then
		return DOTA_TEAM_BADGUYS
	else
		return DOTA_TEAM_GOODGUYS
	end
end

-- returns true 50% of the time.
function CoinFlip(  )
	return RollPercentage(50)
end

-- theta is in radians.
function RotateVector2D(v,theta)
	local xp = v.x*math.cos(theta)-v.y*math.sin(theta)
	local yp = v.x*math.sin(theta)+v.y*math.cos(theta)
	return Vector(xp,yp,v.z):Normalized()
end

function PrintVector(v)
	print('x: ' .. v.x .. ' y: ' .. v.y .. ' z: ' .. v.z)
end

-- Given element and list, returns true if element is in the list.
function TableContains( list, element )
	if list == nil then return false end
	for k,v in pairs(list) do
		if k == element then
			return true
		end
	end
	return false
end

-- Given element and list, returns the position of the element in the list.
-- Returns -1 if element was not found, or if list is nil.
function GetIndex(list, element)
	if list == nil then return -1 end
	for i=1,#list do
		if list[i] == element then
			return i
		end
	end
	return -1
end

-- useful with GameRules:SendCustomMessage
function ColorIt( sStr, sColor )
	if sStr == nil or sColor == nil then
		return
	end

	--Default is cyan.
	local color = "00FFFF"

	if sColor == "green" then
		color = "ADFF2F"
	elseif sColor == "purple" then
		color = "EE82EE"
	elseif sColor == "blue" then
		color = "00BFFF"
	elseif sColor == "orange" then
		color = "FFA500"
	elseif sColor == "pink" then
		color = "DDA0DD"
	elseif sColor == "red" then
		color = "FF6347"
	elseif sColor == "lb" then
		color = "00FFFF"
	elseif sColor == "yellow" then
		color = "FFFF00"
	elseif sColor == "brown" then
		color = "A52A2A"
	elseif sColor == "magenta" then
		color = "FF00FF"
	elseif sColor == "teal" then
		color = "008080"
	elseif sColor == "dg" then
		color = "005624"
	elseif sColor == "grey" then
		color = "787878"
	end

	return "<font color='#" .. color .. "'>" .. sStr .. "</font>"
end

function ColourToID( colour )
	-- Radiant
	if colour == "blue" then
		return 0
	elseif colour == "teal" then
		return 1
	elseif colour == "purple" then
		return 2
	elseif colour == "yellow" then
		return 3
	elseif colour == "orange" then
		return 4

	-- Dire
	elseif colour == "pink" then
		return 5
	elseif colour == "grey" then
		return 6
	elseif colour == "light" or colour == "lb" then -- surely no one will notice ;)
		return 7
	elseif colour == "brown" then
		return 8
	elseif colour == "dark" or colour == "dg" then
		return 9
	else
		return -1 -- Error case
	end
end

function IDToColour( id )
	-- Radiant
	if id == 0 then
		return "blue"
	elseif id == 1 then
		return "teal"
	elseif id == 2 then
		return "purple"
	elseif id == 3 then
		return "yellow"
	elseif id == 4 then
		return "orange"

	-- Dire
	elseif id == 5 then
		return "pink"
	elseif id == 6 then
		return "grey"
	elseif id == 7 then
		return "lb"
	elseif id == 8 then
		return "brown"
	elseif id == 9 then
		return "dg"
	else
		return -1 -- Error case
	end
end


function ParseChat( keys )
	local player = keys.ply
	local msg = keys.text
	tokens = {}
	for word in string.gmatch(msg, '([^ ]+)') do
	    table.insert(tokens, word)
	end

	return tokens
end
--[[
	p: the raw point (Vector)
	center: center of the square. (Vector)
	length: length of 1 side of square. (Float)
]]
function IsPointWithinSquare(p, center, length)
	if (p.x > center.x-length and p.x < center.x+length) and 
		(p.y > center.y-length and p.y < center.y+length) then
		return true
	else
		return false
	end
end

--[[
  Continuous collision algorithm for circular 2D bodies, see
  http://www.gvu.gatech.edu/people/official/jarek/graphics/material/collisionFitzgeraldForsthoefel.pdf
  
  body1 and body2 are tables that contain:
  v: velocity (Vector)
  c: center (Vector)
  r: radius (Float)

  Returns the time-till-collision.
]]
function TimeTillCollision(body1,body2)
	local W = body2.v-body1.v
	local D = body2.c-body1.c
	local A = DotProduct(W,W)
	local B = 2*DotProduct(D,W)
	local C = DotProduct(D,D)-(body1.r+body2.r)*(body1.r+body2.r)
	local d = B*B-(4*A*C)
	if d>=0 then
		local t1=(-B-math.sqrt(d))/(2*A)
		if t1<0 then t1=2 end
		local t2=(-B+math.sqrt(d))/(2*A)
		if t2<0 then t2=2 end
		local m = math.min(t1,t2)
		--if ((-0.02<=m) and (m<=1.02)) then
		return m
			--end
	end
	return 2
end

function DotProduct(v1,v2)
  return (v1.x*v2.x)+(v1.y*v2.y)
end

function VectorString(v)
  return 'x: ' .. v.x .. ' y: ' .. v.y .. ' z: ' .. v.z
end

function PrintTable(t, indent, done)
	--print ( string.format ('PrintTable type %s', type(keys)) )
	if type(t) ~= "table" then return end

	done = done or {}
	done[t] = true
	indent = indent or 0

	local l = {}
	for k, v in pairs(t) do
		table.insert(l, k)
	end

	table.sort(l)
	for k, v in ipairs(l) do
		-- Ignore FDesc
		if v ~= 'FDesc' then
			local value = t[v]

			if type(value) == "table" and not done[value] then
				done [value] = true
				print(string.rep ("\t", indent)..tostring(v)..":")
				PrintTable (value, indent + 2, done)
			elseif type(value) == "userdata" and not done[value] then
				done [value] = true
				print(string.rep ("\t", indent)..tostring(v)..": "..tostring(value))
				PrintTable ((getmetatable(value) and getmetatable(value).__index) or getmetatable(value), indent + 2, done)
			else
				if t.FDesc and t.FDesc[v] then
					print(string.rep ("\t", indent)..tostring(t.FDesc[v]))
				else
					print(string.rep ("\t", indent)..tostring(v)..": "..tostring(value))
				end
			end
		end
	end
end

-- Colors
COLOR_NONE = '\x06'
COLOR_GRAY = '\x06'
COLOR_GREY = '\x06'
COLOR_GREEN = '\x0C'
COLOR_DPURPLE = '\x0D'
COLOR_SPINK = '\x0E'
COLOR_DYELLOW = '\x10'
COLOR_PINK = '\x11'
COLOR_RED = '\x12'
COLOR_LGREEN = '\x15'
COLOR_BLUE = '\x16'
COLOR_DGREEN = '\x18'
COLOR_SBLUE = '\x19'
COLOR_PURPLE = '\x1A'
COLOR_ORANGE = '\x1B'
COLOR_LRED = '\x1C'
COLOR_GOLD = '\x1D'


function round(num, idp)
  return tonumber(string.format("%." .. (idp or 0) .. "f", num))
end

--============ Copyright (c) Valve Corporation, All rights reserved. ==========
--
--
--=============================================================================

--/////////////////////////////////////////////////////////////////////////////
-- Debug helpers
--
--  Things that are really for during development - you really should never call any of this
--  in final/real/workshop submitted code
--/////////////////////////////////////////////////////////////////////////////

-- if you want a table printed to console formatted like a table (dont we already have this somewhere?)
scripthelp_LogDeepPrintTable = "Print out a table (and subtables) to the console"
logFile = "log/log.txt"

function LogDeepSetLogFile( file )
	logFile = file
end

function LogEndLine ( line )
	AppendToLogFile(logFile, line .. "\n")
end

function _LogDeepPrintMetaTable( debugMetaTable, prefix )
	_LogDeepPrintTable( debugMetaTable, prefix, false, false )
	if getmetatable( debugMetaTable ) ~= nil and getmetatable( debugMetaTable ).__index ~= nil then
		_LogDeepPrintMetaTable( getmetatable( debugMetaTable ).__index, prefix )
	end
end

function _LogDeepPrintTable(debugInstance, prefix, isOuterScope, chaseMetaTables )
	prefix = prefix or ""
	local string_accum = ""
	if debugInstance == nil then
		LogEndLine( prefix .. "<nil>" )
		return
	end
	local terminatescope = false
	local oldPrefix = ""
	if isOuterScope then  -- special case for outer call - so we dont end up iterating strings, basically
		if type(debugInstance) == "table" then
			LogEndLine( prefix .. "{" )
			oldPrefix = prefix
			prefix = prefix .. "   "
			terminatescope = true
	else
		LogEndLine( prefix .. " = " .. (type(debugInstance) == "string" and ("\"" .. debugInstance .. "\"") or debugInstance))
	end
	end
	local debugOver = debugInstance

	-- First deal with metatables
	if chaseMetaTables == true then
		if getmetatable( debugOver ) ~= nil and getmetatable( debugOver ).__index ~= nil then
			local thisMetaTable = getmetatable( debugOver ).__index
			if vlua.find(_LogDeepprint_alreadyseen, thisMetaTable ) ~= nil then
				LogEndLine( string.format( "%s%-32s\t= %s (table, already seen)", prefix, "metatable", tostring( thisMetaTable ) ) )
			else
				LogEndLine(prefix .. "metatable = " .. tostring( thisMetaTable ) )
				LogEndLine(prefix .. "{")
				table.insert( _LogDeepprint_alreadyseen, thisMetaTable )
				_LogDeepPrintMetaTable( thisMetaTable, prefix .. "   ", false )
				LogEndLine(prefix .. "}")
			end
		end
	end

	-- Now deal with the elements themselves
	-- debugOver sometimes a string??
	for idx, data_value in pairs(debugOver) do
		if type(data_value) == "table" then
			if vlua.find(_LogDeepprint_alreadyseen, data_value) ~= nil then
				LogEndLine( string.format( "%s%-32s\t= %s (table, already seen)", prefix, idx, tostring( data_value ) ) )
			else
				local is_array = #data_value > 0
				local test = 1
				for idx2, val2 in pairs(data_value) do
					if type( idx2 ) ~= "number" or idx2 ~= test then
						is_array = false
						break
					end
					test = test + 1
				end
				local valtype = type(data_value)
				if is_array == true then
					valtype = "array table"
				end
				LogEndLine( string.format( "%s%-32s\t= %s (%s)", prefix, idx, tostring(data_value), valtype ) )
				LogEndLine(prefix .. (is_array and "[" or "{"))
				table.insert(_LogDeepprint_alreadyseen, data_value)
				_LogDeepPrintTable(data_value, prefix .. "   ", false, true)
				LogEndLine(prefix .. (is_array and "]" or "}"))
			end
		elseif type(data_value) == "string" then
			LogEndLine( string.format( "%s%-32s\t= \"%s\" (%s)", prefix, idx, data_value, type(data_value) ) )
		else
			LogEndLine( string.format( "%s%-32s\t= %s (%s)", prefix, idx, tostring(data_value), type(data_value) ) )
		end
	end
	if terminatescope == true then
		LogEndLine( oldPrefix .. "}" )
	end
end


function LogDeepPrintTable( debugInstance, prefix, isPublicScriptScope )
	prefix = prefix or ""
	_LogDeepprint_alreadyseen = {}
	table.insert(_LogDeepprint_alreadyseen, debugInstance)
	_LogDeepPrintTable(debugInstance, prefix, true, isPublicScriptScope )
end


--/////////////////////////////////////////////////////////////////////////////
-- Fancy new LogDeepPrint - handles instances, and avoids cycles
--
--/////////////////////////////////////////////////////////////////////////////

-- @todo: this is hideous, there must be a "right way" to do this, im dumb!
-- outside the recursion table of seen recurses so we dont cycle into our components that refer back to ourselves
_LogDeepprint_alreadyseen = {}


-- the inner recursion for the LogDeep print
function _LogDeepToString(debugInstance, prefix)
	local string_accum = ""
	if debugInstance == nil then
		return "LogDeep Print of NULL" .. "\n"
	end
	if prefix == "" then  -- special case for outer call - so we dont end up iterating strings, basically
		if type(debugInstance) == "table" or type(debugInstance) == "table" or type(debugInstance) == "UNKNOWN" or type(debugInstance) == "table" then
			string_accum = string_accum .. (type(debugInstance) == "table" and "[" or "{") .. "\n"
			prefix = "   "
	else
		return " = " .. (type(debugInstance) == "string" and ("\"" .. debugInstance .. "\"") or debugInstance) .. "\n"
	end
	end
	local debugOver = type(debugInstance) == "UNKNOWN" and getclass(debugInstance) or debugInstance
	for idx, val in pairs(debugOver) do
		local data_value = debugInstance[idx]
		if type(data_value) == "table" or type(data_value) == "table" or type(data_value) == "UNKNOWN" or type(data_value) == "table" then
			if vlua.find(_LogDeepprint_alreadyseen, data_value) ~= nil then
				string_accum = string_accum .. prefix .. idx .. " ALREADY SEEN " .. "\n"
			else
				local is_array = type(data_value) == "table"
				string_accum = string_accum .. prefix .. idx .. " = ( " .. type(data_value) .. " )" .. "\n"
				string_accum = string_accum .. prefix .. (is_array and "[" or "{") .. "\n"
				table.insert(_LogDeepprint_alreadyseen, data_value)
				string_accum = string_accum .. _LogDeepToString(data_value, prefix .. "   ")
				string_accum = string_accum .. prefix .. (is_array and "]" or "}") .. "\n"
			end
		else
			--string_accum = string_accum .. prefix .. idx .. "\t= " .. (type(data_value) == "string" and ("\"" .. data_value .. "\"") or data_value) .. "\n"
			string_accum = string_accum .. prefix .. idx .. "\t= " .. "\"" .. tostring(data_value) .. "\"" .. "\n"
		end
	end
	if prefix == "   " then
		string_accum = string_accum .. (type(debugInstance) == "table" and "]" or "}") .. "\n" -- hack for "proving" at end - this is DUMB!
	end
	return string_accum
end


scripthelp_LogDeepString = "Convert a class/array/instance/table to a string"

function LogDeepToString(debugInstance, prefix)
	prefix = prefix or ""
	_LogDeepprint_alreadyseen = {}
	table.insert(_LogDeepprint_alreadyseen, debugInstance)
	return _LogDeepToString(debugInstance, prefix)
end


scripthelp_LogDeepPrint = "Print out a class/array/instance/table to the console"

function LogDeepPrint(debugInstance, prefix)
	prefix = prefix or ""
	LogEndLine(LogDeepToString(debugInstance, prefix))
end
