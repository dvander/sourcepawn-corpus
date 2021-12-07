#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>

new g_maxHealth[10] = {0, 125, 125, 900, 175, 150, 300, 175, 125, 125};

public OnConfigsExecuted()
{
    for (new i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i))
        {
            SDKHook(i, SDKHook_GetMaxHealth, OnGetMaxHealth);
        }
    }
}

public OnClientPutInServer(client)
{
    SDKHook(client, SDKHook_GetMaxHealth, OnGetMaxHealth);
}

public Action:OnGetMaxHealth(client, &maxhealth)
{
    if (client > 0 && client <= MaxClients)
    {
        if (TF2_GetPlayerClass(client) == TFClass_Soldier)
        {
            maxhealth = g_maxHealth[TF2_GetPlayerClass(client)];
        }
        return Plugin_Handled;
    }
    return Plugin_Continue;
}