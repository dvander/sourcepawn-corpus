// ====================================================================================================
// Plugin Info
// ====================================================================================================
#define PLUGIN_NAME        "[L4D1/2] Witch Victim Gibs"
#define PLUGIN_AUTHOR      "Finishlast"
#define PLUGIN_DESCRIPTION "Spawns gibs and blooddecals when a witch scratches a survivor"
#define PLUGIN_VERSION     "1.0.8"
#define PLUGIN_URL         "https://forums.alliedmods.net/showthread.php?p=2838185"

public Plugin myinfo =
{
    name        = PLUGIN_NAME,
    author      = PLUGIN_AUTHOR,
    description = PLUGIN_DESCRIPTION,
    version     = PLUGIN_VERSION,
    url         = PLUGIN_URL
}

// ====================================================================================================
// Includes & Pragmas
// ====================================================================================================
#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

// ====================================================================================================
// Defines
// ====================================================================================================
#define BELLY_MODEL "models/props_interiors/refrigerator03_damaged_07.mdl"
#define GIB_MODEL   "models/infected/limbs/exploded_boomer_steak1.mdl"
#define GIB_MODEL2  "models/infected/limbs/exploded_boomer_steak2.mdl"
#define GIB_MODEL3  "models/infected/limbs/exploded_boomer_steak3.mdl"

// ====================================================================================================
// Globals
// ====================================================================================================
float g_LastGibSpawnTime = 0.0;

bool g_bEnabled;
float g_fLifetime;
bool g_bgibsEnabled;
bool g_bdecalsEnabled;
int g_idecalsIntensity;

ConVar g_cvarEnabled;
ConVar g_cvarLifetime;
ConVar g_cvargibsEnabled;
ConVar g_cvardecalsEnabled;
ConVar g_cvardecalsIntensity;

static const char g_gibModels[][] = {
    GIB_MODEL,
    GIB_MODEL2,
    GIB_MODEL3
};

// ====================================================================================================
// Plugin Start and initialisation
// ====================================================================================================
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    EngineVersion engine = GetEngineVersion();
    if (engine != Engine_Left4Dead && engine != Engine_Left4Dead2)
    {
        strcopy(error, err_max, "This plugin only runs in \"Left 4 Dead 1 or 2\" game");
        return APLRes_SilentFailure;
    }
    return APLRes_Success;
}

public void OnPluginStart()
{
    g_cvarEnabled  = CreateConVar("l4d_gibs_enabled", "1", "Enable/disable the witch gib plugin", FCVAR_NOTIFY);
    g_cvarLifetime = CreateConVar("l4d_witch_victim_gibs_lifetime", "20.0", "Time in seconds before the gibs are removed", FCVAR_NOTIFY);
    g_cvargibsEnabled  = CreateConVar("l4d_gibsspawn_enabled", "1", "Enable/disable the spawn of gibs effect", FCVAR_NOTIFY);
    g_cvardecalsEnabled = CreateConVar("l4d_decalsspawn_enabled", "1", "Enable/disable the spawn of decal effect", FCVAR_NOTIFY);
    g_cvardecalsIntensity = CreateConVar("l4d_decalsintensity", "3", "How many decals are sprayed on each hit, do not make it too high", FCVAR_NOTIFY);

    HookEvent("player_hurt", OnPlayerHurt);
    HookConVarChange(g_cvarEnabled, OnCvarChanged);
    HookConVarChange(g_cvarLifetime, OnCvarChanged);
    HookConVarChange(g_cvargibsEnabled, OnCvarChanged);
    HookConVarChange(g_cvardecalsEnabled, OnCvarChanged);
    HookConVarChange(g_cvardecalsIntensity, OnCvarChanged);
    AddNormalSoundHook(SoundHook);

    AutoExecConfig(true, "l4d_witch_victim_gibs");
    GetCvars();
}

public void OnMapStart()
{
    PrecacheParticle("blood_impact_arterial_spray");
    PrecacheModel(BELLY_MODEL, true);
    PrecacheModel(GIB_MODEL, true);
    PrecacheModel(GIB_MODEL2, true);
    PrecacheModel(GIB_MODEL3, true);
    PrecacheSound("physics/flesh/flesh_squishy_impact_hard1.wav", true);
}

public void OnCvarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    GetCvars();
}

public void GetCvars()
{
    g_bEnabled = g_cvarEnabled.BoolValue;
    g_fLifetime = GetConVarFloat(g_cvarLifetime);
    g_bgibsEnabled = g_cvargibsEnabled.BoolValue;
    g_bdecalsEnabled = g_cvardecalsEnabled.BoolValue;
    g_idecalsIntensity = g_cvardecalsIntensity.IntValue;
}


// ====================================================================================================
// Helper
// ====================================================================================================
bool IsWitchType(int ent)
{
    if (ent <= 0 || !IsValidEntity(ent))
        return false;

    char classname[64];
    GetEdictClassname(ent, classname, sizeof(classname));
    return StrEqual(classname, "witch", false);
}

// ====================================================================================================
// Witch Gibs on Scratch
// ====================================================================================================
public void OnPlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
    if (!g_bEnabled)
    return;

    int victim = GetClientOfUserId(event.GetInt("userid"));
    if (victim <= 0 || victim > MaxClients || !IsClientInGame(victim))
        return;

    int attacker = event.GetInt("attackerentid");
    if (!IsWitchType(attacker))
        return;

    float origin[3];
    GetClientAbsOrigin(victim, origin);

    for (int i = 0; i < 4; i++)
    {
        int index = GetRandomInt(0, sizeof(g_gibModels) - 1);

        float gibOrigin[3];
        gibOrigin[0] = origin[0];
        gibOrigin[1] = origin[1];
        gibOrigin[2] = origin[2] + 10.0;
        
        if (g_bgibsEnabled)
        {
            SpawnFlyingGibs(gibOrigin, g_gibModels[index]);
        }
        if (g_bdecalsEnabled)
        {
            SpawnBlooddecals(origin);
        }
    }
}

// ====================================================================================================
// Gib Spawning Logic
// ====================================================================================================
void SpawnFlyingGibs(float origin[3], const char[] gibModel)
{
    g_LastGibSpawnTime = GetGameTime();
    int rand = GetURandomInt() % 100000;
    char bellyName[32];
    Format(bellyName, sizeof(bellyName), "belly_%d", rand);

    int fakegib = CreateEntityByName("prop_physics_override");
    if (fakegib == -1) return;

    DispatchKeyValue(fakegib, "model", BELLY_MODEL);
    DispatchKeyValue(fakegib, "solid", "0");
    DispatchKeyValue(fakegib, "targetname", bellyName);
    DispatchKeyValue(fakegib, "rendermode", "10");
    DispatchKeyValue(fakegib, "renderamt", "0");
    DispatchKeyValue(fakegib, "disableshadows", "1");

    char lifetime[64];
    Format(lifetime, sizeof(lifetime), "OnUser1 !self:Kill::%.2f:-1", g_fLifetime);
    SetVariantString(lifetime);
    AcceptEntityInput(fakegib, "AddOutput");
    AcceptEntityInput(fakegib, "FireUser1");
    DispatchSpawn(fakegib);
    int fx = GetEntProp(fakegib, Prop_Send, "m_fEffects"); 
    SetEntProp(fakegib, Prop_Send, "m_fEffects", fx | 32); // EF_NODRAW

    float angles[3];
    angles[0] = GetRandomFloat(0.0, 360.0);
    angles[1] = GetRandomFloat(0.0, 360.0);
    angles[2] = GetRandomFloat(0.0, 360.0);

    TeleportEntity(fakegib, origin, angles, NULL_VECTOR);

    float velocity[3];
    velocity[0] = 0.0;
    velocity[1] = 0.0;
    velocity[2] = 200.0;
    SetEntPropVector(fakegib, Prop_Data, "m_vecVelocity", velocity);

    ActivateEntity(fakegib);
    SetEntProp(fakegib, Prop_Send, "m_CollisionGroup", 1);

    int gib = CreateEntityByName("prop_dynamic_override");
    if (gib == -1) return;

    DispatchKeyValue(gib, "model", gibModel);
    DispatchKeyValue(gib, "solid", "0");
    DispatchKeyValue(gib, "parentname", bellyName);
    DispatchKeyValue(gib, "disableshadows", "1");
    DispatchSpawn(gib);
    TeleportEntity(gib, origin, NULL_VECTOR, NULL_VECTOR);

    SetVariantString(bellyName);
    AcceptEntityInput(gib, "SetParent");

    int particle = CreateEntityByName("info_particle_system");
    if (particle == -1) return;

    DispatchKeyValue(particle, "effect_name", "blood_impact_arterial_spray");
    DispatchKeyValue(particle, "parentname", bellyName);
    DispatchSpawn(particle);
    TeleportEntity(particle, origin, NULL_VECTOR, NULL_VECTOR);
    AcceptEntityInput(particle, "start");
    SetVariantString(bellyName);
    AcceptEntityInput(particle, "SetParent");
    ActivateEntity(particle);
}

// ====================================================================================================
// Blooddecals Spawning Logic
// ====================================================================================================
void SpawnBlooddecals(float origin[3])
{
    for (int i = 0; i < g_idecalsIntensity; i++)
    {
        int blood = CreateEntityByName("env_blood");
        if (blood != -1)
        {
            DispatchKeyValue(blood, "color", "0");
            DispatchKeyValue(blood, "amount", "255");
            DispatchKeyValue(blood, "spraydir", "0 0 1");
            DispatchKeyValue(blood, "spawnflags", "9"); // Random + Spray decals
            DispatchSpawn(blood);

            TeleportEntity(blood, origin, NULL_VECTOR, NULL_VECTOR);
            AcceptEntityInput(blood, "EmitBlood");

            // Clean up to avoid entity clutter
            AcceptEntityInput(blood, "Kill");
        }
    }
}

// ====================================================================================================
// Sound Replacement
// ====================================================================================================
public Action SoundHook(int clients[64], int &numClients, char sample[PLATFORM_MAX_PATH],
                        int &entity, int &channel, float &volume, int &level, int &pitch, int &flags)
{
    if (StrContains(sample, "metal_solid_impact_soft") != -1 || StrContains(sample, "metal_solid_impact_hard") != -1)
    {
        float now = GetGameTime();
        if (now - g_LastGibSpawnTime < 4.0)
        {
            strcopy(sample, PLATFORM_MAX_PATH, "physics/flesh/flesh_squishy_impact_hard1.wav");
            return Plugin_Changed;
        }
    }

    return Plugin_Continue;
}

// ====================================================================================================
// Marttt Precache Particles
// ====================================================================================================
stock void PrecacheParticle(const char[] sEffectName)
{
    static int table = INVALID_STRING_TABLE;
    if (table == INVALID_STRING_TABLE)
    {
        table = FindStringTable("ParticleEffectNames");
    }

    if (FindStringIndex(table, sEffectName) == INVALID_STRING_INDEX)
    {
        bool save = LockStringTables(false);
        AddToStringTable(table, sEffectName);
        LockStringTables(save);
    }
}
