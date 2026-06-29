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

/* SM Includes */
#include <sourcemod>
#undef REQUIRE_PLUGIN
#include <updater>

/* Plugin Info */
#define PLUGIN_NAME "AllChat"
#define PLUGIN_VERSION "1.1.1"

public Plugin:myinfo =
{
    name = PLUGIN_NAME,
    author = "Frenzzy",
    description = "Relays chat messages to all players",
    version = PLUGIN_VERSION,
    url = "http://forums.alliedmods.net/showthread.php?p=1593727"
};

/* Globals */
#define UPDATE_URL "http://vsdir.com/sm/allchat/update.txt"

/* Convars */
new Handle:g_hCvarVersion = INVALID_HANDLE;
new Handle:g_hCvarAllTalk = INVALID_HANDLE;
new Handle:g_hCvarMode = INVALID_HANDLE;
new Handle:g_hCvarTeam = INVALID_HANDLE;

/* Chat Message */
new g_msgAuthor;
new bool:g_msgIsChat;
new String:g_msgType[64];
new String:g_msgName[64];
new String:g_msgText[512];
new bool:g_msgIsTeammate;
new bool:g_msgTarget[MAXPLAYERS + 1];

public OnPluginStart()
{
    // Events.
    new UserMsg:SayText2 = GetUserMessageId("SayText2");
    
    if (SayText2 == INVALID_MESSAGE_ID)
    {
        SetFailState("This game doesn't support SayText2 user messages.");
    }
    
    HookUserMessage(SayText2, Hook_UserMessage);
    HookEvent("player_say", Event_PlayerSay);
    
    // Convars.
    g_hCvarVersion = CreateConVar("sm_allchat_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD);
    OnVersionChanged(g_hCvarVersion, "", "");
    HookConVarChange(g_hCvarVersion, OnVersionChanged);
    
    g_hCvarAllTalk = FindConVar("sv_alltalk");
    g_hCvarMode = CreateConVar("sm_allchat_mode", "2", "Relays chat messages to all players? 0 = No, 1 = Yes, 2 = If AllTalk On", FCVAR_PLUGIN, true, 0.0, true, 2.0);
    g_hCvarTeam = CreateConVar("sm_allchat_team", "1", "Who can see say_team messages? 0 = Default, 1 = All teammates, 2 = All players", FCVAR_PLUGIN, true, 0.0, true, 2.0);
    
    AutoExecConfig(true, "allchat");
    
    // Commands.
    AddCommandListener(Command_Say, "say");
    AddCommandListener(Command_Say, "say_team");
    
    // Updater.
    if (LibraryExists("updater"))
    {
        Updater_AddPlugin(UPDATE_URL);
    }
}

public OnLibraryAdded(const String:name[])
{
    if (StrEqual(name, "updater"))
    {
        Updater_AddPlugin(UPDATE_URL);
    }
}

public OnVersionChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
    if (!StrEqual(newValue, PLUGIN_VERSION))
    {
        SetConVarString(g_hCvarVersion, PLUGIN_VERSION);
    }
}

public Action:Hook_UserMessage(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
    g_msgAuthor = BfReadByte(bf);
    g_msgIsChat = bool:BfReadByte(bf);
    BfReadString(bf, g_msgType, sizeof(g_msgType), false);
    BfReadString(bf, g_msgName, sizeof(g_msgName), false);
    BfReadString(bf, g_msgText, sizeof(g_msgText), false);
    
    for (new i = 0; i < playersNum; i++)
    {
        g_msgTarget[players[i]] = false;
    }
}

public Action:Event_PlayerSay(Handle:event, const String:name[], bool:dontBroadcast)
{
    new mode = GetConVarInt(g_hCvarMode);
    
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
    
    decl players[MaxClients];
    new playersNum = 0;
    
    if (g_msgIsTeammate && mode == 1 && g_msgAuthor > 0)
    {
        new team = GetClientTeam(g_msgAuthor);
        
        for (new client = 1; client <= MaxClients; client++)
        {
            if (IsClientInGame(client) && g_msgTarget[client] && GetClientTeam(client) == team)
            {
                players[playersNum++] = client;
            }
            
            g_msgTarget[client] = false;
        }
    }
    else
    {
        for (new client = 1; client <= MaxClients; client++)
        {
            if (IsClientInGame(client) && g_msgTarget[client])
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
    
    new Handle:SayText2 = StartMessage("SayText2", players, playersNum, USERMSG_RELIABLE | USERMSG_BLOCKHOOKS);
    
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

public Action:Command_Say(client, const String:command[], argc)
{
    for (new target = 1; target <= MaxClients; target++)
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
