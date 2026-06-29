// Based on[L4D2] Gibs by BHaType
// https://forums.alliedmods.net/showthread.php?t=319355
// ====================================================================================================
// Plugin Info - define
// ====================================================================================================
#define PLUGIN_NAME                   "[L4D] Gibs"
#define PLUGIN_AUTHOR                 "Finishlast"
#define PLUGIN_DESCRIPTION            "Spawns a skull and steaks where the common infected head was."
#define PLUGIN_VERSION                "1.0.6"
#define PLUGIN_URL                    "https://forums.alliedmods.net/showthread.php?p=351265"

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
#define SKULL_MODEL "models/props_interiors/refrigerator03_damaged_07.mdl"
#define GIB_MODEL   "models/gibs/hgibs.mdl"
#define GIB_MODEL2  "models/infected/limbs/exploded_boomer_steak1.mdl"

// ====================================================================================================
// Globals
// ====================================================================================================
float g_LastSkullSpawnTime = 0.0;
ConVar g_cvarEnabled;
ConVar g_cvarGoldChance;
ConVar g_cvarLifetime;
ConVar g_cvarEffectMode;
ConVar g_cvarSkullAndGibsChance;

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
    g_cvarGoldChance  = CreateConVar("l4d_gibs_gold_chance", "5", "Chance (in %) for a gold skull to appear", CVAR_FLAGS);
    g_cvarLifetime    = CreateConVar("l4d_gibs_lifetime", "20.0", "Time in seconds before skulls and gibs are removed", CVAR_FLAGS);
    g_cvarEffectMode  = CreateConVar("l4d_gibs_mode", "3", "Gib effect mode: 1 = skulls only, 2 = gibs only, 3 = both", CVAR_FLAGS);
    g_cvarSkullAndGibsChance = CreateConVar("l4d_skull_and_gibs_chance", "100", "Chance (in %) for the skull and gibs to appear", CVAR_FLAGS);
    AddNormalSoundHook(SoundHook);
    HookEvent("player_death", OnPlayerDeath);
    AutoExecConfig(true, "l4d_gibs");
}

public void OnMapStart()
{
    PrecacheParticle("blood_impact_arterial_spray");
    PrecacheModel(SKULL_MODEL, true);
    PrecacheModel(GIB_MODEL, true);
    PrecacheModel(GIB_MODEL2, true);
    PrecacheSound("physics/flesh/flesh_squishy_impact_hard1.wav", true);
}

// ====================================================================================================
// OnPlayerDeath
// ====================================================================================================
public void OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    if (!g_cvarEnabled.BoolValue)
        return;

    int entity = event.GetInt("entityid");

    char classname[64];
    GetEntityClassname(entity, classname, sizeof(classname));
    if (!StrEqual(classname, "infected"))
        return;

    char weapon[64];
    event.GetString("weapon", weapon, sizeof(weapon));
    if (!(StrEqual(weapon, "pumpshotgun") ||
      StrEqual(weapon, "smg") ||
      StrEqual(weapon, "smg_silenced") ||
      StrEqual(weapon, "shotgun_chrome") ||
      StrEqual(weapon, "autoshotgun") ||
      StrEqual(weapon, "shotgun_spas") ||
      StrEqual(weapon, "rifle") ||
      StrEqual(weapon, "rifle_ak47") ||
      StrEqual(weapon, "rifle_desert") ||
      StrEqual(weapon, "hunting_rifle") ||
      StrEqual(weapon, "sniper_military") ||
      StrEqual(weapon, "rifle_m60")))
    {
      return;
    }
    if (entity <= MaxClients || !event.GetBool("headshot"))
        return;

    int client = GetClientOfUserId(event.GetInt("attacker"));
    if (client <= 0 || client > MaxClients || !IsClientInGame(client))
        return;


    if (GetRandomInt(0, 99) < g_cvarSkullAndGibsChance.IntValue)
    {
       float origin[3];
       GetEntPropVector(entity, Prop_Send, "m_vecOrigin", origin);
       origin[2] += 60.0;

       int mode = g_cvarEffectMode.IntValue;

       if (mode == 1 || mode == 3)
       {
           SpawnFlyingSkull(origin, GIB_MODEL);
       }

       if (mode == 2 || mode == 3)
       {
           for (int i = 0; i < 3; i++)
           {
               origin[0] += GetRandomFloat(-20.0, 20.0);
               origin[1] += GetRandomFloat(-20.0, 20.0);
               origin[2] += GetRandomFloat(-20.0, 20.0);
               SpawnFlyingSkull(origin, GIB_MODEL2);
           }
       }
    }
}

// ====================================================================================================
// SpawnFlyingSkull
// ====================================================================================================
void SpawnFlyingSkull(float origin[3], const char[] gibModel)
{
    g_LastSkullSpawnTime = GetGameTime();
    int rand = GetURandomInt() % 100000;
    char skullName[32];
    Format(skullName, sizeof(skullName), "skull_%d", rand);

    int skull = CreateEntityByName("prop_physics_override");
    if (skull == -1) return;

    DispatchKeyValue(skull, "model", SKULL_MODEL);
    DispatchKeyValue(skull, "solid", "0");
    DispatchKeyValue(skull, "targetname", skullName);
    DispatchKeyValue(skull, "rendermode", "10");
    DispatchKeyValue(skull, "renderamt", "0");
    DispatchKeyValue(skull, "disableshadows", "1");
    char lifetime[32];
    FloatToString(g_cvarLifetime.FloatValue, lifetime, sizeof(lifetime));
    Format(lifetime, sizeof(lifetime), "OnUser1 !self:Kill::%s:-1", lifetime);
    SetVariantString(lifetime);
    AcceptEntityInput(skull, "AddOutput");
    AcceptEntityInput(skull, "FireUser1");
    DispatchSpawn(skull);
    int fx = GetEntProp(skull, Prop_Send, "m_fEffects"); 
    SetEntProp(skull, Prop_Send, "m_fEffects", fx | 32); // EF_NODRAW

    float velocity[3];
    velocity[0] = GetRandomFloat(-200.0, 200.0);
    velocity[1] = GetRandomFloat(-200.0, 200.0);
    velocity[2] = GetRandomFloat(150.0, 300.0);

    float angles[3];
    angles[0] = 0.0;
    angles[1] = GetRandomFloat(0.0, 360.0); // rotate
    angles[2] = 0.0;
    if (StrEqual(gibModel, GIB_MODEL2)) // rotate steaks
    {
	angles[0] = GetRandomFloat(0.0, 360.0); // rotate
	angles[2] = GetRandomFloat(0.0, 360.0); // rotate
    }
    TeleportEntity(skull, origin, angles, velocity);
    ActivateEntity(skull);
    SetEntProp(skull, Prop_Send, "m_CollisionGroup", 1);
    int gib = CreateEntityByName("prop_dynamic_override");
    if (gib == -1) return;

    DispatchKeyValue(gib, "model", gibModel);
    DispatchKeyValue(gib, "solid", "0");
    DispatchKeyValue(gib, "parentname", skullName);
    DispatchKeyValue(gib, "disableshadows", "1");
    DispatchSpawn(gib);
    TeleportEntity(gib, origin, NULL_VECTOR, NULL_VECTOR);

    if (GetRandomInt(0, 99) < g_cvarGoldChance.IntValue && StrEqual(gibModel, GIB_MODEL)) // chance for gold skull
    {
	DispatchKeyValue(gib, "rendercolor", "255 215 0"); // gold skull
    }
    SetVariantString(skullName);
    AcceptEntityInput(gib, "SetParent");

    //attach arterial spray to skull
    int particle = CreateEntityByName("info_particle_system");
    if (particle == -1) return;
    DispatchKeyValue(particle, "effect_name", "blood_impact_arterial_spray");
    DispatchSpawn(particle);
    DispatchKeyValue(particle, "parentname", skullName);
    TeleportEntity(particle, origin, NULL_VECTOR, NULL_VECTOR);
    AcceptEntityInput(particle, "start");
    SetVariantString(skullName);
    AcceptEntityInput(particle, "SetParent");
    ActivateEntity(particle);
}

// ====================================================================================================
// Sound Replacement
// ====================================================================================================
public Action SoundHook(int clients[64], int &numClients, char sample[PLATFORM_MAX_PATH],
                        int &entity, int &channel, float &volume, int &level, int &pitch, int &flags)
{
    if (StrContains(sample, "metal_solid_impact_soft") != -1 ||
        StrContains(sample, "metal_solid_impact_hard") != -1)
    {
        float now = GetGameTime();
        if (now - g_LastSkullSpawnTime < 4.0)
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