// *********************************************************************************
// PREPROCESSOR
// *********************************************************************************
#pragma semicolon 1                  // Force strict semicolon mode.

// *********************************************************************************
// INCLUDES
// *********************************************************************************
#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

// *********************************************************************************
// CONSTANTS
// *********************************************************************************
// ---- Sourcemod constants --------------------------------------------------------
#define PLUGIN_NAME         "[TF2] Buff Banner [Resupply Fix]"
#define PLUGIN_AUTHOR       "Damizean"
#define PLUGIN_VERSION      "1.0"
#define PLUGIN_CONTACT      "elgigantedeyeso@gmail.com"
#define CVAR_FLAGS          FCVAR_PLUGIN|FCVAR_NOTIFY

// *********************************************************************************
// VARIABLES
// *********************************************************************************
new Float:g_fRageMeter[MAXPLAYERS+1];

// *********************************************************************************
// PLUGIN
// *********************************************************************************
public Plugin:myinfo =
{
    name        = PLUGIN_NAME,
    author      = PLUGIN_AUTHOR,
    description = PLUGIN_NAME,
    version     = PLUGIN_VERSION,
    url         = PLUGIN_CONTACT
};

// *********************************************************************************
// METHODS
// *********************************************************************************

/*
**••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••
**    ______              
**   / ____/___  ________ 
**  / /   / __ \/ ___/ _ \
** / /___/ /_/ / /  /  __/
** \____/\____/_/   \___/
**
**••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••
*/
    
/* OnPluginStart()
**
** When the plugin is loaded.
** -------------------------------------------------------------------------- */
public OnPluginStart()
{
    // Check if the plugin is being run on the proper mod.
    decl String:strModName[32]; GetGameFolderName(strModName, sizeof(strModName));
    if (!StrEqual(strModName, "tf")) SetFailState("This plugin is only for Team Fortress 2.");
    
    // Create plugin cvars
    CreateConVar("tf_buffbanner_fixer_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_PLUGIN|FCVAR_NOTIFY);
   
    // Hook all the proper events
    HookEvent("round_start", EventRoundStart, EventHookMode_Post);
    HookEvent("player_death", EventPlayerDeath, EventHookMode_Post);
    HookEvent("post_inventory_application", EventInventoryApplication,  EventHookMode_Post);
}

/* EventRoundStart()
**
** Event fired whenever a round starts.
** -------------------------------------------------------------------------- */
public EventRoundStart(Handle:hEvent, String:strName[], bool:bDontBroadcast)
{
    for (new iClient = 1; iClient <= MaxClients; iClient++)
    {
        if (!IsValidPlayer(iClient, TFClass_Soldier)) continue;
        SetEntPropFloat(iClient, Prop_Send, "m_flRageMeter", 0.0);
    }
}

/* EventPlayerDeath()
**
** Event fired whenever the player dies.
** -------------------------------------------------------------------------- */
public EventPlayerDeath(Handle:hEvent, String:strName[], bool:bDontBroadcast)
{
    new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
    if (!IsValidPlayer(iClient, TFClass_Soldier)) return;
    SetEntPropFloat(iClient, Prop_Send, "m_flRageMeter", 0.0);
}

/* EventInventoryApplication()
**
** Event fired whenever the player spawns or a resupply locker is used.
** -------------------------------------------------------------------------- */
public EventInventoryApplication(Handle:hEvent, String:strName[], bool:bDontBroadcast)
{
    new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
    if (!IsValidPlayer(iClient, TFClass_Soldier)) return;

    g_fRageMeter[iClient] = GetEntPropFloat(iClient, Prop_Send, "m_flRageMeter");
    CreateTimer(0.0, TimerRestoreRage, iClient, TIMER_FLAG_NO_MAPCHANGE);
}

/* TimerRestoreRage()
**
** Restore the current rage meter value for the Buff Banner,
** -------------------------------------------------------------------------- */
public Action:TimerRestoreRage(Handle:hTimer, any:iClient)
{
    if (!IsValidClient(iClient)) return;
    if (TF2_GetPlayerClass(iClient) != TFClass_Soldier) return;
    
    SetEntPropFloat(iClient, Prop_Send, "m_flRageMeter", g_fRageMeter[iClient]);
}

/*
**••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••
**   ______            __    
**  /_  __/___  ____  / /____
**   / / / __ \/ __ \/ / ___/
**  / / / /_/ / /_/ / (__  ) 
** /_/  \____/\____/_/____/  
**
**••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••
*/

/* IsValidClient()
**
** Determines if the given client is valid (valid index, connected and in-game).
** -------------------------------------------------------------------------- */
bool:IsValidClient(iClient)
{
    if (iClient < 0 || iClient > MaxClients) return false;
    if (!IsClientConnected(iClient)) return false;
    return IsClientInGame(iClient);
}

/* IsValidPlayer()
**
** Determines if the given player is valid and has the valid class.
** -------------------------------------------------------------------------- */
bool:IsValidPlayer(iClient, TFClassType:tfcClass)
{
    if (!IsValidClient(iClient)) return false;
    return TF2_GetPlayerClass(iClient) == tfcClass;
}