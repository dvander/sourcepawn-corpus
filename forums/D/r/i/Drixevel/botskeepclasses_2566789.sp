//Pragma
#pragma semicolon 1
#pragma newdecls required

//Sourcemod Includes
#include <sourcemod>
#include <tf2_stocks>

//Globals
TFClassType botclass[MAXPLAYERS + 1] = {TFClass_Unknown, ...};

public Plugin myinfo = 
{
	name = "[TF2] Bots Keep Classes", 
	author = "Keith Warren (Sky Guardian)", 
	description = "Sets bots back to the classes they originally started with.", 
	version = "1.0.0", 
	url = "http://www.sourcemod.com/"
};

public void OnPluginStart()
{
	HookEvent("player_spawn", Event_OnPlayerSpawn);
}

public void OnClientPutInServer(int client)
{
	botclass[client] = TFClass_Unknown;
}

public void OnClientDisconnect(int client)
{
	botclass[client] = TFClass_Unknown;
}

public void Event_OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (client == 0 || !IsClientInGame(client) || !IsPlayerAlive(client) || !IsFakeClient(client))
	{
		return;
	}
	
	TFClassType class = TF2_GetPlayerClass(client);
	
	if (botclass[client] == TFClass_Unknown)
	{
		botclass[client] = class;
		return;
	}
	
	if (class != botclass[client])
	{
		TF2_SetPlayerClass(client, botclass[client], false, true);
		TF2_RegeneratePlayer(client);
	}
}