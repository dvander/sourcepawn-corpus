#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR ""
#define PLUGIN_VERSION "0.00"

#include <sourcemod>
#include <sdktools>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "",
	author = PLUGIN_AUTHOR,
	description = "",
	version = PLUGIN_VERSION,
	url = ""
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_idle", Command_Idle);
}
public Action Command_Idle(int client, int args)
{
	if (IsClientInGame(client) && !IsFakeClient(client))
	{
		CreateTimer(15.0, Idle, client);
		PrintHintText(client, "[RegionZ] \n After 15 seconds you will be afk.");
	}
}
public Action Idle(Handle timer, int client)
{
	if (IsClientInGame(client) && !IsFakeClient(client))
	{
		if (GetClientTeam(client) != 1)
		{
			if (IsPlayerAlive(client))
			{
				ChangeClientTeam(client, 1);
				ForcePlayerSuicide(client);
				PrintToChatAll("\x04[\x05AFK Manager\x04]\x01 Player \x04'%N'\x01 has moved to Spectator team.", client);
				PrintToServer("\x04[\x05AFK Manager\x04]\x01 Player '%N' has moved to Spectator team.", client);
			}
			else
			{
				PrintToChat(client, "\x04[\x05AFK Manager\x04]\x01 You cannot use the !idle command while dead.", client);
			}
		}        
	}
	return Plugin_Continue;
}