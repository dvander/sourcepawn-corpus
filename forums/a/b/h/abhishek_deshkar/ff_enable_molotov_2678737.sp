#include <sourcemod>
#include <sdkhooks>

public Plugin myinfo = {
    name = "Enable FF Molotov/Inc only Damage",
    author = "||ECS|| nUy & Ilusion9",
    description = "This plugin blocks Friendlyfire but enables incendiary/molotove damage to teammates.",
    version = "1.6",
    url = "https://www.facebook.com/abhi.pro"
};

ConVar g_Cvar_FriendlyFire;

public void OnPluginStart()
{
    g_Cvar_FriendlyFire = FindConVar("mp_friendlyfire");
}

public void OnConfigsExecured()
{
    g_Cvar_FriendlyFire.SetInt(1);
}

public OnClientPutInServer(client)
{
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
    if (attacker < 1 || attacker > MaxClients || attacker == victim || attacker == inflictor || weapon < 1)
    {
        return Plugin_Continue;
    }
    
    if (GetClientTeam(victim) == GetClientTeam(attacker))
    {
        return Plugin_Handled;
    }
    
    return Plugin_Continue;
}