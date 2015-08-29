-- Slayer blink, global version of human blink
function SlayerBlink( keys )
  local caster = keys.caster
  local ability = keys.ability
  local point = keys.target_points[1]
  
  local newSpace = FindGoodSpaceForUnit(caster, point, 500, nil)
  if newSpace ~= false then
    caster:SetAbsOrigin(newSpace)
  else
    FireGameEvent('custom_error_show', {player_ID = caster:GetMainControllingPlayer(), _error = "Can't blink there!"})
    ability:RefundManaCost()
    ability:EndCooldown()
  end
end


-- Slayer tracker, for finding invis units
function SlayerSummonTracker( keys )
  local caster = keys.caster
  local pID = caster:GetMainControllingPlayer()

  local tracker = CreateUnitByName("slayer_tracker", caster:GetAbsOrigin(), true, nil, nil,caster:GetTeam() )
  tracker:SetControllableByPlayer(pID, true)
end


-- Tracker death
function SlayerRemoveTracker( keys )
  local caster = keys.caster
  caster:RemoveSelf()
end

-- Slayer building invuln start
function SlayerBuildingProtection( keys )
  local caster = keys.caster
  local radius = keys.InvulRadius
  local pID = caster:GetMainControllingPlayer()
  local ability = keys.ability

  local nearby_units = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin() , nil, radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false) 

  for i, nearby in ipairs(nearby_units) do
    if nearby:GetMainControllingPlayer() == pID then
      if nearby:FindAbilityByName("is_a_building") ~= nil then
        ability:ApplyDataDrivenModifier(caster, nearby, "modifier_building_invulnerable", nil)
      end
    end
  end
end

-- Slayer building invuln end
function SlayerBuildingProtectionEnd( keys )
  local caster = keys.caster
  local radius = keys.InvulRadius
  local pID = caster:GetMainControllingPlayer()

  local nearby_units = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin() , nil, radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false) 

  for i, nearby in ipairs(nearby_units) do
    if nearby:GetMainControllingPlayer() == pID then
      if nearby:HasModifier("modifier_building_invulnerable") == true then
        nearby:RemoveModifierByName("modifier_building_invulnerable")
      end
    end
  end
end

-- Slayer Avatar
function SlayerAvatarStart( keys )
  local caster = keys.caster
  local modelscale = keys.Modelscale
  local scalefinish = 1.0 + modelscale * 1.0 / 100.0
  local scale = 1.0

  Timers:CreateTimer(0.3, function ()
    if scale < scalefinish then
      caster:SetModelScale(scale)
      scale = scale + 0.01
      return 0.03
    else
      return nil
    end
  end)
end

-- Slayer Avatar end
function SlayerAvatarEnd( keys )
  local caster = keys.caster
  local modelscale = keys.Modelscale
  local scalestart = 1.0 + modelscale * 1.0 / 100.0
  local scalefinish = 1.0

  Timers:CreateTimer(0.3, function ()
    if scalestart > scalefinish then
      caster:SetModelScale(scalestart)
      scalestart = scalestart - 0.01
      return 0.03
    else
      return nil
    end
  end)
end

-- Check that the player can summon a slayer, otherwise stop.
function SummonSlayer( keys )
  local caster = keys.caster
  local ability = keys.ability
  local pID = caster:GetMainControllingPlayer()
  local player = PlayerResource:GetPlayer(pID)
  local lumberCost = ABILITY_KV[ability:GetAbilityName()].LumberCost
  local goldCost = ABILITY_KV[ability:GetAbilityName()].GoldCost
  local foodCost = 10

  if SLAYERS[pID] ~= nil then
    caster.refundGold = 0
    caster.refundWood = 0
    caster.refundFood = 0
    FireGameEvent( 'custom_error_show', { player_ID = caster:GetMainControllingPlayer() , _error = "Only one slayer per player." } )
    caster:Stop()
    return
  end

  if lumberCost == nil then
    lumberCost = 0
  end
  if goldCost == nil then
    goldCost = 0
  end

  -- Check that the player can afford the slayer, if not break out of the function
  if WOOD[pID] < lumberCost then
    caster:Stop()
    caster.refundGold = 0
    caster.refundWood = 0
    caster.refundFood = 0
    FireGameEvent( 'custom_error_show', { player_ID = pID, _error = "You need more wood" } )
    return
  end
  caster.refundWood = lumberCost

  if GOLD[pID] < goldCost then
    caster:Stop()
    caster.refundGold = 0
    caster.refundWood = 0
    caster.refundFood = 0
    FireGameEvent( 'custom_error_show', { player_ID = pID, _error = "You need more gold" } )
    return
  end
  caster.refundGold = goldCost

  if CURRENT_FOOD[pID] + foodCost > TOTAL_FOOD[pID] then
    caster:Stop()
    caster.refundGold = 0
    caster.refundWood = 0
    caster.refundFood = 0
    FireGameEvent('custom_error_show', {player_ID = pID, _error = "You need more food!"})
    return
  end

  if CURRENT_FOOD[pID] + foodCost > 250 then
    caster:Stop()
    caster.refundWood = 0
    caster.refundGold = 0
    caster.refundFood = 0
    FireGameEvent('custom_error_show', {player_ID = pID, _error = "Max food reached!"})
    return
  end

  -- Checks passed, deduct the resources and start channeling
  ChangeWood(pID, -1 * lumberCost)
  ChangeGold(pID, -1 * goldCost)
  caster.refundWood = lumberCost
  caster.refundGold = goldCost
  caster.refundFood = 10
  CURRENT_FOOD[pID] = CURRENT_FOOD[pID] + foodCost
  CustomGameEventManager:Send_ServerToPlayer(player, "update_resource", {["resourceType"] = "currentFood", ["value"] = CURRENT_FOOD[pID]})
  FireGameEvent('vamp_food_changed', { player_ID = pID , food_total = CURRENT_FOOD[pID]})
end

function Refund( keys )
  local caster = keys.caster
  local pID = caster:GetMainControllingPlayer()
  local player = PlayerResource:GetPlayer(pID)
  local ability = keys.ability
  
  local refundWood = caster.refundWood
  local refundGold = caster.refundGold
  local refundFood = caster.refundFood

  if refundWood == nil then
    refundWood = 0
  end
  if refundGold == nil then
    refundGold = 0
  end
  if refundFood == nil then
    refundFood = 0
  end

  if HAS_SLAYER[pID] == nil then
    ChangeWood(pID, refundWood)
    ChangeGold(pID, refundGold)
    CURRENT_FOOD[pID] = CURRENT_FOOD[pID] - refundFood
    CustomGameEventManager:Send_ServerToPlayer(player, "update_resource", {["resourceType"] = "currentFood", ["value"] = CURRENT_FOOD[pID]})
  end
end

-- Function that spawns the slayer on channel success
function SpawnSlayer( keys )
  local caster = keys.caster
  local pID = caster:GetMainControllingPlayer()

  SLAYERS[pID] = {["state"] = "alive", ["upgrades"] = {}}

  local slayer = CreateHeroForPlayer("npc_dota_hero_invoker", PlayerResource:GetPlayer(pID))
  --local slayer = CreateUnitByName("npc_dota_hero_invoker", caster:GetAbsOrigin(), true, nil, nil, caster:GetTeam())
  slayer:SetControllableByPlayer(pID, true)
  slayer:SetOwner(EntIndexToHScript(pID))
  slayer:FindAbilityByName("slayer_blink"):SetLevel(1)
  slayer:SetHullRadius(48)

  local newSpace = FindGoodSpaceForUnit(slayer, caster:GetAbsOrigin(), 350, 200)
  if newSpace ~= false then
    slayer:SetAbsOrigin(newSpace)
  end


  SLAYERS[pID].handle = slayer
  FireGameEvent("vamp_slayer_state_update", {player_ID = playerID, slayer_state = "Alive"})

  SLAYERS[pID]['health'] = {}
  SLAYERS[pID]['damage'] = {}
  SLAYERS[pID]['strength'] = {}
  SLAYERS[pID]['agility'] = {}
  SLAYERS[pID]['intellect'] = {}

  slayer:SetAbilityPoints(0)
    
  local name = PlayerResource:GetPlayerName(pID)
  local time = GameRules:GetDOTATime(false, false)
  local formatted = ''

  local mins = math.floor(time / 60)
  local secs = math.floor(time % 60)
  if secs < 10 then
    formatted = "0"..tostring(secs)
  else
    formatted = tostring(secs)
  end
  if mins > 0  then
    formatted = mins..":"..formatted
  else
    formatted = '0'..":"..secs
  end
  GameRules:SendCustomMessage(ColorIt(name, IDToColour(pID)) .. " created a slayer at "..formatted, 0, 0)

  GameMode:ModifyStatBonuses(slayer)
end

-- Revive Slayer
function SlayerRespawnStart( keys )
  local caster = keys.caster
  local pID = caster:GetMainControllingPlayer()
  local player = PlayerResource:GetPlayer(pID)

  if SLAYERS[pID] == nil then
    caster:Stop()
    return nil
  end

  if SLAYERS[pID].state == "alive" then
    FireGameEvent( 'custom_error_show', { player_ID = pID, _error = "Slayer is currently alive" } )
    caster:Stop()
    return nil
  end

  if SLAYERS[pID].state == "reviving" then
    FireGameEvent( 'custom_error_show', { player_ID = pID, _error = "Slayer is currently reviving" } )
    caster:Stop()
    return nil
  end

  if CURRENT_FOOD[pID] > TOTAL_FOOD[pID] + 10 then
    caster:Stop()
    FireGameEvent('custom_error_show', {player_ID = pID, _error = "You need more food!"})
    return
  end

  if CURRENT_FOOD[pID] + 10 > 250 then
    caster:Stop()
    FireGameEvent('custom_error_show', {player_ID = pID, _error = "Max food reached!"})
    return
  end

  SLAYERS[pID].state = "reviving"
  CURRENT_FOOD[pID] = CURRENT_FOOD[pID] + 10
  CustomGameEventManager:Send_ServerToPlayer(player, "update_resource", {["resourceType"] = "currentFood", ["value"] = CURRENT_FOOD[pID]})
  FireGameEvent("vamp_slayer_state_update", {player_ID = playerID, slayer_state = "Reviving"})
end

function SlayerRespawnInterrupted( keys )
  local caster = keys.caster
  local pID = caster:GetMainControllingPlayer()
  local player = PlayerResource:GetPlayer(pID)

  if SLAYERS[pID] == nil then
    return nil
  end

  if SLAYERS[pID].state == "reviving" then
   SLAYERS[pID].state = "dead"
   CURRENT_FOOD[pID] = CURRENT_FOOD[pID] - 10
   CustomGameEventManager:Send_ServerToPlayer(player, "update_resource", {["resourceType"] = "currentFood", ["value"] = CURRENT_FOOD[pID]})
   FireGameEvent("vamp_slayer_state_update", {player_ID = playerID, slayer_state = "Dead"})
  end
end

function SlayerRespawn( keys )
  local caster = keys.caster
  local pID = caster:GetMainControllingPlayer()
  local slayer = SLAYERS[pID].handle

  slayer:RespawnUnit()
  GameMode:ModifyStatBonuses(SLAYERS[pID].handle)
  local newSpace = FindGoodSpaceForUnit(slayer, caster:GetAbsOrigin(), 350, 200)
  if newSpace ~= false then
    slayer:SetAbsOrigin(newSpace)
  end

  --This does not appear to be saved by the game.
  for k, v in pairs(SLAYERS[pID]['health']) do
    slayer:SetMaxHealth(slayer:GetMaxHealth() + v)
    slayer:SetHealth(slayer:GetHealth() + v)
  end

  --This is being saved by the game.
  --for k, v in pairs(SLAYERS[pID]['damage']) do
  --  slayer:SetBaseDamageMax(slayer:GetBaseDamageMax() + v)
  --  slayer:SetBaseDamageMin(slayer:GetBaseDamageMin() + v)
  --end

  -- This may actually be saved by the game, without needing this table.
  for k, v in pairs(SLAYERS[pID]['strength']) do
    slayer:SetBaseStrength(slayer:GetBaseStrength() + v)
  end
  for k, v in pairs(SLAYERS[pID]['agility']) do
    slayer:SetBaseAgility(slayer:GetBaseAgility() + v)
  end
  for k, v in pairs(SLAYERS[pID]['intellect']) do
    slayer:SetBaseIntellect(slayer:GetBaseIntellect() + v)
  end

  GameMode:ModifyStatBonuses(SLAYERS[pID].handle)
end

-- A skill was upgraded, remove the ability point from tracking.
function RemoveAbilityPoint( keys )
  local caster = keys.caster
  local playerID = caster:GetMainControllingPlayer()

  if SLAYERS[playerID].handle.AbilityPoints ~= nil then
    SLAYERS[playerID].handle.AbilityPoints = SLAYERS[playerID].handle.AbilityPoints - 1
  end
end