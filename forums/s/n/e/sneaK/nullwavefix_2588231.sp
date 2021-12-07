#include <sourcemod>
#include <sdkhooks>

#undef REQUIRE_PLUGIN
#include <sourcebans>

bool g_bFullyConnected[MAXPLAYERS+1] = {false,...};
int g_bConnectNetMsgCount[MAXPLAYERS+1] = 0;

public Plugin myinfo =
{
	name = "NullWaveCrashFix",
	author = "backwards",
	description = "Exploit Fix",
	version = SOURCEMOD_VERSION,
	url = "http://www.steamcommunity.com/id/mypassword"
}

public void OnPluginStart()
{
	HookEvent("player_connect_full", Event_PlayerConnectFull, EventHookMode_Pre);
}

public void OnMapStart()
{
	for(new i=1;i<=MaxClients;i++)
	{
		g_bFullyConnected[i] = false;
		g_bConnectNetMsgCount[i] = 0;
	}
}
public void OnClientDisconnect(int client)
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
			SourceBans_BanPlayer(0, client, 0, "Attempted server crash exploit");
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