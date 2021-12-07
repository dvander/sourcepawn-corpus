#include <sourcemod>
#include <sdktools>


#pragma semicolon 1

#define PLUGIN_VERSION "1.0 by Franug"

new g_iAccount = -1;

public Plugin:myinfo = {
	name = "SM Lose survivors",
	author = "Franc1sco steam: franug",
	description = "para castigar los sobrevivientes del equipo perdedor.",
	version = PLUGIN_VERSION,
	url = "http://www.servers-cfg.foroactivo.com"
};

public OnPluginStart() 
{
	CreateConVar("sm_losesurvivors_version", PLUGIN_VERSION, "version.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	HookEvent("round_end", EventRoundEnd);

	g_iAccount = FindSendPropOffs("CCSPlayer", "m_iAccount");
}



public EventRoundEnd(Handle:event, const String:name[], bool:dontBroadcast) 
{
		new ev_winner = GetEventInt(event, "winner");
		if(ev_winner == 2) 
		{
			for (new i = 1; i <= MaxClients; i++) 
			{		
				if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 3) 
				{
					castigar(i);
				}
			}

		}
		else if(ev_winner == 3) 
		{
			for (new i = 1; i <= MaxClients; i++) 
			{		
				if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2) 
				{
					castigar(i);
				}
			}

		}
}

castigar(client)
{
    new iEnt;
    for (new i = 0; i <= 4; i++)
    {
        while ((iEnt = GetPlayerWeaponSlot(client, i)) != -1)
        {
            RemovePlayerItem(client, iEnt);
            RemoveEdict(iEnt);
        }
    }
    SetEntData(client, g_iAccount, 0);

}