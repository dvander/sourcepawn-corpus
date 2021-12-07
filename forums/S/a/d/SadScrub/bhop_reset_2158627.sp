#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

public Plugin:myinfo =
{
    name = "B-Hop Spawn Speed Reset"
};


public OnPluginStart()
{
    HookEvent("round_freeze_end", Event_FreezeEnd, EventHookMode_Pre);
}

public Action:Event_FreezeEnd(Handle:event, String:name[], bool:dontBroadcast)
{
    for (new i = 1; i <= MaxClients; i++)
    {
        if ( IsClientInGame(i) && IsPlayerAlive(i) )
            SetEntProp(i, Prop_Send, "m_flSpeed", 0);
    }
    return Plugin_Continue;
}