#include <sourcemod>
#include <sdktools>
#include <tf2>

public Plugin:myinfo = {
    name = "Capture Team Buff",
    author = "YourName",
    description = "Gives opposite team crits and uber on intel capture with delay",
    version = "1.20"
};

// Configuration settings
#define BUFF_DURATION 20.0   // Duration of crits and uber charge in seconds
#define DELAY_TIME 5.0       // Delay before activating effects in seconds

public void OnPluginStart() {
    // Hook the flag capture event
    HookEvent("ctf_flag_captured", OnFlagCapture, EventHookMode_Post);
    PrintToConsoleAll("Capture Team Buff plugin loaded successfully.");
}

// Flag capture event handler
public Action OnFlagCapture(Event event, const char[] name, bool dontBroadcast) {
    // Get the team that captured the flag
    int capturingTeam = event.GetInt("team_caps"); 
    PrintToConsoleAll("Flag captured by Team %d", capturingTeam);

    // Determine the opposite team
    int oppositeTeam = (capturingTeam == 2) ? 3 : 2; 
    PrintToConsoleAll("Giving buffs to Team %d.", oppositeTeam);
    
    // Set a timer with a delay
    CreateTimer(DELAY_TIME, ApplyEffectsToOppositeTeam, oppositeTeam);
}

// Timer for applying effects
public Action ApplyEffectsToOppositeTeam(Handle timer, any oppositeTeam) {
    // Apply effects to the opposite team
    for (int client = 1; client <= MaxClients; client++) {
        if (IsClientInGame(client) && GetClientTeam(client) == oppositeTeam) {
            // Add crit boost (usually 11) and uber charge (usually 5)
            TF2_AddCondition(client, 11, BUFF_DURATION); // Crits
            TF2_AddCondition(client, 5, BUFF_DURATION);  // Uber charge
            PrintToConsole(client, "You received crits and uber from your opponents!");
        }
    }
    return Plugin_Stop;
}
