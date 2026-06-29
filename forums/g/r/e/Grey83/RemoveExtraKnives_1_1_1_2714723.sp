#pragma semicolon 1
#pragma newdecls required

#include <sdktools_entinput>
#include <sdktools_functions>

public Plugin myinfo = 
{
	name		= "RemoveExtraKnives",
	version		= "1.1.1",
	description	= "Auto strip extra knives on round start from all players",
	author		= "SheriF (rewritten by Grey83)",
	url			= "https://steamcommunity.com/groups/grey83ds"
}

public void OnPluginStart()
{
	HookEvent("round_start", Event_Start, EventHookMode_PostNoCopy);	// "round_freeze_end"
}

public void Event_Start(Event event, const char[] name, bool dontBroadcast)
{
	for(int i = 1, wpn; i <= MaxClients; i++)
		if(IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) > 1 && IsPlayerAlive(i))
		{
			while((wpn = GetPlayerWeaponSlot(i, 2)) != -1)
				if(RemovePlayerItem(i, wpn)) AcceptEntityInput(wpn, "Kill");
			GivePlayerItem(i, "weapon_knife");
		}
}