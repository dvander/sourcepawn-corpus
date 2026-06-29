/*  [ND] Save Last Base Spawn
    Copyright (C) 2023 by databomb

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

#include <sourcemod>
#include <sdktools>

#tryinclude <nd_commander_build>
#tryinclude <nd_structures>

#define PLUGIN_VERSION "1.1.2"

#if !defined _nd_commmander_build_included_

    /**
     * Allows a plugin to block a structure from being sold by returning Plugin_Stop.
     *
     * @param int client                     client index of the commander who attempted to build the structure
     * @param int entity                     entity index of the structure that is trying to be sold
     * @return                               Action that should be taken (Plugin_Stop to prevent sale)
     */
    forward Action ND_OnCommanderSellStructure(int client, int entity)

    // This helper function will display red text and a failed sound to the commander
    stock void UTIL_Commander_FailureText(int iClient, char sMessage[64])
    {
        ClientCommand(iClient, "play buttons/button7");

        Handle hBfCommanderText;
        hBfCommanderText = StartMessageOne("CommanderNotice", iClient, USERMSG_BLOCKHOOKS);
        BfWriteString(hBfCommanderText, sMessage);
        EndMessage();

        // clear other messages from notice area
        hBfCommanderText = StartMessageOne("CommanderNotice", iClient, USERMSG_BLOCKHOOKS);
        BfWriteString(hBfCommanderText, "");
        EndMessage();
    }

#endif

#if !defined _nd_structures_included

    #define STRUCT_TRANSPORT "struct_transport_gate"

    enum ND_Structures: {
        ND_Command_Bunker,
        ND_MG_Turret,
        ND_Transport_Gate,
        ND_Power_Plant,
        ND_Wireless_Repeater,
        ND_Relay_Tower,
        ND_Supply_Station,
        ND_Assembler,
        ND_Armory,
        ND_Artillery,
        ND_Radar_Station,
        ND_FT_Turret,
        ND_Sonic_Turret,
        ND_Rocket_Turret,
        ND_Wall,
        ND_Barrier,
        ND_StructCount
    }

#endif

public Plugin myinfo =
{
    name = "[ND] Save Base Spawn",
    author = "databomb",
    description = "Prevents selling of all base spawns (transport gates powered by the Command Bunker)",
    version = PLUGIN_VERSION,
    url = "https://forums.alliedmods.net/member.php?u=54648"
};

#define COMMAND_BUNKER_POWERED_DISTANCE     1250.0

Handle g_hSDKCall_GetBunkerFromTeam = INVALID_HANDLE;

public void OnPluginStart()
{
    CreateConVar("nd_save_basespawn_version", PLUGIN_VERSION, "ND Save Last Base Spawn Version", FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);

    GameData hGameDataBuild = new GameData("build-structure.games");
    if (!hGameDataBuild)
    {
        SetFailState("Failed to find gamedata/build-structure.games.txt");
    }

    // prep a call to find a team's bunker entity
    StartPrepSDKCall(SDKCall_GameRules);
    bool bSuccess = PrepSDKCall_SetFromConf(hGameDataBuild, SDKConf_Signature, "CNuclearDawn::GetCommandBunkerForTeam");
    if (!bSuccess)
    {
        SetFailState("Failed to find signature CNuclearDawn::GetCommandBunkerForTeam");
    }
    PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
    PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Plain);
    g_hSDKCall_GetBunkerFromTeam = EndPrepSDKCall();

    if (!g_hSDKCall_GetBunkerFromTeam)
    {
        SetFailState("Failed to establish SDKCall for CNuclearDawn::GetCommandBunkerForTeam");
    }

    delete hGameDataBuild;
}

public void OnAllPluginsLoaded()
{
    if (!LibraryExists("nd_structure_intercept"))
    {
        SetFailState("Structure sell detour not available. Check gamedata.");
    }
}

public Action ND_OnCommanderSellStructure(int iPlayer, int iEntity)
{
    // check if commander is trying to sell a spawn
    char sEntityName[32];
    GetEdictClassname(iEntity, sEntityName, sizeof(sEntityName));
    if (StrEqual(sEntityName, STRUCT_TRANSPORT))
    {
        // check if this spawn is powered by the Command Bunker of the player
        int iTeam = GetClientTeam(iPlayer);
        int iBunker = ND_GetTeamBunkerEntityEx(iTeam);
        float fBunkerPosition[3];
        GetEntPropVector(iBunker, Prop_Send, "m_vecOrigin", fBunkerPosition);
        float fStructurePosition[3];
        GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", fStructurePosition);
        float fDistanceFromBunker = GetVectorDistance(fStructurePosition, fBunkerPosition);

        if (fDistanceFromBunker <= COMMAND_BUNKER_POWERED_DISTANCE)
        {
            // check the total number of spawns remaining powered by the command bunker
            if (ND_GetBaseTransportCount(iTeam, fBunkerPosition) <= 1)
            {
                UTIL_Commander_FailureText(iPlayer, "CANNOT SELL LAST BASE SPAWN.");
                LogMessage("%N attempted to sell the last base spawn.", iPlayer);
                return Plugin_Stop;
            }
        }
    }

    return Plugin_Continue;
}

stock int ND_GetBaseTransportCount(int iBaseTeam, float fBunkerPosition[3])
{
    int iBaseSpawns = 0;
    int iLoopIndex = INVALID_ENT_REFERENCE;

    while ((iLoopIndex = FindEntityByClassname(iLoopIndex, STRUCT_TRANSPORT)) != INVALID_ENT_REFERENCE)
    {
        int iEntityTeam = GetEntProp(iLoopIndex, Prop_Send, "m_iTeamNum");
        if (iEntityTeam == iBaseTeam)
        {
            // check if powered by the bunker
            float fStructurePosition[3];
            GetEntPropVector(iLoopIndex, Prop_Send, "m_vecOrigin", fStructurePosition);
            float fDistanceFromBunker = GetVectorDistance(fStructurePosition, fBunkerPosition);

            if (fDistanceFromBunker <= COMMAND_BUNKER_POWERED_DISTANCE)
            {
                iBaseSpawns++;
            }
        }
    }

    return iBaseSpawns;
}

stock int ND_GetTeamBunkerEntityEx(int team)
{
    int entity = SDKCall(g_hSDKCall_GetBunkerFromTeam, team);
    return entity;
}
