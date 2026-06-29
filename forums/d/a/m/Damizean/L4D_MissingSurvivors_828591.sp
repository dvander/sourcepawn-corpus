/* ========================================================
 * L4D Spawn Missing Survivors
 * ========================================================
 *
 * Created by Damizean
 * --------------------------------------------------------
 */

// *********************************************************************************
// PREPROCESSOR
// *********************************************************************************
#pragma semicolon 1                 // Force strict semicolon mode.

// *********************************************************************************
// INCLUDES
// *********************************************************************************
#include <sourcemod>
#include <sdktools>

// *********************************************************************************
// CONSTANTS
// *********************************************************************************
#define CONSISTENCY_CHECK            30.0

// *********************************************************************************
// VARS
// *********************************************************************************
new Handle:SpawnTimer    = INVALID_HANDLE;
new Handle:SurvivorLimit = INVALID_HANDLE;

// *********************************************************************************
// PLUGIN
// *********************************************************************************
public Plugin:myinfo =
{
    name        = "L4D Missing Survivors",
    author      = "Damizean",
    description = "Plugin to use with L4D Downtown to spawn missing survivors.",
    version     = "1.0.0",
    url         = "elgigantedeyeso@gmail.com"
};


// *********************************************************************************
// METHODS
// *********************************************************************************

// =====[ GAME EVENTS ]===================================================

// ------------------------------------------------------------------------
// OnPluginStart()
// ------------------------------------------------------------------------
public OnPluginStart()
{
    // Hook first spawn
    HookEvent("player_first_spawn", Event_PlayerFirstSpawn, EventHookMode_PostNoCopy);
    
    // Find survivor limit cvar
    SurvivorLimit = FindConVar("survivor_limit");
}

// ------------------------------------------------------------------------
// OnMapEnd()
// ------------------------------------------------------------------------
public OnMapEnd()
{
    // Destroy timer if necessary.
    if (SpawnTimer != INVALID_HANDLE)
    {
        KillTimer(SpawnTimer);
        SpawnTimer = INVALID_HANDLE;
    }
}

// ------------------------------------------------------------------------
// Event_PlayerFirstSpawn()
// ------------------------------------------------------------------------
public Event_PlayerFirstSpawn(Handle:hEvent, const String:strName[], bool:bDontBroadcast)
{    
    if (SpawnTimer != INVALID_HANDLE) return;
    SpawnTimer = CreateTimer(CONSISTENCY_CHECK, SpawnTick, _, TIMER_REPEAT);
}

// ------------------------------------------------------------------------
// SpawnTick()
// ------------------------------------------------------------------------
public Action:SpawnTick(Handle:hTimer, any:Junk)
{    
    // Determine the number of survivors and fill the empty
    // slots.
    new NumSurvivors = 0;
    new MaxSurvivors = GetConVarInt(SurvivorLimit);
    
    for (new i=1; i<=MaxClients; i++)
    {
        // Check if the client is real and is on survivors team.
        if (!IsClientConnected(i)) continue;
        if (!IsClientInGame(i))    continue;
        if (GetClientTeam(i) != 2) continue;

        // Next
        NumSurvivors++;
    }
    
    // It's impossible to have less than 4 survivors. Set the lower
    // limit to 4 in order to prevent errors with the respawns. Try
	// again later.
    if (NumSurvivors < 4) return Plugin_Continue;
    
    // Create missing bots
    for (;NumSurvivors < MaxSurvivors; NumSurvivors++)
        SpawnFakeClient();
	
	// Once the missing bots are made, dispose of the timer
    SpawnTimer = INVALID_HANDLE;
    return Plugin_Stop;
}

// ------------------------------------------------------------------------
// SpawnFakeClient()
// ------------------------------------------------------------------------
SpawnFakeClient()
{
    // Spawn bot survivor.
    new Bot = CreateFakeClient("SurvivorBot");
    if (Bot == 0) return;
    
    ChangeClientTeam(Bot, 2);
    DispatchKeyValue(Bot, "classname", "SurvivorBot");
    CreateTimer(2.5, KickFakeClient, Bot);
}

// ------------------------------------------------------------------------
// KickFakeClient()
// ------------------------------------------------------------------------
public Action:KickFakeClient(Handle:hTimer, any:Client)
{
    KickClient(Client, "Free slot.");
    return Plugin_Handled;
}