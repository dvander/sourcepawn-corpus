#include <sourcemod>
#include <sdkhooks>

new bool:g_bFullyConnected[MAXPLAYERS+1] = {false,...};
new g_bConnectNetMsgCount[MAXPLAYERS+1] = 0;

public Plugin:myinfo =
{
	name = "NullWaveCrashFix",
	author = "backwards",
	description = "Exploit Fix",
	version = SOURCEMOD_VERSION,
	url = "http://www.steamcommunity.com/id/mypassword"
}

public OnPluginStart()
{
	HookEvent("player_connect_full", Event_PlayerConnectFull, EventHookMode_Pre);
}

public OnMapStart()
{
	for(new i=1;i<=MaxClients;i++)
	{
		g_bFullyConnected[i] = false;
		g_bConnectNetMsgCount[i] = 0;
	}
}
public OnClientDisconnect(client)
{
	g_bFullyConnected[client] = false;
	g_bConnectNetMsgCount[client] = 0;
}

public Action Event_PlayerConnectFull(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!IsValidClient(client))
		return Plugin_Continue;
	
	g_bConnectNetMsgCount[client]++;
	if(g_bConnectNetMsgCount[client] > 5)
	{
		if(!IsClientInKickQueue(client))
			KickClient(client, "ServerCrashExploitAttempt");
	}
		
	if(g_bFullyConnected[client])
	{
		SetEventBroadcast(event, true);
		return Plugin_Changed;
	}
	else
		g_bFullyConnected[client] = true;
		
	return Plugin_Continue;
}

bool IsValidClient(int client)
{
    if (!(1 <= client <= MaxClients) || !IsClientInGame(client) || IsClientSourceTV(client) || IsClientReplay(client))
        return false;

    return true;
}