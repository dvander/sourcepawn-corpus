// ====================================================================================================
// Plugin Info
// ====================================================================================================
#define PLUGIN_NAME        "[L4D] Barnacle"
#define PLUGIN_AUTHOR      "Finishlast"
#define PLUGIN_DESCRIPTION "Add barnacles to maps with commands and save cfg"
#define PLUGIN_VERSION     "1.2.2"
#define PLUGIN_URL         "https://forums.alliedmods.net/showthread.php?p=2841208"

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
#include <sdkhooks>
#pragma semicolon 1
#pragma newdecls required

// ====================================================================================================
// Configuration Constants
// ====================================================================================================
#define MAX_ROPES 20
#define ROPE_SAVE_FILE "addons/sourcemod/data/l4d_barnacle.cfg"
#define NAMEBUF 64

// Physics & Movement
#define ROPE_MIN_DISTANCE 15.0
#define PULL_SPEED 5.0
#define PULL_VELOCITY_Z 80.0
#define PULL_BOOST_VELOCITY 120.0
#define SAG_ANIMATION_STEP 2.0
#define SAG_TARGET_FINAL 60.0
#define TARGET_HEIGHT_OFFSET 60.0
#define TOUCH_RADIUS 20.0
#define SURVIVOR_DROP_OFFSET_Z -15.0
#define SURVIVOR_DROP_OFFSET_X 1.0

// Timing
#define TIMER_INTERVAL_TOUCH 0.2
#define TIMER_INTERVAL_PULL_AND_SAG 0.1
#define TIMER_INTERVAL_WOBBLE 0.15
#define TIMER_INTERVAL_SOUND 0.5
#define ROPE_ENABLE_DELAY 5.0
#define PHYSICS_SPAWN_DELAY 1.5

// Stall detection
#define STALL_CHECK_THRESHOLD 0.5
#define STALL_TICK_LIMIT 4
#define TAKEOVER_RETRY_LIMIT 100

// Visual
#define FLESH_CIRCLE_COUNT 4
#define FLESH_CIRCLE_POINTS 4

// Sound definitions
#define SOUND_DRAG  "player/boomer/vomit/boomer_disruptvomit_01.wav"
#define SOUND_BURST "player/boomer/vomit/boomer_disruptvomit_05.wav"

// Models
#define BOTTOM_ANCHOR_MODEL "models/props_exteriors/lighthouserailing_03_break04.mdl"
#define CARRIER_MODEL "models/props_interiors/refrigerator03_damaged_07.mdl"
#define HEALTH_MODEL "models/props_industrial/pallet_barrels_water01_single.mdl"

// Handoff tolerance
#define HANDOFF_TOL_X 10.0
#define HANDOFF_TOL_Y 10.0
#define HANDOFF_TOL_Z 10.0

// Safety caps to avoid edict spam
#define MAX_BURST_PIECES 12

char g_gibModels[3][64] = {
    "models/infected/limbs/exploded_boomer_steak1.mdl",
    "models/infected/limbs/exploded_boomer_steak2.mdl",
    "models/infected/limbs/exploded_boomer_steak3.mdl"
};

char g_physModels[11][64] = {
    "models/props_junk/garbage_tunacan01a.mdl",
    "models/props_junk/garbage_beercan01a.mdl",
    "models/props_junk/garbage_takeoutbox01a.mdl",
    "models/infected/limbs/exploded_boomer_steak1.mdl",
    "models/gibs/hgibs.mdl",
    "models/props_junk/garbage_beancan01a_fullsheet.mdl",
    "models/props_junk/garbage_coffeecup01a_fullsheet.mdl",
    "models/props_junk/garbage_coffeemug001a_fullsheet.mdl",
    "models/props_junk/garbage_sodacan01a.mdl",
    "models/props_junk/garbage_toycar01a.mdl",
    "models/props_junk/garbage_frenchfrycup01a_fullsheet.mdl"
};

// ====================================================================================================
// Rope State Enum
// ====================================================================================================
enum RopeState {
    State_Idle = 0,
    State_Ready,
    State_Pulling,
    State_Animating,
    State_Completed
}

// ====================================================================================================
// Globals
// ====================================================================================================
RopeState g_ropeState[MAX_ROPES];
bool  g_timerLock[MAX_ROPES];
bool g_mapEnding = false;

// These store entrefs, not raw indices
int   g_anchorTop[MAX_ROPES];
int   g_anchorBottom[MAX_ROPES];
int   g_ropeTop[MAX_ROPES];
int   g_ropeBottom[MAX_ROPES];

int   g_centerShootable[MAX_ROPES]; // entref
int   g_centerHealth[MAX_ROPES];
bool  g_centerDestroyed[MAX_ROPES];

float g_anchorTopPos[MAX_ROPES][3];
float g_anchorBottomPos[MAX_ROPES][3];
float g_topDropPos[MAX_ROPES][3];

int   g_pulledEntity[MAX_ROPES]; // client index
float g_targetZ[MAX_ROPES];
float g_lastZ[MAX_ROPES];
int   g_stallTicks[MAX_ROPES];

int   g_takeoverRetries[MAX_ROPES];
bool  g_handoffPending[MAX_ROPES];

float g_pulledPos[MAX_ROPES][3];

char  g_nameAnchorTop[MAX_ROPES][NAMEBUF];
char  g_nameAnchorBottom[MAX_ROPES][NAMEBUF];
char  g_nameRopeTop[MAX_ROPES][NAMEBUF];
char  g_nameRopeBottom[MAX_ROPES][NAMEBUF];
char  g_nameCenterShootable[MAX_ROPES][NAMEBUF];
char  g_nameCircleEnt[MAX_ROPES][FLESH_CIRCLE_COUNT][FLESH_CIRCLE_POINTS][NAMEBUF];

Handle g_touchTimer[MAX_ROPES];
Handle g_pullTimer[MAX_ROPES];
Handle g_wobbleTimer[MAX_ROPES];
Handle g_soundTimer[MAX_ROPES];
Handle g_sagTimer[MAX_ROPES];
Handle g_cleanupTimer[MAX_ROPES];

float g_sagTarget[MAX_ROPES];
float g_sagCurrent[MAX_ROPES];

int g_ropeCount;
int g_clientRope[MAXPLAYERS + 1];

// Flesh circle entities stored as entrefs
int   g_circleEnts[MAX_ROPES][FLESH_CIRCLE_COUNT][FLESH_CIRCLE_POINTS];
float g_circleBasePos[MAX_ROPES][FLESH_CIRCLE_COUNT][FLESH_CIRCLE_POINTS][3];
float g_circleBaseAng[MAX_ROPES][FLESH_CIRCLE_COUNT][FLESH_CIRCLE_POINTS][3];

bool g_finalizationSpawned[MAX_ROPES];

// ConVars
ConVar g_cvDebug;
ConVar g_cvPullSpeed;
ConVar g_cvCenterHealth;
ConVar g_cvBurstPieces;
ConVar g_cvPhysicsPropLifetime;
ConVar g_cvBarnaclePropLifetime;
ConVar g_cvMaxRopes;
ConVar g_cvCompletionDamage;

// ====================================================================================================
// Lifecycle
// ====================================================================================================
public void OnPluginStart()
{
    RegAdminCmd("sm_barnacle_add", Command_AimPos, ADMFLAG_ROOT, "Adds a barnacle rope and saves it to the current map config");
    RegAdminCmd("sm_barnacle_del", Command_DeleteRope, ADMFLAG_ROOT, "Deletes the barnacle you are aiming at and removes it from the current map config");
    RegAdminCmd("sm_barnacle_delete_all_temp", Command_ResetAll, ADMFLAG_ROOT, "Temporary deletes all Barnacles from the current map, no save");
    RegAdminCmd("sm_barnacle_list", Command_ListRopes, ADMFLAG_ROOT, "Lists Barnacles of the current map");
    RegAdminCmd("sm_barnacle_save", Command_SaveRopes, ADMFLAG_ROOT, "Saves Barnacles of the current map");
    RegAdminCmd("sm_barnacle_delete_saved", Command_ClearSavedRopes, ADMFLAG_ROOT, "Deletes saved Barnacles from the current map");

    g_cvDebug = CreateConVar("sm_barnacle_debug", "0", "Enable debug messages", FCVAR_NOTIFY);
    g_cvPullSpeed = CreateConVar("sm_barnacle_pullspeed", "5.0", "Pull speed per tick", FCVAR_NOTIFY);
    g_cvCenterHealth = CreateConVar("sm_barnacle_health", "500", "Barnacle health", FCVAR_NOTIFY);
    g_cvBurstPieces = CreateConVar("sm_barnacle_burstpieces", "5", "Number of top burst gibs", FCVAR_NOTIFY);
    g_cvPhysicsPropLifetime = CreateConVar("sm_barnacle_physlife", "20.0", "Lifetime of spawned physics gibs props (seconds)", FCVAR_NOTIFY);
    g_cvBarnaclePropLifetime = CreateConVar("sm_barnacle_life", "20.0", "Lifetime of spawned barnacles after their deaths (seconds)", FCVAR_NOTIFY);
    g_cvMaxRopes = CreateConVar("sm_barnacle_max_ropes", "2", "Number of barnacle ropes allowed (max 20 but expect crashes before that)", FCVAR_NOTIFY);
    g_cvCompletionDamage = CreateConVar("sm_barnacle_damage", "10.0", "Damage dealt to survivor when pull completes", FCVAR_NOTIFY);

    HookEvent("bot_player_replace", Event_BotReplace, EventHookMode_Post);
    HookEvent("player_bot_replace", Event_PlayerReplace, EventHookMode_Post);
    HookEvent("player_team", Event_PlayerTeam, EventHookMode_Post);
    HookEvent("round_freeze_end", Event_RoundFreezeEnd, EventHookMode_PostNoCopy);

    InitAllRopes();
    for (int c = 1; c <= MaxClients; c++) g_clientRope[c] = -1;

    AutoExecConfig(true, "l4d_barnacle");
}

public void OnMapStart()
{
    PrecacheModels();
    PrecacheSounds();
}

public void Event_RoundFreezeEnd(Event event, const char[] name, bool dontBroadcast)
{
    g_mapEnding = false;
    ResetAllRopes();
    CreateTimer(2.0, Timer_DelayedLoadRopes, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_DelayedLoadRopes(Handle timer)
{
    LoadSavedRopesForMap();
    return Plugin_Stop;
}

public void OnMapEnd()
{
    g_mapEnding = true;
    ResetAllRopes();
}

// ====================================================================================================
// Initialization & Cleanup
// ====================================================================================================
void PrecacheModels()
{
    for (int i = 0; i < 3; i++) PrecacheModel(g_gibModels[i], true);
    PrecacheModel(CARRIER_MODEL, true);
    PrecacheModel(BOTTOM_ANCHOR_MODEL, true);
    PrecacheModel(HEALTH_MODEL, true);
    for (int i = 0; i < 11; i++) PrecacheModel(g_physModels[i], true);
}

void PrecacheSounds()
{
    PrecacheSound(SOUND_DRAG, true);
    PrecacheSound(SOUND_BURST, true);
}

void InitAllRopes()
{
    g_ropeCount = 0;
    for (int i = 0; i < MAX_ROPES; i++) {
        ResetRopeSlot(i);
    }
}

void ResetRopeSlot(int idx)
{
    g_ropeState[idx] = State_Idle;
    g_timerLock[idx] = false;

    g_anchorTop[idx] = INVALID_ENT_REFERENCE;
    g_anchorBottom[idx] = INVALID_ENT_REFERENCE;
    g_ropeTop[idx] = INVALID_ENT_REFERENCE;
    g_ropeBottom[idx] = INVALID_ENT_REFERENCE;

    g_pulledEntity[idx] = -1;
    g_targetZ[idx] = 0.0;
    g_lastZ[idx] = 0.0;
    g_stallTicks[idx] = 0;
    g_takeoverRetries[idx] = 0;
    g_handoffPending[idx] = false;

    g_touchTimer[idx] = null;
    g_pullTimer[idx] = null;
    g_wobbleTimer[idx] = null;
    g_soundTimer[idx] = null;
    g_sagTimer[idx] = null;
    g_cleanupTimer[idx] = null;

    for (int k = 0; k < 3; k++) {
        g_anchorTopPos[idx][k] = 0.0;
        g_anchorBottomPos[idx][k] = 0.0;
        g_topDropPos[idx][k] = 0.0;
        g_pulledPos[idx][k] = 0.0;
    }

    g_centerShootable[idx] = INVALID_ENT_REFERENCE;
    g_centerHealth[idx] = 0;
    g_centerDestroyed[idx] = false;

    g_sagTarget[idx] = 0.0;
    g_sagCurrent[idx] = 0.0;

    for (int c = 0; c < FLESH_CIRCLE_COUNT; c++) {
        for (int p = 0; p < FLESH_CIRCLE_POINTS; p++) {
            g_circleEnts[idx][c][p] = INVALID_ENT_REFERENCE;
            for (int k2 = 0; k2 < 3; k2++) {
                g_circleBasePos[idx][c][p][k2] = 0.0;
                g_circleBaseAng[idx][c][p][k2] = 0.0;
            }
        }
    }

    g_finalizationSpawned[idx] = false;

    Format(g_nameAnchorTop[idx], NAMEBUF, "barnacle_rope_anchor_top_%d", idx);
    Format(g_nameAnchorBottom[idx], NAMEBUF, "barnacle_rope_anchor_bottom_%d", idx);
    Format(g_nameRopeTop[idx], NAMEBUF, "barnacle_rope_top_%d", idx);
    Format(g_nameRopeBottom[idx], NAMEBUF, "barnacle_rope_bottom_%d", idx);
    Format(g_nameCenterShootable[idx], NAMEBUF, "barnacle_center_%d", idx);
    for (int c = 0; c < FLESH_CIRCLE_COUNT; c++)
        for (int p = 0; p < FLESH_CIRCLE_POINTS; p++)
            Format(g_nameCircleEnt[idx][c][p], NAMEBUF, "barnacle_circle_%d_%d_%d", idx, c, p);
}

void ResetAllRopes()
{
    for (int i = 0; i < MAX_ROPES; i++) {
        CleanupInstance(i, true);
    }
    g_ropeCount = 0;
    for (int c = 1; c <= MaxClients; c++) g_clientRope[c] = -1;
}

// ====================================================================================================
// Safe timer stopping (FIXED VERSION)
// ====================================================================================================
stock void SafeStopTimer(Handle &h, Handle current = null)
{
    if (h == null)
        return;

    if (current != null && h == current) {
        h = null;
        return;
    }

    Handle tmp = h;
    h = null;
    
    if (tmp != null) {
        KillTimer(tmp, false);
    }
}

// ====================================================================================================
// Commands
// ====================================================================================================
public Action Command_AimPos(int client, int args)
{
    if (!IsValidClient(client) || !IsPlayerAlive(client)) {
        ReplyToCommand(client, "[SM] You must be alive to place a Barnacle.");
        return Plugin_Handled;
    }

    if (GetClientTeam(client) != 2 && GetClientTeam(client) != 3) {
        ReplyToCommand(client, "[SM] Only survivors and infected can place Barnacles.");
        return Plugin_Handled;
    }

    int idx = FindFreeRopeSlot();
    if (idx < 0) {
        ReplyToCommand(client, "[SM] Barnacle limit reached (%d). Use !barnacle_del to delete one you are aiming at.", g_cvMaxRopes.IntValue);
        return Plugin_Handled;
    }

    float eyeOrigin[3], eyeAngles[3], ceilingHit[3];
    GetClientEyePosition(client, eyeOrigin);
    GetClientEyeAngles(client, eyeAngles);

    TR_TraceRayFilter(eyeOrigin, eyeAngles, MASK_SOLID, RayType_Infinite, TraceEntityFilter);
    if (!TR_DidHit()) {
        ReplyToCommand(client, "[SM] Aim at a solid thick ceiling to place a Barnacle.");
        return Plugin_Handled;
    }
    TR_GetEndPosition(ceilingHit);

    float groundOrigin[3];
    GetClientAbsOrigin(client, groundOrigin);

    float top[3], bottom[3];
    top[0] = ceilingHit[0];
    top[1] = ceilingHit[1];
    top[2] = ceilingHit[2];
    bottom[0] = ceilingHit[0];
    bottom[1] = ceilingHit[1];
    bottom[2] = groundOrigin[2] + 40.0;

    CreateRopeAt(idx, top, bottom);
    g_ropeCount++;

    ReplyToCommand(client, "[SM] Barnacle #%d created.", idx);
    Command_SaveRopes(client, 0);
    return Plugin_Handled;
}

public Action Command_ResetAll(int client, int args)
{
    ResetAllRopes();
    ReplyToCommand(client, "[SM] All Barnacles temporarily deleted.");
    return Plugin_Handled;
}

public Action Command_ListRopes(int client, int args)
{
    int active = 0;
    for (int i = 0; i < MAX_ROPES; i++) {
        int topEnt = EntRefToEntIndex(g_anchorTop[i]);
        int bottomEnt = EntRefToEntIndex(g_anchorBottom[i]);

        if (topEnt != INVALID_ENT_REFERENCE && bottomEnt != INVALID_ENT_REFERENCE) {
           active++;
           char stateName[32];
           GetStateName(g_ropeState[i], stateName, sizeof(stateName));
           ReplyToCommand(client, "[SM] Barnacle #%d: State=%s Pulled=%d TopEnt=%d BottomEnt=%d",
              i, stateName, g_pulledEntity[i], topEnt, bottomEnt);
        }
    }

    if (active == 0) {
        ReplyToCommand(client, "[SM] No Barnacles.");
    }
    return Plugin_Handled;
}

public Action Command_SaveRopes(int client, int args)
{
    char map[64];
    GetCurrentMap(map, sizeof(map));
    KeyValues kv = new KeyValues("Ropes");
    kv.ImportFromFile(ROPE_SAVE_FILE);

    if (kv.JumpToKey(map, false)) {
        kv.DeleteThis();
        kv.GoBack();
    }
    kv.JumpToKey(map, true);

    // Collect unique positions first
    float savedPositions[MAX_ROPES][2][3]; // [saved_count][top=0/bottom=1][xyz]
    int saved = 0;
    char ropeKey[32], vecbuf[128];

    for (int i = 0; i < MAX_ROPES; i++) {
        int topEnt = EntRefToEntIndex(g_anchorTop[i]);
        int bottomEnt = EntRefToEntIndex(g_anchorBottom[i]);

        if (topEnt != INVALID_ENT_REFERENCE && bottomEnt != INVALID_ENT_REFERENCE) {
            
            // Check if this position already exists in our saved list
            bool isDuplicate = false;
            for (int j = 0; j < saved; j++) {
                if (FloatAbs(savedPositions[j][0][0] - g_anchorTopPos[i][0]) < 1.0 &&
                    FloatAbs(savedPositions[j][0][1] - g_anchorTopPos[i][1]) < 1.0 &&
                    FloatAbs(savedPositions[j][0][2] - g_anchorTopPos[i][2]) < 1.0 &&
                    FloatAbs(savedPositions[j][1][0] - g_anchorBottomPos[i][0]) < 1.0 &&
                    FloatAbs(savedPositions[j][1][1] - g_anchorBottomPos[i][1]) < 1.0 &&
                    FloatAbs(savedPositions[j][1][2] - g_anchorBottomPos[i][2]) < 1.0) {
                    isDuplicate = true;
                    break;
                }
            }
            
            if (isDuplicate) {
                continue; // Skip this duplicate
            }
            
            // Save this unique position
            Format(ropeKey, sizeof(ropeKey), "rope_%d", saved);
            kv.JumpToKey(ropeKey, true);

            Format(vecbuf, sizeof(vecbuf), "%.3f %.3f %.3f",
                g_anchorTopPos[i][0], g_anchorTopPos[i][1], g_anchorTopPos[i][2]);
            kv.SetString("top", vecbuf);

            Format(vecbuf, sizeof(vecbuf), "%.3f %.3f %.3f",
                g_anchorBottomPos[i][0], g_anchorBottomPos[i][1], g_anchorBottomPos[i][2]);
            kv.SetString("bottom", vecbuf);

            kv.GoBack();
            
            // Remember this position
            savedPositions[saved][0][0] = g_anchorTopPos[i][0];
            savedPositions[saved][0][1] = g_anchorTopPos[i][1];
            savedPositions[saved][0][2] = g_anchorTopPos[i][2];
            savedPositions[saved][1][0] = g_anchorBottomPos[i][0];
            savedPositions[saved][1][1] = g_anchorBottomPos[i][1];
            savedPositions[saved][1][2] = g_anchorBottomPos[i][2];
            
            saved++;
        }
    }

    kv.Rewind();
    kv.ExportToFile(ROPE_SAVE_FILE);
    delete kv;

    ReplyToCommand(client, "[SM] Saved %d Barnacle(s) for map %s.", saved, map);
    return Plugin_Handled;
}

public Action Command_ClearSavedRopes(int client, int args)
{
    char map[64];
    GetCurrentMap(map, sizeof(map));
    KeyValues kv = new KeyValues("Ropes");
    kv.ImportFromFile(ROPE_SAVE_FILE);

    bool had = false;
    if (kv.JumpToKey(map, false)) {
        kv.DeleteThis();
        kv.GoBack();
        had = true;
    }
    kv.Rewind();
    kv.ExportToFile(ROPE_SAVE_FILE);
    delete kv;
    Command_ResetAll(client, 0);
    ReplyToCommand(client, had ? "[SM] Cleared saved Barnacles for map %s." : "[SM] No saved Barnacles found for map %s.", map);
    return Plugin_Handled;
}

public Action Command_DeleteRope(int client, int args)
{
    if (!IsValidClient(client) || !IsPlayerAlive(client)) {
        ReplyToCommand(client, "[SM] You must be alive to delete a Barnacle.");
        return Plugin_Handled;
    }

    float eyeOrigin[3], eyeAngles[3];
    GetClientEyePosition(client, eyeOrigin);
    GetClientEyeAngles(client, eyeAngles);

    TR_TraceRayFilter(eyeOrigin, eyeAngles, MASK_ALL, RayType_Infinite, TraceEntityFilter);

    if (!TR_DidHit()) {
        ReplyToCommand(client, "[SM] You are not aiming at a Barnacle.");
        return Plugin_Handled;
    }

    int ent = TR_GetEntityIndex();

    for (int idx = 0; idx < MAX_ROPES; idx++) {
        if (EntRefToEntIndex(g_centerShootable[idx]) == ent) {
           CleanupInstance(idx, true);
           if (g_ropeCount > 0) g_ropeCount--;
           ReplyToCommand(client, "[SM] Barnacle #%d deleted.", idx);
           Command_SaveRopes(client, 0);
           return Plugin_Handled;
        }
    }

    ReplyToCommand(client, "[SM] That is not a Barnacle.");
    return Plugin_Handled;
}

// ====================================================================================================
// Persistence
// ====================================================================================================
void LoadSavedRopesForMap()
{
    char map[64];
    GetCurrentMap(map, sizeof(map));
    KeyValues kv = new KeyValues("Ropes");
    
    if (!kv.ImportFromFile(ROPE_SAVE_FILE)) {
        delete kv;
        return;
    }
    
    if (!kv.JumpToKey(map, false)) {
        delete kv;
        return;
    }
    
    // First pass: collect all unique positions
    float uniquePositions[MAX_ROPES][2][3]; // [idx][top=0/bottom=1][xyz]
    int uniqueCount = 0;
    int totalRead = 0;
    
    kv.GotoFirstSubKey(false);
    
    do {
        char topStr[128], bottomStr[128];
        float top[3], bottom[3];
        
        kv.GetString("top", topStr, sizeof(topStr), "");
        kv.GetString("bottom", bottomStr, sizeof(bottomStr), "");
        
        totalRead++;
        
        if (!ParseVec3(topStr, top) || !ParseVec3(bottomStr, bottom)) {
            continue;
        }
        
        // Check if this position already exists in our unique list
        bool isDuplicate = false;
        for (int i = 0; i < uniqueCount; i++) {
            if (FloatAbs(uniquePositions[i][0][0] - top[0]) < 1.0 &&
                FloatAbs(uniquePositions[i][0][1] - top[1]) < 1.0 &&
                FloatAbs(uniquePositions[i][0][2] - top[2]) < 1.0 &&
                FloatAbs(uniquePositions[i][1][0] - bottom[0]) < 1.0 &&
                FloatAbs(uniquePositions[i][1][1] - bottom[1]) < 1.0 &&
                FloatAbs(uniquePositions[i][1][2] - bottom[2]) < 1.0) {
                isDuplicate = true;
                break;
            }
        }
        
        if (!isDuplicate && uniqueCount < MAX_ROPES) {
            uniquePositions[uniqueCount][0][0] = top[0];
            uniquePositions[uniqueCount][0][1] = top[1];
            uniquePositions[uniqueCount][0][2] = top[2];
            uniquePositions[uniqueCount][1][0] = bottom[0];
            uniquePositions[uniqueCount][1][1] = bottom[1];
            uniquePositions[uniqueCount][1][2] = bottom[2];
            uniqueCount++;
        }
    } while (kv.GotoNextKey(false));
    
    int duplicatesFound = totalRead - uniqueCount;
    
    // If duplicates found, rewrite the config
    if (duplicatesFound > 0) {
        DebugLog("Found %d duplicate(s) in config, cleaning...", duplicatesFound);
        
        kv.Rewind();
        
        // Delete old map section
        if (kv.JumpToKey(map, false)) {
            kv.DeleteThis();
            kv.GoBack();
        }
        
        // Recreate with unique entries only
        kv.JumpToKey(map, true);
        
        char ropeKey[32], vecbuf[128];
        for (int i = 0; i < uniqueCount; i++) {
            Format(ropeKey, sizeof(ropeKey), "rope_%d", i);
            kv.JumpToKey(ropeKey, true);
            
            Format(vecbuf, sizeof(vecbuf), "%.3f %.3f %.3f",
                uniquePositions[i][0][0], uniquePositions[i][0][1], uniquePositions[i][0][2]);
            kv.SetString("top", vecbuf);
            
            Format(vecbuf, sizeof(vecbuf), "%.3f %.3f %.3f",
                uniquePositions[i][1][0], uniquePositions[i][1][1], uniquePositions[i][1][2]);
            kv.SetString("bottom", vecbuf);
            
            kv.GoBack();
        }
        
        kv.Rewind();
        kv.ExportToFile(ROPE_SAVE_FILE);
        
        DebugLog("[Barnacle] Cleaned config for map %s: removed %d duplicate(s), kept %d unique rope(s)", 
                   map, duplicatesFound, uniqueCount);
    }
    
    kv.Rewind();
    delete kv;
    
    // Second pass: spawn the unique ropes
    for (int i = 0; i < uniqueCount; i++) {
        int idx = FindFreeRopeSlot();
        if (idx >= 0) {
            float top[3], bottom[3];
            top[0] = uniquePositions[i][0][0];
            top[1] = uniquePositions[i][0][1];
            top[2] = uniquePositions[i][0][2];
            bottom[0] = uniquePositions[i][1][0];
            bottom[1] = uniquePositions[i][1][1];
            bottom[2] = uniquePositions[i][1][2];
            
            CreateRopeAt(idx, top, bottom);
            g_ropeCount++;
        }
    }
    
    if (duplicatesFound > 0) {
        DebugLog("Loaded %d rope(s) for map %s (auto-cleaned %d duplicates from config)", 
                 uniqueCount, map, duplicatesFound);
    } else {
        DebugLog("Loaded %d rope(s) for map %s", uniqueCount, map);
    }
}

// ====================================================================================================
// Helpers
// ====================================================================================================
bool ParseVec3(const char[] s, float out[3])
{
    char parts[3][32];
    int n = ExplodeString(s, " ", parts, 3, 32);
    if (n < 3) return false;

    out[0] = StringToFloat(parts[0]);
    out[1] = StringToFloat(parts[1]);
    out[2] = StringToFloat(parts[2]);
    return true;
}

bool IsValidClient(int client)
{
    return (client > 0 && client <= MaxClients && IsClientInGame(client));
}

bool IsClientIncapped(int client)
{
    if (!IsValidClient(client)) return false;
    return GetEntProp(client, Prop_Send, "m_isIncapacitated") != 0;
}

void GetStateName(RopeState state, char[] buffer, int maxlen)
{
    switch (state) {
        case State_Idle: strcopy(buffer, maxlen, "Idle");
        case State_Ready: strcopy(buffer, maxlen, "Ready");
        case State_Pulling: strcopy(buffer, maxlen, "Pulling");
        case State_Animating: strcopy(buffer, maxlen, "Animating");
        case State_Completed: strcopy(buffer, maxlen, "Completed");
        default: strcopy(buffer, maxlen, "Unknown");
    }
}

void DebugLog(const char[] format, any ...)
{
    if (!g_cvDebug.BoolValue) return;

    char buffer[256];
    VFormat(buffer, sizeof(buffer), format, 2);
    PrintToChatAll("[Barnacle Debug] %s", buffer);
    LogMessage("[Barnacle] %s", buffer);
}

// ====================================================================================================
// Center Prop Management
// ====================================================================================================
void KillCenterProp(int idx)
{
    if (idx < 0 || idx >= MAX_ROPES) return;

    int ent = EntRefToEntIndex(g_centerShootable[idx]);
    if (ent != INVALID_ENT_REFERENCE && IsValidEntity(ent)) {
        SDKUnhook(ent, SDKHook_OnTakeDamage, Center_OnTakeDamage);
        AcceptEntityInput(ent, "Kill");
    }

    g_centerShootable[idx] = INVALID_ENT_REFERENCE;
    g_centerHealth[idx] = 0;
    g_centerDestroyed[idx] = true;
}

public Action Center_OnTakeDamage(int entity, int &attacker, int &inflictor, float &damage, int &damagetype)
{
    for (int idx = 0; idx < MAX_ROPES; idx++) {
        if (EntRefToEntIndex(g_centerShootable[idx]) != entity) continue;

        g_centerHealth[idx] -= RoundToNearest(damage);
        if (g_centerHealth[idx] < 0) g_centerHealth[idx] = 0;

        float origin[3];
        GetEntPropVector(entity, Prop_Send, "m_vecOrigin", origin);
        
        EmitSoundToAll(SOUND_DRAG, -1, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, origin);

        DebugLog("Rope %d center prop health: %d", idx, g_centerHealth[idx]);

        if (g_centerHealth[idx] <= 0) {
            DebugLog("Rope %d center prop destroyed!", idx);
            HandleCenterDestruction(idx);
        }

        return Plugin_Continue;
    }
    return Plugin_Continue;
}

void HandleCenterDestruction(int idx)
{
    KillCenterProp(idx);

    if (g_ropeState[idx] == State_Pulling && g_pulledEntity[idx] > 0) {
        SafeStopTimer(g_pullTimer[idx], null);
        SafeStopTimer(g_wobbleTimer[idx], null);
        SafeStopTimer(g_soundTimer[idx], null);
        SafeReleasePulledSurvivor(idx);
    }

    if (g_ropeState[idx] != State_Completed) {
        FinalizeVisualState(idx);
    }
}

// ====================================================================================================
// Survivor Release
// ====================================================================================================
void SafeReleasePulledSurvivor(int idx)
{
    int controller = g_pulledEntity[idx];
    if (!IsValidClient(controller)) return;

    if (g_clientRope[controller] == idx) {
        g_clientRope[controller] = -1;
    }

    SetEntityMoveType(controller, MOVETYPE_WALK);

    float pos[3];
    GetClientAbsOrigin(controller, pos);
    pos[0] += SURVIVOR_DROP_OFFSET_X;
    pos[2] += SURVIVOR_DROP_OFFSET_Z;

    float zeroVel[3] = {0.0, 0.0, 0.0};
    TeleportEntity(controller, pos, NULL_VECTOR, zeroVel);

    g_pulledEntity[idx] = -1;

    DebugLog("Released survivor from rope %d", idx);
}

// ====================================================================================================
// Flesh Circles + Center Prop
// ====================================================================================================
void SpawnFleshCircles(int idx)
{
    if (idx < 0 || idx >= MAX_ROPES)
    {
        DebugLog("SpawnFleshCircles: Invalid rope index %d, skipping", idx);
        return;
    }

    float radii[FLESH_CIRCLE_COUNT] = {7.0, 5.0, 3.0, 2.0};
    float zOffsets[FLESH_CIRCLE_COUNT] = {-4.0, -10.0, -16.0, -21.0};

    float center[3];
    center[0] = g_anchorTopPos[idx][0];
    center[1] = g_anchorTopPos[idx][1];
    center[2] = g_anchorTopPos[idx][2];

    int entCenter = CreateEntityByName("prop_physics_override");
    if (entCenter != -1) {
        DispatchKeyValue(entCenter, "model", HEALTH_MODEL);
        DispatchKeyValue(entCenter, "targetname", g_nameCenterShootable[idx]);

        float posCenter[3];
        posCenter[0] = center[0];
        posCenter[1] = center[1];
        posCenter[2] = center[2] - 45;

        DispatchKeyValueVector(entCenter, "origin", posCenter);
        DispatchKeyValue(entCenter, "solid", "6");
        DispatchKeyValue(entCenter, "spawnflags", "256");
        DispatchKeyValue(entCenter, "rendermode", "10");
        DispatchKeyValue(entCenter, "renderamt", "0");
        DispatchKeyValue(entCenter, "disableshadows", "1");

        DispatchSpawn(entCenter);
        ActivateEntity(entCenter);
        AcceptEntityInput(entCenter, "DisableMotion");
        int fx = GetEntProp(entCenter, Prop_Send, "m_fEffects");
        SetEntProp(entCenter, Prop_Send, "m_fEffects", fx | 32);

        int health = g_cvCenterHealth.IntValue;
        SetEntProp(entCenter, Prop_Data, "m_takedamage", 2);
        SetEntProp(entCenter, Prop_Data, "m_iHealth", health);

        g_centerShootable[idx] = EntIndexToEntRef(entCenter);
        g_centerHealth[idx] = health;
        g_centerDestroyed[idx] = false;

        SDKHook(entCenter, SDKHook_OnTakeDamage, Center_OnTakeDamage);
    }

    for (int c = 0; c < FLESH_CIRCLE_COUNT; c++) {
        for (int i = 0; i < FLESH_CIRCLE_POINTS; i++) {
            float angleDeg = float(i) * (360.0 / float(FLESH_CIRCLE_POINTS));
            float angleRad = angleDeg * (FLOAT_PI / 180.0);

            float pos[3];
            pos[0] = center[0] + Cosine(angleRad) * radii[c];
            pos[1] = center[1] + Sine(angleRad) * radii[c];
            pos[2] = center[2] + zOffsets[c];

            float ang[3];
            ang[0] = GetRandomFloat(0.0, 45.0);
            ang[1] = angleDeg + 90;
            ang[2] = GetRandomFloat(0.0, 45.0);

            int modelIndex = 1;
            int ent = CreateEntityByName("prop_dynamic_override");
            if (ent != -1) {
                DispatchKeyValue(ent, "model", g_gibModels[modelIndex]);
                DispatchKeyValue(ent, "solid", "0");
                DispatchKeyValue(ent, "disableshadows", "1");
                DispatchKeyValue(ent, "targetname", g_nameCircleEnt[idx][c][i]);
                DispatchSpawn(ent);

                TeleportEntity(ent, pos, ang, NULL_VECTOR);

                g_circleEnts[idx][c][i] = EntIndexToEntRef(ent);
                g_circleBasePos[idx][c][i][0] = pos[0];
                g_circleBasePos[idx][c][i][1] = pos[1];
                g_circleBasePos[idx][c][i][2] = pos[2];
                g_circleBaseAng[idx][c][i][0] = ang[0];
                g_circleBaseAng[idx][c][i][1] = ang[1];
                g_circleBaseAng[idx][c][i][2] = ang[2];
            }
        }
    }
}

// ====================================================================================================
// Visual Effects
// ====================================================================================================
void SpawnCleanupPhysicsProps(int idx)
{
    if (idx < 0 || idx >= MAX_ROPES) return;

    if (g_finalizationSpawned[idx]) {
        DebugLog("Physics props already spawned for rope %d, skipping", idx);
        return;
    }

    g_finalizationSpawned[idx] = true;
    CreateTimer(PHYSICS_SPAWN_DELAY, Timer_SpawnPhysicsPropsNew, idx);
}

public Action Timer_SpawnPhysicsPropsNew(Handle timer, int idx)
{
    if (g_mapEnding) return Plugin_Stop;

    if (idx < 0 || idx >= MAX_ROPES) {
        return Plugin_Stop;
    }

    float originTop[3];
    originTop[0] = g_anchorTopPos[idx][0];
    originTop[1] = g_anchorTopPos[idx][1];
    originTop[2] = g_anchorTopPos[idx][2];
    EmitSoundToAll(SOUND_BURST, -1, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, originTop);

    float base[3];
    base[0] = g_topDropPos[idx][0];
    base[1] = g_topDropPos[idx][1];
    base[2] = g_topDropPos[idx][2];

    float origin[3];
    origin[0] = base[0];
    origin[1] = base[1];
    origin[2] = base[2] - 10.0;

    int physCount = g_cvBurstPieces.IntValue;
    if (physCount < 0) physCount = 0;
    if (physCount > MAX_BURST_PIECES) physCount = MAX_BURST_PIECES;

    float lifephysicsprop = g_cvPhysicsPropLifetime.FloatValue;
    float lifebarnacleprop = g_cvBarnaclePropLifetime.FloatValue;

    int spawnedCount = 0;

    for (int n = 0; n < physCount; n++) {
        int carrier = CreateEntityByName("prop_physics_override");
        if (carrier == -1) {
            LogError("Failed to create physics carrier for rope %d piece %d", idx, n);
            continue;
        }

        char carrierName[32];
        Format(carrierName, sizeof(carrierName), "carrier_%d_%d", idx, n);

        DispatchKeyValue(carrier, "model", CARRIER_MODEL);
        DispatchKeyValue(carrier, "solid", "0");
        DispatchKeyValue(carrier, "targetname", carrierName);
        DispatchKeyValue(carrier, "rendermode", "10");
        DispatchKeyValue(carrier, "renderamt", "0");
        DispatchKeyValue(carrier, "disableshadows", "1");

        DispatchSpawn(carrier);
        ActivateEntity(carrier);

        int fx = GetEntProp(carrier, Prop_Send, "m_fEffects");
        SetEntProp(carrier, Prop_Send, "m_fEffects", fx | 32);
        SetEntProp(carrier, Prop_Send, "m_CollisionGroup", 1);

        char buffer[64];
        Format(buffer, sizeof(buffer), "OnUser1 !self:Kill::%f:-1", lifephysicsprop);
        SetVariantString(buffer);
        AcceptEntityInput(carrier, "AddOutput");
        AcceptEntityInput(carrier, "FireUser1");

        float vel[3] = {0.0, 0.0, 0.0};
        float ang[3];
        ang[0] = GetRandomFloat(0.0, 360.0);
        ang[1] = GetRandomFloat(0.0, 360.0);
        ang[2] = GetRandomFloat(0.0, 360.0);

        TeleportEntity(carrier, origin, ang, vel);

        char model[96];
        strcopy(model, sizeof(model), g_physModels[GetRandomInt(0, 10)]);

        int child = CreateEntityByName("prop_dynamic_override");
        if (child == -1) {
            LogError("Failed to create visual child for rope %d piece %d", idx, n);
            AcceptEntityInput(carrier, "Kill");
            continue;
        }

        DispatchKeyValue(child, "model", model);
        DispatchKeyValue(child, "solid", "0");
        DispatchKeyValue(child, "parentname", carrierName);
        DispatchKeyValue(child, "disableshadows", "1");

        DispatchSpawn(child);

        float nullAng[3] = {0.0, 0.0, 0.0};
        TeleportEntity(child, origin, nullAng, NULL_VECTOR);

        SetVariantString(carrierName);
        AcceptEntityInput(child, "SetParent");

        spawnedCount++;
    }

    DebugLog("Spawned %d/%d physics props for rope %d", spawnedCount, physCount, idx);

    if (g_cleanupTimer[idx] == null) {
        g_cleanupTimer[idx] = CreateTimer(lifebarnacleprop, Timer_CleanupInstanceRuntime, idx);
    }

    return Plugin_Stop;
}

public Action Timer_CleanupInstanceRuntime(Handle timer, any data)
{
    if (g_mapEnding) return Plugin_Stop;

    int idx = view_as<int>(data);
    if (idx < 0 || idx >= MAX_ROPES)
        return Plugin_Stop;

    if (g_cleanupTimer[idx] != timer)
        return Plugin_Stop;

    DebugLog("Barnacle lifetime expired for rope %d", idx);

    g_cleanupTimer[idx] = null;

    CleanupInstance(idx, false);

    return Plugin_Stop;
}

// ====================================================================================================
// Rope Creation
// ====================================================================================================
void CreateRopeAt(int idx, const float top[3], const float bottom[3])
{
    g_anchorTopPos[idx][0] = top[0];
    g_anchorTopPos[idx][1] = top[1];
    g_anchorTopPos[idx][2] = top[2];

    g_anchorBottomPos[idx][0] = bottom[0];
    g_anchorBottomPos[idx][1] = bottom[1];
    g_anchorBottomPos[idx][2] = bottom[2];

    g_topDropPos[idx][0] = top[0];
    g_topDropPos[idx][1] = top[1];
    g_topDropPos[idx][2] = top[2] - 10.0;

    int entTop = CreateEntityByName("prop_dynamic_override");
    if (entTop != -1) {
        DispatchKeyValue(entTop, "targetname", g_nameAnchorTop[idx]);
        DispatchKeyValueVector(entTop, "origin", g_anchorTopPos[idx]);
        SetEntityModel(entTop, g_gibModels[0]);
        DispatchSpawn(entTop);
        ActivateEntity(entTop);
        g_anchorTop[idx] = EntIndexToEntRef(entTop);
        SpawnFleshCircles(idx);
    } else {
        g_anchorTop[idx] = INVALID_ENT_REFERENCE;
    }

    int entBottom = CreateEntityByName("prop_dynamic_override");
    if (entBottom != -1) {
        DispatchKeyValue(entBottom, "targetname", g_nameAnchorBottom[idx]);
        DispatchKeyValueVector(entBottom, "origin", g_anchorBottomPos[idx]);
        SetEntityModel(entBottom, BOTTOM_ANCHOR_MODEL);
        DispatchKeyValue(entBottom, "solid", "0");
        SetEntityRenderColor(entBottom, 0, 0, 0);
        DispatchKeyValue(entBottom, "angles", "90 0 0");
        DispatchKeyValue(entBottom, "rendermode", "10");
        DispatchKeyValue(entBottom, "renderamt", "0");
        DispatchKeyValue(entBottom, "disableshadows", "1");
        DispatchSpawn(entBottom);
        ActivateEntity(entBottom);
        g_anchorBottom[idx] = EntIndexToEntRef(entBottom);
    } else {
        g_anchorBottom[idx] = INVALID_ENT_REFERENCE;
    }

    g_ropeState[idx] = State_Idle;
    g_pulledEntity[idx] = -1;

    CreateTimer(0.1, Timer_CreateRope, idx);
    CreateTimer(ROPE_ENABLE_DELAY, Timer_EnableRope, idx);
}

// ====================================================================================================
// Rope Animation (Sag)
// ====================================================================================================
void AnimateRopeSag(int idx, float targetSag)
{
    if (idx < 0 || idx >= MAX_ROPES) return;

    int topEnt = EntRefToEntIndex(g_anchorTop[idx]);
    int bottomEnt = EntRefToEntIndex(g_anchorBottom[idx]);

    if (topEnt == INVALID_ENT_REFERENCE || bottomEnt == INVALID_ENT_REFERENCE) return;
    if (!IsValidEntity(bottomEnt) || !IsValidEntity(topEnt)) return;

    g_sagTarget[idx] = targetSag;

    float top[3];
    top[0] = g_anchorTopPos[idx][0];
    top[1] = g_anchorTopPos[idx][1];
    top[2] = g_anchorTopPos[idx][2];

    float bottom[3];
    GetEntPropVector(bottomEnt, Prop_Send, "m_vecOrigin", bottom);
    g_sagCurrent[idx] = top[2] - bottom[2];

    SafeStopTimer(g_sagTimer[idx], null);
    SafeStopTimer(g_wobbleTimer[idx], null);
    SafeStopTimer(g_soundTimer[idx], null);

    g_ropeState[idx] = State_Animating;
    g_timerLock[idx] = false;

    g_sagTimer[idx] = CreateTimer(TIMER_INTERVAL_PULL_AND_SAG, Timer_SagStep, idx, TIMER_REPEAT);
    g_wobbleTimer[idx] = CreateTimer(TIMER_INTERVAL_WOBBLE, Timer_Wobble, idx, TIMER_REPEAT);
    g_soundTimer[idx] = CreateTimer(TIMER_INTERVAL_SOUND, Timer_PlayDragSound, idx, TIMER_REPEAT);
}

public Action Timer_SagStep(Handle timer, any data)
{
    if (g_mapEnding) return Plugin_Stop;

    int idx = view_as<int>(data);
    if (idx < 0 || idx >= MAX_ROPES) return Plugin_Stop;

    if (g_sagTimer[idx] != timer)
        return Plugin_Stop;

    if (g_ropeState[idx] == State_Completed) {
        g_sagTimer[idx] = null;
        return Plugin_Stop;
    }

    int topEnt = EntRefToEntIndex(g_anchorTop[idx]);
    int bottomEnt = EntRefToEntIndex(g_anchorBottom[idx]);

    if (topEnt == INVALID_ENT_REFERENCE || bottomEnt == INVALID_ENT_REFERENCE) {
        g_sagTimer[idx] = null;
        return Plugin_Stop;
    }

    if (!IsValidEntity(bottomEnt) || !IsValidEntity(topEnt)) {
        g_sagTimer[idx] = null;
        return Plugin_Stop;
    }

    if (g_timerLock[idx]) return Plugin_Continue;
    g_timerLock[idx] = true;

    if (g_sagCurrent[idx] < g_sagTarget[idx]) {
        g_sagCurrent[idx] += SAG_ANIMATION_STEP;
    } else if (g_sagCurrent[idx] > g_sagTarget[idx]) {
        g_sagCurrent[idx] -= SAG_ANIMATION_STEP;
    }

    float topV[3];
    topV[0] = g_anchorTopPos[idx][0];
    topV[1] = g_anchorTopPos[idx][1];
    topV[2] = g_anchorTopPos[idx][2];

    float sagPos[3];
    sagPos[0] = topV[0];
    sagPos[1] = topV[1];
    sagPos[2] = topV[2] - g_sagCurrent[idx];

    if (IsValidEntity(bottomEnt)) {
        TeleportEntity(bottomEnt, sagPos, NULL_VECTOR, NULL_VECTOR);

        int ropeBottomEnt = EntRefToEntIndex(g_ropeBottom[idx]);
        if (ropeBottomEnt != INVALID_ENT_REFERENCE && IsValidEntity(ropeBottomEnt)) {
            TeleportEntity(ropeBottomEnt, sagPos, NULL_VECTOR, NULL_VECTOR);
        }
    }

    g_timerLock[idx] = false;

    if (FloatAbs(g_sagCurrent[idx] - g_sagTarget[idx]) <= SAG_ANIMATION_STEP) {
        g_sagCurrent[idx] = g_sagTarget[idx];
        g_sagTimer[idx] = null;
        SafeStopTimer(g_wobbleTimer[idx], null);
        SafeStopTimer(g_soundTimer[idx], null);
        g_ropeState[idx] = State_Completed;
        SpawnCleanupPhysicsProps(idx);
        return Plugin_Stop;
    }

    return Plugin_Continue;
}

// ====================================================================================================
// Timers
// ====================================================================================================
public Action Timer_CreateRope(Handle timer, any data)
{
    if (g_mapEnding) return Plugin_Stop;

    int idx = view_as<int>(data);
    if (idx < 0 || idx >= MAX_ROPES) return Plugin_Stop;

    int topEnt = EntRefToEntIndex(g_anchorTop[idx]);
    int bottomEnt = EntRefToEntIndex(g_anchorBottom[idx]);
    if (topEnt == INVALID_ENT_REFERENCE || bottomEnt == INVALID_ENT_REFERENCE) return Plugin_Stop;

    int ropeTop = CreateEntityByName("move_rope");
    if (ropeTop != -1) {
        DispatchKeyValueVector(ropeTop, "origin", g_anchorTopPos[idx]);
        DispatchKeyValue(ropeTop, "targetname", g_nameRopeTop[idx]);
        DispatchKeyValue(ropeTop, "NextKey", g_nameRopeBottom[idx]);
        DispatchKeyValue(ropeTop, "Slack", "0");
        DispatchKeyValue(ropeTop, "MoveSpeed", "64");
        DispatchKeyValue(ropeTop, "RopeMaterial", "cable/cable.vmt");
        DispatchKeyValue(ropeTop, "Width", "2");
        DispatchKeyValue(ropeTop, "Subdiv", "0");
        DispatchKeyValue(ropeTop, "Type", "2");
        DispatchKeyValue(ropeTop, "parentname", g_nameAnchorTop[idx]);
        DispatchSpawn(ropeTop);
        ActivateEntity(ropeTop);
        g_ropeTop[idx] = EntIndexToEntRef(ropeTop);
    } else {
        g_ropeTop[idx] = INVALID_ENT_REFERENCE;
    }

    int ropeBottom = CreateEntityByName("keyframe_rope");
    if (ropeBottom != -1) {
        DispatchKeyValueVector(ropeBottom, "origin", g_anchorBottomPos[idx]);
        DispatchKeyValue(ropeBottom, "targetname", g_nameRopeBottom[idx]);
        DispatchKeyValue(ropeBottom, "NextKey", g_nameRopeTop[idx]);
        DispatchKeyValue(ropeBottom, "RopeMaterial", "cable/cable.vmt");
        DispatchKeyValue(ropeBottom, "Width", "2");
        DispatchKeyValue(ropeBottom, "MoveSpeed", "64");
        DispatchKeyValue(ropeBottom, "Subdiv", "0");
        DispatchKeyValue(ropeBottom, "Slack", "0");
        DispatchKeyValue(ropeBottom, "Type", "2");
        DispatchKeyValue(ropeBottom, "parentname", g_nameAnchorBottom[idx]);
        DispatchSpawn(ropeBottom);
        ActivateEntity(ropeBottom);
        g_ropeBottom[idx] = EntIndexToEntRef(ropeBottom);
    } else {
        g_ropeBottom[idx] = INVALID_ENT_REFERENCE;
    }

    return Plugin_Stop;
}

public Action Timer_EnableRope(Handle timer, any data)
{
    if (g_mapEnding) return Plugin_Stop;

    int idx = view_as<int>(data);
    if (idx < 0 || idx >= MAX_ROPES) return Plugin_Stop;

    int centerEnt = EntRefToEntIndex(g_centerShootable[idx]);
    if (g_centerDestroyed[idx] || centerEnt == INVALID_ENT_REFERENCE || !IsValidEntity(centerEnt)) {
        if (g_ropeState[idx] != State_Completed) {
            FinalizeVisualState(idx);
        }
        return Plugin_Stop;
    }

    g_ropeState[idx] = State_Ready;
    if (g_touchTimer[idx] == null) {
        g_touchTimer[idx] = CreateTimer(TIMER_INTERVAL_TOUCH, Timer_CheckTouch, idx, TIMER_REPEAT);
    }

    return Plugin_Stop;
}

public Action Timer_CheckTouch(Handle timer, any data)
{
    if (g_mapEnding)
        return Plugin_Stop;

    int idx = view_as<int>(data);
    if (idx < 0 || idx >= MAX_ROPES)
        return Plugin_Stop;

    // Stale timer protection
    if (g_touchTimer[idx] != timer)
        return Plugin_Stop;

    // Rope already done
    if (g_ropeState[idx] == State_Completed)
    {
        g_touchTimer[idx] = null;
        return Plugin_Stop;
    }

    int centerEnt = EntRefToEntIndex(g_centerShootable[idx]);

    // Center entity gone
    if (g_centerDestroyed[idx] || centerEnt == INVALID_ENT_REFERENCE || !IsValidEntity(centerEnt))
    {
        FinalizeVisualState(idx);
        g_touchTimer[idx] = null;
        return Plugin_Stop;
    }

    // Only check touch in ready state
    if (g_ropeState[idx] != State_Ready)
        return Plugin_Continue;

    int bottomEnt = EntRefToEntIndex(g_anchorBottom[idx]);
    int topEnt = EntRefToEntIndex(g_anchorTop[idx]);

    // Anchors must exist
    if (bottomEnt == INVALID_ENT_REFERENCE || topEnt == INVALID_ENT_REFERENCE ||
        !IsValidEntity(bottomEnt) || !IsValidEntity(topEnt))
    {
        g_touchTimer[idx] = null;
        return Plugin_Stop;
    }

    float bottomPos[3];
    float topPos[3];

    GetEntPropVector(bottomEnt, Prop_Send, "m_vecOrigin", bottomPos);
    GetEntPropVector(topEnt,    Prop_Send, "m_vecOrigin", topPos);

    // Pre-calc vertical bounds (guaranteed correct order)
    float zMin = bottomPos[2] - 90;
    float zMax = topPos[2]-30;

    for (int client = 1; client <= MaxClients; client++)
    {
        if (!IsClientInGame(client) || !IsPlayerAlive(client))
            continue;

        if (GetClientTeam(client) != 2)
            continue; // survivors only

        if (IsClientIncapped(client))
        {
            if (g_clientRope[client] == idx || g_pulledEntity[idx] == client)
                SafeReleasePulledSurvivor(idx);

            continue;
        }

        // Already attached to some rope
        if (g_clientRope[client] != -1)
            continue;

        float pos[3];
        GetClientAbsOrigin(client, pos);

        // Z-axis constraint: must be between bottom and top anchors
        if (pos[2] < zMin || pos[2] > zMax)
            continue;

        // XY radius check around bottom anchor
        float dx = pos[0] - bottomPos[0];
        float dy = pos[1] - bottomPos[1];
        float dist = SquareRoot(dx*dx + dy*dy);

        if (dist < TOUCH_RADIUS)
        {
            StartPullingClient(idx, client);
            g_touchTimer[idx] = null;
            return Plugin_Stop;
        }
    }

    return Plugin_Continue;
}

void StartPullingClient(int idx, int client)
{
    int topEnt = EntRefToEntIndex(g_anchorTop[idx]);
    int bottomEnt = EntRefToEntIndex(g_anchorBottom[idx]);
    if (topEnt == INVALID_ENT_REFERENCE || bottomEnt == INVALID_ENT_REFERENCE) return;

    float topPos[3];
    GetEntPropVector(topEnt, Prop_Send, "m_vecOrigin", topPos);
    g_targetZ[idx] = topPos[2] - TARGET_HEIGHT_OFFSET;

    g_pulledEntity[idx] = client;
    g_clientRope[client] = idx;

    SetEntityMoveType(client, MOVETYPE_NONE);

    float anchorPos[3];
    GetEntPropVector(bottomEnt, Prop_Send, "m_vecOrigin", anchorPos);

    float pos[3];
    GetClientAbsOrigin(client, pos);
    pos[0] = anchorPos[0];
    pos[1] = anchorPos[1] + 3.0;

    float vel[3] = {0.0, 0.0, PULL_VELOCITY_Z};
    TeleportEntity(client, pos, NULL_VECTOR, vel);

    float cpos[3];
    GetClientAbsOrigin(client, cpos);
    g_lastZ[idx] = cpos[2];
    g_stallTicks[idx] = 0;
    g_takeoverRetries[idx] = 0;
    g_handoffPending[idx] = false;

    g_pulledPos[idx][0] = cpos[0];
    g_pulledPos[idx][1] = cpos[1];
    g_pulledPos[idx][2] = cpos[2];

    g_ropeState[idx] = State_Pulling;

    if (g_pullTimer[idx] == null) {
        g_pullTimer[idx] = CreateTimer(TIMER_INTERVAL_PULL_AND_SAG, Timer_PullUp, idx, TIMER_REPEAT);
    }
    if (g_wobbleTimer[idx] == null) {
        g_wobbleTimer[idx] = CreateTimer(TIMER_INTERVAL_WOBBLE, Timer_Wobble, idx, TIMER_REPEAT);
    }
    if (g_soundTimer[idx] == null) {
        g_soundTimer[idx] = CreateTimer(TIMER_INTERVAL_SOUND, Timer_PlayDragSound, idx, TIMER_REPEAT);
    }

    DebugLog("Rope %d grabbed client %N", idx, client);
}

public Action Timer_Wobble(Handle timer, any data)
{
    if (g_mapEnding) return Plugin_Stop;

    int idx = view_as<int>(data);
    if (idx < 0 || idx >= MAX_ROPES) return Plugin_Stop;

    if (g_wobbleTimer[idx] != timer) {
        return Plugin_Stop;
    }

    if (g_ropeState[idx] != State_Pulling && g_ropeState[idx] != State_Animating) {
        g_wobbleTimer[idx] = null;
        return Plugin_Stop;
    }

    float t = GetEngineTime();
    float amplitude[FLESH_CIRCLE_COUNT] = {0.0, 6.0, 4.0, 2.5};
    float speed = 2.5;

    for (int c = 1; c <= 3; c++) {
        for (int i2 = 0; i2 < FLESH_CIRCLE_POINTS; i2++) {
            int ent = EntRefToEntIndex(g_circleEnts[idx][c][i2]);
            if (ent == INVALID_ENT_REFERENCE || !IsValidEntity(ent)) continue;

            float base[3];
            base[0] = g_circleBasePos[idx][c][i2][0];
            base[1] = g_circleBasePos[idx][c][i2][1];
            base[2] = g_circleBasePos[idx][c][i2][2];

            float ang[3];
            ang[0] = g_circleBaseAng[idx][c][i2][0];
            ang[1] = g_circleBaseAng[idx][c][i2][1];
            ang[2] = g_circleBaseAng[idx][c][i2][2];

            float phase = (float(i2) * 0.7) + (float(c) * 0.9);
            float z = base[2] + Sine(t * speed + phase) * amplitude[c];

            float pos[3];
            pos[0] = base[0];
            pos[1] = base[1];
            pos[2] = z;

            TeleportEntity(ent, pos, ang, NULL_VECTOR);
        }
    }

    return Plugin_Continue;
}

public Action Timer_PlayDragSound(Handle timer, any data)
{
    if (g_mapEnding) return Plugin_Stop;

    int idx = view_as<int>(data);
    if (idx < 0 || idx >= MAX_ROPES) return Plugin_Stop;

    if (g_soundTimer[idx] != timer) {
        return Plugin_Stop;
    }

    if (g_ropeState[idx] != State_Pulling && g_ropeState[idx] != State_Animating) {
        g_soundTimer[idx] = null;
        return Plugin_Stop;
    }

    float originTop[3];
    originTop[0] = g_anchorTopPos[idx][0];
    originTop[1] = g_anchorTopPos[idx][1];
    originTop[2] = g_anchorTopPos[idx][2];

    EmitSoundToAll(SOUND_DRAG, -1, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, originTop);

    return Plugin_Continue;
}

public Action Timer_PullUp(Handle timer, any data)
{
    if (g_mapEnding) return Plugin_Stop;

    int idx = view_as<int>(data);
    if (idx < 0 || idx >= MAX_ROPES) return Plugin_Stop;

    if (g_pullTimer[idx] != timer) {
        return Plugin_Stop;
    }

    if (g_ropeState[idx] == State_Completed) {
        g_pullTimer[idx] = null;
        return Plugin_Stop;
    }

    int centerEnt = EntRefToEntIndex(g_centerShootable[idx]);
    if (g_centerDestroyed[idx] || centerEnt == INVALID_ENT_REFERENCE || !IsValidEntity(centerEnt)) {
        if (g_ropeState[idx] == State_Pulling && g_pulledEntity[idx] > 0) {
            SafeReleasePulledSurvivor(idx);
        }

        g_ropeState[idx] = State_Completed;
        g_pullTimer[idx] = null;
        SafeStopTimer(g_wobbleTimer[idx], null);
        SafeStopTimer(g_soundTimer[idx], null);

        FinalizeVisualState(idx);
        return Plugin_Stop;
    }

    int bottomEnt = EntRefToEntIndex(g_anchorBottom[idx]);
    int topEnt = EntRefToEntIndex(g_anchorTop[idx]);

    if (bottomEnt == INVALID_ENT_REFERENCE || topEnt == INVALID_ENT_REFERENCE ||
        !IsValidEntity(bottomEnt) || !IsValidEntity(topEnt)) {
        g_ropeState[idx] = State_Completed;
        g_pullTimer[idx] = null;
        SafeStopTimer(g_wobbleTimer[idx], null);
        SafeStopTimer(g_soundTimer[idx], null);
        return Plugin_Stop;
    }

    int controller = g_pulledEntity[idx];

    if (controller == -1 || !IsClientInGame(controller) || GetClientTeam(controller) != 2) {
        if (HandleControllerHandoff(idx, controller)) {
            return Plugin_Continue;
        }
        return Plugin_Stop;
    }

    if (!IsPlayerAlive(controller) || IsClientIncapped(controller)) {
        CompletePull(idx, timer);
        return Plugin_Stop;
    }

    for (int i = 1; i <= MaxClients; i++) {
       if (IsClientInGame(i) && GetClientTeam(i) == 3) {
           if (GetEntPropEnt(i, Prop_Send, "m_tongueVictim") == controller ||
               GetEntPropEnt(i, Prop_Send, "m_pounceVictim") == controller) {
               CompletePull(idx, timer);
               return Plugin_Stop;
           }
       }
    }

    if (g_timerLock[idx]) return Plugin_Continue;
    g_timerLock[idx] = true;

    SetEntityMoveType(controller, MOVETYPE_NONE);

    float pos[3];
    GetClientAbsOrigin(controller, pos);

    g_pulledPos[idx][0] = pos[0];
    g_pulledPos[idx][1] = pos[1];
    g_pulledPos[idx][2] = pos[2];

    float anchorPos[3];
    GetEntPropVector(bottomEnt, Prop_Send, "m_vecOrigin", anchorPos);

    float dx = pos[0] - anchorPos[0];
    float dy = pos[1] - anchorPos[1];
    float dist = SquareRoot(dx * dx + dy * dy);

    float releaseRadius = TOUCH_RADIUS * 1.5;
    if (dist > releaseRadius) {
        g_timerLock[idx] = false;
        DebugLog("Rope %d: survivor moved out of range (%.1f > %.1f), releasing", idx, dist, releaseRadius);
        CompletePull(idx, timer);
        return Plugin_Stop;
    }

    if (pos[2] <= g_lastZ[idx] + STALL_CHECK_THRESHOLD) {
        g_stallTicks[idx]++;
        if (g_stallTicks[idx] >= STALL_TICK_LIMIT) {
            float vel[3] = {0.0, 0.0, PULL_BOOST_VELOCITY};
            TeleportEntity(controller, NULL_VECTOR, NULL_VECTOR, vel);
            g_stallTicks[idx] = 0;
        }
    } else {
        g_stallTicks[idx] = 0;
    }
    g_lastZ[idx] = pos[2];

    if (g_ropeState[idx] != State_Completed && pos[2] >= g_targetZ[idx]) {
        g_timerLock[idx] = false;
        CompletePullWithDamage(idx, timer, controller);
        return Plugin_Stop;
    }

    float pullSpeed = g_cvPullSpeed.FloatValue;
    pos[0] = anchorPos[0];
    pos[1] = anchorPos[1] + 3.0;
    pos[2] += pullSpeed;
    TeleportEntity(controller, pos, NULL_VECTOR, NULL_VECTOR);

    if (bottomEnt != INVALID_ENT_REFERENCE && IsValidEntity(bottomEnt)) {
        float bpos[3];
        GetEntPropVector(bottomEnt, Prop_Send, "m_vecOrigin", bpos);

        float maxBottomZ = g_anchorTopPos[idx][2] - ROPE_MIN_DISTANCE;
        if (bpos[2] + pullSpeed > maxBottomZ) {
            bpos[2] = maxBottomZ;
        } else {
            bpos[2] += pullSpeed;
        }

        TeleportEntity(bottomEnt, bpos, NULL_VECTOR, NULL_VECTOR);

        int ropeBottomEnt = EntRefToEntIndex(g_ropeBottom[idx]);
        if (ropeBottomEnt != INVALID_ENT_REFERENCE && IsValidEntity(ropeBottomEnt)) {
            TeleportEntity(ropeBottomEnt, bpos, NULL_VECTOR, NULL_VECTOR);
        }

        if (bpos[2] >= g_targetZ[idx]) {
            g_timerLock[idx] = false;
            CompletePullWithDamage(idx, timer, controller);
            return Plugin_Stop;
        }
    }

    g_timerLock[idx] = false;
    return Plugin_Continue;
}

// ====================================================================================================
// Handoff System and completion helpers
// ====================================================================================================
bool OriginsMatchWithinXYZ(int client1, int client2, float tolX, float tolY, float tolZ)
{
    float p1[3], p2[3];
    GetClientAbsOrigin(client1, p1);
    GetClientAbsOrigin(client2, p2);

    return (FloatAbs(p1[0] - p2[0]) <= tolX &&
            FloatAbs(p1[1] - p2[1]) <= tolY &&
            FloatAbs(p1[2] - p2[2]) <= tolZ);
}

int FindMatchingSurvivorByOriginWithinXYZ(float x, float y, float z, float tolX, float tolY, float tolZ)
{
    for (int i = 1; i <= MaxClients; i++) {
        if (!IsClientInGame(i) || !IsPlayerAlive(i)) continue;
        if (GetClientTeam(i) != 2) continue;
        if (g_clientRope[i] != -1) continue;

        float p[3];
        GetClientAbsOrigin(i, p);

        if (FloatAbs(p[0] - x) <= tolX &&
            FloatAbs(p[1] - y) <= tolY &&
            FloatAbs(p[2] - z) <= tolZ) {
            return i;
        }
    }
    return -1;
}

bool HandleControllerHandoff(int idx, int oldController)
{
    g_handoffPending[idx] = true;

    int candidate = FindMatchingSurvivorByOriginWithinXYZ(
        g_pulledPos[idx][0], g_pulledPos[idx][1], g_pulledPos[idx][2],
        HANDOFF_TOL_X, HANDOFF_TOL_Y, HANDOFF_TOL_Z
    );

    if (candidate > 0 && g_clientRope[candidate] == -1) {
        if (oldController > 0 && g_clientRope[oldController] == idx) {
            g_clientRope[oldController] = -1;
        }

        g_pulledEntity[idx] = candidate;
        g_clientRope[candidate] = idx;
        SetEntityMoveType(candidate, MOVETYPE_NONE);

        float vel[3] = {0.0, 0.0, PULL_VELOCITY_Z};
        TeleportEntity(candidate, NULL_VECTOR, NULL_VECTOR, vel);

        g_handoffPending[idx] = false;
        g_takeoverRetries[idx] = 0;

        DebugLog("Rope %d handed off via tolerant XYZ origin match", idx);
        return true;
    }

    if (g_takeoverRetries[idx] < TAKEOVER_RETRY_LIMIT) {
        g_takeoverRetries[idx]++;
        return true;
    }

    g_ropeState[idx] = State_Completed;
    g_pullTimer[idx] = null;
    SafeStopTimer(g_wobbleTimer[idx], null);
    SafeStopTimer(g_soundTimer[idx], null);
    SafeReleasePulledSurvivor(idx);
    FinalizeVisualState(idx);
    return false;
}

void CompletePull(int idx, Handle timer)
{
    g_ropeState[idx] = State_Completed;
    
    if (g_pullTimer[idx] == timer) {
        g_pullTimer[idx] = null;
    }
    
    SafeStopTimer(g_wobbleTimer[idx], null);
    SafeStopTimer(g_soundTimer[idx], null);
    SafeReleasePulledSurvivor(idx);
    FinalizeVisualState(idx);
}

void CompletePullWithDamage(int idx, Handle timer, int survivor)
{
    KillCenterProp(idx);

    g_ropeState[idx] = State_Completed;
    
    if (g_pullTimer[idx] == timer) {
        g_pullTimer[idx] = null;
    }
    
    SafeStopTimer(g_wobbleTimer[idx], null);
    SafeStopTimer(g_soundTimer[idx], null);

    SafeReleasePulledSurvivor(idx);

    if (survivor > 0 && IsClientInGame(survivor) && IsPlayerAlive(survivor)) {
        float dmg = g_cvCompletionDamage.FloatValue;
        SDKHooks_TakeDamage(survivor, survivor, survivor, dmg, DMG_GENERIC);
    }

    FinalizeVisualState(idx);
}

// ====================================================================================================
// Finalization
// ====================================================================================================
void FinalizeVisualState(int idx)
{
    if (g_ropeState[idx] == State_Pulling && g_pulledEntity[idx] > 0) {
        SafeReleasePulledSurvivor(idx);
    }

    SafeStopTimer(g_touchTimer[idx], null);
    SafeStopTimer(g_pullTimer[idx], null);
    SafeStopTimer(g_wobbleTimer[idx], null);
    SafeStopTimer(g_soundTimer[idx], null);
    SafeStopTimer(g_sagTimer[idx], null);

    AnimateRopeSag(idx, SAG_TARGET_FINAL);

    DebugLog("Rope %d finalized", idx);
}

// ====================================================================================================
// Cleanup
// ====================================================================================================

void KillByTargetname(const char[] targetname)
{
    int maxEnts = GetMaxEntities();
    for (int ent = MaxClients + 1; ent < maxEnts; ent++)
    {
        if (!IsValidEntity(ent))
            continue;

        char name[NAMEBUF];
        GetEntPropString(ent, Prop_Data, "m_iName", name, sizeof(name));
        if (StrEqual(name, targetname))
        {
            AcceptEntityInput(ent, "Kill");
            break;
        }
    }
}

void CleanupInstance(int idx, bool fullErase)
{
    if (idx < 0 || idx >= MAX_ROPES) return;

    DebugLog("CleanupInstance called for rope %d (fullErase=%d)", idx, fullErase);

    SafeStopTimer(g_touchTimer[idx], null);
    SafeStopTimer(g_pullTimer[idx], null);
    SafeStopTimer(g_wobbleTimer[idx], null);
    SafeStopTimer(g_soundTimer[idx], null);
    SafeStopTimer(g_sagTimer[idx], null);

    SafeStopTimer(g_cleanupTimer[idx], null);

    int controller = g_pulledEntity[idx];
    if (controller > 0 && controller <= MaxClients && g_clientRope[controller] == idx) {
        g_clientRope[controller] = -1;
    }
    g_pulledEntity[idx] = -1;

    KillByTargetname(g_nameRopeTop[idx]);
    KillByTargetname(g_nameRopeBottom[idx]);
    KillByTargetname(g_nameAnchorTop[idx]);
    KillByTargetname(g_nameAnchorBottom[idx]);

    if (fullErase) {
        g_ropeTop[idx] = INVALID_ENT_REFERENCE;
        g_ropeBottom[idx] = INVALID_ENT_REFERENCE;
        g_anchorTop[idx] = INVALID_ENT_REFERENCE;
        g_anchorBottom[idx] = INVALID_ENT_REFERENCE;
    }

    for (int c = 0; c < FLESH_CIRCLE_COUNT; c++) {
        for (int p = 0; p < FLESH_CIRCLE_POINTS; p++) {
            KillByTargetname(g_nameCircleEnt[idx][c][p]);
            g_circleEnts[idx][c][p] = INVALID_ENT_REFERENCE;
        }
    }

    int centerEnt = EntRefToEntIndex(g_centerShootable[idx]);
    if (centerEnt != INVALID_ENT_REFERENCE && IsValidEntity(centerEnt)) {
        SDKUnhook(centerEnt, SDKHook_OnTakeDamage, Center_OnTakeDamage);
    }
    KillByTargetname(g_nameCenterShootable[idx]);
    g_centerShootable[idx] = INVALID_ENT_REFERENCE;
    g_centerDestroyed[idx] = true;
    g_centerHealth[idx] = 0;

    g_finalizationSpawned[idx] = false;
    g_ropeState[idx] = State_Idle;

    DebugLog("Rope %d cleaned (%s)", idx, fullErase ? "full erase" : "runtime only");
}

// ====================================================================================================
// Slot Management
// ====================================================================================================
int FindFreeRopeSlot()
{
    int limit = g_cvMaxRopes.IntValue;

    if (limit > MAX_ROPES)
        limit = MAX_ROPES;

    for (int i = 0; i < limit; i++) {
        if (g_ropeState[i] == State_Idle) {

            bool hasGibs = false;
            for (int c = 0; c < FLESH_CIRCLE_COUNT && !hasGibs; c++) {
                for (int p = 0; p < FLESH_CIRCLE_POINTS; p++) {
                    int ent = EntRefToEntIndex(g_circleEnts[i][c][p]);
                    if (ent != INVALID_ENT_REFERENCE && IsValidEntity(ent)) {
                        hasGibs = true;
                        break;
                    }
                }
            }

            if (!hasGibs &&
                EntRefToEntIndex(g_anchorTop[i]) == INVALID_ENT_REFERENCE &&
                EntRefToEntIndex(g_anchorBottom[i]) == INVALID_ENT_REFERENCE) {
                return i;
            }
        }
    }

    return -1;
}

// ====================================================================================================
// Handoff Events
// ====================================================================================================
public void Event_BotReplace(Event event, const char[] name, bool dontBroadcast)
{
    int bot = GetClientOfUserId(event.GetInt("botid"));
    int player = GetClientOfUserId(event.GetInt("playerid"));

    for (int idx = 0; idx < MAX_ROPES; idx++) {
        if (g_pulledEntity[idx] == player && bot > 0 && IsClientInGame(bot)) {
            if (OriginsMatchWithinXYZ(bot, player, HANDOFF_TOL_X, HANDOFF_TOL_Y, HANDOFF_TOL_Z)) {
                if (player > 0 && g_clientRope[player] == idx) {
                    g_clientRope[player] = -1;
                }

                g_pulledEntity[idx] = bot;
                g_clientRope[bot] = idx;
                g_handoffPending[idx] = false;

                float p[3];
                GetClientAbsOrigin(bot, p);
                g_pulledPos[idx][0] = p[0];
                g_pulledPos[idx][1] = p[1];
                g_pulledPos[idx][2] = p[2];

                SetEntityMoveType(bot, MOVETYPE_NONE);
                float vel[3] = {0.0, 0.0, PULL_VELOCITY_Z};
                TeleportEntity(bot, NULL_VECTOR, NULL_VECTOR, vel);

                DebugLog("Bot replaced player in rope %d via tolerant origin XYZ", idx);
            }
        }
    }
}

public void Event_PlayerReplace(Event event, const char[] name, bool dontBroadcast)
{
    int player = GetClientOfUserId(event.GetInt("playerid"));
    int bot = GetClientOfUserId(event.GetInt("botid"));

    for (int idx = 0; idx < MAX_ROPES; idx++) {
        if (g_pulledEntity[idx] == bot && player > 0 && IsClientInGame(player)) {
            if (OriginsMatchWithinXYZ(player, bot, HANDOFF_TOL_X, HANDOFF_TOL_Y, HANDOFF_TOL_Z)) {
                if (bot > 0 && g_clientRope[bot] == idx) {
                    g_clientRope[bot] = -1;
                }

                g_pulledEntity[idx] = player;
                g_clientRope[player] = idx;
                g_handoffPending[idx] = false;

                float p[3];
                GetClientAbsOrigin(player, p);
                g_pulledPos[idx][0] = p[0];
                g_pulledPos[idx][1] = p[1];
                g_pulledPos[idx][2] = p[2];

                SetEntityMoveType(player, MOVETYPE_NONE);
                float vel[3] = {0.0, 0.0, PULL_VELOCITY_Z};
                TeleportEntity(player, NULL_VECTOR, NULL_VECTOR, vel);

                DebugLog("Player replaced bot in rope %d via tolerant origin XYZ", idx);
            }
        }
    }
}

public void Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    int oldteam = event.GetInt("oldteam");
    int newteam = event.GetInt("team");

    if (oldteam == 2 && newteam != 2) {
        for (int idx = 0; idx < MAX_ROPES; idx++) {
            if (g_pulledEntity[idx] == client) {
                g_handoffPending[idx] = true;
                g_takeoverRetries[idx] = 0;

                if (client > 0 && g_clientRope[client] == idx) {
                    g_clientRope[client] = -1;
                }

                int newController = FindMatchingSurvivorByOriginWithinXYZ(
                    g_pulledPos[idx][0], g_pulledPos[idx][1], g_pulledPos[idx][2],
                    HANDOFF_TOL_X, HANDOFF_TOL_Y, HANDOFF_TOL_Z
                );
                if (newController > 0 && g_clientRope[newController] == -1) {
                    g_pulledEntity[idx] = newController;
                    g_clientRope[newController] = idx;
                    g_handoffPending[idx] = false;

                    SetEntityMoveType(newController, MOVETYPE_NONE);
                    float vel[3] = {0.0, 0.0, PULL_VELOCITY_Z};
                    TeleportEntity(newController, NULL_VECTOR, NULL_VECTOR, vel);

                    DebugLog("Team change: handed off rope %d via tolerant origin XYZ", idx);
                }
            }
        }
    }
}

public void OnClientDisconnect(int client)
{
    for (int idx = 0; idx < MAX_ROPES; idx++) {
        if (g_pulledEntity[idx] == client) {
            if (g_clientRope[client] == idx) {
                g_clientRope[client] = -1;
            }
            g_handoffPending[idx] = true;
            g_takeoverRetries[idx] = 0;
        }
    }

    if (client > 0 && g_clientRope[client] != -1) {
        g_clientRope[client] = -1;
    }
}

// ====================================================================================================
// Trace Filter
// ====================================================================================================
public bool TraceEntityFilter(int entity, int contentsMask)
{
    if (entity >= 1 && entity <= MaxClients) {
        if (IsClientInGame(entity)) return false;
    }
    return true;
}
