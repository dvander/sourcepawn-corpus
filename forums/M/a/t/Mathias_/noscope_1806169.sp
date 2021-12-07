#include <sourcemod>

public OnPluginStart()
{
    HookEvent("weapon_zoom", OnPlayerZoom, EventHookMode_Pre);
}

public Action:OnPlayerZoom(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    
    SetEntProp(client, Prop_Data, "m_iFOV", 0);
}