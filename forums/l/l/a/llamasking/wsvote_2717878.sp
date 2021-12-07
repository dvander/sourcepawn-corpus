/**
 * ======================================================================
 * Workshop Map Vote
 * Copyright (C) 2020-2021 llamasking
 * ======================================================================
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, as per version 3 of the license.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

#pragma semicolon 1

#include <sourcemod>
#include <multicolors>
#include <nativevotes>
#include <SteamWorks>

//#define DEBUG
#define VERSION "1.1.5"
#define UPDATE_URL "https://raw.githubusercontent.com/llamasking/sourcemod-plugins/master/Plugins/wsvote/updatefile.txt"

#if !defined DEBUG
#undef REQUIRE_PLUGIN
#include <updater>
#endif

public Plugin myinfo =
{
    name = "Workshop Map Vote",
    author = "llamasking",
    description = "Allows players to call votes to change to workshop maps.",
    version = VERSION,
    url = "https://github.com/llamasking/sourcemod-plugins"
}

/* Global Variables */
char g_mapid[16];
char g_mapname[64];

/* ConVars */
ConVar g_minsubs;
ConVar g_mapchange_delay;
ConVar g_notify;
ConVar g_notifydelay;

/* Current Map Info */
char g_cmap_name[64];
char g_cmap_id[64];
bool g_cmap_stock;

public void OnPluginStart()
{
    char game[16];
    GetGameFolderName(game, sizeof(game));

    // Throw error if running any game other than tf2.
    if (!StrEqual(game, "tf"))
        SetFailState("This game is not supported! Stopping.");

    // Fail if the game does not support a change level vote.
    // Useful if I add support for other games in the future.
    /*
    if (!NativeVotes_IsVoteTypeSupported(NativeVotesType_ChgLevel))
        SetFailState("This game does not support a change level vote! Stopping.");
    */

    // ConVars
    CreateConVar("sm_workshop_version", VERSION, "Plugin Version", FCVAR_DONTRECORD | FCVAR_NOTIFY);
    g_minsubs         = CreateConVar("sm_workshop_min_subs", "50", "The minimum number of current subscribers for a workshop map.");
    g_mapchange_delay = CreateConVar("sm_workshop_delay", "10", "The delay between the vote passing and the map changing.", _, true, 0.0);
    g_notify          = CreateConVar("sm_workshop_notify", "1", "Whether or not to notify joining players about the map's Workshop name and ID.'", _, true, 0.0, true, 1.0);
    g_notifydelay     = CreateConVar("sm_workshop_notify_delay", "60", "How many seconds to wait after a client joins before notifying them.'", _, true, 0.0);

    // Load config values.
    AutoExecConfig();

    // Load translations.
    LoadTranslations("wsvote.phrases.txt");

    // Register commands.
    RegConsoleCmd("sm_wsmap", Command_WsVote, "Call a vote to change to a workshop map.");
    RegConsoleCmd("sm_wsvote", Command_WsVote, "Call a vote to change to a workshop map.");
    RegConsoleCmd("sm_cmap", Command_CurrentMap, "Shows information about the current map.");
    RegConsoleCmd("sm_currentmap", Command_CurrentMap, "Shows information about the current map.");

    // Updater
    #if !defined DEBUG
    if (LibraryExists("updater"))
    {
        Updater_AddPlugin(UPDATE_URL);
    }
    #endif
}

#if !defined DEBUG
public void OnLibraryAdded(const char[] name)
{
    if (StrEqual(name, "updater"))
    {
        Updater_AddPlugin(UPDATE_URL);
    }
}
#endif

// Current Map Functionality
public void OnMapStart()
{
    #if defined DEBUG
    LogMessage("---- Update Map");
    #endif

    char cmap_name[64];
    GetCurrentMap(cmap_name, sizeof(cmap_name));

    if(StrContains(cmap_name, ".ugc") != -1)
    {
        #if defined DEBUG
        LogMessage("---- Workshop Map");
        #endif

        g_cmap_stock = false;

        // Get map ID out of it's name
        char buffers[2][64];
        ExplodeString(cmap_name, ".ugc", buffers, 2, 64);
        strcopy(g_cmap_id, sizeof(g_cmap_id), buffers[1]);

        // Query SteamAPI for more information.
        // Format body of request.
        char reqBody[64];
        Format(reqBody, sizeof(reqBody), "itemcount=1&publishedfileids[0]=%s&format=vdf", buffers[1]);

        // Query SteamAPI.
        Handle req = SteamWorks_CreateHTTPRequest(k_EHTTPMethodPOST, "https://api.steampowered.com/ISteamRemoteStorage/GetPublishedFileDetails/v1/");
        SteamWorks_SetHTTPRequestRawPostBody(req, "application/x-www-form-urlencoded", reqBody, strlen(reqBody));
        SteamWorks_SetHTTPCallbacks(req, UpdateCurrentMapCallback);
        SteamWorks_SendHTTPRequest(req);
    }
    else
    {
        #if defined DEBUG
        LogMessage("---- Stock Map");
        #endif

        g_cmap_stock = true;
        strcopy(g_cmap_name, sizeof(g_cmap_name), cmap_name);
    }
}

public void UpdateCurrentMapCallback(Handle req, bool failure, bool requestSuccessful, EHTTPStatusCode statusCode)
{
    #if defined DEBUG
    LogMessage("---- Map Callback");
    #endif

    if (failure || !requestSuccessful || statusCode != k_EHTTPStatusCode200OK)
    {
        strcopy(g_cmap_name, sizeof(g_cmap_name), "Error");

        LogError("Error updating current map info!");
        delete req; // See notice below.
        return;
    }

    // Read response.
    int size;
    SteamWorks_GetHTTPResponseBodySize(req, size);
    char[] data = new char[size];
    SteamWorks_GetHTTPResponseBodyData(req, data, size);

    // Turn response into keyvalues.
    KeyValues kv = new KeyValues("response");
    kv.SetEscapeSequences(true);
    kv.ImportFromString(data);

    // Move into item's subkey.
    kv.JumpToKey("publishedfiledetails");
    kv.JumpToKey("0");

    // Get map name!
    kv.GetString("title", g_cmap_name, sizeof(g_cmap_name));

    // NOTICE: FOR THE LOVE OF ALL THINGS YOU CARE ABOUT, DELETE HANDLES.
    // OTHERWISE IT WILL LEAK SO BADLY THAT THE SERVER WILL ALMOST IMMEDIATELY CRASH.
    delete req;
    delete kv;
}

// Notify Functionality
public void OnClientPutInServer(int client)
{
    if(GetConVarBool(g_notify) && !IsFakeClient(client))
        CreateTimer(GetConVarFloat(g_notifydelay), Timer_NotifyPlayer, GetClientUserId(client));
}

public Action Timer_NotifyPlayer(Handle timer, any userid)
{
    #if defined DEBUG
    LogMessage("---- Notify Timer");
    #endif
    int client = GetClientOfUserId(userid);

    // Ignore if the player left and all that good shit
    if(!g_cmap_stock && IsClientInGame(client))
        CPrintToChat(client, "{gold}[Workshop]{default} %t", "WsVote_CurrentMap_Workshop", g_cmap_name, g_cmap_id);
}

// Current Map Command
public Action Command_CurrentMap(int client, int args)
{
    if(g_cmap_stock)
    {
        CPrintToChat(client, "{gold}[Workshop]{default} %t", "WsVote_CurrentMap_Stock", g_cmap_name);
    }
    else
    {
        CPrintToChat(client, "{gold}[Workshop]{default} %t", "WsVote_CurrentMap_Workshop", g_cmap_name, g_cmap_id);
    }
    return Plugin_Handled;
}

// WsVote / WsMap Command
public Action Command_WsVote(int client, int args)
{
    #if defined DEBUG
    CReplyToCommand(client, "{fullred}[Workshop]{default} %t", "WsVote_DebugMode_Enabled", client);
    #endif

    // Ignore console/rcon and spectators.
    if (client == 0 || GetClientTeam(client) < 2)
    {
        CReplyToCommand(client, "{gold}[Workshop]{default} %t", "WsVote_Spectator", client);
        return Plugin_Handled;
    }

    // Get workshop id and ignore if none is given.
    if (GetCmdArg(1, g_mapid, sizeof(g_mapid)) == 0)
    {
        CReplyToCommand(client, "{gold}[Workshop]{default} %t", "WsVote_CallVote_NoId", client);
        return Plugin_Handled;
    }

    // Format body of request.
    char reqBody[64];
    Format(reqBody, sizeof(reqBody), "itemcount=1&publishedfileids[0]=%s&format=vdf", g_mapid);

    // Query SteamAPI.
    Handle req = SteamWorks_CreateHTTPRequest(k_EHTTPMethodPOST, "https://api.steampowered.com/ISteamRemoteStorage/GetPublishedFileDetails/v1/");
    SteamWorks_SetHTTPRequestRawPostBody(req, "application/x-www-form-urlencoded", reqBody, strlen(reqBody));
    SteamWorks_SetHTTPRequestContextValue(req, GetClientUserId(client));
    SteamWorks_SetHTTPCallbacks(req, ReqCallback);
    SteamWorks_SendHTTPRequest(req);

    return Plugin_Handled;
}

public void ReqCallback(Handle req, bool failure, bool requestSuccessful, EHTTPStatusCode statusCode, any userid)
{
    int client = GetClientOfUserId(userid);

    if (failure || !requestSuccessful || statusCode != k_EHTTPStatusCode200OK)
    {
        CPrintToChat(client, "{gold}[Workshop]{default} %t", "WsVote_CallVote_ApiFailure");
        LogError("Error on request for id: '%s'", g_mapid);
        delete req; // See notice below.
        return;
    }

    // Read response.
    int size;
    SteamWorks_GetHTTPResponseBodySize(req, size);
    char[] data = new char[size];
    SteamWorks_GetHTTPResponseBodyData(req, data, size);

    // Turn response into keyvalues.
    KeyValues kv = new KeyValues("response");
    kv.SetEscapeSequences(true);
    kv.ImportFromString(data);

    // Move into item's subkey.
    kv.JumpToKey("publishedfiledetails");
    kv.JumpToKey("0");

    // Verify the item is actually for TF2 and has enough subscribers.
    // Also accidentally verifies that the id is actually a map since apparently only maps can have subscriptions.
    if (kv.GetNum("consumer_app_id") != 440 || (kv.GetNum("lifetime_subscriptions") < GetConVarInt(g_minsubs)))
    {
        CPrintToChat(client, "{gold}[Workshop]{default} %t", "WsVote_CallVote_InvalidItem");

        // See notice below
        delete req;
        delete kv;

        return;
    }

    // Get map name!
    kv.GetString("title", g_mapname, sizeof(g_mapname));

    // Initialize vote.
    Handle vote = NativeVotes_Create(Nv_Vote, NativeVotesType_ChgLevel);
    NativeVotes_SetDetails(vote, g_mapname);
    NativeVotes_SetInitiator(vote, client);

    // Gets a list of players that are actually in game - not spectators.
    // Based off code from nativevotes.inc
    int total;
    int[] players = new int[MaxClients];
    for (int i=1; i<=MaxClients; i++)
    {
        if (!IsClientInGame(i) || IsFakeClient(i) || (GetClientTeam(i) < 2))
            continue;
        players[total++] = i;
    }

    // Display vote or error if a vote is in progress.
    if (!NativeVotes_Display(vote, players, total, 20, VOTEFLAG_NO_REVOTES))
    {
        CPrintToChat(client, "{gold}[Workshop]{default} %t", "WsVote_ExistingVote");
        //NativeVotes_DisplayFail(vote, NativeVotesFail_Generic);
    }
    else
    {
        PrintHintText(client, "%t", "WsVote_CallVote_FailWarning", client);
    }

    // NOTICE: FOR THE LOVE OF ALL THINGS YOU CARE ABOUT, DELETE HANDLES.
    // OTHERWISE IT WILL LEAK SO BADLY THAT THE SERVER WILL ALMOST IMMEDIATELY CRASH.
    delete req;
    delete kv;
}

public int Nv_Vote(NativeVote vote, MenuAction action, int param1, int param2)
{
    // Taken from one of the comments on the NativeVotes thread on AM.
    switch (action)
    {
        case MenuAction_VoteEnd:
        {
            if (param1 == NATIVEVOTES_VOTE_YES)
            {
                // Attempt to download map ahead of time.
                ServerCommand("tf_workshop_map_sync %s", g_mapid);

                vote.DisplayPass(g_mapname);

                float delay = GetConVarFloat(g_mapchange_delay);

                CPrintToChatAll("{gold}[Workshop]{default} %t", "WsVote_CallVote_VotePass", g_mapname, RoundToNearest(delay));
                #if !defined DEBUG
                CreateTimer(delay, Timer_ChangeLevel);
                #endif
            }
            else
            {
                vote.DisplayFail(NativeVotesFail_Loses);
            }
        }

        case MenuAction_VoteCancel:
        {
            if (param1 == VoteCancel_NoVotes)
            {
                vote.DisplayFail(NativeVotesFail_NotEnoughVotes);
            }
            else
            {
                vote.DisplayFail(NativeVotesFail_Generic);
            }
        }

        case MenuAction_End:
        {
            vote.Close();
        }
    }
}

public Action Timer_ChangeLevel(Handle timer)
{
    ServerCommand("changelevel workshop/%s", g_mapid);
}