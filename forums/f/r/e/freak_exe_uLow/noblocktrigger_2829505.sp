#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.01"
#define SM "\x04[SM]\x01"

public Plugin myinfo =
{
	name = "Noblock Trigger",
	author = "Heartless",
	description = "Allows players to enable noblock on everyone in the server for x seconds",
	version = PLUGIN_VERSION,
	url = "http://www.badnetwork.net/"
};

int g_CollisionOffset;
ConVar sm_noblock_time;

public void OnPluginStart()
{
	RegConsoleCmd("sm_noblock", Command_NoBlock);
	g_CollisionOffset = FindSendPropInfo("CBaseEntity", "m_CollisionGroup");
	sm_noblock_time = CreateConVar("sm_noblock_time", "5", "Sets the noblock timer value");
	AutoExecConfig(true, "sm_noblock");
}

public Action Command_NoBlock(int client, int args)
{
	if (IsClientInGame(client) && IsPlayerAlive(client))
	{
		float Time = sm_noblock_time.FloatValue;
		PrintToChat(client, "%s Noblock enabled for %f seconds", SM, Time);	
		CreateTimer(Time, Timer_UnBlockPlayer, GetClientUserId(client));
		
		EnableNoBlock(client);
	}
	else
	{
		PrintToChat(client, "%s You must be alive to use this command", SM);
	}
	
	return Plugin_Handled;
	
}

public Action Timer_UnBlockPlayer(Handle timer, any data)
{
	int client;
	if ((client = GetClientOfUserId(data)) == 0 || !IsClientInGame(client)) {
		return Plugin_Continue;
	}

	PrintToChat(client, "%s Noblock disabled", SM);
	EnableBlock(client);
	
	return Plugin_Continue;
}

void EnableBlock(int client)
{
	// CAN NOT PASS THRU ie: Players can jump on each other
	SetEntData(client, g_CollisionOffset, 5, 4, true);
}

void EnableNoBlock(int client)
{
	// Noblock active ie: Players can walk thru each other
	SetEntData(client, g_CollisionOffset, 2, 4, true);
}