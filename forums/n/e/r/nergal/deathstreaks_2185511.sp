#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION			"1.0.1"
#define CLIENTS				MAXPLAYERS+1
#pragma newdecls			required

public Plugin myinfo =
{
    name = "Deathstreaks Rewarder",
    author = "Nergal/Assyrian",
    description = "Does stuff when Deathstreaks blah",
    version = PLUGIN_VERSION,
    url = "http://steamcommunity.com/groups/acvsh"
};

//cvar handles
ConVar gbEnabled = null;
//ints
int giDedstreak[CLIENTS];
int giKillstreak[CLIENTS];

public void OnPluginStart()
{
	gbEnabled = CreateConVar("sm_dsr_enabled", "1", "Dis/En-Ables Deathstreaks rewarder plugin", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	HookEvent("player_death", PlayerDeath, EventHookMode_Pre);
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsValidClient(i)) continue;
		OnClientPutInServer(i);
	}
	AutoExecConfig(true, "Deathstreaker-Config");
}
public void OnClientPutInServer(int client)
{
	giDedstreak[client] = 0;
	giKillstreak[client] = 0;
}
public void OnClientDisconnect(int client)
{
	giDedstreak[client] = 0;
	giKillstreak[client] = 0;
}
public Action PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if (!gbEnabled.BoolValue) return Plugin_Continue;
	int client = GetClientOfUserId( event.GetInt("userid") );
	int killer = GetClientOfUserId( event.GetInt("attacker") );
	if (client == killer) return Plugin_Continue;

	if (giKillstreak[client] < 1) giDedstreak[client]++;
	giKillstreak[client] = 0;

	giDedstreak[killer] = 0;
	giKillstreak[killer]++;
	return Plugin_Continue;
}
stock bool IsValidClient(int client, bool replaycheck = true)
{
	if (client <= 0 || client > MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	//if (GetEntProp(client, Prop_Send, "m_bIsCoaching")) return false;
	if (replaycheck) if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
	return true;
}
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("DSR_GetDeathstreak", Native_GetDeathstreak);
	CreateNative("DSR_SetDeathstreak", Native_SetDeathstreak);
	CreateNative("DSR_GetKillstreak", Native_GetKillstreak);
	CreateNative("DSR_SetKillstreak", Native_SetKillstreak);
	RegPluginLibrary("deathstreaks");
	return APLRes_Success;
}
public int Native_GetDeathstreak(Handle plugin, int numParams)
{
	return giDedstreak[GetNativeCell(1)];
}
public int Native_SetDeathstreak(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if (IsValidClient(client)) giDedstreak[client] = GetNativeCell(2);
}
public int Native_GetKillstreak(Handle plugin, int numParams)
{
	return giKillstreak[GetNativeCell(1)];
}
public int Native_SetKillstreak(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if (IsValidClient(client)) giKillstreak[client] = GetNativeCell(2);
}
