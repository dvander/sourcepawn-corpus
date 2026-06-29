/*
// ====================================================================================================
Based completely on Marts 
[L4D1 & L4D2] Tank Car Smash [v1.0.1 | 09-November-2021]
https://forums.alliedmods.net/showthread.php?t=335105

// ====================================================================================================

Change Log:
1.1.0 (30-December-2025)
    Reworked to use EntRefs, arrays and loops for all car parts.
    Fixed invalid entity access in changevDir by validating EntRefs.
    Removed massive ent_carpartX globals; now using a single array.
    Cleaned up unused variables and parameters
1.0.6 (02-August-2022)
    extra check for models/props_vehicles/generator (in hospital map after elevator)
1.0.5 (22-April-2022)
    set rendercolor to 0 0 0 for the purple parts in l4d2 as workaround
1.0.4 (09-January-2022)
    extra check for models/props_vehicles/train // custom maps as physics override
1.0.3 (10-December-2021)
    extra check for models/props_vehicles/airport_baggage_cart2.mdl
1.0.2 (1-December-2021)
    auto cleanup of entity mess
1.0.1 (20-November-2021)
    cvar chance added
    vertical movement added
1.0.0 (16-November-2021)
    - Initial release.
// ====================================================================================================
*/

// ====================================================================================================
// Plugin Info - define
// ====================================================================================================
#define PLUGIN_NAME                   "[L4D1] Boatstyle cars"
#define PLUGIN_AUTHOR                 "Finishlast"
#define PLUGIN_DESCRIPTION            "Tank punch will have a default chance of 5% to completely smash the car."
#define PLUGIN_VERSION                "1.1.0"
#define PLUGIN_URL                    "https://forums.alliedmods.net/showthread.php?p=2764719"

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
#include <sdkhooks>

// ====================================================================================================
// Pragmas
// ====================================================================================================
#pragma semicolon 1
#pragma newdecls required

// ====================================================================================================
// Cvar Flags
// ====================================================================================================
#define CVAR_FLAGS                    FCVAR_NOTIFY
#define CVAR_FLAGS_PLUGIN_VERSION     FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_SPONLY

// ====================================================================================================
// Filenames
// ====================================================================================================
#define CONFIG_FILENAME               "l4d_boatstyle_cars"

// ====================================================================================================
// Defines
// ====================================================================================================

#define SOUND_GLASS_SHEET_BREAK1      "physics/glass/glass_sheet_break1.wav"
#define SOUND_GLASS_SHEET_BREAK2      "physics/glass/glass_sheet_break2.wav"
#define SOUND_GLASS_SHEET_BREAK3      "physics/glass/glass_sheet_break3.wav"

#define CAR_PARTS1                    "models/props_vehicles/tire001c_car.mdl"
#define CAR_PARTS3                    "models/props_unique/subwaycarexterior01_enddoor01_damaged01.mdl"
#define CAR_PARTS4                    "models/props_unique/subwaycarexterior01_enddoor01_damaged02.mdl"
#define CAR_PARTS5                    "models/props_unique/subwaycarexterior01_enddoor01_damaged03.mdl"
#define CAR_PARTS6                    "models/props_unique/subwaycarexterior01_enddoor01_damaged04.mdl"
#define CAR_PARTS7                    "models/props_unique/subwaycarexterior01_enddoor01_damaged05.mdl"
#define CAR_PARTS8                    "models/props_unique/subwaycarexterior01_sidedoor01_damaged_01.mdl"
#define CAR_PARTS9                    "models/props_unique/subwaycarexterior01_sidedoor01_damaged_02.mdl"
#define CAR_PARTS10                   "models/props_unique/subwaycarexterior01_sidedoor01_damaged_03.mdl"
#define CAR_PARTS11                   "models/props_unique/subwaycarexterior01_sidedoor01_damaged_04.mdl"
#define CAR_PARTS12                   "models/props_vehicles/helicopter_crashed_chunk04.mdl"
#define CAR_PARTS15                   "models/props_vehicles/helicopter_crashed_chunk07.mdl"
#define CAR_PARTS56                   "models/props_vehicles/helicopter_crashed_chunk08.mdl"

#define TEAM_INFECTED                 3
#define L4D1_ZOMBIECLASS_TANK         5
#define L4D2_ZOMBIECLASS_TANK         8
#define MAXENTITIES                   2048

// ====================================================================================================
// Plugin Cvars
// ====================================================================================================
static ConVar g_hCvar_Enabled;
static ConVar g_hCvar_DeleteChilds;
static ConVar g_hCvar_GlassSound;
static ConVar g_hCvar_DestroyChance;

// ====================================================================================================
// bool - Plugin Variables
// ====================================================================================================
static bool   g_bL4D2;
static bool   g_bCvar_Enabled;
static bool   g_bCvar_DeleteChilds;
static bool   g_bCvar_GlassSound;

// ====================================================================================================
// int - Plugin Variables
// ====================================================================================================
static int    g_iTankClass;
static int    g_iCvar_DestroyChance;

// ====================================================================================================
// entity - Plugin Variables
// ====================================================================================================
static bool   ge_bOnTakeDamagePostHooked[MAXENTITIES+1];

// Anzahl Car Parts pro Smash
#define MAX_CAR_PARTS 32

// EntRefs der Car Parts für den letzten Smash
int g_iCarPartRefs[MAX_CAR_PARTS];

// Modelle der Car Parts – strukturiert statt ent_carpart1..28
static const char g_sCarPartModels[][] =
{
    // 0-3: tires (CAR_PARTS1)
    CAR_PARTS1,
    CAR_PARTS1,
    CAR_PARTS1,
    CAR_PARTS1,

    // 4-7: chairs (CAR_PARTS56)
    CAR_PARTS56,
    CAR_PARTS56,
    CAR_PARTS56,
    CAR_PARTS56,

    // 8-31: junk (Subway/Heli Teile)
    CAR_PARTS3,   // 8
    CAR_PARTS4,   // 9
    CAR_PARTS5,   // 10
    CAR_PARTS6,   // 11
    CAR_PARTS7,   // 12
    CAR_PARTS8,   // 13
    CAR_PARTS9,   // 14
    CAR_PARTS10,  // 15
    CAR_PARTS11,  // 16
    CAR_PARTS12,  // 17
    CAR_PARTS6,   // 18
    CAR_PARTS3,   // 19
    CAR_PARTS4,   // 20
    CAR_PARTS5,   // 21
    CAR_PARTS6,   // 22
    CAR_PARTS7,   // 23
    CAR_PARTS8,   // 24
    CAR_PARTS9,   // 25
    CAR_PARTS10,  // 26
    CAR_PARTS11,  // 27
    CAR_PARTS12,  // 28
    CAR_PARTS6,   // 29
    CAR_PARTS4,   // 30
    CAR_PARTS9    // 31
};

// ====================================================================================================
// Plugin Start
// ====================================================================================================
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    EngineVersion engine = GetEngineVersion();

    if (engine != Engine_Left4Dead && engine != Engine_Left4Dead2)
    {
        strcopy(error, err_max, "This plugin only runs in \"Left 4 Dead\" and \"Left 4 Dead 2\" game");
        return APLRes_SilentFailure;
    }

    g_bL4D2 = (engine == Engine_Left4Dead2);
    g_iTankClass = (g_bL4D2 ? L4D2_ZOMBIECLASS_TANK : L4D1_ZOMBIECLASS_TANK);

    return APLRes_Success;
}

/****************************************************************************************************/

public void OnPluginStart()
{
    CreateConVar("l4d_tank_car_smash_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
    g_hCvar_Enabled       = CreateConVar("l4d_boatstyle_cars_enable", "1", "Enable/Disable the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_DestroyChance = CreateConVar("l4d_boatstyle_cars_DestroyChance", "5", "Percent chance a tank punch can detroy a car. 1-100", CVAR_FLAGS);
    g_hCvar_DeleteChilds  = CreateConVar("l4d_boatstyle_cars_delete_childs", "1", "Delete attached entities (child) from the car.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_GlassSound    = CreateConVar("l4d_boatstyle_cars_glass_sound", "1", "Emit a random breaking glass sound on car hit (only once).\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);

    g_hCvar_Enabled.AddChangeHook(Event_ConVarChanged);
    g_hCvar_DestroyChance.AddChangeHook(Event_ConVarChanged);
    g_hCvar_DeleteChilds.AddChangeHook(Event_ConVarChanged);
    g_hCvar_GlassSound.AddChangeHook(Event_ConVarChanged);

    AutoExecConfig(true, CONFIG_FILENAME);

    for (int i = 0; i < MAX_CAR_PARTS; i++)
    {
        g_iCarPartRefs[i] = INVALID_ENT_REFERENCE;
    }
}

/****************************************************************************************************/

public void OnMapStart()
{
    PrecacheModel(CAR_PARTS1, true);
    PrecacheModel(CAR_PARTS3, true);
    PrecacheModel(CAR_PARTS4, true);
    PrecacheModel(CAR_PARTS5, true);
    PrecacheModel(CAR_PARTS6, true);
    PrecacheModel(CAR_PARTS7, true);
    PrecacheModel(CAR_PARTS8, true);
    PrecacheModel(CAR_PARTS9, true);
    PrecacheModel(CAR_PARTS10, true);
    PrecacheModel(CAR_PARTS11, true);
    PrecacheModel(CAR_PARTS12, true);
    PrecacheModel(CAR_PARTS15, true);
    PrecacheModel(CAR_PARTS56, true);

    for (int i = 0; i < MAX_CAR_PARTS; i++)
    {
        g_iCarPartRefs[i] = INVALID_ENT_REFERENCE;
    }
}

/****************************************************************************************************/

public void OnConfigsExecuted()
{
    GetCvars();
    PrecacheSounds();
    LateLoad();
}

/****************************************************************************************************/

public void Event_ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    GetCvars();
    PrecacheSounds();
}

/****************************************************************************************************/

void GetCvars()
{
    g_bCvar_Enabled       = g_hCvar_Enabled.BoolValue;
    g_bCvar_DeleteChilds  = g_hCvar_DeleteChilds.BoolValue;
    g_bCvar_GlassSound    = g_hCvar_GlassSound.BoolValue;
    g_iCvar_DestroyChance = g_hCvar_DestroyChance.IntValue;
}

/****************************************************************************************************/

void PrecacheSounds()
{
    if (g_bCvar_Enabled && g_bCvar_GlassSound)
    {
        PrecacheSound(SOUND_GLASS_SHEET_BREAK1);
        PrecacheSound(SOUND_GLASS_SHEET_BREAK2);
        PrecacheSound(SOUND_GLASS_SHEET_BREAK3);
    }
}

/****************************************************************************************************/

public void LateLoad()
{
    int entity = INVALID_ENT_REFERENCE;
    while ((entity = FindEntityByClassname(entity, "prop*")) != INVALID_ENT_REFERENCE)
    {
        if (HasEntProp(entity, Prop_Send, "m_hasTankGlow")) // CPhysicsProp
        {
            RequestFrame(OnNextFrame, EntIndexToEntRef(entity));
        }
    }
}

/****************************************************************************************************/

public void OnEntityDestroyed(int entity)
{
    if (!IsValidEntityIndex(entity))
        return;

    ge_bOnTakeDamagePostHooked[entity] = false;
}

/****************************************************************************************************/

public void OnEntityCreated(int entity, const char[] classname)
{
    if (!IsValidEntityIndex(entity))
        return;

    if (classname[0] != 'p')
        return;

    if (!HasEntProp(entity, Prop_Send, "m_hasTankGlow")) // CPhysicsProp
        return;

    SDKHook(entity, SDKHook_SpawnPost, OnSpawnPost);
}

/****************************************************************************************************/

public void OnSpawnPost(int entity)
{
    if (ge_bOnTakeDamagePostHooked[entity])
        return;

    char modelname[PLATFORM_MAX_PATH];
    GetEntPropString(entity, Prop_Data, "m_ModelName", modelname, sizeof(modelname));
    StringToLowerCase(modelname);

    if (strncmp(modelname, "models/props_vehicles", 21) == 0
        && StrContains(modelname, "boat", false) == -1
        && strncmp(modelname, "models/props_vehicles/generator", 31) != 0
        && strncmp(modelname, "models/props_vehicles/airport", 29) != 0
        && strncmp(modelname, "models/props_vehicles/train", 27) != 0
        && strncmp(modelname, "models/props_vehicles/heli", 26) != 0
        && strncmp(modelname, "models/props_vehicles/carp", 26) != 0
        && strncmp(modelname, "models/props_vehicles/tire", 26) != 0)
    {
        ge_bOnTakeDamagePostHooked[entity] = true;
        SDKHook(entity, SDKHook_OnTakeDamagePost, OnTakeDamagePost);
        return;
    }
}

/****************************************************************************************************/

public void OnNextFrame(int entityRef)
{
    int entity = EntRefToEntIndex(entityRef);

    if (entity == INVALID_ENT_REFERENCE)
        return;

    OnSpawnPost(entity);
}

/****************************************************************************************************/

public void OnTakeDamagePost(int victim, int attacker, int inflictor, float damage, int damagetype)
{
    if (!g_bCvar_Enabled)
        return;

    if (!IsValidClient(attacker))
        return;

    if (GetClientTeam(attacker) != TEAM_INFECTED)
        return;

    if (GetZombieClass(attacker) != g_iTankClass)
        return;

    char sWeapon[PLATFORM_MAX_PATH];
    GetEdictClassname(inflictor, sWeapon, sizeof(sWeapon));

    // ignore rock hits
    if (strncmp(sWeapon, "tank_r", 6) == 0)
        return;

    int tempchance = GetRandomInt(1, 100);
    if (tempchance > g_iCvar_DestroyChance)
        return;

    PrintToChatAll("[SM] Tank smashed the car!");

    SDKUnhook(victim, SDKHook_OnTakeDamagePost, OnTakeDamagePost);

    if (g_bCvar_DeleteChilds)
    {
        int entity = INVALID_ENT_REFERENCE;
        while ((entity = FindEntityByClassname(entity, "*")) != INVALID_ENT_REFERENCE)
        {
            if (HasEntProp(entity, Prop_Send, "moveparent") && victim == GetEntPropEnt(entity, Prop_Send, "moveparent"))
            {
                AcceptEntityInput(entity, "Kill");
            }
        }
    }

    if (g_bCvar_GlassSound)
    {
        switch (GetRandomInt(1, 3))
        {
            case 1: EmitSoundToAll(SOUND_GLASS_SHEET_BREAK1, victim);
            case 2: EmitSoundToAll(SOUND_GLASS_SHEET_BREAK2, victim);
            case 3: EmitSoundToAll(SOUND_GLASS_SHEET_BREAK3, victim);
        }
    }

    float vPos[3], vAng[3];
    GetEntPropVector(victim, Prop_Data, "m_vecAbsOrigin", vPos);
    GetEntPropVector(victim, Prop_Send, "m_angRotation", vAng);

    AcceptEntityInput(victim, "Kill");

    for (int i = 0; i < MAX_CAR_PARTS; i++)
    {
        g_iCarPartRefs[i] = INVALID_ENT_REFERENCE;
    }

    SpawnCarParts();
    ScatterCarParts(attacker);

    CreateTimer(1.5, changevDir);
}

/****************************************************************************************************/
// Car Parts Handling
/****************************************************************************************************/

void SpawnCarParts()
{
    bool bL4D2Hack = (g_iTankClass == L4D2_ZOMBIECLASS_TANK);

    for (int i = 0; i < MAX_CAR_PARTS; i++)
    {
        int ent = CreateEntityByName("prop_physics_override");
        if (ent == -1)
            continue;

        DispatchKeyValue(ent, "model", g_sCarPartModels[i]);
        DispatchKeyValue(ent, "solid", "0");
        DispatchKeyValue(ent, "disableshadows", "1");

        if (bL4D2Hack)
        {
            DispatchKeyValue(ent, "rendercolor", "0 0 0");
        }

        SetVariantString("OnUser1 !self:Kill::10:-1");
        AcceptEntityInput(ent, "AddOutput");
        AcceptEntityInput(ent, "FireUser1");

        DispatchSpawn(ent);

        g_iCarPartRefs[i] = EntIndexToEntRef(ent);
    }
}

void ScatterCarParts(int attacker)
{
    float vDir[3];
    float vPosBase[3], vAngBase[3];

    GetClientEyePosition(attacker, vPosBase);
    GetClientEyeAngles(attacker, vAngBase);

    vPosBase[2] += 50.0;

    if (vAngBase[1] >= -160.0 && vAngBase[1] <= -145.0)
    {
        vDir[1] = -400.0;
        vDir[0] = -400.0;
    }
    else if (vAngBase[1] >= -144.0 && vAngBase[1] <= -54.0)
    {
        vDir[1] = -400.0;
        vDir[0] = 0.0;
    }
    else if (vAngBase[1] >= -45.0 && vAngBase[1] <= -21.0)
    {
        vDir[1] = -400.0;
        vDir[0] = 400.0;
    }
    else if (vAngBase[1] >= -20.0 && vAngBase[1] <= 20.0)
    {
        vDir[1] = 0.0;
        vDir[0] = 400.0;
    }
    else if (vAngBase[1] >= 21.0 && vAngBase[1] <= 69.0)
    {
        vDir[1] = 400.0;
        vDir[0] = 400.0;
    }
    else if (vAngBase[1] >= 70.0 && vAngBase[1] <= 110.0)
    {
        vDir[1] = 400.0;
        vDir[0] = 0.0;
    }
    else if (vAngBase[1] >= 111.0 && vAngBase[1] <= 160.0)
    {
        vDir[1] = 400.0;
        vDir[0] = -400.0;
    }
    else if ((vAngBase[1] <= -161.0 && vAngBase[1] >= -179.0) || (vAngBase[1] <= 180.0 && vAngBase[1] >= 161.0))
    {
        vDir[1] = 0.0;
        vDir[0] = -400.0;
    }

    vDir[2] = 0.0;

    vPosBase[0] += 164.0 * Cosine(DegToRad(vAngBase[1]));
    vPosBase[1] += 164.0 * Sine(DegToRad(vAngBase[1]));

    float vPosTemp[3], vDirTemp[3];

    for (int i = 0; i < MAX_CAR_PARTS; i++)
    {
        int ent = EntRefToEntIndex(g_iCarPartRefs[i]);
        if (ent == INVALID_ENT_REFERENCE)
            continue;

        vPosTemp[0] = vPosBase[0] + float(GetRandomInt(1, 100));
        vPosTemp[1] = vPosBase[1] + float(GetRandomInt(1, 100));
        vPosTemp[2] = vPosBase[2];

        vDirTemp[0] = vDir[0];
        vDirTemp[1] = vDir[1];
        vDirTemp[2] = vDir[2] + float(GetRandomInt(1, 400));

        TeleportEntity(ent, vPosTemp, vAngBase, vDirTemp);
    }
}

/****************************************************************************************************/

public Action changevDir(Handle timer)
{
    

    float vPos[3], vAng[3];
    float vDir[3];
    vDir[0] = 0.0;
    vDir[1] = 0.0;
    vDir[2] = 0.0;

    for (int i = 0; i < MAX_CAR_PARTS; i++)
    {
        int ent = EntRefToEntIndex(g_iCarPartRefs[i]);
        if (ent == INVALID_ENT_REFERENCE)
            continue;

        if (!IsValidEntityIndex(ent))
            continue;

        GetEntPropVector(ent, Prop_Data, "m_vecAbsOrigin", vPos);
        GetEntPropVector(ent, Prop_Send, "m_angRotation", vAng);
        TeleportEntity(ent, vPos, vAng, vDir);
    }

    return Plugin_Handled;
}

// ====================================================================================================
// Helpers
// ====================================================================================================
bool IsValidClientIndex(int client)
{
    return (1 <= client <= MaxClients);
}

/****************************************************************************************************/

bool IsValidClient(int client)
{
    return (IsValidClientIndex(client) && IsClientInGame(client));
}

/****************************************************************************************************/

bool IsValidEntityIndex(int entity)
{
    return (MaxClients+1 <= entity <= GetMaxEntities());
}

/****************************************************************************************************/

int GetZombieClass(int client)
{
    return GetEntProp(client, Prop_Send, "m_zombieClass");
}

/****************************************************************************************************/

void StringToLowerCase(char[] input)
{
    int len = strlen(input);
    for (int i = 0; i < len; i++)
    {
        input[i] = CharToLower(input[i]);
    }
}
