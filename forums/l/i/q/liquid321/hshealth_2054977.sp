#pragma semicolon 1

#include <sourcemod>

#define PLUGIN_VERSION "1.2"

public Plugin:myinfo = 
{
	name = "Headshot Reward",
	author = "MUNDA",
	description = "Gives health reward on HEADSHOT",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
}

public OnPluginStart() 
{
    HookEvent("player_death", Event_player_death);
}    

public Event_player_death(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetEventBool(event, "headshot"))
	{
   		new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
    		if (1 <= attacker <= MaxClients) // Check if is valid client
    		{
            	new health = GetClientHealth(attacker) + 30;
            	health >= 100 ? SetEntityHealth(attacker, 100) : SetEntityHealth(attacker, health);
		PrintHintText(attacker, "30 HP Awarded for HEADSHOT!");
        	}
    	}
}
