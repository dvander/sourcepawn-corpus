/* ******************************************************************************** *
 *                       [L4D & L4D2] Plugin Template                               *
 * -------------------------------------------------------------------------------- *
 *  Author: AuthorName                                                              *
 *  Description: Basic plugin features for L4D & L4D2                               *
 *  Version: 1.0.0                                                                  *
 *  Link: https://github.com/Earendil-89/l4d_template                               *
 * -------------------------------------------------------------------------------- *
 *                                                                                  *
 *  CopyRight (C) 2024 Eduardo "Eärendil" Chueca                                    *
 * -------------------------------------------------------------------------------- *
 *  This program is free software; you can redistribute it and/or modify it under   *
 *  the terms of the GNU General Public License, version 3.0, as published by the   *
 *  Free Software Foundation.                                                       *
 *                                                                                  *
 *  This program is distributed in the hope that it will be useful, but WITHOUT     *
 *  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS   *
 *  FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more          *
 *  details.                                                                        *
 *                                                                                  *
 *  You should have received a copy of the GNU General Public License along with    *
 *  this program. If not, see <http://www.gnu.org/licenses/>.                       *
 * -------------------------------------------------------------------------------- *
 *  - This file is used as a template to start L4D/L4D2 plugins from scratch.       *
 *  - Checks the game running (L4D/L4D2) and throws an error otherwise.             *
 *  - It also has basic ConVars to enable/disable plugin and control                *
 *    gamemode activation.                                                          *
 *  - This template was developed with the help of Silvers,                         *
 *    visit his GitHub here: https://github.com/SilvDev                             *
 * ******************************************************************************** */

#include <sdktools>
#include <sourcemod>

#pragma newdecls required
#pragma semicolon 1

#tryinclude <left4dhooks>           // Very useful plugin for L4D/L4D that its commonly used

// Constants section
#define PLUGIN_VERSION      "1.0.0"         // Used on plugin and ConVar registration
#define CVAR_FLAGS          FCVAR_NOTIFY    // Register common ConVar flags for the plugin
#define TRUE_ROUND_START    1               // Allow plugin to get the true round start

// Variables section
bool g_bPluginOn;               // This variable stores the current state of plugin: true -> ON, false -> OFF

GameMode g_gmCurrent;           // Stores the current server gamemode, you can use it anytime to check the current gamemode if needed

// Convars
ConVar g_cvAllow;               // ConVar to globally enable/disable plugin
ConVar g_cvGameModesOn;         // ConVar to enable plugin on gamemode
ConVar g_cvGameModesOff;        // ConVar to disable plugin on gamemode
ConVar g_cvGameModesTog;        // ConVar to toggle plugin on gamemode
ConVar g_cvGameMode;            // Store server gamemode ConVar

// Enumerators, Methodmaps...

/**
 * Instead of storing gamemode as integer, using this enum will make easier
 * for developers to check the gamemode by comparing enum values
 * there is not a convention of the true value of those, I decided to give them
 * the same integer value as Silvers asings in their ConVars to prevent confusion
 */
enum GameMode
{
    GameMode_Null = 0,          // No gamemode
    GameMode_Coop = 1,
    GameMode_Survival = 1 << 1,
    GameMode_Versus = 1 << 2,
    GameMode_Scavenge = 1 << 3
};

/* ******************************************************************************** *
 *                              Plugin Info Register                                *
 * ******************************************************************************** */

public Plugin myinfo =
{
    name = "[L4D & L4D2] Plugin Template",
    author = "AuthorName",
    description = "Basic plugin features for L4D & L4D2",
    version = PLUGIN_VERSION,
    url = ""
};

/* ******************************************************************************** *
 *                               SourceMod Forwards                                 *
 * ******************************************************************************** */

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    EngineVersion ev = GetEngineVersion();

    if( ev == Engine_Left4Dead )
    {
        // Actions if engine is L4D
        return APLRes_Success;
    }
    if( ev == Engine_Left4Dead2 )
    {
        // Actions if engine is L4D2
        return APLRes_Success;
    }
    strcopy(error, err_max, "This plugin only supports Left 4 Dead Series.");
    return APLRes_SilentFailure;
}

public void OnPluginStart()
{
    // Register plugin version as ConVar
    CreateConVar("l4d_yourpluginname_version", "", "Plugin name Version", FCVAR_NOTIFY | FCVAR_DONTRECORD);

    // Register plugin ConVars
    g_cvAllow =         CreateConVar("l4d_yourpluginname_enable",       "1",    "0 = Plugin Off. 1 = Plugin On.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_cvGameModesOn =   CreateConVar("l4d_yourpluginname_modes_on",     "",     "Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS);
    g_cvGameModesOff =  CreateConVar("l4d_yourpluginname_modes_off",    "",     "Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS );
    g_cvGameModesTog =  CreateConVar("l4d_yourpluginname_modes_tog",    "0",    "Turn on the plugin in these game modes. 0 = All, 1 = Coop, 2 = Survival, 4 = Versus, 8 = Scavenge. Add numbers together.", CVAR_FLAGS );

    g_cvGameMode = FindConVar("mp_gamemode"); // Store gamemode ConVar to get the current GameMode

    // Hook ConVar changes
    g_cvAllow.AddChangeHook(CVarChange_Allow);
    g_cvGameModesOn.AddChangeHook(CVarChange_Allow);
    g_cvGameModesOff.AddChangeHook(CVarChange_Allow);
    g_cvGameModesTog.AddChangeHook(CVarChange_Allow);

    #if !defined _l4dh_included
    // Ignore with L4DH since it catches gamemode change by itws own way
    g_cvGameMode.AddChangeHook(CVarChange_Allow);
    #endif
}

public void OnConfigsExecuted()
{
    // Check plugin status and enable/disable it
    PluginSwitch();
}

/* ******************************************************************************** *
 *                               ConVar Change Hooks                                *
 * ******************************************************************************** */

void CVarChange_Allow(ConVar convar, const char[] oldValue, const char[] newValue)
{
    PluginSwitch();
}

/**
 * @brief Called to check status of ConVars and gamemode to decide to enable/disable plugin
 * A good practice is to Hook events when plugin is enabled and unhook them when disabled
 * @noreturn
 */
void PluginSwitch()
{
    bool bAllow = g_cvAllow.BoolValue;
    bool bAllowMode = IsGamemodeAllowed();

    if( !g_bPluginOn && bAllow && bAllowMode )
    {
        g_bPluginOn = true;
        // Plugin on actions
    }

    if( g_bPluginOn && (!bAllow || !bAllowMode) ) {
        g_bPluginOn = false;
        // Plugin off actions
    }
}

/**
 * @brief Checks if the gamemode allows the plugin to be loaded.
 * @return true if gamemode is allowed, false otherwise.
 */
bool IsGamemodeAllowed()
{
    if( g_cvGameMode == null )
    {
        return false;
    }

    int iCvarModesTog = g_cvGameModesTog.IntValue;
    if( iCvarModesTog != 0 )
    {
#if defined _l4dh_included
        // If L4DHooks included use L4D Native to get the gamemode, which is faster
        int iCurrentMode = L4D_GetGameModeType();
        switch( iCurrentMode )
        {
            case 0:       // Failed to get gamemode
            {
                g_gmCurrent = GameMode_Null;
                return false;
            }
            case 1: g_gmCurrent = GameMode_Coop;
            // Left 4 DHooks reverses Versus & survival values
            case 2: g_gmCurrent = GameMode_Versus;
            case 4: g_gmCurrent = GameMode_Survival;
            case 8: g_gmCurrent = GameMode_Scavenge;
        }

        if( !(iCvarModesTog & view_as<int>(g_gmCurrent)) )
            return false;
#else
        // If Left 4 DHooks is not present create info_gamemode to get the gamemode
        g_gmCurrent = GameMode_Null;
        int entity = CreateEntityByName("info_gamemode");
        if( !IsValidEntity(entity) ) 
            return false;

        DispatchSpawn(entity);
        HookSingleEntityOutput(entity, "OnCoop", OnGamemode, true);
        HookSingleEntityOutput(entity, "OnSurvival", OnGamemode, true);
        HookSingleEntityOutput(entity, "OnVersus", OnGamemode, true);
        HookSingleEntityOutput(entity, "OnScavenge", OnGamemode, true);
        ActivateEntity(entity);
        AcceptEntityInput(entity, "PostSpawnActivate");
        if( IsValidEntity(entity) ) // Because sometimes "PostSpawnActivate" seems to kill the ent.
            RemoveEdict(entity); // Because multiple plugins creating at once, avoid too many duplicate ents in the same frame

        if( g_gmCurrent == GameMode_Null )
            return false;

        if( !(iCvarModesTog & view_as<int>(g_gmCurrent)) )
            return false;
#endif
    }

    char sGameModes[64], sGameMode[64];
    g_cvGameMode.GetString(sGameMode, sizeof(sGameMode));
    Format(sGameMode, sizeof(sGameMode), ",%s,", sGameMode);

    g_cvGameModesOn.GetString(sGameModes, sizeof(sGameModes));
    if( sGameModes[0] )
	{
        Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
        if( StrContains(sGameModes, sGameMode, false) == -1 )
            return false;
    }

    g_cvGameModesOff.GetString(sGameModes, sizeof(sGameModes));
    if( sGameModes[0] )
	{
        Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
        if( StrContains(sGameModes, sGameMode, false) != -1 )
            return false;
    }

    return true;
}

#if !defined _l4dh_included
void OnGamemode(const char[] output, int caller, int activator, float delay)
{
    if( strcmp(output, "OnCoop") == 0 )
        g_gmCurrent = GameMode_Coop;
    else if( strcmp(output, "OnSurvival") == 0 )
        g_gmCurrent = GameMode_Survival;
    else if( strcmp(output, "OnVersus") == 0 )
        g_gmCurrent = GameMode_Versus;
    else if( strcmp(output, "OnScavenge") == 0 )
        g_gmCurrent = GameMode_Scavenge;
}
#endif

/* ******************************************************************************** *
 *                             Left 4 DHooks Forwards                               *
 * ******************************************************************************** */

#if defined _l4dh_included
/**
 * L4D_GetGameModeType value must be checked after L4D_OnGameModeChange
 * is fired, this is because this is fired after ConVar change hook is called. Trying
 * to get the value of L4D_GetGameModeType with mp_gamemode hook will lead to incorrect value
 */
public void L4D_OnGameModeChange(int gamemode)
{
    PluginSwitch();
}
#endif