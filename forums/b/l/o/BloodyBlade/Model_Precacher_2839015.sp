#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>

#define CVAR_FLAGS FCVAR_NOTIFY

ConVar h_L4dSurvivorsEnabled, h_L4d2SurvivorsEnabled, h_WeaponsEnabled, h_M60GlEnabled, h_MeleeWeaponsEnabled, h_CssWeaponsEnabled, h_InfectedEnabled, h_CommonInfectedEnabled;

public Plugin myinfo =
{
	name = "Model Precacher",
	author = "Satannuts, Mister Game Over",
	description = "Precaches models.",
	version = "1.0",
	url = "steamcommunity.com/profiles/76561198203206199"
};

public void OnPluginStart()
{
	h_L4dSurvivorsEnabled   = CreateConVar ("precache_l4d_survivors",    "1",  "Precaching L4D Survivors",         CVAR_FLAGS);	
	h_L4d2SurvivorsEnabled  = CreateConVar ("precache_l4d2_survivors",   "1",  "Precaching L4D2 Survivors",        CVAR_FLAGS);
	h_WeaponsEnabled        = CreateConVar ("precache_weapon",           "1",  "Precaching Weapons",               CVAR_FLAGS);		
	h_M60GlEnabled          = CreateConVar ("precache_m60_gl",           "1",  "Precaching M60, Grenade Launcher", CVAR_FLAGS);	
	h_MeleeWeaponsEnabled   = CreateConVar ("precache_melee_weapons",    "1",  "Precaching Melee Weapons",         CVAR_FLAGS);	
	h_CssWeaponsEnabled	    = CreateConVar ("precache_css_weapons",      "1",  "Precaching Css Weapons",           CVAR_FLAGS);	
	h_InfectedEnabled	    = CreateConVar ("precache_infected",         "1",  "Precaching Infected",              CVAR_FLAGS);	
	h_CommonInfectedEnabled	= CreateConVar ("precache_common_infected",  "1",  "Precaching Common Infected",       CVAR_FLAGS);	
	AutoExecConfig(true, "model_precacher");		
}

void CheckPrecacheModel(const char[] Model)
{
	if (!IsModelPrecached(Model))
	{
		PrecacheModel(Model);
	}
}

public void OnMapStart()
{
	if (h_L4dSurvivorsEnabled.BoolValue)
	{	
		CheckPrecacheModel("models/survivors/survivor_teenangst.mdl");
		CheckPrecacheModel("models/survivors/survivor_biker.mdl");
		CheckPrecacheModel("models/survivors/survivor_manager.mdl");
		CheckPrecacheModel("models/survivors/survivor_namvet.mdl");
	}

	if (h_L4d2SurvivorsEnabled.BoolValue)
	{
		CheckPrecacheModel("models/survivors/survivor_coach.mdl");
		CheckPrecacheModel("models/survivors/survivor_gambler.mdl");
		CheckPrecacheModel("models/survivors/survivor_mechanic.mdl");
		CheckPrecacheModel("models/survivors/survivor_producer.mdl");
	}

	if (h_WeaponsEnabled.BoolValue)
	{	
		CheckPrecacheModel("models/v_models/v_pistola.mdl");
		CheckPrecacheModel("models/w_models/weapons/w_pistol_a.mdl");
		CheckPrecacheModel("models/v_models/v_dual_pistola.mdl");
		CheckPrecacheModel("models/w_models/weapons/w_pistol_b.mdl");
		CheckPrecacheModel("models/v_models/v_desert_eagle.mdl");
		CheckPrecacheModel("models/w_models/weapons/w_desert_eagle.mdl");
		CheckPrecacheModel("models/v_models/v_shotgun_chrome.mdl");
		CheckPrecacheModel("models/w_models/weapons/w_shotgun.mdl");
		CheckPrecacheModel("models/v_models/v_pumpshotgun.mdl");
		CheckPrecacheModel("models/w_models/weapons/w_pumpshotgun_a.mdl");	
		CheckPrecacheModel("models/v_models/v_autoshotgun.mdl");
		CheckPrecacheModel("models/w_models/weapons/w_autoshot_m4super.mdl");
		CheckPrecacheModel("models/v_models/v_shotgun_spas.mdl");
		CheckPrecacheModel("models/w_models/weapons/w_shotgun_spas.mdl");
		CheckPrecacheModel("models/v_models/v_smg.mdl");
		CheckPrecacheModel("models/w_models/weapons/w_smg_uzi.mdl");
		CheckPrecacheModel("models/v_models/v_silenced_smg.mdl");
		CheckPrecacheModel("models/w_models/weapons/w_smg_a.mdl");
		CheckPrecacheModel("models/v_models/v_desert_rifle.mdl");
		CheckPrecacheModel("models/w_models/weapons/w_desert_rifle.mdl");
		CheckPrecacheModel("models/v_models/v_rifle.mdl");
		CheckPrecacheModel("models/w_models/weapons/w_rifle_m16a2.mdl");
		CheckPrecacheModel("models/v_models/v_rifle_ak47.mdl");
		CheckPrecacheModel("models/w_models/weapons/w_rifle_ak47.mdl");
		CheckPrecacheModel("models/v_models/v_huntingrifle.mdl");
		CheckPrecacheModel("models/w_models/weapons/w_sniper_mini14.mdl");
		CheckPrecacheModel("models/v_models/v_sniper_military.mdl");
		CheckPrecacheModel("models/w_models/weapons/w_sniper_military.mdl");
	}

	if (h_M60GlEnabled.BoolValue)
	{
		CheckPrecacheModel("models/v_models/v_m60.mdl");
		CheckPrecacheModel("models/w_models/weapons/w_m60.mdl");
		CheckPrecacheModel("models/v_models/v_grenade_launcher.mdl");
		CheckPrecacheModel("models/w_models/weapons/w_grenade_launcher.mdl");
	}

	if (h_MeleeWeaponsEnabled.BoolValue)
	{
		CheckPrecacheModel("models/weapons/melee/v_golfclub.mdl");
		CheckPrecacheModel("models/weapons/melee/w_golfclub.mdl");
		CheckPrecacheModel("models/weapons/melee/v_bat.mdl");
		CheckPrecacheModel("models/weapons/melee/w_bat.mdl");
		CheckPrecacheModel("models/weapons/melee/v_riotshield.mdl");
		CheckPrecacheModel("models/weapons/melee/w_riotshield.mdl");
		CheckPrecacheModel("models/weapons/melee/v_tonfa.mdl");
		CheckPrecacheModel("models/weapons/melee/w_tonfa.mdl");
		CheckPrecacheModel("models/weapons/melee/v_cricket_bat.mdl");
		CheckPrecacheModel("models/weapons/melee/w_cricket_bat.mdl");
		CheckPrecacheModel("models/weapons/melee/v_crowbar.mdl");
		CheckPrecacheModel("models/weapons/melee/w_crowbar.mdl");	
		CheckPrecacheModel("models/weapons/melee/v_chainsaw.mdl");
		CheckPrecacheModel("models/weapons/melee/w_chainsaw.mdl");
		CheckPrecacheModel("models/weapons/melee/v_electric_guitar.mdl");
		CheckPrecacheModel("models/weapons/melee/w_electric_guitar.mdl");
		CheckPrecacheModel("models/weapons/melee/v_fireaxe.mdl");
		CheckPrecacheModel("models/weapons/melee/w_fireaxe.mdl");
		CheckPrecacheModel("models/weapons/melee/v_frying_pan.mdl");	
		CheckPrecacheModel("models/weapons/melee/w_frying_pan.mdl");
		CheckPrecacheModel("models/weapons/melee/v_katana.mdl");
		CheckPrecacheModel("models/weapons/melee/w_katana.mdl");
		CheckPrecacheModel("models/weapons/melee/v_machete.mdl");
		CheckPrecacheModel("models/weapons/melee/w_machete.mdl");
		CheckPrecacheModel("models/weapons/melee/w_shovel.mdl");
		CheckPrecacheModel("models/weapons/melee/v_shovel.mdl");
		CheckPrecacheModel("models/weapons/melee/w_pitchfork.mdl");
		CheckPrecacheModel("models/weapons/melee/v_pitchfork.mdl");
	}

	if (h_CssWeaponsEnabled.BoolValue)
	{
		CheckPrecacheModel("models/v_models/v_rif_sg552.mdl");
		CheckPrecacheModel("models/w_models/weapons/w_rifle_sg552.mdl");
		CheckPrecacheModel("models/v_models/v_snip_awp.mdl");
		CheckPrecacheModel("models/w_models/weapons/w_sniper_awp.mdl");
		CheckPrecacheModel("models/v_models/v_snip_scout .mdl");
		CheckPrecacheModel("models/w_models/weapons/w_sniper_scout.mdl");
		CheckPrecacheModel("models/v_models/v_smg_mp5.mdl");
		CheckPrecacheModel("models/w_models/weapons/w_smg_mp5.mdl");
		CheckPrecacheModel("models/v_models/v_knife_t.mdl");
		CheckPrecacheModel("models/w_models/weapons/w_knife_t.mdl");
	}

	if (h_InfectedEnabled.BoolValue)
	{
		CheckPrecacheModel("models/infected/hulk.mdl");
		CheckPrecacheModel("models/infected/hulk_dlc3.mdl");
		CheckPrecacheModel("models/infected/witch.mdl");
		CheckPrecacheModel("models/infected/witch_bride.mdl");
		CheckPrecacheModel("models/infected/boomette.mdl");
		CheckPrecacheModel("models/infected/limbs/exploded_boomette.mdl");
	}

	if (h_CommonInfectedEnabled.BoolValue)
	{
		CheckPrecacheModel("models/infected/common_male_ceda.mdl");
		CheckPrecacheModel("models/infected/common_male_clown.mdl");
		CheckPrecacheModel("models/infected/common_male_fallen_survivor.mdl");
		CheckPrecacheModel("models/infected/common_male_jimmy.mdl");
		CheckPrecacheModel("models/infected/common_male_mud.mdl");
		CheckPrecacheModel("models/infected/common_male_riot.mdl");
		CheckPrecacheModel("models/infected/common_male_roadcrew.mdl");
		CheckPrecacheModel("models/infected/common_male_dressShirt_jeans.mdl");
		CheckPrecacheModel("models/infected/common_female_tankTop_jeans.mdl");
		CheckPrecacheModel("models/infected/common_female_tshirt_skirt.mdl");
	}
}
