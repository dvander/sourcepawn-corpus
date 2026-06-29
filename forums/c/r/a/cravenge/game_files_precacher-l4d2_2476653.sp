#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.8"

public Plugin myinfo =
{
	name = "[L4D2] Game Files Precacher",
	author = "cravenge",
	description = "Precaches Game Files To Prevent Crashes.",
	version = PLUGIN_VERSION,
	url = "forums.alliedmods.net"
};

public void OnPluginStart()
{
	char game_name[64];
	GetGameFolderName(game_name, sizeof(game_name));
	if (!StrEqual(game_name, "left4dead2", false))
	{
		SetFailState("[GFP] Plugin Supports L4D2 Only!");
	}
}

public void OnMapStart()
{
	PrecacheModel("models/survivors/survivor_gambler.mdl", true);
	PrecacheModel("models/survivors/survivor_producer.mdl", true);
	PrecacheModel("models/survivors/survivor_coach.mdl", true);
	PrecacheModel("models/survivors/survivor_mechanic.mdl", true);
	PrecacheModel("models/survivors/survivor_namvet.mdl", true);
	PrecacheModel("models/survivors/survivor_teenangst.mdl", true);
	PrecacheModel("models/survivors/survivor_biker.mdl", true);
	PrecacheModel("models/survivors/survivor_manager.mdl", true);
	PrecacheModel("models/survivors/survivor_adawong.mdl", true);
	
	PrecacheModel("models/weapons/arms/v_arms_gambler_new.mdl", true);
	PrecacheModel("models/weapons/arms/v_arms_producer_new.mdl", true);
	PrecacheModel("models/weapons/arms/v_arms_coach_new.mdl", true);
	PrecacheModel("models/weapons/arms/v_arms_mechanic_new.mdl", true);
	PrecacheModel("models/weapons/arms/v_arms_bill.mdl", true);
	PrecacheModel("models/weapons/arms/v_arms_zoey.mdl", true);
	PrecacheModel("models/weapons/arms/v_arms_francis.mdl", true);
	PrecacheModel("models/weapons/arms/v_arms_louis.mdl", true);
	
	PrecacheModel("models/v_models/v_grenade_launcher.mdl", true);
	PrecacheModel("models/w_models/weapons/w_grenade_launcher.mdl", true);
	PrecacheModel("models/v_models/v_m60.mdl", true);
	PrecacheModel("models/w_models/weapons/w_m60.mdl", true);
	PrecacheModel("models/w_models/weapons/w_minigun.mdl", true);
	PrecacheModel("models/w_models/weapons/50cal.mdl", true);
	
	PrecacheModel("models/v_models/v_rif_sg552.mdl", true);
	PrecacheModel("models/w_models/weapons/w_rifle_sg552.mdl", true);
	PrecacheModel("models/v_models/v_snip_awp.mdl", true);
	PrecacheModel("models/w_models/weapons/w_sniper_awp.mdl", true);
	PrecacheModel("models/v_models/v_snip_scout.mdl", true);
	PrecacheModel("models/w_models/weapons/w_sniper_scout.mdl", true);
	PrecacheModel("models/v_models/v_smg_mp5.mdl", true);
	PrecacheModel("models/w_models/weapons/w_smg_mp5.mdl", true);
	PrecacheModel("models/v_models/v_knife_t.mdl", true);
	PrecacheModel("models/w_models/weapons/w_knife_t.mdl", true);
	PrecacheModel("models/weapons/melee/v_riotshield.mdl", true);
	PrecacheModel("models/weapons/melee/w_riotshield.mdl", true);
	
	PrecacheModel("models/weapons/melee/v_bat.mdl", true);
	PrecacheModel("models/weapons/melee/w_bat.mdl", true);
	PrecacheModel("models/weapons/melee/v_cricket_bat.mdl", true);
	PrecacheModel("models/weapons/melee/w_cricket_bat.mdl", true);
	PrecacheModel("models/weapons/melee/v_crowbar.mdl", true);
	PrecacheModel("models/weapons/melee/w_crowbar.mdl", true);
	PrecacheModel("models/weapons/melee/v_electric_guitar.mdl", true);
	PrecacheModel("models/weapons/melee/w_electric_guitar.mdl", true);
	PrecacheModel("models/weapons/melee/v_fireaxe.mdl", true);
	PrecacheModel("models/weapons/melee/w_fireaxe.mdl", true);
	PrecacheModel("models/bunny/weapons/melee/v_b_foamfinger.mdl", true);
	PrecacheModel("models/bunny/weapons/melee/w_b_foamfinger.mdl", true);
	PrecacheModel("models/weapons/melee/v_frying_pan.mdl", true);	
	PrecacheModel("models/weapons/melee/w_frying_pan.mdl", true);
	PrecacheModel("models/weapons/melee/v_golfclub.mdl", true);	
	PrecacheModel("models/weapons/melee/w_golfclub.mdl", true);
	PrecacheModel("models/weapons/melee/v_katana.mdl", true);
	PrecacheModel("models/weapons/melee/w_katana.mdl", true);
	PrecacheModel("models/weapons/melee/v_machete.mdl", true);
	PrecacheModel("models/weapons/melee/w_machete.mdl", true);
	PrecacheModel("models/weapons/melee/v_paintrain.mdl", true);
	PrecacheModel("models/weapons/melee/w_paintrain.mdl", true);
	PrecacheModel("models/weapons/melee/v_sledgehammer.mdl", true);
	PrecacheModel("models/weapons/melee/w_sledgehammer.mdl", true);
	PrecacheModel("models/weapons/melee/v_tonfa.mdl", true);	
	PrecacheModel("models/weapons/melee/w_tonfa.mdl", true);
	PrecacheModel("models/weapons/melee/v_tonfa_riot.mdl", true);
	PrecacheModel("models/weapons/melee/w_tonfa_riot.mdl", true);
	
	PrecacheModel("models/sblitz/foam_finger.mdl", true);
	PrecacheModel("models/bunny/b_ghostanim5.mdl", true);
	PrecacheModel("models/weapons/melee/v_crowbaa.mdl", true);
	PrecacheModel("models/weapons/melee/v_electric_guitaa.mdl", true);
	
	PrecacheModel("models/v_models/v_incendiary_ammopack.mdl", true);
	PrecacheModel("models/w_models/weapons/w_eq_incendiary_ammopack.mdl", true);
	PrecacheModel("models/v_models/v_explosive_ammopack.mdl", true);
	PrecacheModel("models/w_models/weapons/w_eq_explosive_ammopack.mdl", true);
	
	PrecacheModel("models/v_models/v_bile_flask.mdl", true);	
	PrecacheModel("models/w_models/weapons/w_eq_bile_flask.mdl", true);
	PrecacheModel("models/w_models/weapons/v_cola.mdl", true);
	PrecacheModel("models/w_models/weapons/w_cola.mdl", true);
	PrecacheModel("models/weapons/melee/v_gnome.mdl", true);
	PrecacheModel("models/weapons/melee/w_gnome.mdl", true);
	
	PrecacheModel("models/infected/hulk.mdl", true);
	PrecacheModel("models/infected/hulk_dlc3.mdl", true);
	PrecacheModel("models/infected/fs_glowtank.mdl", true);
	
	PrecacheModel("models/infected/witch.mdl", true);
	PrecacheModel("models/infected/witch_bride.mdl", true);
	
	PrecacheModel("models/infected/boomette.mdl", true);
	PrecacheModel("models/infected/common_male_ceda.mdl", true);
	PrecacheModel("models/infected/common_male_clown.mdl", true);
	PrecacheModel("models/infected/common_male_fallen_survivor.mdl", true);
	PrecacheModel("models/infected/common_male_jimmy.mdl", true);
	PrecacheModel("models/infected/common_male_mud.mdl", true);
	PrecacheModel("models/infected/common_male_riot.mdl", true);
	PrecacheModel("models/infected/common_male_roadcrew.mdl", true);
	
	PrecacheModel("models/props_junk/gascan001a.mdl", true);
	PrecacheModel("models/props_junk/explosive_box001.mdl", true);
	PrecacheModel("models/props_junk/propanecanister001a.mdl", true);
	PrecacheModel("models/props_vehicles/tire001c_car.mdl", true);
	PrecacheModel("models/props_unique/airport/atlas_break_ball.mdl", true);
	
	PrecacheSound("player/survivor/voice/teengirl/hordeattack10.wav", true);
	PrecacheSound("ambient/fire/gascan_ignite1.wav", true);
	PrecacheSound("player/charger/hit/charger_smash_02.wav", true);
	PrecacheSound("npc/infected/action/die/male/death_42.wav", true);
	PrecacheSound("npc/infected/action/die/male/death_43.wav", true);
	PrecacheSound("ambient/energy/zap1.wav", true);
	PrecacheSound("ambient/energy/zap5.wav", true);
	PrecacheSound("ambient/energy/zap7.wav", true);
	PrecacheSound("player/spitter/voice/warn/spitter_spit_02.wav", true);
	PrecacheSound("player/tank/voice/growl/tank_climb_01.wav", true);
	PrecacheSound("player/tank/voice/growl/tank_climb_02.wav", true);
	PrecacheSound("player/tank/voice/growl/tank_climb_03.wav", true);
	PrecacheSound("player/tank/voice/growl/tank_climb_04.wav", true);
	
	PrecacheGeneric("scripts/melee/baseball_bat.txt", true);
	PrecacheGeneric("scripts/melee/cricket_bat.txt", true);
	PrecacheGeneric("scripts/melee/crowbar.txt", true);
	PrecacheGeneric("scripts/melee/fireaxe.txt", true);
	PrecacheGeneric("scripts/melee/foam_finger.txt", true);
	PrecacheGeneric("scripts/melee/frying_pan.txt", true);
	PrecacheGeneric("scripts/melee/golfclub.txt", true);
	PrecacheGeneric("scripts/melee/hunting_knife.txt", true);
	PrecacheGeneric("scripts/melee/katana.txt", true);
	PrecacheGeneric("scripts/melee/knife.txt", true);
	PrecacheGeneric("scripts/melee/machete.txt", true);
	PrecacheGeneric("scripts/melee/melee_manifest.txt", true);
	PrecacheGeneric("scripts/melee/nail_board.txt", true);
	PrecacheGeneric("scripts/melee/riotshield.txt", true);
	PrecacheGeneric("scripts/melee/sledgehammer.txt", true);
	PrecacheGeneric("scripts/melee/tonfa.txt", true);
	PrecacheGeneric("scripts/melee/tonfa_riotshield.txt", true);
}

