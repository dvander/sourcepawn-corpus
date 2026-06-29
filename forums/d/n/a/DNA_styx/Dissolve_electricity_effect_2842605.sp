#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

// ===================== CONSTANTS =====================
#define PLUGIN_VERSION "2.2.7"
#define MAX_ACTIVE_DISSOLVES 10     // Limits simultaneous effects to preserve client FPS

// ===================== GLOBAL VARIABLES =====================
ConVar g_cvEnabled, g_cvDelay, g_cvType, g_cvUpwardForce, g_cvSoundPath, g_cvSoundLevel;
int g_iActiveDissolves = 0;

public Plugin myinfo = 
{
    name        = "Dissolve electricity effect",
    author      = "Maxim Melnikov",
    description = "Optimized body disintegration using native Source Engine shaders",
    version     = PLUGIN_VERSION,
    url         = "https://github.com/Maximka1993271"
};

// ===================== PLUGIN INITIALIZATION =====================

public void OnPluginStart() 
{
    g_cvEnabled      = CreateConVar("sm_dissolve_enabled", "1", "Enable dissolve effect (1/0)", FCVAR_NONE, true, 0.0, true, 1.0);
    g_cvDelay        = CreateConVar("sm_dissolve_delay", "0.3", "Delay before dissolve (0.1-5.0 sec)", FCVAR_NONE, true, 0.1, true, 5.0);
    g_cvType         = CreateConVar("sm_dissolve_type", "0", "Type: 0=Energy, 1=Heavy, 2=Light, 3=Core", FCVAR_NONE, true, 0.0, true, 3.0);
    g_cvUpwardForce  = CreateConVar("sm_dissolve_upward_force", "300.0", "Upward force applied to body", FCVAR_NONE, true, 0.0, true, 1000.0);
    g_cvSoundPath    = CreateConVar("sm_dissolve_sound_path", "ambient/levels/citadel/weapon_disintegrate2.wav", "Sound file path");
    g_cvSoundLevel   = CreateConVar("sm_dissolve_sound_level", "75", "Sound volume level", FCVAR_NONE, true, 0.0, true, 150.0);

    AutoExecConfig(true, "dissolve_electricity_effect");
    HookEvent("player_death", Event_PlayerDeath);
}

public void OnMapStart()
{
    g_iActiveDissolves = 0; 

    char sSound[PLATFORM_MAX_PATH];
    g_cvSoundPath.GetString(sSound, sizeof(sSound));
    
    // Check if sound file actually exists on the server
    if (sSound[0] != '\0' && FileExists(sSound, true)) 
        PrecacheSound(sSound, true);
}

// ===================== EVENT HANDLERS =====================

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    if (!g_cvEnabled.BoolValue) return;

    int userid = event.GetInt("userid");
    float delay = g_cvDelay.FloatValue;
    
    // Safety timer to allow ragdoll entity to materialize
    CreateTimer((delay < 0.1 ? 0.1 : delay), Timer_Dissolve, userid, TIMER_FLAG_NO_MAPCHANGE); 
}

// ===================== CORE LOGIC =====================

public Action Timer_Dissolve(Handle timer, any userid)
{
    int client = GetClientOfUserId(userid);
    if (client > 0 && IsClientInGame(client)) 
    {
        ApplyDissolve(client);
    }
    return Plugin_Stop;
}

void ApplyDissolve(int client)
{
    // Retrieve the ragdoll entity associated with the dead client
    int ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
    
    if (ragdoll <= MaxClients || !IsValidEntity(ragdoll)) return;
    if (g_iActiveDissolves >= MAX_ACTIVE_DISSOLVES) return;
    
    g_iActiveDissolves++;

    // --- Physics: Apply upward "levitation" effect ---
    float upForce = g_cvUpwardForce.FloatValue;
    if (upForce > 0.0)
    {
        AcceptEntityInput(ragdoll, "EnableMotion");

        float velocity[3];
        velocity[0] = GetRandomFloat(-15.0, 15.0);
        velocity[1] = GetRandomFloat(-15.0, 15.0);
        velocity[2] = upForce; 
        TeleportEntity(ragdoll, NULL_VECTOR, NULL_VECTOR, velocity);
    }

    // --- Sound Effects ---
    char sSound[PLATFORM_MAX_PATH];
    g_cvSoundPath.GetString(sSound, sizeof(sSound));
    if (sSound[0] != '\0')
        EmitSoundToAll(sSound, ragdoll, SNDCHAN_AUTO, g_cvSoundLevel.IntValue);

    // --- Native Dissolver Setup ---
    int ent = CreateEntityByName("env_entity_dissolver");
    if (ent != -1)
    {
        // Tag the ragdoll so the dissolver knows what to target
        char dname[32];
        FormatEx(dname, sizeof(dname), "dis_%d", ragdoll);
        DispatchKeyValue(ragdoll, "targetname", dname);

        char dtype[4];
        IntToString(g_cvType.IntValue, dtype, sizeof(dtype));
        
        DispatchKeyValue(ent, "dissolvetype", dtype);
        DispatchKeyValue(ent, "target", dname);

        if (DispatchSpawn(ent))
        {
            AcceptEntityInput(ent, "Dissolve");
            // Use Entity Reference for safe cleanup
            CreateTimer(0.5, Timer_KillDissolver, EntIndexToEntRef(ent), TIMER_FLAG_NO_MAPCHANGE);
        }
        else
        {
            AcceptEntityInput(ent, "Kill");
            if (g_iActiveDissolves > 0) g_iActiveDissolves--;
        }
    }
    else
    {
        if (g_iActiveDissolves > 0) g_iActiveDissolves--;
    }
}

public Action Timer_KillDissolver(Handle timer, any ref)
{
    int entity = EntRefToEntIndex(ref);
    if (entity != INVALID_ENT_REFERENCE && IsValidEntity(entity)) 
    {
        AcceptEntityInput(entity, "Kill");
    }
    
    // Decrement the active counter when the effect is completed
    if (g_iActiveDissolves > 0) g_iActiveDissolves--;
    
    return Plugin_Stop;
}