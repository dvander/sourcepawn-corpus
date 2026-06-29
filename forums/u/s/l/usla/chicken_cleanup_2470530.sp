#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

public OnPluginStart()
{
    CreateTimer(5.0, Timer_RemoveFlashbangs, _, TIMER_REPEAT);
}

public Action:Timer_RemoveFlashbangs(Handle:timer, any:data)
{
    new iMaxEnts = GetMaxEntities();
    decl String:sClassName[64];
    for(new i=MaxClients;i<iMaxEnts;i++)
    {
        if(IsValidEntity(i) && 
           IsValidEdict(i) && 
           GetEdictClassname(i, sClassName, sizeof(sClassName)) &&
           StrEqual(sClassName, "chicken") &&
           GetEntPropEnt(i, Prop_Send, "m_hOwnerEntity") == -1)
        {
            RemoveEdict(i);
        }
    }
}  