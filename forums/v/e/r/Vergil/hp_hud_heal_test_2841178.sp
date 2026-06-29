#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

new Handle:g_hHud = INVALID_HANDLE;
new Handle:g_hHudTimers[MAXPLAYERS+1] = {INVALID_HANDLE,...};

public Plugin:myinfo =
{
	name = "Numeric HUD HP",
	author = "Elmo, the Grand Defiler of Souls",
	description = "Shows numeric representation of hp to clients",
	version = "1.0",
	url = ""
};

public OnPluginStart()
{	
	g_hHud = CreateHudSynchronizer();
	LoadTranslations("common.phrases");
}

public OnClientPutInServer(client)
{
	g_hHudTimers[client] = CreateTimer(0.1, Timer_SyncHud, client, TIMER_REPEAT);
}

public OnClientDisconnect(client)
{
	if(g_hHudTimers[client]!=INVALID_HANDLE)
	{
		KillTimer(g_hHudTimers[client]);
	}
	g_hHudTimers[client] = INVALID_HANDLE;
}

public OnMapEnd()
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if(g_hHudTimers[i]!=INVALID_HANDLE)
		{
			KillTimer(g_hHudTimers[i]);
		}
		g_hHudTimers[i] = INVALID_HANDLE;
	}	
}

public Action:Timer_SyncHud(Handle:timer, any:client)
{	
	SetHudTextParams(0.386, 0.00, 0.4, 0, 255, 64, 255, 0, 0.0, 0.0, 0.0);
	ShowSyncHudText(client, g_hHud, "HP[%d]", GetClientHealth(client));
	return Plugin_Continue;
}