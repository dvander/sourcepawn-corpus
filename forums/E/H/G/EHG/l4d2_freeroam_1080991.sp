#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION			"1.1"

public Plugin:myinfo =
{
	name = "L4D2 Take a break Free Roam",
	author = "EHG",
	description = "L4D2 Take a break Free Roam",
	version = PLUGIN_VERSION,
	url = ""
};


public OnPluginStart()
{
	CreateConVar("l4d2_takeabreak_freeroam_version", PLUGIN_VERSION, "L4D2 Enable Spectator Free Roam Version", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_DONTRECORD | FCVAR_NOTIFY);
	RegConsoleCmd("sm_freeroam", Command_Freeroam);
	HookEvent("player_team", Event_PlayerTeam);
}


public Action:Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (GetEventInt(event,"team") == 1)
	{
		PrintToChat(client, "Type /freeroam in chat or sm_freeroam in console to enter the free roam camera");
	}
}



public Action:Command_Freeroam(client, args)
{
	if (GetClientTeam(client) == 1)
	{
		SetEntProp(client, Prop_Data, "m_iObserverMode", 6);
		return Plugin_Handled;
	}
	return Plugin_Handled;
}




