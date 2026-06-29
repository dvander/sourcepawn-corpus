#pragma semicolon 1
#include <sourcemod>

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo =
{
	name = "[L4D2] Witch Precache",
	author = "CanadaRox",
	description = "Precaches both witch models so z_spawn witch/witch_bride doesn't crash the server.",
	version = PLUGIN_VERSION,
	url = "forums.alliedmods.net"
};

new Handle:g_hEnabled;

public OnPluginStart()
{
	decl String:game_name[64];
	GetGameFolderName(game_name, sizeof(game_name));
	if (!StrEqual(game_name, "left4dead2", false))
	{
		SetFailState("Plugin supports Left 4 Dead 2 only.");
	}
	
	g_hEnabled = CreateConVar("l4d2_witchprecache_enable", "1", "Toggle precaching of witch models to prevent crashes caused by z_spawn witch/witch_bride", FCVAR_NOTIFY|FCVAR_PLUGIN);
}

public OnMapStart()
{
	if (!GetConVarBool(g_hEnabled)) return;
	
	if (!IsModelPrecached("models/infected/witch.mdl")) PrecacheModel("models/infected/witch.mdl");
	if (!IsModelPrecached("models/infected/witch_bride.mdl")) PrecacheModel("models/infected/witch_bride.mdl");
}