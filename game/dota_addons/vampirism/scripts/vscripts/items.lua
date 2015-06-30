function CheckLumber( keys )
	print('checking lumber for item')
	PrintTable(keys)
end

function CoinUsed(keys)
	local caster = keys.caster
	local coin = keys.ability
	local playerID = caster:GetMainControllingPlayer()

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
	local gooddist = keys.MaxBlink

	local dist_vec =  point - caster:GetAbsOrigin()

	if dist_vec:Length2D() > keys.MaxBlink then
		point = caster:GetAbsOrigin() + (point - caster:GetAbsOrigin()):Normalized() * keys.MaxBlink
	end

	caster:SetAbsOrigin(point)
	FindClearSpaceForUnit(caster, point, false)
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
	local targetUnit = nil
	local interval = false
	local casterTeam = caster:GetTeamNumber()
	local particleDamageBuilding = "particles/units/heroes/hero_death_prophet/death_prophet_exorcism_attack_building_glows.vpcf"

	Timers:CreateTimer(function ()
      	local units = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, ghostRange, ability:GetAbilityTargetTeam(), DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO, 0, FIND_CLOSEST, false)
		for k, v in pairs(units) do
			--finds nearest enemy unit.
			if v:GetTeamNumber() ~= casterTeam and v:GetUnitName() ~= 'ring_ghost' and v:IsInvulnerable() ~= true and v:NotOnMinimap() ~= true then
				targetUnit = v
				if ghostStock > 0 and interval == false then
					newGhost(targetUnit)
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
	        	ghost:Destroy()
	        	Timers:CreateTimer(2, function ()
	        		ghostStock = ghostStock + 1
	        	end)
			end

			if ghost.current_target == nil or ghost.current_target:IsInvulnerable() == true then
				ghost:SetPhysicsVelocity(Vector(0,0,0))
	        	ghost:OnPhysicsFrame(nil)
	        	ghost:ForceKill(false)
	        	ghost:Destroy()
	        	Timers:CreateTimer(2, function ()
	        		ghostStock = ghostStock + 1
	        	end)
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
	if mercName == 'merc_avernal' then
		merc:FindAbilityByName('avernal_hp_growth'):OnUpgrade()
	end
end

-- Stops from casting on non-slayers.
function PulseStaffCheck( keys )
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability

	if target:GetUnitName() ~= 'npc_dota_hero_invoker' then
		target:Stop()
		FireGameEvent('custom_error_show', {player_ID = playerID, _error = 'Can only be cast on Slayers!'})
		ability:EndCooldown()
		ability:RefundManaCost()
	else
		PulseStaff(keys)
	end
end

function PulseStaff( keys )
	local caster = keys.caster
	local target = keys.target
	local targetPos = target:GetAbsOrigin()
	local ability = keys.ability
	local targetTeam = ability:GetAbilityTargetTeam()
	local targetType = ability:GetAbilityTargetType()
	local abilityDamage = ability:GetSpecialValueFor('damage')
	local damageType = ability:GetAbilityDamageType()

	local chainP = ParticleManager:CreateParticle("particles/items_fx/chain_lightning.vpcf", PATTACH_CUSTOMORIGIN, caster)
	ParticleManager:SetParticleControlEnt(chainP, 0, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(chainP, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	ApplyDamage({victim = target, attacker = caster, damage = abilityDamage, damage_type = damageType})

	local newUnit = FindUnitsInRadius(caster:GetTeam(), targetPos, nil, 500, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_CLOSEST, false)

	for k, v in pairs(newUnit) do
		if v:GetUnitName() == 'npc_dota_hero_invoker' then
			newUnit = v
		end
	end
	if newUnit ~= nil then
		Timers:CreateTimer(0.15, function ()
			ParticleManager:SetParticleControlEnt(chainP, 0, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
			ParticleManager:SetParticleControlEnt(chainP, 1, newUnit, PATTACH_POINT_FOLLOW, "attach_hitloc", newUnit:GetAbsOrigin(), true)
			ApplyDamage({victim = newUnit, attacker = caster, damage = abilityDamage * 0.85, damage_type = damageType})
		end)
	end
end

function ShieldParticle(keys)
	local caster = keys.caster
	local casterPos = caster:GetAbsOrigin()
	particle = ParticleManager:CreateParticle("particles/econ/items/abaddon/abaddon_alliance/abaddon_aphotic_shield_alliance.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControl(particle, 1, Vector(100,0,100))
	ParticleManager:SetParticleControl(particle, 2, Vector(100,0,100))
	ParticleManager:SetParticleControl(particle, 4, Vector(100,0,100))
	ParticleManager:SetParticleControl(particle, 5, Vector(100,0,10))
	ParticleManager:SetParticleControlEnt(particle, 0, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", casterPos, true)

	Timers:CreateTimer(10, function() 
    	ParticleManager:DestroyParticle(particle,false)
	end)
end

function UrnReveal( keys )
	local caster = keys.caster
	local playerID = caster:GetMainControllingPlayer()
	local target = keys.target_points[1]

	local urnSight = CreateUnitByName('vampire_vision_dummy_urn', target, false, caster, PlayerResource:GetPlayer(playerID), caster:GetTeam())

	Timers:CreateTimer(30, function ()
		urnSight:Destroy()
	end)
end