#include <sourcemod>
#include <tf2>
#include <tf2_stocks>

new Handle:g_hCvarEnabled;

public Plugin:myinfo = 
{
	name = "Scouts Can't Teleport",
	author = "Afronanny",
	description = "Scouts cannot take teleporters",
	version = "1.0",
	url = "http://www.afronanny.org/"
}

public OnPluginStart()
{
	CreateConVar("sm_teleportcheck_version", "1.0", _, FCVAR_NOTIFY);
	g_hCvarEnabled = CreateConVar("sm_teleportcheck_enabled", "1");
}

public Action:TF2_OnPlayerTeleport(client, teleporter, &bool:result)
{
	if (TF2_GetPlayerClass(client) == TFClass_Scout && GetConVarBool(g_hCvarEnabled))
	{
		result = false;
		return Plugin_Changed;
	} else {
		return Plugin_Continue;
	}
}
