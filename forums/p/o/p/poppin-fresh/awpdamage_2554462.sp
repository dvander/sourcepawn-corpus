#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>

ConVar g_cvDamageModifier = null;

public void OnPluginStart()
{
    g_cvDamageModifier = CreateConVar("sm_awp_damage", "0.8", "AWP damage modifier value.");
    AutoExecConfig();
    
    // Allows reloading
    for (int i = 1; i <= MaxClients; i++) {
        if (IsClientInGame(i))
            SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
    }
}

public void OnClientPutInServer(int client)
{
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public void OnClientDisconnect(int client)
{
    SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
    if (!IsValidClient(victim) || !IsValidClient(attacker) || !IsValidEntity(weapon))
        return Plugin_Continue;
    
    char buffer[32];
    GetEntityClassname(weapon, buffer, sizeof(buffer));
    
    if (StrEqual("weapon_awp", buffer)) {
        damage *= GetConVarFloat(g_cvDamageModifier);
        return Plugin_Changed;
    }
    
    return Plugin_Continue;
}

bool IsValidClient(int client)
{
    return 0 < client <= MaxClients && IsClientInGame(client);
}