#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <dhooks>
#include <sdkhooks>

#undef CVAR_FLAGS 
#define CVAR_FLAGS                   FCVAR_NOTIFY
#define CVAR_FLAGS_PLUGIN_VERSION    FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_SPONLY
#define PLUGIN_VERSION              "1.4.3"
#define FILE_NAME                   "l4d2_mix_map"
#define PREFIX                      "[Marathon Mode]"
#define MAXWEAPONNAME               64
#define MAX_HEALTH                  100
#define MAX_TEMP_HEALTH            100
#define RESCUE_HEALTH              100
#define DEFIB_HEALTH               100
#define DEFAULT_INCAP_HEALTH        300

Address g_pDirector;
Handle g_hSDK_CDirector_IsFirstMapInScenario;

enum struct CampaignInfo {
    char firstMap[64];
    char finaleMap[64];
    char name[64];
}

enum struct PlayerStats {
    int health;
    float tempHealth;
    char primaryWeapon[MAXWEAPONNAME];
    int primaryAmmo;      // Reserve ammo for primary weapon
    int primaryClip;      // Main clip ammo for primary weapon
    char secondaryWeapon[MAXWEAPONNAME];
    char throwable[MAXWEAPONNAME];
    char healSlot[MAXWEAPONNAME];
    char pillsSlot[MAXWEAPONNAME];
    bool wasIncapacitated;
    bool hasStats;
    float saveTime;      // Timestamp when stats were saved
}

static const CampaignInfo g_Campaigns[] = {
    {"c1m1_hotel", "c1m4_atrium", "Dead Center"},
    {"c6m1_riverbank", "c6m3_port", "The Passing"},
    {"c2m1_highway", "c2m5_concert", "Dark Carnival"},
    {"c3m1_plankcountry", "c3m4_plantation", "Swamp Fever"},
    {"c4m1_milltown_a", "c4m5_milltown_escape", "Hard Rain"},
    {"c5m1_waterfront", "c5m5_bridge", "The Parish"},
    {"c13m1_alpinecreek", "c13m4_cutthroatcreek", "Cold Stream"},
    {"c8m1_apartment", "c8m5_rooftop", "No Mercy"},
    {"c9m1_alleys", "c9m2_lots", "Crash Course"},
    {"c10m1_caves", "c10m5_houseboat", "Death Toll"},
    {"c14m1_junkyard", "c14m2_lighthouse", "The Last Stand"},
    {"c11m1_greenhouse", "c11m5_runway", "Dead Air"},
    {"c12m1_hilltop", "c12m5_cornfield", "Blood Harvest"},
    {"c7m1_docks", "c7m3_port", "The Sacrifice"}
};

char
    g_sValidLandMarkName[128];

bool
    g_bInited,
    g_bEnable,
    g_bStart,
    g_bSpawn,
    g_bIsValid,
    g_bFirstMap,
    g_bIsFinaleMap,
    g_bShouldRestoreStats,
    g_bRestoreFromMapStartOnRestart,
    g_bPendingMapStartSnapshot,
    g_bHasSeenWelcomeMessage[MAXPLAYERS + 1],
    g_bPlayerWasDead[MAXPLAYERS + 1],
    g_bPlayerWasRescued[MAXPLAYERS + 1]; // New flag to track rescued players

PlayerStats g_PlayerStats[MAXPLAYERS + 1];
PlayerStats g_MapStartStats[MAXPLAYERS + 1];

ConVar
    g_hCvar_Enable,
    g_hCvar_TransitionTime,
    g_hCvar_FinaleTime,
    g_hCvar_FinaleCamera,
    g_hCvar_SaveFrequency;

StringMap
    g_mMapLandMarkSet,
    g_mMapSet;

StringMapSnapshot
    g_msMapLandMarkSet,
    g_msMapSet;

// Helper function for string formatting
stock char[] String_Format(const char[] format, any ...)
{
    char buffer[1024];
    VFormat(buffer, sizeof(buffer), format, 2);
    return buffer;
}

// Add this function to check if we're in an active marathon
static bool IsInMarathon()
{
    // We're in a marathon if we have stats to restore
    // or if players have active stats
    if (g_bShouldRestoreStats)
        return true;
        
    // Check if any players have active stats
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && g_PlayerStats[i].hasStats)
            return true;
    }
    
    return false;
}

public Plugin myinfo =
{
    name = "Marathon Mode",
    author = "Yuzumi, Modified by Mezo123451A",
    description = "Sequential campaign progression with stats saving",
    version = PLUGIN_VERSION,
    url = ""
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    EngineVersion engine = GetEngineVersion();
    if(engine != Engine_Left4Dead2)
    {
        strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
        return APLRes_SilentFailure;
    }
    return APLRes_Success;
}

static void InitGameData()
{
    char sPath[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, sPath, sizeof(sPath), "gamedata/%s.txt", FILE_NAME);
    if(!FileExists(sPath))
    {
        SetFailState("\n==========\nMissing required file: \"%s\".\n==========", sPath);
    }

    GameData hGameData = new GameData(FILE_NAME);
    if(!hGameData)
    {
        SetFailState("Failed to load \"%s.txt\" gamedata.", FILE_NAME);
    }

    g_pDirector = hGameData.GetAddress("CDirector");
    if(!g_pDirector)
    {
        SetFailState("Failed to find address: \"CDirector\"");
    }

    StartPrepSDKCall(SDKCall_Raw);
    if(!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CDirector::IsFirstMapInScenario"))
    {
        SetFailState("Failed to find signature: \"CDirector::IsFirstMapInScenario\"");
    }
    PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
    g_hSDK_CDirector_IsFirstMapInScenario = EndPrepSDKCall();
    if(!g_hSDK_CDirector_IsFirstMapInScenario)
    {
        SetFailState("Failed to create SDKCall: \"CDirector::IsFirstMapInScenario\"");
    }

    delete hGameData;
}

public void OnPluginStart()
{
    g_mMapLandMarkSet = new StringMap();
    g_mMapSet = new StringMap();
    LoadKvFile();

    InitGameData();

    // Register version ConVar (this one doesn't need to be in config)
    CreateConVar("l4d2_marathon_version", PLUGIN_VERSION, "Marathon Mode version.", CVAR_FLAGS_PLUGIN_VERSION);
    
    // Register main plugin ConVars with explicit flags
    g_hCvar_Enable = CreateConVar("l4d2_marathon_enable", "1", 
        "Enable Marathon Mode plugin [0=OFF, 1=ON]", 
        FCVAR_NOTIFY, 
        true, 0.0, 
        true, 1.0);
    
    g_hCvar_TransitionTime = CreateConVar("l4d2_marathon_transition_time", "4.0", 
        "Time to wait before normal map transition", 
        FCVAR_NOTIFY, 
        true, 0.1);
    
    g_hCvar_FinaleTime = CreateConVar("l4d2_marathon_finale_time", "3.0", 
        "Time to wait after finale before transition", 
        FCVAR_NOTIFY, 
        true, 0.1);
    
    g_hCvar_SaveFrequency = CreateConVar("l4d2_marathon_save_frequency", "5.0", 
        "How often to save player stats (in seconds)", 
        FCVAR_NOTIFY, 
        true, 0.1, 
        true, 5.0);
    
    // Initialize finale camera ConVar
    g_hCvar_FinaleCamera = FindConVar("director_no_finale_camera");
    if (g_hCvar_FinaleCamera == null)
    {
        g_hCvar_FinaleCamera = CreateConVar("director_no_finale_camera", "0", 
            "Disable finale camera sequence", 
            FCVAR_NOTIFY);
    }

    // Create the auto config
    AutoExecConfig(true, "l4d2_marathon");

    // Initialize the welcome message tracker
    for (int i = 1; i <= MaxClients; i++)
    {
        g_bHasSeenWelcomeMessage[i] = false;
    }

    // Initialize player state tracking
    for (int i = 1; i <= MaxClients; i++)
    {
        g_bPlayerWasDead[i] = false;
    }

    // Rest of the initialization
    g_hCvar_Enable.AddChangeHook(CvarChange);
    RegAdminCmd("sm_marathon_reload", Command_Reload, ADMFLAG_ROOT, "Reload map config");

    HookEvent("finale_vehicle_leaving", Event_FinaleVehicleLeaving, EventHookMode_Pre);
    HookEvent("finale_win", Event_FinaleWin, EventHookMode_Pre);
    HookEvent("mission_lost", Event_MissionLost, EventHookMode_Pre);
    HookEvent("map_transition", Event_MapTransition, EventHookMode_Pre);
    HookEvent("player_spawn", Event_PlayerSpawn);
    HookEvent("player_death", Event_PlayerDeath); // Added event hook for player death
    HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
    HookEvent("survivor_rescued", Event_PlayerRevived);
    HookEvent("defibrillator_used", Event_PlayerRevived);

    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i))
        {
            OnClientPutInServer(i);
        }
    }

    Init();
    
    // Add a periodic check timer
    CreateTimer(30.0, Timer_StabilityCheck, _, TIMER_REPEAT);
    
    // Add continuous save timer
    CreateTimer(g_hCvar_SaveFrequency.FloatValue, Timer_ContinuousSave, _, TIMER_REPEAT);
}

// Handle defib and rescue events
public void Event_PlayerRevived(Event event, const char[] name, bool dontBroadcast)
{
    int client;
    bool isDefib = false;
    
    // Get the correct client based on the event type
    if (StrEqual(name, "survivor_rescued"))
    {
        client = GetClientOfUserId(event.GetInt("victim"));
        isDefib = false;
    }
    else if (StrEqual(name, "defibrillator_used"))
    {
        client = GetClientOfUserId(event.GetInt("subject"));
        isDefib = true;
    }
    
    if (client > 0 && IsClientInGame(client))
    {
        bool wasActuallyDead = g_bPlayerWasDead[client];
        
        if (isDefib)
        {
            if (!wasActuallyDead)
            {
                PrintToServer("%s Ignoring defib restore for %N because they were not marked dead", PREFIX, client);
                return;
            }
            
            // Defibrillated players get configured defib health and their previous live loadout.
            PrintToServer("%s Player %N was defibrillated - will get previous loadout", PREFIX, client);
            
            // Defibrillated players are not considered "rescued" for team wipe purposes
            g_bPlayerWasRescued[client] = false;
            g_bPlayerWasDead[client] = false;
            
            // Force-apply defibrillator loadout after a short delay
            DataPack dp = new DataPack();
            dp.WriteCell(GetClientUserId(client));
            CreateTimer(0.1, Timer_ForceDefibLoadout, dp, TIMER_DATA_HNDL_CLOSE);
        }
        else
        {
            // Rescued players get 100 HP and basic loadout
            PrintToServer("%s Player %N was rescued - will get basic loadout with 100 HP", PREFIX, client);
            
            // Mark this player as rescued (important for team wipe handling)
            g_bPlayerWasRescued[client] = true;
            g_bPlayerWasDead[client] = false;
            
            // Force-apply rescue closet loadout after a short delay
            DataPack dp = new DataPack();
            dp.WriteCell(GetClientUserId(client));
            CreateTimer(0.1, Timer_ForceRescueLoadout, dp, TIMER_DATA_HNDL_CLOSE);
        }
    }
}

// Timer to apply defibrillator loadout (50 HP + previous items)
public Action Timer_ForceDefibLoadout(Handle timer, DataPack dp)
{
    dp.Reset();
    int client = GetClientOfUserId(dp.ReadCell());
    
    if (client <= 0 || !IsClientInGame(client) || !IsPlayerAlive(client)) 
        return Plugin_Stop;
    
    // Set defib health (no temp health)
    SetEntityHealth(client, DEFIB_HEALTH);
    SetTempHealth(client, 0.0);
    
    // If we have saved stats, restore them (except health)
    if (g_bShouldRestoreStats && g_PlayerStats[client].hasStats)
    {
        // Remove all items first
        for (int slot = 0; slot <= 4; slot++)
        {
            int weapon = GetPlayerWeaponSlot(client, slot);
            if (weapon != -1)
            {
                RemovePlayerItem(client, weapon);
                AcceptEntityInput(weapon, "Kill");
            }
        }
        
        // Restore primary weapon with ammo
        if (g_PlayerStats[client].primaryWeapon[0] != '\0')
        {
            int weapon = GivePlayerItem(client, g_PlayerStats[client].primaryWeapon);
            if (weapon != -1)
            {
                SetEntProp(weapon, Prop_Send, "m_iClip1", g_PlayerStats[client].primaryClip);
                
                int ammoType = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
                if (ammoType != -1)
                {
                    SetEntProp(client, Prop_Send, "m_iAmmo", g_PlayerStats[client].primaryAmmo, _, ammoType);
                }
                
                PrintToServer("%s Restored primary weapon %s with clip: %d, reserve: %d for defibed player %N", 
                    PREFIX, 
                    g_PlayerStats[client].primaryWeapon, 
                    g_PlayerStats[client].primaryClip, 
                    g_PlayerStats[client].primaryAmmo,
                    client);
            }
        }
        
        // Restore secondary weapon
        if (g_PlayerStats[client].secondaryWeapon[0] != '\0')
        {
            // Check if it's a melee weapon
            if (StrContains(g_PlayerStats[client].secondaryWeapon, "melee_") == 0)
            {
                char meleeType[64];
                strcopy(meleeType, sizeof(meleeType), g_PlayerStats[client].secondaryWeapon[6]); // Skip "melee_"
                
                if (!IsValidMeleeWeapon(meleeType) || !CreateAndEquipMeleeWeapon(client, meleeType))
                {
                    GivePlayerItem(client, "weapon_pistol");
                    PrintToServer("%s Failed with melee, gave pistol to defibed player %N instead", PREFIX, client);
                }
            }
            else
            {
                GivePlayerItem(client, g_PlayerStats[client].secondaryWeapon);
            }
        }
        else
        {
            // Give a pistol if no secondary saved
            GivePlayerItem(client, "weapon_pistol");
        }
        
        // Restore other items
        if (g_PlayerStats[client].throwable[0] != '\0' && !PlayerHasWeapon(client, g_PlayerStats[client].throwable))
        {
            GivePlayerItem(client, g_PlayerStats[client].throwable);
        }
        
        if (g_PlayerStats[client].healSlot[0] != '\0' && !PlayerHasWeapon(client, g_PlayerStats[client].healSlot))
        {
            GivePlayerItem(client, g_PlayerStats[client].healSlot);
        }
        
        if (g_PlayerStats[client].pillsSlot[0] != '\0' && !PlayerHasWeapon(client, g_PlayerStats[client].pillsSlot))
        {
            GivePlayerItem(client, g_PlayerStats[client].pillsSlot);
        }
        
        SavePlayerStatsIndividual(client);
        PrintToServer("%s Restored full loadout for defibed player %N", PREFIX, client);
    }
    else
    {
        // No saved stats, give basic loadout
        ApplyBasicLoadout(client);
        SavePlayerStatsIndividual(client);
    }
    
    return Plugin_Stop;
}

// Timer to apply rescue closet loadout (100 HP + basic weapon)
public Action Timer_ForceRescueLoadout(Handle timer, DataPack dp)
{
    dp.Reset();
    int client = GetClientOfUserId(dp.ReadCell());
    
    if (client <= 0 || !IsClientInGame(client) || !IsPlayerAlive(client)) 
        return Plugin_Stop;
    
    // Apply basic loadout with 100 HP
    ApplyBasicLoadout(client);
    CreateTimer(0.3, Timer_EnsureBasicPistol, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
    CreateTimer(1.0, Timer_EnsureBasicPistol, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
    SavePlayerStatsIndividual(client);
    
    PrintToServer("%s Applied basic loadout to rescued player %N (100 HP + pistol)", PREFIX, client);
    return Plugin_Stop;
}

// Add this function to handle team wipe scenarios
public Action Event_MissionLost(Event event, const char[] name, bool dontBroadcast)
{
    if (!g_bEnable || !g_bIsValid) return Plugin_Continue;
    
    char currentMap[64];
    GetCurrentMap(currentMap, sizeof(currentMap));
    
    // Check if all players are dead
    bool allDead = true;
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
        {
            allDead = false;
            break;
        }
    }
    
    // If all players are dead on a non-finale map, restore the snapshot from when this map began.
    if (allDead && !IsFinaleMap(currentMap))
    {
        PrintToChatAll("\x04%s \x01Team wiped! Restoring equipment from the start of this map...", PREFIX);
        RestoreLiveStatsFromMapStart();
        g_bShouldRestoreStats = true;
        g_bRestoreFromMapStartOnRestart = true;
        
        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsClientInGame(i) && GetClientTeam(i) == 2)
            {
                g_bPlayerWasDead[i] = false;
                g_bPlayerWasRescued[i] = false;
            }
        }
        
        // Don't interfere with the game's normal mission lost handling.
        return Plugin_Continue;
    }
    
    // Only prevent mission loss on finale maps (except Last Stand)
    if (IsFinaleMap(currentMap) && !StrEqual(currentMap, "c14m2_lighthouse", false))
    {
        return Plugin_Handled;
    }
    
    // Don't reset stats on non-finale map losses if we're in a marathon
    if (!IsFinaleMap(currentMap) && IsInMarathon())
    {
        return Plugin_Continue;
    }
    
    // Reset only if we're not in a marathon or it's a finale loss
    g_bShouldRestoreStats = false;
    ResetAllPlayerStats();
    return Plugin_Continue;
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client > 0 && IsClientInGame(client) && GetClientTeam(client) == 2)
    {
        if (g_bPendingMapStartSnapshot)
        {
            CreateTimer(2.0, Timer_CaptureMapStartStats, _, TIMER_FLAG_NO_MAPCHANGE);
        }
        
        // If the player spawns after a team wipe, we don't want to treat them as previously dead
        // so we check if they were actually marked as dead from a previous map
        char currentMap[64];
        GetCurrentMap(currentMap, sizeof(currentMap));
        bool isPostWipe = false;
        bool isFirstMapOfCampaign = false;
        
        // Check if this is the first map of a campaign
        for (int i = 0; i < sizeof(g_Campaigns); i++)
        {
            if (StrEqual(currentMap, g_Campaigns[i].firstMap, false))
            {
                isFirstMapOfCampaign = true;
                break;
            }
        }
        
        // Check if we're after a team wipe (all players died on this map, not a finale)
        if (!IsFinaleMap(currentMap) && g_bShouldRestoreStats)
        {
            // This is a respawn after team wipe
            isPostWipe = true;
        }
        
        // After a mission failure, restore the snapshot taken when this map began.
        if (g_bRestoreFromMapStartOnRestart && g_PlayerStats[client].hasStats)
        {
            PrintToServer("%s Restoring map-start loadout for player %N after team wipe", PREFIX, client);
            g_bPlayerWasDead[client] = false;
            CreateTimer(0.5, Timer_RestorePlayerStatsByUserId, GetClientUserId(client));
        }
        // Handling for players who died and are respawning normally (not team wipe)
        else if (g_bPlayerWasDead[client] && !isPostWipe)
        {
            PrintToServer("%s Player %N spawned after being dead - applying basic loadout", PREFIX, client);
            // Use a delay to make sure we override default behavior
            CreateTimer(0.2, Timer_DelayedBasicLoadout, GetClientUserId(client));
        }
        // Special handling for first map of a new campaign after team wipe
        else if (isFirstMapOfCampaign && isPostWipe && g_bShouldRestoreStats && g_PlayerStats[client].hasStats)
        {
            PrintToServer("%s Player %N spawned after team wipe on first map - restoring previous campaign loadout", PREFIX, client);
            CreateTimer(0.5, Timer_RestorePlayerStats, client);
        }
        // Otherwise, restore normal stats if in a marathon
        else if (g_bShouldRestoreStats && g_PlayerStats[client].hasStats)
        {
            PrintToServer("%s Player %N spawned with saved stats - restoring", PREFIX, client);
            CreateTimer(0.5, Timer_RestorePlayerStats, client);
        }
    }
}

// Special timer for forced loadout restore after first map wipe
public Action Timer_ForceFirstMapWipeRestore(Handle timer, any userId)
{
    int client = GetClientOfUserId(userId);
    if (client <= 0 || !IsClientInGame(client) || !IsPlayerAlive(client)) 
        return Plugin_Stop;
    
    // Force restore their saved stats from previous campaign finale
    if (g_bShouldRestoreStats && g_PlayerStats[client].hasStats)
    {
        PrintToServer("%s FORCED loadout restore for player %N after first map wipe", PREFIX, client);
        
        // Set main health
        int healthToSet = g_PlayerStats[client].health;
        if (healthToSet <= 0) healthToSet = MAX_HEALTH;
        if (healthToSet > MAX_HEALTH) healthToSet = MAX_HEALTH;
        SetEntityHealth(client, healthToSet);
        
        // Set temp health
        float tempHealthToSet = g_PlayerStats[client].tempHealth;
        if (tempHealthToSet < 0.0) tempHealthToSet = 0.0;
        if (tempHealthToSet > MAX_TEMP_HEALTH) tempHealthToSet = float(MAX_TEMP_HEALTH);
        SetTempHealth(client, tempHealthToSet);
        
        // Clear all weapons first
        for (int slot = 0; slot <= 4; slot++)
        {
            int weapon = GetPlayerWeaponSlot(client, slot);
            if (weapon != -1)
            {
                RemovePlayerItem(client, weapon);
                AcceptEntityInput(weapon, "Kill");
            }
        }
        
        // Restore primary weapon
        if (g_PlayerStats[client].primaryWeapon[0] != '\0')
        {
            int weapon = GivePlayerItem(client, g_PlayerStats[client].primaryWeapon);
            if (weapon != -1)
            {
                SetEntProp(weapon, Prop_Send, "m_iClip1", g_PlayerStats[client].primaryClip);
                int ammoType = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
                if (ammoType != -1)
                {
                    SetEntProp(client, Prop_Send, "m_iAmmo", g_PlayerStats[client].primaryAmmo, _, ammoType);
                }
            }
        }
        
        // Restore secondary immediately 
        if (g_PlayerStats[client].secondaryWeapon[0] != '\0')
        {
            if (StrContains(g_PlayerStats[client].secondaryWeapon, "melee_") == 0)
            {
                char meleeType[64];
                strcopy(meleeType, sizeof(meleeType), g_PlayerStats[client].secondaryWeapon[6]); // Skip "melee_"
                
                if (!IsValidMeleeWeapon(meleeType) || !CreateAndEquipMeleeWeapon(client, meleeType))
                {
                    GivePlayerItem(client, "weapon_pistol");
                }
            }
            else
            {
                GivePlayerItem(client, g_PlayerStats[client].secondaryWeapon);
            }
        }
        else
        {
            GivePlayerItem(client, "weapon_pistol");
        }
        
        // Restore items immediately
        if (g_PlayerStats[client].throwable[0] != '\0')
            GivePlayerItem(client, g_PlayerStats[client].throwable);
            
        if (g_PlayerStats[client].healSlot[0] != '\0')
            GivePlayerItem(client, g_PlayerStats[client].healSlot);
            
        if (g_PlayerStats[client].pillsSlot[0] != '\0')
            GivePlayerItem(client, g_PlayerStats[client].pillsSlot);
        
        // Notify the player
        PrintToChat(client, "\x04%s \x01Restored your loadout from the previous campaign finale!", PREFIX);
    }
    else
    {
        // Fallback to basic loadout
        ApplyBasicLoadout(client);
    }
    
    return Plugin_Stop;
}

public Action Timer_RestorePlayerStats(Handle timer, any client)
{
    if (IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client))
    {
        RestorePlayerStats(client);
    }
    return Plugin_Stop;
}

public Action Timer_RestorePlayerStatsByUserId(Handle timer, any userId)
{
    int client = GetClientOfUserId(userId);
    if (client > 0 && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client))
    {
        RestorePlayerStats(client);
    }
    return Plugin_Stop;
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    if (g_bRestoreFromMapStartOnRestart)
    {
        CreateTimer(12.0, Timer_ClearRoundRestartRestoreFlag, _, TIMER_FLAG_NO_MAPCHANGE);
    }
    
    if(!g_bSpawn)
    {
        for(int i = 1; i <= MaxClients; i++)
        {
            if(IsClientInGame(i) && !IsFakeClient(i))
            {
                g_bSpawn = true;
                CreateTimer(1.0, Timer_Start, _, TIMER_FLAG_NO_MAPCHANGE);
                break;
            }
        }
    }
}

public Action Timer_Start(Handle timer)
{
    if(!g_bStart)
    {
        g_bStart = true;
        g_bFirstMap = IsFirstMapInScenario();
        CreateTimer(1.0, Timer_DelayedStart, _, TIMER_FLAG_NO_MAPCHANGE);
    }
    return Plugin_Stop;
}

public Action Timer_ClearRoundRestartRestoreFlag(Handle timer)
{
    g_bRestoreFromMapStartOnRestart = false;
    return Plugin_Stop;
}

public Action Timer_DelayedStart(Handle timer)
{
    if(g_bEnable && FindMapEntity())
    {
        g_bIsValid = true;
    }
    return Plugin_Stop;
}

public Action Event_FinaleVehicleLeaving(Event event, const char[] name, bool dontBroadcast)
{
    if (!g_bEnable || !g_bIsValid) return Plugin_Continue;
    
    char currentMap[64];
    GetCurrentMap(currentMap, sizeof(currentMap));
    
    // Skip for The Sacrifice finale
    if (StrEqual(currentMap, "c7m3_port", false))
    {
        return Plugin_Continue;
    }
    
    // IMPORTANT: Save player stats right at finale completion
    SavePlayerStats();
    g_bShouldRestoreStats = true;
    g_bPendingMapStartSnapshot = true;
    
    // Debug logs to verify the saving
    LogMessage("%s Saved all player stats at finale completion on map %s", PREFIX, currentMap);
    
    // Disable finale camera if available
    if (g_hCvar_FinaleCamera != null)
    {
        g_hCvar_FinaleCamera.SetInt(1);
    }
    
    // Add this verification timer before transition
    CreateTimer(0.5, Timer_VerifySavedStats, _, TIMER_FLAG_NO_MAPCHANGE);
    
    char nextMap[64];
    if (GetChangeLevelMap(nextMap, sizeof(nextMap)))
    {
        // Call this right before campaign change to handle dead players
        CreateTimer(g_hCvar_FinaleTime.FloatValue - 0.5, Timer_PrepareForCampaignChange, _, TIMER_FLAG_NO_MAPCHANGE);
        CreateTimer(g_hCvar_FinaleTime.FloatValue, Timer_ForceNextMap, _, TIMER_FLAG_NO_MAPCHANGE);
        return Plugin_Handled;
    }
    
    return Plugin_Continue;
}

public Action Timer_ForceNextMap(Handle timer)
{
    char nextMap[64];
    if (GetChangeLevelMap(nextMap, sizeof(nextMap)))
    {
        // Before changing to a new campaign, handle dead players
        HandleDeadPlayersForNewCampaign();
        
        // Force the map change
        ForceChangeLevel(nextMap, "Marathon Mode");
        
        // Clean up any existing changelevel entities
        int entity = -1;
        while ((entity = FindEntityByClassname(entity, "info_changelevel")) != -1)
        {
            AcceptEntityInput(entity, "Kill");
        }
    }
    return Plugin_Stop;
}

public Action Event_FinaleWin(Event event, const char[] name, bool dontBroadcast)
{
    if (!g_bEnable || !g_bIsValid) return Plugin_Continue;
    
    char currentMap[64];
    GetCurrentMap(currentMap, sizeof(currentMap));
    
    // Skip for The Sacrifice finale
    if (StrEqual(currentMap, "c7m3_port", false))
    {
        PrintToChatAll("\x04%s \x01 Congratulations! You've completed the marathon!", PREFIX);
        ResetAllPlayerStats();
        return Plugin_Continue;
    }
    
    // IMPORTANT: Save player stats right at finale completion
    SavePlayerStats();
    g_bShouldRestoreStats = true;
    g_bPendingMapStartSnapshot = true;
    
    // Add this verification timer before transition
    CreateTimer(0.5, Timer_VerifySavedStats, _, TIMER_FLAG_NO_MAPCHANGE);
    
    // Debug message
    LogMessage("%s Saved all player stats at finale win on map %s", PREFIX, currentMap);
    PrintToServer("%s Saved stats at finale completion", PREFIX);
    
    return Plugin_Handled;
}

public Action Timer_ForceStandardTransition(Handle timer)
{
    // Trigger the changelevel entity to use the standard transition
    int changeLevelEnt = FindEntityByClassname(-1, "info_changelevel");
    if (changeLevelEnt != -1)
    {
        AcceptEntityInput(changeLevelEnt, "Changelevel");
    }
    return Plugin_Stop;
}

public Action Event_MapTransition(Event event, const char[] name, bool dontBroadcast)
{
    if (!g_bEnable || !g_bIsValid) return Plugin_Continue;
    
    char currentMap[64];
    GetCurrentMap(currentMap, sizeof(currentMap));
    
    // Save exact state at the saferoom transition so the next map starts with current gear.
    SavePlayerStats();
    g_bShouldRestoreStats = true;
    g_bPendingMapStartSnapshot = true;
    
    // Add verification timer to make sure all stats are recent
    CreateTimer(0.1, Timer_VerifySavedStats, _, TIMER_FLAG_NO_MAPCHANGE);
    
    // Clear the dead flag for players who made it to the safe room
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
        {
            // This player successfully completed the map - they're no longer considered "dead"
            g_bPlayerWasDead[i] = false;
            PrintToServer("%s Player %N completed the map successfully - cleared dead flag", PREFIX, i);
        }
    }
    
    // Special handling for finale maps
    if (IsFinaleMap(currentMap))
    {
        char nextMap[64];
        if (GetChangeLevelMap(nextMap, sizeof(nextMap)))
        {
            DataPack dp = new DataPack();
            dp.WriteString(nextMap);
            CreateTimer(g_hCvar_TransitionTime.FloatValue, Timer_ForceNextCampaign, dp, TIMER_FLAG_NO_MAPCHANGE | TIMER_DATA_HNDL_CLOSE);
            return Plugin_Handled;
        }
    }
    
    return Plugin_Continue;
}

public Action Timer_ForceNextCampaign(Handle timer, DataPack dp)
{
    char nextMap[64];
    dp.Reset();
    dp.ReadString(nextMap, sizeof(nextMap));
    
    // Before changing to a new campaign, handle dead players
    HandleDeadPlayersForNewCampaign();
    
    ForceChangeLevel(nextMap, "Marathon Mode");
    
    int entity = -1;
    while ((entity = FindEntityByClassname(entity, "info_changelevel")) != -1)
    {
        AcceptEntityInput(entity, "Kill");
    }
    
    return Plugin_Stop;
}

public void OnMapStart()
{
    if(!g_bInited)
    {
        Init();
    }
    
    if (g_hCvar_FinaleCamera == null)
    {
        InitFinaleCamera();
    }
    if (g_hCvar_FinaleCamera != null)
    {
        g_hCvar_FinaleCamera.SetInt(1);
    }
    
    char currentMap[64];
    GetCurrentMap(currentMap, sizeof(currentMap));
    
    // Handle first map of campaign specially
    bool isFirstMapOfCampaign = false;
    for (int i = 0; i < sizeof(g_Campaigns); i++)
    {
        if (StrEqual(currentMap, g_Campaigns[i].firstMap, false))
        {
            isFirstMapOfCampaign = true;
            PrintToChatAll("\x04%s \x01Starting Campaign %d/14: \x05%s", PREFIX, i + 1, g_Campaigns[i].name);
            
            // Important: If this is the first map of a new campaign and we have stats to restore,
            // we need to preserve them for possible team wipes
            if (g_bShouldRestoreStats && i > 0)
            {
                PrintToServer("%s First map of new campaign - preserving loadout from previous campaign finale", PREFIX);
            }
            
            break;
        }
    }
    
    // If we're starting a new campaign, any player who was dead stays with basic loadout
    if (isFirstMapOfCampaign && g_bShouldRestoreStats)
    {
        PrintToChatAll("\x04%s \x01New campaign started - players who died will have basic loadout", PREFIX);
        // g_bPlayerWasDead flags will be used during player spawn
    }
    
    // Only reset on THE first map if we're starting fresh
    if (StrEqual(currentMap, "c1m1_hotel", false) && !g_bShouldRestoreStats)
    {
        ResetAllPlayerStats();
        // Reset dead flags for everyone
        for (int i = 1; i <= MaxClients; i++)
        {
            g_bPlayerWasDead[i] = false;
        }
        PrintToChatAll("\x04%s \x01Welcome to Marathon Mode! Starting from the beginning.", PREFIX);
        g_bPendingMapStartSnapshot = true;
        CreateTimer(4.0, Timer_CaptureMapStartStats, _, TIMER_FLAG_NO_MAPCHANGE);
    }
    // If we have stats to restore
    else if (g_bShouldRestoreStats)
    {
        PrintToChatAll("\x04%s \x01Restoring player loadouts...", PREFIX);
        CreateTimer(1.0, Timer_RestoreAllPlayers);
        g_bPendingMapStartSnapshot = true;
        CreateTimer(4.0, Timer_CaptureMapStartStats, _, TIMER_FLAG_NO_MAPCHANGE);
    }
    else
    {
        g_bPendingMapStartSnapshot = true;
        CreateTimer(4.0, Timer_CaptureMapStartStats, _, TIMER_FLAG_NO_MAPCHANGE);
    }
    
    // Print current campaign progress
    bool foundCampaign = false;
    for (int i = 0; i < sizeof(g_Campaigns); i++)
    {
        if (StrContains(currentMap, g_Campaigns[i].firstMap, false) == 0)
        {
            // Only print this once (we already printed above for first map of campaign)
            if (!isFirstMapOfCampaign)
            {
                PrintToChatAll("\x04%s \x01Starting Campaign %d/14: \x05%s", PREFIX, i + 1, g_Campaigns[i].name);
            }
            foundCampaign = true;
            break;
        }
    }
    
    if (!foundCampaign && g_bShouldRestoreStats && !isFirstMapOfCampaign)
    {
        PrintToChatAll("\x04%s \x01Continuing marathon on map: %s", PREFIX, currentMap);
    }
}

public void OnMapEnd()
{
    // Preserve the dead player status across map changes
    // Do not reset g_bPlayerWasDead here
    
    g_bStart = false;
    g_bSpawn = false;
    g_bIsValid = false;
    g_bFirstMap = false;
}

public void OnClientPutInServer(int client)
{
    if (!IsFakeClient(client))
    {
        // Only reset stats if we're not in the middle of a marathon
        if (!g_bShouldRestoreStats)
        {
            ResetPlayerStats(client);
        }
        else if (!g_bHasSeenWelcomeMessage[client])
        {
            // Player joined during an active marathon and hasn't seen the message
            CreateTimer(5.0, Timer_WelcomeJoiner, GetClientUserId(client));
            g_bHasSeenWelcomeMessage[client] = true;
        }
        
        if (!g_bSpawn)
        {
            g_bSpawn = true;
            CreateTimer(1.0, Timer_Start, _, TIMER_FLAG_NO_MAPCHANGE);
        }
    }
}

static bool GetChangeLevelMap(char[] name, int maxLength)
{
    char currentMap[64];
    GetCurrentMap(currentMap, sizeof(currentMap));
    
    if (StrEqual(currentMap, "c7m3_port", false))
    {
        PrintToChatAll("\x04%s \x01 Congratulations! You've completed the marathon!", PREFIX);
        return false;
    }
    
    if (IsFinaleMap(currentMap))
    {
        for (int i = 0; i < sizeof(g_Campaigns); i++)
        {
            if (StrEqual(currentMap, g_Campaigns[i].finaleMap, false))
            {
                int nextCampaign = i + 1;
                if (nextCampaign >= sizeof(g_Campaigns))
                {
                    return false;
                }
                strcopy(name, maxLength, g_Campaigns[nextCampaign].firstMap);
                PrintToChatAll("\x04%s \x01 Completed: \x05%s\x01! Next Campaign: \x05%s", 
                    PREFIX, g_Campaigns[i].name, g_Campaigns[nextCampaign].name);
                return true;
            }
        }
    }
    return false;
}

static bool IsFinaleMap(const char[] mapName)
{
    for (int i = 0; i < sizeof(g_Campaigns); i++)
    {
        if (StrEqual(mapName, g_Campaigns[i].finaleMap, false))
        {
            return true;
        }
    }
    return false;
}

static bool IsFirstMapInScenario()
{
    return SDKCall(g_hSDK_CDirector_IsFirstMapInScenario, g_pDirector);
}

static void LoadKvFile()
{
    char sPath[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, sPath, sizeof(sPath), "data/l4d2_mix_map.cfg");
    if(!FileExists(sPath))
    {
        SetFailState("\n==========\nMissing required file: \"%s\".\n==========", sPath);
    }

    KeyValues kv = new KeyValues("MapLandMarkSet");
    if(!kv.ImportFromFile(sPath))
    {
        SetFailState("\n==========\nFailed to import keyvalue: \"%s\".\n==========", sPath);
    }

    char sMapName[64], sLandMarkName[128];
    if(kv.GotoFirstSubKey())
    {
        do
        {
            kv.GetSectionName(sMapName, sizeof(sMapName));
            kv.GetString("LandMarkName", sLandMarkName, sizeof(sLandMarkName));
            g_mMapLandMarkSet.SetString(sMapName, sLandMarkName);
            g_mMapSet.SetString(sMapName, sMapName);
        } while (kv.GotoNextKey());
    }

    g_msMapLandMarkSet = g_mMapLandMarkSet.Snapshot();
    g_msMapSet = g_mMapSet.Snapshot();

    delete kv;
}

public void CvarChange(ConVar convar, const char[] oldValue, const char[] newValue)
{
    g_bEnable = g_hCvar_Enable.BoolValue;
}

public Action Command_Reload(int client, int args)
{
    delete g_mMapLandMarkSet;
    delete g_mMapSet;
    delete g_msMapLandMarkSet;
    delete g_msMapSet;

    g_mMapLandMarkSet = new StringMap();
    g_mMapSet = new StringMap();

    LoadKvFile();

    ReplyToCommand(client, "%s Config reloaded.", PREFIX);
    return Plugin_Handled;
}

public void OnPluginEnd()
{
    delete g_mMapLandMarkSet;
    delete g_mMapSet;
    delete g_msMapLandMarkSet;
    delete g_msMapSet;
}

static bool PlayerHasWeapon(int client, const char[] weaponName)
{
    char currentWeapon[MAXWEAPONNAME];
    
    // Überprüfe alle Waffen-Slots
    for (int slot = 0; slot <= 4; slot++)
    {
        int weapon = GetPlayerWeaponSlot(client, slot);
        if (weapon != -1)
        {
            GetEdictClassname(weapon, currentWeapon, sizeof(currentWeapon));
            if (StrEqual(currentWeapon, weaponName, false))
            {
                return true;
            }
            
            // Spezialfall für Nahkampfwaffen
            if (StrEqual(currentWeapon, "weapon_melee", false) && StrContains(weaponName, "melee_") == 0)
            {
                char meleeType[64], meleeScript[64];
                strcopy(meleeType, sizeof(meleeType), weaponName[6]); // Skip "melee_"
                
                GetEntPropString(weapon, Prop_Data, "m_strMapSetScriptName", meleeScript, sizeof(meleeScript));
                ReplaceString(meleeScript, sizeof(meleeScript), "scripts/melee/", "");
                
                if (StrEqual(meleeScript, meleeType, false))
                {
                    return true;
                }
            }
        }
    }
    
    return false;
}

public Action Timer_ActuallyChangeLevel(Handle timer, DataPack pack)
{
    char nextMap[64];
    pack.Reset();
    pack.ReadString(nextMap, sizeof(nextMap));
    
    if (nextMap[0] != '\0')
    {
        ForceChangeLevel(nextMap, "Marathon Mode");
    }
    return Plugin_Stop;
}

bool CreateAndEquipMeleeWeapon(int client, const char[] meleeType)
{
    // Safety check
    if (!IsClientInGame(client) || !IsPlayerAlive(client)) return false;
    
    // First check if the client already has a melee weapon
    int currentMelee = GetPlayerWeaponSlot(client, 1);
    if (currentMelee != -1)
    {
        char className[64];
        GetEdictClassname(currentMelee, className, sizeof(className));
        
        // If they already have a melee weapon, don't create another one
        if (StrEqual(className, "weapon_melee"))
        {
            char currentMeleeType[64];
            GetEntPropString(currentMelee, Prop_Data, "m_strMapSetScriptName", currentMeleeType, sizeof(currentMeleeType));
            ReplaceString(currentMeleeType, sizeof(currentMeleeType), "scripts/melee/", "");
            
            // If it's the same type we want to give them, just return success
            if (StrEqual(currentMeleeType, meleeType))
            {
                return true;
            }
            
            // Otherwise, remove it before giving the new one
            RemovePlayerItem(client, currentMelee);
            AcceptEntityInput(currentMelee, "Kill");
        }
    }
    
    // Create the new melee weapon
    int weapon = CreateEntityByName("weapon_melee");
    if (weapon == -1) return false;
    
    char scriptName[64];
    Format(scriptName, sizeof(scriptName), "scripts/melee/%s", meleeType);
    
    DispatchKeyValue(weapon, "melee_script_name", meleeType);
    DispatchSpawn(weapon);
    
    // Set the script name
    SetEntPropString(weapon, Prop_Data, "m_strMapSetScriptName", scriptName);
    
    // Don't teleport the weapon to the player's position
    // Instead use direct equipping method
    
    // Try to equip the weapon directly
    if (EquipPlayerWeapon(client, weapon))
    {
        PrintToServer("%s Successfully equipped melee %s to player %N", PREFIX, meleeType, client);
        return true;
    }
    else
    {
        AcceptEntityInput(weapon, "Kill");
        PrintToServer("%s Failed to equip melee to player %N", PREFIX, client);
        return false;
    }
}

public Action Timer_StabilityCheck(Handle timer)
{
    // Check for weird states that might indicate a problem
    char currentMap[64];
    GetCurrentMap(currentMap, sizeof(currentMap));
    
    // Make sure we're in a valid state
    if (g_bStart && !g_bIsValid && !g_bFirstMap)
    {
        LogError("%s Detected invalid plugin state on map %s - attempting recovery", PREFIX, currentMap);
        g_bStart = true;
        g_bFirstMap = IsFirstMapInScenario();
        FindMapEntity();
    }
    
    // Make sure all living players have valid health
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
        {
            int health = GetClientHealth(i);
            if (health <= 0)
            {
                LogError("%s Detected player %N with invalid health %d - fixing", PREFIX, i, health);
                SetEntityHealth(i, MAX_HEALTH / 2); // Set to half health as a fallback
            }
        }
    }
    
    return Plugin_Continue;
}

public Action Timer_VerifySavedStats(Handle timer)
{
    float currentTime = GetGameTime();
    bool statsAreFresh = true;  // This was the missing variable declaration
    
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) && g_PlayerStats[i].hasStats)
        {
            // Check if stats are older than 30 seconds
            if (currentTime - g_PlayerStats[i].saveTime > 30.0)
            {
                statsAreFresh = false;
                LogMessage("%s Warning: Player %N has stale stats (%.1f seconds old)", 
                    PREFIX, i, currentTime - g_PlayerStats[i].saveTime);
            }
        }
    }
    
    // If stats are stale, save them again
    if (!statsAreFresh)
    {
        LogMessage("%s Refreshing stale player stats before transition", PREFIX);
        SavePlayerStats();
    }
    
    return Plugin_Stop;
}

static void HandleDeadPlayersForNewCampaign()
{
    bool anyoneAlive = false;
    
    // First check if anyone is alive
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
        {
            anyoneAlive = true;
            break;
        }
    }
    
    // If no one is alive, we're in a mission failed state
    if (!anyoneAlive)
    {
        LogMessage("%s All players are dead - everyone will restart with default loadout", PREFIX);
        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsClientInGame(i) && GetClientTeam(i) == 2)
            {
                // Reset to default loadout
                ResetPlayerToDefaultState(i);
            }
        }
        return;
    }
    
    // If some players are alive, only reset dead players
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && GetClientTeam(i) == 2 && !IsPlayerAlive(i))
        {
            // Reset only dead players to default loadout
            ResetPlayerToDefaultState(i);
        }
    }
}

public Action Timer_PrepareForCampaignChange(Handle timer)
{
    HandleDeadPlayersForNewCampaign();
    return Plugin_Stop;
}

static void CopyLiveStatsToMapStart(int client)
{
    g_MapStartStats[client].health = g_PlayerStats[client].health;
    g_MapStartStats[client].tempHealth = g_PlayerStats[client].tempHealth;
    strcopy(g_MapStartStats[client].primaryWeapon, MAXWEAPONNAME, g_PlayerStats[client].primaryWeapon);
    g_MapStartStats[client].primaryAmmo = g_PlayerStats[client].primaryAmmo;
    g_MapStartStats[client].primaryClip = g_PlayerStats[client].primaryClip;
    strcopy(g_MapStartStats[client].secondaryWeapon, MAXWEAPONNAME, g_PlayerStats[client].secondaryWeapon);
    strcopy(g_MapStartStats[client].throwable, MAXWEAPONNAME, g_PlayerStats[client].throwable);
    strcopy(g_MapStartStats[client].healSlot, MAXWEAPONNAME, g_PlayerStats[client].healSlot);
    strcopy(g_MapStartStats[client].pillsSlot, MAXWEAPONNAME, g_PlayerStats[client].pillsSlot);
    g_MapStartStats[client].wasIncapacitated = g_PlayerStats[client].wasIncapacitated;
    g_MapStartStats[client].hasStats = g_PlayerStats[client].hasStats;
    g_MapStartStats[client].saveTime = g_PlayerStats[client].saveTime;
}

static void CopyMapStartStatsToLive(int client)
{
    g_PlayerStats[client].health = g_MapStartStats[client].health;
    g_PlayerStats[client].tempHealth = g_MapStartStats[client].tempHealth;
    strcopy(g_PlayerStats[client].primaryWeapon, MAXWEAPONNAME, g_MapStartStats[client].primaryWeapon);
    g_PlayerStats[client].primaryAmmo = g_MapStartStats[client].primaryAmmo;
    g_PlayerStats[client].primaryClip = g_MapStartStats[client].primaryClip;
    strcopy(g_PlayerStats[client].secondaryWeapon, MAXWEAPONNAME, g_MapStartStats[client].secondaryWeapon);
    strcopy(g_PlayerStats[client].throwable, MAXWEAPONNAME, g_MapStartStats[client].throwable);
    strcopy(g_PlayerStats[client].healSlot, MAXWEAPONNAME, g_MapStartStats[client].healSlot);
    strcopy(g_PlayerStats[client].pillsSlot, MAXWEAPONNAME, g_MapStartStats[client].pillsSlot);
    g_PlayerStats[client].wasIncapacitated = g_MapStartStats[client].wasIncapacitated;
    g_PlayerStats[client].hasStats = g_MapStartStats[client].hasStats;
    g_PlayerStats[client].saveTime = GetGameTime();
}

static void RestoreLiveStatsFromMapStart()
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && GetClientTeam(i) == 2)
        {
            if (g_MapStartStats[i].hasStats)
            {
                CopyMapStartStatsToLive(i);
                PrintToServer("%s Queued map-start loadout for %N after team wipe", PREFIX, i);
            }
            else if (!g_PlayerStats[i].hasStats)
            {
                ResetPlayerToDefaultState(i);
            }
        }
    }
}

public Action Timer_CaptureMapStartStats(Handle timer)
{
    if (!g_bEnable)
        return Plugin_Stop;
    
    int savedCount = 0;
    
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
        {
            SavePlayerStatsIndividual(i);
            CopyLiveStatsToMapStart(i);
            g_bPlayerWasDead[i] = false;
            g_bPlayerWasRescued[i] = false;
            savedCount++;
        }
    }
    
    if (savedCount > 0)
    {
        g_bPendingMapStartSnapshot = false;
        PrintToServer("%s Captured map-start loadout snapshot for %d survivor(s)", PREFIX, savedCount);
    }
    
    return Plugin_Stop;
}

public Action Timer_ContinuousSave(Handle timer)
{
    // Only save if the plugin is enabled and in a valid state
    if (g_bEnable && g_bIsValid)
    {
        // Save stats for all living players
        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
            {
                SavePlayerStatsIndividual(i);
            }
        }
    }
    return Plugin_Continue;
}

static void SavePlayerStatsIndividual(int client)
{
    if (!IsClientInGame(client) || GetClientTeam(client) != 2 || !IsPlayerAlive(client))
        return;
        
    bool isIncapacitated = IsClientIncapacitated(client);
    g_PlayerStats[client].wasIncapacitated = isIncapacitated;
    
    // Validate health values when saving
    int currentHealth = GetClientHealth(client);
    if (isIncapacitated)
    {
        currentHealth = ClampIncapHealth(currentHealth);
    }
    else
    {
        if (currentHealth <= 0) currentHealth = MAX_HEALTH;
        if (currentHealth > MAX_HEALTH) currentHealth = MAX_HEALTH;
    }
    g_PlayerStats[client].health = currentHealth;

    float currentTempHealth = GetTempHealth(client);
    if (isIncapacitated) currentTempHealth = 0.0;
    if (currentTempHealth > MAX_TEMP_HEALTH) currentTempHealth = float(MAX_TEMP_HEALTH);
    g_PlayerStats[client].tempHealth = currentTempHealth;

    // Save primary weapon and its ammo
    int weapon = GetPlayerWeaponSlot(client, 0);
    char weaponName[MAXWEAPONNAME];
    if (weapon != -1)
    {
        GetEdictClassname(weapon, weaponName, sizeof(weaponName));
        strcopy(g_PlayerStats[client].primaryWeapon, MAXWEAPONNAME, weaponName);
        g_PlayerStats[client].primaryClip = GetEntProp(weapon, Prop_Send, "m_iClip1");
        g_PlayerStats[client].primaryAmmo = GetClientAmmo(client, weapon);
    }
    else
    {
        g_PlayerStats[client].primaryWeapon[0] = '\0';
        g_PlayerStats[client].primaryClip = 0;
        g_PlayerStats[client].primaryAmmo = 0;
    }

    // Save secondary weapon (including melee)
    weapon = GetPlayerWeaponSlot(client, 1);
    if (weapon != -1)
    {
        GetEdictClassname(weapon, weaponName, sizeof(weaponName));
        
        // For melee weapons, save the specific type
        if (StrEqual(weaponName, "weapon_melee"))
        {
            char meleeName[64];
            GetEntPropString(weapon, Prop_Data, "m_strMapSetScriptName", meleeName, sizeof(meleeName));
            
            // Debug print
            PrintToServer("%s Raw melee name: %s for player %N", PREFIX, meleeName, client);
            
            // Remove the "scripts/melee/" prefix if present
            ReplaceString(meleeName, sizeof(meleeName), "scripts/melee/", "");
            
            // Validate the melee weapon type
            if (IsValidMeleeWeapon(meleeName))
            {
                // Store just the melee type name with prefix for identification
                Format(g_PlayerStats[client].secondaryWeapon, MAXWEAPONNAME, "melee_%s", meleeName);
                PrintToServer("%s Saved valid melee weapon: %s for player %N", PREFIX, g_PlayerStats[client].secondaryWeapon, client);
            }
            else
            {
                PrintToServer("%s Invalid melee weapon type: %s for player %N", PREFIX, meleeName, client);
                g_PlayerStats[client].secondaryWeapon[0] = '\0';
            }
        }
        else
        {
            strcopy(g_PlayerStats[client].secondaryWeapon, MAXWEAPONNAME, weaponName);
            PrintToServer("%s Saved secondary weapon: %s for player %N", PREFIX, g_PlayerStats[client].secondaryWeapon, client);
        }
    }
    else
    {
        g_PlayerStats[client].secondaryWeapon[0] = '\0';
    }

    GetClientWeaponName(client, 2, g_PlayerStats[client].throwable, MAXWEAPONNAME);
    GetClientWeaponName(client, 3, g_PlayerStats[client].healSlot, MAXWEAPONNAME);
    GetClientWeaponName(client, 4, g_PlayerStats[client].pillsSlot, MAXWEAPONNAME);

    // Add timestamp to know when these stats were saved
    g_PlayerStats[client].saveTime = GetGameTime();
    
    g_PlayerStats[client].hasStats = true;
    
    // Debug message - only print occasionally to avoid console spam
    static float lastDebugTime[MAXPLAYERS+1] = {0.0, ...};
    if (GetGameTime() - lastDebugTime[client] > 10.0)
    {
        PrintToServer("%s Auto-saved stats for player %N at time %.1f", PREFIX, client, g_PlayerStats[client].saveTime);
        lastDebugTime[client] = GetGameTime();
    }
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    
    if (client > 0 && IsClientInGame(client) && GetClientTeam(client) == 2)
    {
        // Mark this player as dead - their status will be changed based on how they're revived
        g_bPlayerWasDead[client] = true;
        PrintToServer("%s Player %N died - will get revive loadout based on revival method", PREFIX, client);
        
        // Save their stats at time of death (we'll only restore these for defib, not for rescue closet)
        // We don't change any of their stored stats here - they should keep their original loadout
        // for defibrillator revives to restore
        
        // Just update timestamp
        g_PlayerStats[client].saveTime = GetGameTime();
        
        PrintToServer("%s Saved death time for player %N at %.1f", PREFIX, client, g_PlayerStats[client].saveTime);
    }
}

public Action Timer_WelcomeJoiner(Handle timer, any userId)
{
    int client = GetClientOfUserId(userId);
    if (client > 0 && IsClientInGame(client))
    {
        PrintToChat(client, "\x04%s \x01You've joined an ongoing marathon. Your stats will be restored if you die and rejoin.", PREFIX);
    }
    return Plugin_Stop;
}

public void OnClientDisconnect(int client)
{
    g_bHasSeenWelcomeMessage[client] = false;
}

static void ResetPlayerToDefaultState(int client)
{
    g_PlayerStats[client].hasStats = true;
    g_PlayerStats[client].health = MAX_HEALTH;
    g_PlayerStats[client].tempHealth = 0.0;
    g_PlayerStats[client].primaryWeapon[0] = '\0';  // No primary
    g_PlayerStats[client].primaryAmmo = 0;
    g_PlayerStats[client].primaryClip = 0;
    strcopy(g_PlayerStats[client].secondaryWeapon, MAXWEAPONNAME, "weapon_pistol");  // Just a pistol
    g_PlayerStats[client].throwable[0] = '\0';      // No throwable
    g_PlayerStats[client].healSlot[0] = '\0';       // No medkit
    g_PlayerStats[client].pillsSlot[0] = '\0';      // No pills
    g_PlayerStats[client].wasIncapacitated = false;
    g_PlayerStats[client].saveTime = GetGameTime();
    
    PrintToServer("%s Reset player %N to default state (100 HP + pistol)", PREFIX, client);
}

public Action Timer_ForceBasicLoadout(Handle timer, DataPack dp)
{
    dp.Reset();
    int client = GetClientOfUserId(dp.ReadCell());
    
    if (client <= 0 || !IsClientInGame(client)) 
        return Plugin_Stop;
    
    // Set basic loadout
    ApplyBasicLoadout(client);
    return Plugin_Stop;
}

static void ApplyBasicLoadout(int client)
{
    if (!IsClientInGame(client) || GetClientTeam(client) != 2 || !IsPlayerAlive(client))
        return;
    
    // Set health to 100
    SetEntityHealth(client, 100);
    SetTempHealth(client, 0.0);
    
    // Remove all items
    for (int slot = 0; slot <= 4; slot++)
    {
        int weapon = GetPlayerWeaponSlot(client, slot);
        if (weapon != -1)
        {
            RemovePlayerItem(client, weapon);
            AcceptEntityInput(weapon, "Kill");
        }
    }
    
    // Give only a pistol
    int pistol = GivePlayerItem(client, "weapon_pistol");
    if (pistol != -1)
    {
        // Ensure the pistol is equipped
        EquipPlayerWeapon(client, pistol);
    }
    
    CreateTimer(0.3, Timer_EnsureBasicPistol, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
    
    PrintToServer("%s Applied basic loadout to player %N (100 HP + pistol)", PREFIX, client);
}

public Action Timer_EnsureBasicPistol(Handle timer, any userId)
{
    int client = GetClientOfUserId(userId);
    if (client <= 0 || !IsClientInGame(client) || GetClientTeam(client) != 2 || !IsPlayerAlive(client))
        return Plugin_Stop;
    
    int secondary = GetPlayerWeaponSlot(client, 1);
    if (secondary == -1)
    {
        int pistol = GivePlayerItem(client, "weapon_pistol");
        if (pistol != -1)
        {
            EquipPlayerWeapon(client, pistol);
            PrintToServer("%s Re-applied missing pistol to player %N", PREFIX, client);
        }
    }
    
    return Plugin_Stop;
}

public Action Timer_DelayedBasicLoadout(Handle timer, any userId)
{
    int client = GetClientOfUserId(userId);
    if (client > 0 && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client))
    {
        ApplyBasicLoadout(client);
    }
    return Plugin_Stop;
}

static void RestorePlayerStats(int client)
{
    // Always check the dead flag first
    if (g_bPlayerWasDead[client])
    {
        PrintToServer("%s Player %N was previously dead - applying basic loadout", PREFIX, client);
        ApplyBasicLoadout(client);
        return;
    }
    
    // Don't restore stats if player has no saved stats
    if (!g_PlayerStats[client].hasStats) 
    {
        PrintToServer("%s Not restoring stats for player %N (no saved stats)", PREFIX, client);
        ApplyBasicLoadout(client);
        return;
    }
    
    // Normal stat restoration for living players
    // Validate stored health values before restoration
    if (g_PlayerStats[client].wasIncapacitated)
    {
        g_PlayerStats[client].health = ClampIncapHealth(g_PlayerStats[client].health);
        g_PlayerStats[client].tempHealth = 0.0;
    }
    else
    {
        if (g_PlayerStats[client].health <= 0) g_PlayerStats[client].health = MAX_HEALTH;
        if (g_PlayerStats[client].health > MAX_HEALTH) g_PlayerStats[client].health = MAX_HEALTH;
    }
    if (g_PlayerStats[client].tempHealth > MAX_TEMP_HEALTH) g_PlayerStats[client].tempHealth = float(MAX_TEMP_HEALTH);
    
    CreateTimer(0.5, Timer_DelayedRestore, client);
}

public Action Timer_RestoreAllPlayers(Handle timer)
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
        {
            RestorePlayerStats(i);
        }
    }
    return Plugin_Stop;
}

static void Init()
{
    g_bInited = true;
    g_bEnable = g_hCvar_Enable.BoolValue;
    g_bStart = false;    g_bSpawn = false;
    g_bIsValid = false;
    g_bFirstMap = false;
    g_bShouldRestoreStats = false;
    g_bRestoreFromMapStartOnRestart = false;
    g_bPendingMapStartSnapshot = false;

    for (int i = 1; i <= MaxClients; i++)
    {
        g_PlayerStats[i].hasStats = false;
        g_MapStartStats[i].hasStats = false;
    }
}

static void InitFinaleCamera()
{
    g_hCvar_FinaleCamera = FindConVar("director_no_finale_camera");
    if (g_hCvar_FinaleCamera == null)
    {
        // Create the ConVar if it doesn't exist
        g_hCvar_FinaleCamera = CreateConVar("director_no_finale_camera", "0", "Disable finale camera sequence", FCVAR_NOTIFY);
        if (g_hCvar_FinaleCamera != null)
        {
            LogMessage("%s Created missing ConVar 'director_no_finale_camera'", PREFIX);
        }
        else
        {
            LogError("%s Failed to create ConVar 'director_no_finale_camera'", PREFIX);
        }
    }
}

static float GetTempHealth(int client)
{
    float fHealth = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
    float fHealthTime = GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime");
    float fDuration = GetConVarFloat(FindConVar("pain_pills_decay_rate"));
    float fTemp = fHealth - (fHealthTime * fDuration);
    return fTemp > 0.0 ? (fTemp > MAX_TEMP_HEALTH ? float(MAX_TEMP_HEALTH) : fTemp) : 0.0;
}

static bool IsClientIncapacitated(int client)
{
    if (!IsClientInGame(client) || !IsPlayerAlive(client))
        return false;
    
    return GetEntProp(client, Prop_Send, "m_isIncapacitated") != 0;
}

static int GetMaxIncapHealth()
{
    ConVar cvar = FindConVar("survivor_incap_health");
    if (cvar == null)
    {
        return DEFAULT_INCAP_HEALTH;
    }
    
    int value = cvar.IntValue;
    return value > 0 ? value : DEFAULT_INCAP_HEALTH;
}

static int ClampIncapHealth(int health)
{
    int maxIncapHealth = GetMaxIncapHealth();
    
    if (health <= 0)
    {
        return maxIncapHealth;
    }
    
    if (health > maxIncapHealth)
    {
        return maxIncapHealth;
    }
    
    return health;
}

static void SetTempHealth(int client, float fHealth)
{
    if (fHealth < 0.0) fHealth = 0.0;
    if (fHealth > MAX_TEMP_HEALTH) fHealth = float(MAX_TEMP_HEALTH);
    
    SetEntPropFloat(client, Prop_Send, "m_healthBuffer", fHealth);
    SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
}

static int GetClientAmmo(int client, int weapon)
{
    int ammoType = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
    if (ammoType == -1) return -1;
    return GetEntProp(client, Prop_Send, "m_iAmmo", _, ammoType);
}

static void GetClientWeaponName(int client, int slot, char[] buffer, int maxlen)
{
    int weapon = GetPlayerWeaponSlot(client, slot);
    if (weapon != -1)
    {
        GetEdictClassname(weapon, buffer, maxlen);
    }
    else
    {
        buffer[0] = '\0';
    }
}

static bool IsValidMeleeWeapon(const char[] meleeScript)
{
    static const char validMeleeTypes[][] = {
        "baseball_bat",
        "cricket_bat",
        "crowbar",
        "electric_guitar",
        "fireaxe",
        "frying_pan",
        "golfclub",
        "katana",
        "knife",
        "machete",
        "tonfa",
        "pitchfork",
        "shovel"
    };
    
    for (int i = 0; i < sizeof(validMeleeTypes); i++)
    {
        if (StrEqual(meleeScript, validMeleeTypes[i], false))
        {
            return true;
        }
    }
    return false;
}

public Action Timer_DelayedRestore(Handle timer, any client)
{
    if (!IsClientInGame(client) || !IsPlayerAlive(client)) return Plugin_Stop;

    // Set main health with validation
    int healthToSet = g_PlayerStats[client].health;
    if (g_PlayerStats[client].wasIncapacitated)
    {
        healthToSet = ClampIncapHealth(healthToSet);
    }
    else
    {
        if (healthToSet <= 0) healthToSet = MAX_HEALTH;
        if (healthToSet > MAX_HEALTH) healthToSet = MAX_HEALTH;
    }
    SetEntityHealth(client, healthToSet);

    // Set temp health with validation
    float tempHealthToSet = g_PlayerStats[client].tempHealth;
    if (g_PlayerStats[client].wasIncapacitated) tempHealthToSet = 0.0;
    if (tempHealthToSet < 0.0) tempHealthToSet = 0.0;
    if (tempHealthToSet > MAX_TEMP_HEALTH) tempHealthToSet = float(MAX_TEMP_HEALTH);
    SetTempHealth(client, tempHealthToSet);

    // Clear existing weapons only if we're going to restore them
    // Check if we have any weapons to restore first
    bool hasWeaponsToRestore = (g_PlayerStats[client].primaryWeapon[0] != '\0' || 
                               g_PlayerStats[client].secondaryWeapon[0] != '\0' ||
                               g_PlayerStats[client].throwable[0] != '\0' ||
                               g_PlayerStats[client].healSlot[0] != '\0' ||
                               g_PlayerStats[client].pillsSlot[0] != '\0');
    
    if (hasWeaponsToRestore)
    {
        // Clear existing weapons
        for (int slot = 0; slot <= 4; slot++)
        {
            int weapon = GetPlayerWeaponSlot(client, slot);
            if (weapon != -1)
            {
                RemovePlayerItem(client, weapon);
                AcceptEntityInput(weapon, "Kill");
            }
        }
    }

    // Restore primary weapon with ammo
    if (g_PlayerStats[client].primaryWeapon[0] != '\0')
    {
        int weapon = GivePlayerItem(client, g_PlayerStats[client].primaryWeapon);
        if (weapon != -1)
        {
            SetEntProp(weapon, Prop_Send, "m_iClip1", g_PlayerStats[client].primaryClip);
            
            int ammoType = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
            if (ammoType != -1)
            {
                SetEntProp(client, Prop_Send, "m_iAmmo", g_PlayerStats[client].primaryAmmo, _, ammoType);
            }
            
            PrintToServer("%s Restored primary weapon %s with clip: %d, reserve: %d for player %N", 
                PREFIX, 
                g_PlayerStats[client].primaryWeapon, 
                g_PlayerStats[client].primaryClip, 
                g_PlayerStats[client].primaryAmmo,
                client);
        }
    }

    CreateTimer(0.1, Timer_RestoreSecondary, client);
    CreateTimer(0.2, Timer_RestoreItems, client);
    
    if (g_PlayerStats[client].wasIncapacitated)
    {
        CreateTimer(0.3, Timer_ApplySavedIncapState, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
        CreateTimer(0.8, Timer_ApplySavedIncapState, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
    }

    PrintToServer("%s Restored stats for player %N", PREFIX, client);
    return Plugin_Stop;
}

public Action Timer_ApplySavedIncapState(Handle timer, any userId)
{
    int client = GetClientOfUserId(userId);
    if (client <= 0 || !IsClientInGame(client) || GetClientTeam(client) != 2 || !IsPlayerAlive(client))
        return Plugin_Stop;
    
    if (!g_PlayerStats[client].wasIncapacitated)
        return Plugin_Stop;
    
    int incapHealth = ClampIncapHealth(g_PlayerStats[client].health);
    SetTempHealth(client, 0.0);
    SetEntProp(client, Prop_Send, "m_isHangingFromLedge", 0);
    SetEntProp(client, Prop_Send, "m_isIncapacitated", 1);
    SetEntityHealth(client, incapHealth);
    
    PrintToServer("%s Restored incapacitated state for player %N with %d HP", PREFIX, client, incapHealth);
    return Plugin_Stop;
}

public Action Timer_RestoreSecondary(Handle timer, any client)
{
    if (!IsClientInGame(client) || !IsPlayerAlive(client)) return Plugin_Stop;
    
    if (g_PlayerStats[client].secondaryWeapon[0] != '\0')
    {
        // Check if player already has a secondary weapon
        int currentSecondary = GetPlayerWeaponSlot(client, 1);
        if (currentSecondary != -1)
        {
            // Player already has a secondary weapon, don't give another one
            return Plugin_Stop;
        }
        
        // Check if it's a melee weapon
        if (StrContains(g_PlayerStats[client].secondaryWeapon, "melee_") == 0)
        {
            char meleeType[64];
            strcopy(meleeType, sizeof(meleeType), g_PlayerStats[client].secondaryWeapon[6]); // Skip "melee_"
            
            // Use our improved melee creation function
            if (!IsValidMeleeWeapon(meleeType) || !CreateAndEquipMeleeWeapon(client, meleeType))
            {
                GivePlayerItem(client, "weapon_pistol");
                PrintToServer("%s Failed with melee, gave pistol to %N instead", PREFIX, client);
            }
        }
        else
        {
            // Regular secondary weapon
            GivePlayerItem(client, g_PlayerStats[client].secondaryWeapon);
        }
    }
    return Plugin_Stop;
}

public Action Timer_RestoreItems(Handle timer, any client)
{
    if (!IsClientInGame(client) || !IsPlayerAlive(client)) return Plugin_Stop;
    
    // Überprüfe, ob der Spieler bereits die entsprechenden Items hat, bevor neue hinzugefügt werden
    if (g_PlayerStats[client].throwable[0] != '\0' && !PlayerHasWeapon(client, g_PlayerStats[client].throwable))
    {
        GivePlayerItem(client, g_PlayerStats[client].throwable);
    }
    
    if (g_PlayerStats[client].healSlot[0] != '\0' && !PlayerHasWeapon(client, g_PlayerStats[client].healSlot))
    {
        GivePlayerItem(client, g_PlayerStats[client].healSlot);
    }
    
    if (g_PlayerStats[client].pillsSlot[0] != '\0' && !PlayerHasWeapon(client, g_PlayerStats[client].pillsSlot))
    {
        GivePlayerItem(client, g_PlayerStats[client].pillsSlot);
    }
    
    return Plugin_Stop;
}

static bool FindMapEntity()
{
    int CId = -1, LId = -1;
    char LandMarkName[128], BindName[128];
    
    // Initialize with safe defaults
    BindName[0] = '\0';
    g_sValidLandMarkName[0] = '\0';
    
    char currentMap[64];
    GetCurrentMap(currentMap, sizeof(currentMap));
    g_bIsFinaleMap = IsFinaleMap(currentMap);

    // Find existing changelevel entity
    bool HasChangeLevel = false;
    CId = FindEntityByClassname(-1, "info_changelevel");
    if (CId != -1)
    {
        GetEntPropString(CId, Prop_Data, "m_landmarkName", BindName, sizeof(BindName));
        if (BindName[0] != '\0')
        {
            HasChangeLevel = true;
        }
    }

    // Try to find landmark if we have a bind name
    if (HasChangeLevel && BindName[0] != '\0')
    {
        while ((LId = FindEntityByClassname(LId, "info_landmark")) != -1)
        {
            GetEntPropString(LId, Prop_Data, "m_iName", LandMarkName, sizeof(LandMarkName));
            if (StrEqual(LandMarkName, BindName, false))
            {
                return true;
            }
            else if (!g_bFirstMap && g_sValidLandMarkName[0] == '\0')
            {
                strcopy(g_sValidLandMarkName, sizeof(g_sValidLandMarkName), LandMarkName);
            }
        }
    }

    // Special handling for finale maps - with safety checks
    if (!HasChangeLevel && g_bIsFinaleMap)
    {
        int entity = CreateEntityByName("info_changelevel");
        if (entity != -1)
        {
            DispatchSpawn(entity);
            
            int landmark = CreateEntityByName("info_landmark");
            if (landmark != -1)
            {
                DispatchSpawn(landmark);
                SetEntPropString(landmark, Prop_Data, "m_iName", "marathon_transition_landmark");
                strcopy(BindName, sizeof(BindName), "marathon_transition_landmark");
                HasChangeLevel = true;
            }
        }
    }

    return HasChangeLevel;
}

static void ResetPlayerStats(int client)
{
    g_PlayerStats[client].hasStats = false;
    g_MapStartStats[client].hasStats = false;
    g_PlayerStats[client].health = MAX_HEALTH;
    g_PlayerStats[client].tempHealth = 0.0;
    g_PlayerStats[client].primaryWeapon[0] = '\0';
    g_PlayerStats[client].primaryAmmo = 0;
    g_PlayerStats[client].primaryClip = 0;
    g_PlayerStats[client].secondaryWeapon[0] = '\0';
    g_PlayerStats[client].throwable[0] = '\0';
    g_PlayerStats[client].healSlot[0] = '\0';
    g_PlayerStats[client].pillsSlot[0] = '\0';
    g_PlayerStats[client].wasIncapacitated = false;
    g_MapStartStats[client].wasIncapacitated = false;
    PrintToChat(client, "\x04%s \x01Welcome! Starting fresh with default loadout.", PREFIX);
}

static void ResetAllPlayerStats()
{
    g_bShouldRestoreStats = false;
    g_bRestoreFromMapStartOnRestart = false;
    g_bPendingMapStartSnapshot = false;
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i))
        {
            ResetPlayerStats(i);
        }
    }
    PrintToChatAll("\x04%s \x01Stats have been reset for a fresh start!", PREFIX);
}

static void SavePlayerStats()
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
        {
            SavePlayerStatsIndividual(i);
        }
    }
    g_bShouldRestoreStats = true;
}
