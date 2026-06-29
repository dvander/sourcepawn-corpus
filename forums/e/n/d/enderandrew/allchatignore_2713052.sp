/*
 * ============================================================================
 *
 *  SourceMod AllChat Plugin
 *
 *  File:          allchat.sp
 *  Description:   Relays chat messages to all players.
 *
 *  Copyright (C) 2011  Frenzzy
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * ============================================================================
 */

#pragma semicolon 1
#pragma newdecls required

/* SM Includes */
#include <sourcemod>
#include <ignore>

/* Plugin Info */
#define PLUGIN_NAME "AllChatIgnore"
#define PLUGIN_VERSION "0x04"

public Plugin myinfo =
{
    name = PLUGIN_NAME,
    author = "Frenzzy & Chdata",
    description = "Relays chat messages to all players - supports /ignore",
    version = PLUGIN_VERSION,
    url = "https://forums.alliedmods.net/showthread.php?p=2091299"
};

/* Convars */
Handle g_hCvarVersion = INVALID_HANDLE;
Handle g_hCvarAllTalk = INVALID_HANDLE;
Handle g_hCvarMode = INVALID_HANDLE;
Handle g_hCvarTeam = INVALID_HANDLE;

/* Chat Message */
int g_msgAuthor;
bool g_msgIsChat;
char g_msgType[64];
char g_msgName[64];
char g_msgText[512];
bool g_msgIsTeammate;
bool g_msgTarget[MAXPLAYERS + 1];

static bool g_bEnabled = false;

public void OnPluginStart()
{
    // Events.
    UserMsg SayText2 = GetUserMessageId("SayText2");
    
    if (SayText2 == INVALID_MESSAGE_ID)
    {
        SetFailState("This game doesn't support SayText2 user messages.");
    }
    
    HookUserMessage(SayText2, Hook_UserMessage);
    HookEvent("player_say", Event_PlayerSay);
    
    // Convars.
    g_hCvarVersion = CreateConVar("sm_allchat_version", PLUGIN_VERSION, PLUGIN_NAME, 0|FCVAR_NOTIFY|FCVAR_DONTRECORD);
    OnVersionChanged(g_hCvarVersion, "", "");
    HookConVarChange(g_hCvarVersion, OnVersionChanged);
    
    g_hCvarAllTalk = FindConVar("sv_alltalk");
    g_hCvarMode = CreateConVar("sm_allchat_mode", "2", "Relays chat messages to all players? 0 = No, 1 = Yes, 2 = If AllTalk On", 0, true, 0.0, true, 2.0);
    g_hCvarTeam = CreateConVar("sm_allchat_team", "1", "Who can see say_team messages? 0 = Default, 1 = All teammates, 2 = All players", 0, true, 0.0, true, 2.0);
    
    AutoExecConfig(true, "allchat");
    
    // Commands.
    AddCommandListener(Command_Say, "say");
    AddCommandListener(Command_Say, "say_team");
}

/*
    Check for necessary plugin dependencies and shut down this plugin if not found.

*/
public void OnAllPluginsLoaded()
{
    if (!LibraryExists("ignorematrix"))
    {
        SetFailState("Need ignorematrix to run this plugin.");
        //g_bEnabled = false;
    }
}

/*
    If a necessary plugin is removed, also shut this one down.

*/
public void OnLibraryRemoved(const char[] name)
{
    if (StrEqual(name, "ignorematrix"))
    {
        g_bEnabled = false;
    }
}

public void OnLibraryAdded(const char[] name)
{
    if (StrEqual(name, "ignorematrix"))
    {
        g_bEnabled = true;
    }
}

public void OnVersionChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
    if (!StrEqual(newValue, PLUGIN_VERSION))
    {
        SetConVarString(g_hCvarVersion, PLUGIN_VERSION);
    }
}

public Action Hook_UserMessage(UserMsg msg_id, Handle bf, const int[] players, int playersNum, bool reliable, bool init)
{
    if (!g_bEnabled) return Plugin_Continue;

    g_msgAuthor = BfReadByte(bf);
    g_msgIsChat = view_as<bool>(BfReadByte(bf));
    BfReadString(bf, g_msgType, sizeof(g_msgType), false);
    BfReadString(bf, g_msgName, sizeof(g_msgName), false);
    BfReadString(bf, g_msgText, sizeof(g_msgText), false);
    
    for (int i = 0; i < playersNum; i++)
    {
        g_msgTarget[players[i]] = false;
    }

    return Plugin_Continue;
}

public Action Event_PlayerSay(Handle event, const char[] name, bool dontBroadcast)
{
    if (!g_bEnabled) return;

    int mode = GetConVarInt(g_hCvarMode);
    
    if (mode < 1)
    {
        return;
    }
    
    if (mode > 1 && g_hCvarAllTalk != INVALID_HANDLE && !GetConVarBool(g_hCvarAllTalk))
    {
        return;
    }
    
    if (GetClientOfUserId(GetEventInt(event, "userid")) != g_msgAuthor)
    {
        return;
    }
    
    mode = GetConVarInt(g_hCvarTeam);
    
    if (g_msgIsTeammate && mode < 1)
    {
        return;
    }
    
    int[] players = new int[MaxClients];
    int playersNum = 0;
    
    if (g_msgIsTeammate && mode == 1 && g_msgAuthor > 0)
    {
        int team = GetClientTeam(g_msgAuthor);
        
        for (int client = 1; client <= MaxClients; client++)
        {
            if (!GetIgnoreMatrix(g_msgAuthor, client) && IsClientInGame(client) && g_msgTarget[client] && GetClientTeam(client) == team)
            {
                players[playersNum++] = client;
            }
            
            g_msgTarget[client] = false;
        }
    }
    else
    {
        for (int client = 1; client <= MaxClients; client++)
        {
            if (!GetIgnoreMatrix(g_msgAuthor, client) && IsClientInGame(client) && g_msgTarget[client])
            {
                players[playersNum++] = client;
            }
            
            g_msgTarget[client] = false;
        }
    }
    
    if (playersNum == 0)
    {
        return;
    }
    
    Handle SayText2 = StartMessage("SayText2", players, playersNum, USERMSG_RELIABLE); //| USERMSG_BLOCKHOOKS
    
    if (SayText2 != INVALID_HANDLE)
    {
        BfWriteByte(SayText2, g_msgAuthor);
        BfWriteByte(SayText2, g_msgIsChat);
        BfWriteString(SayText2, g_msgType);
        BfWriteString(SayText2, g_msgName);
        BfWriteString(SayText2, g_msgText);
        EndMessage();
    }
}

public Action Command_Say(int client, const char[] command, int argc)
{
    if (!g_bEnabled) return Plugin_Continue;

    for (int target = 1; target <= MaxClients; target++)
    {
        g_msgTarget[target] = true;
    }
    
    if (StrEqual(command, "say_team", false))
    {
        g_msgIsTeammate = true;
    }
    else
    {
        g_msgIsTeammate = false;
    }
    
    return Plugin_Continue;
}
