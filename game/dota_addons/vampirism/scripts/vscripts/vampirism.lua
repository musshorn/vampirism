print ('[vampirism] vampirism.lua' )

ENABLE_HERO_RESPAWN = true              -- Should the heroes automatically respawn on a timer or stay dead until manually respawned
UNIVERSAL_SHOP_MODE = false             -- Should the main shop contain Secret Shop items as well as regular items
ALLOW_SAME_HERO_SELECTION = true        -- Should we let people select the same hero as each other

HERO_SELECTION_TIME = 0.0             -- How long should we let people select their hero?
PRE_GAME_TIME = 56.0                    -- How long after people select their heroes should the horn blow and the game start?
POST_GAME_TIME = 60.0                   -- How long should we let people look at the scoreboard before closing the server automatically?
TREE_REGROW_TIME = 60.0                 -- How long should it take individual trees to respawn after being cut down/destroyed?

GOLD_PER_TICK = 0                     -- How much gold should players get per tick?
GOLD_TICK_TIME = 5                      -- How long should we wait in seconds between gold ticks?

RECOMMENDED_BUILDS_DISABLED = true     -- Should we disable the recommened builds for heroes (Note: this is not working currently I believe)
CAMERA_DISTANCE_OVERRIDE = 1134.0        -- How far out should we allow the camera to go?  1134 is the default in Dota

MINIMAP_ICON_SIZE = 1                   -- What icon size should we use for our heroes?
MINIMAP_CREEP_ICON_SIZE = 1             -- What icon size should we use for creeps?
MINIMAP_RUNE_ICON_SIZE = 1              -- What icon size should we use for runes?

RUNE_SPAWN_TIME = 120                    -- How long in seconds should we wait between rune spawns?
CUSTOM_BUYBACK_COST_ENABLED = true      -- Should we use a custom buyback cost setting?
CUSTOM_BUYBACK_COOLDOWN_ENABLED = true  -- Should we use a custom buyback time?
BUYBACK_ENABLED = false                 -- Should we allow people to buyback when they die?

DISABLE_FOG_OF_WAR_ENTIRELY = false      -- Should we disable fog of war entirely for both teams?
--USE_STANDARD_DOTA_BOT_THINKING = false  -- Should we have bots act like they would in Dota? (This requires 3 lanes, normal items, etc)
USE_STANDARD_HERO_GOLD_BOUNTY = true    -- Should we give gold for hero kills the same as in Dota, or allow those values to be changed?

USE_CUSTOM_TOP_BAR_VALUES = true        -- Should we do customized top bar values or use the default kill count per team?
TOP_BAR_VISIBLE = false                  -- Should we display the top bar score/count at all?
SHOW_KILLS_ON_TOPBAR = true             -- Should we display kills only on the top bar? (No denies, suicides, kills by neutrals)  Requires USE_CUSTOM_TOP_BAR_VALUES

ENABLE_TOWER_BACKDOOR_PROTECTION = false-- Should we enable backdoor protection for our towers?
REMOVE_ILLUSIONS_ON_DEATH = false       -- Should we remove all illusions if the main hero dies?
DISABLE_GOLD_SOUNDS = false             -- Should we disable the gold sound when players get gold?

END_GAME_ON_KILLS = false                -- Should the game end after a certain number of kills?
KILLS_TO_END_GAME_FOR_TEAM = 50         -- How many kills for a team should signify an end of game?

USE_CUSTOM_HERO_LEVELS = true           -- Should we allow heroes to have custom levels?
MAX_LEVEL = 200                          -- What level should we let heroes get to?
USE_CUSTOM_XP_VALUES = true             -- Should we use custom XP values to level up heroes, or the default Dota numbers?

WOOD = {}
TOTAL_FOOD = {}
CURRENT_FOOD = {}

UNIT_KV = {} -- Each player has their own UNIT_KV file that research modifies properties of
ABILITY_KV = LoadKeyValues("scripts/npc/npc_abilities_custom.txt")
LUMBER_DROPS = {} -- table with handles to all the buildings that can recieve lumber
VAMP_COUNT = 0
HUMAN_COUNT = 0

-- Fill this table up with the required XP per level if you want to change it
XP_PER_LEVEL_TABLE = {}
XP_PER_LEVEL_TABLE[1] = 0
for i=2,MAX_LEVEL do
  XP_PER_LEVEL_TABLE[i] = XP_PER_LEVEL_TABLE[i - 1] + i * 80
end

-- Generated from template
if GameMode == nil then
    print ( '[vampirism] creating vampirism game mode' )
    GameMode = class({})
end


--[[
  This function should be used to set up Async precache calls at the beginning of the game.  The Precache() function 
  in addon_game_mode.lua used to and may still sometimes have issues with client's appropriately precaching stuff.
  If this occurs it causes the client to never precache things configured in that block.

  In this function, place all of your PrecacheItemByNameAsync and PrecacheUnitByNameAsync.  These calls will be made
  after all players have loaded in, but before they have selected their heroes. PrecacheItemByNameAsync can also
  be used to precache dynamically-added datadriven abilities instead of items.  PrecacheUnitByNameAsync will 
  precache the precache{} block statement of the unit and all precache{} block statements for every Ability# 
  defined on the unit.

  This function should only be called once.  If you want to/need to precache more items/abilities/units at a later
  time, you can call the functions individually (for example if you want to precache units in a new wave of
  holdout).
]]
function GameMode:PostLoadPrecache()
  print("[vampirism] Performing Post-Load precache") 
  PrecacheUnitByNameAsync("house_t1", function(...) end)   
  --PrecacheItemByNameAsync("item_example_item", function(...) end)
  --PrecacheItemByNameAsync("example_ability", function(...) end)

  --PrecacheUnitByNameAsync("npc_dota_hero_viper", function(...) end)
  --PrecacheUnitByNameAsync("npc_dota_hero_enigma", function(...) end)
  --PrecacheUnitByNameAsync("npc_precache_everything", function(...) end)
end

--[[
  This function is called once and only once as soon as the first player (almost certain to be the server in local lobbies) loads in.
  It can be used to initialize state that isn't initializeable in InitGameMode() but needs to be done before everyone loads in.
]]
function GameMode:OnFirstPlayerLoaded()
  print("[vampirism] First Player has loaded")
end

--[[
  This function is called once and only once after all players have loaded into the game, right as the hero selection time begins.
  It can be used to initialize non-hero player state or adjust the hero selection (i.e. force random etc)
]]
function GameMode:OnAllPlayersLoaded()
  print("[vampirism] All Players have loaded into the game")

    local dummy = CreateUnitByName("npc_bh_dummy", Vector(0,0,0), true, nil, nil, 0)
    local particle = ParticleManager:CreateParticle("particles/vampire/shadow_demon_disruption.vpcf",  PATTACH_ABSORIGIN, dummy)
    dummy:FindAbilityByName("vampire_vision_dummy_lock2"):OnUpgrade()
    ParticleManager:SetParticleControl(particle, 0, Vector(96, -416, 570))
  
    local sigil = CreateUnitByName("util_vampire_spawn_particles", Vector(96, -416, -200), false, nil, nil, 0)
    sigil:FindAbilityByName("vampire_particle_call"):OnUpgrade()
  
    local portalvision = CreateUnitByName("vampire_vision_dummy_3", Vector(96, -416, 220), false, nil, nil, DOTA_TEAM_BADGUYS)

end

--[[
  This function is called once and only once for every player when they spawn into the game for the first time.  It is also called
  if the player's hero is replaced with a new hero for any reason.  This function is useful for initializing heroes, such as adding
  levels, changing the starting gold, removing/adding abilities, adding physics, etc.

  The hero parameter is the hero entity that just spawned in
]]
function GameMode:OnHeroInGame(hero)
  print("[vampirism] Hero spawned in game for first time -- " .. hero:GetUnitName())

  --[[ Multiteam configuration, currently unfinished

  local team = "team1"
  local playerID = hero:GetPlayerID()
  if playerID > 3 then
    team = "team2"
  end
  print("setting " .. playerID .. " to team: " .. team)
  MultiTeam:SetPlayerTeam(playerID, team)]]

  -- This line for example will set the starting gold of every hero to 500 unreliable gold
  hero:SetGold(0, false)

  -- These lines will create an item and add it to the player, effectively ensuring they start with the item
  --local item = CreateItem("item_multiteam_action", hero, hero)
  --hero:AddItem(item)

  --[[ --These lines if uncommented will replace the W ability of any hero that loads into the game
    --with the "example_ability" ability

  local abil = hero:GetAbilityByIndex(1)
  hero:RemoveAbility(abil:GetAbilityName())
  hero:AddAbility("example_ability")]]
end

--[[
  This function is called once and only once when the game completely begins (about 0:00 on the clock).  At this point,
  gold will begin to go up in ticks if configured, creeps will spawn, towers will become damageable etc.  This function
  is useful for starting any game logic timers/thinkers, beginning the first round, etc.
]]
function GameMode:OnGameInProgress()
  print("[vampirism] The game has officially begun")
  local vamps = Entities:FindAllByName("npc_dota_hero_night_stalker")

  for i = 1, table.getn(vamps) do
  	print(vamps[i]:GetUnitName())
  	vamps[i]:RemoveModifierByName("modifier_init_hider")
  	vamps[i]:SetAbilityPoints(3)
    FindClearSpaceForUnit(vamps[i], Vector(96, -416, 256), false)
  end
end




-- Cleanup a player when they leave
function GameMode:OnDisconnect(keys)
  print('[vampirism] Player Disconnected ' .. tostring(keys.userid))
  PrintTable(keys)

  local name = keys.name
  local networkid = keys.networkid
  local reason = keys.reason
  local userid = keys.userid

end
-- The overall game state has changed
function GameMode:OnGameRulesStateChange(keys)
  print("[vampirism] GameRules State Changed")
  PrintTable(keys)

  local newState = GameRules:State_Get()
  if newState == DOTA_GAMERULES_STATE_WAIT_FOR_PLAYERS_TO_LOAD then
    self.bSeenWaitForPlayers = true
  elseif newState == DOTA_GAMERULES_STATE_INIT then
    Timers:RemoveTimer("alljointimer")
  elseif newState == DOTA_GAMERULES_STATE_HERO_SELECTION then
    local et = 6
    if self.bSeenWaitForPlayers then
      et = .01
    end
    Timers:CreateTimer("alljointimer", {
      useGameTime = true,
      endTime = et,
      callback = function()
        if PlayerResource:HaveAllPlayersJoined() then
          GameMode:PostLoadPrecache()
          GameMode:OnAllPlayersLoaded()
          return  
        end
        return 1
      end
      })
  elseif newState == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
    GameMode:OnGameInProgress()
  end
end

-- An NPC has spawned somewhere in game.  This includes heroes
function GameMode:OnNPCSpawned(keys)

  print("[vampirism] NPC Spawned")

  local npc = EntIndexToHScript(keys.entindex)
  local playerID = npc:GetPlayerOwnerID()

  if npc:GetName() == "npc_dota_hero_omniknight" then
  	npc:FindAbilityByName("call_buildui"):SetLevel(1)
  	npc:FindAbilityByName("human_blink"):SetLevel(1)
  	npc:FindAbilityByName("human_manaburn"):SetLevel(1)
  	npc:FindAbilityByName("human_repair"):SetLevel(1)
    if playerID < 8 then 
      WOOD[playerID] = 50
      TOTAL_FOOD[playerID] = 15
      CURRENT_FOOD[playerID] = 0
      UNIT_KV[playerID] = LoadKeyValues("scripts/npc/npc_units_custom.txt")
      UNIT_KV[playerID].Version = nil -- Value is made by LoadKeyValues, pretty annoying for iterating so we'll remove it
      print("made 40 wood for player "..playerID)
      HUMAN_COUNT = HUMAN_COUNT + 1
      npc:SetAbilityPoints(0)
      PlayerResource:SetCustomTeamAssignment(playerID, DOTA_TEAM_GOODGUYS)
    end
  end

  local newState = GameRules:State_Get()
  if newState == DOTA_GAMERULES_STATE_PRE_GAME then
 	print('pregame')
  end

  if npc:GetName() == "npc_dota_hero_night_stalker" then
  	if newState == DOTA_GAMERULES_STATE_PRE_GAME then
  		--Next frame timer
  		Timers:CreateTimer(0.03, function ()
  			npc:FindAbilityByName("vampire_init_hider"):OnUpgrade()
  			npc:SetAbsOrigin(OutOfWorldVector)
    		npc:FindAbilityByName("vampire_particles"):OnUpgrade()
        npc:SetAbilityPoints(0)
    		VAMP_COUNT = VAMP_COUNT + 1
    		return nil
  		end)
    end
  end
  if npc:IsRealHero() and npc.bFirstSpawned == nil then
    npc.bFirstSpawned = true
    GameMode:OnHeroInGame(npc)
  end

  if npc:GetUnitName() == "tower_pearls" then
    npc:FindAbilityByName("is_a_building"):OnUpgrade()
  end

  if string.match(npc:GetUnitName(), "vampire_vision_dummy") then
    VisionDummy(npc)
  end
  
  --TechTree:GetRequired(npc:GetUnitName(), npc:GetMainControllingPlayer())
end

-- An entity somewhere has been hurt.  This event fires very often with many units so don't do too many expensive
-- operations here
function GameMode:OnEntityHurt(keys)
  print("[vampirism] Entity Hurt")
  local entCause = EntIndexToHScript(keys.entindex_attacker)
  local entVictim = EntIndexToHScript(keys.entindex_killed)

  -- Buildings attacked by the worker are instantly killed
  if entCause:GetMainControllingPlayer() == entVictim:GetMainControllingPlayer() then
    local ability = entVictim:FindAbilityByName("is_a_building")
    if entCause:GetUnitName() == "npc_dota_hero_omniknight" and ability ~= nil then
      entVictim:ForceKill(true)
    end
  end
end

-- An item was picked up off the ground
function GameMode:OnItemPickedUp(keys)
  print ( '[vampirism] OnItemPurchased' )
  PrintTable(keys)

  local heroEntity = EntIndexToHScript(keys.HeroEntityIndex)
  local itemEntity = EntIndexToHScript(keys.ItemEntityIndex)
  local player = PlayerResource:GetPlayer(keys.PlayerID)
  local itemname = keys.itemname
end

-- A player has reconnected to the game.  This function can be used to repaint Player-based particles or change
-- state as necessary
function GameMode:OnPlayerReconnect(keys)
  print ( '[vampirism] OnPlayerReconnect' )
  PrintTable(keys) 
end

-- An item was purchased by a player
function GameMode:OnItemPurchased( keys )
  print ( '[vampirism] OnItemPurchased' )
  PrintTable(keys)

  -- The playerID of the hero who is buying something
  local plyID = keys.PlayerID
  if not plyID then return end

  -- The name of the item purchased
  local itemName = keys.itemname 
  
  -- The cost of the item purchased
  local itemcost = keys.itemcost
  
end

-- An ability was used by a player
function GameMode:OnAbilityUsed(keys)
  print('[vampirism] AbilityUsed')
  PrintTable(keys)

  local player = EntIndexToHScript(keys.PlayerID)
  local abilityname = keys.abilityname
  local hero = player:GetAssignedHero()

  -- Cancel the ghost if the player casts another active ability.
  -- Start of BH Snippet:
  if hero ~= nil then
    local abil = hero:FindAbilityByName(abilityname)
    if player.cursorStream ~= nil then
      if not (string.len(abilityname) > 14 and string.sub(abilityname,1,14) == "move_to_point_") then
        if not DontCancelBuildingGhostAbils[abilityname] then
          player.cancelBuilding = true
        else
          print(abilityname .. " did not cancel building ghost.")
        end
      end
    end
  end
  -- End of BH Snippet
end

-- A non-player entity (necro-book, chen creep, etc) used an ability
function GameMode:OnNonPlayerUsedAbility(keys)
  print('[vampirism] OnNonPlayerUsedAbility')
  PrintTable(keys)

  local abilityname =  keys.abilityname
end

-- A player changed their name
function GameMode:OnPlayerChangedName(keys)
  print('[vampirism] OnPlayerChangedName')
  PrintTable(keys)

  local newName = keys.newname
  local oldName = keys.oldName
end



-- A player leveled up an ability
function GameMode:OnPlayerLearnedAbility( keys)
  print ('[vampirism] OnPlayerLearnedAbility')
  PrintTable(keys)

  local player = EntIndexToHScript(keys.player)
  local abilityname = keys.abilityname
end

-- A channelled ability finished by either completing or being interrupted
function GameMode:OnAbilityChannelFinished(keys)
  print ('[vampirism] OnAbilityChannelFinished')
  PrintTable(keys)

  local abilityname = keys.abilityname
  local interrupted = keys.interrupted == 1
end

-- A player leveled up
function GameMode:OnPlayerLevelUp(keys)
  print ('[vampirism] OnPlayerLevelUp')
  PrintTable(keys)

  local player = EntIndexToHScript(keys.player)
  local level = keys.level
end

-- A player last hit a creep, a tower, or a hero
function GameMode:OnLastHit(keys)
  print ('[vampirism] OnLastHit')
  PrintTable(keys)

  local isFirstBlood = keys.FirstBlood == 1
  local isHeroKill = keys.HeroKill == 1
  local isTowerKill = keys.TowerKill == 1
  local player = PlayerResource:GetPlayer(keys.PlayerID)
end

-- A tree was cut down by tango, quelling blade, etc
function GameMode:OnTreeCut(keys)
  print ('[vampirism] OnTreeCut')
  PrintTable(keys)

  local treeX = keys.tree_x
  local treeY = keys.tree_y
end

-- A rune was activated by a player
function GameMode:OnRuneActivated (keys)
  print ('[vampirism] OnRuneActivated')
  PrintTable(keys)

  local player = PlayerResource:GetPlayer(keys.PlayerID)
  local rune = keys.rune

  --[[ Rune Can be one of the following types
  DOTA_RUNE_DOUBLEDAMAGE
  DOTA_RUNE_HASTE
  DOTA_RUNE_HAUNTED
  DOTA_RUNE_ILLUSION
  DOTA_RUNE_INVISIBILITY
  DOTA_RUNE_MYSTERY
  DOTA_RUNE_RAPIER
  DOTA_RUNE_REGENERATION
  DOTA_RUNE_SPOOKY
  DOTA_RUNE_TURBO
  ]]
end

-- A player took damage from a tower
function GameMode:OnPlayerTakeTowerDamage(keys)
  print ('[vampirism] OnPlayerTakeTowerDamage')
  PrintTable(keys)

  local player = PlayerResource:GetPlayer(keys.PlayerID)
  local damage = keys.damage
end

-- A player picked a hero
function GameMode:OnPlayerPickHero(keys)
  print ('[vampirism] OnPlayerPickHero')
  PrintTable(keys)

  local heroClass = keys.hero
  local heroEntity = EntIndexToHScript(keys.heroindex)
  local player = EntIndexToHScript(keys.player)
  if heroEntity:GetUnitName() == "npc_dota_hero_night_stalker" then 
    GameMode:ModifyStatBonuses(heroEntity) 
  end
end

-- A player killed another player in a multi-team context
function GameMode:OnTeamKillCredit(keys)
  print ('[vampirism] OnTeamKillCredit')
  PrintTable(keys)

  local killerPlayer = PlayerResource:GetPlayer(keys.killer_userid)
  local victimPlayer = PlayerResource:GetPlayer(keys.victim_userid)
  local numKills = keys.herokills
  local killerTeamNumber = keys.teamnumber
end

-- An entity died
function GameMode:OnEntityKilled( keys )
  print( '[vampirism] OnEntityKilled Called' )
  PrintTable( keys )
  
  -- The Unit that was Killed
  local killedUnit = EntIndexToHScript( keys.entindex_killed )
  -- The Killing entity
  local killerEntity = nil
  local unitName = killedUnit:GetUnitName()
  local playerID = killedUnit:GetPlayerOwnerID()
  local modelName = killedUnit:GetModelName() 

  if keys.entindex_attacker ~= nil then
    killerEntity = EntIndexToHScript( keys.entindex_attacker )
  end

  if killedUnit:IsRealHero() then 
    print ("KILLEDKILLER: " .. killedUnit:GetName() .. " -- " .. killerEntity:GetName())
    if killedUnit:GetTeam() == DOTA_TEAM_BADGUYS and killerEntity:GetTeam() == DOTA_TEAM_GOODGUYS then
      self.nRadiantKills = self.nRadiantKills + 1
      if END_GAME_ON_KILLS and self.nRadiantKills >= KILLS_TO_END_GAME_FOR_TEAM then
        GameRules:SetSafeToLeave( true )
        GameRules:SetGameWinner( DOTA_TEAM_GOODGUYS )
      end
    elseif killedUnit:GetTeam() == DOTA_TEAM_GOODGUYS and killerEntity:GetTeam() == DOTA_TEAM_BADGUYS then
      self.nDireKills = self.nDireKills + 1
      if END_GAME_ON_KILLS and self.nDireKills >= KILLS_TO_END_GAME_FOR_TEAM then
        GameRules:SetSafeToLeave( true )
        GameRules:SetGameWinner( DOTA_TEAM_BADGUYS )
      end
    end

    if SHOW_KILLS_ON_TOPBAR then
      GameRules:GetGameModeEntity():SetTopBarTeamValue ( DOTA_TEAM_BADGUYS, self.nDireKills )
      GameRules:GetGameModeEntity():SetTopBarTeamValue ( DOTA_TEAM_GOODGUYS, self.nRadiantKills )
    end
  end

  if killedUnit:GetUnitName() == "npc_dota_hero_omniknight" then
    local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_phantom_assassin/phantom_assassin_crit_impact.vpcf", PATTACH_ABSORIGIN_FOLLOW, killedUnit)
    --[[create a unit and flip its facing, to overcome particles following killer, not direction
    killer was facing.]]
    local unit = CreateUnitByName("npc_bh_dummy", killedUnit:GetAbsOrigin(), false, nil, nil, 0)
    local angle = (killerEntity:GetAngles().y + 180) % 360
    unit:SetAngles(0, angle, 0)
    ParticleManager:SetParticleControlEnt(particle, 1, unit, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", killedUnit:GetAbsOrigin(), true)
    Timers:CreateTimer(.1, function()
      unit:RemoveSelf()
      return nil
    end) 

    HUMAN_COUNT = HUMAN_COUNT - 1
    if HUMAN_COUNT == 0 then
      GameRules:MakeTeamLose(DOTA_TEAM_GOODGUYS)
    end
  end

  if killedUnit:GetName() == "npc_dota_hero_night_stalker" then
    VAMP_COUNT = VAMP_COUNT - 1
    if VAMP_COUNT == 0 then
      GameRules:MakeTeamLose(DOTA_TEAM_BADGUYS)
    end
  end

  if killerEntity:GetUnitName() == "npc_dota_hero_night_stalker" then
    if killedUnit:GetUnitName() ~= "npc_dota_hero_omniknight" then

      -- Probability function for a coin drop
      local outcome = RandomInt(1, 200)
      local largeProb = 3 + (2 * HUMAN_COUNT / VAMP_COUNT)
      local smallProb = 18 + (2 * HUMAN_COUNT / VAMP_COUNT) + largeProb
      if outcome <= largeProb then        
        local coin = CreateItem("item_large_coin", nil, nil)
        local coinP = CreateItemOnPositionSync(killedUnit:GetAbsOrigin(), coin)
        coinP:SetOrigin(Vector(killedUnit:GetAbsOrigin().x, killedUnit:GetAbsOrigin().y, killedUnit:GetAbsOrigin().z + 50))
        coinP:SetModelScale(5) 
      elseif outcome <= smallProb then
        local coin = CreateItem("item_small_coin", nil, nil)
        local coinP = CreateItemOnPositionSync(killedUnit:GetAbsOrigin(), coin)
        coinP:SetOrigin(Vector(killedUnit:GetAbsOrigin().x, killedUnit:GetAbsOrigin().y, killedUnit:GetAbsOrigin().z + 50))
        coinP:SetModelScale(3)
      end
    end
  end
  
  -- If the killed unit increased the players food cap then it needs to decrease when it dies
  if UNIT_KV[playerID][unitName].ProvidesFood ~= nil then
    local lostfood = UNIT_KV[playerID][unitName].ProvidesFood
    TOTAL_FOOD[playerID] = TOTAL_FOOD[playerID] - lostfood
    FireGameEvent("vamp_food_cap_changed", { player_ID = playerID, food_cap = TOTAL_FOOD[playerID]})
  end

  if killedUnit:GetTeam() == DOTA_TEAM_GOODGUYS then
    TechTree:RemoveTech(unitName, playerID)
  end

end


function GameMode:ModifyStatBonuses(unit) 
  local spawnedUnitIndex = unit 
  print("modifying stat bonuses") 
    Timers:CreateTimer(DoUniqueString("updateHealth_" .. spawnedUnitIndex:GetPlayerID()), { 
    endTime = 0.25, 
    callback = function() 
      -- ================================== 
      -- Adjust health based on strength 
      -- ================================== 

      -- Get player strength 
      local strength = spawnedUnitIndex:GetStrength() 

      --Check if strBonus is stored on hero, if not set it to 0 
      if spawnedUnitIndex.strBonus == nil then 
        spawnedUnitIndex.strBonus = 0 
      end 

      -- If player strength is different this time around, start the adjustment 
      if strength ~= spawnedUnitIndex.strBonus then 
        -- Modifier values 
        local bitTable = {512,256,128,64,32,16,8,4,2,1} 

        -- Gets the list of modifiers on the hero and loops through removing and health modifier 
        local modCount = spawnedUnitIndex:GetModifierCount() 
        for i = 0, modCount do 
          for u = 1, #bitTable do 
            local val = bitTable[u] 
            if spawnedUnitIndex:GetModifierNameByIndex(i) == "modifier_health_mod_" .. val  then 
              spawnedUnitIndex:RemoveModifierByName("modifier_health_mod_" .. val) 
            end 
          end 
        end 
         
        -- Creates temporary item to steal the modifiers from 
        local healthUpdater = CreateItem("item_health_modifier", nil, nil)  
        for p=1, #bitTable do 
          local val = bitTable[p] 
          local count = math.floor(strength / val) 
          if count >= 1 then 
            healthUpdater:ApplyDataDrivenModifier(spawnedUnitIndex, spawnedUnitIndex, "modifier_health_mod_" .. val, {}) 
            strength = strength - val 
          end 
        end 
        -- Cleanup 
        UTIL_RemoveImmediate(healthUpdater) 
        healthUpdater = nil 
      end 
      -- Updates the stored strength bonus value for next timer cycle 
      spawnedUnitIndex.strBonus = spawnedUnitIndex:GetStrength() 
      return 0.25 
    end 
  }) 
end 


-- This function initializes the game mode and is called before anyone loads into the game
-- It can be used to pre-initialize any values/tables that will be needed later
function GameMode:InitGameMode()
  GameMode = self
  print('[vampirism] Starting to load vampirism gamemode...')

  -- Setup rules
  GameRules:SetHeroRespawnEnabled( ENABLE_HERO_RESPAWN )
  GameRules:SetUseUniversalShopMode( UNIVERSAL_SHOP_MODE )
  GameRules:SetSameHeroSelectionEnabled( ALLOW_SAME_HERO_SELECTION )
  GameRules:SetHeroSelectionTime( HERO_SELECTION_TIME )
  GameRules:SetPreGameTime( PRE_GAME_TIME)
  GameRules:SetPostGameTime( POST_GAME_TIME )
  GameRules:SetTreeRegrowTime( TREE_REGROW_TIME )
  GameRules:SetUseCustomHeroXPValues ( USE_CUSTOM_XP_VALUES )
  GameRules:SetGoldPerTick(GOLD_PER_TICK)
  GameRules:SetGoldTickTime(GOLD_TICK_TIME)
  GameRules:SetRuneSpawnTime(RUNE_SPAWN_TIME)
  GameRules:SetUseBaseGoldBountyOnHeroes(USE_STANDARD_HERO_GOLD_BOUNTY)
  GameRules:SetHeroMinimapIconScale( MINIMAP_ICON_SIZE )
  GameRules:SetCreepMinimapIconScale( MINIMAP_CREEP_ICON_SIZE )
  GameRules:SetRuneMinimapIconScale( MINIMAP_RUNE_ICON_SIZE )
  print('[vampirism] GameRules set')

  InitLogFile( "log/vampirism.txt","")

  -- Event Hooks
  -- All of these events can potentially be fired by the game, though only the uncommented ones have had
  -- Functions supplied for them.  If you are interested in the other events, you can uncomment the
  -- ListenToGameEvent line and add a function to handle the event
  ListenToGameEvent('dota_player_gained_level', Dynamic_Wrap(GameMode, 'OnPlayerLevelUp'), self)
  ListenToGameEvent('dota_ability_channel_finished', Dynamic_Wrap(GameMode, 'OnAbilityChannelFinished'), self)
  ListenToGameEvent('dota_player_learned_ability', Dynamic_Wrap(GameMode, 'OnPlayerLearnedAbility'), self)
  ListenToGameEvent('entity_killed', Dynamic_Wrap(GameMode, 'OnEntityKilled'), self)
  ListenToGameEvent('player_connect_full', Dynamic_Wrap(GameMode, 'OnConnectFull'), self)
  ListenToGameEvent('player_disconnect', Dynamic_Wrap(GameMode, 'OnDisconnect'), self)
  ListenToGameEvent('dota_item_purchased', Dynamic_Wrap(GameMode, 'OnItemPurchased'), self)
  ListenToGameEvent('dota_item_picked_up', Dynamic_Wrap(GameMode, 'OnItemPickedUp'), self)
  ListenToGameEvent('last_hit', Dynamic_Wrap(GameMode, 'OnLastHit'), self)
  ListenToGameEvent('dota_non_player_used_ability', Dynamic_Wrap(GameMode, 'OnNonPlayerUsedAbility'), self)
  ListenToGameEvent('player_changename', Dynamic_Wrap(GameMode, 'OnPlayerChangedName'), self)
  ListenToGameEvent('dota_rune_activated_server', Dynamic_Wrap(GameMode, 'OnRuneActivated'), self)
  ListenToGameEvent('dota_player_take_tower_damage', Dynamic_Wrap(GameMode, 'OnPlayerTakeTowerDamage'), self)
  ListenToGameEvent('tree_cut', Dynamic_Wrap(GameMode, 'OnTreeCut'), self)
  ListenToGameEvent('entity_hurt', Dynamic_Wrap(GameMode, 'OnEntityHurt'), self)
  ListenToGameEvent('player_connect', Dynamic_Wrap(GameMode, 'PlayerConnect'), self)
  ListenToGameEvent('dota_player_used_ability', Dynamic_Wrap(GameMode, 'OnAbilityUsed'), self)
  ListenToGameEvent('game_rules_state_change', Dynamic_Wrap(GameMode, 'OnGameRulesStateChange'), self)
  ListenToGameEvent('npc_spawned', Dynamic_Wrap(GameMode, 'OnNPCSpawned'), self)
  ListenToGameEvent('dota_player_pick_hero', Dynamic_Wrap(GameMode, 'OnPlayerPickHero'), self)
  ListenToGameEvent('dota_team_kill_credit', Dynamic_Wrap(GameMode, 'OnTeamKillCredit'), self)
  ListenToGameEvent("player_reconnected", Dynamic_Wrap(GameMode, 'OnPlayerReconnect'), self)
  --ListenToGameEvent('player_spawn', Dynamic_Wrap(GameMode, 'OnPlayerSpawn'), self)
  --ListenToGameEvent('dota_unit_event', Dynamic_Wrap(GameMode, 'OnDotaUnitEvent'), self)
  --ListenToGameEvent('nommed_tree', Dynamic_Wrap(GameMode, 'OnPlayerAteTree'), self)
  --ListenToGameEvent('player_completed_game', Dynamic_Wrap(GameMode, 'OnPlayerCompletedGame'), self)
  --ListenToGameEvent('dota_match_done', Dynamic_Wrap(GameMode, 'OnDotaMatchDone'), self)
  --ListenToGameEvent('dota_combatlog', Dynamic_Wrap(GameMode, 'OnCombatLogEvent'), self)
  --ListenToGameEvent('dota_player_killed', Dynamic_Wrap(GameMode, 'OnPlayerKilled'), self)
  --ListenToGameEvent('player_team', Dynamic_Wrap(GameMode, 'OnPlayerTeam'), self)



  -- Commands can be registered for debugging purposes or as functions that can be called by the custom Scaleform UI
  Convars:RegisterCommand("command_example", Dynamic_Wrap(GameMode, 'ExampleConsoleCommand'), "A console command example", 0 )

  -- Fill server with fake clients
  -- Fake clients don't use the default bot AI for buying items or moving down lanes and are sometimes necessary for debugging
  Convars:RegisterCommand('fake', function()
    -- Check if the server ran it
    if not Convars:GetCommandClient() then
      -- Create fake Players
      SendToServerConsole('dota_create_fake_clients')
        
      Timers:CreateTimer('assign_fakes', {
        useGameTime = false,
        endTime = Time(),
        callback = function(vampirism, args)
          local userID = 20
          for i=0, 9 do
            userID = userID + 1
            -- Check if this player is a fake one
            if PlayerResource:IsFakeClient(i) then
              -- Grab player instance
              local ply = PlayerResource:GetPlayer(i)
              -- Make sure we actually found a player instance
              if ply then
                CreateHeroForPlayer('npc_dota_hero_axe', ply)
                self:OnConnectFull({
                  userid = userID,
                  index = ply:entindex()-1
                })

                ply:GetAssignedHero():SetControllableByPlayer(0, true)
              end
            end
          end
        end})
    end
  end, 'Connects and assigns fake Players.', 0)

  --[[This block is only used for testing events handling in the event that Valve adds more in the future
  Convars:RegisterCommand('events_test', function()
      GameMode:StartEventTest()
    end, "events test", 0)]]

  -- Change random seed
  local timeTxt = string.gsub(string.gsub(GetSystemTime(), ':', ''), '0','')
  math.randomseed(tonumber(timeTxt))

  -- Initialized tables for tracking state
  self.vUserIds = {}
  self.vSteamIds = {}
  self.vBots = {}
  self.vBroadcasters = {}

  self.vPlayers = {}
  self.vRadiant = {}
  self.vDire = {}

  self.nRadiantKills = 0
  self.nDireKills = 0

  self.bSeenWaitForPlayers = false

  BuildingHelper:AutoSetHull(true)
  BuildingHelper:DisableFireEffects(true)

  BuildingHelper:Init(8192)
  BuildUI:Init()
  TechTree:Init()

  print('[vampirism] Done loading vampirism gamemode!\n\n')
end

mode = nil

-- This function is called as the first player loads and sets up the GameMode parameters
function GameMode:CaptureGameMode()
  if mode == nil then
    -- Set GameMode parameters
    mode = GameRules:GetGameModeEntity()        
    mode:SetRecommendedItemsDisabled( RECOMMENDED_BUILDS_DISABLED )
    mode:SetCameraDistanceOverride( CAMERA_DISTANCE_OVERRIDE )
    mode:SetCustomBuybackCostEnabled( CUSTOM_BUYBACK_COST_ENABLED )
    mode:SetCustomBuybackCooldownEnabled( CUSTOM_BUYBACK_COOLDOWN_ENABLED )
    mode:SetBuybackEnabled( BUYBACK_ENABLED )
    mode:SetTopBarTeamValuesOverride ( USE_CUSTOM_TOP_BAR_VALUES )
    mode:SetTopBarTeamValuesVisible( TOP_BAR_VISIBLE )
    mode:SetUseCustomHeroLevels ( USE_CUSTOM_HERO_LEVELS )
    mode:SetCustomHeroMaxLevel ( MAX_LEVEL )
    mode:SetCustomXPRequiredToReachNextLevel( XP_PER_LEVEL_TABLE )

    --mode:SetBotThinkingEnabled( USE_STANDARD_DOTA_BOT_THINKING )
    mode:SetTowerBackdoorProtectionEnabled( ENABLE_TOWER_BACKDOOR_PROTECTION )

    mode:SetFogOfWarDisabled(DISABLE_FOG_OF_WAR_ENTIRELY)
    mode:SetGoldSoundDisabled( DISABLE_GOLD_SOUNDS )
    mode:SetRemoveIllusionsOnDeath( REMOVE_ILLUSIONS_ON_DEATH )


    --GameRules:GetGameModeEntity():SetThink( "Think", self, "GlobalThink", 2 )

    --self:SetupMultiTeams()
    self:OnFirstPlayerLoaded()
  end 
end

-- Multiteam support is unfinished currently
--[[function GameMode:SetupMultiTeams()
  MultiTeam:start()
  MultiTeam:CreateTeam("team1")
  MultiTeam:CreateTeam("team2")
end]]

-- This function is called 1 to 2 times as the player connects initially but before they 
-- have completely connected
function GameMode:PlayerConnect(keys)
  print('[vampirism] PlayerConnect')
  PrintTable(keys)
  
  if keys.bot == 1 then
    -- This user is a Bot, so add it to the bots table
    self.vBots[keys.userid] = 1
  end

end

-- This function is called once when the player fully connects and becomes "Ready" during Loading
function GameMode:OnConnectFull(keys)
  print ('[vampirism] OnConnectFull')
  PrintTable(keys)
  GameMode:CaptureGameMode()
  
  local entIndex = keys.index+1
  print('entindex'..tostring(entIndex))

  -- The Player entity of the joining user
  local ply = EntIndexToHScript(entIndex)
  -- The Player ID of the joining player
  local playerID = ply:GetPlayerID()
  print('playerID '..playerID)
  -- Update the user ID table with this user
  self.vUserIds[keys.userid] = ply

  -- Update the Steam ID tables
  self.vSteamIds[PlayerResource:GetSteamAccountID(playerID)] = ply
  
  -- If the player is a broadcaster flag it in the Broadcasters table
  if PlayerResource:IsBroadcaster(playerID) then
    self.vBroadcasters[keys.userid] = 1
    return
  end

  --Hides unused HUD elements. Thanks to Noya for docuementing this!
  mode = GameRules:GetGameModeEntity()
  mode:SetHUDVisible(1, false)
  mode:SetHUDVisible(2, false)
  mode:SetHUDVisible(9, false)
  mode:SetHUDVisible(12, false)
  mode:SetCameraDistanceOverride(1500)
  
  heroRoller(playerID)
end

--an EPIC function. aka how to skip hero selection.
function heroRoller(playerID)
	print(PlayerResource:GetSelectedHeroName(playerID))
	if playerID < 8 then
		if PlayerResource:GetSelectedHeroName(playerID) ~= "npc_dota_hero_omniknight" then
			PlayerResource:GetPlayer(playerID):MakeRandomHeroSelection()
			Timers:CreateTimer(.3, function ()
				print('ROLLING')
				heroRoller(playerID)
				return nil
			end)
			return
		else
			PlayerResource:SetHasRepicked(playerID) 
			return
		end
	else
		if PlayerResource:GetSelectedHeroName(playerID) ~= "npc_dota_hero_night_stalker" then
			PlayerResource:GetPlayer(playerID):MakeRandomHeroSelection()
			heroRoller(playerID)
			Timers:CreateTimer(.3, function ()
				print('ROLLING')
				heroRoller(playerID)
				return nil
			end)
			return
		else
			PlayerResource:SetHasRepicked(playerID) 
			return
		end
	end
end

-- This is an example console command
function GameMode:ExampleConsoleCommand()
  print( '******* Example Console Command ***************' )
  local cmdPlayer = Convars:GetCommandClient()
  if cmdPlayer then
    local playerID = cmdPlayer:GetPlayerID()
    if playerID ~= nil and playerID ~= -1 then
      -- Do something here for the player who called this command
      PlayerResource:ReplaceHeroWith(playerID, "npc_dota_hero_viper", 1000, 1000)
    end
  end

  print( '*********************************************' )
end

--require('eventtest')
--GameMode:StartEventTest()