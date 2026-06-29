#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <keyvalues>

#define PLUGIN_VERSION "1.0"

// --- Plugin Information ---
public Plugin myinfo = {
    name = "MvM Player-Based Invader Scaler",
    author = "gloom",
    description = "Dynamically changes tf_mvm_max_invaders based on player count.",
    version = PLUGIN_VERSION,
    url = "https://steamcommunity.com/id/OneDeadGloom/"
};

// --- Global Handles & Variables ---
ConVar g_hCvarEnabled;
ConVar g_hCvarMaxInvaders;
KeyValues g_hKvConfig;

// ====================================================================================================
//                                          PLUGIN EVENTS
// ====================================================================================================

public void OnPluginStart() {
    // --- Create Plugin ConVars ---
    g_hCvarEnabled = CreateConVar("mvm_invader_scaler_enabled", "1", "Enable/disable the MvM Invader Scaler plugin.", FCVAR_NOTIFY, true, 0.0, true, 1.0);

    // --- Register Admin Commands ---
    RegAdminCmd("sm_reload_invader_config", Command_ReloadConfig, ADMFLAG_CONFIG, "Reloads the configuration file for the MvM Invader Scaler.");

    // --- Find the Target ConVar ---
    g_hCvarMaxInvaders = FindConVar("tf_mvm_max_invaders");
    if (g_hCvarMaxInvaders == null) {
        SetFailState("Could not find ConVar 'tf_mvm_max_invaders'. This plugin is likely for the wrong game or the ConVar is missing.");
        return;
    }

    // --- Hook Game Events ---
    // These hooks trigger the update when a player joins or leaves.
    HookEvent("player_activate", Event_PlayerActivate, EventHookMode_Post);
    HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Post);

    // --- Load Configuration ---
    LoadConfig();

    // --- Initial Update ---
    // Use a short timer to ensure the game state is settled on map start.
    CreateTimer(2.0, Timer_DelayedInitialUpdate);
}

/**
 * @brief Called when the plugin is unloaded.
 */
public void OnPluginEnd() {
    // Close the handle to the KeyValues config to prevent memory leaks.
    if (g_hKvConfig != null) {
        g_hKvConfig.Close();
    }
}

/**
 * @brief Called after a map starts.
 */
public void OnMapStart() {
    // Perform an update at the start of every map.
    CreateTimer(2.0, Timer_DelayedInitialUpdate);
}


// ====================================================================================================
//                                          EVENT HANDLERS
// ====================================================================================================

/**
 * @brief Called after a player has fully joined the server.
 */
public void Event_PlayerActivate(Event event, const char[] name, bool dontBroadcast) {
    UpdateInvaderCount();
}

/**
 * @brief Called after a player disconnects from the server.
 */
public void Event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast) {
    // We need a short delay because the player count isn't updated instantly.
    CreateTimer(0.1, Timer_UpdateInvaderCount);
}

/**
 * @brief A timer callback that simply calls the main update function.
 * Used to add delays where needed.
 */
public Action Timer_UpdateInvaderCount(Handle timer) {
    UpdateInvaderCount();
    return Plugin_Stop;
}

/**
 * @brief A timer callback for the initial update on map start/plugin load.
 */
public Action Timer_DelayedInitialUpdate(Handle timer) {
    LogMessage("[MvM Invader Scaler] Performing initial check...");
    UpdateInvaderCount();
    return Plugin_Stop;
}

// ====================================================================================================
//                                          COMMAND HANDLERS
// ====================================================================================================

/**
 * @brief Handles the sm_reload_invader_config command.
 */
public Action Command_ReloadConfig(int client, int args) {
    LoadConfig();
    UpdateInvaderCount();
    ReplyToCommand(client, "[SM] MvM Invader Scaler configuration reloaded.");
    return Plugin_Handled;
}

// ====================================================================================================
//                                          CORE LOGIC
// ====================================================================================================

/**
 * @brief Loads the configuration from the KeyValues file.
 */
void LoadConfig() {
    // If a config is already loaded, close its handle first.
    if (g_hKvConfig != null) {
        g_hKvConfig.Close();
        g_hKvConfig = null;
    }

    char sPath[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, sPath, sizeof(sPath), "configs/mvm_invader_scaler.cfg");

    // Create a new KeyValues object and load the file.
    g_hKvConfig = new KeyValues("MvMInvaderScaler");

    if (!g_hKvConfig.ImportFromFile(sPath)) {
        // If the file doesn't exist or is invalid, log an error and clean up.
        SetFailState("Could not read config file: %s. Please ensure it exists and is valid.", sPath);
        g_hKvConfig.Close();
        g_hKvConfig = null;
        return;
    }

    LogMessage("[MvM Invader Scaler] Configuration file loaded successfully from %s.", sPath);
}

/**
 * @brief Main function to count players and update the convar.
 */
void UpdateInvaderCount() {
    // Abort if the plugin is disabled via its cvar.
    if (!g_hCvarEnabled.BoolValue) {
        return;
    }

    // Abort if the config failed to load.
    if (g_hKvConfig == null) {
        return;
    }
    
    // Count the number of active, human players.
    int playerCount = GetHumanPlayerCount();
    char sPlayerCount[4];
    IntToString(playerCount, sPlayerCount, sizeof(sPlayerCount));

    // Look for the player count in the config file.
    if (g_hKvConfig.JumpToKey(sPlayerCount)) {
        // Get the desired invader count from the config.
        int newInvaderCount = g_hKvConfig.GetNum(NULL_STRING);
        
        // Only update the convar if the value is different.
        if (newInvaderCount != g_hCvarMaxInvaders.IntValue) {
            g_hCvarMaxInvaders.SetInt(newInvaderCount, true);
            LogMessage("[MvM Invader Scaler] Player count is %d. Set tf_mvm_max_invaders to %d.", playerCount, newInvaderCount);
        }

        // Reset the KV handle to the root for the next lookup.
        g_hKvConfig.Rewind();
    } else {
        // Log a message if the current player count isn't defined in the config.
        LogMessage("[MvM Invader Scaler] No invader count defined for %d players. ConVar unchanged.", playerCount);
    }
}

/**
 * @brief Counts the number of connected human players who are not spectators.
 *
 * @return The number of active human players.
 */
int GetHumanPlayerCount() {
    int count = 0;
    for (int i = 1; i <= MaxClients; i++) {
        // Check if the client slot is in use, the player is fully in-game, and is not a bot.
        if (IsClientInGame(i) && !IsFakeClient(i)) {
            // Further check if they are on a valid team (not spectator).
            if (GetClientTeam(i) > 1) { // 0=Unassigned, 1=Spectator, 2=Red, 3=Blu
                count++;
            }
        }
    }
    return count;
}