#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>

public Plugin myinfo =
{
	name = "Ragdoll keeper",
	author = "bklol",
	description = "keep player bodies after death.",
};

public void OnPluginStart()
{
	HookEvent("player_team", Player_Notifications, EventHookMode_Pre);
	HookEvent("player_death", Player_Notifications, EventHookMode_Pre);
}

public Action Player_Notifications(Handle event,const char[] name,bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsValidEntity(client))
	{
		if (GetEntPropEnt(client, Prop_Send, "m_hRagdoll") != INVALID_ENT_REFERENCE)
		{
			SetEntPropEnt(client, Prop_Send , "m_hRagdoll", -1);
		}
	}
	return Plugin_Continue;
}