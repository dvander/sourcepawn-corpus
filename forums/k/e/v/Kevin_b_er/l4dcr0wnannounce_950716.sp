#include <sourcemod>
#include <sdktools>
 
#pragma semicolon 1
 
public Plugin:myinfo =
{
	name = "[L4D] Cr0wn Announcer",
	author = "Kevin_b_er",
	description = "Announces a cr0wn",
	version = "1.0.0.0",
	url = "http://www.brothersofchaos.com/"
};


public OnPluginStart()
{
   HookEvent("witch_killed", event_witch_killed);
}

public Action:event_witch_killed(Handle:event, const String:name[], bool:dontBroadcast)
{
new bool:witch_crowned = GetEventBool(event, "oneshot");

if( witch_crowned )
	{
	new 	   witch_killer  	= GetClientOfUserId(GetEventInt(event, "userid"));
	new String:killer_name[64];
	
	/* Filter out bad killer IDs then get the killer's name */
	if( (witch_killer != 0) && GetClientName(witch_killer, killer_name, 64) )
		{
		PrintToChatAll("%s cr0wned a witch!", killer_name);
		}
	}

return Plugin_Continue;
}

