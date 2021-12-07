/*
* 
* TrainWreck
* 
* Description:
* Adds a kill icon for the Pain Train and Homewrecker
* Pain Train shows as a train, and Homewrecker shows
* as a sawblade.
* 
* Changelog
* Apr 22, 2010 - v.1.0:
* 				[*] Initial Release
* Apr 24, 2010 - v.1.1:
* 				[+] Added Train icon for Pain Train
* 
*/

#pragma semicolon 1
#include <sourcemod>

#define PLUGIN_VERSION "1.1"

public Plugin:myinfo = 
{
	name = "TrainWreck",
	author = "Stevo.TVR",
	description = "Adds kill icons for the Pain Train and Homewrecker",
	version = PLUGIN_VERSION,
	url = "http://www.theville.org/"
}

public OnPluginStart()
{
	CreateConVar("sm_trainwreck_version", PLUGIN_VERSION, "TrainWreck plugin version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:weapon[16];
	GetEventString(event, "weapon", weapon, sizeof(weapon));
	if(StrEqual(weapon, "paintrain"))
	{
		SetEventString(event, "weapon", "vehicle");
	}
	else if(StrEqual(weapon, "sledgehammer"))
	{
		new damagebits = 65536;
		if(GetEventInt(event, "damagebits") & 1048576)
		{
			damagebits += 1048576;
		}
		SetEventInt(event, "damagebits", damagebits);
	}
	return Plugin_Continue;
}

// TOPATO