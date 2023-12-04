#pragma semicolon 1
#pragma newdecls required

#include <cstrike>
#include <sdktools_functions>

static char
	PL_NAME[]	= "[CSGO] FragTag",
	PL_VER[]	= "1.0.1_18.08.2022",

	TAG[] = "<%i>";	// Clantag should contain only one format specifier: '%i'

bool
	bLate;
int
	iOffset,
	iManager,
	kills[MAXPLAYERS+1];

public Plugin myinfo =
{
	name		= PL_NAME,
	version		= PL_VER,
	description	= "Shows the number of frags in the clantag",
	author		= "Grey83",
	url			= "https://steamcommunity.com/groups/grey83ds"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if(GetEngineVersion() != Engine_CSGO)
	{
		FormatEx(error, sizeof(err_max), "Plugin for CS:GO only!");
		return APLRes_Failure;
	}

	if((iOffset= FindSendPropInfo("CCSPlayerResource", "m_iKills")) < 1)
	{
		FormatEx(error, sizeof(err_max), "Unable to find offset 'CCSPlayerResource::m_iKills'!");
		return APLRes_Failure;
	}

	bLate = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("sm_fragtag_version", PL_VER, PL_NAME, FCVAR_DONTRECORD|FCVAR_NOTIFY|FCVAR_SPONLY);

	HookEvent("player_death", Event_Player);
}

public void OnMapStart()
{
	iManager = -1;
	if(!GetManager() || !bLate)
		return;

	bLate = false;
	GetEntDataArray(iManager, iOffset, kills, sizeof(kills));
	for(int i = 1; i <= MaxClients; i++) if(IsPlayerValid(i)) SetPlayerClanTag(i);
}

public void OnClientSettingsChanged(int client)
{
	if(IsPlayerValid(client)) Timer_Death(null, GetClientUserId(client));
}

public void Event_Player(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("attacker"));
	if(client && client != GetClientOfUserId(event.GetInt("userid")) && IsPlayerValid(client))
		CreateTimer(0.1, Timer_Death, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_Death(Handle timer, int client)
{
	if(!GetManager() || !(client = GetClientOfUserId(client)))
		return Plugin_Stop;

	kills[client] = GetEntProp(iManager, Prop_Send, "m_iKills", 2, client);
	SetPlayerClanTag(client);

	return Plugin_Stop;
}

stock void SetPlayerClanTag(int client, bool pre = false)
{
	static char buffer[8];
	FormatEx(buffer, sizeof(buffer), TAG, kills[client]);
	CS_SetClientClanTag(client, buffer);
}

stock bool GetManager()
{
	if(iManager == -1 && (iManager = FindEntityByClassname(-1, "cs_player_manager")) == -1)
	{
		LogError("Unable to find entity 'cs_player_manager'!");
		return false;
	}

	return true;
}

stock bool IsPlayerValid(int client)
{
	return IsClientInGame(client) && !IsFakeClient(client);
}