#define PLUGIN_VERSION 		"1.0"

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define MODEL_BOOMETTE		"models/infected/boomette.mdl"
#define MODEL_LIMBS			"models/infected/limbs/exploded_boomette.mdl"

public Plugin myinfo =
{
	name = "[L4D2] Leaker",
	author = "SilverShot",
	description = "Boomer Leaker.",
	version = PLUGIN_VERSION,
	url = "https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers"
}

public void OnPluginStart()
{
	HookEvent("player_spawn", Event_PlayerSpawn);
}

public void OnMapStart()
{
	PrecacheModel(MODEL_BOOMETTE);
	PrecacheModel(MODEL_LIMBS);
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if( client && GetClientTeam(client) == 3 && GetEntProp(client, Prop_Send, "m_zombieClass") == 2 && GetEntProp(client, Prop_Send, "m_nVariantType") == 1 )
	{
		SetEntityModel(client, MODEL_BOOMETTE);
	}
}