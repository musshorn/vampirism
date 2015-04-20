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
require('abilities.vampire')

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
		PrecacheResource("particle", "particles/units/heroes/hero_wisp/wisp_base_attack.vpcf", context)
		PrecacheResource("particle", "particles/units/heroes/hero_oracle/oracle_base_attack.vpcf", context)
		PrecacheResource("particle", "particles/neutral_fx/satyr_trickster_projectile.vpcf", context)
		PrecacheResource("particle", "particles/msg_heal.vpcf", context)
		PrecacheResource("particle", "particles/vampire/shadow_demon_disruption.vpcf", context)
		PrecacheResource("particle", "particles/items_fx/necronomicon_true_sight.vpcf", context)
		PrecacheResource("particle", "particles/base_attacks/ranged_tower_bad.vpcf", context)
		PrecacheResource("particle", "particles/items_fx/desolator_projectile.vpcf", context)
		PrecacheResource("particle", "particles/items2_fx/skadi_projectile.vpcf", context)
		PrecacheResource("particle", "particles/units/heroes/hero_shadow_demon/shadow_demon_base_attack.vpcf", context)

		-- Models can also be precached by folder or individually
		-- PrecacheModel should generally used over PrecacheResource for individual models
		--PrecacheResource("model_folder", "particles/heroes/antimage", context)
		PrecacheModel("models/props_stone/stoneblock009a.vmdl", context)
		PrecacheModel("models/creeps/neutral_creeps/n_creep_kobold/kobold_b/n_creep_kobold_b.vmdl", context)
		PrecacheModel("models/props_structures/good_barracks_melee001.vmdl", context)
		PrecacheModel("models/house1.vmdl", context)
		PrecacheModel("models/heroes/invoker/invoker.vmdl", context)
		PrecacheModel("models/coin_reference.vmdl", context)
		PrecacheModel("models/props_structures/barrel_fish.vmdl", context) 
		PrecacheModel("models/props_structures/good_barracks_ranged002.vmdl", context) 
		PrecacheModel("models/props_debris/secret_shop001.vmdl", context)
		PrecacheModel("models/tower_good4_reference.vmdl", context)
		PrecacheModel("models/props_teams/banner_radiant.vmdl", context)
		PrecacheModel("models/props_structures/weapon_rack_00.vmdl", context)
		PrecacheModel("models/heroes/juggernaut/jugg_healing_ward.vmdl", context)
		PrecacheModel("models/props_cave/mine_cart.vmdl", context)
		PrecacheModel("models/props_structures/good_statue008.vmdl", context)
		PrecacheModel("models/heroes/nightstalker/nightstalker_wings.vmdl", context)
		PrecacheModel("models/barrel_fish_reference.vmdl", context)
		PrecacheModel("models/barrel_oct_reference.vmdl", context)
		PrecacheModel("models/props_rock/riveredge_rock006a.vmdl", context)
		PrecacheModel("models/crystal_spike_sub1.vmdl", context)
		PrecacheModel("models/statue_cuttlefish001.vmdl", context)
		PrecacheModel("bad_column_torch_reference.vmdl", context)
		PrecacheModel("models/bloodstone_reference.vmdl", context)
		PrecacheModel("models/crystal_ring01_reference.vmdl", context)
		PrecacheModel("models/props_structures/bad_statue002.vmdl", context)
		PrecacheModel("models/items/wards/celestial_observatory/celestial_observatory.vmdl", context)
		
		-- Placeholder models for walls
		PrecacheModel("models/heroes/keeper_of_the_light/horsefx.vmdl",context)
		PrecacheModel("models/heroes/mirana/mount.vmdl",context)
		PrecacheModel("models/heroes/phoenix/phoenix_egg.vmdl",context)
		PrecacheModel("models/heroes/undying/undying_tower.vmdl",context)
		PrecacheModel("models/items/chen/mount_navi_combined/mount_navi_combined.vmdl",context)
		PrecacheModel("models/items/courier/carty/carty.vmdl",context)
		PrecacheModel("models/items/lone_druid/viciouskraitpanda/viciouskrait_panda.vmdl",context)
		PrecacheModel("models/props_bones/rib_cage001.vmdl",context)
		PrecacheModel("models/props_gameplay/shopkeeper_dire/secretshopkeeper_dire.vmdl",context)


		PrecacheResource("particle_folder", "particles/buildinghelper", context)
		PrecacheResource("particle_folder", "particles/vampire", context)

		-- unit precache
		PrecacheUnitByNameSync("tent_t2", context)
		PrecacheUnitByNameSync("shiny_tower_pearls", context)
		PrecacheUnitByNameSync("npc_dota_hero_night_stalker", context)
		PrecacheUnitByNameSync("npc_dota_hero_omniknight", context)
		PrecacheUnitByNameSync("npc_dota_hero_jakiro", context)
		PrecacheUnitByNameSync("npc_dota_hero_invoker", context)
		PrecacheUnitByNameSync("slayer_tracker", context)
		
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