#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define GETVERSION "2.6-L4D1-Instant"
#define ARRAY_SIZE 2048
#define EXPLODE_INTERVAL 6.0

#define MODEL_GASCAN "models/props_junk/gascan001a.mdl"

static const char FIRE_PARTICLE[] =        "gas_explosion_ground_fire";
static const char EXPLOSION_PARTICLE[] =   "weapon_pipebomb";
static const char EXPLOSION_PARTICLE3[] =  "explosion_huge_b";
static const char EXPLOSION_SOUND[] =      "ambient/explosions/explode_1.wav";
static const char EXPLOSION_SOUND2[] =     "ambient/explosions/explode_2.wav";
static const char EXPLOSION_SOUND3[] =     "ambient/explosions/explode_3.wav";

static bool g_bConfigLoaded;
static bool g_bExploded[ARRAY_SIZE+1];
static bool g_bHooked[ARRAY_SIZE+1];
static int g_iParticleRef[ARRAY_SIZE+1] = {INVALID_ENT_REFERENCE, ...};
static bool g_bDisabled = false;
static int g_iPlayerSpawn, g_iRoundStart;
static float g_GameExplodeTime;

ConVar g_cvarRadius, g_cvarPower, g_cvarDamage,
       g_cvarPanicEnable, g_cvarPanicChance, g_cvarInfected,
       g_cvarRemoveCarTime, g_cvarUnloadMap;

int g_iPanicChance, g_iDamage;
float g_fRadius, g_fPower, g_fRemoveCarTime;
bool g_bPanicEnable, g_bInfected;
char g_sUnloadMap[512];

public Plugin myinfo =
{
    name = "[L4D1] Explosive Cars (Instant)",
    author = "honorcode23, Fixed: kochiurun119, HarryPotter, Adapted for L4D1 by ChatGPT",
    description = "Cars explode instantly on any hit",
    version = GETVERSION,
    url = "http://forums.alliedmods.net/showthread.php?t=138644"
};

public void OnPluginStart()
{
    g_cvarRadius           = CreateConVar("l4d_explosive_cars_radius",              "320",  "Maximum radius of the explosion", FCVAR_NOTIFY, true, 0.0);
    g_cvarPower            = CreateConVar("l4d_explosive_cars_power",               "300",  "Power of the explosion when the car explodes", FCVAR_NOTIFY, true, 0.0);
    g_cvarDamage           = CreateConVar("l4d_explosive_cars_damage",              "8",    "Damage made by the explosion", FCVAR_NOTIFY, true, 0.0);
    g_cvarPanicEnable      = CreateConVar("l4d_explosive_cars_panic",               "1",    "Should the car explosion cause a panic event? (1: Yes 0: No)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_cvarPanicChance      = CreateConVar("l4d_explosive_cars_panic_chance",        "5",    "Chance that the cars explosion might call a horde (1 / CVAR) [1: Always]", FCVAR_NOTIFY, true, 1.0);
    g_cvarInfected         = CreateConVar("l4d_explosive_cars_infected",            "1",    "Should infected trigger the car explosion? (1: Yes 0: No)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_cvarRemoveCarTime    = CreateConVar("l4d_explosive_cars_removetime",          "60",   "Time to wait before removing the exploded car in case it blocks the way. (0: Don't remove)", FCVAR_NOTIFY, true);
    g_cvarUnloadMap        = CreateConVar("l4d_explosive_cars_unload_map",          "",     "On which maps should the plugin disable itself? separate by commas (no spaces). (Example: c5m3_cemetery,c5m5_bridge)", FCVAR_NOTIFY);
    CreateConVar("l4d_explosive_cars_version", GETVERSION, "Version of the l4d Explosive Cars plugin for L4D1", FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
    AutoExecConfig(true, "l4d_explosive_cars");

    GetCvars();
    g_cvarRadius.AddChangeHook(ConVarChanged_Cvars);
    g_cvarPower.AddChangeHook(ConVarChanged_Cvars);
    g_cvarDamage.AddChangeHook(ConVarChanged_Cvars);
    g_cvarPanicEnable.AddChangeHook(ConVarChanged_Cvars);
    g_cvarPanicChance.AddChangeHook(ConVarChanged_Cvars);
    g_cvarInfected.AddChangeHook(ConVarChanged_Cvars);
    g_cvarRemoveCarTime.AddChangeHook(ConVarChanged_Cvars);
    g_cvarUnloadMap.AddChangeHook(ConVarChanged_Cvars);

    HookEvent("player_spawn",   Event_PlayerSpawn,   EventHookMode_PostNoCopy);
    HookEvent("round_start",    Event_RoundStart,    EventHookMode_PostNoCopy);
    HookEvent("round_end",      Event_RoundEnd,      EventHookMode_PostNoCopy);
}

public void OnPluginEnd()
{
    ResetPlugin();
}

void ConVarChanged_Cvars(ConVar hCvar, const char[] sOldVal, const char[] sNewVal)
{
    GetCvars();
}

void GetCvars()
{
    g_fRadius      = g_cvarRadius.FloatValue;
    g_fPower       = g_cvarPower.FloatValue;
    g_iDamage      = g_cvarDamage.IntValue;
    g_bPanicEnable = g_cvarPanicEnable.BoolValue;
    g_iPanicChance = g_cvarPanicChance.IntValue;
    g_bInfected    = g_cvarInfected.BoolValue;
    g_fRemoveCarTime = g_cvarRemoveCarTime.FloatValue;
    g_cvarUnloadMap.GetString(g_sUnloadMap, sizeof(g_sUnloadMap));
}

public void OnConfigsExecuted()
{
    GetCvars();
    g_bConfigLoaded = true;
    g_bDisabled = false;

    char sCurrentMap[64];
    GetCurrentMap(sCurrentMap, sizeof(sCurrentMap));
    if (StrContains(g_sUnloadMap, sCurrentMap) >= 0)
        g_bDisabled = true;

    if (!g_bDisabled)
    {
        PrecacheParticle(FIRE_PARTICLE);
        PrecacheParticle(EXPLOSION_PARTICLE);
        PrecacheParticle(EXPLOSION_PARTICLE3);
        PrecacheModel("sprites/muzzleflash4.vmt");
        PrecacheModel("models/props_vehicles/cara_82hatchback_wrecked.mdl");
        PrecacheModel("models/props_vehicles/cara_95sedan_wrecked.mdl");

        PrecacheSound(EXPLOSION_SOUND);
        PrecacheSound(EXPLOSION_SOUND2);
        PrecacheSound(EXPLOSION_SOUND3);
    }
}

public void OnMapStart()
{
    PrecacheModel(MODEL_GASCAN, true);
}

public void OnMapEnd()
{
    ResetPlugin();
    g_bConfigLoaded = false;
}

void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
    ResetPlugin();
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    g_GameExplodeTime = 0.0;
    if (g_iPlayerSpawn == 1 && g_iRoundStart == 0)
        CreateTimer(0.5, TimerStart);
    g_iRoundStart = 1;
}

void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    if (g_iPlayerSpawn == 0 && g_iRoundStart == 1)
        CreateTimer(0.5, TimerStart);
    g_iPlayerSpawn = 1;
}

Action TimerStart(Handle timer)
{
    ResetPlugin();
    if (g_bDisabled) return Plugin_Continue;
    FindMapCars();
    return Plugin_Continue;
}

void FindMapCars()
{
    for (int i = 1; i <= ARRAY_SIZE; i++)
    {
        g_bHooked[i] = false;
        g_bExploded[i] = false;
        g_iParticleRef[i] = INVALID_ENT_REFERENCE;
    }

    int maxEnts = GetMaxEntities();
    char classname[128], model[256];

    for (int entity = MaxClients+1; entity <= maxEnts; entity++)
    {
        if (!IsValidEntity(entity)) continue;
        if (entity <= ARRAY_SIZE && g_bHooked[entity]) continue;

        GetEdictClassname(entity, classname, sizeof(classname));
        GetEntPropString(entity, Prop_Data, "m_ModelName", model, sizeof(model));

        if (StrEqual(model, "models/props_vehicles/airport_baggage_cart2.mdl") ||
            StrEqual(model, "models/props_vehicles/generatortrailer01.mdl"))
            continue;

        bool isCar = false;
        if (strncmp(classname, "prop_physics", 12) == 0)
        {
            if (StrContains(model, "vehicle", false) != -1)
                isCar = true;
            else if (StrEqual(model, "models/props/cs_assault/forklift.mdl"))
                isCar = true;
        }
        else if (StrEqual(classname, "prop_car_alarm"))
        {
            isCar = true;
        }

        if (isCar && entity <= ARRAY_SIZE)
        {
            g_bHooked[entity] = true;
            SDKHook(entity, SDKHook_OnTakeDamagePost, OnTakeDamagePost);
        }
    }
}

public void OnEntityDestroyed(int entity)
{
    if (g_bDisabled) return;
    if (entity > 0 && entity <= ARRAY_SIZE)
    {
        int particleRef = g_iParticleRef[entity];
        if (particleRef != INVALID_ENT_REFERENCE)
        {
            int particle = EntRefToEntIndex(particleRef);
            if (particle != INVALID_ENT_REFERENCE)
                AcceptEntityInput(particle, "Kill");
            g_iParticleRef[entity] = INVALID_ENT_REFERENCE;
        }
        g_bHooked[entity] = false;
        g_bExploded[entity] = false;
    }
}

public void OnEntityCreated(int entity, const char[] classname)
{
    if (g_bDisabled || !g_bConfigLoaded)
        return;
    if (!IsValidEntityIndex(entity))
        return;
    RequestFrame(OnNextFrame, EntIndexToEntRef(entity));
}

void OnNextFrame(int entityRef)
{
    if (g_bDisabled) return;
    int entity = EntRefToEntIndex(entityRef);
    if (entity == INVALID_ENT_REFERENCE)
        return;
    if (entity > ARRAY_SIZE)
        return;
    if (g_bHooked[entity])
        return;

    char classname[15];
    GetEntityClassname(entity, classname, sizeof(classname));
    char model[256];

    if (strncmp(classname, "prop_physics", 12) == 0)
    {
        GetEntPropString(entity, Prop_Data, "m_ModelName", model, sizeof(model));
        bool isCar = (StrContains(model, "vehicle", false) != -1) ||
                     StrEqual(model, "models/props/cs_assault/forklift.mdl");
        if (isCar)
        {
            SDKHook(entity, SDKHook_OnTakeDamagePost, OnTakeDamagePost);
            g_bHooked[entity] = true;
            g_bExploded[entity] = false;
            g_iParticleRef[entity] = INVALID_ENT_REFERENCE;
        }
    }
    else if (StrEqual(classname, "prop_car_alarm"))
    {
        SDKHook(entity, SDKHook_OnTakeDamagePost, OnTakeDamagePost);
        g_bHooked[entity] = true;
        g_bExploded[entity] = false;
        g_iParticleRef[entity] = INVALID_ENT_REFERENCE;
    }
}

void OnTakeDamagePost(int victim, int attacker, int inflictor, float damage, int damagetype)
{
    if (g_bDisabled) return;
    if (victim < 0 || victim > ARRAY_SIZE) return;
    if (g_bExploded[victim]) return;

    if (inflictor > 0 && IsValidEntity(inflictor) && attacker > 0)
    {
        char attackerClass[256];
        GetEdictClassname(attacker, attackerClass, sizeof(attackerClass));

        // Если урон от заражённого и они не должны вызывать взрыв
        if (strcmp(attackerClass, "player") == 0)
        {
            if (attacker <= MaxClients && IsClientInGame(attacker) && GetClientTeam(attacker) == 3 && !g_bInfected)
                return;
        }

        // Мгновенный взрыв
        CreateTimer(0.05, Timer_ExplodeCar, EntIndexToEntRef(victim));
    }
}

Action Timer_ExplodeCar(Handle timer, any entityRef)
{
    if (g_bDisabled) return Plugin_Continue;
    int car = EntRefToEntIndex(entityRef);
    if (car == INVALID_ENT_REFERENCE) return Plugin_Continue;
    if (car < 0 || car > ARRAY_SIZE) return Plugin_Continue;
    if (g_bExploded[car]) return Plugin_Continue;

    if (g_GameExplodeTime < GetEngineTime())
    {
        g_bExploded[car] = true;
        float carPos[3];
        GetEntPropVector(car, Prop_Data, "m_vecOrigin", carPos);
        CreateExplosion(car, carPos);
        EditCar(car);
        LaunchCar(car);

        SDKUnhook(car, SDKHook_OnTakeDamagePost, OnTakeDamagePost);

        g_GameExplodeTime = GetEngineTime() + EXPLODE_INTERVAL;
    }
    return Plugin_Continue;
}

void EditCar(int car)
{
    SetEntityRenderColor(car, 51, 51, 51, 255);
    char sModel[256];
    GetEntPropString(car, Prop_Data, "m_ModelName", sModel, sizeof(sModel));
    ReplaceString(sModel, sizeof(sModel), ".mdl", "");
    Format(sModel, sizeof(sModel), "%s_wrecked.mdl", sModel);
    if (FileExists(sModel, true))
    {
        if (!IsModelPrecached(sModel))
            PrecacheModel(sModel);
        SetEntityModel(car, sModel);
    }
}

void LaunchCar(int car)
{
    float vel[3];
    GetEntPropVector(car, Prop_Data, "m_vecVelocity", vel);
    vel[0] += GetRandomFloat(50.0, 300.0);
    vel[1] += GetRandomFloat(50.0, 300.0);
    vel[2] += GetRandomFloat(1000.0, 2500.0);
    TeleportEntity(car, NULL_VECTOR, NULL_VECTOR, vel);

    CreateTimer(4.0, timerNormalVelocity, EntIndexToEntRef(car));
    if (g_fRemoveCarTime > 0.0)
        CreateTimer(g_fRemoveCarTime, timerRemoveCarFire, EntIndexToEntRef(car));
}

Action timerNormalVelocity(Handle timer, any entityRef)
{
    if (g_bDisabled) return Plugin_Continue;
    int car = EntRefToEntIndex(entityRef);
    if (car == INVALID_ENT_REFERENCE) return Plugin_Continue;

    if (IsValidEntity(car))
    {
        float zeroVel[3] = {0.0, 0.0, 0.0};
        TeleportEntity(car, NULL_VECTOR, NULL_VECTOR, zeroVel);
    }
    return Plugin_Continue;
}

Action timerRemoveCarFire(Handle timer, int ref)
{
    if (g_bDisabled) return Plugin_Continue;
    int car = EntRefToEntIndex(ref);
    if (car != INVALID_ENT_REFERENCE)
    {
        int particleRef = g_iParticleRef[car];
        if (particleRef != INVALID_ENT_REFERENCE)
        {
            int particle = EntRefToEntIndex(particleRef);
            if (particle != INVALID_ENT_REFERENCE)
                AcceptEntityInput(particle, "Kill");
            g_iParticleRef[car] = INVALID_ENT_REFERENCE;
        }
        if (IsValidEntity(car))
            AcceptEntityInput(car, "Kill");
    }
    return Plugin_Continue;
}

void CreateExplosion(int car, float carPos[3])
{
    char sRadius[16], sPower[16], sDamage[11];
    IntToString(RoundFloat(g_fRadius), sRadius, sizeof(sRadius));
    IntToString(RoundFloat(g_fPower), sPower, sizeof(sPower));
    IntToString(g_iDamage, sDamage, sizeof(sDamage));

    int exParticle = CreateEntityByName("info_particle_system");
    int exParticle3 = CreateEntityByName("info_particle_system");
    int exTrace = CreateEntityByName("info_particle_system");
    int exPhys = CreateEntityByName("env_physexplosion");

    if (IsValidEntity(exParticle))
    {
        DispatchKeyValue(exParticle, "effect_name", EXPLOSION_PARTICLE);
        DispatchSpawn(exParticle);
        ActivateEntity(exParticle);
        TeleportEntity(exParticle, carPos, NULL_VECTOR, NULL_VECTOR);
        AcceptEntityInput(exParticle, "Start");
        CreateTimer(1.5, timerDeleteParticles, EntIndexToEntRef(exParticle));
    }

    if (IsValidEntity(exParticle3))
    {
        DispatchKeyValue(exParticle3, "effect_name", EXPLOSION_PARTICLE3);
        DispatchSpawn(exParticle3);
        ActivateEntity(exParticle3);
        TeleportEntity(exParticle3, carPos, NULL_VECTOR, NULL_VECTOR);
        AcceptEntityInput(exParticle3, "Start");
        CreateTimer(1.5, timerDeleteParticles, EntIndexToEntRef(exParticle3));
    }

    if (IsValidEntity(exTrace))
    {
        DispatchKeyValue(exTrace, "effect_name", FIRE_PARTICLE);
        DispatchSpawn(exTrace);
        ActivateEntity(exTrace);
        TeleportEntity(exTrace, carPos, NULL_VECTOR, NULL_VECTOR);
        AcceptEntityInput(exTrace, "Start");
        CreateTimer(1.5, timerStop, EntIndexToEntRef(exTrace));
    }

    int exEntity = CreateEntityByName("env_explosion");
    if (IsValidEntity(exEntity))
    {
        DispatchKeyValue(exEntity, "fireballsprite", "sprites/muzzleflash4.vmt");
        DispatchKeyValue(exEntity, "iMagnitude", sDamage);
        DispatchKeyValue(exEntity, "iRadiusOverride", sRadius);
        DispatchKeyValue(exEntity, "spawnflags", "828");
        DispatchSpawn(exEntity);
        TeleportEntity(exEntity, carPos, NULL_VECTOR, NULL_VECTOR);
        AcceptEntityInput(exEntity, "Explode");
        CreateTimer(1.5, timerDeleteParticles, EntIndexToEntRef(exEntity));
    }

    if (IsValidEntity(exPhys))
    {
        DispatchKeyValue(exPhys, "radius", sRadius);
        DispatchKeyValue(exPhys, "magnitude", sPower);
        DispatchSpawn(exPhys);
        TeleportEntity(exPhys, carPos, NULL_VECTOR, NULL_VECTOR);
        AcceptEntityInput(exPhys, "Explode");
        CreateTimer(1.5, timerDeleteParticles, EntIndexToEntRef(exPhys));
    }

    CreateFireOnGround(car, carPos);

    switch (GetRandomInt(1, 3))
    {
        case 1: EmitSoundToAll(EXPLOSION_SOUND);
        case 2: EmitSoundToAll(EXPLOSION_SOUND2);
        case 3: EmitSoundToAll(EXPLOSION_SOUND3);
    }

    if (g_bPanicEnable && GetRandomInt(1, g_iPanicChance) == 1)
    {
        PanicEvent();
        PrintToChatAll("\x04[SM] \x03The car exploded and the infected heard the noise!");
    }

    float survivorPos[3];
    for (int player = 1; player <= MaxClients; player++)
    {
        if (!IsClientInGame(player) || !IsPlayerAlive(player) || GetClientTeam(player) != 2)
            continue;

        GetClientAbsOrigin(player, survivorPos);
        if (GetVectorDistance(carPos, survivorPos) <= g_fRadius)
        {
            float dir[3];
            MakeVectorFromPoints(carPos, survivorPos, dir);
            NormalizeVector(dir, dir);
            ScaleVector(dir, g_fPower);
            TeleportEntity(player, NULL_VECTOR, NULL_VECTOR, dir);
        }
    }
}

Action timerStop(Handle timer, int ref)
{
    int entity = EntRefToEntIndex(ref);
    if (entity != INVALID_ENT_REFERENCE)
    {
        AcceptEntityInput(entity, "Stop");
        AcceptEntityInput(entity, "Kill");
    }
    return Plugin_Continue;
}

Action timerDeleteParticles(Handle timer, int ref)
{
    int entity = EntRefToEntIndex(ref);
    if (entity != INVALID_ENT_REFERENCE)
        AcceptEntityInput(entity, "Kill");
    return Plugin_Continue;
}

int PrecacheParticle(const char[] sEffectName)
{
    static int table = INVALID_STRING_TABLE;
    if (table == INVALID_STRING_TABLE)
        table = FindStringTable("ParticleEffectNames");

    int index = FindStringIndex(table, sEffectName);
    if (index == INVALID_STRING_INDEX)
    {
        bool save = LockStringTables(false);
        AddToStringTable(table, sEffectName);
        LockStringTables(save);
        index = FindStringIndex(table, sEffectName);
    }
    return index;
}

void PanicEvent()
{
    ServerCommand("director_force_panic_event");
}

bool IsValidEntityIndex(int entity)
{
    return (MaxClients+1 <= entity <= GetMaxEntities());
}

void ResetPlugin()
{
    g_iRoundStart = 0;
    g_iPlayerSpawn = 0;
}

void CreateFireOnGround(int car, float carPos[3])
{
    int entity = CreateEntityByName("prop_physics");
    if (IsValidEntity(entity))
    {
        SetEntityModel(entity, MODEL_GASCAN);
        SDKHook(entity, SDKHook_SetTransmit, OnTransmitExplosive);

        int flags = GetEntityFlags(entity);
        SetEntityFlags(entity, flags | FL_EDICT_DONTSEND);
        SetEntityRenderMode(entity, RENDER_TRANSALPHAADD);
        SetEntityRenderColor(entity, 0, 0, 0, 0);
        SetEntProp(entity, Prop_Send, "m_CollisionGroup", 1, 1);
        SetEntityMoveType(entity, MOVETYPE_NONE);
        TeleportEntity(entity, carPos, NULL_VECTOR, NULL_VECTOR);
        DispatchSpawn(entity);
        SetEntPropEnt(entity, Prop_Data, "m_hPhysicsAttacker", car);
        SetEntPropFloat(entity, Prop_Data, "m_flLastPhysicsInfluenceTime", GetGameTime());
        AcceptEntityInput(entity, "Break");
    }
}

Action OnTransmitExplosive(int entity, int client)
{
    return Plugin_Handled;
}