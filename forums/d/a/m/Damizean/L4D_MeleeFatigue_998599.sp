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
// VARIABLES
// *********************************************************************************
new Handle:g_hCvarEnabled    = INVALID_HANDLE;
new bool:g_bEnabled          = false;
new g_iPreviousState         = -1;

// *********************************************************************************
// PLUGIN
// *********************************************************************************
public Plugin:myinfo =
{
    name        = "[L4D/L4D2] Melee Fatigue",
    author      = "Damizean",
    description = "Plugin to enable/disable melee fatigue on L4D/L4D2 game servers.",
    version     = "1.0.0",
    url         = "elgigantedeyeso@gmail.com"
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
    decl String:strModName[50]; GetGameFolderName(strModName, sizeof(strModName));
    if (!StrEqual(strModName, "left4dead", false) && !StrEqual(strModName, "left4dead2", false))
    {
        SetFailState("This plugin is only for L4D/L4D2.");
    }
    
    // Crate the melee controller cvar and find the game mode cvar.
    g_hCvarEnabled = CreateConVar("l4d_meleefatigue", "0", "Enables/disables Melee Fatigue (0 - Disabled / 1 - Enabled)", FCVAR_PLUGIN);
    
    // Hook the cvars.
    HookConVarChange(g_hCvarEnabled, ManageCvars);
 
    // Autoexec config
    AutoExecConfig(true, "L4D_MeleeFatigue");
}

/* OnPlayerRunCmd()
**
** Whenever a command is sent from a player.
** -------------------------------------------------------------------------- */
public Action:OnPlayerRunCmd(iClient, &iButtons, &iImpulse, Float:fVelocity[3], Float:fAngles[3], &iWeapon)
{
    if (g_bEnabled == true)
    {
        if (!IsValidSurvivor(iClient)) return Plugin_Continue;
        if (iButtons & IN_ATTACK2) SetEntProp(iClient, Prop_Send, "m_iShovePenalty", 0, 1);
    }
    return Plugin_Continue;
}

/*
**••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••
**     __  ___                                                  __ 
**    /  |/  /___ _____  ____ _____ ____  ____ ___  ___  ____  / /_
**   / /|_/ / __ `/ __ \/ __ `/ __ `/ _ \/ __ `__ \/ _ \/ __ \/ __/
**  / /  / / /_/ / / / / /_/ / /_/ /  __/ / / / / /  __/ / / / /_  
** /_/  /_/\__,_/_/ /_/\__,_/\__, /\___/_/ /_/ /_/\___/_/ /_/\__/  
**                          /____/                                 
**••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••
*/

/* OnConfigsExecuted()
**
** Whenever the configs are executed, retrieve the status of the melee fatigue.
** -------------------------------------------------------------------------- */
public OnConfigsExecuted()
{
    // If the configuration changed to something else than the default
    if (g_iPreviousState != -1) SetConVarInt(g_hCvarEnabled, g_iPreviousState);
    
    // Determine the game mode and check if it's worthy to activate.
    if (GetConVarInt(g_hCvarEnabled) == 0)
        g_bEnabled = true;
}

/* OnMapEnd()
**
** Whenever the map ends, disable the plugin and store current status.
** -------------------------------------------------------------------------- */
public OnMapEnd()
{
    // Disable melee on map end and retrieve the enabled value for next map.
    g_bEnabled = false;
    g_iPreviousState = GetConVarInt(g_hCvarEnabled);
}

/* ManageCvars()
**
** If a cvar value changes, change the status of the plugin.
** -------------------------------------------------------------------------- */
public ManageCvars(Handle:hVariable, const String:strOldValue[], const String:strNewValue[])
{
    g_bEnabled = !GetConVarBool(g_hCvarEnabled);
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

/* IsValidSurvivor()
**
** A tool routine to check if the given client is a valid survivor.
** -------------------------------------------------------------------------- */
bool:IsValidSurvivor(iClient)
{
    if (!IsClientConnected(iClient)) return false;
    if (!IsClientInGame(iClient))    return false;
    if (!IsPlayerAlive(iClient))     return false;
    if (GetClientTeam(iClient) != 2) return false;

    return true;
}