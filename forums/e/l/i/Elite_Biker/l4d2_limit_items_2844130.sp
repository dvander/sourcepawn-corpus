#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION  "1.2"
#define MEDKIT_SAFEROOM_RADIUS 400.0

// Models for removable prop_physics entities
#define MODEL_GASCAN    "models/props_junk/gascan001a.mdl"
#define MODEL_PROPANE   "models/props_junk/propanecanister001a.mdl"
#define MODEL_OXYGEN    "models/props_equipment/oxygentank01.mdl"
#define MODEL_FIREWORKS "models/props_junk/explosive_box001.mdl"

public Plugin myinfo =
{
    name        = "[L4D2] Limit Item Spawns (All Modes)",
    author      = "Ferks-FK (Touched by EliteBiker)",
    description = "Limits the number of item spawns on the map across Campaign, Versus, and Scavenge",
    version     = PLUGIN_VERSION,
    url         = ""
};

ConVar g_cvEnable;
ConVar g_cvDebug;
ConVar g_cvMaxMolotov;
ConVar g_cvMaxPipeBomb;
ConVar g_cvMaxPills;
ConVar g_cvMaxAdrenaline;
ConVar g_cvMaxMedkitInside;
ConVar g_cvMaxMedkitOutside;
ConVar g_cvMaxDefibrillator;
ConVar g_cvMaxBileJar;
ConVar g_cvMaxGascan;
ConVar g_cvMaxPropane;
ConVar g_cvMaxOxygen;
ConVar g_cvMaxFireworks;

bool   g_bEnabled;
bool   g_bDebug;
bool   g_bLimitedThisRound;

// Tracked timers to prevent overlapping executions
Handle g_hMapTimer;
Handle g_hCansTimerShort;
Handle g_hCansTimerLong;

public void OnPluginStart()
{
    CreateConVar("l4d2_limit_items_version", PLUGIN_VERSION, "Plugin version", FCVAR_NOTIFY | FCVAR_DONTRECORD);

    g_cvEnable           = CreateConVar("l4d2_limit_items_enable",        "1",  "Enable plugin (1 = On / 0 = Off)", FCVAR_NOTIFY);
    g_cvDebug            = CreateConVar("l4d2_limit_items_debug",         "0",  "Enable debug mode - registers sm_listitems command (1 = On / 0 = Off)", FCVAR_NOTIFY);
    g_cvMaxMolotov       = CreateConVar("l4d2_limit_items_molotov",       "2",  "Max molotov spawns (-1 = unlimited)", FCVAR_NOTIFY);
    g_cvMaxPipeBomb      = CreateConVar("l4d2_limit_items_pipebomb",      "2",  "Max pipe bomb spawns (-1 = unlimited)", FCVAR_NOTIFY);
    g_cvMaxPills         = CreateConVar("l4d2_limit_items_pills",         "4",  "Max pain pills spawns (-1 = unlimited)", FCVAR_NOTIFY);
    g_cvMaxAdrenaline    = CreateConVar("l4d2_limit_items_adrenaline",    "-1", "Max adrenaline spawns (-1 = unlimited)", FCVAR_NOTIFY);
    g_cvMaxMedkitInside  = CreateConVar("l4d2_limit_items_medkit_inside",  "-1", "Max medkits inside the starting saferoom (-1 = unlimited)", FCVAR_NOTIFY);
    g_cvMaxMedkitOutside = CreateConVar("l4d2_limit_items_medkit_outside", "-1", "Max medkits outside the starting saferoom (-1 = unlimited)", FCVAR_NOTIFY);
    g_cvMaxDefibrillator = CreateConVar("l4d2_limit_items_defibrillator", "-1", "Max defibrillator spawns (-1 = unlimited)", FCVAR_NOTIFY);
    g_cvMaxBileJar       = CreateConVar("l4d2_limit_items_bilejar",       "-1", "Max bile jar spawns (-1 = unlimited)", FCVAR_NOTIFY);
    g_cvMaxGascan        = CreateConVar("l4d2_limit_items_gascan",        "-1", "Max gascans on the map (-1 = unlimited)", FCVAR_NOTIFY);
    g_cvMaxPropane       = CreateConVar("l4d2_limit_items_propane",       "-1", "Max propane tanks on the map (-1 = unlimited)", FCVAR_NOTIFY);
    g_cvMaxOxygen        = CreateConVar("l4d2_limit_items_oxygen",        "-1", "Max oxygen tanks on the map (-1 = unlimited)", FCVAR_NOTIFY);
    g_cvMaxFireworks     = CreateConVar("l4d2_limit_items_fireworks",     "-1", "Max fireworks on the map (-1 = unlimited)", FCVAR_NOTIFY);

    g_cvEnable.AddChangeHook(OnCvarChanged);
    g_cvDebug.AddChangeHook(OnCvarChanged);
    g_cvMaxMolotov.AddChangeHook(OnCvarChanged);
    g_cvMaxPipeBomb.AddChangeHook(OnCvarChanged);
    g_cvMaxPills.AddChangeHook(OnCvarChanged);
    g_cvMaxAdrenaline.AddChangeHook(OnCvarChanged);
    g_cvMaxMedkitInside.AddChangeHook(OnCvarChanged);
    g_cvMaxMedkitOutside.AddChangeHook(OnCvarChanged);
    g_cvMaxDefibrillator.AddChangeHook(OnCvarChanged);
    g_cvMaxBileJar.AddChangeHook(OnCvarChanged);
    g_cvMaxGascan.AddChangeHook(OnCvarChanged);
    g_cvMaxPropane.AddChangeHook(OnCvarChanged);
    g_cvMaxOxygen.AddChangeHook(OnCvarChanged);
    g_cvMaxFireworks.AddChangeHook(OnCvarChanged);

    AutoExecConfig(true, "l4d2_limit_items");

    // Unified hooks for all gamemodes
    HookEvent("round_start",          Event_RoundStart,  EventHookMode_PostNoCopy); // Campaign/Survival
    HookEvent("versus_round_start",   Event_RoundStart,  EventHookMode_PostNoCopy); // Versus
    HookEvent("scavenge_round_start", Event_RoundStart,  EventHookMode_PostNoCopy); // Scavenge
    HookEvent("player_spawn",         Event_PlayerSpawn, EventHookMode_PostNoCopy);

    GetCvars();
}

void GetCvars()
{
    g_bEnabled = g_cvEnable.BoolValue;
    g_bDebug   = g_cvDebug.BoolValue;

    if( g_bDebug )
        RegAdminCmd("sm_listitems", CmdListItems, ADMFLAG_ROOT, "List all active item spawns on the map with coordinates");
}

public void OnCvarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    GetCvars();
}

public void OnPluginEnd()
{
    ClearTimers();
}

public void OnMapEnd()
{
    ClearTimers();
    g_bLimitedThisRound = false;
}

void ClearTimers()
{
    delete g_hMapTimer;
    delete g_hCansTimerShort;
    delete g_hCansTimerLong;
}

// Handles round_start, versus_round_start, and scavenge_round_start safely
public void Event_RoundStart(Event hEvent, const char[] name, bool dontBroadcast)
{
    g_bLimitedThisRound = false;
    ClearTimers();

    g_hMapTimer       = CreateTimer(1.0,  Timer_LimitItems);
    g_hCansTimerShort = CreateTimer(1.0,  Timer_RemoveCans, _, TIMER_FLAG_NO_MAPCHANGE);
    g_hCansTimerLong  = CreateTimer(10.0, Timer_RemoveCans, _, TIMER_FLAG_NO_MAPCHANGE);
}

public void Event_PlayerSpawn(Event hEvent, const char[] name, bool dontBroadcast)
{
    if( g_bLimitedThisRound || !g_bEnabled )
        return;

    g_bLimitedThisRound = true;
    ClearTimers();
    
    g_hMapTimer       = CreateTimer(1.0, Timer_LimitItems);
    g_hCansTimerShort = CreateTimer(1.0, Timer_RemoveCans, _, TIMER_FLAG_NO_MAPCHANGE);
}

Action Timer_LimitItems(Handle timer)
{
    g_hMapTimer = null;
    g_bLimitedThisRound = true;

    if( !g_bEnabled )
        return Plugin_Continue;

    LimitSpawns("weapon_molotov_spawn",       g_cvMaxMolotov.IntValue,       "Molotov");
    LimitSpawns("weapon_pipe_bomb_spawn",     g_cvMaxPipeBomb.IntValue,      "Pipe Bomb");
    LimitSpawns("weapon_pain_pills_spawn",    g_cvMaxPills.IntValue,         "Pain Pills");
    LimitSpawns("weapon_adrenaline_spawn",    g_cvMaxAdrenaline.IntValue,    "Adrenaline");
    LimitSpawns("weapon_defibrillator_spawn", g_cvMaxDefibrillator.IntValue, "Defibrillator");
    LimitSpawns("weapon_vomitjar_spawn",      g_cvMaxBileJar.IntValue,       "Bile Jar");

    LimitMedkitsInStartSaferoom(g_cvMaxMedkitInside.IntValue, g_cvMaxMedkitOutside.IntValue);

    return Plugin_Continue;
}

Action Timer_RemoveCans(Handle timer)
{
    if (timer == g_hCansTimerShort) g_hCansTimerShort = null;
    if (timer == g_hCansTimerLong)  g_hCansTimerLong = null;

    if( !g_bEnabled )
        return Plugin_Stop;

    LimitProps(MODEL_GASCAN,    g_cvMaxGascan.IntValue,    "Gascan");
    LimitProps(MODEL_PROPANE,   g_cvMaxPropane.IntValue,   "Propane");
    LimitProps(MODEL_OXYGEN,    g_cvMaxOxygen.IntValue,    "Oxygen");
    LimitProps(MODEL_FIREWORKS, g_cvMaxFireworks.IntValue, "Fireworks");

    return Plugin_Stop;
}

void LimitProps(const char[] model, int maxAllowed, const char[] label)
{
    if( maxAllowed < 0 )
        return;

    ArrayList hList = new ArrayList();

    int ent = -1;
    while( (ent = FindEntityByClassname(ent, "prop_physics")) != -1 )
    {
        if( !IsValidEdict(ent) )
            continue;

        if( GetEntProp(ent, Prop_Send, "m_isCarryable", 1) < 1 )
            continue;

        char entModel[PLATFORM_MAX_PATH];
        GetEntPropString(ent, Prop_Data, "m_ModelName", entModel, sizeof(entModel));

        if( strcmp(entModel, model, false) == 0 )
            hList.Push(ent);
    }

    int total = hList.Length;

    if( total > maxAllowed )
    {
        for( int i = maxAllowed; i < total; i++ )
        {
            int e = hList.Get(i);
            if( IsValidEntity(e) )
                RemoveEntity(e);
        }

        LogMessage("[L4D2 Limit Items] %s: found %d, limit %d, removed %d", label, total, maxAllowed, total - maxAllowed);
    }

    delete hList;
}

void LimitSpawns(const char[] classname, int maxAllowed, const char[] label)
{
    if( maxAllowed < 0 )
        return;

    ArrayList hList = new ArrayList();

    int ent = -1;
    while( (ent = FindEntityByClassname(ent, classname)) != -1 )
        hList.Push(ent);

    int total = hList.Length;

    if( total > maxAllowed )
    {
        for( int i = maxAllowed; i < total; i++ )
        {
            int e = hList.Get(i);
            if( IsValidEntity(e) )
                RemoveEntity(e);
        }

        LogMessage("[L4D2 Limit Items] %s: found %d, limit %d, removed %d", label, total, maxAllowed, total - maxAllowed);
    }

    delete hList;
}

bool FindSurvivorStart(float output[3])
{
    int iEntityCount = GetEntityCount();
    char classname[128];

    for( int i = 0; i <= iEntityCount; i++ )
    {
        if( !IsValidEntity(i) )
            continue;

        GetEdictClassname(i, classname, sizeof(classname));

        if( StrEqual(classname, "prop_door_rotating_checkpoint") )
        {
            if( GetEntProp(i, Prop_Data, "m_bLocked") == 1 )
            {
                GetEntPropVector(i, Prop_Data, "m_vecAbsOrigin", output);
                return true;
            }
        }
    }

    for( int i = 0; i <= iEntityCount; i++ )
    {
        if( !IsValidEntity(i) )
            continue;

        GetEdictClassname(i, classname, sizeof(classname));

        if( StrEqual(classname, "info_survivor_position") )
        {
            GetEntPropVector(i, Prop_Data, "m_vecAbsOrigin", output);
            return true;
        }
    }

    return false;
}

void LimitMedkitsInStartSaferoom(int maxInside, int maxOutside)
{
    if( maxInside < 0 && maxOutside < 0 )
        return;

    float startPos[3];
    if( !FindSurvivorStart(startPos) )
    {
        LogMessage("[L4D2 Limit Items] Medkit: could not find survivor start, skipping.");
        return;
    }

    float nearestPos[3];
    float nearestDist = -1.0;
    bool  foundNearest = false;

    int ent = -1;
    while( (ent = FindEntityByClassname(ent, "weapon_first_aid_kit_spawn")) != -1 )
    {
        float pos[3];
        GetEntPropVector(ent, Prop_Data, "m_vecAbsOrigin", pos);
        float dist = GetVectorDistance(startPos, pos);

        if( !foundNearest || dist < nearestDist )
        {
            nearestDist  = dist;
            nearestPos   = pos;
            foundNearest = true;
        }
    }

    if( !foundNearest )
        return;

    ArrayList hInsideEnts  = new ArrayList();
    ArrayList hInsideDists = new ArrayList();
    ArrayList hOutsideEnts = new ArrayList();
    ArrayList hOutsideDists = new ArrayList();

    ent = -1;
    while( (ent = FindEntityByClassname(ent, "weapon_first_aid_kit_spawn")) != -1 )
    {
        float pos[3];
        GetEntPropVector(ent, Prop_Data, "m_vecAbsOrigin", pos);
        float dist = GetVectorDistance(nearestPos, pos);

        if( dist <= MEDKIT_SAFEROOM_RADIUS )
        {
            hInsideEnts.Push(ent);
            hInsideDists.Push(view_as<int>(dist));
        }
        else
        {
            hOutsideEnts.Push(ent);
            hOutsideDists.Push(view_as<int>(dist));
        }
    }

    int removedOutside  = 0;
    int removedInside   = 0;
    int totalInside     = hInsideEnts.Length;
    int totalOutside    = hOutsideEnts.Length;

    for( int i = 0; i < totalInside - 1; i++ )
    {
        for( int j = i + 1; j < totalInside; j++ )
        {
            float di = view_as<float>(hInsideDists.Get(i));
            float dj = view_as<float>(hInsideDists.Get(j));
            if( dj < di )
            {
                int   ei = hInsideEnts.Get(i);
                int   ej = hInsideEnts.Get(j);
                hInsideEnts.Set(i,  ej);
                hInsideDists.Set(i, view_as<int>(dj));
                hInsideEnts.Set(j,  ei);
                hInsideDists.Set(j, view_as<int>(di));
            }
        }
    }

    for( int i = (maxInside < 0 ? totalInside : maxInside); i < totalInside; i++ )
    {
        int e = hInsideEnts.Get(i);
        if( IsValidEntity(e) )
        {
            RemoveEntity(e);
            removedInside++;
        }
    }

    int keptInside = totalInside - removedInside;
    int limitOutside = (maxOutside < 0 ? totalOutside : maxOutside);

    if( totalOutside > limitOutside )
    {
        for( int i = 0; i < totalOutside - 1; i++ )
        {
            for( int j = i + 1; j < totalOutside; j++ )
            {
                float di = view_as<float>(hOutsideDists.Get(i));
                float dj = view_as<float>(hOutsideDists.Get(j));
                if( dj < di )
                {
                    int   ei = hOutsideEnts.Get(i);
                    int   ej = hOutsideEnts.Get(j);
                    hOutsideEnts.Set(i,  ej);
                    hOutsideDists.Set(i, view_as<int>(dj));
                    hOutsideEnts.Set(j,  ei);
                    hOutsideDists.Set(j, view_as<int>(di));
                }
            }
        }

        for( int i = limitOutside; i < totalOutside; i++ )
        {
            int e = hOutsideEnts.Get(i);
            if( IsValidEntity(e) )
            {
                RemoveEntity(e);
                removedOutside++;
            }
        }
    }

    int keptOutside = totalOutside - removedOutside;
    LogMessage("[L4D2 Limit Items] Medkit: inside %d (kept %d, removed %d) limit %d, outside %d (kept %d, removed %d) limit %d",
        totalInside, keptInside, removedInside, maxInside,
        totalOutside, keptOutside, removedOutside, maxOutside);

    delete hInsideEnts;
    delete hInsideDists;
    delete hOutsideEnts;
    delete hOutsideDists;
}

int ListProps(int client, const char[] model, const char[] label)
{
    int count = 0;
    int ent   = -1;

    PrintToConsole(client, "--- %s ---", label);

    while( (ent = FindEntityByClassname(ent, "prop_physics")) != -1 )
    {
        if( !IsValidEdict(ent) )
            continue;

        if( GetEntProp(ent, Prop_Send, "m_isCarryable", 1) < 1 )
            continue;

        char entModel[PLATFORM_MAX_PATH];
        GetEntPropString(ent, Prop_Data, "m_ModelName", entModel, sizeof(entModel));

        if( strcmp(entModel, model, false) != 0 )
            continue;

        float pos[3];
        GetEntPropVector(ent, Prop_Data, "m_vecAbsOrigin", pos);
        count++;
        PrintToConsole(client, "  [world] #%d  %.0f  %.0f  %.0f", count, pos[0], pos[1], pos[2]);
    }

    if( count == 0 )
        PrintToConsole(client, "  (none)");

    return count;
}

Action CmdListItems(int client, int args)
{
    static const char spawns[][] = {
        "weapon_molotov_spawn", "weapon_pipe_bomb_spawn", "weapon_pain_pills_spawn",
        "weapon_adrenaline_spawn", "weapon_first_aid_kit_spawn", "weapon_defibrillator_spawn", "weapon_vomitjar_spawn"
    };

    static const char instances[][] = {
        "weapon_molotov", "weapon_pipe_bomb", "weapon_pain_pills",
        "weapon_adrenaline", "weapon_first_aid_kit", "weapon_defibrillator", "weapon_vomitjar"
    };

    static const char labels[][] = {
        "Molotov", "Pipe Bomb", "Pain Pills", "Adrenaline", "Medkit", "Defibrillator", "Bile Jar"
    };

    int totalFound = 0;
    float startPos[3];
    bool  hasStart = FindSurvivorStart(startPos);

    PrintToConsole(client, "=== [L4D2 Limit Items] Item Spawns ===");

    if( hasStart )
        PrintToConsole(client, "Survivor start: %.0f  %.0f  %.0f  (saferoom radius: %.0f)", startPos[0], startPos[1], startPos[2], MEDKIT_SAFEROOM_RADIUS);

    for( int t = 0; t < sizeof(labels); t++ )
    {
        int spawnCount    = 0;
        int instanceCount = 0;
        int ent           = -1;
        float pos[3];

        PrintToConsole(client, "--- %s ---", labels[t]);

        while( (ent = FindEntityByClassname(ent, spawns[t])) != -1 )
        {
            GetEntPropVector(ent, Prop_Data, "m_vecAbsOrigin", pos);
            spawnCount++;
            totalFound++;

            if( t == 4 && hasStart )
            {
                float dist = GetVectorDistance(startPos, pos);
                char tag[16];
                FormatEx(tag, sizeof(tag), dist <= MEDKIT_SAFEROOM_RADIUS ? " [safe]" : "");
                PrintToConsole(client, "  [spawn] #%d  %.0f  %.0f  %.0f  (dist: %.0f)%s", spawnCount, pos[0], pos[1], pos[2], dist, tag);
            }
            else
            {
                PrintToConsole(client, "  [spawn] #%d  %.0f  %.0f  %.0f", spawnCount, pos[0], pos[1], pos[2]);
            }
        }

        ent = -1;
        while( (ent = FindEntityByClassname(ent, instances[t])) != -1 )
        {
            GetEntPropVector(ent, Prop_Data, "m_vecAbsOrigin", pos);
            instanceCount++;
            totalFound++;

            if( t == 4 && hasStart )
            {
                float dist = GetVectorDistance(startPos, pos);
                char tag[16];
                FormatEx(tag, sizeof(tag), dist <= MEDKIT_SAFEROOM_RADIUS ? " [safe]" : "");
                PrintToConsole(client, "  [world] #%d  %.0f  %.0f  %.0f  (dist: %.0f)%s", instanceCount, pos[0], pos[1], pos[2], dist, tag);
            }
            else
            {
                PrintToConsole(client, "  [world] #%d  %.0f  %.0f  %.0f", instanceCount, pos[0], pos[1], pos[2]);
            }
        }

        if( spawnCount == 0 && instanceCount == 0 )
            PrintToConsole(client, "  (none)");
    }

    totalFound += ListProps(client, MODEL_GASCAN,    "Gascan");
    totalFound += ListProps(client, MODEL_PROPANE,   "Propane");
    totalFound += ListProps(client, MODEL_OXYGEN,    "Oxygen");
    totalFound += ListProps(client, MODEL_FIREWORKS, "Fireworks");

    PrintToConsole(client, "======================================");
    PrintToConsole(client, "Total: %d active items", totalFound);

    if( client != 0 )
        PrintToChat(client, " \x04[L4D2 Limit Items]\x01 List printed to console. (%d items)", totalFound);
    else
        PrintToServer("[L4D2 Limit Items] Total: %d active items", totalFound);

    return Plugin_Handled;
}