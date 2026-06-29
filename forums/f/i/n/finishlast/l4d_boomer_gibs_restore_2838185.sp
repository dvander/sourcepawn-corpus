// Based on [L4D2] Gibs by BHaType
// Based on [L4D2] Boomer gibs restore by Lux
// ====================================================================================================
// Plugin Info - define
// ====================================================================================================
#define PLUGIN_NAME                   "[L4D] Boomer Gibs Restore"
#define PLUGIN_AUTHOR                 "Finishlast"
#define PLUGIN_DESCRIPTION            "Spawns boomer gibs when a Boomer dies."
#define PLUGIN_VERSION                "1.0.6"
#define PLUGIN_URL                    "https://forums.alliedmods.net/showthread.php?p=2838185"

// ====================================================================================================
// Plugin Info
// ====================================================================================================
public Plugin myinfo =
{
    name        = PLUGIN_NAME,
    author      = PLUGIN_AUTHOR,
    description = PLUGIN_DESCRIPTION,
    version     = PLUGIN_VERSION,
    url         = PLUGIN_URL
}

// ====================================================================================================
// Includes
// ====================================================================================================
#include <sourcemod>
#include <sdktools>

// ====================================================================================================
// Pragmas
// ====================================================================================================
#pragma semicolon 1
#pragma newdecls required

// ====================================================================================================
// Cvar Flags
// ====================================================================================================
#define CVAR_FLAGS                    FCVAR_NOTIFY

// ====================================================================================================
// Defines
// ====================================================================================================
#define BELLY_MODEL "models/props_interiors/refrigerator03_damaged_07.mdl"
#define GIB_MODEL   "models/infected/limbs/exploded_boomer_steak1.mdl"
#define GIB_MODEL2  "models/infected/limbs/exploded_boomer_steak2.mdl"
#define GIB_MODEL3  "models/infected/limbs/exploded_boomer_steak3.mdl"
#define GIB_MODEL4  "models/infected/limbs/exploded_boomer_head.mdl"
#define GIB_MODEL5  "models/infected/limbs/exploded_boomer_rarm.mdl"

// ====================================================================================================
// Globals
// ====================================================================================================
float g_LastGibSpawnTime = 0.0;
ConVar g_cvarEnabled;
ConVar g_cvarLifetime;
ConVar g_cvarBoomerGibsChance;
ConVar g_cvarBoomerGibCount;

// ====================================================================================================
// Plugin Start
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
    g_cvarEnabled     = CreateConVar("l4d_gibs_enabled", "1", "Enable/disable the gib effect", CVAR_FLAGS);
    g_cvarLifetime    = CreateConVar("l4d_gibs_lifetime", "20.0", "Time in seconds before the gibs are removed", CVAR_FLAGS);
    g_cvarBoomerGibsChance = CreateConVar("l4d_boomer_gibs_chance", "100", "Chance (in %) for the gibs to appear", CVAR_FLAGS);
    g_cvarBoomerGibCount = CreateConVar("l4d_boomer_gibs_count", "20", "Number of random gib chunks to spawn on Boomer death", CVAR_FLAGS);
    AddNormalSoundHook(SoundHook);
    HookEvent("player_death", OnPlayerDeath);
    AutoExecConfig(true, "l4d_boomer_gibs");
}

public void OnMapStart()
{
    PrecacheParticle("blood_impact_arterial_spray");
    PrecacheModel(BELLY_MODEL, true);
    PrecacheModel(GIB_MODEL, true);
    PrecacheModel(GIB_MODEL2, true);
    PrecacheModel(GIB_MODEL3, true);
    PrecacheModel(GIB_MODEL4, true);
    PrecacheModel(GIB_MODEL5, true);
    PrecacheSound("physics/flesh/flesh_squishy_impact_hard1.wav", true);
}

// ====================================================================================================
// OnPlayerDeath
// ====================================================================================================
public void OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    if (!g_cvarEnabled.BoolValue)
        return;

    int victim = GetClientOfUserId(event.GetInt("userid"));
    if (victim <= 0 || victim > MaxClients || !IsClientInGame(victim))
        return;

    if (!IsBoomer(victim))
        return;

    int attacker = GetClientOfUserId(event.GetInt("attacker"));
    if (attacker <= 0 || attacker > MaxClients || !IsClientInGame(attacker))
        return;

    if (GetRandomInt(0, 99) < g_cvarBoomerGibsChance.IntValue)
    {
        float origin[3];
        GetClientAbsOrigin(victim, origin);
	SpawnBlooddecals(origin);
        origin[2] += 60.0;

        // head
        origin[0] += GetRandomFloat(-20.0, 20.0);
        origin[1] += GetRandomFloat(-20.0, 20.0);
        origin[2] += GetRandomFloat(-20.0, 20.0);
        SpawnFlyingGibs(origin, GIB_MODEL4);

        // arm
        origin[0] += GetRandomFloat(-20.0, 20.0);
        origin[1] += GetRandomFloat(-20.0, 20.0);
        origin[2] += GetRandomFloat(-20.0, 20.0);
        SpawnFlyingGibs(origin, GIB_MODEL5);

        static const char gibModels[][] = {
            GIB_MODEL,
            GIB_MODEL2,
            GIB_MODEL3
        };

        int gibCount = g_cvarBoomerGibCount.IntValue;
        for (int i = 0; i < gibCount; i++)
          {
             origin[0] += GetRandomFloat(-20.0, 20.0);
             origin[1] += GetRandomFloat(-20.0, 20.0);
             origin[2] += GetRandomFloat(-20.0, 20.0);

             int index = GetRandomInt(0, sizeof(gibModels) - 1);
             SpawnFlyingGibs(origin, gibModels[index]);
          }
	
        
    }
}

bool IsBoomer(int client)
{
    if (!IsClientInGame(client))
        return false;

    if (GetClientTeam(client) != 3) // Team 3 = Infected
        return false;

    char model[PLATFORM_MAX_PATH];
    GetClientModel(client, model, sizeof(model));

    return StrContains(model, "boomer", false) != -1;
}

// ====================================================================================================
// SpawnFlyingGibs
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
    char lifetime[32];
    FloatToString(g_cvarLifetime.FloatValue, lifetime, sizeof(lifetime));
    Format(lifetime, sizeof(lifetime), "OnUser1 !self:Kill::%s:-1", lifetime);
    SetVariantString(lifetime);
    AcceptEntityInput(fakegib, "AddOutput");
    AcceptEntityInput(fakegib, "FireUser1");
    DispatchSpawn(fakegib);
    int fx = GetEntProp(fakegib, Prop_Send, "m_fEffects"); 
    SetEntProp(fakegib, Prop_Send, "m_fEffects", fx | 32); // EF_NODRAW

    float velocity[3];
    velocity[0] = GetRandomFloat(-200.0, 200.0);
    velocity[1] = GetRandomFloat(-200.0, 200.0);
    velocity[2] = 200.0;

    float angles[3];

    angles[1] = GetRandomFloat(0.0, 360.0);
    angles[0] = GetRandomFloat(0.0, 360.0);
    angles[2] = GetRandomFloat(0.0, 360.0);

    TeleportEntity(fakegib, origin, angles, velocity);
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

    //attach arterial spray to belly
    int particle = CreateEntityByName("info_particle_system");
    if (particle == -1) return;
    DispatchKeyValue(particle, "effect_name", "blood_impact_arterial_spray");
    DispatchSpawn(particle);
    DispatchKeyValue(particle, "parentname", bellyName);
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
    for (int i = 0; i < 50; i++)
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
	if( table == INVALID_STRING_TABLE )
	{
		table = FindStringTable("ParticleEffectNames");
	}

	if( FindStringIndex(table, sEffectName) == INVALID_STRING_INDEX )
	{
		bool save = LockStringTables(false);
		AddToStringTable(table, sEffectName);
		LockStringTables(save);
	}
}