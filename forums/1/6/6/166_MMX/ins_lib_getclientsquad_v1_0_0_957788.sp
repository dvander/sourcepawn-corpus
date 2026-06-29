/**
 * vim: set ts=4 :
 * jedit:mode=c++:tabSize=4:indentSize=4:noTabs=true:folding=indent:
 * =============================================================================
 * SourceMod Insurgency beta 2 Library - GetClientSquad Plugin
 * Provides GetClientSquad for Insurgency beta 2.
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
 */

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_NAME    "INS b2 Library - GetClientSquad"
#define PLUGIN_VERSION "1.0.0"

#define INS_TEAM_NONE      0   /**< No team yet. */
#define INS_TEAM_US        1   /**< U.S. Marines. */
#define INS_TEAM_INS       2   /**< Insurgents. */
#define INS_TEAM_SPECTATOR 3   /**< Spectators. */
#define INS_TEAM_COUNT     4   /**< Number of teams. */

#define INS_SQUAD_INVALID  0   /**< Invalid. */
#define INS_SQUAD_US_1     1   /**< Squad 1. */
#define INS_SQUAD_US_2     2   /**< Squad 2. */
#define INS_SQUAD_INS_1    3   /**< Cell 1. */
#define INS_SQUAD_INS_2    4   /**< Cell 2. */

public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = "166_MMX.TVR",
	description = "Provides GetClientSquad for Insurgency beta 2",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

new g_aiClientSquad[MAXPLAYERS + 1] = {INS_SQUAD_INVALID, ...};

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

/**
 * Retrieves one of these client's constants {INS_SQUAD_INVALID,
 * INS_SQUAD_US_1, INS_SQUAD_US_2, INS_SQUAD_INS_1, INS_SQUAD_INS_2}
 *
 * @param   client  Client index to query
 * @return          Squad constant
 */

public GetClientSquad(client)
{
    return g_aiClientSquad[client];
}

public OnPluginStart()
{
    CreateConVar("sm_ins_lib_getclientsquad_version", PLUGIN_VERSION,
        "Insurgency beta 2 Library GetClientSquad Version",
        FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY);

    decl String:name[256];
    GetGameFolderName(name, sizeof(name));
    new bool:bIsGameIns = (strcmp(name, "insurgency") == 0);

    if (!bIsGameIns)
    {
        LogError("Skipping initialization of \"%s\" due to game folder name mismatch. Expected \"%s\" but found \"%s\" (case sensitive match).", PLUGIN_NAME, "insurgency", name);
        return;
    }

    RegPluginLibrary("ins_lib_getclientsquad");

    initClientSquadArray();

    HookEvent("player_squad", Event_player_squad);
}

