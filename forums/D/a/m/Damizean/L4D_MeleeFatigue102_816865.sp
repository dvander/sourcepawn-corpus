/* ========================================================
 * L4D Melee Fatigue
 * ========================================================
 *
 * Created by Damizean
 * --------------------------------------------------------
 *
 * This plugin forces the game to reset the melee fatigue 
 * penalty whenever a melee hit lands upon another player and
 * or an entity, effectively disabling melee fatigue.
 */

// *********************************************************************************
// PREPROCESSOR
// *********************************************************************************
#pragma semicolon 1            // Force strict semicolon mode.

// *********************************************************************************
// INCLUDES
// *********************************************************************************
#include <sourcemod>
#include <sdktools>

// *********************************************************************************
// CONSTANTS
// *********************************************************************************

// *********************************************************************************
// VARS
// *********************************************************************************
new Handle:Melee_EnableCvar     = INVALID_HANDLE;
new Handle:Melee_GameModeCvar   = INVALID_HANDLE;
new bool:Melee_Enabled          = false;
new Melee_PreviousState         = -1;
new Melee_FatigueVarOffset      = 0;
new Melee_Iterator                = 0;

// *********************************************************************************
// PLUGIN
// *********************************************************************************
public Plugin:myinfo =
{
    name        = "L4D Melee Fatigue",
    author      = "Damizean",
    description = "Plugin to enable/disable melee fatigue on L4D game servers.",
    version     = "1.0.2",
    url         = "elgigantedeyeso@gmail.com"
};

// *********************************************************************************
// METHODS
// *********************************************************************************

// =====[ GAME EVENTS ]====================================================

// ------------------------------------------------------------------------
// OnPluginStart()
// ------------------------------------------------------------------------
// Upon plugin start, create the proper con-vars to be able to control
// the melee fatigue of the game.
// ------------------------------------------------------------------------
public OnPluginStart()
{
    decl String:strModName[50]; GetGameFolderName(strModName, sizeof(strModName));
    if(!StrEqual(strModName, "left4dead", false)) SetFailState("This plugin is Left 4 Dead only. It won't work on other games.");
    
    // Crate the melee controller cvar.
    Melee_EnableCvar  = CreateConVar("sm_l4d_meleefatigue", "0", "Enables/Disables Melee Fatigue (0 - Disabled / 1 - Enabled)", FCVAR_PLUGIN);

    // Find the game mode cvar.
    Melee_GameModeCvar = FindConVar("mp_gamemode");
    
    // Hook the cvars.
    HookConVarChange(Melee_EnableCvar,   Melee_ManageCvars);
    HookConVarChange(Melee_GameModeCvar, Melee_ManageCvars);
    
    // Determine the melee fatigue variable offset
    Melee_FatigueVarOffset = FindSendPropInfo("CTerrorPlayer", "m_iShovePenalty");
    
    // Autoexec config
    AutoExecConfig(true, "L4D_MeleeFatigue");
}

// ------------------------------------------------------------------------
// OnConfigsExecuted()
// ------------------------------------------------------------------------
// Whenever the configuration file has been executed, re-hook the events.
// ------------------------------------------------------------------------
public OnConfigsExecuted()
{
    // If the configuration changed to something else than the default
    if (Melee_PreviousState != -1) SetConVarInt(Melee_EnableCvar, Melee_PreviousState);
    
    // Determine the game mode and check if it's worthy to activate.
    if (GetConVarInt(Melee_EnableCvar) == 0 && Melee_GameMode() == 1)
        Melee_Enabled = true;
}

// ------------------------------------------------------------------------
// OnMapEnd()
// ------------------------------------------------------------------------
// Store the current value to use on next map change.
// ------------------------------------------------------------------------
public OnMapEnd() {
    // Disable melee on map end.
    Melee_Enabled = false;
    
    // Retrieve the enabled value for next map.
    Melee_PreviousState = GetConVarInt(Melee_EnableCvar);
}

// ------------------------------------------------------------------------
// OnGameFrame()
// ------------------------------------------------------------------------
// Not exactly the best idea, but seeing no melee event is fired while missing
// this seems to be the last resort.
// ------------------------------------------------------------------------
public OnGameFrame()
{
    if (Melee_Enabled == false) return;
    
    // Iterate through all the clients
    for (Melee_Iterator=1; Melee_Iterator<=MaxClients; Melee_Iterator++) {
        // If it's not connected, not on the survivor team or not alive, skip.
        if (!IsClientInGame(Melee_Iterator))    continue;
        if (!IsPlayerAlive(Melee_Iterator))     continue;
        if (GetClientTeam(Melee_Iterator) != 2) continue;        
        
        // Once alive, if the player is using the melee, reset
        // the fatigue.
        if (GetClientButtons(Melee_Iterator) & IN_ATTACK2)
            SetEntData(Melee_Iterator, Melee_FatigueVarOffset, 0, 4);
    }
}

// ------------------------------------------------------------------------
// Melee_ManageCvars()
// ------------------------------------------------------------------------
// This method manages the cvars and hooks/unhooks the events as they're
// needed by the game mode.
// ------------------------------------------------------------------------
public Melee_ManageCvars(Handle:hVariable, const String:strOldValue[], const String:strNewValue[])
{
    // Determine if it's worthy to enable on this game mode.
    if (GetConVarInt(Melee_EnableCvar) == 0 && Melee_GameMode() == 1)
        Melee_Enabled = true;
    else
        Melee_Enabled = false;
}

// ------------------------------------------------------------------------
// Melee_GameMode()
// ------------------------------------------------------------------------
// This method determines the current game mode, and whenever the melee
// fatigue control really needs to be hooked.
// ------------------------------------------------------------------------
public Melee_GameMode() {
    // Retrieve game mode
    new String:strGameMode[16]; GetConVarString(Melee_GameModeCvar, strGameMode, sizeof(strGameMode));
    
    // Determine if it's worthy to hook the melee events.
    if (StrEqual(strGameMode, "coop")) return 0;
    return 1;
}