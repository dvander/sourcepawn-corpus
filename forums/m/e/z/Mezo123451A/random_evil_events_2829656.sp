#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <left4dhooks>

#define PLUGIN_VERSION "1.3.1"
#define TEAM_SURVIVOR 2
#define ZOMBIECLASS_SMOKER 1
#define ZOMBIECLASS_BOOMER 2
#define ZOMBIECLASS_HUNTER 3
#define ZOMBIECLASS_SPITTER 4
#define ZOMBIECLASS_JOCKEY 5
#define ZOMBIECLASS_CHARGER 6
#define ZOMBIECLASS_TANK 8

#define UNSTUCK_ATTEMPTS 15  // Number of attempts to free a stuck player
#define UNSTUCK_MAX_HEIGHT 200.0  // Max height to search for free space

public Plugin myinfo = {
    name = "Evil Random Events",
    author = "Mezo123451A",
    description = "Only bad things happen to survivors",
    version = PLUGIN_VERSION,
    url = ""
};

ConVar g_hEnabled;
ConVar g_cvEnableEvent0;  // Double Tank
ConVar g_cvEnableEvent1;  // Remove Items
ConVar g_cvEnableEvent2;  // Witch Army
ConVar g_cvEnableEvent3;  // Black and White
ConVar g_cvEnableEvent4;  // Explosive Bullets
ConVar g_cvEnableEvent5;  // Slippery Floor
ConVar g_cvEnableEvent6;  // Mega Horde Rush
ConVar g_cvEnableEvent7;  // Car Alarms
ConVar g_cvEnableEvent8;  // Sudden Death
ConVar g_cvEnableEvent9;  // Acid Rain

int g_iEventsTriggered = 0;
bool g_bEventInProgress = false;
bool g_bFirstEventTriggered = false;
Handle g_hEventTimer = null;

char g_sConfigFile[PLATFORM_MAX_PATH];

// Add a global timer to keep track of unstuck attempts
Handle g_hUnstuckTimers[MAXPLAYERS+1] = {null, ...};
int g_iUnstuckAttempts[MAXPLAYERS+1] = {0, ...};
float g_vOriginalPosition[MAXPLAYERS+1][3];

public void OnPluginStart() {
    CreateConVar("evil_events_version", PLUGIN_VERSION, "Plugin version", FCVAR_NOTIFY|FCVAR_DONTRECORD);
    g_hEnabled = CreateConVar("evil_events_enabled", "1", "Enable/disable evil events plugin", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    
    g_cvEnableEvent0 = CreateConVar("l4d2_evil_event_enable_double_tank", "1", "Enable/disable Double Tank event", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_cvEnableEvent1 = CreateConVar("l4d2_evil_event_enable_remove_items", "1", "Enable/disable Remove Items event", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_cvEnableEvent2 = CreateConVar("l4d2_evil_event_enable_1hp_challenge", "1", "Enable/disable 1 HP Challenge event", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_cvEnableEvent3 = CreateConVar("l4d2_evil_event_enable_teleport", "1", "Enable/disable Teleport event", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_cvEnableEvent4 = CreateConVar("l4d2_evil_event_enable_angry_witch", "1", "Enable/disable Angry Witch event", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_cvEnableEvent5 = CreateConVar("l4d2_evil_event_enable_special_infected_party", "1", "Enable/disable Special Infected Party event", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_cvEnableEvent6 = CreateConVar("l4d2_evil_event_enable_mega_horde", "1", "Enable/disable Mega Horde event", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_cvEnableEvent7 = CreateConVar("l4d2_evil_event_enable_darkness_falls", "1", "Enable/disable Darkness Falls event", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_cvEnableEvent8 = CreateConVar("l4d2_evil_event_enable_toxic_gas", "1", "Enable/disable Toxic Gas event", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_cvEnableEvent9 = CreateConVar("l4d2_evil_event_enable_toxic_atmosphere", "1", "Enable/disable Toxic Atmosphere event", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    
    // Add ConVar change hooks to track changes at runtime
    g_hEnabled.AddChangeHook(ConVarChanged_EnabledState);
    g_cvEnableEvent0.AddChangeHook(ConVarChanged_EventState);
    g_cvEnableEvent1.AddChangeHook(ConVarChanged_EventState);
    g_cvEnableEvent2.AddChangeHook(ConVarChanged_EventState);
    g_cvEnableEvent3.AddChangeHook(ConVarChanged_EventState);
    g_cvEnableEvent4.AddChangeHook(ConVarChanged_EventState);
    g_cvEnableEvent5.AddChangeHook(ConVarChanged_EventState);
    g_cvEnableEvent6.AddChangeHook(ConVarChanged_EventState);
    g_cvEnableEvent7.AddChangeHook(ConVarChanged_EventState);
    g_cvEnableEvent8.AddChangeHook(ConVarChanged_EventState);
    g_cvEnableEvent9.AddChangeHook(ConVarChanged_EventState);
    
    AutoExecConfig(true);
    
    BuildPath(Path_SM, g_sConfigFile, sizeof(g_sConfigFile), "../../cfg/sourcemod/plugin.random_evil_events.cfg");
    RegAdminCmd("sm_evilevent_reload", Command_ReloadConfig, ADMFLAG_CONFIG, "Reload the Evil Events config file");
    
    RegConsoleCmd("sm_testevent", Command_TestEvent, "Test evil events");
    
    HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
    HookEvent("map_transition", Event_MapTransition, EventHookMode_Post);
    
    // Execute the config immediately after creating it
    ServerCommand("exec sourcemod/plugin.random_evil_events.cfg");
}

// ConVar change hooks to track changes at runtime
public void ConVarChanged_EnabledState(ConVar convar, const char[] oldValue, const char[] newValue) {
    PrintToServer("[Evil Events] Global enabled state changed: %s", newValue);
    
    // If plugin is being enabled, restart events
    if (strcmp(oldValue, "0") == 0 && strcmp(newValue, "1") == 0) {
        RestartEventSystem();
    }
}

public void ConVarChanged_EventState(ConVar convar, const char[] oldValue, const char[] newValue) {
    char convarName[64];
    convar.GetName(convarName, sizeof(convarName));
    PrintToServer("[Evil Events] Event enabled state changed for %s: %s", convarName, newValue);
    
    // If an event is being enabled and no event timer is running, restart events
    if (strcmp(oldValue, "0") == 0 && strcmp(newValue, "1") == 0) {
        // Check if we currently have a running timer
        if (g_hEventTimer == null && GetRandomEnabledEvent() != -1) {
            RestartEventSystem();
        }
    }
}

// New function to restart the event system
void RestartEventSystem() {
    // Only restart if global enabled and we aren't in the middle of an event
    if (!g_hEnabled.BoolValue || g_bEventInProgress) {
        return;
    }
    
    // Make sure there are events enabled
    if (GetRandomEnabledEvent() == -1) {
        PrintToServer("[Evil Events] No events enabled, not restarting event system");
        return;
    }
    
    // Clear any existing timer
    if (g_hEventTimer != null) {
        KillTimer(g_hEventTimer);
        g_hEventTimer = null;
    }
    
    PrintToServer("[Evil Events] Restarting event system");
    
    // If no events have happened yet, start with initial delay
    if (!g_bFirstEventTriggered) {
        g_hEventTimer = CreateTimer(60.0, Timer_FirstEvent);
        PrintToServer("[Evil Events] Starting initial event timer (60 seconds)");
    } else {
        // Otherwise, schedule next event with normal delay
        g_hEventTimer = CreateTimer(60.0, Timer_NextEvent);
        PrintToServer("[Evil Events] Scheduling next event (60 seconds)");
    }
    
    // Output message to all players
    PrintToChatAll("\x04[Evil Event] \x01Event system restarted!");
}

public void OnMapStart() {
    g_iEventsTriggered = 0;
    g_bEventInProgress = false;
    g_bFirstEventTriggered = false;
    
    // Clear any existing timer
    if (g_hEventTimer != null) {
        KillTimer(g_hEventTimer);
        g_hEventTimer = null;
    }
    
    // Clear unstuck timers
    for (int i = 1; i <= MaxClients; i++) {
        if (g_hUnstuckTimers[i] != null) {
            KillTimer(g_hUnstuckTimers[i]);
            g_hUnstuckTimers[i] = null;
        }
        g_iUnstuckAttempts[i] = 0;
    }
    
    // Precache particles that are actually available in L4D2
    PrecacheParticle("fire_small_02");
    PrecacheParticle("explosion_basic");
    PrecacheParticle("fireworks_sparkshower_01");
    PrecacheParticle("gas_explosion_main");
    PrecacheParticle("smoker_smokecloud");
    PrecacheParticle("spitter_area");
    PrecacheParticle("boomer_explode");
}

void PrecacheParticle(const char[] particleName) {
    int particle = CreateEntityByName("info_particle_system");
    if (particle != -1) {
        DispatchKeyValue(particle, "effect_name", particleName);
        DispatchSpawn(particle);
        ActivateEntity(particle);
        AcceptEntityInput(particle, "Start");
        CreateTimer(0.1, Timer_RemoveEntity, particle);
    }
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast) {
    g_iEventsTriggered = 0;
    g_bEventInProgress = false;
    g_bFirstEventTriggered = false;
    
    // Clear any existing timer
    if (g_hEventTimer != null) {
        KillTimer(g_hEventTimer);
        g_hEventTimer = null;
    }
    
    // Start initial delay timer
    CreateTimer(60.0, Timer_FirstEvent);
    return Plugin_Continue;
}

public Action Event_MapTransition(Event event, const char[] name, bool dontBroadcast) {
    g_iEventsTriggered = 0;
    g_bEventInProgress = false;
    g_bFirstEventTriggered = false;
    
    if (g_hEventTimer != null) {
        KillTimer(g_hEventTimer);
        g_hEventTimer = null;
    }
    return Plugin_Continue;
}

public Action Timer_FirstEvent(Handle timer) {
    g_hEventTimer = null;
    g_bFirstEventTriggered = true;
    
    int eventId = GetRandomEnabledEvent();
    if (eventId == -1) {
        PrintToChatAll("\x04[Evil Event] \x01No events enabled!");
        return Plugin_Stop;
    }
    
    TriggerEvent(eventId);
    return Plugin_Stop;
}

public Action Timer_EventComplete(Handle timer) {
    g_bEventInProgress = false;
    
    // Start the timer for the next event
    if (g_bFirstEventTriggered) {
        g_hEventTimer = CreateTimer(60.0, Timer_NextEvent);
    }
    
    return Plugin_Stop;
}

public Action Timer_NextEvent(Handle timer) {
    g_hEventTimer = null;
    
    if (!g_hEnabled.BoolValue || g_bEventInProgress) return Plugin_Stop;
    
    // Start the next event
    TriggerEvent(GetRandomInt(0, 9));
    g_iEventsTriggered++;
    PrintToChatAll("\x04[Evil Event] \x01 An evil event has been triggered!");
    
    return Plugin_Stop;
}

public Action Command_TestEvent(int client, int args) {
    if (g_bEventInProgress) {
        ReplyToCommand(client, "\x04[Evil Event] \x01 An event is already in progress!");
        return Plugin_Handled;
    }

    if (args < 1) {
        ReplyToCommand(client, "Usage: sm_testevent <0-9>");  // Updated range
        ReplyToCommand(client, "0 = Double Tank, 1 = Remove Items, 2 = 1 HP");
        ReplyToCommand(client, "3 = Teleport, 4 = Witch, 5 = Special Infected");
        ReplyToCommand(client, "6 = Mega Horde, 7 = Darkness Falls");
        ReplyToCommand(client, "8 = Toxic Gas, 9 = Toxic Atmosphere");  // Updated event name
        return Plugin_Handled;
    }
    
    char arg[4];
    GetCmdArg(1, arg, sizeof(arg));
    int eventId = StringToInt(arg);
    
    if (eventId < 0 || eventId > 9) {  // Updated range check
        ReplyToCommand(client, "Event ID must be between 0 and 9");
        return Plugin_Handled;
    }
    
    // Check if the specified event is enabled
    if (!IsEventEnabled(eventId)) {
        ReplyToCommand(client, "\x04[Evil Event] \x01 Event #%d is disabled in the config!", eventId);
        return Plugin_Handled;
    }
    
    TriggerEvent(eventId);
    ReplyToCommand(client, "\x04[Evil Event] \x01 Test event triggered!");
    return Plugin_Handled;
}

void TriggerEvent(int eventId) {
    // First check if the event is enabled
    if (!IsEventEnabled(eventId)) {
        PrintToServer("[Evil Events] Attempted to trigger disabled event #%d", eventId);
        return;
    }
    
    g_bEventInProgress = true;

    switch (eventId) {
        case 0: {
            // Double Tank with instant aggression
            float pos[3], ang[3];
            int tank1, tank2;
            float vecPos[3];
            
            int survivor = FindRandomSurvivor();
            if (survivor > 0) {
                GetClientAbsOrigin(survivor, pos);
                GetClientAbsAngles(survivor, ang);
                
                // Spawn first tank
                vecPos = pos;
                vecPos[0] += GetRandomFloat(-600.0, 600.0);
                vecPos[1] += GetRandomFloat(-600.0, 600.0);
                
                float ground[3];
                if (GetValidGroundPosition(vecPos, ground)) {
                    tank1 = L4D2_SpawnTank(ground, ang);
                    if (tank1 > 0) {
                        SetEntProp(tank1, Prop_Data, "m_iHealth", 4000);
                        CreateTimer(0.1, Timer_CheckTankStuck, tank1, TIMER_REPEAT);
                        ForceEntityToMove(tank1);
                    }
                }
                
                // Spawn second tank
                vecPos = pos;
                vecPos[0] += GetRandomFloat(-600.0, 600.0);
                vecPos[1] += GetRandomFloat(-600.0, 600.0);
                
                if (GetValidGroundPosition(vecPos, ground)) {
                    tank2 = L4D2_SpawnTank(ground, ang);
                    if (tank2 > 0) {
                        SetEntProp(tank2, Prop_Data, "m_iHealth", 4000);
                        CreateTimer(0.1, Timer_CheckTankStuck, tank2, TIMER_REPEAT);
                        ForceEntityToMove(tank2);
                    }
                }
                
                if (tank1 > 0 || tank2 > 0) {
                    PrintToChatAll("\x04[Evil Event] \x01 The \x04 Tanks\x01 are charging at you!");
                    
                    // Show hint text to all survivors
                    for (int i = 1; i <= MaxClients; i++) {
                        if (IsClientInGame(i) && IsSurvivor(i) && IsPlayerAlive(i)) {
                            PrintHintText(i, "WARNING: Two Tanks are approaching!\nPrepare to fight or run!");
                        }
                    }
                }
            }
            CreateTimer(30.0, Timer_EventComplete);
        }
        
        case 1: {
            // Remove items
            for (int i = 1; i <= MaxClients; i++) {
                if (IsClientInGame(i) && IsSurvivor(i)) {
                    RemovePlayerItems(i);
                }
            }
            PrintToChatAll("\x04[Evil Event] \x01 All of your items have been \x04removed\x01!");
            
            // Show hint text to all survivors
            for (int i = 1; i <= MaxClients; i++) {
                if (IsClientInGame(i) && IsSurvivor(i)) {
                    PrintHintText(i, "Your items have been confiscated!\nFind new equipment quickly!");
                }
            }
            CreateTimer(5.0, Timer_EventComplete);
        }
        
        case 2: {
            // 1 HP
            for (int i = 1; i <= MaxClients; i++) {
                if (IsClientInGame(i) && IsSurvivor(i) && IsPlayerAlive(i)) {
                    SetEntProp(i, Prop_Send, "m_iHealth", 1);
                    SetEntPropFloat(i, Prop_Send, "m_healthBuffer", 0.0);
                }
            }
            PrintToChatAll("\x04[Evil Event] \x01 Everyone now has only 1HP! Good luck!");
            
            // Show hint text to all survivors
            for (int i = 1; i <= MaxClients; i++) {
                if (IsClientInGame(i) && IsSurvivor(i) && IsPlayerAlive(i)) {
                    PrintHintText(i, "CRITICAL CONDITION!\nYou have only 1 HP!\nStay alert and find healing!");
                }
            }
            CreateTimer(5.0, Timer_EventComplete);
        }

        case 3: {
            // Completely rewritten saferoom teleport to ensure it ONLY targets the starting saferoom
            char mapName[64];
            GetCurrentMap(mapName, sizeof(mapName));
            
            // Check if this is a finale map - finale maps usually end with "finale" or have "5" as the middle number
            bool isFinaleMap = false;
            if (StrContains(mapName, "finale", false) != -1 || 
                StrContains(mapName, "m5_", false) != -1 ||
                StrEqual(mapName, "c1m4_atrium", false) ||
                StrEqual(mapName, "c2m5_concert", false) ||
                StrEqual(mapName, "c3m4_plantation", false) ||
                StrEqual(mapName, "c4m5_milltown_escape", false) ||
                StrEqual(mapName, "c5m5_bridge", false) ||
                StrEqual(mapName, "c6m3_port", false) ||
                StrEqual(mapName, "c7m3_port", false) ||
                StrEqual(mapName, "c8m5_rooftop", false) ||
                StrEqual(mapName, "c9m2_lots", false) ||
                StrEqual(mapName, "c10m5_houseboat", false) ||
                StrEqual(mapName, "c11m5_runway", false) ||
                StrEqual(mapName, "c12m5_cornfield", false) ||
                StrEqual(mapName, "c13m4_cutthroatcreek", false) ||
                StrEqual(mapName, "c14m2_lighthouse", false)) {
                
                isFinaleMap = true;
            }
            
            // Skip teleport if on a finale map
            if (isFinaleMap) {
                PrintToChatAll("\x04[Evil Event] \x01 The teleport event has been \x04disabled\x01 during the finale!");
                
                // Show hint text
                for (int i = 1; i <= MaxClients; i++) {
                    if (IsClientInGame(i) && IsSurvivor(i) && IsPlayerAlive(i)) {
                        PrintHintText(i, "Teleport disabled during finale!\nStand your ground!");
                    }
                }
                
                // Complete the event immediately
                CreateTimer(2.0, Timer_EventComplete);
                return;
            }
            
            PrintToServer("[Evil Events] Attempting teleport to START saferoom on map %s", mapName);
            
            float safePos[3];
            bool foundSpawn = false;
            
            // *** METHOD 1: Map-specific hardcoded coordinates (most reliable) ***
            // These coordinates are verified to work for starting saferooms on standard maps
            if (StrEqual(mapName, "c1m1_hotel", false)) {
                // Dead Center - Hotel
                safePos[0] = 568.0;
                safePos[1] = 5707.0;
                safePos[2] = 2872.0;
                foundSpawn = true;
                PrintToServer("[Evil Events] Using verified start coordinates for c1m1_hotel");
            }
            else if (StrEqual(mapName, "c2m1_highway", false)) {
                // Dark Carnival - Highway
                safePos[0] = 1740.0;
                safePos[1] = -1320.0;
                safePos[2] = -510.0;
                foundSpawn = true;
                PrintToServer("[Evil Events] Using verified start coordinates for c2m1_highway");
            }
            else if (StrEqual(mapName, "c3m1_plankcountry", false)) {
                // Swamp Fever - Plank Country
                safePos[0] = -12085.0;
                safePos[1] = 7600.0;
                safePos[2] = 190.0;
                foundSpawn = true;
                PrintToServer("[Evil Events] Using verified start coordinates for c3m1_plankcountry");
            }
            else if (StrEqual(mapName, "c4m1_milltown_a", false)) {
                // Hard Rain - Mill Town A
                safePos[0] = -7550.0;
                safePos[1] = 7860.0;
                safePos[2] = 175.0;
                foundSpawn = true;
                PrintToServer("[Evil Events] Using verified start coordinates for c4m1_milltown_a");
            }
            else if (StrEqual(mapName, "c5m1_waterfront", false)) {
                // The Parish - Waterfront
                safePos[0] = -475.0;
                safePos[1] = -1485.0;
                safePos[2] = -190.0;
                foundSpawn = true;
                PrintToServer("[Evil Events] Using verified start coordinates for c5m1_waterfront");
            }
            else if (StrEqual(mapName, "c6m1_riverbank", false)) {
                // The Passing - Riverbank
                safePos[0] = 505.0;
                safePos[1] = -845.0;
                safePos[2] = 155.0;
                foundSpawn = true;
                PrintToServer("[Evil Events] Using verified start coordinates for c6m1_riverbank");
            }
            else if (StrEqual(mapName, "c7m1_docks", false)) {
                // The Sacrifice - Docks
                safePos[0] = -5710.0;
                safePos[1] = -1150.0;
                safePos[2] = 350.0;
                foundSpawn = true;
                PrintToServer("[Evil Events] Using verified start coordinates for c7m1_docks");
            }
            else if (StrEqual(mapName, "c8m1_apartment", false)) {
                // No Mercy - Apartment
                safePos[0] = -5125.0;
                safePos[1] = 8860.0;
                safePos[2] = 135.0;
                foundSpawn = true;
                PrintToServer("[Evil Events] Using verified start coordinates for c8m1_apartment");
            }
            else if (StrEqual(mapName, "c9m1_alleys", false)) {
                // Crash Course - Alleys
                safePos[0] = -9240.0;
                safePos[1] = 2205.0;
                safePos[2] = 35.0;
                foundSpawn = true;
                PrintToServer("[Evil Events] Using verified start coordinates for c9m1_alleys");
            }
            else if (StrEqual(mapName, "c10m1_caves", false)) {
                // Death Toll - Caves
                safePos[0] = 7515.0;
                safePos[1] = 7850.0;
                safePos[2] = -275.0;
                foundSpawn = true;
                PrintToServer("[Evil Events] Using verified start coordinates for c10m1_caves");
            }
            else if (StrEqual(mapName, "c11m1_greenhouse", false)) {
                // Dead Air - Greenhouse
                safePos[0] = 6450.0;
                safePos[1] = 1435.0;
                safePos[2] = 540.0;
                foundSpawn = true;
                PrintToServer("[Evil Events] Using verified start coordinates for c11m1_greenhouse");
            }
            else if (StrEqual(mapName, "c12m1_hilltop", false)) {
                // Blood Harvest - Hilltop
                safePos[0] = -7060.0;
                safePos[1] = -10120.0;
                safePos[2] = 575.0;
                foundSpawn = true;
                PrintToServer("[Evil Events] Using verified start coordinates for c12m1_hilltop");
            }
            else if (StrEqual(mapName, "c13m1_alpinecreek", false)) {
                // Cold Stream - Alpine Creek
                safePos[0] = 350.0;
                safePos[1] = 3430.0;
                safePos[2] = 155.0;
                foundSpawn = true;
                PrintToServer("[Evil Events] Using verified start coordinates for c13m1_alpinecreek");
            }
            
            // *** Check if this is a first map of a campaign (these always have starting saferooms) ***
            bool isFirstMap = false;
            
            // Pattern match to identify first maps of campaigns
            if (StrContains(mapName, "m1_") != -1) {
                isFirstMap = true;
                PrintToServer("[Evil Events] Detected first map in campaign: %s", mapName);
            }
            
            // *** METHOD 2: Detect if map is NOT the first map, and try to identify starting point ***
            if (!foundSpawn && !isFirstMap) {
                // Determine if we need to find the first checkpoint or the starting saferoom
                // For non-first maps, we want to find the FIRST checkpoint, not the end saferoom
                
                // Check for nav spawn areas with "start" or "begin" markers
                int navarea = -1;
                while ((navarea = FindEntityByClassname(navarea, "terror_nav_mark_area")) != -1) {
                    char areaName[64];
                    if (GetEntPropString(navarea, Prop_Data, "m_iName", areaName, sizeof(areaName)) > 0) {
                        if (StrContains(areaName, "start", false) != -1 || 
                            StrContains(areaName, "begin", false) != -1 || 
                            StrContains(areaName, "saferoom", false) != -1) {
                            
                            GetEntPropVector(navarea, Prop_Data, "m_vecOrigin", safePos);
                            PrintToServer("[Evil Events] Found start area marker at %.1f, %.1f, %.1f", 
                                safePos[0], safePos[1], safePos[2]);
                            foundSpawn = true;
                            break;
                        }
                    }
                }
            }
            
            // *** METHOD 3: Try standard spawn entities (but ONLY if this is the first map) ***
            if (!foundSpawn && isFirstMap) {
                // Only use player_start on first maps where it's less likely to be at finale
                int navSpawn = -1;
                while ((navSpawn = FindEntityByClassname(navSpawn, "info_player_start")) != -1) {
                    // Get position
                    GetEntPropVector(navSpawn, Prop_Data, "m_vecOrigin", safePos);
                    PrintToServer("[Evil Events] Found saferoom using info_player_start at %.1f, %.1f, %.1f", 
                        safePos[0], safePos[1], safePos[2]);
                    foundSpawn = true;
                    break;
                }
            }
            
            // *** METHOD 4: Try L4D1/L4D2 specific survivor spawn points (very reliable for starts) ***
            if (!foundSpawn) {
                int spawnPoint = -1;
                
                // L4D1 and L4D2 survivor spawn entities are always at start
                while ((spawnPoint = FindEntityByClassname(spawnPoint, "info_survivor_position")) != -1) {
                    GetEntPropVector(spawnPoint, Prop_Data, "m_vecOrigin", safePos);
                    PrintToServer("[Evil Events] Found saferoom using info_survivor_position at %.1f, %.1f, %.1f", 
                        safePos[0], safePos[1], safePos[2]);
                    foundSpawn = true;
                    break;
                }
            }
            
            // *** METHOD 5: Look for rescue closet first door - often near saferoom ***
            if (!foundSpawn) {
                int rescueCloset = -1;
                while ((rescueCloset = FindEntityByClassname(rescueCloset, "prop_door_rotating_checkpoint")) != -1) {
                    if (HasEntProp(rescueCloset, Prop_Data, "m_ModelName")) {
                        char modelName[128];
                        GetEntPropString(rescueCloset, Prop_Data, "m_ModelName", modelName, sizeof(modelName));
                        
                        // Model for the start saferoom door
                        if (StrContains(modelName, "checkpoint_door_01", false) != -1 ||
                            StrContains(modelName, "door_apartment", false) != -1) {
                            
                            float doorPos[3], doorAngles[3], facingDir[3];
                            GetEntPropVector(rescueCloset, Prop_Data, "m_vecOrigin", doorPos);
                            GetEntPropVector(rescueCloset, Prop_Data, "m_angRotation", doorAngles);
                            
                            // Get direction the door is facing
                            GetAngleVectors(doorAngles, facingDir, NULL_VECTOR, NULL_VECTOR);
                            
                            // Move inside the door (opposite of facing direction)
                            safePos[0] = doorPos[0] - (facingDir[0] * 150.0);
                            safePos[1] = doorPos[1] - (facingDir[1] * 150.0);
                            safePos[2] = doorPos[2] + 10.0;
                            
                            PrintToServer("[Evil Events] Found saferoom using checkpoint door model at %.1f, %.1f, %.1f", 
                                safePos[0], safePos[1], safePos[2]);
                    foundSpawn = true;
                            break;
                        }
                    }
                }
            }
            
            // *** METHOD 6: Look for specific weapon clusters that indicate a starting point ***
            if (!foundSpawn) {
                // First aid kits are almost always at start positions in L4D2
                int medkitCount = 0;
                float medkitPositions[10][3];
                
                int medkitSpawn = -1;
                while ((medkitSpawn = FindEntityByClassname(medkitSpawn, "weapon_first_aid_kit_spawn")) != -1 && medkitCount < 10) {
                    GetEntPropVector(medkitSpawn, Prop_Data, "m_vecOrigin", medkitPositions[medkitCount]);
                    medkitCount++;
                }
                
                if (medkitCount >= 2) {
                    // Find the most clustered medkits (likely in starting area)
                    int bestClusterIdx = 0;
                    int bestClusterSize = 0;
                    
                    for (int i = 0; i < medkitCount; i++) {
                        int clusterSize = 0;
                        for (int j = 0; j < medkitCount; j++) {
                            if (GetVectorDistance(medkitPositions[i], medkitPositions[j]) < 500.0) {
                                clusterSize++;
                            }
                        }
                        
                        if (clusterSize > bestClusterSize) {
                            bestClusterSize = clusterSize;
                            bestClusterIdx = i;
                        }
                    }
                    
                    safePos = medkitPositions[bestClusterIdx];
                    PrintToServer("[Evil Events] Found saferoom using medkit cluster at %.1f, %.1f, %.1f", 
                        safePos[0], safePos[1], safePos[2]);
                    foundSpawn = true;
                }
            }
            
            // *** METHOD 7: Detect if there's a finale trigger, and if so, find the furthest point away ***
            if (!foundSpawn) {
                int finaleEntity = -1;
                float finalePos[3];
                bool foundFinale = false;
                
                // Check for finale triggers
                while ((finaleEntity = FindEntityByClassname(finaleEntity, "trigger_finale")) != -1) {
                    GetEntPropVector(finaleEntity, Prop_Data, "m_vecOrigin", finalePos);
                    foundFinale = true;
                    break;
                }
                
                // If we found a finale trigger, search for the furthest door away
                if (foundFinale) {
                    int door = -1;
                    int bestDoor = -1;
                    float bestDistance = 0.0;
                    
                    while ((door = FindEntityByClassname(door, "prop_door_rotating_checkpoint")) != -1) {
                        float doorPos[3];
                        GetEntPropVector(door, Prop_Data, "m_vecOrigin", doorPos);
                        
                        float distance = GetVectorDistance(doorPos, finalePos);
                        if (distance > bestDistance) {
                            bestDistance = distance;
                            bestDoor = door;
                        }
                    }
                    
                    // If we found a door furthest from finale, use it
                    if (bestDoor != -1) {
                        float doorPos[3], doorAngles[3], facingDir[3];
                        GetEntPropVector(bestDoor, Prop_Data, "m_vecOrigin", doorPos);
                        GetEntPropVector(bestDoor, Prop_Data, "m_angRotation", doorAngles);
                        
                        // Get direction the door is facing
                        GetAngleVectors(doorAngles, facingDir, NULL_VECTOR, NULL_VECTOR);
                        
                        // Move inside the door (opposite of facing direction)
                        safePos[0] = doorPos[0] - (facingDir[0] * 150.0);
                        safePos[1] = doorPos[1] - (facingDir[1] * 150.0);
                        safePos[2] = doorPos[2] + 10.0;
                        
                        PrintToServer("[Evil Events] Found saferoom by finding door furthest from finale at %.1f, %.1f, %.1f", 
                            safePos[0], safePos[1], safePos[2]);
                        foundSpawn = true;
                    }
                }
            }
            
            // *** METHOD 8: Scan for map-specific entities that hint at starting position ***
            if (!foundSpawn) {
                // Look for objectives at the start
                int objective = -1;
                while ((objective = FindEntityByClassname(objective, "game_scavenge_progress_display")) != -1) {
                    float objPos[3];
                    GetEntPropVector(objective, Prop_Data, "m_vecOrigin", objPos);
                    
                    // Find closest door to this objective
                    int door = -1;
                    float closestDist = 999999.0;
                    float doorPos[3];
                    
                    while ((door = FindEntityByClassname(door, "prop_door_rotating")) != -1) {
                        GetEntPropVector(door, Prop_Data, "m_vecOrigin", doorPos);
                        float dist = GetVectorDistance(objPos, doorPos);
                        
                        if (dist < closestDist) {
                            closestDist = dist;
                            safePos = doorPos;
                        }
                    }
                    
                    if (closestDist < 999999.0) {
                        PrintToServer("[Evil Events] Found start position via objective marker at %.1f, %.1f, %.1f", 
                            safePos[0], safePos[1], safePos[2]);
                        foundSpawn = true;
                        break;
                    }
                }
            }
            
            // *** METHOD 9: First player spawn location fallback (only if this is first map) ***
            if (!foundSpawn && isFirstMap) {
                for (int i = 1; i <= MaxClients; i++) {
                    if (IsClientInGame(i) && IsSurvivor(i)) {
                        float playerPos[3];
                        GetClientAbsOrigin(i, playerPos);
                        
                        // Only use if not default position
                        float dist = SquareRoot(playerPos[0]*playerPos[0] + playerPos[1]*playerPos[1] + playerPos[2]*playerPos[2]);
                        if (dist > 100.0) {
                            safePos = playerPos;
                            PrintToServer("[Evil Events] Using player position as fallback at %.1f, %.1f, %.1f", 
                                safePos[0], safePos[1], safePos[2]);
                            foundSpawn = true;
                            break;
                        }
                    }
                }
            }
            
            // If we found any valid spawn point
            if (foundSpawn) {
                // Teleport all alive survivors to this position
                PrintToServer("[Evil Events] Teleporting all survivors to START saferoom at %.1f, %.1f, %.1f", 
                    safePos[0], safePos[1], safePos[2]);
                
                // Set all survivors to make sure they don't get stuck
                for (int i = 1; i <= MaxClients; i++) {
                    if (IsClientInGame(i) && IsSurvivor(i) && IsPlayerAlive(i)) {
                        // Clear any movement before teleporting to avoid getting stuck
                        TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, view_as<float>({0.0, 0.0, 0.0}));
                        
                        // Raise position slightly to avoid getting stuck in ground/ceiling
                        float teleportPos[3], upPos[3], ceiling[3];
                        teleportPos = safePos;
                        upPos = safePos;
                        upPos[2] += 150.0; // Check 150 units up
                        
                        Handle trace = TR_TraceRayFilterEx(teleportPos, upPos, MASK_SOLID, RayType_EndPoint, TraceFilter_NoPlayers);
                        if (TR_DidHit(trace)) {
                            // Found a ceiling - position player carefully
                            TR_GetEndPosition(ceiling, trace);
                            // Position player 60 units below ceiling (player height is ~72 units)
                            teleportPos[2] = ceiling[2] - 60.0;
                        } else {
                            // No ceiling found, just add a safe offset from floor
                            teleportPos[2] += 10.0;
                        }
                        delete trace;
                        
                        // Teleport the player
                        TeleportEntity(i, teleportPos, NULL_VECTOR, NULL_VECTOR);
                        PrintToServer("[Evil Events] Teleported %N to saferoom", i);
                        
                        // Store original position in case we can't find a good unstuck position
                        g_vOriginalPosition[i] = teleportPos;
                        
                        // Start unstuck checks for players in case they get stuck
                        g_iUnstuckAttempts[i] = 0;
                        if (g_hUnstuckTimers[i] != null) {
                            KillTimer(g_hUnstuckTimers[i]);
                            g_hUnstuckTimers[i] = null;
                        }
                        g_hUnstuckTimers[i] = CreateTimer(0.2, Timer_CheckPlayerStuck, i, TIMER_REPEAT);
                    }
                }
                
                // Display message to all players
                PrintToChatAll("\x04[Evil Event] \x01 Team teleported back to \x04START saferoom\x01!");
                
                // Show hint text
                for (int i = 1; i <= MaxClients; i++) {
                    if (IsClientInGame(i) && IsSurvivor(i) && IsPlayerAlive(i)) {
                        PrintHintText(i, "You've been teleported back to the start!\nRegrouping required!");
                    }
                }
            } else {
                // If no spawn point found at all, teleport players randomly across the map
                PrintToServer("[Evil Events] No saferoom found, using random map spawning instead");
                
                // Spawn each survivor at a different random position
                int spawnedPlayers = 0;
                
                for (int i = 1; i <= MaxClients; i++) {
                    if (IsClientInGame(i) && IsSurvivor(i) && IsPlayerAlive(i)) {
                        float randomPos[3];
                        // Try to find a safe random position up to 10 times
                        bool foundSafePos = false;
                        
                        for (int attempt = 0; attempt < 10 && !foundSafePos; attempt++) {
                            // Get a survivor's position as a starting reference point
                            int randomSurvivor = FindRandomSurvivor();
                            if (randomSurvivor > 0) {
                                float referencePos[3];
                                GetClientAbsOrigin(randomSurvivor, referencePos);
                                
                                // Generate a random position within reasonable distance
                                randomPos[0] = referencePos[0] + GetRandomFloat(-1500.0, 1500.0);
                                randomPos[1] = referencePos[1] + GetRandomFloat(-1500.0, 1500.0);
                                randomPos[2] = referencePos[2] + 500.0; // Start high and trace down
                                
                                // Find ground position
                                if (GetValidGroundPosition(randomPos, randomPos)) {
                                    foundSafePos = true;
                                }
                            }
                        }
                        
                        if (foundSafePos) {
                            // Teleport the player to this random position
                            TeleportEntity(i, randomPos, NULL_VECTOR, NULL_VECTOR);
                            PrintToServer("[Evil Events] Teleported %N to random position: %.1f, %.1f, %.1f", 
                                i, randomPos[0], randomPos[1], randomPos[2]);
                            
                            // Store original position in case we can't find a good unstuck position
                            g_vOriginalPosition[i] = randomPos;
                            
                            // Start unstuck checks for players in case they get stuck
                            g_iUnstuckAttempts[i] = 0;
                            if (g_hUnstuckTimers[i] != null) {
                                KillTimer(g_hUnstuckTimers[i]);
                                g_hUnstuckTimers[i] = null;
                            }
                            g_hUnstuckTimers[i] = CreateTimer(0.2, Timer_CheckPlayerStuck, i, TIMER_REPEAT);
                            
                            spawnedPlayers++;
                        }
                    }
                }
                
                // If we couldn't spawn any players at random positions, fall back to regrouping
                if (spawnedPlayers == 0) {
                    int survivor = FindRandomSurvivor();
                    if (survivor > 0) {
                        GetClientAbsOrigin(survivor, safePos);
                        for (int i = 1; i <= MaxClients; i++) {
                            if (IsClientInGame(i) && IsSurvivor(i) && IsPlayerAlive(i) && i != survivor) {
                                TeleportEntity(i, safePos, NULL_VECTOR, NULL_VECTOR);
                            }
                        }
                        PrintToChatAll("\x04[Evil Event] \x01 Team has been \x04regrouped\x01 (couldn't find valid random positions)!");
                    }
                } else {
                    PrintToChatAll("\x04[Evil Event] \x01 Team has been \x04scattered\x01 across the map!");
                    
                    // Show hint text
                    for (int i = 1; i <= MaxClients; i++) {
                        if (IsClientInGame(i) && IsSurvivor(i) && IsPlayerAlive(i)) {
                            PrintHintText(i, "You've been randomly teleported!\nFind your teammates!");
                        }
                    }
                }
            }
            CreateTimer(5.0, Timer_EventComplete);
        }
        
        case 4: {
            // Single Angry Witch
            float pos[3], ang[3];
            float vecPos[3];
            
            int survivor = FindRandomSurvivor();
            if (survivor > 0) {
                GetClientAbsOrigin(survivor, pos);
                GetClientAbsAngles(survivor, ang);
                
                vecPos = pos;
                vecPos[0] += GetRandomFloat(-400.0, 400.0);
                vecPos[1] += GetRandomFloat(-400.0, 400.0);
                
                float ground[3];
                if (GetValidGroundPosition(vecPos, ground)) {
                    int witch = L4D2_SpawnWitch(ground, ang);
                    if (witch > 0) {
                        PrintToChatAll("\x04[Evil Event] \x01 An \x04 Angry Witch\x01 is charging at you!");
                        
                        SetEntProp(witch, Prop_Send, "m_mobRush", 1);
                        SetEntProp(witch, Prop_Send, "m_isAngry", 1);
                        CreateTimer(0.1, Timer_CheckWitchStuck, witch, TIMER_REPEAT);
                        
                        // Show hint text
                        for (int i = 1; i <= MaxClients; i++) {
                            if (IsClientInGame(i) && IsSurvivor(i) && IsPlayerAlive(i)) {
                                PrintHintText(i, "DANGER: Enraged Witch!\nKeep your distance and avoid her attack!");
                            }
                        }
                    } else {
                        PrintToChatAll("\x04[Evil Event] \x01 Error: Failed to spawn the \x04Witch\x01!");
                    }
                } else {
                    PrintToChatAll("\x04[Evil Event] \x01 Error: Could not find valid spawn position!");
                }
            } else {
                PrintToChatAll("\x04[Evil Event] \x01 Error: No valid survivors found!");
            }
            CreateTimer(30.0, Timer_EventComplete);
        }
        
        case 5: {
            // Special infected party
            float pos[3], ang[3];
            float vecPos[3];
            int spawnedInfected = 0;
            
            int survivor = FindRandomSurvivor();
            if (survivor > 0) {
                GetClientAbsOrigin(survivor, pos);
                GetClientAbsAngles(survivor, ang);
                
                int zombieClasses[6] = {
                    ZOMBIECLASS_SMOKER,
                    ZOMBIECLASS_BOOMER,
                    ZOMBIECLASS_HUNTER,
                    ZOMBIECLASS_SPITTER,
                    ZOMBIECLASS_JOCKEY,
                    ZOMBIECLASS_CHARGER
                };
                
                for (int i = 0; i < 6; i++) {
                    float distance = GetRandomFloat(600.0, 1000.0);
                    float angle = float(i) * (360.0 / 6.0);
                    
                    vecPos = pos;
                    vecPos[0] += distance * Cosine(angle * 3.14159265359 / 180.0);
                    vecPos[1] += distance * Sine(angle * 3.14159265359 / 180.0);
                    
                    float ground[3];
                    if (GetValidGroundPosition(vecPos, ground)) {
                        if (L4D2_SpawnSpecial(zombieClasses[i], ground, ang) > 0) {
                            spawnedInfected++;
                        }
                    }
                }
                
                if (spawnedInfected > 0) {
                    PrintToChatAll("\x04[Evil Event] \x01 Special infected \x04 Party\x01 with \x04%d\x01 infected! Run!", spawnedInfected);
                    
                    // Show hint text to all survivors
                    for (int i = 1; i <= MaxClients; i++) {
                        if (IsClientInGame(i) && IsSurvivor(i) && IsPlayerAlive(i)) {
                            PrintHintText(i, "DANGER: Multiple Special Infected approaching!\nPrepare for coordinated attack!");
                        }
                    }
                }
            }
            CreateTimer(30.0, Timer_EventComplete);
        }

        case 6: {
            // Mega Horde Rush
            int flags = GetCommandFlags("director_force_panic_event");
            SetCommandFlags("director_force_panic_event", flags & ~FCVAR_CHEAT);
            
            // Store original values
            ConVar z_mega_mob_size = FindConVar("z_mega_mob_size");
            ConVar z_mob_spawn_max_size = FindConVar("z_mob_spawn_max_size");
            ConVar z_mob_spawn_min_size = FindConVar("z_mob_spawn_min_size");
            
            int original_mega_size = z_mega_mob_size.IntValue;
            int original_max_size = z_mob_spawn_max_size.IntValue;
            int original_min_size = z_mob_spawn_min_size.IntValue;
            
            // Set massive horde values
            z_mega_mob_size.SetInt(150);
            z_mob_spawn_max_size.SetInt(100);
            z_mob_spawn_min_size.SetInt(50);
            
            // Announce first
            PrintToChatAll("\x04[Evil Event] \x01 MASSIVE \x04 Horde\x01 incoming! Run or die!");
            
            // Show hint text
            for (int i = 1; i <= MaxClients; i++) {
                if (IsClientInGame(i) && IsSurvivor(i) && IsPlayerAlive(i)) {
                    PrintHintText(i, "MASSIVE HORDE INCOMING!\nFind defensible position or keep moving!");
                }
            }
            
            // Trigger waves with slight delay
            CreateTimer(2.0, Timer_TriggerExtraWave);  // First wave
            CreateTimer(5.0, Timer_TriggerExtraWave);  // Second wave
            CreateTimer(8.0, Timer_TriggerExtraWave);  // Third wave
            
            // Reset values after 30 seconds
            Handle pack = CreateDataPack();
            WritePackCell(pack, original_mega_size);
            WritePackCell(pack, original_max_size);
            WritePackCell(pack, original_min_size);
            CreateTimer(30.0, Timer_ResetHordeValues, pack);
            
            CreateTimer(35.0, Timer_EventComplete);
        }
        
        case 7: {
            // Enhanced Darkness Event
            // Create primary fog controller
            int fog = CreateEntityByName("env_fog_controller");
            if (fog != -1) {
                DispatchKeyValue(fog, "fogcolor", "0 0 0");
                DispatchKeyValue(fog, "fogcolor2", "0 0 0");
                DispatchKeyValue(fog, "fogstart", "0");
                DispatchKeyValue(fog, "fogend", "150");
                DispatchKeyValue(fog, "fogmaxdensity", "0.99");
                DispatchSpawn(fog);
                AcceptEntityInput(fog, "TurnOn");
                
                // Create secondary fog for extra darkness
                int fog2 = CreateEntityByName("env_fog_controller");
                if (fog2 != -1) {
                    DispatchKeyValue(fog2, "fogcolor", "16 16 16");
                    DispatchKeyValue(fog2, "fogcolor2", "16 16 16");
                    DispatchKeyValue(fog2, "fogstart", "0");
                    DispatchKeyValue(fog2, "fogend", "200");
                    DispatchKeyValue(fog2, "fogmaxdensity", "0.99");
                    DispatchSpawn(fog2);
                    AcceptEntityInput(fog2, "TurnOn");
                }
                
                // Create darkness overlay
                int overlay = CreateEntityByName("env_fade");
                if (overlay != -1) {
                    DispatchKeyValue(overlay, "duration", "3");
                    DispatchKeyValue(overlay, "holdtime", "20");
                    DispatchKeyValue(overlay, "rendercolor", "0 0 0");
                    DispatchKeyValue(overlay, "renderamt", "235");
                    DispatchSpawn(overlay);
                    AcceptEntityInput(overlay, "Fade");
                }
                
                // Create darkness screen effect
                int screen = CreateEntityByName("env_screenoverlay");
                if (screen != -1) {
                    DispatchKeyValue(screen, "OverlayName1", "effects/black");
                    DispatchKeyValue(screen, "StartOverlayTime1", "0");
                    DispatchKeyValue(screen, "OverlayTime1", "20");
                    DispatchSpawn(screen);
                    AcceptEntityInput(screen, "StartOverlay");
                }
                
                PrintToChatAll("\x04[Evil Event] \x01 The \x04 Darkness\x01 descends!");
                
                // Show hint text
                for (int i = 1; i <= MaxClients; i++) {
                    if (IsClientInGame(i) && IsSurvivor(i) && IsPlayerAlive(i)) {
                        PrintHintText(i, "Extreme darkness has fallen!\nStay close and use your flashlight!");
                    }
                }
                
                // Store entities for cleanup
                Handle pack = CreateDataPack();
                WritePackCell(pack, fog);
                WritePackCell(pack, fog2);
                WritePackCell(pack, overlay);
                WritePackCell(pack, screen);
                
                CreateTimer(20.0, Timer_ResetDarkness, pack);
                CreateTimer(25.0, Timer_EventComplete);
            } else {
                PrintToChatAll("\x04[Evil Event] \x01 Error: Could not create darkness effect!");
                CreateTimer(1.0, Timer_EventComplete);
            }
        }
        
        case 8: {
            // Toxic Gas Event
            float pos[3];
            int particleCount = 0;
            
            for (int i = 1; i <= MaxClients; i++) {
                if (IsClientInGame(i) && IsSurvivor(i) && IsPlayerAlive(i)) {
                    GetClientAbsOrigin(i, pos);
                    
                    // Create multiple particle effects for more visibility
                    for (int layer = 0; layer < 3; layer++) {
                        int particle = CreateEntityByName("info_particle_system");
                        if (particle != -1) {
                            char particleName[64];
                            Format(particleName, sizeof(particleName), "gas_particle_%d_%d", i, layer);
                            DispatchKeyValue(particle, "targetname", particleName);
                            
                            // Use different effects for better visibility
                            switch(layer) {
                                case 0: DispatchKeyValue(particle, "effect_name", "smoker_smokecloud");
                                case 1: DispatchKeyValue(particle, "effect_name", "spitter_area");
                                case 2: DispatchKeyValue(particle, "effect_name", "boomer_explode");
                            }
                            
                            DispatchSpawn(particle);
                            ActivateEntity(particle);
                            
                            // Slightly offset each layer for better coverage
                            float layerPos[3];
                            layerPos = pos;
                            layerPos[0] += GetRandomFloat(-50.0, 50.0);
                            layerPos[1] += GetRandomFloat(-50.0, 50.0);
                            layerPos[2] += float(layer) * 20.0;
                            
                            TeleportEntity(particle, layerPos, NULL_VECTOR, NULL_VECTOR);
                            AcceptEntityInput(particle, "Start");
                            
                            // Create timer to damage player
                            DataPack pack = new DataPack();
                            pack.WriteCell(GetClientUserId(i));
                            pack.WriteCell(particle);
                            CreateTimer(0.5, Timer_DamagePlayer, pack, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
                            
                            particleCount++;
                        }
                    }
                }
            }
            
            if (particleCount > 0) {
                PrintToChatAll("\x04[Evil Event] \x01 \x04Deadly Toxic Gas\x01 is spreading! Get to higher ground!");
                
                // Show hint text to all survivors
                for (int i = 1; i <= MaxClients; i++) {
                    if (IsClientInGame(i) && IsSurvivor(i) && IsPlayerAlive(i)) {
                        PrintHintText(i, "WARNING: Toxic Gas Detected!\nMove to higher ground or clear areas!");
                    }
                }
                
                CreateTimer(15.0, Timer_RemoveGas);
                CreateTimer(20.0, Timer_EventComplete);
            } else {
                CreateTimer(1.0, Timer_EventComplete);
            }
        }

        case 9: {
            // Renamed to Toxic Atmosphere since it's not really rain anymore
            PrintToChatAll("\x04[Evil Event] \x01 \x04 Toxic Atmosphere\x01 surrounds you! Moving players take damage!");
            
            // Create a director script that triggers effects
            int director = CreateEntityByName("info_director");
            if (director != -1) {
                DispatchSpawn(director);
                ActivateEntity(director);
                
                // Rain color can be set via fog instead
                int fogController = CreateEntityByName("env_fog_controller");
                if (fogController != -1) {
                    DispatchKeyValue(fogController, "fogcolor", "144 238 144"); // Light green for toxic air
                    DispatchKeyValue(fogController, "fogstart", "0");
                    DispatchKeyValue(fogController, "fogend", "800");
                    DispatchKeyValue(fogController, "fogmaxdensity", "0.6");
                    DispatchSpawn(fogController);
                    AcceptEntityInput(fogController, "TurnOn");
                    
                    // Store for cleanup
                    CreateTimer(20.0, Timer_RemoveEntity, fogController);
                }
                
                // Create a color correction to give everything a green tint
                int colorCorrection = CreateEntityByName("color_correction");
                if (colorCorrection != -1) {
                    DispatchKeyValue(colorCorrection, "maxweight", "1.0");
                    DispatchKeyValue(colorCorrection, "fadeInDuration", "1.0");
                    DispatchKeyValue(colorCorrection, "fadeOutDuration", "1.0");
                    DispatchSpawn(colorCorrection);
                    ActivateEntity(colorCorrection);
                    AcceptEntityInput(colorCorrection, "Enable");
                    
                    // Store for cleanup
                    CreateTimer(20.0, Timer_RemoveEntity, colorCorrection);
                }
                
                // Use effects as a substitute for toxic atmosphere
                for (int i = 0; i < 4; i++) {
                    // Create effect at different points around players
                        int survivor = FindRandomSurvivor();
                        if (survivor > 0) {
                        float pos[3];
                            GetClientAbsOrigin(survivor, pos);
                        pos[0] += GetRandomFloat(-300.0, 300.0);
                        pos[1] += GetRandomFloat(-300.0, 300.0);
                        pos[2] += 200.0;
                        
                        int env_steam = CreateEntityByName("env_steam");
                        if (env_steam != -1) {
                            char targetname[32];
                            Format(targetname, sizeof(targetname), "toxic_steam_%d", i);
                            DispatchKeyValue(env_steam, "targetname", targetname);
                            DispatchKeyValue(env_steam, "SpawnFlags", "1");
                            DispatchKeyValue(env_steam, "rendercolor", "144 238 144");
                            DispatchKeyValue(env_steam, "SpreadSpeed", "10");
                            DispatchKeyValue(env_steam, "Speed", "80");
                            DispatchKeyValue(env_steam, "StartSize", "10");
                            DispatchKeyValue(env_steam, "EndSize", "100");
                            DispatchKeyValue(env_steam, "Rate", "12");
                            DispatchKeyValue(env_steam, "JetLength", "400");
                            DispatchKeyValue(env_steam, "renderamt", "180");
                            DispatchKeyValue(env_steam, "InitialState", "1");
                            DispatchSpawn(env_steam);
                            TeleportEntity(env_steam, pos, NULL_VECTOR, NULL_VECTOR);
                            AcceptEntityInput(env_steam, "TurnOn");
                        
                        // Store for cleanup
                            CreateTimer(20.0, Timer_RemoveEntity, env_steam);
                        }
                    }
                }
                
                // Create another effect using boomer particles which do exist
                for (int i = 0; i < 3; i++) {
                        int survivor = FindRandomSurvivor();
                        if (survivor > 0) {
                        float pos[3];
                            GetClientAbsOrigin(survivor, pos);
                        pos[0] += GetRandomFloat(-200.0, 200.0);
                        pos[1] += GetRandomFloat(-200.0, 200.0);
                        pos[2] += 150.0;
                        
                        int particle = CreateEntityByName("info_particle_system");
                        if (particle != -1) {
                            char targetname[32];
                            Format(targetname, sizeof(targetname), "toxic_particle_%d", i);
                            DispatchKeyValue(particle, "targetname", targetname);
                            DispatchKeyValue(particle, "effect_name", "boomer_explode");
                            DispatchSpawn(particle);
                            ActivateEntity(particle);
                            TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
                            AcceptEntityInput(particle, "Start");
                            
                            // Create timer to remove after a short time
                            CreateTimer(0.5, Timer_RemoveEntity, particle);
                        }
                    }
                }
                
                // Create timer to periodically apply effects and damage
                CreateTimer(1.0, Timer_AcidRainEffects, 0, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
                
                // Create timer for toxic atmosphere damage check
                CreateTimer(1.0, Timer_AcidRainDamage, director, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
                
                // Show hint to all players explaining how the event works
                for (int i = 1; i <= MaxClients; i++) {
                    if (IsClientInGame(i) && IsSurvivor(i) && IsPlayerAlive(i)) {
                        PrintHintText(i, "TOXIC ATMOSPHERE DETECTED!\nMoving players take damage\nStand still to avoid damage");
                    }
                }
                
                // Store entity for cleanup
                CreateTimer(20.0, Timer_RemoveEntity, director);
                CreateTimer(25.0, Timer_EventComplete);
            } else {
                PrintToChatAll("\x04[Evil Event] \x01 Error: Could not create toxic atmosphere effect!");
                CreateTimer(1.0, Timer_EventComplete);
            }
        }
    }
}

public Action Timer_TriggerExtraWave(Handle timer) {
    ServerCommand("director_force_panic_event");
    return Plugin_Stop;
}

public Action Timer_ResetHordeValues(Handle timer, Handle pack) {
    if (pack == INVALID_HANDLE) return Plugin_Stop;
    
    ResetPack(pack);
    int original_mega_size = ReadPackCell(pack);
    int original_max_size = ReadPackCell(pack);
    int original_min_size = ReadPackCell(pack);
    CloseHandle(pack);
    
    ConVar z_mega_mob_size = FindConVar("z_mega_mob_size");
    ConVar z_mob_spawn_max_size = FindConVar("z_mob_spawn_max_size");
    ConVar z_mob_spawn_min_size = FindConVar("z_mob_spawn_min_size");
    
    z_mega_mob_size.SetInt(original_mega_size);
    z_mob_spawn_max_size.SetInt(original_max_size);
    z_mob_spawn_min_size.SetInt(original_min_size);
    
    return Plugin_Stop;
}

public Action Timer_ResetDarkness(Handle timer, Handle pack) {
    if (pack == INVALID_HANDLE) return Plugin_Stop;
    
    ResetPack(pack);
    int fog = ReadPackCell(pack);
    int fog2 = ReadPackCell(pack);
    int overlay = ReadPackCell(pack);
    int screen = ReadPackCell(pack);
    CloseHandle(pack);
    
    // Remove fog entities
    if (IsValidEntity(fog)) {
        AcceptEntityInput(fog, "Kill");
    }
    if (IsValidEntity(fog2)) {
        AcceptEntityInput(fog2, "Kill");
    }
    
    // Remove overlay
    if (IsValidEntity(overlay)) {
        AcceptEntityInput(overlay, "Kill");
    }
    
    // Remove screen effect
    if (IsValidEntity(screen)) {
        AcceptEntityInput(screen, "StopOverlay");
        AcceptEntityInput(screen, "Kill");
    }
    
    // Create fade out effect
    int fadeOut = CreateEntityByName("env_fade");
    if (fadeOut != -1) {
        DispatchKeyValue(fadeOut, "duration", "2");
        DispatchKeyValue(fadeOut, "holdtime", "0");
        DispatchKeyValue(fadeOut, "rendercolor", "0 0 0");
        DispatchKeyValue(fadeOut, "renderamt", "0");
        DispatchSpawn(fadeOut);
        AcceptEntityInput(fadeOut, "Fade");
        CreateTimer(3.0, Timer_KillEntity, fadeOut);
    }
    
    PrintToChatAll("\x04[Evil Event] \x01 The \x04 Darkness\x01 is lifting!");
    return Plugin_Stop;
}

public Action Timer_KillEntity(Handle timer, any entity) {
    if (IsValidEntity(entity)) {
        AcceptEntityInput(entity, "Kill");
    }
    return Plugin_Stop;
}

public Action Timer_CheckTankStuck(Handle timer, any entityId) {
    if (!IsValidEntity(entityId)) return Plugin_Stop;
    
    float currentPos[3], lastPos[3];
    static float lastPositions[2048][3];
    GetEntPropVector(entityId, Prop_Data, "m_vecOrigin", currentPos);
    lastPos = lastPositions[entityId];
    lastPositions[entityId] = currentPos;
    
    if (GetVectorDistance(currentPos, lastPos) < 1.0) {
        int survivor = FindRandomSurvivor();
        if (survivor > 0) {
            float survivorPos[3], teleportPos[3];
            GetClientAbsOrigin(survivor, survivorPos);
            
            for (int i = 0; i < 8; i++) {
                float angle = float(i) * 45.0;
                teleportPos = survivorPos;
                teleportPos[0] += 300.0 * Cosine(angle * 3.14159265359 / 180.0);
                teleportPos[1] += 300.0 * Sine(angle * 3.14159265359 / 180.0);
                
                float ground[3];
                if (GetValidGroundPosition(teleportPos, ground)) {
                    TeleportEntity(entityId, ground, NULL_VECTOR, NULL_VECTOR);
                    ForceEntityToMove(entityId);
                    break;
                }
            }
        }
    }
    
    return Plugin_Continue;
}

public Action Timer_CheckWitchStuck(Handle timer, any entityId) {
    if (!IsValidEntity(entityId)) return Plugin_Stop;
    
    float currentPos[3], lastPos[3];
    static float lastPositions[2048][3];
    GetEntPropVector(entityId, Prop_Data, "m_vecOrigin", currentPos);
    lastPos = lastPositions[entityId];
    lastPositions[entityId] = currentPos;
    
    if (GetVectorDistance(currentPos, lastPos) < 1.0) {
        int survivor = FindRandomSurvivor();
        if (survivor > 0) {
            float targetPos[3], teleportPos[3];
            GetClientAbsOrigin(survivor, targetPos);
            
            teleportPos = targetPos;
            teleportPos[0] += GetRandomFloat(-200.0, 200.0);
            teleportPos[1] += GetRandomFloat(-200.0, 200.0);
            
            float ground[3];
            if (GetValidGroundPosition(teleportPos, ground)) {
                TeleportEntity(entityId, ground, NULL_VECTOR, NULL_VECTOR);
            }
        }
    }
    
    return Plugin_Continue;
}

void ForceEntityToMove(int entity) {
    float vel[3];
    vel[0] = GetRandomFloat(-50.0, 50.0);
    vel[1] = GetRandomFloat(-50.0, 50.0);
    vel[2] = 0.0;
    TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, vel);
}

bool GetValidGroundPosition(float pos[3], float outPos[3]) {
    float startPos[3], endPos[3];
    startPos = pos;
    endPos = pos;
    startPos[2] += 500.0;
    endPos[2] -= 500.0;
    
    Handle trace = TR_TraceRayFilterEx(startPos, endPos, MASK_SOLID, RayType_EndPoint, TraceFilter_NoPlayers);
    if (TR_DidHit(trace)) {
        TR_GetEndPosition(outPos, trace);
        outPos[2] += 10.0;
        delete trace;
        return true;
    }
    delete trace;
    return false;
}

void RemovePlayerItems(int client) {
    int itemIdx;
    // Primary
    itemIdx = GetPlayerWeaponSlot(client, 0);
    if (itemIdx != -1) {
        RemovePlayerItem(client, itemIdx);
        AcceptEntityInput(itemIdx, "Kill");
    }
    // Secondary
    itemIdx = GetPlayerWeaponSlot(client, 1);
    if (itemIdx != -1) {
        RemovePlayerItem(client, itemIdx);
        AcceptEntityInput(itemIdx, "Kill");
    }
    // Throwable
    itemIdx = GetPlayerWeaponSlot(client, 2);
    if (itemIdx != -1) {
        RemovePlayerItem(client, itemIdx);
        AcceptEntityInput(itemIdx, "Kill");
    }
    // Medkit
    itemIdx = GetPlayerWeaponSlot(client, 3);
    if (itemIdx != -1) {
        RemovePlayerItem(client, itemIdx);
        AcceptEntityInput(itemIdx, "Kill");
    }
    // Pills/Adrenaline
    itemIdx = GetPlayerWeaponSlot(client, 4);
    if (itemIdx != -1) {
        RemovePlayerItem(client, itemIdx);
        AcceptEntityInput(itemIdx, "Kill");
    }
    
    // Give them a pistol so they're not completely helpless
    GivePlayerItem(client, "weapon_pistol");
}

int FindRandomSurvivor() {
    int[] survivors = new int[MaxClients];
    int count = 0;
    
    for (int i = 1; i <= MaxClients; i++) {
        if (IsClientInGame(i) && IsSurvivor(i) && IsPlayerAlive(i)) {
            survivors[count] = i;
            count++;
        }
    }
    
    return (count == 0) ? -1 : survivors[GetRandomInt(0, count - 1)];
}

bool IsSurvivor(int client) {
    if (client <= 0 || !IsClientInGame(client)) return false;
    return GetClientTeam(client) == TEAM_SURVIVOR;
}

public bool TraceFilter_NoPlayers(int entity, int contentsMask) {
    return (entity > MaxClients || !entity);
}

// Add the missing trace filter function for world-only collisions
public bool TraceFilter_OnlyWorld(int entity, int contentsMask) {
    return entity == 0; // Only allow world (entity index 0) to block traces
}

// Optional: Add debug commands
#if defined DEBUG
public Action Command_DebugInfo(int client, int args) {
    ReplyToCommand(client, "Events Triggered: %d", g_iEventsTriggered);
    ReplyToCommand(client, "Event In Progress: %s", g_bEventInProgress ? "Yes" : "No");
    ReplyToCommand(client, "First Event Triggered: %s", g_bFirstEventTriggered ? "Yes" : "No");
    ReplyToCommand(client, "Event Timer Active: %s", (g_hEventTimer != null) ? "Yes" : "No");
    return Plugin_Handled;
}
#endif

public Action Timer_DamagePlayer(Handle timer, DataPack pack) {
    pack.Reset();
    int userId = pack.ReadCell();
    int particle = pack.ReadCell();
    
    int client = GetClientOfUserId(userId);
    
    // Check if both client and particle entity are valid
    if (client <= 0 || !IsClientInGame(client) || !IsSurvivor(client) || !IsPlayerAlive(client) || 
        !IsValidEntity(particle)) {
        delete pack;
        return Plugin_Stop;
    }
    
    float playerPos[3], particlePos[3];
    GetClientAbsOrigin(client, playerPos);
    
    // Additional safety check before getting particle position
    if (!GetEntPropVector(particle, Prop_Send, "m_vecOrigin", particlePos)) {
        delete pack;
        return Plugin_Stop;
    }
    
    if (GetVectorDistance(playerPos, particlePos) < 300.0) {
        int damage = 2;
        int currentHealth = GetEntProp(client, Prop_Send, "m_iHealth");
        float currentTempHealth = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
        
        // Apply damage to temp health first
        if (currentTempHealth > 0.0) {
            float newTempHealth = currentTempHealth - float(damage);
            if (newTempHealth < 0.0) {
                damage = RoundToFloor(FloatAbs(newTempHealth));
                newTempHealth = 0.0;
            } else {
                damage = 0;
            }
            SetEntPropFloat(client, Prop_Send, "m_healthBuffer", newTempHealth);
        }
        
        // Apply remaining damage to regular health
        if (damage > 0) {
            if (currentHealth <= damage) {
                SetEntProp(client, Prop_Send, "m_isIncapacitated", 1);
                SetEntProp(client, Prop_Send, "m_iHealth", 1);
                SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 300.0);
            } else {
                SetEntProp(client, Prop_Send, "m_iHealth", currentHealth - damage);
            }
        }
        
        // Add hint text to show damage
        PrintHintText(client, "You're being poisoned by Toxic Gas!\nHealth: %d + %.1f Temp", 
            currentHealth - (damage > currentHealth ? currentHealth - 1 : damage), 
            GetEntPropFloat(client, Prop_Send, "m_healthBuffer"));
    }
    
    return Plugin_Continue;
}

public Action Timer_RemoveGas(Handle timer) {
    int particle = -1;
    while ((particle = FindEntityByClassname(particle, "info_particle_system")) != -1) {
        if (!IsValidEntity(particle)) {
            continue;
        }
        
        char targetname[64];
        if (GetEntPropString(particle, Prop_Data, "m_iName", targetname, sizeof(targetname)) > 0) {
            if (StrContains(targetname, "gas_particle_") != -1) {
                AcceptEntityInput(particle, "Stop");
                AcceptEntityInput(particle, "Kill");
            }
        }
    }
    return Plugin_Stop;
}

public Action Timer_RemoveEntity(Handle timer, any entity) {
    if (IsValidEntity(entity)) {
        AcceptEntityInput(entity, "Kill");
    }
    return Plugin_Stop;
}

public Action Timer_AcidRainEffects(Handle timer, any data) {
    // Check if the acid rain event is still active
    bool acidRainActive = false;
    for (int i = 1; i <= MaxClients; i++) {
        if (IsClientInGame(i) && IsSurvivor(i) && IsPlayerAlive(i)) {
            acidRainActive = true;
            break;
        }
    }
    
    if (!acidRainActive || g_bEventInProgress == false) return Plugin_Stop;
    
    // Create occasional smoke and spitter effects around players
    for (int i = 1; i <= MaxClients; i++) {
        if (!IsClientInGame(i) || !IsSurvivor(i) || !IsPlayerAlive(i)) continue;
        
        if (IsPlayerOutside(i) && GetRandomInt(0, 2) == 0) { // 1 in 3 chance
            float playerPos[3];
            GetClientAbsOrigin(i, playerPos);
            
            // Randomly choose between valid L4D2 effects
            int effectType = GetRandomInt(0, 1);
            char effectName[32];
            
            switch (effectType) {
                case 0: strcopy(effectName, sizeof(effectName), "smoker_smokecloud");
                case 1: strcopy(effectName, sizeof(effectName), "spitter_area");
            }
            
            int particle = CreateEntityByName("info_particle_system");
            if (particle != -1) {
                char targetname[32];
                Format(targetname, sizeof(targetname), "acid_effect_%d", i);
                DispatchKeyValue(particle, "targetname", targetname);
                DispatchKeyValue(particle, "effect_name", effectName);
                DispatchSpawn(particle);
                ActivateEntity(particle);
                
                // Position near player but not exactly on them
                float effectPos[3];
                effectPos[0] = playerPos[0] + GetRandomFloat(-50.0, 50.0);
                effectPos[1] = playerPos[1] + GetRandomFloat(-50.0, 50.0);
                effectPos[2] = playerPos[2] + GetRandomFloat(0.0, 10.0);
                
                TeleportEntity(particle, effectPos, NULL_VECTOR, NULL_VECTOR);
                AcceptEntityInput(particle, "Start");
                
                // Remove after a short time
                CreateTimer(GetRandomFloat(0.5, 1.5), Timer_RemoveEntity, particle);
            }
        }
    }
    
    return Plugin_Continue;
}

bool IsPlayerOutside(int client) {
    float vel[3];
    GetEntPropVector(client, Prop_Data, "m_vecVelocity", vel);
    float speed = SquareRoot(vel[0]*vel[0] + vel[1]*vel[1] + vel[2]*vel[2]);
    
    // If player is moving faster than walking speed, assume they're outside
    return (speed > 100.0);
}

// Replace your current random event selection code with this
int GetRandomEnabledEvent() {
    // Count enabled events
    int enabledEvents = 0;
    int enabledEventIds[10];  // Store IDs of enabled events
    
    // Check each event's ConVar
    if (g_cvEnableEvent0.BoolValue) enabledEventIds[enabledEvents++] = 0;
    if (g_cvEnableEvent1.BoolValue) enabledEventIds[enabledEvents++] = 1;
    if (g_cvEnableEvent2.BoolValue) enabledEventIds[enabledEvents++] = 2;
    if (g_cvEnableEvent3.BoolValue) enabledEventIds[enabledEvents++] = 3;
    if (g_cvEnableEvent4.BoolValue) enabledEventIds[enabledEvents++] = 4;
    if (g_cvEnableEvent5.BoolValue) enabledEventIds[enabledEvents++] = 5;
    if (g_cvEnableEvent6.BoolValue) enabledEventIds[enabledEvents++] = 6;
    if (g_cvEnableEvent7.BoolValue) enabledEventIds[enabledEvents++] = 7;
    if (g_cvEnableEvent8.BoolValue) enabledEventIds[enabledEvents++] = 8;
    if (g_cvEnableEvent9.BoolValue) enabledEventIds[enabledEvents++] = 9;
    
    // If no events are enabled, return -1
    if (enabledEvents == 0) return -1;
    
    // Return a random enabled event
    return enabledEventIds[GetRandomInt(0, enabledEvents - 1)];
}

public Action Command_ReloadConfig(int client, int args)
{
    if (!FileExists(g_sConfigFile))
    {
        ReplyToCommand(client, "[Evil Events] Config file not found: %s", g_sConfigFile);
        return Plugin_Handled;
    }
    
    // Execute the config file - note we're just using the relative path from cfg/
    ServerCommand("exec sourcemod/plugin.random_evil_events.cfg");
    
    // Force refresh all ConVar values - this ensures the plugin has the latest values
    bool globalEnabled = g_hEnabled.BoolValue;
    bool event0Enabled = g_cvEnableEvent0.BoolValue;
    bool event1Enabled = g_cvEnableEvent1.BoolValue;
    bool event2Enabled = g_cvEnableEvent2.BoolValue;
    bool event3Enabled = g_cvEnableEvent3.BoolValue;
    bool event4Enabled = g_cvEnableEvent4.BoolValue;
    bool event5Enabled = g_cvEnableEvent5.BoolValue;
    bool event6Enabled = g_cvEnableEvent6.BoolValue;
    bool event7Enabled = g_cvEnableEvent7.BoolValue;
    bool event8Enabled = g_cvEnableEvent8.BoolValue;
    bool event9Enabled = g_cvEnableEvent9.BoolValue;
    
    // Print current event states after reload
    PrintToServer("[Evil Events] Config reloaded. Current event states:");
    PrintToServer(" - Global enabled: %s", globalEnabled ? "YES" : "NO");
    PrintToServer(" - Double Tank: %s", event0Enabled ? "ENABLED" : "DISABLED");
    PrintToServer(" - Remove Items: %s", event1Enabled ? "ENABLED" : "DISABLED");
    PrintToServer(" - 1 HP Challenge: %s", event2Enabled ? "ENABLED" : "DISABLED");
    PrintToServer(" - Teleport: %s", event3Enabled ? "ENABLED" : "DISABLED");
    PrintToServer(" - Angry Witch: %s", event4Enabled ? "ENABLED" : "DISABLED");
    PrintToServer(" - Special Infected: %s", event5Enabled ? "ENABLED" : "DISABLED");
    PrintToServer(" - Mega Horde: %s", event6Enabled ? "ENABLED" : "DISABLED");
    PrintToServer(" - Darkness Falls: %s", event7Enabled ? "ENABLED" : "DISABLED");
    PrintToServer(" - Toxic Gas: %s", event8Enabled ? "ENABLED" : "DISABLED");
    PrintToServer(" - Toxic Atmosphere: %s", event9Enabled ? "ENABLED" : "DISABLED");
    
    // Count how many events are enabled
    int enabledCount = 0;
    if (event0Enabled) enabledCount++;
    if (event1Enabled) enabledCount++;
    if (event2Enabled) enabledCount++;
    if (event3Enabled) enabledCount++;
    if (event4Enabled) enabledCount++;
    if (event5Enabled) enabledCount++;
    if (event6Enabled) enabledCount++;
    if (event7Enabled) enabledCount++;
    if (event8Enabled) enabledCount++;
    if (event9Enabled) enabledCount++;
    
    // Also send this info to the client who reloaded the config
    if (client > 0) {
        ReplyToCommand(client, "[Evil Events] Config reloaded successfully");
        ReplyToCommand(client, " - Global enabled: %s", globalEnabled ? "YES" : "NO");
        ReplyToCommand(client, " - Events enabled: %d/10", enabledCount);
    }
    
    // If plugin is enabled and we have enabled events, restart the event system
    if (globalEnabled && enabledCount > 0) {
        // Wait a brief moment for config to fully apply
        CreateTimer(1.0, Timer_RestartEventsAfterConfig);
    }
    
    return Plugin_Handled;
}

public Action Timer_RestartEventsAfterConfig(Handle timer) {
    RestartEventSystem();
    return Plugin_Stop;
}

// New function to check if an event is enabled
bool IsEventEnabled(int eventId) {
    switch (eventId) {
        case 0: return g_cvEnableEvent0.BoolValue;
        case 1: return g_cvEnableEvent1.BoolValue;
        case 2: return g_cvEnableEvent2.BoolValue;
        case 3: return g_cvEnableEvent3.BoolValue;
        case 4: return g_cvEnableEvent4.BoolValue;
        case 5: return g_cvEnableEvent5.BoolValue;
        case 6: return g_cvEnableEvent6.BoolValue;
        case 7: return g_cvEnableEvent7.BoolValue;
        case 8: return g_cvEnableEvent8.BoolValue;
        case 9: return g_cvEnableEvent9.BoolValue;
        default: return false;
    }
}

// Add the missing Acid Rain damage function
public Action Timer_AcidRainDamage(Handle timer, any entity) {
    if (!IsValidEntity(entity) || !g_bEventInProgress) return Plugin_Stop;
    
    for (int i = 1; i <= MaxClients; i++) {
        if (!IsClientInGame(i) || !IsSurvivor(i) || !IsPlayerAlive(i)) continue;
        
        // Only damage players who are moving (assumed to be outside)
        if (IsPlayerOutside(i)) {
            int damage = GetRandomInt(1, 3); // Reduced damage a bit
            
            int currentHealth = GetEntProp(i, Prop_Send, "m_iHealth");
            float currentTempHealth = GetEntPropFloat(i, Prop_Send, "m_healthBuffer");
            
            // Create toxic effect around player 
            float playerPos[3];
            GetClientAbsOrigin(i, playerPos);
            playerPos[2] += 10.0;
            
            // Use smoker cloud as the effect
            int particle = CreateEntityByName("info_particle_system");
            if (particle != -1) {
                char targetname[32];
                Format(targetname, sizeof(targetname), "toxic_damage_%d", i);
                DispatchKeyValue(particle, "targetname", targetname);
                DispatchKeyValue(particle, "effect_name", "smoker_smokecloud");
                DispatchSpawn(particle);
                ActivateEntity(particle);
                TeleportEntity(particle, playerPos, NULL_VECTOR, NULL_VECTOR);
                AcceptEntityInput(particle, "Start");
                CreateTimer(0.5, Timer_RemoveEntity, particle);
            }
            
            // Apply damage to temp health first
            if (currentTempHealth > 0.0) {
                float newTempHealth = currentTempHealth - float(damage);
                if (newTempHealth < 0.0) {
                    damage = RoundToFloor(FloatAbs(newTempHealth));
                    newTempHealth = 0.0;
                } else {
                    damage = 0;
                }
                SetEntPropFloat(i, Prop_Send, "m_healthBuffer", newTempHealth);
                
                // Updated hint text
                PrintHintText(i, "Toxic atmosphere damaging you while moving!\nStop moving to avoid damage!\nHealth: %d + %.1f Temp", currentHealth, newTempHealth);
            }
            
            // Apply remaining damage to regular health
            if (damage > 0) {
                if (currentHealth <= damage) {
                    // Incapacitate the player if they're at critical health
                    if (GetEntProp(i, Prop_Send, "m_isIncapacitated") == 0) {
                        SetEntProp(i, Prop_Send, "m_isIncapacitated", 1);
                        SetEntProp(i, Prop_Send, "m_iHealth", 1);
                        SetEntPropFloat(i, Prop_Send, "m_healthBuffer", 300.0);
                        
                        // Clear any screen overlays for the incapacitated player
                        int screen = CreateEntityByName("env_screenoverlay");
                        if (screen != -1) {
                            DispatchKeyValue(screen, "OverlayName1", "");  // Empty overlay to clear existing ones
                            DispatchKeyValue(screen, "StartOverlayTime1", "0");
                            DispatchKeyValue(screen, "OverlayTime1", "1");
                            DispatchSpawn(screen);
                            
                            // Set the player as the target
                            SetVariantString("!activator");
                            AcceptEntityInput(screen, "DisplayOverlays", i);
                        }
                        
                        // Announce incapacitation
                        PrintToChatAll("\x04[Evil Event] \x01%N was \x04incapacitated\x01 by the toxic atmosphere!", i);
                        
                        // Show hint text for incapacitation
                        PrintHintText(i, "You've been INCAPACITATED by toxic fumes!\nCall for help!");
                    }
                } else {
                    SetEntProp(i, Prop_Send, "m_iHealth", currentHealth - damage);
                    
                    // Show hint text for damage
                    PrintHintText(i, "Toxic atmosphere damaging you while moving!\nStop moving to avoid damage!\nHealth: %d", currentHealth - damage);
                }
            }
            
            // For already incapacitated players, continue draining their health
            if (GetEntProp(i, Prop_Send, "m_isIncapacitated") == 1) {
                float incapHealth = GetEntPropFloat(i, Prop_Send, "m_healthBuffer");
                incapHealth -= float(damage) * 2.0; // Drain faster when incapped but not as extreme
                
                if (incapHealth <= 0.0) {
                    // Player dies when incap health reaches 0
                    incapHealth = 0.0;
                    ForcePlayerSuicide(i);
                    PrintToChatAll("\x04[Evil Event] \x01%N has \x04died\x01 from toxic atmosphere exposure!", i);
                }
                
                SetEntPropFloat(i, Prop_Send, "m_healthBuffer", incapHealth);
                PrintHintText(i, "Toxic fumes are killing you!\nIncap Health: %.1f", incapHealth);
            }
        } else {
            // Updated hint text for when players are safe (not moving)
            PrintHintText(i, "You're protected from toxic atmosphere by staying still");
        }
    }
    
    return Plugin_Continue;
}

// Function to check if a player is stuck and free them if needed
public Action Timer_CheckPlayerStuck(Handle timer, any client) {
    if (!IsClientInGame(client) || !IsSurvivor(client) || !IsPlayerAlive(client)) {
        g_hUnstuckTimers[client] = null;
        return Plugin_Stop;
    }
    
    // Increase attempt counter
    g_iUnstuckAttempts[client]++;
    
    // Check if the maximum number of attempts has been reached
    if (g_iUnstuckAttempts[client] >= UNSTUCK_ATTEMPTS) {
        PrintToServer("[Evil Events] Maximum unstuck attempts reached for %N, stopping unstuck timer", client);
        g_hUnstuckTimers[client] = null;
    return Plugin_Stop;
}

    // Check if player is stuck (cannot move)
    if (IsPlayerStuck(client)) {
        // Try to free the player
        if (AttemptToFreePlayer(client)) {
            PrintToServer("[Evil Events] Successfully freed %N from being stuck", client);
            g_hUnstuckTimers[client] = null;
            return Plugin_Stop;
        }
    } else {
        // Player is not stuck, stop checking
        PrintToServer("[Evil Events] %N is not stuck, stopping unstuck timer", client);
        g_hUnstuckTimers[client] = null;
    return Plugin_Stop;
}

    return Plugin_Continue;
}

// Check if a player is stuck by testing their movement capabilities
bool IsPlayerStuck(int client) {
    // Get player's current position
    float currentPos[3];
    GetClientAbsOrigin(client, currentPos);
    
    // Try to move the player very slightly
    float testPos[3];
    testPos = currentPos;
    testPos[2] += 5.0; // Try moving up very slightly
    
    // See if player can be teleported there
    bool canTeleport = CanTeleportToPosition(client, testPos);
    
    // If we can't teleport at all, player is likely stuck
    return !canTeleport;
}

bool CanTeleportToPosition(int client, float pos[3]) {
    #pragma unused client
    
    // Check if position is inside a solid
    Handle trace = TR_TraceHullFilterEx(
        pos, // Start position
        pos, // End position (same as start for a point check)
        view_as<float>({-16.0, -16.0, 0.0}), // Minimum hull size of a player
        view_as<float>({16.0, 16.0, 72.0}), // Maximum hull size of a player
        MASK_PLAYERSOLID,
        TraceFilter_OnlyWorld);
    
    bool hit = TR_DidHit(trace);
    delete trace;
    
    return !hit; // If we didn't hit anything, position is free
}

// Try to free a stuck player
bool AttemptToFreePlayer(int client) {
    float originalPos[3];
    GetClientAbsOrigin(client, originalPos);
    
    // Try a series of different positions
    float testPos[3];
    
    // First try: just move up a bit
    testPos = originalPos;
    testPos[2] += 10.0;
    if (CanTeleportToPosition(client, testPos)) {
        TeleportEntity(client, testPos, NULL_VECTOR, NULL_VECTOR);
        return true;
    }
    
    // Second try: move down a bit
    testPos = originalPos;
    testPos[2] -= 10.0;
    if (CanTeleportToPosition(client, testPos)) {
        TeleportEntity(client, testPos, NULL_VECTOR, NULL_VECTOR);
        return true;
    }
    
    // Search up and down for a free area
    for (float h = 20.0; h <= UNSTUCK_MAX_HEIGHT; h += 20.0) {
        // Try up
        testPos = originalPos;
        testPos[2] += h;
        if (CanTeleportToPosition(client, testPos)) {
            TeleportEntity(client, testPos, NULL_VECTOR, NULL_VECTOR);
            return true;
        }
        
        // Try down
        testPos = originalPos;
        testPos[2] -= h;
        if (CanTeleportToPosition(client, testPos)) {
            TeleportEntity(client, testPos, NULL_VECTOR, NULL_VECTOR);
            return true;
        }
    }
    
    // Try in a spiral pattern around original position
    for (int radius = 5; radius <= 100; radius += 15) {
        for (int angle = 0; angle < 360; angle += 45) {
            float rad = angle * 3.14159 / 180.0;
            testPos = originalPos;
            testPos[0] += radius * Cosine(rad);
            testPos[1] += radius * Sine(rad);
            
            // Try at different heights
            for (float h = -50.0; h <= 100.0; h += 25.0) {
                testPos[2] = originalPos[2] + h;
                if (CanTeleportToPosition(client, testPos)) {
                    TeleportEntity(client, testPos, NULL_VECTOR, NULL_VECTOR);
                    return true;
                }
            }
        }
    }
    
    // If all else fails, try the original stored position from the saferoom teleport
    if (CanTeleportToPosition(client, g_vOriginalPosition[client])) {
        TeleportEntity(client, g_vOriginalPosition[client], NULL_VECTOR, NULL_VECTOR);
        return true;
    }
    
    // Last resort: find a safe ground position below player
    testPos = originalPos;
    testPos[2] += 50.0; // Start above player
    float groundPos[3];
    
    if (GetValidGroundPosition(testPos, groundPos)) {
        groundPos[2] += 10.0; // Lift slightly off ground
        if (CanTeleportToPosition(client, groundPos)) {
            TeleportEntity(client, groundPos, NULL_VECTOR, NULL_VECTOR);
            return true;
        }
    }
    
    // We failed to free the player
    return false;
}