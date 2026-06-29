#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>

#define PLUGIN_VERSION "1.0"
#define CVAR_FLAGS FCVAR_NOTIFY

public Plugin myinfo =
{
	name = "Player Spawn God",
	author = "DenisPukin, BloodyBlade",
	version = PLUGIN_VERSION,
	url = "hlmod.ru/members/denispukin.85089/"
}

ConVar hPluginEnable, hGodTime;
bool bHooked = false;
float fTime = 0.0;
Handle God_Timer[MAXPLAYERS + 1] = {null, ...};

public void OnPluginStart()
{
	CreateConVar("player_spawn_god_version", PLUGIN_VERSION, "Player Spawn God plugin version", CVAR_FLAGS|FCVAR_DONTRECORD);
	hPluginEnable = CreateConVar("player_spawn_god_enable", "1", "Enable/Disable plugin", CVAR_FLAGS, true, 0.0, true, 1.0);
	hGodTime = CreateConVar("player_spawn_god_godtime", "5.0", "How many seconds will the player be immortal?", CVAR_FLAGS, true, 0.0, true, 60.0);
	AutoExecConfig(true, "PlayerSpawnGod");
	hPluginEnable.AddChangeHook(OnConvarEnableChanged);
	hGodTime.AddChangeHook(OnConVarTimeChanged);
}

public void OnConfigsExecuted()
{
	IsAllowed();
}

void OnConvarEnableChanged(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	IsAllowed();
}

void OnConVarTimeChanged(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	fTime = hGodTime.FloatValue;
}

void IsAllowed()
{
	bool bPluginOn = hPluginEnable.BoolValue;
	if(!bHooked && bPluginOn)
	{
		bHooked = true;
		OnConVarTimeChanged(null, "", "");
		HookEvent("player_spawn", Event_PlayerSpawn);
	}
	else if(bHooked && !bPluginOn)
	{
		bHooked = false;
		UnhookEvent("player_spawn", Event_PlayerSpawn);
	}
}

void Event_PlayerSpawn(Event hEvent, const char[] sEvName, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(hEvent.GetInt("userid")); 
	if(IsValidClient(iClient) && IsPlayerAlive(iClient))
	{
		if(God_Timer[iClient] == null)
		{
			SetEntProp(iClient, Prop_Data, "m_takedamage", 0, 1);
			God_Timer[iClient] = CreateTimer(fTime, Timer_God, GetClientUserId(iClient));
		}
	}
}

Action Timer_God(Handle hTimer, any UserId)
{
	if(bHooked)
	{
		int iClient = GetClientOfUserId(UserId);
		if(IsValidClient(iClient))
		{
			SetEntProp(iClient, Prop_Data, "m_takedamage", 2, 1);
			God_Timer[iClient] = null; 
		}
	}
	return Plugin_Stop;
}

stock bool IsValidClient(int client)
{
	return client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && GetClientTeam(client) == 2;
}
