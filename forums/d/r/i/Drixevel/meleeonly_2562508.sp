//Pragma
#pragma semicolon 1
#pragma newdecls required

//Sourcemod Includes
#include <sourcemod>
#include <tf2_stocks>

public Plugin myinfo =
{
	name = "Melee Only For Team",
	author = "Keith Warren (Drixevel)",
	description = "Melee only for one team.",
	version = "1.0.0",
	url = "http://www.drixevel.com/"
};

public void OnPluginStart()
{
	HookEvent("player_spawn", Event_OnPlayerSpawn);
}

public void Event_OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (client > 0 && IsClientInGame(client) && IsPlayerAlive(client) && TF2_GetClientTeam(client) == TFTeam_Red)
	{
		TF2_AddCondition(client, TFCond_RestrictToMelee, TFCondDuration_Infinite);
	}
}

public void TF2_OnConditionAdded(int client, TFCond condition)
{
	if (condition == TFCond_RestrictToMelee && TF2_GetClientTeam(client) == TFTeam_Red)
	{
		int melee = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
		
		if (IsValidEntity(melee))
		{
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", melee);
		}
	}
}

public void TF2_OnConditionRemoved(int client, TFCond condition)
{
	if (condition == TFCond_RestrictToMelee && TF2_GetClientTeam(client) == TFTeam_Red)
	{
		TF2_AddCondition(client, TFCond_RestrictToMelee, TFCondDuration_Infinite);
	}
}