#pragma semicolon 1

#include <sourcemod>
//#include <sdktools>
#include <tf2_stocks>

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo =
{
	name = "[TF2] Medic Taunt Killicon",
	author = "FlaminSarge",
	description = "Replaces the Ubersaw killicon on the taunt kill with the actual taunt kill one",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/"
};

public OnPluginStart()
{
	CreateConVar("sm_medictauntkilliconfix_version", PLUGIN_VERSION, "[TF2] Medic Taunt Killicon Version", FCVAR_REPLICATED|FCVAR_NOTIFY | FCVAR_PLUGIN | FCVAR_SPONLY);
	HookEvent("player_death", player_death, EventHookMode_Pre);
}
public Action:player_death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new customkill = GetEventInt(event, "customkill");
	if (customkill == TF_CUSTOM_TAUNT_UBERSLICE)
	{
		SetEventString(event, "weapon", "taunt_medic");
		SetEventString(event, "weapon_logclassname", "taunt_medic");
	}
	return Plugin_Continue;
}