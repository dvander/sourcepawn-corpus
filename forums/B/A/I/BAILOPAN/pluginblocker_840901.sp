/**
 * vim: set ts=4 sw=4 et :
 * =============================================================================
 * SourceMod Cheat ConVar blocker
 *
 * SourceMod (C)2004-2009 AlliedModders LLC.  All rights reserved.
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
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <http://www.sourcemod.net/license.php>.
 *
 * Version: $Id$
 */

#include <sourcemod>

#define DEBUG
#define VERSION "1.0"

public Plugin:myinfo = 
{
    name = "Cheat ConVar Blocker",
    author = "BAILOPAN",
    description = "Blocks plugins & cheat cvars on the client",
    version = VERSION,
    url = "http://www.sourcemod.net/"
}

new Handle:cheat_cvar_list
new Handle:cheat_value_list
new Handle:check_existance
new serial_gen
new player_cycler[MAXPLAYERS + 1]
new player_serial[MAXPLAYERS + 1]
new player_busy[MAXPLAYERS + 1]
new bool:late_load
new String:existance_vars[2][] =
{
    "metamod_version",
    "sourcemod_version"
}

public bool:AskPluginLoad(Handle:myself, bool:late, String:error[], err_max)
{
    late_load = late
    return true
}

public OnPluginStart()
{
    CreateConVar("sm_ccpblocker", VERSION, "Plugin version", FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD)
    check_existance = CreateConVar("sm_blockplugins", "0", "Block plugins")

    cheat_cvar_list = CreateArray(ByteCountToCells(256))
    cheat_value_list = CreateArray(ByteCountToCells(256))

    for (new i = 0; i < sizeof(existance_vars); i++)
    {
        PushArrayString(cheat_cvar_list, existance_vars[i])
        PushArrayString(cheat_value_list, "***SOURCEMOD***")
    }

    new flags
    new bool:isCommand
    new String:buffer[256]
    new Handle:list = FindFirstConCommand(buffer, sizeof(buffer), isCommand, flags)

    if (list == INVALID_HANDLE)
        return SetFailState("Could not read cvar list")

    if (!isCommand && (flags & FCVAR_CHEAT) == FCVAR_CHEAT)
        PushArrayString(cheat_cvar_list, buffer) 


    while (FindNextConCommand(list, buffer, sizeof(buffer), isCommand, flags))
    {
        if (!isCommand && (flags & FCVAR_CHEAT) == FCVAR_CHEAT)
            PushArrayString(cheat_cvar_list, buffer)
    }

    CloseHandle(list)

    for (new i = sizeof(existance_vars); i < GetArraySize(cheat_cvar_list); i++)
    {
        GetArrayString(cheat_cvar_list, i, buffer, sizeof(buffer))
#if defined DEBUG
        if (FindConVar(buffer) == INVALID_HANDLE)
            LogError("Invalid ConVar: %s", buffer)
#endif
        GetConVarString(FindConVar(buffer), buffer, sizeof(buffer))
        PushArrayString(cheat_value_list, buffer)
    }

    for (new i = 1; i <= MAXPLAYERS; i++)
        player_cycler[i] = -1

    if (late_load)
    {
        for (new i = 1; i <= MaxClients; i++)
        {
            if (IsClientInGame(i))
                OnClientPutInServer(i)
        }
    }

    CreateTimer(1.0, Timer_CheckPlayers, 0, TIMER_REPEAT)

    AutoExecConfig()

    return 0
}

public OnClientPutInServer(client)
{
    if (IsFakeClient(client))
        return

    player_serial[client] = ++serial_gen
    player_cycler[client] = -1
}

public OnClientDisconnect(client)
{
    player_serial[client] = 0
}

public ConVarQueried(QueryCookie:cookie,
                     client,
                     ConVarQueryResult:result,
                     const String:cvarName[],
                     const String:cvarValue[],
                     any:value)
{
    player_busy[client] = 0

    if (player_serial[client] != value)
        return

    if (result != ConVarQuery_Okay)
        return

    decl String:buffer[64]
#if defined DEBUG
    GetArrayString(cheat_cvar_list, player_cycler[client], buffer, sizeof(buffer))
    if (strcmp(buffer, cvarName) != 0)
    {
        LogError("Error detected, please report (%d, %d, %d, %s, %s, %d)",
                 cookie,
                 client,
                 result,
                 cvarName,
                 cvarValue,
                 value)
    }
#endif

    GetArrayString(cheat_value_list, player_cycler[client], buffer, sizeof(buffer))
    
    if (GetConVarInt(check_existance) && strcmp(buffer, "***SOURCEMOD***") == 0)
    {
        LogMessage("Rejecting client \"%N\" because \"%s\" = \"%s\"",
                   client,
                   cvarName,
                   cvarValue)
        KickClient(client, "Your client has plugins loaded, please remove them")
        return
    }

    if (strcmp(buffer, cvarValue) != 0)
    {
        LogMessage("Rejecting client \"%N\" because \"%s\" = \"%s\" instead of \"%s\"",
                   client,
                   cvarName,
                   cvarValue,
                   buffer)
        //KickClient(client, "cvar %s is invalid", cvarName)
    }
    else
    {
#if defined DEBUG2
        PrintToConsole(client,
                       "cvar \"%s\" checks out (\"%s\"=\"%s\")",
                       cvarName,
                       cvarValue,
                       buffer)
#endif
    }
}

public Action:Timer_CheckPlayers(Handle:timer)
{
    decl String:buffer[64]

    for (new i = 1; i <= MaxClients; i++)
    {
        if (!IsClientConnected(i) || IsFakeClient(i))
            continue
        if (player_busy[i])
            continue
        player_cycler[i]++
        if (player_cycler[i] >= GetArraySize(cheat_cvar_list))
            player_cycler[i] = 0
        GetArrayString(cheat_cvar_list, player_cycler[i], buffer, sizeof(buffer))
        QueryClientConVar(i, buffer, ConVarQueried, player_serial[i])
        player_busy[i] = 1
}

    return Plugin_Continue
}

