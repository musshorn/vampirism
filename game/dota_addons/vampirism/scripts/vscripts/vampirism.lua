print ('[VAMPIRISM] vampirism.lua' )

VERSION_NUMBER = "0.14d"                   -- Version number sent to panorama.

ENABLE_HERO_RESPAWN = false              -- Should the heroes automatically respawn on a timer or stay dead until manually respawned
UNIVERSAL_SHOP_MODE = false              -- Should the main shop contain Secret Shop items as well as regular items
ALLOW_SAME_HERO_SELECTION = true         -- Should we let people select the same hero as each other
 
HERO_SELECTION_TIME = 0.0                -- How long should we let people select their hero?
PRE_GAME_TIME = 56.0                     -- How long after people select their heroes should the horn blow and the game start?
POST_GAME_TIME = 60.0                    -- How long should we let people look at the scoreboard before closing the server automatically?
TREE_REGROW_TIME = 60.0                  -- How long should it take individual trees to respawn after being cut down/destroyed?

GOLD_PER_TICK = 0                        -- How much gold should players get per tick?
GOLD_TICK_TIME = 10000                   -- How long should we wait in seconds between gold ticks?

RECOMMENDED_BUILDS_DISABLED = true     	 -- Should we disable the recommened builds for heroes (Note: this is not working currently I believe)
CAMERA_DISTANCE_OVERRIDE = 1500.0        -- How far out should we allow the camera to go?  1134 is the default in Dota

MINIMAP_ICON_SIZE = 1                    -- What icon size should we use for our heroes?
MINIMAP_CREEP_ICON_SIZE = 1              -- What icon size should we use for creeps?
MINIMAP_RUNE_ICON_SIZE = 1               -- What icon size should we use for runes?

RUNE_SPAWN_TIME = 120                    -- How long in seconds should we wait between rune spawns?
CUSTOM_BUYBACK_COST_ENABLED = true       -- Should we use a custom buyback cost setting?
CUSTOM_BUYBACK_COOLDOWN_ENABLED = true   -- Should we use a custom buyback time?
BUYBACK_ENABLED = false                  -- Should we allow people to buyback when they die?

DISABLE_FOG_OF_WAR_ENTIRELY = false      -- Should we disable fog of war entirely for both teams?
--USE_STANDARD_DOTA_BOT_THINKING = false -- Should we have bots act like they would in Dota? (This requires 3 lanes, normal items, etc)
USE_STANDARD_HERO_GOLD_BOUNTY = true     -- Should we give gold for hero kills the same as in Dota, or allow those values to be changed?

USE_CUSTOM_TOP_BAR_VALUES = true         -- Should we do customized top bar values or use the default kill count per team?
TOP_BAR_VISIBLE = false                  -- Should we display the top bar score/count at all?
SHOW_KILLS_ON_TOPBAR = true              -- Should we display kills only on the top bar? (No denies, suicides, kills by neutrals)  Requires USE_CUSTOM_TOP_BAR_VALUES

ENABLE_TOWER_BACKDOOR_PROTECTION = false -- Should we enable backdoor protection for our towers?
REMOVE_ILLUSIONS_ON_DEATH = false        -- Should we remove all illusions if the main hero dies?
DISABLE_GOLD_SOUNDS = false              -- Should we disable the gold sound when players get gold?
 
END_GAME_ON_KILLS = false                -- Should the game end after a certain number of kills?
KILLS_TO_END_GAME_FOR_TEAM = 50          -- How many kills for a team should signify an end of game?
 
USE_CUSTOM_HERO_LEVELS = true            -- Should we allow heroes to have custom levels?
MAX_LEVEL = 200                          -- What level should we let heroes get to?
USE_CUSTOM_XP_VALUES = true              -- Should we use custom XP values to level up heroes, or the default Dota numbers?
 
WORKER_FACTOR = 4                        -- How many workers does a single worker count for. This can only be set once.
FACTOR_SET = false

LOW_PLAYER_MAP = true
ANNOUNCER_SOUND = {} -- Each player can toggle the announcer sound.

GOLD = {}
WOOD = {}
TOTAL_FOOD = {}
CURRENT_FOOD = {}

UNIT_KV = {} -- Each player has their own UNIT_KV file that research modifies properties of
ABILITY_KV = LoadKeyValues("scripts/npc/npc_abilities_custom.txt")
HERO_KV = LoadKeyValues("scripts/npc/npc_heroes_custom.txt")
ITEM_KV = LoadKeyValues("scripts/npc/npc_items_custom.txt")
SHOP_KV = LoadKeyValues('scripts/buildKVs/itemKV.txt')
 
INVENTORIES = {}
LUMBER_DROPS = {} -- table with handles to all the buildings that can recieve lumber
VAMP_COUNT = 0
HUMAN_COUNT = 0
HAS_SLAYER = {}
SLAYERS = {}
VAMPIRE_COINS = {} --table for tracking which vampire dropped which coins
HUMANS = {}
VAMPIRES = {} -- table of all created vampires
ABILITY_HOLDERS = {} --[[table containing units which hold extra abilities when another unit does not have enough slots to store them all.
                         Remember that in order to be used with buildUI, all abilities need to exist in abilities_custom]]
SHOPS = {} --table of all shops, by entindex.
AVERNALS = {} --table of all avernals, by playerID

Bases = {}     -- Access by owner pID, has int value baseID and a table of shared builders pIDs
Bases.Owners = {}
HUMAN_FEED = {}
for i = 0, 9 do
	HUMAN_FEED[i] = 0
end

VAMPIRE_FEED = {}
for i = -1, 11 do
	VAMPIRE_FEED[i] = 0
  AVERNALS[i] = {}
  ANNOUNCER_SOUND[i] = true
end

-- Default worker stacking factors.
WORKER_STACKS = {
  worker_t1 = 4,
  npc_dota_hero_ursa = 2,
  npc_dota_hero_sven = 1,
  worker_t4 = 1,
  worker_t5 = 1
}

-- Table used to check if something has been bought or built before.
UNIQUE_TABLE = {}

-- Time between attack notifications
ATTACK_NOTIFICATION_COOLDOWN = 5

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
  --PrecacheUnitByNameAsync("house_t1", function(...) end)   
  --PrecacheItemByNameAsync("item_example_item", function(...) end)
  --PrecacheItemByNameAsync("example_ability", function(...) end)

  PrecacheItemByNameAsync("item_vampiric_concoction", function( ... ) end)
  PrecacheItemByNameAsync("item_cloak_shadows", function( ... ) end)
  PrecacheItemByNameAsync("item_avernus_rain", function( ... ) end)
  PrecacheItemByNameAsync("item_claws_dreadlord", function( ... ) end)
  PrecacheItemByNameAsync("item_silent_whisper", function( ... ) end)
  PrecacheItemByNameAsync("item_refresh_potion", function( ... ) end)
  PrecacheItemByNameAsync("item_replenish_potion", function ( ... ) end)
  PrecacheItemByNameAsync("item_gauntlets_hellfire", function ( ... ) end)
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

  local sigil = CreateUnitByName("util_vampire_spawn_particles", Vector(96, -416, -200), false, nil, nil, DOTA_TEAM_BADGUYS)
  sigil:FindAbilityByName("vampire_particle_call"):OnUpgrade()

  local portalvision = CreateUnitByName("vampire_vision_dummy_spawn", Vector(96, -416, 220), false, nil, nil, DOTA_TEAM_BADGUYS)
  GameRules:SetHeroRespawnEnabled(false)
  for i = 0, 9 do
  	FireGameEvent("vamp_scoreboard_addplayer", {player_ID = i, player_name = PlayerResource:GetPlayerName(i)})
  end

  local vshop = CreateUnitByName("vampire_shop", Vector(-1088, 512, 128), false, nil, nil, DOTA_TEAM_BADGUYS)
  ShopUI:InitVampShop(vshop)
  vshop:FindAbilityByName('bh_dummy_unit'):OnSpellStart()

  CreateUnitByName("npc_vamp_fountain", Vector(779, 430, 128), false, nil, nil, DOTA_TEAM_BADGUYS)
  
  if not FACTOR_SET then
    Notifications:TopToAll({text = "By default, a worker factor of 4 is applied to reduce the network load on hosts. The host may change it by using -wf (number) to change it. Check info pane for details.", duration = 55, nil, style = {color="white", ["font-size"]="20px"}})
  end
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

  for i = 1, #vamps do
  	vamps[i]:RemoveModifierByName("modifier_init_hider")
  	vamps[i]:SetAbilityPoints(3)
    FindGoodSpaceForUnit(vamps[i], Vector(96, -416, 256), 300, nil)
    vamps[i]:SetForwardVector(RandomVector(1))
    vamps[i]:AddNewModifier(vampire, nil, "modifier_item_forcestaff_active", {push_length = 200})
  end

  ShopUI:ProcessQueues()
  GoldMineTimer()
  SphereTimer()
  UrnTimer()
  AutoGoldTimer()
  SlayerPool:ActivatePool()

  if tonumber(WORKER_FACTOR) > 1 then
    Notifications:TopToAll({text = "Remember that there is a worker factor of "..WORKER_FACTOR.." for this game. That means that tier 1 workers will roll "..WORKER_FACTOR.." times to drop a coin, take "..WORKER_FACTOR.." times as many detonates to destroy, and give "..WORKER_FACTOR.." as much gold and XP. Check info pane for details.", duration = 15, nil, style = {color="white", ["font-size"]="20px"}})
  end
end

-- Cleanup a player when they leave
function GameMode:OnDisconnect(keys)
  print('[vampirism] Player Disconnected ' .. tostring(keys.userid))

  local name = keys.name
  local networkid = keys.networkid
  local reason = keys.reason
  local userid = keys.userid

end
-- The overall game state has changed
function GameMode:OnGameRulesStateChange(keys)
  
  print("[vampirism] GameRules State Changed")

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

    -- Need to delay the human spawns, spawning 8 omnis at once is too much for the server.
    for i = 0, 11 do
      Timers:CreateTimer(.03, function ()
        local playerTeam = PlayerResource:GetTeam(i)
        if playerTeam == 2 then
          local human = CreateHeroForPlayer("npc_dota_hero_omniknight", PlayerResource:GetPlayer(i))
          HUMANS[i] = human
          human:FindAbilityByName("call_buildui"):SetLevel(1)
          human:FindAbilityByName("human_blink"):SetLevel(1)
          human:FindAbilityByName("human_manaburn"):SetLevel(1)
          human:FindAbilityByName("human_repair"):SetLevel(1)
          WOOD[i] = 4000000 --cheats, real is 50.
          GOLD[i] = 1000000 --this is how it should look on ship.
          TOTAL_FOOD[i] = 20
          CURRENT_FOOD[i] = 0
          UNIT_KV[i] = LoadKeyValues("scripts/npc/npc_units_custom.txt")
          UNIT_KV[i].Version = nil -- Value is made by LoadKeyValues, pretty annoying for iterating so we'll remove it
          HUMAN_COUNT = HUMAN_COUNT + 1
          human:SetAbilityPoints(0)
          human:SetHasInventory(false) --testing
          FireGameEvent("vamp_gold_changed", {player_ID = i, gold_total = GOLD[i]})
          FireGameEvent("vamp_wood_changed", {player_ID = i, wood_total = WOOD[i]})
          FireGameEvent("vamp_food_changed", {player_ID = i, food_total = CURRENT_FOOD[i]})
          FireGameEvent("vamp_food_cap_changed", {player_ID = i, food_cap = TOTAL_FOOD[i]})
          PlayerResource:SetCustomTeamAssignment(i, DOTA_TEAM_GOODGUYS)
          AddSwag(human)
        elseif playerTeam == 3 then
          local vampire = CreateHeroForPlayer("npc_dota_hero_night_stalker", PlayerResource:GetPlayer(i))
          vampire:SetHullRadius(48)
          local newSpace = FindGoodSpaceForUnit(vampire, vampire:GetAbsOrigin(), 200, nil)
          if newSpace ~= false then
            vampire:SetAbsOrigin(newSpace)
          end
          GOLD[i] = 0 --cheats off
          WOOD[i] = 0 --cheats off
          TOTAL_FOOD[i] = 10
          CURRENT_FOOD[i] = 0
          FireGameEvent("vamp_gold_changed", {player_ID = i, gold_total = GOLD[i]})
          FireGameEvent("vamp_wood_changed", {player_ID = i, wood_total = WOOD[i]})
          FireGameEvent("vamp_food_changed", {player_ID = i, food_total = CURRENT_FOOD[i]})
          FireGameEvent("vamp_food_cap_changed", {player_ID = i, food_cap = TOTAL_FOOD[i]})
          UNIT_KV[i] = LoadKeyValues("scripts/npc/npc_units_custom.txt")
          vampire:AddExperience(400, 0, false, true)
          AddSwag(vampire)
          if GetMapName() == 'vamp_5h_1v' then
            vampire:SetBaseMoveSpeed(500)
          end
  
          --Next frame timer
          Timers:CreateTimer(0.03, function ()
            vampire:FindAbilityByName("vampire_init_hider"):OnUpgrade()
            vampire:SetAbsOrigin(Vector(96, -416, -500))
            vampire:FindAbilityByName("vampire_particles"):OnUpgrade()
            vampire:SetAbilityPoints(0)
            vampire:FindAbilityByName("vampire_poison"):SetLevel(1)
            VAMP_COUNT = VAMP_COUNT + 1
            VAMPIRES[i] = vampire
            --VAMPIRES[-1] = vampire --nice game
            return nil
          end)
        end
      end)

      -- Create ABILITY_HOLDERS
      for unitName, h in pairs(UNIT_KV[-1]) do
        if UNIT_KV[-1][unitName]['AbilityHolder'] ~= nil then
          if ABILITY_HOLDERS[unitName] == nil then
            ABILITY_HOLDERS[unitName] = {}
            for i = 1, UNIT_KV[-1][unitName]["AbilityHolder"] do
              table.insert(ABILITY_HOLDERS[unitName], UNIT_KV[-1][unitName]["ExtraAbility"..i])
            end
          end
        end
      end
    end
    
  elseif newState == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
    GameMode:OnGameInProgress()
  elseif newState == DOTA_GAMERULES_STATE_PRE_GAME then
    Timers:CreateTimer(1.0, function ( )
      CustomGameEventManager:Send_ServerToAllClients("send_version", {version=VERSION_NUMBER} )
      return nil
    end)
  end
end

-- An NPC has spawned somewhere in game.  This includes heroes
function GameMode:OnNPCSpawned(keys)
  local npc = EntIndexToHScript(keys.entindex)
  local playerID = npc:GetMainControllingPlayer()

  if npc:GetName() == "npc_dota_hero_night_stalker" then
    if npc:GetItemInSlot(0) == nil then
      local item = CreateItem('item_vampiric_research_center', npc, npc)
      npc:AddItem(item)
    end
  end

  local unitName = string.lower(npc:GetUnitName())

  -- Adds omniknight to abilityholder.
  if npc:IsRealHero() and unitName ~= 'research_center_vampire' then
    npc.bFirstSpawned = true
    GameMode:OnHeroInGame(npc)

    local name = ''

    for k, v in pairs(HERO_KV) do
      if HERO_KV[k]["override_hero"] == unitName then
        name = k
      end
    end

    if HERO_KV[name].AbilityHolder ~= nil then
      if ABILITY_HOLDERS[unitName] == nil then
        ABILITY_HOLDERS[unitName] = {}
        for i = 1, HERO_KV[name]["AbilityHolder"] do
          table.insert(ABILITY_HOLDERS[unitName], HERO_KV[name]["ExtraAbility"..i])
        end
      end
    end 
  end

  if npc:GetUnitName() == "tower_pearls" then
    npc:FindAbilityByName("is_a_building"):OnUpgrade()
  end

  if string.match(npc:GetUnitName(), "vampire_vision_dummy") then
    VisionDummy(npc)
  end

  if npc:HasInventory() and npc:GetName() then
    if INVENTORIES[playerID] == nil then
      INVENTORIES[playerID] = {}
    end
    table.insert(INVENTORIES[playerID], npc)
  end
end

-- An entity somewhere has been hurt.  This event fires very often with many units so don't do too many expensive
-- operations here
function GameMode:OnEntityHurt(keys)
  if keys.entindex_attacker ~= nil then
    local entCause = EntIndexToHScript(keys.entindex_attacker)
    local entVictim = EntIndexToHScript(keys.entindex_killed)

    -- Buildings attacked by the worker are instantly killed
    if entCause:GetMainControllingPlayer() == entVictim:GetMainControllingPlayer() then
      local ability = entVictim:FindAbilityByName("is_a_building")
      if entCause:GetUnitName() == "npc_dota_hero_omniknight" and ability ~= nil then
        entVictim:ForceKill(true)
      end
    end

    if entCause:GetTeam() == DOTA_TEAM_BADGUYS and ATTACK_NOTIFICATION_COOLDOWN == 0 then
      NotifyAttack(entVictim, entCause)
      -- Emit sound on all humans
      for k,v in pairs(HUMANS) do
        if v:GetMainControllingPlayer() == entVictim:GetMainControllingPlayer() and ANNOUNCER_SOUND[v:GetMainControllingPlayer()] == true then
          EmitSoundOnClient("Vampirism.YourBaseAttacked", PlayerResource:GetPlayer(entVictim:GetMainControllingPlayer()))
        else
          if ANNOUNCER_SOUND[v:GetMainControllingPlayer()] == true then
            EmitSoundOnClient("Vampirism.AllyBaseAttacked", PlayerResource:GetPlayer(v:GetMainControllingPlayer()))
          end
        end
      end
    end
  end
end

-- An item was picked up off the ground
function GameMode:OnItemPickedUp(keys)
  local heroEntity = EntIndexToHScript(keys.HeroEntityIndex)
  local itemEntity = EntIndexToHScript(keys.ItemEntityIndex)
  local playerID = PlayerResource:GetPlayer(keys.PlayerID)
  local itemname = keys.itemname

  if itemname == "item_small_coin" then
  	VAMPIRE_FEED[VAMPIRE_COINS[keys.ItemEntityIndex]] = VAMPIRE_FEED[VAMPIRE_COINS[keys.ItemEntityIndex]] + 1
  	FireGameEvent("vamp_gold_feed", {player_ID = VAMPIRE_COINS[keys.ItemEntityIndex], feed_total = VAMPIRE_FEED[VAMPIRE_COINS[keys.ItemEntityIndex]]})
  end
  if itemname == "item_large_coin" then
  	VAMPIRE_FEED[VAMPIRE_COINS[keys.ItemEntityIndex]] = VAMPIRE_FEED[VAMPIRE_COINS[keys.ItemEntityIndex]] + 2
  	FireGameEvent("vamp_gold_feed", {player_ID = VAMPIRE_COINS[keys.ItemEntityIndex], feed_total = VAMPIRE_FEED[VAMPIRE_COINS[keys.ItemEntityIndex]]})
  end
end

-- A player has reconnected to the game.  This function can be used to repaint Player-based particles or change
-- state as necessary
function GameMode:OnPlayerReconnect(keys)
  print ( '[vampirism] OnPlayerReconnect' )
  local pID = keys.PlayerID
  Timers:CreateTimer(2.0, function()
    FireGameEvent("vamp_gold_changed", { player_ID = pID, gold_total = GOLD[pID]})
    FireGameEvent("vamp_wood_changed", { player_ID = pID, wood_total = WOOD[pID]})
    FireGameEvent("vamp_food_changed", { player_ID = pID, food_total = CURRENT_FOOD[pID]})
    FireGameEvent("vamp_food_cap_changed", { player_ID = pID, food_cap = TOTAL_FOOD[pID]})
    CustomGameEventManager:Send_ServerToAllClients("send_version", {version=VERSION_NUMBER} )
    local hero = PlayerResource:GetSelectedHeroEntity(pID)
    if hero ~= nil then
      AddSwag(hero)
    else
      local playerTeam = PlayerResource:GetTeam(pID)
      if playerTeam == 2 then
        local human = CreateHeroForPlayer("npc_dota_hero_omniknight", PlayerResource:GetPlayer(pID))
        HUMANS[pID] = human
        human:FindAbilityByName("call_buildui"):SetLevel(1)
        human:FindAbilityByName("human_blink"):SetLevel(1)
        human:FindAbilityByName("human_manaburn"):SetLevel(1)
        human:FindAbilityByName("human_repair"):SetLevel(1)
        WOOD[pID] = 50 --cheats, real is 50.
        GOLD[pID] = 0 --this is how it should look on ship.
        TOTAL_FOOD[pID] = 20
        CURRENT_FOOD[pID] = 0
        UNIT_KV[pID] = LoadKeyValues("scripts/npc/npc_units_custom.txt")
        UNIT_KV[pID].Version = nil -- Value is made by LoadKeyValues, pretty annoying for iterating so we'll remove it
        HUMAN_COUNT = HUMAN_COUNT + 1
        human:SetAbilityPoints(0)
        human:SetHasInventory(false) --testing
        FireGameEvent("vamp_gold_changed", {player_ID = pID, gold_total = GOLD[pID]})
        FireGameEvent("vamp_wood_changed", {player_ID = pID, wood_total = WOOD[pID]})
        FireGameEvent("vamp_food_changed", {player_ID = pID, food_total = CURRENT_FOOD[pID]})
        FireGameEvent("vamp_food_cap_changed", {player_ID = pID, food_cap = TOTAL_FOOD[pID]})
        PlayerResource:SetCustomTeamAssignment(pID, DOTA_TEAM_GOODGUYS)
        AddSwag(human)
      elseif playerTeam == 3 then
        local vampire = CreateHeroForPlayer("npc_dota_hero_night_stalker", PlayerResource:GetPlayer(pID))
        vampire:SetHullRadius(48)
        local newSpace = FindGoodSpaceForUnit(vampire, vampire:GetAbsOrigin(), 200, nil)
        if newSpace ~= false then
          vampire:SetAbsOrigin(newSpace)
        end
        GOLD[pID] = 0 --cheats off
        WOOD[pID] = 0 --cheats off
        TOTAL_FOOD[pID] = 10
        CURRENT_FOOD[pID] = 0
        FireGameEvent("vamp_gold_changed", {player_ID = pID, gold_total = GOLD[pID]})
        FireGameEvent("vamp_wood_changed", {player_ID = pID, wood_total = WOOD[pID]})
        FireGameEvent("vamp_food_changed", {player_ID = pID, food_total = CURRENT_FOOD[pID]})
        FireGameEvent("vamp_food_cap_changed", {player_ID = pID, food_cap = TOTAL_FOOD[pID]})
        UNIT_KV[pID] = LoadKeyValues("scripts/npc/npc_units_custom.txt")
        vampire:AddExperience(400, 0, false, true)
        AddSwag(vampire)
        if GetMapName() == 'vamp_5h_1v' then
          vampire:SetBaseMoveSpeed(500)
        end
        --Next frame timer
        Timers:CreateTimer(0.03, function ()
          if GameRules:State_Get() ~= DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
            vampire:FindAbilityByName("vampire_init_hider"):OnUpgrade()
            vampire:SetAbsOrigin(Vector(96, -416, -500))
            vampire:FindAbilityByName("vampire_particles"):OnUpgrade()
            vampire:SetAbilityPoints(0)
            vampire:FindAbilityByName("vampire_poison"):SetLevel(1)
            VAMP_COUNT = VAMP_COUNT + 1
            VAMPIRES[pID] = vampire
            --VAMPIRES[-1] = vampire --nice game
          end
          return nil
        end)
      end
    end
    return nil
  end)
end

-- An item was purchased by a player
function GameMode:OnItemPurchased( keys )
  -- The playerID of the hero who is buying something
  local plyID = keys.PlayerID
  if not plyID then return end
end

-- An ability was used by a player
function GameMode:OnAbilityUsed(keys)

  local player = PlayerResource:GetPlayer(keys.PlayerID) 
  local abilitysname = keys.abilityname
  local hero = player:GetAssignedHero()
end

-- A non-player entity (necro-book, chen creep, etc) used an ability
function GameMode:OnNonPlayerUsedAbility(keys)
  --print('[vampirism] OnNonPlayerUsedAbility')
  --PrintTable(keys)

  local abilityname =  keys.abilityname
end

-- A player changed their name
function GameMode:OnPlayerChangedName(keys)
  print('[vampirism] OnPlayerChangedName')

  local newName = keys.newname
  local oldName = keys.oldName
end

-- A player leveled up an ability
function GameMode:OnPlayerLearnedAbility( keys)

  local player = EntIndexToHScript(keys.player)
  local abilityname = keys.abilityname
end

-- A channelled ability finished by either completing or being interrupted
function GameMode:OnAbilityChannelFinished(keys)
  --print ('[vampirism] OnAbilityChannelFinished')
  --PrintTable(keys)

  local abilityname = keys.abilityname
  local interrupted = keys.interrupted == 1
end

-- A player leveled up
function GameMode:OnPlayerLevelUp(keys)
  local player = EntIndexToHScript(keys.player)
  local level = keys.level
  local playerID = player:GetPlayerID()

  for k, v in pairs(AVERNALS[playerID]) do
    Timers:CreateTimer(0.03, function ()
      v:SetMaxHealth(v:GetMaxHealth() + 50)
      if v:HasAbility('avernal_dmg_growth') then
        v:SetBaseDamageMin(v:GetBaseDamageMin() + 10)
        v:SetBaseDamageMax(v:GetBaseDamageMax() + 10)
      end
    end)
  end
end

-- A player last hit a creep, a tower, or a hero
function GameMode:OnLastHit(keys)

  local isFirstBlood = keys.FirstBlood == 1
  local isHeroKill = keys.HeroKill == 1
  local isTowerKill = keys.TowerKill == 1
  local player = PlayerResource:GetPlayer(keys.PlayerID)
end

-- A tree was cut down by tango, quelling blade, etc
function GameMode:OnTreeCut(keys)
  local treeX = keys.tree_x
  local treeY = keys.tree_y
end

-- A player picked a hero
function GameMode:OnPlayerPickHero(keys)
  print ('[vampirism] OnPlayerPickHero')

  local heroClass = keys.hero
  local heroEntity = EntIndexToHScript(keys.heroindex)
  local player = EntIndexToHScript(keys.player)
  if heroEntity:GetUnitName() == "npc_dota_hero_night_stalker" then 
    GameMode:ModifyStatBonuses(heroEntity) 
  end
end

-- A player killed another player in a multi-team context
function GameMode:OnTeamKillCredit(keys)

  local killerPlayer = PlayerResource:GetPlayer(keys.killer_userid)
  local victimPlayer = PlayerResource:GetPlayer(keys.victim_userid)
  local numKills = keys.herokills
  local killerTeamNumber = keys.teamnumber
end

-- An entity died
function GameMode:OnEntityKilled( keys )
  -- The Unit that was Killed
  local killedUnit = EntIndexToHScript( keys.entindex_killed )
  -- The Killing entity
  local killerEntity = nil
  local unitName = killedUnit:GetUnitName()
  local playerID = killedUnit:GetMainControllingPlayer()
  local killedOwner = killedUnit:GetPlayerOwner()
  local modelName = killedUnit:GetModelName() 

  if keys.entindex_attacker ~= nil then
    killerEntity = EntIndexToHScript( keys.entindex_attacker )
  else
    return
  end

  if killedUnit:IsRealHero() then 
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

  if killedUnit:GetUnitName() == "npc_dota_hero_omniknight" and killedUnit:HasOwnerAbandoned() == false and killerEntity:GetTeam() == DOTA_TEAM_BADGUYS then
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

    local playerEnts = Entities:FindAllByClassname("npc_dota_creature")


    -- Goes to next frame to stop bugs.
    Timers:CreateTimer(.03, function ()
      for k,v in pairs(playerEnts) do
        if v:GetMainControllingPlayer() == killedUnit:GetMainControllingPlayer() then
          -- Silence, disarm buildings still alive.
          v:AddNewModifier(killedUnit, nil, "modifier_silence", {duration = 60})
          v:AddNewModifier(killedUnit, nil, "modifier_disarmed", {duration = 60})
  
          -- If its nbot a building kill it now, otherwise kill it in 60 seconds.
          if not v:HasAbility('is_a_building') then
            v:Destroy()
          else
            Timers:CreateTimer(60, function ()
              local tempFood = TOTAL_FOOD[v:GetMainControllingPlayer()]
              v:RemoveBuilding(true)
              TOTAL_FOOD[v:GetMainControllingPlayer()] = tempFood
              return nil
            end)  
          end 
        end   
      end
      return nil
    end)

    -- Create a tombstone, the player can then pick to become a human spectator or a vampire
    local tomb = CreateUnitByName("human_tomb", killedUnit:GetAbsOrigin(), true, nil, nil, killedOwner:GetTeam())
    tomb:SetControllableByPlayer(killedUnit:GetMainControllingPlayer(), true)
    TOTAL_FOOD[killedUnit:GetMainControllingPlayer()] = 0
    CURRENT_FOOD[killedUnit:GetMainControllingPlayer()] = 0
  end

  if killedUnit:GetName() == "npc_dota_hero_night_stalker" then
    VAMP_COUNT = VAMP_COUNT - 1
    if VAMP_COUNT == 0 then
      GameRules:MakeTeamLose(DOTA_TEAM_BADGUYS)
    end
  end

  local stackAbility = killedUnit:FindAbilityByName('worker_stack')

  if killerEntity:GetTeam() == DOTA_TEAM_BADGUYS then
    --print('killer was bad, check 4 coins', killerEntity:GetUnitName())
    if killedUnit:GetUnitName() ~= "npc_dota_hero_omniknight" and killedUnit:GetUnitName() ~= "npc_dota_hero_invoker" and killedUnit:FindAbilityByName('no_coin_drops') == nil and killedUnit.gravekilled ~= true and killerEntity:FindAbilityByName('is_a_building') == nil then
      --print('roll 4 coins')
      local outcome = RandomInt(1, 200)
      local largeProb = 3 + (2 * HUMAN_COUNT / VAMP_COUNT)
      local smallProb = 18 + (2 * HUMAN_COUNT / VAMP_COUNT) + largeProb

      --outcome = 1 --dont forget to change this
      if outcome <= largeProb then
        --print('coin in first loop')
        local coin = CreateItem("item_large_coin", VAMPIRES[killerEntity:GetMainControllingPlayer()], VAMPIRES[killerEntity:GetMainControllingPlayer()])
        local coinP = CreateItemOnPositionSync(killedUnit:GetAbsOrigin(), coin)
        --print(coin:entindex(), ' = ', killerEntity:GetMainControllingPlayer())    
        VAMPIRE_COINS[coin:entindex()] = killerEntity:GetMainControllingPlayer()
        --print(VAMPIRE_COINS[coin:entindex()])
        coinP:SetOrigin(Vector(killedUnit:GetAbsOrigin().x, killedUnit:GetAbsOrigin().y, killedUnit:GetAbsOrigin().z + 50))
        coinP:SetModelScale(5)
      elseif outcome <= smallProb then
        --print('coin in first loop')
        local coin = CreateItem("item_small_coin", VAMPIRES[killerEntity:GetMainControllingPlayer()], VAMPIRES[killerEntity:GetMainControllingPlayer()])
        local coinP = CreateItemOnPositionSync(killedUnit:GetAbsOrigin(), coin)
        VAMPIRE_COINS[coin:entindex()] = killerEntity:GetMainControllingPlayer()
        coin.player = killerEntity:GetMainControllingPlayer()
        coinP:SetOrigin(Vector(killedUnit:GetAbsOrigin().x, killedUnit:GetAbsOrigin().y, killedUnit:GetAbsOrigin().z + 50))
        coinP:SetModelScale(3)
      end
    
      --roll for extra coins, grant extra exp, bounty. if the unit was stacked.
      local expReward = 25
      if killedUnit:GetModifierStackCount("modifier_worker_stack", stackAbility) ~= nil then
        local stacks = killedUnit:GetModifierStackCount("modifier_worker_stack", stackAbility) - 1
        while stacks > 0 do
          --print('coin in second loop')
          outcome = RandomInt(1, 200)
          largeProb = 3 + (2 * HUMAN_COUNT / VAMP_COUNT)
          smallProb = 18 + (2 * HUMAN_COUNT / VAMP_COUNT) + largeProb
          --outcome = 1 --dont forget to change this
          if outcome <= largeProb then
            local newcoin = CreateItem("item_large_coin", VAMPIRES[killerEntity:GetMainControllingPlayer()], VAMPIRES[killerEntity:GetMainControllingPlayer()])
            local newcoinP = CreateItemOnPositionSync(killedUnit:GetAbsOrigin(), newcoin)
            --print(coin:entindex(), ' = ', killerEntity:GetMainControllingPlayer())        
            VAMPIRE_COINS[newcoin:entindex()] = killerEntity:GetMainControllingPlayer()
            --print(VAMPIRE_COINS[coin:entindex()])
            newcoinP:SetOrigin(Vector(killedUnit:GetAbsOrigin().x, killedUnit:GetAbsOrigin().y, killedUnit:GetAbsOrigin().z + 50))
            newcoinP:SetModelScale(5) 
          elseif outcome <= smallProb then
            local newcoin = CreateItem("item_small_coin", VAMPIRES[killerEntity:GetMainControllingPlayer()], VAMPIRES[killerEntity:GetMainControllingPlayer()])
            local newcoinP = CreateItemOnPositionSync(killedUnit:GetAbsOrigin(), newcoin)
            VAMPIRE_COINS[newcoin:entindex()] = killerEntity:GetMainControllingPlayer()
            newcoin.player = killerEntity:GetMainControllingPlayer()
            newcoinP:SetOrigin(Vector(killedUnit:GetAbsOrigin().x, killedUnit:GetAbsOrigin().y, killedUnit:GetAbsOrigin().z + 50))
            newcoinP:SetModelScale(4)
          end
          ChangeGold(killerEntity:GetMainControllingPlayer(), killedUnit:GetGoldBounty())
          expReward = expReward + 25
          stacks = stacks - 1
        end
        if killedUnit:FindAbilityByName('no_exp_gain') == nil then
          local nearVamps = FindUnitsInRadius(killedUnit:GetTeam(), killedUnit:GetAbsOrigin(), nil, 1000, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, 0, FIND_ANY_ORDER, false)
          if nearVamps ~= nil then
          	local xpSplit = expReward / (#nearVamps)
          	for k,v in pairs(nearVamps) do
              v:AddExperience(xpSplit, 2, false, true)
          	end
          end
        end
      end
    end

    if killedUnit:GetGoldBounty() > 0 and killedUnit:IsHero() ~= true and killedUnit:IsConsideredHero() ~= true then
    	HUMAN_FEED[playerID] = HUMAN_FEED[playerID] + killedUnit:GetGoldBounty()
    	FireGameEvent("vamp_gold_feed", {player_ID = playerID, feed_total = HUMAN_FEED[playerID]})
    end
  end
  
  -- Update all the slayer taverns the player owns to the new respawn time
  if killedUnit:GetUnitName() == "npc_dota_hero_invoker" then
    local name = PlayerResource:GetPlayerName(killedUnit:GetMainControllingPlayer())
    GameRules:SendCustomMessage(ColorIt(name, IDToColour(ownerpID)) .. "'s slayer has fallen!", 0, 0)
    ChangeGold(killerEntity:GetMainControllingPlayer(), 15)
    CURRENT_FOOD[killedUnit:GetMainControllingPlayer()] = CURRENT_FOOD[killedUnit:GetMainControllingPlayer()] - 10
    SLAYERS[playerID].state = "dead"
    SLAYERS[playerID].level = killedUnit:GetLevel()
    local house = nil
    repeat
      house = Entities:FindByModel(house, UNIT_KV[playerID]["slayer_tavern"].Model)
      if house ~= nil then
        if house:GetMainControllingPlayer() == playerID then
          house:FindAbilityByName("slayer_respawn"):SetLevel(killedUnit:GetLevel())
        end
      end
    until house == nil
    FireGameEvent("vamp_slayer_state_update", {player_ID = playerID, slayer_state = "Dead"})
    FireGameEvent("vamp_food_changed", {player_ID = playerID, food_total = CURRENT_FOOD[killedUnit:GetMainControllingPlayer()]})
  end

  -- If the killed unit increased the players food cap then it needs to decrease when it dies
  if UNIT_KV[playerID] ~= nil then
    if UNIT_KV[playerID][unitName] ~= nil then
      local lostfood = 0
      
      if UNIT_KV[playerID][unitName].ProvidesFood ~= nil then
        lostfood = UNIT_KV[playerID][unitName].ProvidesFood
        TOTAL_FOOD[playerID] = TOTAL_FOOD[playerID] - lostfood
        if TOTAL_FOOD[playerID] < 10 and VAMPIRES[playerID] ~= nil then
          TOTAL_FOOD[playerID] = 10
        end
        if TOTAL_FOOD[playerID] < 250 then
          FireGameEvent("vamp_food_cap_changed", { player_ID = playerID, food_cap = TOTAL_FOOD[playerID]})
        else
          FireGameEvent("vamp_food_cap_changed", { player_ID = playerID, food_cap = 250})
        end 
      end

      if UNIT_KV[playerID][unitName].ConsumesFood ~= nil then
        lostfood = UNIT_KV[playerID][unitName].ConsumesFood
        CURRENT_FOOD[playerID] = CURRENT_FOOD[playerID] - lostfood
        FireGameEvent("vamp_food_changed", { player_ID = playerID, food_total = CURRENT_FOOD[playerID]})
        -- Decrease food based on stack count.
        local stackAbility = killedUnit:FindAbilityByName('worker_stack')
        if stackAbility ~= nil then
          local stacks = killedUnit:GetModifierStackCount("modifier_worker_stack", stackAbility) - 1
          if stacks ~= nil then
            CURRENT_FOOD[playerID] = CURRENT_FOOD[playerID] - (lostfood * stacks)
          	FireGameEvent("vamp_food_changed", {player_ID = playerID, food_total =  CURRENT_FOOD[playerID]})
          end
        end
      end

      if UNIT_KV[playerID][unitName].SpawnsUnits == "true" then
        if killedUnit.updateHealthTimer ~= nil then
          Timers:RemoveTimer(killedUnit.updateHealthTimer)
        end
      end

      if UNIT_KV[playerID][unitName].RecievesLumber == "true" then
        for k, v in pairs(LUMBER_DROPS) do
          if v == killedUnit then
            LUMBER_DROPS[k] = nil
          end
        end
      end
    end
  end

  -- Vampire killed a unit
  if killedUnit:GetTeam() == DOTA_TEAM_GOODGUYS and killerEntity:GetTeam() == DOTA_TEAM_BADGUYS then
    local vampPID = killerEntity:GetMainControllingPlayer()
    ChangeGold(vampPID, killedUnit:GetGoldBounty())
  end

  -- If it's a building we need to remove the gridnav blocks
  if killedUnit:FindAbilityByName("is_a_building") ~= nil then
    killedUnit:RemoveBuilding(false)
    if killedUnit.ShopEnt ~= nil then -- Also cleanup shops
      killedUnit.ShopEnt:SetModel("")
      killedUnit.ShopEnt = nil
    end
  end


  if killedUnit:GetTeam() == DOTA_TEAM_GOODGUYS and killedUnit:IsHero() == false then
    -- The killed unit was upgraded from another, remove those from the tree too.
    if UNIT_KV[playerID][unitName]['ParentUnit'] ~= nil then
      TechTree:RemoveTech(unitName, playerID)
      local clearedParents = false
      local parent = unitName
      while clearedParents == false do
        if UNIT_KV[playerID][parent]['ParentUnit'] ~= nil then
          parent = UNIT_KV[playerID][parent]['ParentUnit']
          TechTree:RemoveTech(parent, playerID)
        else
          clearedParents = true
        end
      end
    else
      TechTree:RemoveTech(unitName, playerID)
    end
  end
end


function GameMode:ModifyStatBonuses(unit) 
  local spawnedUnitIndex = unit 
    Timers:CreateTimer(DoUniqueString("updateHealth_" .. spawnedUnitIndex:GetPlayerID()), { 
    endTime = 0.25, 
    callback = function() 
      -- ================================== 
      -- Adjust health, regen based on strength 
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
      -- ================================== 
      -- Adjust armor, attack speed based on agility 
      -- ================================== 

      -- Get player agility 
      local agility = spawnedUnitIndex:GetAgility() 

      --Check if agiBonus is stored on hero, if not set it to 0 
      if spawnedUnitIndex.agiBonus == nil then 
        spawnedUnitIndex.agiBonus = 0 
      end 

      -- If player agility is different this time around, start the adjustment 
      if agility ~= spawnedUnitIndex.agiBonus then 
        -- Modifier values 
        local bitTable = {512,256,128,64,32,16,8,4,2,1} 

        -- Gets the list of modifiers on the hero and loops through removing and health modifier 
        local modCount = spawnedUnitIndex:GetModifierCount() 
        for i = 0, modCount do 
          for u = 1, #bitTable do 
            local val = bitTable[u] 
            if spawnedUnitIndex:GetModifierNameByIndex(i) == "modifier_agility_mod_" .. val  then 
              spawnedUnitIndex:RemoveModifierByName("modifier_agility_mod_" .. val) 
            end 
          end 
        end 
         
        -- Creates temporary item to steal the modifiers from 
        local agiUpdater = CreateItem("item_agility_modifier", nil, nil)  
        for p=1, #bitTable do 
          local val = bitTable[p] 
          local count = math.floor(agility / val) 
          if count >= 1 then 
            agiUpdater:ApplyDataDrivenModifier(spawnedUnitIndex, spawnedUnitIndex, "modifier_agility_mod_" .. val, {}) 
            agility = agility - val 
          end 
        end 
        -- Cleanup 
        UTIL_RemoveImmediate(agiUpdater) 
        agiUpdater = nil 
      end 
      -- Updates the stored agility bonus value for next timer cycle 
      spawnedUnitIndex.agiBonus = spawnedUnitIndex:GetAgility()

      -- ================================== 
      -- Adjust mana regen, mana based on intellect 
      -- ================================== 

      -- Get player intellect 
      local intellect = spawnedUnitIndex:GetIntellect() 

      --Check if intBonus is stored on hero, if not set it to 0 
      if spawnedUnitIndex.intBonus == nil then 
        spawnedUnitIndex.intBonus = 0 
      end 

      -- If player intellect is different this time around, start the adjustment 
      if intellect ~= spawnedUnitIndex.intBonus then 
        -- Modifier values 
        local bitTable = {512,256,128,64,32,16,8,4,2,1} 

        -- Gets the list of modifiers on the hero and loops through removing and health modifier 
        local modCount = spawnedUnitIndex:GetModifierCount() 
        for i = 0, modCount do 
          for u = 1, #bitTable do 
            local val = bitTable[u] 
            if spawnedUnitIndex:GetModifierNameByIndex(i) == "modifier_intellect_mod_" .. val  then 
              spawnedUnitIndex:RemoveModifierByName("modifier_intellect_mod_" .. val) 
            end 
          end 
        end 
         
        -- Creates temporary item to steal the modifiers from 
        local intUpdater = CreateItem("item_intellect_modifier", nil, nil)  
        for p=1, #bitTable do 
          local val = bitTable[p] 
          local count = math.floor(intellect / val) 
          if count >= 1 then 
            intUpdater:ApplyDataDrivenModifier(spawnedUnitIndex, spawnedUnitIndex, "modifier_intellect_mod_" .. val, {}) 
            intellect = intellect - val 
          end 
        end 
        -- Cleanup 
        UTIL_RemoveImmediate(intUpdater) 
        intUpdater = nil 
      end 
      -- Updates the stored intellect bonus value for next timer cycle 
      spawnedUnitIndex.intBonus = spawnedUnitIndex:GetIntellect()
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

  if GetMapName() == 'vamp' then
    GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_GOODGUYS, 10 )
    GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_BADGUYS, 2 )
    LOW_PLAYER_MAP = false
  elseif GetMapName() == 'vamp_5h_1v' then
    GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_GOODGUYS, 5 )
    GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_BADGUYS, 1 )
    LOW_PLAYER_MAP = true
  end

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
  ListenToGameEvent('player_say', Dynamic_Wrap(GameMode, 'OnPlayerSay'), self)
  --ListenToGameEvent('player_spawn', Dynamic_Wrap(GameMode, 'OnPlayerSpawn'), self)
  --ListenToGameEvent('dota_unit_event', Dynamic_Wrap(GameMode, 'OnDotaUnitEvent'), self)
  --ListenToGameEvent('nommed_tree', Dynamic_Wrap(GameMode, 'OnPlayerAteTree'), self)
  --ListenToGameEvent('player_completed_game', Dynamic_Wrap(GameMode, 'OnPlayerCompletedGame'), self)
  --ListenToGameEvent('dota_match_done', Dynamic_Wrap(GameMode, 'OnDotaMatchDone'), self)
  --ListenToGameEvent('dota_combatlog', Dynamic_Wrap(GameMode, 'OnCombatLogEvent'), self)
  --ListenToGameEvent('dota_player_killed', Dynamic_Wrap(GameMode, 'OnPlayerKilled'), self)
  --ListenToGameEvent('player_team', Dynamic_Wrap(GameMode, 'OnPlayerTeam'), self)

  CustomGameEventManager:RegisterListener( "building_helper_build_command", Dynamic_Wrap(BuildingHelper, "RegisterLeftClick"))
  CustomGameEventManager:RegisterListener( "building_helper_cancel_command", Dynamic_Wrap(BuildingHelper, "RegisterRightClick"))


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

  Convars:RegisterCommand('player_say', function(...)
    local arg = {...}
    table.remove(arg,1)
    local cmdPlayer = Convars:GetCommandClient()
    keys = {}
    keys.ply = cmdPlayer
    keys.text = table.concat(arg, " ")
    self:OnPlayerSay(keys)
  end, 'player say', 0)

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
  
  BuildUI:Init()
  TechTree:Init()
  ShopUI:Init()
  AttackTimer()

  UNIT_KV[-1] = LoadKeyValues("scripts/npc/npc_units_custom.txt")
  UNIT_KV[-1].Version = nil

  ATTACK_NOTIFICATION_COOLDOWN = 0

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

    --reborn things

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

  -- The Player entity of the joining user
  local ply = EntIndexToHScript(entIndex)
  -- The Player ID of the joining player
  local playerID = ply:GetPlayerID()
  -- Update the user ID table with this user
  self.vUserIds[keys.userid] = ply

  -- Update the Steam ID tables
  self.vSteamIds[PlayerResource:GetSteamAccountID(playerID)] = ply
  
  -- If the player is a broadcaster flag it in the Broadcasters table
  if PlayerResource:IsBroadcaster(playerID) then
    self.vBroadcasters[keys.userid] = 1
    return
  end

  --Hides unused HUD elements. Thanks to Noya for documenting this!
  mode = GameRules:GetGameModeEntity()
  mode:SetHUDVisible(1, false)
  mode:SetHUDVisible(2, false)
  mode:SetHUDVisible(9, false)
  mode:SetHUDVisible(11, false)
  mode:SetHUDVisible(12, false)
  mode:SetCameraDistanceOverride(1500)

  --Lets player see bottom row of trees.
  SendToConsole("dota_camera_pitch_max 63")
end

-- start here
function NotifyAttack( victim, attacker )
  local victimPID = victim:GetMainControllingPlayer()
  local attackerPID = attacker:GetMainControllingPlayer()
  local victimPos = victim:GetAbsOrigin()

  print('making minimap event.')
  MinimapEvent(victim:GetTeam(), victim, victimPos.x, victimPos.y, DOTA_MINIMAP_EVENT_ENEMY_TELEPORTING, 2)
  ATTACK_NOTIFICATION_COOLDOWN = 5
end

function GoldMineTimer()
  --adds gold from gold mines
  local goldTime = 0
  Timers:CreateTimer(function()
    --print('tick')
    --check t4 gold
    if goldTime % 4 == 0 then
      local t4gold = Entities:FindAllByModel('models/gold_mine_4.vmdl')
      for k, mine in pairs(t4gold) do
        if mine ~= nil then
          local playerID = mine:GetMainControllingPlayer()
          ChangeGold(playerID, 2)
        end
      end      
    end
    --check t3 gold
    if goldTime % 6 == 0 then
      local t3gold = Entities:FindAllByModel('models/gold_mine_3.vmdl')
      for k, mine in pairs(t3gold) do
        if mine ~= nil then
          local playerID = mine:GetMainControllingPlayer() 
          ChangeGold(playerID, 2)
        end
      end
    end
    --check t2 gold mines
    if goldTime % 15 == 0 then
      local t2gold = Entities:FindAllByModel('models/gold_mine_2.vmdl')
      for k, mine in pairs(t2gold) do
        if mine ~= nil then
          local playerID = mine:GetMainControllingPlayer()
          ChangeGold(playerID, 2)
        end
      end
    end
    --check t1 gold mines
    if goldTime == 0 then
      local t1gold = Entities:FindAllByModel('models/mine_cart_reference.vmdl')
      for k, mine in pairs(t1gold) do
        if mine ~= nil then
          local playerID = mine:GetMainControllingPlayer()
          ChangeGold(playerID, 2)
        end
      end
    end
    goldTime = goldTime + 1
    if goldTime == 60 then
      goldTime = 0
    end
    return 1
  end)
end

--Runs every 15 seconds, checks whether vamps have sphere of doom
function SphereTimer()
  Timers:CreateTimer(function()
    local haveSphere = false
    for k, v in pairs(VAMPIRES) do
      if v:HasItemInInventory('item_sphere_doom') then
        haveSphere = true
      end
    end

    for k, v in pairs(VAMPIRES) do
      if haveSphere then
        v:SetBaseAgility(v:GetBaseAgility() +5)
        v:SetBaseStrength(v:GetBaseStrength() +5)
        v:SetBaseIntellect(v:GetBaseIntellect() +5)
      end
    end
    return 15
  end)
end

-- Runs each minute, adds 35 gold if the vampire has an urn of dracula.
function UrnTimer()
  Timers:CreateTimer(function ()
    for k, v in pairs(VAMPIRES) do
      if v:HasItemInInventory('item_dracula_urn') then
        ChangeGold(k, 35)
      end
    end
    return 60
  end)
end

-- Automatically gives gold at certain intervals.
function AutoGoldTimer()
  local time = 0
  Timers:CreateTimer(function ()
    if time == 90 then
      for k, v in pairs(VAMPIRES) do
        ChangeGold(v:GetMainControllingPlayer(), 25)
      end
    end
    if time == 720 then
      for k, v in pairs(VAMPIRES) do
        ChangeGold(v:GetMainControllingPlayer(), 100)
      end
      for k, v in pairs(HUMANS) do
        ChangeGold(v:GetMainControllingPlayer(), 2)
      end
    end
    if time == 1440 then
      for k, v in pairs(VAMPIRES) do
        ChangeGold(v:GetMainControllingPlayer(), 200)
      end
    end
    if time == 2160 then
      for k, v in pairs(VAMPIRES) do
        ChangeGold(v:GetMainControllingPlayer(), 300)
      end
    end
    if time == 2880 then
      for k, v in pairs(VAMPIRES) do
        ChangeGold(v:GetMainControllingPlayer(), 400)
      end
    end
    time = time + 1
    return 1
  end)
end

function AttackTimer()
  Timers:CreateTimer(function ()
    if ATTACK_NOTIFICATION_COOLDOWN > 0 then
      ATTACK_NOTIFICATION_COOLDOWN = ATTACK_NOTIFICATION_COOLDOWN - 1
    end
    return 1
  end)
end

function GameMode:OnPlayerSay(keys)
  local player = keys.ply
  local msg = keys.text

  if string.find(msg, "-sell") ~= nil then
    Trade:HandleChat(keys)
  end

  if string.find(msg, "-list") ~= nil then
    Trade:HandleChat(keys)
  end

  if string.find(msg, "-buy") ~= nil then
    Trade:HandleChat(keys)
  end

  if string.find(msg, "-wood") ~= nil then
    Trade:HandleChat(keys)
  end

  if string.find(msg, "-gold") ~= nil then
    Trade:HandleChat(keys)
  end

  if string.find(msg, "-mycolor") ~= nil then
    Trade:HandleChat(keys)
  end

  if string.find(msg, "-allow") ~= nil then
    Bases:HandleChat(keys)
  end

  if string.find(msg, "-disallow") ~= nil then
    Bases:HandleChat(keys)
  end

  if string.find(msg, "-wf") ~= nil and player == GetListenServerHost() and GameRules:State_Get() ~= DOTA_GAMERULES_STATE_GAME_IN_PROGRESS and FACTOR_SET ~= true then
    local chat = ParseChat(keys)

    WORKER_FACTOR = string.gsub(chat[2], '%D', '')

    for i = 1, 5 do
      local tier = i - 1
      local k = 'worker_t'..i
      local workerFactor = WORKER_FACTOR / math.pow(2, tier)

      if workerFactor < 1 then
        workerFactor = 1
      end     

      workerFactor = math.floor(workerFactor)

      WORKER_STACKS[k] = workerFactor
    end
    FACTOR_SET = true
    Notifications:ClearTopFromAll()
    Notifications:TopToAll({text = "Host has chosen a worker factor of "..WORKER_FACTOR.." for the duration of this game.", duration = 5, nil, style = {color="white", ["font-size"]="20px"}})
  end

  if string.find(msg, "-ok") ~= nil and player == GetListenServerHost() and GameRules:State_Get() ~= DOTA_GAMERULES_STATE_GAME_IN_PROGRESS and FACTOR_SET ~= true then
    FACTOR_SET = true
  end

  if string.find(msg, "-unstuck") ~= nil then
    local newState = GameRules:State_Get()
    local playerID = player:GetPlayerID()

    if HUMANS[playerID] ~= nil and newState == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
      local human = HUMANS[playerID]
      human:AddNewModifier(human, nil, 'modifier_stunned', {duration = 10})
      Timers:CreateTimer(10, function (  )
        FindClearSpaceForUnit(human, Vector(-128,0,192), true)
        return nil
      end)
    elseif VAMPIRES[playerID] ~= nil and newState == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
      local vampire = VAMPIRES[playerID]
      vampire:AddNewModifier(vampire, nil, 'modifier_stunned', {duration = 10})
      Timers:CreateTimer(10, function (  )
        FindClearSpaceForUnit(vampire, Vector(-128,0,192), true)
        return nil
      end)
    end
  end

  if string.find(msg, "-announcer") ~= nil then
    local playerID = player:GetPlayerID()
    local chat = ParseChat(keys)
    local option = chat[2]

    if option == 'on' then
      ANNOUNCER_SOUND[playerID] = true
      Notifications:Bottom(playerID, {text = "Announcer sound is enabled.", duration = 5, nil, style = {color="white", ["font-size"]="18px"}})
    end
    if option == 'off' then
      ANNOUNCER_SOUND[playerID] = false
      Notifications:Bottom(playerID, {text = "Announcer sound is disabled.", duration = 5, nil, style = {color="white", ["font-size"]="18px"}})
    end
  end

  if string.find(msg, "-ah") ~= nil then
    local playerID = player:GetPlayerID()
    local chat = ParseChat(keys)
    local option = chat[2]

    if option == 'on' then
      Notifications:Bottom(playerID, {text = "Auto harvest has been enabled on all your workers!", duration = 5, nil, style = {color="white", ["font-size"]="18px"}})
      local playerWorkers = FindUnitsInRadius(player:GetTeam(), Vector(0,0,0), nil, 10000, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO, 0, FIND_ANY_ORDER, false)
      for k,v in pairs(playerWorkers) do
        if v:GetMainControllingPlayer() == playerID then
          if v:HasAbility('harvest_channel') then
            if v.ability:GetAutoCastState() == false then
              v.ability:ToggleAutoCast()
            end
          end
        end
      end
    end
    if option == 'off' then
      Notifications:Bottom(playerID, {text = "Auto harvest has been disabled on all your workers!", duration = 5, nil, style = {color="white", ["font-size"]="18px"}})
      local playerWorkers = FindUnitsInRadius(player:GetTeam(), Vector(0,0,0), nil, 10000, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO, 0, FIND_ANY_ORDER, false)
      for k,v in pairs(playerWorkers) do
        if v:GetMainControllingPlayer() == playerID then
          if v:HasAbility('harvest_channel') then
            if v.ability:GetAutoCastState() == true then
              v.ability:ToggleAutoCast()
            end
          end
        end
      end
    end
  end
end

DEV_IDS = {
  ['51689298'] = 'particles/econ/courier/courier_greevil_green/courier_greevil_green_ambient_3.vpcf',
  ['57175732'] = 'particles/units/heroes/hero_ancient_apparition/ancient_apparition_ambient_f.vpcf',
  ['8964043'] = 'particles/econ/courier/courier_golden_doomling/courier_golden_doomling_ambient.vpcf',
  ['35147195'] = 'particles/econ/courier/courier_golden_doomling/courier_golden_doomling_ambient.vpcf',
  ['71016052'] = 'particles/econ/courier/courier_golden_doomling/courier_golden_doomling_ambient.vpcf',
  ['2059672'] = 'particles/econ/courier/courier_golden_doomling/courier_golden_doomling_ambient.vpcf',
  ['83715223'] = 'particles/econ/courier/courier_golden_doomling/courier_golden_doomling_ambient.vpcf',
  ['87441883'] = 'particles/econ/courier/courier_golden_doomling/courier_golden_doomling_ambient.vpcf',
  ['45960854'] = 'particles/econ/courier/courier_golden_doomling/courier_golden_doomling_ambient.vpcf',
  ['60699139'] = 'particles/econ/courier/courier_golden_doomling/courier_golden_doomling_ambient.vpcf',
  ['24618382'] = 'particles/econ/courier/courier_golden_doomling/courier_golden_doomling_ambient.vpcf',
  ['68458224'] = 'particles/econ/courier/courier_golden_doomling/courier_golden_doomling_ambient.vpcf',
  ['54720119'] = 'particles/econ/courier/courier_golden_doomling/courier_golden_doomling_ambient.vpcf',
  ['35695803'] = 'particles/econ/courier/courier_golden_doomling/courier_golden_doomling_ambient.vpcf'
}

function AddSwag( unit )
  for k,v in pairs(DEV_IDS) do
    local playerID = unit:GetMainControllingPlayer()
    local steamID = PlayerResource:GetSteamAccountID(playerID)
    if tostring(steamID) == k then
      local particle = v
      local ambient = ParticleManager:CreateParticle(particle, PATTACH_ABSORIGIN, unit)
      ParticleManager:SetParticleControlEnt(ambient, 0, unit, PATTACH_POINT_FOLLOW, "attach_origin", unit:GetAbsOrigin(), true)
      ParticleManager:SetParticleControlEnt(ambient, 1, unit, PATTACH_POINT_FOLLOW, "attach_origin", unit:GetAbsOrigin(), true)
    end
  end
end

function Bases:HandleChat( keys )
  local chat = ParseChat(keys)
  local pID = keys.ply:GetPlayerID()

  if chat[1] == "-allow" then
    local ownerpID = pID
    
    local sharePID = ColourToID(chat[2])
    
    if sharePID ~= -1 then
      if Bases.Owners[ownerpID] ~= nil then
        Bases.Owners[ownerpID].SharedBuilders[sharePID] = true

        local name = PlayerResource:GetPlayerName(ownerpID)
        local sharedName = PlayerResource:GetPlayerName(sharePID)
        
        GameRules:SendCustomMessage(ColorIt(name, IDToColour(ownerpID)) .. " has shared their base with " .. ColorIt(sharedName, IDToColour(sharePID)) .. "!", 0, 0)
      else
        FireGameEvent( 'custom_error_show', { player_ID = ownerpID, _error = "That's not a valid color!" } )
      end
    else
      FireGameEvent( 'custom_error_show', { player_ID = ownerpID, _error = "You have not claimed a base" } )
    end
  end 

  --require('eventtest')
--GameMode:StartEventTest()

  if chat[1] == "-disallow" then
    local ownerpID = pID
    local blockPID = ColourToID(chat[2])

    if blockPID ~= -1 then
      if Bases.Owners[ownerpID] ~= nil then
        for k, v in pairs(Bases.Owners[ownerpID].SharedBuilders) do
          if k == blockPID then
            Bases.Owners[ownerpID].SharedBuilders[k] = nil

            local name = PlayerResource:GetPlayerName(ownerpID)
            local blockName = PlayerResource:GetPlayerName(blockPID)

            GameRules:SendCustomMessage(ColorIt(blockName, IDToColour(blockPID)) .. " can no longer build in " .. ColorIt(name, IDToColour(ownerpID)) .. "'s base!", 0, 0)
          end
        end
      else
        FireGameEvent( 'custom_error_show', { player_ID = ownerpID, _error = "That's not a valid color!" } )
      end
    else
      FireGameEvent( 'custom_error_show', { player_ID = ownerpID, _error = "You have not claimed a base" } )
    end
  end
end

-- Used to add and remove gold.
function ChangeGold( playerID, amount )
  if GOLD[playerID] == nil then
    GOLD[playerID] = 0
  end
  if amount ~= nil then
    if GOLD[playerID] + amount > 1000000 then
      GOLD[playerID] = 1000000
      --GOLD[playerID] = GOLD[playerID] + amount --cheats
    elseif GOLD[playerID] + amount < 0 then
      GOLD[playerID] = 0
    else
      GOLD[playerID] = GOLD[playerID] + amount
    end
    FireGameEvent('vamp_gold_changed', {player_ID = playerID, gold_total = GOLD[playerID]})
  end
end

function ChangeWood( playerID, amount )
  if WOOD[playerID] == nil then
    WOOD[playerID] = 50
  end
  if amount ~= nil then
    if WOOD[playerID] + amount > 1000000 then
      WOOD[playerID] = 1000000
      --WOOD[playerID] = WOOD[playerID] + amount --cheats
    elseif WOOD[playerID] + amount < 0 then
      WOOD[playerID] = 0
    else
      WOOD[playerID] = WOOD[playerID] + amount
    end
    FireGameEvent('vamp_wood_changed', {player_ID = playerID, wood_total = WOOD[playerID]})
  end
end

function GameMode:CheckGemQuality( unit )
  local playerID = unit:GetMainControllingPlayer()
  --some neg pid junk
  if playerID == -1 then playerID = 0 end
  local unitName = unit:GetUnitName()
  local modifierLevel = UNIT_KV[playerID][unitName].HealthModifier
  if modifierLevel > 0 then
    local gemQuality = UNIT_KV[playerID][unitName].GemQuality
    local prevQuality = gemQuality..modifierLevel -1
    gemQuality = gemQuality..modifierLevel
    if unit:HasAbility(prevQuality) then
      unit:RemoveAbility(prevQuality)
    end
    unit:AddAbility(gemQuality)
    local gemAbility = unit:FindAbilityByName(gemQuality)
    gemAbility:SetLevel(modifierLevel)  
  end
end