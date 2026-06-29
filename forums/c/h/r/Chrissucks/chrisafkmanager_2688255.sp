#include <sourcemod> 
#include <cstrike>
#include <clientprefs>
#include <sdktools>


#define PLUGIN_VERSION "1.0.1"

bool stepped[320];

public Plugin:myinfo =
{
	name = "Chris's simple afk manager",
	author = "Chrissucks",
	description = "Kicks afk players with no added bloat",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/member.php?u=298577"
}

public OnPluginStart()
{
	HookEvent("round_poststart", event_round_poststart) // reset stepped
	HookEvent("player_footstep", event_player_footstep) // set stepped if player has caused a footstep
	HookEvent("buytime_ended", event_buytime_ended) // when buytime ends move players that haven't moved
}

public Action:event_round_poststart(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	stepped[client] = false;
	return Plugin_Continue;
}


public Action:event_player_footstep(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	stepped[client] = true;
	return Plugin_Continue;
}

public Action:event_buytime_ended (Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:player_name[64];
	PrintToServer("Attempting to move AFK players");
	for(new i=1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i)) 
		{
			if ( !stepped[i] && IsPlayerAlive(i) && GetClientTeam(i) > 1 && !IsFakeClient(i) && !IsClientSourceTV(i) )
			{
				ChangeClientTeam(i, 1);
				GetClientName(i, player_name, sizeof(player_name));
				PrintToServer("moved %s to spectator for being afk ", player_name);
			}
		}
		
	}
	return Plugin_Continue;
}
