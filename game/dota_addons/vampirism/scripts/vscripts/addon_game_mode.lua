-- Generated from template

require('util.print')
require('util.print_table')
require('util.myutil')
require('timers')
require('vampirism')
require('buildinghelper')
require('buildui')
require('abilities')
require('buildings.building')
require('buildings.wall1')
require('buildings.house1')
require('items')
require('units.worker')
require('FlashUtil')
require('TechTree')
require('physics')
require('util')

function Precache( context )
		--[[
		This function is used to precache resources/units/items/abilities that will be needed
		for sure in your game and that cannot or should not be precached asynchronously or 
		after the game loads.

		See GameMode:PostLoadPrecache() in barebones.lua for more information
		]]

		print("[vampirism] Performing pre-load precache")



		-- Particles can be precached individually or by folder
		-- It it likely that precaching a single particle system will precache all of its children, but this may not be guaranteed
		--PrecacheResource("particle", "particles/econ/generic/generic_aoe_explosion_sere_1/generic_aoe_explosion_sphere_1.vpcf", context)
		--PrecacheResource("particle_folder", "particles/test_particle", context)
		PrecacheResource("particle", "particles/units/heroes/hero_phantom_assassin/phantom_assassin_crit_impact.vpcf", context)

		-- Models can also be precached by folder or individually
		-- PrecacheModel should generally used over PrecacheResource for individual models
		--PrecacheResource("model_folder", "particles/heroes/antimage", context)
		PrecacheModel("models/props_stone/stoneblock009a.vmdl", context)
		PrecacheModel("models/creeps/neutral_creeps/n_creep_kobold/kobold_b/n_creep_kobold_b.vmdl", context)
		PrecacheModel("models/props_structures/good_barracks_melee001.vmdl", context)
		PrecacheModel("models/house1.vmdl", context)
		PrecacheModel("models/coin_reference.vmdl", context)
		PrecacheModel("models/props_structures/barrel_fish.vmdl", context) 
		PrecacheModel("models/props_structures/secretshop_asian001.vmdl", context) 
		PrecacheModel("models/props_debris/secret_shop001.vmdl", context)
		PrecacheModel("models/props_structures/tower_good4.vmdl", context)
		PrecacheModel("models/props_teams/banner_radiant.vmdl", context)
		PrecacheModel("models/props_structures/weapon_rack_00.vmdl", context)
		PrecacheModel("models/heroes/juggernaut/jugg_healing_ward.vmdl", context)
		PrecacheModel("models/props_cave/mine_cart.vmdl", context)
		PrecacheModel("models/props_structures/good_statue008.vmdl", context)

		PrecacheResource("particle_folder", "particles/buildinghelper", context)
		PrecacheResource("particle_folder", "particles/vampire", context)

		-- unit precache
		PrecacheUnitByNameSync("tent_t2", context)
		
		--PrecacheModel("models/heroes/viper/viper.vmdl", context)

		-- Sounds can precached here like anything else
		--PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_gyrocopter.vsndevts", context)

		-- Entire items can be precached by name
		-- Abilities can also be precached in this way despite the name
		--PrecacheItemByNameSync("example_ability", context)
		--PrecacheItemByNameSync("item_example_item", context)

		-- Entire heroes (sound effects/voice/models/particles) can be precached with PrecacheUnitByNameSync
		-- Custom units from npc_units_custom.txt can also have all of their abilities and precache{} blocks precached in this way
		--PrecacheUnitByNameSync("npc_dota_hero_ancient_apparition", context)
		--PrecacheUnitByNameSync("npc_dota_hero_enigma", context)
end

-- Create the game mode when we activate
function Activate()
	GameRules.GameMode = GameMode()
	GameRules.GameMode:InitGameMode()
end