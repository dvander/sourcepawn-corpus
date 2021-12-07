#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.1a"

public Plugin:myinfo =
{
	name = "TF2 Medic Farming",
	author = "R-Hehl",
	description = "TF2 Medic Farming",
	version = PLUGIN_VERSION,
	url = "http://compactaim.de"
}

public OnPluginStart()
{
	CreateConVar("sm_tf2_farm_version", PLUGIN_VERSION, "TF2 Medic Farming", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegConsoleCmd("charge", Command_medup);
	RegConsoleCmd("health", Command_health);
}

public Action:Command_medup(client, args)
{
	if (GetEntProp(client, Prop_Send, "m_iClass") == 5)
		TF_SetUberLevel(client, 100);
	else
		ReplyToCommand(client, "[SM] You must be a medic to use this command.");
}

public Action:Command_health(client, args)
	SetEntityHealth(client, 1);

stock TF_SetUberLevel(client, uberlevel)
{
	new index = GetPlayerWeaponSlot(client, 1);
	if (index > 0)
		SetEntPropFloat(index, Prop_Send, "m_flChargeLevel", uberlevel*0.01);
}