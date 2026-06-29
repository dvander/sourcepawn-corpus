// vim: set ai et ts=4 sw=4 syntax=sourcepawn :

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>

#define PLUGIN_VERSION "1.32"
#define VERSION_CVAR_NAME "sm_building_repair_version"

public Plugin:myinfo = 
{
    name = "Building Repair",
    author = "Sneakret <sneakret@sneakret.com>",
    description =
        "Dispensers heal buildings and refill sentry ammo.",
    version = PLUGIN_VERSION,
    url = "http://www.sneakret.com"
};


//// Entity Class Names
#define CLASSNAME_SENTRY "obj_sentrygun"
#define CLASSNAME_DISPENSER "obj_dispenser"
#define CLASSNAME_TELEPORTER "obj_teleporter"

//// Global Handles

new Handle:MaxDispenserDistanceCVar = INVALID_HANDLE;
new Handle:TickIntervalCVar = INVALID_HANDLE;

new Handle:RepairSentryCVar = INVALID_HANDLE;
new Handle:RepairDispenserCVar = INVALID_HANDLE;
new Handle:RepairTeleporterCVar = INVALID_HANDLE;

new Handle:AntiSapSentryCVar = INVALID_HANDLE;
new Handle:AntiSapDispenserCVar = INVALID_HANDLE;
new Handle:AntiSapTeleporterCVar = INVALID_HANDLE;

new Handle:RepairRatesCVar = INVALID_HANDLE;
new Handle:ShellRefillRatesCVar = INVALID_HANDLE;
new Handle:RocketRefillRatesCVar = INVALID_HANDLE;

new Handle:RepairTimer = INVALID_HANDLE;


//// Cached Console Variables

new MaxDispenserDistance;
new Float:TickInterval;

new bool:IsSentryRepairEnabled;
new bool:IsDispenserRepairEnabled;
new bool:IsTeleporterRepairEnabled;

new bool:IsSentryAntiSapperEnabled;
new bool:IsDispenserAntiSapperEnabled;
new bool:IsTeleporterAntiSapperEnabled;

new RepairRateByDispenserLevel[3];
new SentryShellRefillRateByDispenserLevel[3];
new SentryRocketRefillRateByDispenserLevel[3];


//// Other Global Variables

new MaxSentryShellsByLevel[] = { 150, 200, 200 };


//// Global Constants

const MaxSentryRockets = 20;


//// Event Handlers

public OnPluginStart()
{
    CreateCVars();
    InitializeCachedValues();
    HookCVarChanges();
    StartRepairTimer();
}

public OnRepairRateChange(
    Handle:convar,
    const String:oldValue[],
    const String:newValue[])
{
    CacheDelimitedValues(
        RepairRateByDispenserLevel,
        RepairRatesCVar,
        3);
}

public OnSentryShellRefillRateChange(
    Handle:convar,
    const String:oldValue[],
    const String:newValue[])
{
    CacheDelimitedValues(
        SentryShellRefillRateByDispenserLevel,
        ShellRefillRatesCVar,
        3);
}

public OnSentryRocketRefillRateChange(
    Handle:convar,
    const String:oldValue[],
    const String:newValue[])
{
    CacheDelimitedValues(
        SentryRocketRefillRateByDispenserLevel,
        RocketRefillRatesCVar,
        3);
}

public OnMaxDispenserDistanceChange(
    Handle:convar,
    const String:oldValue[],
    const String:newValue[])
{
    MaxDispenserDistance = GetConVarInt(MaxDispenserDistanceCVar);
}

public OnRepairSentryChange(
    Handle:convar,
    const String:oldValue[],
    const String:newValue[])
{
    IsSentryRepairEnabled = GetConVarBool(RepairSentryCVar);
}

public OnRepairDispenserChange(
    Handle:convar,
    const String:oldValue[],
    const String:newValue[])
{
    IsDispenserRepairEnabled = GetConVarBool(RepairDispenserCVar);
}

public OnRepairTeleporterChange(
    Handle:convar,
    const String:oldValue[],
    const String:newValue[])
{
    IsTeleporterRepairEnabled = GetConVarBool(RepairTeleporterCVar);
}

public OnAntiSapSentryChange(
    Handle:convar,
    const String:oldValue[],
    const String:newValue[])
{
    IsSentryAntiSapperEnabled = GetConVarBool(AntiSapSentryCVar);
}

public OnAntiSapDispenserChange(
    Handle:convar,
    const String:oldValue[],
    const String:newValue[])
{
    IsDispenserAntiSapperEnabled =
        GetConVarBool(AntiSapDispenserCVar);
}

public OnAntiSapTeleporterChange(
    Handle:convar,
    const String:oldValue[],
    const String:newValue[])
{
    IsTeleporterAntiSapperEnabled =
        GetConVarBool(AntiSapTeleporterCVar);
}

public OnTickIntervalChange(
    Handle:convar,
    const String:oldValue[],
    const String:newValue[])
{
    TickInterval = GetConVarFloat(TickIntervalCVar);

    // Kill the old timer that was scheduled with the old interval.
    KillTimer(RepairTimer);
    StartRepairTimer();
}

public Action:OnTick(Handle:timer)
{
    ProcessDispensers();
    return Plugin_Continue;
}


//// Utility Functions

StartRepairTimer()
{
    RepairTimer = CreateTimer(
        TickInterval,
        OnTick,
        _,
        TIMER_REPEAT);
}

CreateCVars()
{
    CreateConVar(
        VERSION_CVAR_NAME,
        PLUGIN_VERSION,
        "Building Repair plugin version.",
        FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);

    MaxDispenserDistanceCVar = CreateConVar(
        "br_max_distance",
        "150",
        "Maximum distance from which a dispenser can repair/refill buildings.",
        FCVAR_PLUGIN);

    RepairSentryCVar = CreateConVar(
        "br_repair_sentry",
        "1",
        "Whether a dispenser will repair nearby sentries.",
        FCVAR_PLUGIN);

    RepairDispenserCVar = CreateConVar(
        "br_repair_dispenser",
        "0",
        "Whether a dispenser will repair other nearby dispensers.",
        FCVAR_PLUGIN);

    RepairTeleporterCVar = CreateConVar(
        "br_repair_teleporter",
        "0",
        "Whether a dispenser will repair nearby teleporters.",
        FCVAR_PLUGIN);

    AntiSapSentryCVar = CreateConVar(
        "br_antisap_sentry",
        "1",
        "Whether a dispenser will fight sappers on nearby sentries.",
        FCVAR_PLUGIN);

    AntiSapDispenserCVar = CreateConVar(
        "br_antisap_dispenser",
        "0",
        "Whether a dispenser will fight sappers on other nearby dispensers.",
        FCVAR_PLUGIN);

    AntiSapTeleporterCVar = CreateConVar(
        "br_antisap_teleporter",
        "1",
        "Whether a dispenser will fight sappers on nearby teleporters.",
        FCVAR_PLUGIN);

    TickIntervalCVar = CreateConVar(
        "br_tick_seconds",
        "0.1",
        "The interval between ticks, in seconds.",
        FCVAR_PLUGIN);

    RepairRatesCVar = CreateConVar(
        "br_repair_rates",
        "5,10,20",
        "Health to add to buildings per tick, ordered by dispenser level.",
        FCVAR_PLUGIN);

    ShellRefillRatesCVar = CreateConVar(
        "br_shell_refill_rates",
        "1,2,4",
        "Sentry shells to refill every tick, ordered by dispenser level.",
        FCVAR_PLUGIN);

    RocketRefillRatesCVar = CreateConVar(
        "br_rocket_refill_rates",
        "0,0,0",
        "Sentry rockets to refill every tick, ordered by dispenser level.",
        FCVAR_PLUGIN);
}

InitializeCachedValues()
{
    MaxDispenserDistance = GetConVarInt(MaxDispenserDistanceCVar);
    IsSentryRepairEnabled = GetConVarBool(RepairSentryCVar);
    IsDispenserRepairEnabled = GetConVarBool(RepairDispenserCVar);
    IsTeleporterRepairEnabled = GetConVarBool(RepairTeleporterCVar);
    IsSentryAntiSapperEnabled = GetConVarBool(AntiSapSentryCVar);
    IsDispenserAntiSapperEnabled =
        GetConVarBool(AntiSapDispenserCVar);
    IsTeleporterAntiSapperEnabled =
        GetConVarBool(AntiSapTeleporterCVar);
    TickInterval = GetConVarFloat(TickIntervalCVar);

    CacheDelimitedValues(
        RepairRateByDispenserLevel,
        RepairRatesCVar,
        3);
    CacheDelimitedValues(
        SentryShellRefillRateByDispenserLevel,
        ShellRefillRatesCVar,
        3);
    CacheDelimitedValues(
        SentryRocketRefillRateByDispenserLevel,
        RocketRefillRatesCVar,
        3);
}

HookCVarChanges()
{
    HookConVarChange(RepairRatesCVar, OnRepairRateChange);
    HookConVarChange(ShellRefillRatesCVar, OnSentryShellRefillRateChange);
    HookConVarChange(RocketRefillRatesCVar, OnSentryRocketRefillRateChange);
    HookConVarChange(MaxDispenserDistanceCVar, OnMaxDispenserDistanceChange);
    HookConVarChange(RepairSentryCVar, OnRepairSentryChange);
    HookConVarChange(RepairDispenserCVar, OnRepairDispenserChange);
    HookConVarChange(RepairTeleporterCVar, OnRepairTeleporterChange);
    HookConVarChange(AntiSapSentryCVar, OnAntiSapSentryChange);
    HookConVarChange(AntiSapDispenserCVar, OnAntiSapDispenserChange);
    HookConVarChange(AntiSapTeleporterCVar, OnAntiSapTeleporterChange);

    // Hook the change event for TickIntervalCVar so we can reset
    // the timer when the interval is changed.
    HookConVarChange(
        TickIntervalCVar,
        OnTickIntervalChange);
}

FindDispenser(previousDispenserEntity)
{
    return FindEntityByClassname(previousDispenserEntity, "obj_dispenser");
}

CacheDelimitedValues(cachedValues[], Handle:cvarHandle, valueCount)
{
    new String:cvarString[21];
    GetConVarString(cvarHandle, cvarString, sizeof(cvarString));
    new String:stringValues[valueCount][6];
    ExplodeString(cvarString, ",", stringValues, valueCount, 6);
    for (new level = 1; level <= valueCount; level++)
    {
        cachedValues[level - 1] =
            StringToInt(stringValues[level - 1], 10);
    }
}

GetEntLevel(entity)
{
    return GetEntProp(entity, Prop_Send, "m_iUpgradeLevel", 1);
}

GetEntTeam(entity)
{
    return GetEntProp(entity, Prop_Send, "m_iTeamNum", 1);
}

GetEntLocation(entity, Float:positionVector[3])
{
    return GetEntPropVector(entity, Prop_Send, "m_vecOrigin", positionVector);
}

GetEntHealth(entity)
{
    return GetEntProp(entity, Prop_Send, "m_iHealth");
}

GetEntMaxHealth(entity)
{
    return GetEntProp(entity, Prop_Send, "m_iMaxHealth");
}

AddEntHealth(entity, amount)
{
    SetVariantInt(amount);
    AcceptEntityInput(entity, "AddHealth");
}

bool:IsEntBeingBuilt(entity)
{
    return (GetEntProp(entity, Prop_Send, "m_bBuilding", 1) == 1);
}

bool:IsEntBeingPlaced(entity)
{
    return (GetEntProp(entity, Prop_Send, "m_bPlacing", 1) == 1);
}

bool:IsEntBeingSapped(entity)
{
    return (GetEntProp(entity, Prop_Send, "m_bHasSapper", 1) == 1);
}


//// Business Logic

ProcessDispensers()
{
    // Loop through the dispensers.
    for (new dispenserEntity = FindDispenser(-1);
        dispenserEntity != -1;
        dispenserEntity = FindDispenser(dispenserEntity))
    {
        // Skip dispensers that are being built, placed, or sapped.
        if (IsEntBeingBuilt(dispenserEntity)
            || IsEntBeingPlaced(dispenserEntity)
            || IsEntBeingSapped(dispenserEntity))
        {
            continue;
        }

        ProcessDispenser(dispenserEntity);
    }
}

ProcessDispenser(dispenserEntity)
{
    new dispenserTeam = GetEntTeam(dispenserEntity);
    new dispenserLevel = GetEntLevel(dispenserEntity);
    decl Float:dispenserLocation[3];
    GetEntLocation(dispenserEntity, dispenserLocation);
    ProcessOtherBuildings(
        dispenserEntity,
        dispenserLevel,
        dispenserTeam,
        dispenserLocation,
        CLASSNAME_SENTRY);
    ProcessOtherBuildings(
        dispenserEntity,
        dispenserLevel,
        dispenserTeam,
        dispenserLocation,
        CLASSNAME_DISPENSER);
    ProcessOtherBuildings(
        dispenserEntity,
        dispenserLevel,
        dispenserTeam,
        dispenserLocation,
        CLASSNAME_TELEPORTER);
}

ProcessOtherBuildings(
    dispenserEntity,
    dispenserLevel,
    dispenserTeam,
    Float:dispenserLocation[3],
    String:otherBuildingClassname[])
{
    new bool:isSentry =
        (strcmp(otherBuildingClassname, CLASSNAME_SENTRY) == 0);
    new bool:isDispenser =
        (strcmp(otherBuildingClassname, CLASSNAME_DISPENSER) == 0);
    new bool:isTeleporter =
        (strcmp(otherBuildingClassname, CLASSNAME_TELEPORTER) == 0);

    new otherBuildingEntity = -1;
    for (
        otherBuildingEntity =
            FindEntityByClassname(otherBuildingEntity, otherBuildingClassname);
        otherBuildingEntity != -1;
        otherBuildingEntity =
            FindEntityByClassname(otherBuildingEntity, otherBuildingClassname))
    {
        if (dispenserEntity == otherBuildingEntity)
        {
            // The other building IS the dispenser.
            // Skip it. (Don't let dispensers heal themselves.)
            continue;
        }

        new otherBuildingTeam = GetEntTeam(otherBuildingEntity);
        new Float:otherBuildingLocation[3];
        GetEntLocation(otherBuildingEntity, otherBuildingLocation);

        new Float:actualDistance =
            GetVectorDistance(dispenserLocation, otherBuildingLocation);
        if (actualDistance > MaxDispenserDistance)
        {
            // The other building is too far from the dispenser.
            // Skip it.
            continue;
        }

        if (otherBuildingTeam != dispenserTeam)
        {
            // The other building is on a different team than the dispenser.
            // Skip it.
            continue;
        }

        if (IsEntBeingBuilt(otherBuildingEntity)
            || IsEntBeingPlaced(otherBuildingEntity))
        {
            // The other building is being built or placed.
            // Skip it.
            continue;
        }

        // I'd really like to define a ProcessBuilding functag:
        //   functag public ProcessBuilding(entity, dispenserLevel);
        // then pass a callback to the appropriate building's function, but as
        // far as I can tell there's no way to invoke a callback from a
        // SourcePawn script... so I'll just do if/else/if/else/if...
        if (isSentry)
        {
            RepairBuilding(
                otherBuildingEntity,
                dispenserLevel,
                IsSentryRepairEnabled,
                IsSentryAntiSapperEnabled);
            RefillSentryShells(otherBuildingEntity, dispenserLevel);
            RefillSentryRockets(otherBuildingEntity, dispenserLevel);
        }
        else if (isDispenser)
        {
            RepairBuilding(
                otherBuildingEntity,
                dispenserLevel,
                IsDispenserRepairEnabled,
                IsDispenserAntiSapperEnabled);
        }
        else if (isTeleporter)
        {
            RepairBuilding(
                otherBuildingEntity,
                dispenserLevel,
                IsTeleporterRepairEnabled,
                IsTeleporterAntiSapperEnabled);
        }
    }
}

RepairBuilding(
    buildingEntity,
    dispenserLevel,
    bool:isRepairEnabled,
    bool:isAntiSapperEnabled)
{
    new buildingMaxHealth = GetEntMaxHealth(buildingEntity);
    new buildingHealth = GetEntHealth(buildingEntity);

    if (buildingHealth >= buildingMaxHealth)
    {
        // This building is already at full health.
        // Skip it.
        return;
    }

    if (dispenserLevel < 1)
    {
        // The dispenser level is below 1. This is unexpected.
        // Skip the building.
        // TODO: Log this.
        return;
    }

    if (dispenserLevel > 3)
    {
        // The dispenser level is above 3. This is unexpected.
        // Clip it to 3 for the purpose of establishing the repair rate.
        dispenserLevel = 3;
        // TODO: Log this.
    }

    new healthIncrement = RepairRateByDispenserLevel[dispenserLevel - 1];

    if (IsEntBeingSapped(buildingEntity))
    {
        // The building is being sapped.
        if (isAntiSapperEnabled)
        {
            // Anti-sapper is enabled.
            // Repair the building at one fifth normal speed.
            healthIncrement /= 5;
        }
        else
        {
            // Anti-sapper is disabled.
            // Skip the building.
            return;
        }
    }
    else if (!isRepairEnabled)
    {
        // The building is not being sapped, but repair is disabled.
        // Skip the building.
        return;
    }

    if ((buildingHealth + healthIncrement) > buildingMaxHealth)
    {
        // The increase in the building's health would exceed its maximum
        // health.
        // Clip the increment to the amount necessary to reach maximum health.
        healthIncrement = buildingMaxHealth - buildingHealth;
    }

    AddEntHealth(buildingEntity, healthIncrement);
}

RefillSentryShells(sentryEntity, dispenserLevel)
{
    new sentryLevel = GetEntLevel(sentryEntity);
    new shells = GetEntProp(sentryEntity, Prop_Send, "m_iAmmoShells");
    shells += SentryShellRefillRateByDispenserLevel[dispenserLevel - 1];
    if (shells > MaxSentryShellsByLevel[sentryLevel - 1])
    {
        shells = MaxSentryShellsByLevel[sentryLevel - 1];
    }

    SetEntProp(sentryEntity, Prop_Send, "m_iAmmoShells", shells);
}

RefillSentryRockets(sentryEntity, dispenserLevel)
{
    new sentryLevel = GetEntLevel(sentryEntity);
    if (sentryLevel < 3)
    {
        // The sentry is below level 3, so it doesn't have rockets.
        return;
    }

    new sentryRockets = GetEntProp(sentryEntity, Prop_Send, "m_iAmmoRockets");
    sentryRockets += SentryRocketRefillRateByDispenserLevel[dispenserLevel - 1];
    if (sentryRockets > MaxSentryRockets)
    {
        sentryRockets = MaxSentryRockets;
    }

    SetEntProp(sentryEntity, Prop_Send, "m_iAmmoRockets", sentryRockets);
}
