/**
 * vim: set ts=4 :
 * jedit:mode=c++:tabSize=4:indentSize=4:noTabs=true:folding=indent:
 * =============================================================================
 * SourceMod Insurgency beta 2 Library - GetClientSquad Plugin
 * Provides team, squad constants and GetClientSquad function
 * for Insurgency beta 2.
 *
 * 166_MMX.TVR.  All rights reserved.
 * =============================================================================
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Version: $Id$
 *
 *
 * v1.1.0 - 2009-10-11
 *   * fixed    Missing player_team event hook
 *   * changed  Global g_aiClientSquad variable to static
 *   + added    Change log
 *   + added    Plugin structure comments
 *   + added    A couple of documentation comments
 *   * added    INS_SQUAD_COUNT constant
 *   - removed  sdktools include for now
 *
 * v1.0.0 - 2009-10-10
 *   +          Initial release
 */

//==============================================================================
// Compiler Directives
//==============================================================================

#pragma semicolon 1

#include <sourcemod>
// Not needed right now as a reimplementation of FindEntityByClassname
// is being used
//#include <sdktools>

#define PLUGIN_NAME         "INS b2 Library - GetClientSquad"
#define PLUGIN_VERSION      "1.1.0"

#define INS_TEAM_NONE       0  /**< No team yet. */
#define INS_TEAM_US         1  /**< U.S. Marines. */
#define INS_TEAM_INS        2  /**< Insurgents. */
#define INS_TEAM_SPECTATOR  3  /**< Spectators. */
#define INS_TEAM_COUNT      4  /**< Number of teams. */

#define INS_SQUAD_INVALID   0  /**< Invalid. */
#define INS_SQUAD_US_1      1  /**< Squad 1. */
#define INS_SQUAD_US_2      2  /**< Squad 2. */
#define INS_SQUAD_INS_1     3  /**< Cell 1. */
#define INS_SQUAD_INS_2     4  /**< Cell 2. */
#define INS_SQUAD_COUNT     5  /**< Number of squads. */

//==============================================================================
// Plugin information
//==============================================================================

public Plugin:myinfo =
{
    name        = PLUGIN_NAME,
    author      = "166_MMX.TVR",
    description = "Provides team, squad constants and GetClientSquad function for Insurgency beta 2",
    version     = PLUGIN_VERSION,
    url         = "http://www.sourcemod.net/"
};

//==============================================================================
// Global variables
//==============================================================================

static g_aiClientSquad[MAXPLAYERS + 1] = {INS_SQUAD_INVALID, ...};

//==============================================================================
// Private functions
//==============================================================================

findEntityByClassnameForIns(startEnt, const String:classname[])
{
    decl String:sClassName[128];
    new iEntityCount   = GetEntityCount(),
        iMaxEntities   = GetMaxEntities(),
        iFoundEntities = 0,
        iEntity        = startEnt + 1;

    while (iFoundEntities <= iEntityCount && iEntity <= iMaxEntities)
    {
        if (!IsValidEntity(iEntity) || !IsValidEdict(iEntity))
        {
            iEntity++;
            continue;
        }
        iFoundEntities++;

        GetEntityNetClass(iEntity, sClassName, sizeof(sClassName));
        if (strcmp(sClassName, classname) != 0)
        {
            iEntity++;
            continue;
        }

        return iEntity;
    }

    return -1;
}

getCPlayTeamEntity(iTeamId, iTeamIdOffset)
{
    new iEntity       = -1,
        iEntityTeamId = -1;

    // Using a reimplementation of FindEntityByClassname as the native function
    // always return -1; might be a bug
    while ((iEntity = findEntityByClassnameForIns(iEntity, "CPlayTeam")) != -1)
    {
        iEntityTeamId = GetEntData(iEntity, iTeamIdOffset);
        if (iEntityTeamId == iTeamId)
        {
            return iEntity;
        }
    }

    return iEntity;
}

getSquadConst(iClientTeam, iSquadNr)
{
    switch(iClientTeam)
    {
        case INS_TEAM_US:
        {
            switch(iSquadNr)
            {
                case 1:
                {
                    return INS_SQUAD_US_1;
                }
                case 2:
                {
                    return INS_SQUAD_US_2;
                }
                default:
                {
                    return INS_SQUAD_INVALID;
                }
            }
        }
        case INS_TEAM_INS:
        {
            switch(iSquadNr)
            {
                case 1:
                {
                    return INS_SQUAD_INS_1;
                }
                case 2:
                {
                    return INS_SQUAD_INS_2;
                }
                default:
                {
                    return INS_SQUAD_INVALID;
                }
            }
        }
        default:
        {
            return INS_SQUAD_INVALID;
        }
    }

    return INS_SQUAD_INVALID;
}

/**
 * GameServerConsole] sm_dump_netprops ins_netprops_.txt
 * insurgency/ins_netprops_.txt
 * 
 * CPlayTeam: [260 lines]
 *  See attached file: ins_netprops_CPlayTeam.txt
 */

initClientSquadArray()
{
    new iTeamIdOffset    = FindSendPropInfo("CPlayTeam", "m_iTeamID"),
        iSquadDataOffset = FindSendPropInfo("CPlayTeam", "m_iSquadData"),
        iClient          = MaxClients - 1,
        iClientTeam      = INS_TEAM_NONE,
        iEntity          = -1,
        aaiSquadData[INS_TEAM_COUNT][MAXPLAYERS + 1] = {{-1, ...}, {-1, ...},
            {-1, ...}, {-1, ...}},
        iSquadNr         = 0;

    for (; iClient > 0; iClient--)
    {
        if (
            !IsClientConnected(iClient)
            || IsFakeClient(iClient)
            || !IsClientInGame(iClient)
        )
        {
            continue;
        }

        iClientTeam = GetClientTeam(iClient);

        if (iClientTeam == INS_TEAM_NONE || iClientTeam == INS_TEAM_SPECTATOR)
        {
            continue;
        }

        if (aaiSquadData[iClientTeam][0] == -1)
        {
            iEntity = getCPlayTeamEntity(iClientTeam, iTeamIdOffset);
            GetEntDataArray(iEntity, iSquadDataOffset,
                aaiSquadData[iClientTeam], sizeof(aaiSquadData[]));
        }

        // iSquadData will be one of {5, 9,  13, 17, 21, 25, 29, 33} for Squad 1
        // iSquadData will be one of {6, 10, 14, 18, 22, 26, 30, 34} for Squad 2
        // iSquadData will be one of {5, 9,  13, 17, 21, 25, 29, 33} for Cell 1
        // iSquadData will be one of {6, 10, 14, 18, 22, 26, 30, 34} for Cell 2
        iSquadNr                = aaiSquadData[iClientTeam][iClient] % 4;

        g_aiClientSquad[iClient] = getSquadConst(iClientTeam, iSquadNr);
    }
}

//==============================================================================
// Privately called event handlers
//==============================================================================

/**
 * Steam/SteamApps/insurgencybase.gcf/root/insurgency/resource/GameEvents.res
 * 
 * "player_team"                // player change his team
 * {
 *     "userid"   "short"       // user ID on server
 *     "team"     "byte"        // team id
 *     "oldteam"  "byte"        // old team id
 * }
 */

public Action:Event_player_team(Handle:event, const String:name[], bool:dontBroadcast)
{
    new iUserId     = GetEventInt(event, "userid"),
        iTeamId     = GetEventInt(event, "team"),
        iClient     = GetClientOfUserId(iUserId);

    if (iTeamId == INS_TEAM_NONE || iTeamId == INS_TEAM_SPECTATOR)
    {
        g_aiClientSquad[iClient] = INS_SQUAD_INVALID;
    }

    return Plugin_Continue;
}

/**
 * Steam/SteamApps/insurgencybase.gcf/root/insurgency/resource/GameEvents.res
 * 
 * "player_squad"               // a player changed his class
 * {
 *     "userid"    "short"      // user ID on server
 *     "squad"     "short"      // squad id
 *     "slot"      "short"      // slot id
 *     "oldsquad"  "short"      // old squad id
 *     "oldslot"   "short"      // old slot id
 * }
 */

public Action:Event_player_squad(Handle:event, const String:name[], bool:dontBroadcast)
{
    new iUserId     = GetEventInt(event, "userid"),
        iSquadId    = GetEventInt(event, "squad"),
        iClient     = GetClientOfUserId(iUserId),
        iClientTeam = GetClientTeam(iClient),
        iSquadNr    = (iSquadId % 4);

    g_aiClientSquad[iClient] = getSquadConst(iClientTeam, iSquadNr);

    return Plugin_Continue;
}

//==============================================================================
// Public functions
//==============================================================================

/**
 * Retrieves the client's squad. The value will be one of these constants:
 * {INS_SQUAD_INVALID, INS_SQUAD_US_1, INS_SQUAD_US_2,
 *     INS_SQUAD_INS_1, INS_SQUAD_INS_2}
 *
 * @param   client  Client index to query
 * @return          Squad constant
 */

public GetClientSquad(client)
{
    return g_aiClientSquad[client];
}

//==============================================================================
// Globally called event handlers
//==============================================================================

public OnPluginStart()
{
    CreateConVar("sm_ins_lib_getclientsquad_version", PLUGIN_VERSION,
        "Insurgency beta 2 Library GetClientSquad Version",
        FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY);

    decl String:sGameFolderName[256];
    GetGameFolderName(sGameFolderName, sizeof(sGameFolderName));
    new bool:bIsGameIns = (strcmp(sGameFolderName, "insurgency") == 0);

    if (!bIsGameIns)
    {
        LogError(
            "Skipping initialization of \"%s\" due to game folder name mismatch. Expected \"%s\" but found \"%s\" (case sensitive match).",
            PLUGIN_NAME, "insurgency", sGameFolderName);
        return;
    }

    RegPluginLibrary("ins_lib_getclientsquad");

    initClientSquadArray();

    HookEvent("player_team",  Event_player_team);
    HookEvent("player_squad", Event_player_squad);
}

