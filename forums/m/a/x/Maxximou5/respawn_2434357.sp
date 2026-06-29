#include <cstrike>
#include <sdktools>
#include <sdkhooks>

bool g_bSpawned[MAXPLAYERS + 1] = {false, ...};

#define PLUGIN_VERSION          "1.0.0"
#define PLUGIN_NAME             "Respawn For Ranks"
#define PLUGIN_AUTHOR           "Maxximou5"
#define PLUGIN_DESCRIPTION      "Some plugins require a plugin to fix a plugin"
#define PLUGIN_URL              "http://maxximou5.com/"

public Plugin myinfo =
{
    name                        = PLUGIN_NAME,
    author                      = PLUGIN_AUTHOR,
    description                 = PLUGIN_DESCRIPTION,
    version                     = PLUGIN_VERSION,
    url                         = PLUGIN_URL
}

public void OnPluginStart()
{
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_death", Event_PlayerDeath);
}

public void OnClientPostAdminCheck(int client)
{
	if (IsValidClient(client))
	{
		g_bSpawned[client] = false;
	}
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (IsValidClient(client) && (g_bSpawned[client] == false) && (GetClientTeam(client) != CS_TEAM_SPECTATOR))
	{
		CreateTimer(0.5, Timer_Suicide, client);
	}
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (IsValidClient(client) && (g_bSpawned[client] == false))
	{
		CreateTimer(0.5, Timer_Respawn, client);
		g_bSpawned[client] = true;
	}
}

public Action Timer_Suicide(Handle timer, any client)
{
	if (IsValidClient(client))
	{
		ForcePlayerSuicide(client);
	}
}

public Action Timer_Respawn(Handle timer, any client)
{
	if (IsValidClient(client))
	{
		CS_RespawnPlayer(client);
	}
}

stock bool IsValidClient(int client)
{
    if (!(0 < client <= MaxClients)) return false;
    if (!IsClientInGame(client)) return false;
    if (IsFakeClient(client)) return false;
    return true;
}
