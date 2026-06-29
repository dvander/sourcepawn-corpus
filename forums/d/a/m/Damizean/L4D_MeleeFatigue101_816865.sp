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
new bool:Melee_Hooked           = false;
new Melee_Enabled               = -1;
new Melee_FatigueVarOffset      = 0;

// *********************************************************************************
// PLUGIN
// *********************************************************************************
public Plugin:myinfo =
{
    name        = "L4D Melee Fatigue",
    author      = "Damizean",
    description = "Plugin to enable/disable melee fatigue on L4D game servers.",
    version     = "1.0.1",
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
    if (Melee_Enabled != -1) SetConVarInt(Melee_EnableCvar, Melee_Enabled);
    
    // Determine the game mode and check if it's worthy to hook the events.
    if (GetConVarInt(Melee_EnableCvar) == 0 && Melee_GameMode() == 1)
        Melee_HookEvents();
}

// ------------------------------------------------------------------------
// OnMapEnd()
// ------------------------------------------------------------------------
// Store the current value to use on next map change.
// ------------------------------------------------------------------------
public OnMapEnd() {
    // Unhook the events on map end.
    Melee_UnhookEvents();
    
    // Retrieve the enabled value for next map.
    Melee_Enabled = GetConVarInt(Melee_EnableCvar);
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
        Melee_HookEvents();
    else
        Melee_UnhookEvents();
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

// ------------------------------------------------------------------------
// Melee_HookEvents()
// ------------------------------------------------------------------------
// Pretty self explanatory.
// ------------------------------------------------------------------------
public Melee_HookEvents()
{
    // If there's no need to rehook, exit.
    if (Melee_Hooked) return;
    
    // Hook events.
    HookEvent("player_shoved", Melee_MeleeHit, EventHookMode_Post);
    HookEvent("entity_shoved", Melee_MeleeHit, EventHookMode_Post);    
    Melee_Hooked = true;
}

// ------------------------------------------------------------------------
// Melee_UnhookEvents()
// ------------------------------------------------------------------------
// Pretty self explanatory.
// ------------------------------------------------------------------------
public Melee_UnhookEvents()
{
    // If there's no need to unhook, exit.
    if (!Melee_Hooked) return;
    
    // Unhook events.
    UnhookEvent("player_shoved", Melee_MeleeHit, EventHookMode_Post);
    UnhookEvent("entity_shoved", Melee_MeleeHit, EventHookMode_Post);    
    Melee_Hooked = false;    
}

// ------------------------------------------------------------------------
// Melee_MeleeHit()
// ------------------------------------------------------------------------
// This method is the one that controls the reset of the melee fatigue. Since
// I haven't found a proper way to detect whenever the player has melee'd, we
// can only force to reset the fatigue value when there has been a hit with
// another player, or with the world.
// ------------------------------------------------------------------------
public Action:Melee_MeleeHit(Handle:hEvent, const String:strName[], bool:bDonBroadcast)
{
    // Set penalty value to 0.
    SetEntData(GetClientOfUserId(GetEventInt(hEvent, "attacker")), Melee_FatigueVarOffset, 0, 4);
    return Plugin_Continue;
}