#pragma semicolon 1
#define PLUGIN_VERSION "1.0"

#include <sourcemod>
#include <autoexecconfig>	//https://github.com/Impact123/AutoExecConfig or https://forums.alliedmods.net/showthread.php?p=1862459
#include <store>

new	Handle:g_hNumCredits = INVALID_HANDLE;
new g_iNumCredits;

public Plugin:myinfo =
{
	name = "Deathrun Terrorist Kill Credits",
	author = "That One Guy",
	description = "Deathrun Terrorist kill credits for Zephs store",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/member.php?u=188078"
}

public OnPluginStart()
{
	AutoExecConfig_SetFile("drkillcreds");
	AutoExecConfig_CreateConVar("drkc_version", PLUGIN_VERSION, "Deathrun Terrorist Kill Credits: Version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	g_hNumCredits = AutoExecConfig_CreateConVar("drkc_numcredits", "10", "Number of credits to give CTs upon killing a Terrorist (0 = disabled).", FCVAR_NONE, true, 0.0);
	HookConVarChange(g_hNumCredits, OnCVarChange);
	g_iNumCredits = GetConVarInt(g_hNumCredits);
	
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
	
	HookEvent("player_death", EventPlayerDeath, EventHookMode_Post);
}

public EventPlayerDeath(Handle:hEvent, const String:sName[], bool:bDontBroadcast)
{
	if(!g_iNumCredits)
	{
		return;
	}
	
	new iVictim = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	new iAttacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
	
	if(IsValidClient(iVictim) && IsValidClient(iAttacker))
	{
		if((GetClientTeam(iVictim) == 2) && (GetClientTeam(iAttacker) == 3))
		{
			Store_SetClientCredits(iAttacker, Store_GetClientCredits(iAttacker) + g_iNumCredits);
		}
	}
}


public OnCVarChange(Handle:hCVar, const String:sOldValue[], const String:sNewValue[])
{
	if(hCVar == g_hNumCredits)
	{
		g_iNumCredits = StringToInt(sNewValue);
	}
}

bool:IsValidClient(client, bool:bAllowBots = false, bool:bAllowDead = true)
{
	if(!(1 <= client <= MaxClients) || !IsClientInGame(client) || (IsFakeClient(client) && !bAllowBots) || IsClientSourceTV(client) || IsClientReplay(client) || (!IsPlayerAlive(client) && !bAllowDead))
	{
		return false;
	}
	return true;
}

/*
CHANGELOG:
	1.0
		- Plugin made.
*/