/*
 * ============================================================================
 *
 *  DeadChat
 *
 *  File:          deadchat.sp
 *  Type:          Base
 *  Description:   Modifies who can chat with who.
 *
 *  Copyright (C) 2009-2010  Greyscale
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

#define DEADCHAT_GAME_CSS
// #define DEADCHAT_GAME_TF2

#if defined DEADCHAT_GAME_CSS
    #define GAME_GCHAT      "\x01%s1 \x03%s2 \x01:  %s3"
    #define TEAM_1_TCHAT    "DeadChat CSS teamsay spectator"
    #define TEAM_2_TCHAT    "DeadChat CSS teamsay terrorist"
    #define TEAM_3_TCHAT    "DeadChat CSS teamsay counter-terrorist"
    #define GAME_TCHAT      "\x01%s1%s2 \x03%s3 \x01:  %s4"
    #define GAME_SPECLBL    "DeadChat CSS label spectator"
    #define GAME_DEADLBL    "DeadChat CSS label dead"
#endif

#if defined DEADCHAT_GAME_TF2
    #define GAME_GCHAT      "\x01%s1 \x03%s2 \x01:  %s3"
    #define TEAM_1_TCHAT    "DeadChat TF2 teamsay"
    #define TEAM_2_TCHAT    "DeadChat TF2 teamsay"
    #define TEAM_3_TCHAT    "DeadChat TF2 teamsay"
    #define GAME_TCHAT      "\x01%s1%s2 \x03%s3 \x01:  %s4"
    #define GAME_SPECLBL    "DeadChat TF2 label spectator"
    #define GAME_DEADLBL    "DeadChat TF2 label dead"
#endif

#pragma semicolon 1
#include <sourcemod>

#define PLUGIN_VERSION "2.0"

public Plugin:myinfo =
{
    name = "DeadChat",
    author = "Greyscale",
    description = "Modifies who can chat with who.",
    version = PLUGIN_VERSION,
    url = ""
};

/**
 * The server's index.
 */
#define SERVER_INDEX 0
/**
 * @section Cvar handles.
 */
new Handle:g_hCvarEnable;
new Handle:g_hCvarTeamSay;
/**
 * @endsection
 */

/**
 * This is set in the SayText2 usermessage hook for the
 */
//new bool:g_bInChat;

/**
 * Plugin is loading.
 */
public OnPluginStart()
{
    // Add listeners.
    RegConsoleCmd("say", Command_Say);
    RegConsoleCmd("say_team", Command_Say);
    
    // Hook the SayText2 usermessage, because this will stop gagged/admin chat from showing up.
    HookUserMessage(GetUserMessageId("SayText2"), SayText2Hook, true, SayText2PostHook);
    
    //AddCommandListener(Command_Say, "say");       // Any eventscripts users will have problems if I use this.
    //AddCommandListener(Command_Say, "say_team");
    
    // Create cvars.
    g_hCvarEnable =     CreateConVar("deadchat_enable", "-1", "Modify who can chat with who. ['-1' = Use sv_alltalk's value | '0' = Disable | '1' = Enable");
    g_hCvarTeamSay =    CreateConVar("deadchat_teamsay", "1", "Allow dead players to talk to alive teammates through team-only chat. (Aka \"ghosting\")");
    
    // Create public cvar.
    CreateConVar("gs_deadtalk_version", PLUGIN_VERSION, "[DeadChat] Current version of this plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
    
    // Create admin command.
    RegAdminCmd("deadchat_printmsg", Command_PrintMsg, ADMFLAG_GENERIC, "Sends messages from one client to another.  Usage deadchat_printmsg <sender> <receiver> <text> [teamonly]");
    
    // Load translations.
    LoadTranslations("deadchat.phrases");
}

/**
 * Empty usermessage callback, we only care about the post hook. (SayText2PostHook)
 */
public Action:SayText2Hook(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
}

/**
 * Valid values for the g_iSayMode variable.
 */
#define SAYMODE_NONE -1
#define SAYMODE_GLOBAL 0
#define SAYMODE_TEAM 1

/**
 * Information from the say(_team) callback for the usermessage post hook.
 */
new g_iSayMode = SAYMODE_NONE;
new g_iSayClient;
new String:g_strMessage[192];   // 192 is the max chat message length.

public SayText2PostHook(UserMsg:msg_id, bool:sent)
{
    // This means that the say or say_team commands weren't used prior to this, so the client hasn't entered text.
    if (g_iSayMode == SAYMODE_NONE)
        return;
    
    new saymode = g_iSayMode;   // Copy to new var so this one can be reset.
    new client = g_iSayClient;  // Better readability.
    
    g_iSayMode = SAYMODE_NONE;
    
    // Loop through living clients to print the dead client's message.
    for (new livingclient = 1; livingclient <= MaxClients; livingclient++)
    {
        if (!IsClientInGame(livingclient))
            continue;
        
        // Only living players need to have the chat printed to them.
        if (!IsPlayerAlive(livingclient))
            continue;
        
        if (saymode == SAYMODE_GLOBAL)
        {
            PrintGameChatMessage(client, livingclient, g_strMessage, false);
        }
        else if (saymode == SAYMODE_TEAM)
        {
            // Verify clients are on the same team.
            if (GetClientTeam(client) == GetClientTeam(livingclient))
                PrintGameChatMessage(client, livingclient, g_strMessage, true);
        }
    }
}

/**
 * Command listener: say, say_team
 * "Listens" for the say commands and modifies who can chat with who.
 * 
 * @param client    The client index.
 * @param command   The command the client used.
 * @param argc      The argument count.
 */
public Action:Command_Say(client, /*const String:command[], */argc)
{
    // If the client is the server, then don't interrupt.
    if (client == SERVER_INDEX)
        return Plugin_Continue;
    
    // If the client is alive, then don't interrupt.
    if (IsPlayerAlive(client))
        return Plugin_Continue;
    
    new Handle:hAlltalk = FindConVar("sv_alltalk");
    if (hAlltalk == INVALID_HANDLE)
    {
        LogError("[DeadChat] Can't find the \"sv_alltalk\" cvar!");
        return Plugin_Continue;
    }
    
    // Check the plugin should do anything.
    new enablemode = GetConVarInt(g_hCvarEnable);
    new bool:enabled = (enablemode == -1) ? GetConVarBool(hAlltalk) : (bool:enablemode);
    if (!enabled)
        return Plugin_Continue;
    
    // Get the command being used.
    decl String:command[16];
    GetCmdArg(0, command, sizeof(command));
    
    // Stop if ghosting isn't allowed.
    if (StrEqual(command, "say_team", false) && !GetConVarBool(g_hCvarTeamSay))
        return Plugin_Continue;
    
    // Set the information for the usermessage hook.
    
    if (StrEqual(command, "say", false))
        g_iSayMode = SAYMODE_GLOBAL;
    else if (StrEqual(command, "say_team", false))
        g_iSayMode = SAYMODE_TEAM;
    
    g_iSayClient = client;
    
    // Get text string.
    GetCmdArgString(g_strMessage, sizeof(g_strMessage));
    StripQuotes(g_strMessage);
    
    // Must reset g_iSayMode if the usermessage hook never fired (for gagged players, admin chat, etc)
    CreateTimer(0.1, ResetUserMessageInfo);
    return Plugin_Continue;
}

public Action:ResetUserMessageInfo(Handle:timer)
{
    g_iSayMode = SAYMODE_NONE;
}

/**
 * Print text from one client to another that appears the same as in the specified game.
 * 
 * @param sender    The sender of the message.
 * @param receiver  The receiver of the sender's message.
 * @param text      The text to send to the receiver from the sender.
 * @param teamonly  True to format as a team-only message, false as a global message.
 */
stock PrintGameChatMessage(sender, receiver, const String:text[], bool:teamonly)
{
    decl String:sendername[64];
    GetClientName(sender, sendername, sizeof(sendername));
    
    new Handle:hSayText2 = StartMessageOne("SayText2", receiver);
        
    BfWriteByte(hSayText2, sender);
    BfWriteByte(hSayText2, true);
    
    new String:label[16];   // Use |new| to initialize the string.
    
    if (teamonly)
    {
        // Write the team chat format string to the usermessage.
        BfWriteString(hSayText2, GAME_TCHAT);
        
        // Format the client's team name on in the message.
        decl String:team[32];
        new clientteam = GetClientTeam(sender);
        if (clientteam <= 1)
        {
            strcopy(label, sizeof(label), "");
            Format(team, sizeof(team), "%T", TEAM_1_TCHAT, receiver);
            clientteam = 1; // Just in case the client isn't on a team.  Using 0 in the TEAM_X_TCHAT macro would cause errors
        }
        else
        {
            if (!IsPlayerAlive(sender))
                Format(label, sizeof(label), "%T", GAME_DEADLBL, receiver);
            
            if (clientteam  == 2)
                Format(team, sizeof(team), "%T", TEAM_2_TCHAT, receiver);
            else if (clientteam  == 3)
                Format(team, sizeof(team), "%T", TEAM_3_TCHAT, receiver);
        }
        
        // Write the label of the string.
        BfWriteString(hSayText2, label);
        
        // Write the team of the client whose sending the message.
        BfWriteString(hSayText2, team);
    }
    else
    {
        // Write the global chat format string to the usermessage.
        BfWriteString(hSayText2, GAME_GCHAT);
        
        if (GetClientTeam(sender) > 1)
        {
            // Format the *DEAD* label if the sender isn't alive.
            if (!IsPlayerAlive(sender))
                Format(label, sizeof(label), "%T", GAME_DEADLBL, receiver);
        }
        else
            Format(label, sizeof(label), "%T", GAME_SPECLBL, receiver);
        
        BfWriteString(hSayText2, label);
    }
    
    BfWriteString(hSayText2, sendername);
    BfWriteString(hSayText2, text);
    
    EndMessage();
}

/**
 * Command callback.  deadchat_printmsg
 * Prints a message from the sender to a receiver.
 * 
 * @param client    The client index.
 * @param argc      The number of arguments sent with the command.
 */
public Action:Command_PrintMsg(client, argc)
{
    // Verify argument count.
    if (argc < 3)
    {
        ReplyToCommand(client, "[DeadChat] %t", "DeadChat cmd printmsg syntax");
        return Plugin_Handled;
    }
    
    new String:args[5][192];
    for (new arg = 1; arg < sizeof(args); arg++)
        GetCmdArg(arg, args[arg], sizeof(args[]));
    
    decl String:targetname[MAX_NAME_LENGTH];
    new senders[MAXPLAYERS], receivers[MAXPLAYERS], bool:tn_is_ml, result;
    
    // Find a target.
    result = ProcessTargetString(args[1], client, senders, sizeof(senders), COMMAND_FILTER_NO_MULTI, targetname, sizeof(targetname), tn_is_ml);
    
    // Check if there was a problem finding a sender.
    if (result <= 0)
    {
        ReplyToTargetError(client, result);
        return Plugin_Handled;
    }
    
    // Find a target.
    result = ProcessTargetString(args[2], client, receivers, sizeof(receivers), 0, targetname, sizeof(targetname), tn_is_ml);
        
    // Check if there was a problem finding receiver(s).
    if (result <= 0)
    {
        ReplyToTargetError(client, result);
        return Plugin_Handled;
    }
    
    // Loop through the receivers.
    for (new rindex = 0; rindex < result; rindex++)
        PrintGameChatMessage(senders[0], receivers[rindex], args[3], bool:StringToInt(args[4]));
    
    return Plugin_Handled;
}
