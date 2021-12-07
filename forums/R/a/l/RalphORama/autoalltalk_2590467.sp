/**
 * vim: set ts=4 :
 *
 * AutoAllTalk: Enable sv_alltalk when only a few players are on your server.
 *
 * Dependencies:
 *  - [INC] More Colors: https://forums.alliedmods.net/showthread.php?t=185016
 *
 * Copyright (C) 2018 Ralph Drake
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include <sourcemod>
#include <morecolors>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = {
    name        = "AutoAllTalk",
    author      = "Ralph \"RalphORama\" Drake",
    description = "Enables sv_alltalk when player count is below a certain threshold or the round hasn't begun / is over.",
    version     = "1.0.1",
    url         = "https://friendos.club"
};

// Pre-defined ConVars
ConVar g_allTalk;

// Custom ConVars
ConVar sm_aat_threshold = null;

/*
 * Returns the client count put in the server.
 *
 * Adapted from smlib
 * https://github.com/bcserv/smlib/blob/master/scripting/include/smlib/clients.inc#L623
 *
 * @param inGameOnly    If false connecting players are also counted.
 * @param countBots     If true bots will be counted too.
 * @return              Client count in the server.
 */
stock int Client_GetCount(bool countInGameOnly=true, bool countFakeClients=true)
{
    int numClients = 0;

    for (int client = 1; client <= MaxClients; client++) {

        if (!IsClientConnected(client)) {
            continue;
        }

        if (countInGameOnly && !IsClientInGame(client)) {
            continue;
        }

        if (!countFakeClients && IsFakeClient(client)) {
            continue;
        }

        numClients++;
    }

    return numClients;
}

public void OnPluginStart()
{
    // Player join/leave hooks
    HookEvent("player_activate", Event_PlayerActivate, EventHookMode_PostNoCopy);
    HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_PostNoCopy);

    // TF2 only: round start/end hooks
    // TODO: See if more hooks exist that I should take into account.
    HookEvent("teamplay_round_start", Event_RoundStart, EventHookMode_PostNoCopy);
    HookEvent("teamplay_waiting_begins", Event_RoundEnd, EventHookMode_PostNoCopy);
    HookEvent("teamplay_round_win", Event_RoundEnd, EventHookMode_PostNoCopy);
    HookEvent("teamplay_round_stalemate", Event_RoundEnd, EventHookMode_PostNoCopy);

    // Find existing ConVars
    g_allTalk = FindConVar("sv_alltalk");

    // Create our own ConVars
    sm_aat_threshold = CreateConVar("sm_aat_threshold", "17", "Turn alltalk off after this many players have connected", FCVAR_REPLICATED, true, view_as<float>(0));

    // Create a cfg file
    AutoExecConfig(true, "autoalltalk");

    PrintToServer("[AutoAllTalk] Plugin loaded.");
}

public void Event_PlayerActivate(Event event, const char[] name, bool dontBroadcast)
{
    UpdateAllTalk();
}

public void Event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast)
{
    UpdateAllTalk();
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    UpdateAllTalk();
}

/*
 * Generic function for "non-round" event hooks.
 * Called when an event signifying we aren't in a round fires.
 */
public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
    UpdateAllTalk(true);
}

/*
 * Updates sv_alltalk based on current player count.
 *
 * @param enable    If true, force sv_alltalk on (for pre and post-round).
 */
void UpdateAllTalk(bool enable = false)
{
    PrintToServer("[AutoAllTalk] UpdateAllTalk() called.");

    // Force enable alltalk
    if (enable && GetConVarInt(g_allTalk) == 0) {
        SetConVarInt(g_allTalk, 1, true, false);
        PrintToServer("[AutoAllTalk] Round inactive. sv_alltalk enabled.");
        CPrintToChatAll("{violet}[AutoAllTalk]{default} Round inactive, sv_alltalk {green}enabled{default}.");
        return;
    }

    int playerCount = Client_GetCount(true, false); // only count "active" non-bot clients
    int threshold = GetConVarInt(sm_aat_threshold);

    bool withinThreshold = playerCount < threshold;

    if (withinThreshold && GetConVarInt(g_allTalk) == 0) {
        SetConVarInt(g_allTalk, 1, true, false);
        CPrintToChatAll("{violet}[AutoAllTalk]{default} Less than %d players, sv_alltalk {green}enabled{default}.", threshold);
    }
    else if (!withinThreshold && GetConVarInt(g_allTalk) == 1) {
        SetConVarInt(g_allTalk, 0, true, false);
        CPrintToChatAll("{violet}[AutoAllTalk]{default} More than %d players, sv_alltalk {red}disabled{default}.", threshold);
    }
}
