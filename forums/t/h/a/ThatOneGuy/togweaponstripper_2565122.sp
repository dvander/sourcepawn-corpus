/*

*/

#pragma semicolon 1
#define PLUGIN_VERSION "1.1.0"
#include <sourcemod>
#include <autoexecconfig>	//https://github.com/Impact123/AutoExecConfig or https://forums.alliedmods.net/showthread.php?p=1862459
#include <sdkhooks>
#include <sdktools>
#include <cstrike>

#pragma newdecls required

ConVar g_cSpawnDelay = null;
ConVar g_cGroundWeaponsDelay = null;
ConVar g_cRemoveDrops = null;

public Plugin myinfo =
{
	name = "TOG Weapon Stripper",
	author = "That One Guy",
	description = "Removes weapons after several optional events: Player spawn weapons, dropped weapons, round start weapons.",
	version = PLUGIN_VERSION,
	url = "http://www.togcoding.com"
}

public void OnPluginStart()
{
	AutoExecConfig_SetFile("togweaponstripper");
	AutoExecConfig_CreateConVar("tws_version", PLUGIN_VERSION, "TOG Weapon Stripper: Version", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	g_cSpawnDelay = AutoExecConfig_CreateConVar("tws_delay_spawn", "0.5", "Delay after player spawn before stripping weapons (0 = disabled).", FCVAR_NONE, true, 0.0);
	
	g_cGroundWeaponsDelay = AutoExecConfig_CreateConVar("tws_delay_ground", "1.0", "Delay after round start before removing all weapons on the ground (0 = disabled).", FCVAR_NONE, true, 0.0);
	
	g_cRemoveDrops = AutoExecConfig_CreateConVar("tws_delay_drops", "1.0", "Delay after weapon drops before removing weapon (0 = disabled).", FCVAR_NONE, true, 0.0);
	
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
	
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("round_start", Event_RoundStart);
}

public void OnMapStart()
{
	if(g_cGroundWeaponsDelay.FloatValue)
	{
		CreateTimer(g_cGroundWeaponsDelay.FloatValue, TimerCB_CleanMapWeapons, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action Event_RoundStart(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	if(g_cGroundWeaponsDelay.FloatValue)
	{
		CreateTimer(g_cGroundWeaponsDelay.FloatValue, TimerCB_CleanMapWeapons, _, TIMER_FLAG_NO_MAPCHANGE);
	}
	return Plugin_Continue;
}

public Action TimerCB_CleanMapWeapons(Handle hTimer)
{
	for(int i = MaxClients + 1; i < 2048; ++i)
	{
		char sClassName[PLATFORM_MAX_PATH];
		if(IsValidEntity(i) && IsValidEdict(i))
		{
			GetEntityClassname(i, sClassName, sizeof(sClassName));
			if(StrContains(sClassName, "weapon_", false) != -1)
			{
				AcceptEntityInput(i, "Kill");
			}
		}
	}
}

public Action CS_OnCSWeaponDrop(int client, int iWeapon)
{
	if(g_cRemoveDrops.FloatValue)
	{
		CreateTimer(g_cRemoveDrops.FloatValue, TimerCB_RemoveEnt, EntIndexToEntRef(iWeapon), TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action TimerCB_RemoveEnt(Handle hTimer, any iEntRef)
{
	int iWeapon = EntRefToEntIndex(iEntRef);
	if(IsValidEntity(iWeapon) && IsValidEdict(iWeapon))
	{
		AcceptEntityInput(iWeapon, "Kill");
	}
}

public Action Event_PlayerSpawn(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	int client = GetClientOfUserId(hEvent.GetInt("userid"));
	if(!IsValidClient(client))
	{
		return Plugin_Continue;
	}
	
	CreateTimer(g_cSpawnDelay.FloatValue, TimerCB_StripWeapons, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	
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
	1.1.0
		* Added removal of map weapons (optional), removal of weapons after drop (optional).
		* Edited spawn weapon removal to be optional.
*/