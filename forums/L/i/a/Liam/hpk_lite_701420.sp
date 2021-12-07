/**
 * vim: set ts=4 :
 * =============================================================================
 * High Ping Kicker - Lite Edition
 * Checks for High Ping
 *
 * SourceMod (C)2004-2007 AlliedModders LLC.  All rights reserved.
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
 */

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define VERSION "1.0.0.1"

#define VERSION_FLAGS FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD
#define TIMER_FLAGS TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE
#define UMIN(%1,%2) (%1 < %2 ? %2 : %1)

new Handle:g_Cvar_Enabled = INVALID_HANDLE;         // HPK Enabled?
new Handle:g_Cvar_MaxPing = INVALID_HANDLE;         // maximum ping clients are allowed
new Handle:g_Cvar_MaxChecks = INVALID_HANDLE;       // amount of times to check
new Handle:g_Cvar_StartCheck = INVALID_HANDLE;      // seconds to start checking after map start
new Handle:g_Cvar_AdminsImmune = INVALID_HANDLE;    // are admins immune to checks
new g_FailedChecks[MAXPLAYERS+1];                   // number of checks clients have failed
new g_Ping[MAXPLAYERS+1];                           

public Plugin:myinfo =
{
    name = "High Ping Kicker - Lite Edition",
    author = "Liam",
    description = "Checks for High Ping.",
    version = VERSION,
    url = "http://www.wcugaming.org"
};

public OnPluginStart( )
{
    LoadTranslations("common.phrases");
    CreateConVar("hpk_lite_version", VERSION, "HPK - Lite Version Number", VERSION_FLAGS);
    g_Cvar_Enabled = CreateConVar("sm_hpk_enabled", "1", "0 = Off | 1 = On -- HPK Enabled?");
    g_Cvar_MaxPing = CreateConVar("sm_maxping", "150", "Max ping allowed for clients.");
    g_Cvar_MaxChecks = CreateConVar("sm_maxchecks", "10", "Number of grace checks for high ping.");
    g_Cvar_StartCheck = CreateConVar("sm_startcheck", "15.0", "When to start checking ping after map start. (Seconds)");
    g_Cvar_AdminsImmune = CreateConVar("sm_adminsimmune", "1", "0 = Off | 1 = On -- Admins immune to High Ping?");

    AutoExecConfig(true, "hpk_lite");
}

public OnMapStart( )
{
    new maxclients = GetMaxClients( );

    if(GetConVarInt(g_Cvar_Enabled) == 1)
    {
        CreateTimer(GetConVarFloat(g_Cvar_StartCheck), Timer_CheckPing, _, TIMER_FLAGS);
    }

    for(new i = 1; i < maxclients; i++)
    {
        g_Ping[i] = 0;
        g_FailedChecks[i] = 0;
    }
}

public OnClientPutInServer(client)
{
    g_Ping[client] = 0;
    g_FailedChecks[client] = 0;
}

public Action:Timer_CheckPing(Handle:Timer)
{
    if(GetConVarInt(g_Cvar_Enabled) == 0)
        return Plugin_Stop;

    new maxclients = GetMaxClients( );

    for(new i = 1; i < maxclients; i++)
    {
        if(!IsClientConnected(i) || !IsClientInGame(i)
            || IsFakeClient(i) || IsAdmin(i))
            continue;

        UpdatePingStatus(i);
    }
    HandleHighPingers( );
    return Plugin_Continue;
}

UpdatePingStatus(client)
{
    decl String:rate[32];
    GetClientInfo(client, "cl_cmdrate", rate, sizeof(rate));
    new Float:ping = GetClientAvgLatency(client, NetFlow_Outgoing);
    new Float:tickRate = GetTickInterval( );
    new cmdRate = UMIN(StringToInt(rate), 20);

    ping -= ((0.5 / cmdRate) + (tickRate * 1.0));
    ping -= (tickRate * 0.5);
    ping *= 1000.0;

    g_Ping[client] = RoundToZero(ping);

    if(g_Ping[client] > GetConVarInt(g_Cvar_MaxPing))
        g_FailedChecks[client]++;
    else
    {
        if(g_FailedChecks[client] > 0)
            g_FailedChecks[client]--;
    }
}

HandleHighPingers( )
{
    new maxclients = GetMaxClients( );

    for(new i = 1; i < maxclients; i++)
    {
        if(!IsClientConnected(i) || !IsClientInGame(i) || IsFakeClient(i))
            continue;

        if(g_FailedChecks[i] >= GetConVarInt(g_Cvar_MaxChecks))
        {
            KickClient(i, "Your ping is too high. (%d) Max: (%d)", 
                g_Ping[i], GetConVarInt(g_Cvar_MaxPing));
        }
    }
}

bool:IsAdmin(client)
{
    if(GetConVarInt(g_Cvar_AdminsImmune) == 0)
        return false;

    new AdminId:admin = GetUserAdmin(client);

    if(admin == INVALID_ADMIN_ID)
        return false;

    return true;
}