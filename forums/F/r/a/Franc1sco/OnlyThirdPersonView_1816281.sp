#include <sourcemod>
#include <sdktools>

public OnPluginStart()
{
    HookEvent("player_spawn", OnPlayerSpawn);
}


public Action:OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
        new client = GetClientOfUserId(GetEventInt(event, "userid"));
        SetThirdPersonView(client);
}

SetThirdPersonView(client)
{
        SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", 0); 
        SetEntProp(client, Prop_Send, "m_iObserverMode", 1);
        SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 0);
        SetEntProp(client, Prop_Send, "m_iFOV", 120);
}  