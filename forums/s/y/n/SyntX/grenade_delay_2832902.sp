#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#pragma newdecls required

#define AMMO_HEGRENADE 11

Handle g_hDurationGrenade = INVALID_HANDLE;
float g_fDurationGrenade;

public Plugin myinfo =
{
	name = "Grenades Delay",
	author = "+SyntX",
	description = "Bla bla",
	version = "1.1",
	url = "https://steamcommunity.com/id/SyntX34"
}

public void OnPluginStart()
{
    g_hDurationGrenade = CreateConVar("grenades_grenade_length", "5.0", "The number of seconds it takes before a HE Grenade will explode. (0.0 = Default)", FCVAR_NONE, true, 0.0);
    
    HookConVarChange(g_hDurationGrenade, OnSettingsChange);

    g_fDurationGrenade = GetConVarFloat(g_hDurationGrenade);

    AutoExecConfig(true, "grenade_delay");
}

public void OnSettingsChange(Handle cvar, const char [] oldvalue, const char [] newvalue)
{
    if(cvar == g_hDurationGrenade)
    {
        g_fDurationGrenade = StringToFloat(newvalue);
    }
}

public void OnEntityCreated(int entity, const char [] classname)
{
    if (StrEqual(classname, "env_particlesmokegrenade", false))
    {
        AcceptEntityInput(entity, "Kill");
    }
    else if (StrEqual(classname, "hegrenade_projectile", false))
    {
        int iReference = EntIndexToEntRef(entity);
        CreateTimer(0.1, Timer_OnGrenadeCreated, iReference);
        
        if (g_fDurationGrenade)
        {
            CreateTimer(g_fDurationGrenade, Timer_OnStartDetonate, iReference);
        }
    }
}

public Action Timer_OnGrenadeCreated(Handle timer, int ref)
{
    int entity = EntRefToEntIndex(ref);
    if (entity != INVALID_ENT_REFERENCE)
    {
        if (g_fDurationGrenade)
        {
            SetEntProp(entity, Prop_Data, "m_nNextThinkTick", -1);
        }
    }
    return Plugin_Continue;
}

public Action Timer_OnStartDetonate(Handle timer, int ref)
{
    int entity = EntRefToEntIndex(ref);
    if (entity != INVALID_ENT_REFERENCE)
    {
        ExplodeNade(entity);
    }
    return Plugin_Continue;
}

stock void ExplodeNade(int entity)
{
    SetEntProp(entity, Prop_Data, "m_takedamage", 2);          // Enable damage
    SetEntProp(entity, Prop_Data, "m_iHealth", 1);             // Set health to 1 to simulate explosion
    SDKHooks_TakeDamage(entity, 0, 0, 1.0);                    // Trigger explosion effect
    SetEntProp(entity, Prop_Data, "m_nNextThinkTick", 1);       // Set next think tick for the grenade (this can be used for further processing)
}
