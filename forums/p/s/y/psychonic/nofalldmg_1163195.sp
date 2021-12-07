#include <sourcemod>
#include <sdkhooks>

public OnPluginStart()
{
    for (new i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i))
        {
            SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
        }
    }
}

public OnClientPutInServer(client)
{
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
    if ((damagetype & DMG_FALL) == DMG_FALL)
    {
        return Plugin_Handled;
    }
    return Plugin_Continue;
}  