#include <sourcemod> 
#include <sdktools> 

new USE_ACCEPT_ENTITY        =      1;  

public OnPluginStart()
{
    HookEvent("player_death", Event_PlayerDeath);
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));

    if (client < 1 || client > MaxClients || !IsClientInGame(client) || GetClientTeam(client) != 3) 
    {
        return;
    }

    new body = GetEntPropEnt(client, Prop_Send, "m_hRagdoll"); 

    if (body > 0) 
    {
        if (USE_ACCEPT_ENTITY == 1) 
        {
            AcceptEntityInput(body, "kill"); 
        }
        else RemoveEdict(body);
    }
} 