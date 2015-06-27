function CheckLumber( keys )
	print('checking lumber for item')
	PrintTable(keys)
end

function CoinUsed(keys)
	local caster = keys.caster
	local coin = keys.ability
	local playerID = caster:GetMainControllingPlayer()
	local playerGold = GOLD[playerID]
	print(playerGold)

	if caster:IsRealHero() then
    	if keys.Type == "small" then
    		GOLD[playerID] = GOLD[playerID] + 1
    		FireGameEvent('vamp_gold_changed', {player_ID = playerID, gold_total = GOLD[playerID]})
    end
    	if keys.Type == "large" then
    		GOLD[playerID] = GOLD[playerID] + 2
      		FireGameEvent('vamp_gold_changed', {player_ID = playerID, gold_total = GOLD[playerID]})
    	end
	end
end

function ItemMoveSpeed( keys )
	--do this later hehe
end

function SphereDoom( keys )
	local caster = keys.caster
	local ability = keys.ability
	local point = keys.target_points[1]

	-- Move a "test unit", find the distance between them and see if it's ok then move the vamp
	FindClearSpaceForUnit(caster, point, false)

	local dist = CalcDistanceBetweenEntityOBB(caster, caster)

	if dist < gooddist then
		FindClearSpaceForUnit(caster, point, false)
	else
		FireGameEvent("custom_error_show", {player_ID = caster:GetMainControllingPlayer(), _error = "Vampire doesn't fit here!"}) 
	end
end

function SpawnEngineers( keys )
	local caster = keys.caster
	local playerID = caster:GetMainControllingPlayer()
	local ability = keys.ability

	for i = 1, 4 do
		local engi = CreateUnitByName("toolkit_engineer", caster:GetAbsOrigin(), true, nil, nil, 0)
		engi:SetControllableByPlayer(playerID, true)
	end
end

function VenomOrb( keys )
	local caster = keys.caster
	local ability = keys.ability
	local abilityToAdd = keys.AbilityToAdd

	caster:AddAbility(abilityToAdd)
	local added = caster:FindAbilityByName(abilityToAdd)
	caster:CastAbilityNoTarget(added, caster:GetMainControllingPlayer())
end

function GhostRing( keys )
	print('inGhostring')
	local caster = keys.caster
	local ability = keys.ability
	local ghostRange = ability:GetLevelSpecialValueFor('range', 1)
	local ghostDamage = ability:GetLevelSpecialValueFor('damage', 1)
	local maxGhosts = ability:GetLevelSpecialValueFor('max_ghosts', 1) 
	local ghostSpeed = ability:GetLevelSpecialValueFor('ghost_speed', 1)
	local ringCD = ability:GetLevelSpecialValueFor('ring_cd', 1) 
	local ghostInterval = ability:GetLevelSpecialValueFor('ghost_interval', 1)
	local abilityDamageType = ability:GetAbilityDamageType()
	local ghostStock = maxGhosts
	local targetBuilding = nil
	local interval = false
	local casterTeam = caster:GetTeamNumber()
	local particleDamageBuilding = "particles/units/heroes/hero_death_prophet/death_prophet_exorcism_attack_building_glows.vpcf"

	print('specials', ghostRange,  ghostDamage, maxGhosts, ghostSpeed, ringCD, ghostInterval, abilityDamageType)

	Timers:CreateTimer(function ()
		local nearBuildings = Entities:FindAllByClassnameWithin('npc_dota_creature', caster:GetAbsOrigin(), ghostRange)
		for k, v in pairs(nearBuildings) do
			--finds nearest enemy building.
			if v:GetTeamNumber() ~= casterTeam and v:GetUnitName() ~= 'ring_ghost' and v:IsInvulnerable() ~= true and v:NotOnMinimap() ~= true then
				targetBuilding = v
				if ghostStock > 0 and interval == false then
					newGhost(targetBuilding)
					ghostStock = ghostStock - 1
					interval = true
					Timers:CreateTimer(ghostInterval, function ()
						interval = false
						return nil
					end)
				end
			end
		end
		return 0.03
	end)


	--Credit to Noya, BMD and anyone who worked on SpellLibrary for this.
	function newGhost(target)
		local ghost = CreateUnitByName('ring_ghost', caster:GetAbsOrigin(), false, nil, nil, 3)
		ghost:AddAbility('ghost_phasing')
		ghost:FindAbilityByName('ghost_phasing'):OnUpgrade()

		Physics:Unit(ghost)
		ghost:PreventDI(true)
		ghost:SetAutoUnstuck(false)
		ghost:SetNavCollisionType(PHYSICS_NAV_NOTHING)
		ghost:FollowNavMesh(false)
		ghost:SetPhysicsVelocityMax(ghostSpeed)
		ghost:SetPhysicsVelocity(target:GetAbsOrigin())
		ghost:SetPhysicsFriction(0)
		ghost:Hibernate(false)

		local point = target:GetAbsOrigin()
		ghost:OnPhysicsFrame(function ( ghost )
			-- Move the unit orientation to adjust the particle
			ghost:SetForwardVector( ( ghost:GetPhysicsVelocity() ):Normalized() )
			ghost.current_target = target
			if ghost.current_target:IsNull() then
	        	ghost:SetPhysicsVelocity(Vector(0,0,0))
	        	ghost:OnPhysicsFrame(nil)
	        	ghost:ForceKill(false)
			end
			local source = caster:GetAbsOrigin()
			local current_position = ghost:GetAbsOrigin()
			local diff = point - ghost:GetAbsOrigin()
        	diff.z = 0
        	local direction = diff:Normalized()

        	-- Calculate the angle difference
			local angle_difference = RotationDelta(VectorToAngles(ghost:GetPhysicsVelocity():Normalized()), VectorToAngles(direction)).y
			
			-- Set the new velocity
			if math.abs(angle_difference) < 5 then
				-- CLAMP
				local newVel = ghost:GetPhysicsVelocity():Length() * direction
				ghost:SetPhysicsVelocity(newVel)
			elseif angle_difference > 0 then
				local newVel = RotatePosition(Vector(0,0,0), QAngle(0,10,0), ghost:GetPhysicsVelocity())
				ghost:SetPhysicsVelocity(newVel)
			else		
				local newVel = RotatePosition(Vector(0,0,0), QAngle(0,-10,0), ghost:GetPhysicsVelocity())
				ghost:SetPhysicsVelocity(newVel)
			end
        	local distance = (point - current_position):Length()
			local collision = distance < 50
			if ghost.current_target then
				point = ghost.current_target:GetAbsOrigin()
			end

			if collision then
				if ghost.current_target ~= nil and ghost.current_target:IsInvulnerable() ~= true then

					local damage_table = {
						victim = ghost.current_target,
						attacker = caster,
						damage_type = DAMAGE_TYPE_MAGICAL,
						damage = 50
					}
	
					ApplyDamage(damage_table)
					local particle = ParticleManager:CreateParticle(particleDamageBuilding, PATTACH_ABSORIGIN, ghost.current_target)
					ParticleManager:SetParticleControl(particle, 0, ghost.current_target:GetAbsOrigin())
					ParticleManager:SetParticleControlEnt(particle, 1, ghost.current_target, PATTACH_POINT_FOLLOW, "attach_hitloc", ghost.current_target:GetAbsOrigin(), true)
					ghost:SetPhysicsVelocity(Vector(0,0,0))
	        		ghost:OnPhysicsFrame(nil)
	        		ghost:ForceKill(false)
	        		ghost:Destroy()

	        		Timers:CreateTimer(2, function ()
	        			ghostStock = ghostStock + 1
	        		end)
	        	end
			end
		end)
	end
end

-- Handles all unit hiring behavior
function HireUnit( keys )
	local caster = keys.caster
	local ability = keys.ability
	local foodCost = ITEM_KV[ability:GetAbilityName()]['FoodCost']
	local mercName = keys.Mercenary
	local playerID = caster:GetMainControllingPlayer()

	local merc = CreateUnitByName(mercName, caster:GetAbsOrigin(), true, caster, PlayerResource:GetPlayer(playerID), caster:GetTeam())
	merc:SetControllableByPlayer(playerID, true)

	-- initialize specific mercenary abilities
	if mercName == 'merc_shade' then
		merc:AddNewModifier(caster, nil, "modifier_invisible", {})
	end
end