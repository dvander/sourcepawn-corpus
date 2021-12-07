#pragma semicolon 1
#include <sourcemod>

#define PLUGIN_VERSION "1.666.1"

public Plugin:myinfo =
{
	name = "[L4D2] Model Precacher",
	author = "satannuts",
	description = "Precaches models so z_spawn use doesn't crash the server.",
	version = PLUGIN_VERSION,
	url = "forums.alliedmods.net"
};

new Handle:h_billEnabled = INVALID_HANDLE;
new Handle:h_survivorsEnabled = INVALID_HANDLE;

new Handle:h_m60Enabled = INVALID_HANDLE;
new Handle:h_cssweaponsEnabled = INVALID_HANDLE;
new Handle:h_meleeEnabled = INVALID_HANDLE;

new Handle:h_miscEnabled = INVALID_HANDLE;

new Handle:h_tankEnabled = INVALID_HANDLE;
new Handle:h_witchEnabled = INVALID_HANDLE;
new Handle:h_infectedEnabled = INVALID_HANDLE;

public OnPluginStart()
{
	decl String:game_name[64];
	GetGameFolderName(game_name, sizeof(game_name));
	if (!StrEqual(game_name, "left4dead2", false))
	{
		SetFailState("Plugin supports Left 4 Dead 2 only.");
	}

	h_billEnabled = CreateConVar("l4d2_precache_bill", "1", "Toggle precaching of Bill's model to prevent crashes caused by sb_add", FCVAR_NOTIFY|FCVAR_PLUGIN);	
	h_survivorsEnabled = CreateConVar("l4d2_precache_survivors", "1", "Toggle precaching of L4D1 survivor models to prevent crashes after the passing update", FCVAR_NOTIFY|FCVAR_PLUGIN);

	h_m60Enabled = CreateConVar("l4d2_precache_m60", "1", "Toggle precaching of the m60 model to prevent crashes caused by z_spawn", FCVAR_NOTIFY|FCVAR_PLUGIN);
	h_cssweaponsEnabled = CreateConVar("l4d2_precache_cssweapons", "1", "Toggle precaching of css weapon models to prevent crashes caused by z_spawn", FCVAR_NOTIFY|FCVAR_PLUGIN);
	h_meleeEnabled = CreateConVar("l4d2_precache_melee", "1", "Toggle precaching of melee weapon models to prevent crashes caused by z_spawn", FCVAR_NOTIFY|FCVAR_PLUGIN);

	h_miscEnabled = CreateConVar("l4d2_precache_misc", "1", "Toggle precaching of miscellaneous models to prevent crashes caused by z_spawn", FCVAR_NOTIFY|FCVAR_PLUGIN);

	h_tankEnabled = CreateConVar("l4d2_precache_tank", "1", "Toggle precaching of tank models to prevent crashes caused by z_spawn", FCVAR_NOTIFY|FCVAR_PLUGIN);
	h_witchEnabled = CreateConVar("l4d2_precache_witch", "1", "Toggle precaching of witch models to prevent crashes caused by z_spawn", FCVAR_NOTIFY|FCVAR_PLUGIN);
	h_infectedEnabled = CreateConVar("l4d2_precache_infected", "1", "Toggle precaching of infected models to prevent crashes caused by z_spawn", FCVAR_NOTIFY|FCVAR_PLUGIN);
	AutoExecConfig(true, "l4d2_model_precacher");
}

public OnMapStart()

{
	//Precache Bill
	if (!GetConVarBool(h_billEnabled)) return;
	if (!IsModelPrecached("models/survivors/survivor_namvet.mdl")) PrecacheModel("models/survivors/survivor_namvet.mdl");

	//Precache L4D1 Survivors
	if (!GetConVarBool(h_survivorsEnabled)) return;
	if (!IsModelPrecached("models/survivors/survivor_teenangst.mdl")) PrecacheModel("models/survivors/survivor_teenangst.mdl");
	if (!IsModelPrecached("models/survivors/survivor_biker.mdl")) PrecacheModel("models/survivors/survivor_biker.mdl");
	if (!IsModelPrecached("models/survivors/survivor_manager.mdl")) PrecacheModel("models/survivors/survivor_manager.mdl");

	//Precache M60
	if (!GetConVarBool(h_m60Enabled)) return;
	if (!IsModelPrecached("models/v_models/v_m60.mdl")) PrecacheModel("models/v_models/v_m60.mdl");
	if (!IsModelPrecached("models/w_models/weapons/w_m60.mdl")) PrecacheModel("models/w_models/weapons/w_m60.mdl");
	
	//Precache CSS Weapons
	if (!GetConVarBool(h_cssweaponsEnabled)) return;
	if (!IsModelPrecached("models/v_models/v_rif_sg552.mdl")) PrecacheModel("models/v_models/v_rif_sg552.mdl");
	if (!IsModelPrecached("models/w_models/weapons/w_rifle_sg552.mdl")) PrecacheModel("models/w_models/weapons/w_rifle_sg552.mdl");
	if (!IsModelPrecached("models/v_models/v_snip_awp.mdl")) PrecacheModel("models/v_models/v_snip_awp.mdl");
	if (!IsModelPrecached("models/w_models/weapons/w_sniper_awp.mdl")) PrecacheModel("models/w_models/weapons/w_sniper_awp.mdl");
	if (!IsModelPrecached("models/v_models/v_snip_scout.mdl")) PrecacheModel("models/v_models/v_snip_scout .mdl");
	if (!IsModelPrecached("models/w_models/weapons/w_sniper_scout.mdl")) PrecacheModel("models/w_models/weapons/w_sniper_scout.mdl");
	if (!IsModelPrecached("models/v_models/v_smg_mp5.mdl")) PrecacheModel("models/v_models/v_smg_mp5.mdl");
	if (!IsModelPrecached("models/w_models/weapons/w_smg_mp5.mdl")) PrecacheModel("models/w_models/weapons/w_smg_mp5.mdl");
	if (!IsModelPrecached("models/v_models/v_knife_t.mdl")) PrecacheModel("models/v_models/v_knife_t.mdl");
	if (!IsModelPrecached("models/w_models/weapons/w_knife_t.mdl")) PrecacheModel("models/w_models/weapons/w_knife_t.mdl");
	
	//Precache Melee Weapons
	if (!GetConVarBool(h_meleeEnabled)) return;
	if (!IsModelPrecached("models/weapons/melee/v_golfculb.mdl")) PrecacheModel("models/weapons/melee/v_golfculb.mdl");
	if (!IsModelPrecached("models/weapons/melee/w_golfculb.mdl")) PrecacheModel("models/weapons/melee/w_golfculb.mdl");
	if (!IsModelPrecached("models/weapons/melee/v_bat.mdl")) PrecacheModel("models/weapons/melee/v_bat.mdl");
	if (!IsModelPrecached("models/weapons/melee/w_bat.mdl")) PrecacheModel("models/weapons/melee/w_bat.mdl");
	if (!IsModelPrecached("models/weapons/melee/v_riotshield.mdl")) PrecacheModel("models/weapons/melee/v_riotshield.mdl");
	if (!IsModelPrecached("models/weapons/melee/w_riotshield.mdl")) PrecacheModel("models/weapons/melee/w_riotshield.mdl");
	if (!IsModelPrecached("models/weapons/melee/v_tonfa.mdl")) PrecacheModel("models/weapons/melee/v_tonfa.mdl");
	if (!IsModelPrecached("models/weapons/melee/w_tonfa.mdl")) PrecacheModel("models/weapons/melee/w_tonfa.mdl");

	//Precache Misc
	if (!GetConVarBool(h_miscEnabled)) return;
	if (!IsModelPrecached("models/v_models/v_bile_flask.mdl")) PrecacheModel("models/v_models/v_bile_flask.mdl");	
	if (!IsModelPrecached("models/w_models/weapons/w_eq_bile_flask.mdl")) PrecacheModel("models/w_models/weapons/w_eq_bile_flask.mdl");
	if (!IsModelPrecached("models/w_models/weapons/v_cola.mdl")) PrecacheModel("models/w_models/weapons/v_cola.mdl");
	if (!IsModelPrecached("models/w_models/weapons/W_cola.mdl")) PrecacheModel("models/w_models/weapons/W_cola.mdl");
	if (!IsModelPrecached("models/weapons/melee/v_gnome.mdl")) PrecacheModel("models/weapons/melee/v_gnome.mdl");
	if (!IsModelPrecached("models/weapons/melee/w_gnome.mdl")) PrecacheModel("models/weapons/melee/w_gnome.mdl");

	//Precache Tank
	if (!GetConVarBool(h_tankEnabled)) return;
	if (!IsModelPrecached("models/infected/hulk.mdl")) PrecacheModel("models/infected/hulk.mdl");
	
	//Precache Witch
	if (!GetConVarBool(h_witchEnabled)) return;
	if (!IsModelPrecached("models/infected/witch.mdl")) PrecacheModel("models/infected/witch.mdl");
	if (!IsModelPrecached("models/infected/witch_bride.mdl")) PrecacheModel("models/infected/witch_bride.mdl");
		
	//Precache Infected
	if (!GetConVarBool(h_infectedEnabled)) return;
	if (!IsModelPrecached("models/infected/boomette.mdl")) PrecacheModel("models/infected/boomette.mdl");
	if (!IsModelPrecached("models/infected/common_male_ceda.mdl")) PrecacheModel("models/infected/common_male_ceda.mdl");
	if (!IsModelPrecached("models/infected/common_male_clown.mdl")) PrecacheModel("models/infected/common_male_clown.mdl");
	if (!IsModelPrecached("models/infected/common_male_fallen_survivor.mdl")) PrecacheModel("models/infected/common_male_fallen_survivor.mdl");
	if (!IsModelPrecached("models/infected/common_male_jimmy.mdl")) PrecacheModel("models/infected/common_male_jimmy.mdl");
	if (!IsModelPrecached("models/infected/common_male_mud.mdl")) PrecacheModel("models/infected/common_male_mud.mdl");
	if (!IsModelPrecached("models/infected/common_male_riot.mdl")) PrecacheModel("models/infected/common_male_riot.mdl");
	if (!IsModelPrecached("models/infected/common_male_roadcrew.mdl")) PrecacheModel("models/infected/common_male_roadcrew.mdl");
}