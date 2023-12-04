#include <sourcemod>
#include <tf2>
#include <tf2_stocks>

public Plugin myinfo =
{
    name = "Team Class Restriction",
    author = "Cyriv",
    description = "A plugin that restricts the blue team to demoman and the red team to soldier",
    version = "1.0",
};

public void OnPluginStart();
{
    // Register a command that can be used by admins to toggle the plugin on or off
    RegConsoleCmd("sm_classrestrict", Command_ClassRestrict, "Toggle class restriction plugin");
    
    // Create a global variable to store the plugin state
    new Handle g_hClassRestrict = CreateConVar("sm_classrestrict_enabled", "1", "Enable or disable class restriction plugin", _, true, 0.0, true, 1.0);
    
    // Hook the event that fires when a player spawns
    HookEvent("player_spawn", Event_PlayerSpawn);
}

public Action Command_ClassRestrict(int client, int args);
{
    // Check if the client is a valid admin
    if (!IsClientAdmin(client))
    {
        // Print a message to the client
        PrintToChat(client, "You are not authorized to use this command.");
        return Plugin_Handled;
    }
    
    // Get the current value of the plugin state
    new bool enabled = GetConVarBool(g_hClassRestrict);
    
    // Toggle the value
    enabled = !enabled;
    
    // Set the new value
    SetConVarBool(g_hClassRestrict, enabled);
    
    // Print a message to all players
    PrintToChatAll("Class restriction plugin is now %s.", enabled ? "enabled" : "disabled");
    
    return Plugin_Handled;
}

public Action Event_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
    // Get the player index from the event
    Handle g_hClassRestrict = CreateConVar("sm_classrestrict_enabled", "1", "Enable or disable class restriction plugin", _, true, 0.0, true, 1.0);
    
    // Check if the player is valid and connected
    if (!IsClientInGame(client))
        return Plugin_Continue;
    
    // Check if the plugin is enabled
    if (!GetConVarBool(g_hClassRestrict))
        return Plugin_Continue;
    
    // Get the player's team and class
    TFTeam team = GetClientTeam(client);
    TFClassType class = TF2_GetPlayerClass(client);
    
    // Check if the player's team and class are valid
    if (team == TFTeam_Unassigned || team == TFTeam_Spectator || class == TFClass_Unknown)
        return Plugin_Continue;
    
    // Check if the player's class matches the team restriction
    if ((team == TFTeam_Blue && class != TFClass_DemoMan) || (team == TFTeam_Red && class != TFClass_Soldier))
    {
        // Force the player to change class
        TF2_ForcePlayerClass(client, team == TFTeam_Blue ? TFClass_DemoMan : TFClass_Soldier);
        
        // Print a message to the player
        PrintToChat(client, "You can only play as %s on this team.", team == TFTeam_Blue ? "demoman" : "soldier");
        
        // Return Plugin_Handled to prevent other plugins from interfering
        return Plugin_Handled;
    }
    
    // Return Plugin_Continue to allow other plugins to process the event
    return Plugin_Continue;
}
