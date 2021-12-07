#define PLUGIN_VERSION		"1.2"

public Plugin myinfo = 
{
	name = "[L4D] Model Precacher",
	author = "Alex Dragokas",
	description = "Prevents late precache of specific models",
	version = PLUGIN_VERSION,
	url = "https://github.com/dragokas/"
};

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

bool g_bLeft4dead2;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	g_bLeft4dead2 = (test == Engine_Left4Dead2);
	return APLRes_Success;
}

public void OnPluginStart()
{
}

public void OnMapStart()
{
	// 	PrecacheModel("...

	if( g_bLeft4dead2 )
	{
		PrecacheL4D2();
	}
	else {
		PrecacheL4D1();
	}
}

void PrecacheL4D1()
{
	PrecacheModel("models/props_junk/wood_crate001a_chunk01.mdl" , true);
	PrecacheModel("models/props_junk/wood_crate001a_chunk02.mdl" , true);
	PrecacheModel("models/props_junk/wood_crate001a_chunk03.mdl" , true);
	PrecacheModel("models/props_junk/wood_crate001a_chunk04.mdl" , true);
	PrecacheModel("models/props_junk/wood_crate001a_chunk05.mdl" , true);
	PrecacheModel("models/props_junk/wood_crate001a_chunk06.mdl" , true);
	PrecacheModel("models/props_junk/wood_crate001a_chunk07.mdl" , true);
	PrecacheModel("models/props_junk/wood_crate001a_chunk08.mdl" , true);
	PrecacheModel("models/props_junk/wood_crate001a_chunk09.mdl" , true);
	
	PrecacheSound("music/terror/PuddleOfYou.wav", true);
	PrecacheSound("music/terror/ClingingToHellHit1.wav", true);
	PrecacheSound("music/terror/ClingingToHellHit2.wav", true);
	PrecacheSound("music/terror/ClingingToHellHit3.wav", true);
	PrecacheSound("music/terror/ClingingToHellHit4.wav", true);
	
	PrecacheModel("sprites/glow_test02.vmt", true);
}
	
void PrecacheL4D2()
{
	// weapons
	if (!IsModelPrecached("models/survivors/survivor_biker.mdl")) // 'by iHX
	{
		PrecacheModel("models/survivors/survivor_biker.mdl", false);
	}
	if (!IsModelPrecached("models/survivors/survivor_manager.mdl"))
	{
		PrecacheModel("models/survivors/survivor_manager.mdl", false);
	}
	if (!IsModelPrecached("models/survivors/survivor_teenangst.mdl"))
	{
		PrecacheModel("models/survivors/survivor_teenangst.mdl", false);
	}
	if (!IsModelPrecached("models/survivors/survivor_coach.mdl"))
	{
		PrecacheModel("models/survivors/survivor_coach.mdl", false);
	}
	if (!IsModelPrecached("models/survivors/survivor_gambler.mdl"))
	{
		PrecacheModel("models/survivors/survivor_gambler.mdl", false);
	}
	if (!IsModelPrecached("models/survivors/survivor_namvet.mdl"))
	{
		PrecacheModel("models/survivors/survivor_namvet.mdl", false);
	}
	if (!IsModelPrecached("models/survivors/survivor_mechanic.mdl"))
	{
		PrecacheModel("models/survivors/survivor_mechanic.mdl", false);
	}
	if (!IsModelPrecached("models/survivors/survivor_producer.mdl"))
	{
		PrecacheModel("models/survivors/survivor_producer.mdl", false);
	}
	if (!IsModelPrecached("models/infected/witch.mdl"))
	{
		PrecacheModel("models/infected/witch.mdl", false);
	}
	if (!IsModelPrecached("models/infected/witch_bride.mdl"))
	{
		PrecacheModel("models/infected/witch_bride.mdl", false);
	}
	if (!IsModelPrecached("models/v_models/v_rif_sg552.mdl"))
	{
		PrecacheModel("models/v_models/v_rif_sg552.mdl", false);
	}
	if (!IsModelPrecached("models/v_models/v_smg_mp5.mdl"))
	{
		PrecacheModel("models/v_models/v_smg_mp5.mdl", false);
	}
	if (!IsModelPrecached("models/v_models/v_snip_awp.mdl"))
	{
		PrecacheModel("models/v_models/v_snip_awp.mdl", false);
	}
	if (!IsModelPrecached("models/v_models/v_snip_scout.mdl"))
	{
		PrecacheModel("models/v_models/v_snip_scout.mdl", false);
	}
	if (!IsModelPrecached("models/w_models/weapons/50cal.mdl"))
	{
		PrecacheModel("models/w_models/weapons/50cal.mdl", false);
	}
	if (!IsModelPrecached("models/w_models/weapons/w_knife_t.mdl"))
	{
		PrecacheModel("models/w_models/weapons/w_knife_t.mdl", false);
	}
	if (!IsModelPrecached("models/w_models/weapons/w_rifle_sg552.mdl"))
	{
		PrecacheModel("models/w_models/weapons/w_rifle_sg552.mdl", false);
	}
	if (!IsModelPrecached("models/w_models/weapons/w_smg_mp5.mdl"))
	{
		PrecacheModel("models/w_models/weapons/w_smg_mp5.mdl", false);
	}
	if (!IsModelPrecached("models/w_models/weapons/w_sniper_awp.mdl"))
	{
		PrecacheModel("models/w_models/weapons/w_sniper_awp.mdl", false);
	}
	if (!IsModelPrecached("models/w_models/weapons/w_sniper_scout.mdl"))
	{
		PrecacheModel("models/w_models/weapons/w_sniper_scout.mdl", false);
	}
	if (!IsModelPrecached("models/weapons/melee/v_fireaxe.mdl"))
	{
		PrecacheModel("models/weapons/melee/v_fireaxe.mdl", false);
	}
	if (!IsModelPrecached("models/weapons/melee/v_frying_pan.mdl"))
	{
		PrecacheModel("models/weapons/melee/v_frying_pan.mdl", false);
	}
	if (!IsModelPrecached("models/weapons/melee/v_golfclub.mdl"))
	{
		PrecacheModel("models/weapons/melee/v_golfclub.mdl", false);
	}
	if (!IsModelPrecached("models/weapons/melee/v_machete.mdl"))
	{
		PrecacheModel("models/weapons/melee/v_machete.mdl", false);
	}
	if (!IsModelPrecached("models/weapons/melee/w_cricket_bat.mdl"))
	{
		PrecacheModel("models/weapons/melee/w_cricket_bat.mdl", false);
	}
	if (!IsModelPrecached("models/weapons/melee/w_crowbar.mdl"))
	{
		PrecacheModel("models/weapons/melee/w_crowbar.mdl", false);
	}
	if (!IsModelPrecached("models/weapons/melee/w_electric_guitar.mdl"))
	{
		PrecacheModel("models/weapons/melee/w_electric_guitar.mdl", false);
	}
	if (!IsModelPrecached("models/weapons/melee/w_frying_pan.mdl"))
	{
		PrecacheModel("models/weapons/melee/w_frying_pan.mdl", false);
	}
	if (!IsModelPrecached("models/weapons/melee/w_golfclub.mdl"))
	{
		PrecacheModel("models/weapons/melee/w_golfclub.mdl", false);
	}
	if (!IsModelPrecached("models/weapons/melee/w_katana.mdl"))
	{
		PrecacheModel("models/weapons/melee/w_katana.mdl", false);
	}
	if (!IsModelPrecached("models/weapons/melee/w_machete.mdl"))
	{
		PrecacheModel("models/weapons/melee/w_machete.mdl", false);
	}
	if (!IsModelPrecached("models/weapons/melee/w_tonfa.mdl"))
	{
		PrecacheModel("models/weapons/melee/w_tonfa.mdl", false);
	}
	if (!IsModelPrecached("models/weapons/melee/w_shovel.mdl"))
	{
		PrecacheModel("models/weapons/melee/w_shovel.mdl", false);
	}
	if (!IsModelPrecached("models/weapons/melee/w_pitchfork.mdl"))
	{
		PrecacheModel("models/weapons/melee/w_pitchfork.mdl", false);
	}
	
	//other
	PrecacheDecal("decals/rocketdude/rd_logo_glow"); // not sure is it correct path
	
	//late precache
	PrecacheModel("models/deadbodies/dead_male_civilian_body.mdl");
	PrecacheModel("models/deadbodies/dead_male_sittingchair.mdl");
	PrecacheModel("models/props/cs_militia/fireplacechimney01.mdl");
	PrecacheModel("models/props/cs_militia/militiarock01.mdl");
	PrecacheModel("models/props/cs_militia/militiarock02.mdl");
	PrecacheModel("models/props/cs_office/computer_caseb.mdl");
	PrecacheModel("models/props/cs_office/computer_mouse.mdl");
	PrecacheModel("models/props/de_prodigy/ammo_can_02.mdl");
	PrecacheModel("models/props/cs_office/computer_caseb_gib1.mdl");
	PrecacheModel("models/props/cs_office/computer_caseb_gib2.mdl");
	PrecacheModel("models/props/cs_office/computer_caseb_p1.mdl");
	PrecacheModel("models/props/cs_office/computer_caseb_p1a.mdl");
	PrecacheModel("models/props/cs_office/computer_caseb_p2.mdl");
	PrecacheModel("models/props/cs_office/computer_caseb_p2a.mdl");
	PrecacheModel("models/props/cs_office/computer_caseb_p3.mdl");
	PrecacheModel("models/props/cs_office/computer_caseb_p3a.mdl");
	PrecacheModel("models/props/cs_office/computer_caseb_p4.mdl");
	PrecacheModel("models/props/cs_office/computer_caseb_p4a.mdl");
	PrecacheModel("models/props/cs_office/computer_caseb_p4b.mdl");
	PrecacheModel("models/props/cs_office/computer_caseb_p5.mdl");
	PrecacheModel("models/props/cs_office/computer_caseb_p5a.mdl");
	PrecacheModel("models/props/cs_office/computer_caseb_p5b.mdl");
	PrecacheModel("models/props/cs_office/computer_caseb_p6.mdl");
	PrecacheModel("models/props/cs_office/computer_caseb_p6a.mdl");
	PrecacheModel("models/props/cs_office/computer_caseb_p6b.mdl");
	PrecacheModel("models/props/cs_office/computer_caseb_p7.mdl");
	PrecacheModel("models/props/cs_office/computer_caseb_p7a.mdl");
	PrecacheModel("models/props/cs_office/computer_caseb_p8.mdl");
	PrecacheModel("models/props/cs_office/computer_caseb_p8a.mdl");
	PrecacheModel("models/props/cs_office/computer_caseb_p9.mdl");
	PrecacheModel("models/props/cs_office/computer_caseb_p9a.mdl");
	PrecacheModel("models/props_c17/computer01_keyboard.mdl");
	PrecacheModel("models/props_crates/static_crate_40.mdl");
	PrecacheModel("models/props_downtown/booth_table.mdl");
	PrecacheModel("models/props_fairgrounds/alligator.mdl");
	PrecacheModel("models/props_fairgrounds/anvil_case_casters_64.mdl");
	PrecacheModel("models/props_fairgrounds/bass_case.mdl");
	PrecacheModel("models/props_foliage/trees_cluster01.mdl");
	PrecacheModel("models/props_interiors/computer_monitor.mdl");
	PrecacheModel("models/props_interiors/desk_metal.mdl");
	PrecacheModel("models/props_interiors/computer_monitor_p1.mdl");
	PrecacheModel("models/props_interiors/computer_monitor_p1a.mdl");
	PrecacheModel("models/props_interiors/computer_monitor_p2.mdl");
	PrecacheModel("models/props_interiors/computer_monitor_p2a.mdl");
	PrecacheModel("models/props_lighting/lightbulb01a.mdl");
	PrecacheModel("models/props_pipes/pipeset08d_128_001a.mdl");
	PrecacheModel("models/props_unique/spawn_apartment/lantern.mdl");
	PrecacheModel("models/props_unique/zombiebreakwallhospitalexterior01_main.mdl");
	PrecacheModel("models/props_unique/zombiebreakwallexteriorhospitalframe01_dm.mdl");
	PrecacheModel("models/props_unique/zombiebreakwallexteriorhospitalpart01_dm.mdl");
	PrecacheModel("models/props_unique/zombiebreakwallexteriorhospitalpart02_dm.mdl");
	PrecacheModel("models/props_unique/zombiebreakwallexteriorhospitalpart03_dm.mdl");
	PrecacheModel("models/props_unique/zombiebreakwallexteriorhospitalpart04_dm.mdl");
	PrecacheModel("models/props_unique/zombiebreakwallexteriorhospitalpart05_dm.mdl");
	PrecacheModel("models/props_unique/zombiebreakwallexteriorhospitalpart06_dm.mdl");
	PrecacheModel("models/props_unique/zombiebreakwallexteriorhospitalpart07_dm.mdl");
	PrecacheModel("models/props_unique/zombiebreakwallexteriorhospitalpart08_dm.mdl");
	PrecacheModel("models/props_unique/zombiebreakwallexteriorhospitalpart09_dm.mdl");
	PrecacheModel("models/props_update/plywood_128.mdl");
	PrecacheModel("models/props_urban/gas_meter.mdl");
	PrecacheModel("models/props_vehicles/deliveryvan_armored.mdl");
	PrecacheModel("models/props_vehicles/deliveryvan_armored_glass.mdl");
	PrecacheModel("models/props_vehicles/pickup_truck_2004.mdl");
	PrecacheModel("models/props_vehicles/pickup_truck_2004_glass.mdl");
	PrecacheModel("models/props_vehicles/racecar_damaged_glass.mdl");
	PrecacheModel("models/props_vehicles/van.mdl");
	PrecacheModel("models/props_vehicles/van_glass.mdl");
	
	// late precache
	PrecacheSound("physics/destruction/ExplosiveGasLeak.wav");
	
	//crash
	PrecacheModel("models/props_unique/spawn_apartment/coffeeammo.mdl", true);
	PrecacheModel("models/props_unique/zombiebreakwallexteriorhospitalframe01_dm.mdl", true);
}

// Vitamin
// PrecacheModel("sprites/l4d_zone_1.vmt", true); - работает !!! Спасибо