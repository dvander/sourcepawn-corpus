#pragma semicolon 1

#include <sourcemod>
#include <tf2>
#include <tf2_stocks>

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo =
{
	name = "Quickfix Fix",
	author = "Geit",
	description = "Fixes the Quickfix immunity bug",
	version = PLUGIN_VERSION,
	url = "http://geit.co.uk"
};

public OnPluginStart()
{
	CreateConVar("quickfixfix_version", PLUGIN_VERSION, "Version Information", FCVAR_REPLICATED|FCVAR_NOTIFY);
	HookEvent("teamplay_win_panel", Event_game_over);
	HookEvent("arena_win_panel", Event_game_over);
	HookEvent("pve_win_panel", Event_game_over);
}

public Action:Event_game_over(Handle:event, const String:name[], bool:dontBroadcast)
{
	for(new i=1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i) && TF2_GetPlayerClass(i) == TFClass_Medic)
		{
			new index = GetPlayerWeaponSlot(i, 1);
			if (index > 0) 
			{
				if(GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex") == 411)
				{
					SetEntPropFloat(index, Prop_Send, "m_flChargeLevel", 0.0);
				}
			}
		}
	}
}
