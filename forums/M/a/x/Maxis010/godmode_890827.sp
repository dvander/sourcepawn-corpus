// Includes
#pragma semicolon 1
#include <sourcemod>
// Global handle
new Handle:g_enabled = INVALID_HANDLE;
// Called when plugin is loaded
public OnPluginStart() {
    // Create a cvar - defaults to disabled
    g_enabled = CreateConVar("sm_godmode", "0", "Enable god mode.", FCVAR_PLUGIN|FCVAR_NOTIFY);
    // Hook player_spawn
    HookEvent("player_spawn", Event_player_spawn);
}
// Called when the event fires
public Action:Event_player_spawn(Handle:event, const String:name[], bool:dontBroadcast) {
    // Is sm_godmode set to 1?
    if(GetConVarBool(g_enabled)) {
        CreateTimer(5.00, ApplyGod, GetClientOfUserId(GetEventInt(event, "userid")));
        CreateTimer(0.01, RemoveGod, GetClientOfUserId(GetEventInt(event, "userid")));
    }
}
// Called 0.01s after the event fires
public Action:ApplyGod(Handle:timer, any:client) {
    // Can the plugin target them?
    if(IsClientInGame(client) && IsPlayerAlive(client)) {
        // Set godmode on
	SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);  
    }
}  
// Called 5.00s after the event fires
public Action:RemoveGod(Handle:timer, any:client) {
    // Can the plugin target them?
    if(IsClientInGame(client) && IsPlayerAlive(client)) {
        // Set godmode off
	SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);  
    }
}  