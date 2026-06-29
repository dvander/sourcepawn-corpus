#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0"


public Plugin:myinfo =
{
	name = "SM Deathrun Attacker",
	author = "Franc1sco Steam: franug",
	description = "Deathrun Ts attacker",
	version = PLUGIN_VERSION,
	url = "www.servers-cfg.foroactivo.com"
};

public OnPluginStart()
{

	CreateConVar("sm_deathrun_attacker", PLUGIN_VERSION, "version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	
	HookEvent("player_death", event_Death, EventHookMode_Pre);

}


public Action:event_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
 
 	new client = GetClientOfUserId(GetEventInt(event, "userid"));


        if (!IsClientInGame(client))
            return;

        if (GetClientTeam(client) != 3)
            return ;

        new count = 0; 

        for(new i = 1; i <= MaxClients; i++) 
        { 
            if(IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i)) 
            { 
                count++; 
            } 
        } 

        if(count != 1)
            return;  // only for 1 ts supported


        new ts_attacker;

	for (new i = 1; i <= MaxClients; i++) 
	{
		if(IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i)) 
		{

			ts_attacker = i;

		}
	}
        SetEventInt(event, "attacker", GetClientUserId(ts_attacker));

}