/*

*/

#pragma semicolon 1
#define PLUGIN_VERSION "1.0.0"
#include <sourcemod>
#include <autoexecconfig>	//https://github.com/Impact123/AutoExecConfig or https://forums.alliedmods.net/showthread.php?p=1862459
#include <sdkhooks>
#include <sdktools>

#pragma newdecls required

ConVar g_cDelay = null;

public Plugin myinfo =
{
	name = "TOG Weapon Stripper",
	author = "That One Guy",
	description = "Strips weapons a configurable number of seconds after a player spawns.",
	version = PLUGIN_VERSION,
	url = "http://www.togcoding.com"
}

public void OnPluginStart()
{
	AutoExecConfig_SetFile("togweaponstripper");
	AutoExecConfig_CreateConVar("tws_version", PLUGIN_VERSION, "FILENAME: Version", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	g_cDelay = AutoExecConfig_CreateConVar("tws_", "1.0", "Delay after player spawn before stripping weapons.", FCVAR_NONE, true, 0.1);
	
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
	
	HookEvent("player_spawn", Event_PlayerSpawn);
}

public Action Event_PlayerSpawn(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	int client = GetClientOfUserId(hEvent.GetInt("userid"));
	if(!IsValidClient(client))
	{
		return Plugin_Continue;
	}
	
	CreateTimer(g_cDelay.FloatValue, TimerCB_StripWeapons, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	
	return Plugin_Continue;
}

public Action TimerCB_StripWeapons(Handle hTimer, any iUserID)
{
	int client = GetClientOfUserId(iUserID);
	if(IsValidClient(client))
	{
		if(IsPlayerAlive(client))	//player can die during the timer, or disconnect
		{
			for(int i = 0; i < 5; i++)
			{
				int iWeaponEnt = GetPlayerWeaponSlot(client, i);
				if(iWeaponEnt != -1) 
				{
					RemovePlayerItem(client, iWeaponEnt);
				}
			}
		}
	}
}

bool IsValidClient(int client)
{
	if(!(1 <= client <= MaxClients) || !IsClientInGame(client))
	{
		return false;
	}
	return true;
}

/*
/////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////// CHANGE LOG //////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////
	1.0.0
		* Initial creation.
		
*/