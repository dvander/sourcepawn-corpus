#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

ConVar convar_TeammatesAreEnemies;

public Plugin myinfo = 
{
	name = "[CSGO] free for all command", 
	author = "Drixevel", 
	description = "A command which just executes free for all.", 
	version = "1.0.0", 
	url = "https://drixevel.dev/"
};

public void OnPluginStart()
{
	convar_TeammatesAreEnemies = FindConVar("mp_teammates_are_enemies");
	RegAdminCmd("sm_ffa", Command_FreeForAll, ADMFLAG_GENERIC, "Toggles free for all on/off.");
}

public Action Command_FreeForAll(int client, int args)
{
	convar_TeammatesAreEnemies.BoolValue = !convar_TeammatesAreEnemies.BoolValue;
	PrintToChat(client, "Free for All: %s", convar_TeammatesAreEnemies.BoolValue ? "Enabled" : "Disabled");
	return Plugin_Handled;
}