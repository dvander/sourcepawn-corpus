#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

// --- Constants ---
#define MAX_ACTIVE_FIRE 8 
#define PLUGIN_VERSION "2.4.0"

// --- Global Variables ---
ConVar g_cvEnabled, g_cvFireDuration, g_cvSoundPath, g_cvSoundVolume, g_cvParticleName, g_cvOnlyHeadshot, g_cvZOffset, g_cvBodyAlpha;
int g_iActiveFires = 0;

public Plugin myinfo = 
{
    name = "Dissolve fire effect",
    author = "Maxim Melnikov",
    description = "Bodies burn and vanish cleanly",
    version = PLUGIN_VERSION,
    url = ""
};

public void OnPluginStart() 
{
    g_cvEnabled       = CreateConVar("sm_firedeath_enabled", "1", "Enable body burning effect (1/0)", FCVAR_NONE, true, 0.0, true, 1.0);
    g_cvFireDuration  = CreateConVar("sm_firedeath_time", "2.0", "How long the body burns before vanishing", FCVAR_NONE, true, 0.1, true, 10.0);
    g_cvSoundPath     = CreateConVar("sm_firedeath_sound", "ambient/fire/ignite.wav", "Path to ignition sound");
    g_cvSoundVolume   = CreateConVar("sm_firedeath_volume", "0.8", "Sound volume (0.1 - 1.0)", FCVAR_NONE, true, 0.1, true, 1.0);
    g_cvParticleName  = CreateConVar("sm_firedeath_particle", "env_fire_medium", "Particle effect name");
    g_cvOnlyHeadshot  = CreateConVar("sm_firedeath_headshot", "0", "Trigger only on headshots (1/0)");
    g_cvZOffset       = CreateConVar("sm_firedeath_z_offset", "15.0", "Vertical fire offset");
    g_cvBodyAlpha      = CreateConVar("sm_firedeath_alpha", "255", "Body transparency while burning (0-255)");

    AutoExecConfig(true, "Dissolve_fire_effect");

    HookEvent("player_death", Event_PlayerDeath);
}

public void OnMapStart() 
{
    char sSound[PLATFORM_MAX_PATH];
    g_cvSoundPath.GetString(sSound, sizeof(sSound));
    if (sSound[0] != '\0') 
    {
        PrecacheSound(sSound, true);
    }
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast) 
{
    if (!g_cvEnabled.BoolValue) return;

    if (g_cvOnlyHeadshot.BoolValue && !event.GetBool("headshot")) return;

    int userid = event.GetInt("userid");
    if (userid > 0) 
    {
        // Small delay to ensure the server has created the ragdoll entity
        CreateTimer(0.2, Timer_StartBurning, userid, TIMER_FLAG_NO_MAPCHANGE);
    }
}

public Action Timer_StartBurning(Handle timer, any userid) 
{
    int client = GetClientOfUserId(userid);
    if (client <= 0) return Plugin_Stop;

    int ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
    if (ragdoll <= MaxClients || !IsValidEntity(ragdoll)) return Plugin_Stop;

    // Set transparency for a burning effect look
    int alpha = g_cvBodyAlpha.IntValue;
    if (alpha < 255) 
    {
        SetEntityRenderMode(ragdoll, RENDER_TRANSCOLOR);
        SetEntityRenderColor(ragdoll, 255, 255, 255, (alpha < 0) ? 0 : alpha);
    }

    // Create the particle fire
    CreateFireEffect(ragdoll);
    
    // Play the ignition sound
    char sSound[PLATFORM_MAX_PATH];
    g_cvSoundPath.GetString(sSound, sizeof(sSound));
    if (sSound[0] != '\0') 
    {
        EmitSoundToAll(sSound, ragdoll, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, g_cvSoundVolume.FloatValue);
    }

    // Schedule ragdoll removal
    CreateTimer(g_cvFireDuration.FloatValue, Timer_RemoveRagdoll, EntIndexToEntRef(ragdoll), TIMER_FLAG_NO_MAPCHANGE);

    return Plugin_Stop;
}

void CreateFireEffect(int entity) 
{
    if (g_iActiveFires >= MAX_ACTIVE_FIRE) return; 

    int fire = CreateEntityByName("info_particle_system");
    if (fire != -1) 
    {
        g_iActiveFires++; 

        float pos[3];
        GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);
        pos[2] += g_cvZOffset.FloatValue;

        TeleportEntity(fire, pos, NULL_VECTOR, NULL_VECTOR); 
        
        char sParticle[64];
        g_cvParticleName.GetString(sParticle, sizeof(sParticle));
        
        DispatchKeyValue(fire, "effect_name", sParticle); 
        DispatchSpawn(fire);
        ActivateEntity(fire);
        AcceptEntityInput(fire, "Start");

        // Parent the fire to the body so it moves with it
        SetVariantString("!activator");
        AcceptEntityInput(fire, "SetParent", entity);

        // Schedule fire removal
        CreateTimer(g_cvFireDuration.FloatValue + 0.5, Timer_RemoveFire, EntIndexToEntRef(fire), TIMER_FLAG_NO_MAPCHANGE);
    }
}

public Action Timer_RemoveRagdoll(Handle timer, any ref) 
{
    int entity = EntRefToEntIndex(ref);
    if (entity != INVALID_ENT_REFERENCE && IsValidEntity(entity)) 
    {
        RemoveEntity(entity);
    }
    return Plugin_Stop;
}

public Action Timer_RemoveFire(Handle timer, any ref) 
{
    int entity = EntRefToEntIndex(ref);
    if (entity != INVALID_ENT_REFERENCE && IsValidEntity(entity)) 
    {
        RemoveEntity(entity);
    }

    if (g_iActiveFires > 0) g_iActiveFires--;
    
    return Plugin_Stop;
}