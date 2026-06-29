#pragma semicolon 1

// ====[ INCLUDES ]============================================================
#include <sourcemod>

// ====[ DEFINES ]=============================================================
#define	PLUGIN_VERSION			"1.3"
#define	dDeaths					(1 << 0)
#define	dKills					(1 << 1)

// ====[ HANDLES | CVARS ]=====================================================
new Handle:cvarEnabled;

// ====[ VARIABLES ]===========================================================
new g_iEnabled;

public Plugin:myinfo =
{
	name = "Hide Bots in Kill Feed",
	author = "ReFlexPoison",
	description = "Disables advertisements of bot deaths and/or kills in the kill feed",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1684156"
}

public OnPluginStart()
{
	CreateConVar("sm_botfeed_version", PLUGIN_VERSION, "Hide Bots in Kill Feed Version", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_NOTIFY | FCVAR_REPLICATED | FCVAR_DONTRECORD);

	cvarEnabled = CreateConVar("sm_botfeed_enabled", "3", "Enable Hide Bots in Kill Feed (Add up values)\n0 = Disabled\n1 = Deaths\n2 = Kills", FCVAR_NONE, true, 0.0, true, 3.0);
	g_iEnabled = GetConVarInt(cvarEnabled);

	HookConVarChange(cvarEnabled, CVarChange);

	HookEvent("player_death", OnPlayerDeath, EventHookMode_Pre);
}

public CVarChange(Handle:hConvar, const String:strOldVal[], const String:strNewVal[])
{
	g_iEnabled = GetConVarInt(cvarEnabled);
}

public Action:OnPlayerDeath(Handle:hEvent, const String:strName[], bool:bBroadcast)
{
	if(g_iEnabled <= 0)
		return Plugin_Continue;

	if(g_iEnabled & dDeaths)
	{
		new iVictim = GetClientOfUserId(GetEventInt(hEvent, "userid"));
		if(IsValidClient(iVictim) && IsFakeClient(iVictim))
			SetEventBroadcast(hEvent, true);
	}

	if(g_iEnabled & dKills)
	{
		new iAttacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
		if(IsValidClient(iAttacker) && IsFakeClient(iAttacker))
			SetEventBroadcast(hEvent, true);
	}
	return Plugin_Continue;
}

// ====[ STOCKS ]==============================================================
stock bool:IsValidClient(iClient, bool:bReplay = true)
{
	if(iClient <= 0 || iClient > MaxClients || !IsClientInGame(iClient))
		return false;
	if(bReplay && (IsClientSourceTV(iClient) || IsClientReplay(iClient)))
		return false;
	return true;
}