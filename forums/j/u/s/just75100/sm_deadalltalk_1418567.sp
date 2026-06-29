/**
 * =============================================================================
 * SourceMod DeadAllTalk
 * (C)2009 <eVa>Dog - www.theville.org
 *
 * SourceMod (C)2004-2008 AlliedModders LLC.  All rights reserved.
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

new Handle:Cvar_Deadtalk = INVALID_HANDLE;
new Handle:Cvar_Sentinel = INVALID_HANDLE;

#define PLUGIN_VERSION "1.0.104"

#define ADMIN_LEVEL          ADMFLAG_CHAT

public Plugin:myinfo =
{
   name = "Dead Alltalk",
   author = "<eVa>StrontiumDog/MMX.TVR",
   description = "Lets dead players chat with each other while the living play on",
   version = PLUGIN_VERSION,
   url = "http://www.theville.org"
};

public OnPluginStart()
{
   CreateConVar("sm_deadalltalk_version", PLUGIN_VERSION, "DeadAlltalk Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
   Cvar_Deadtalk = CreateConVar("sm_deadalltalk", "1", " - when enabled, dead players can listen/chat to one another", FCVAR_PLUGIN);
   Cvar_Sentinel = FindConVar("sv_admin_sentinel_startup");
   }

public OnMapStart()
{
   HookEvent("player_spawn", PlayerSpawnEvent);
   HookEvent("player_death", PlayerDeathEvent);
}

public OnEventShutdown()
{
   UnhookEvent("player_spawn", PlayerSpawnEvent);
   UnhookEvent("player_death", PlayerDeathEvent);
}

public PlayerSpawnEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
    if (1 != GetConVarInt(Cvar_Deadtalk))
    {
        return;
    }
    
    new sourceClient = GetClientOfUserId(GetEventInt(event, "userid"));
    
    if ((GetUserFlagBits(sourceClient) & ADMIN_LEVEL) && (Cvar_Sentinel != INVALID_HANDLE))
    {
        return;
    }
    
    for (new targetClient = MaxClients; 0 < targetClient; targetClient--)
    {
        if (!IsClientInGame(targetClient))
        {
            continue;
        }
        
        SetClientListening(sourceClient, targetClient, LISTEN_DEFAULT);
    
        if (GetClientTeam(targetClient) == GetClientTeam(sourceClient))
        {
            continue;
        }
        
        // Dead clients on opposite team can't hear respawned client
        SetClientListening(targetClient, sourceClient, LISTEN_DEFAULT);
    }
}

public PlayerDeathEvent(Handle:event, const String:name[], bool:dontBroadcast)
{   
    if (1 != GetConVarInt(Cvar_Deadtalk))
    {
        return;
    }
    
    new sourceClient = GetClientOfUserId(GetEventInt(event, "userid"));
    
    if ((GetUserFlagBits(sourceClient) & ADMIN_LEVEL) && (Cvar_Sentinel != INVALID_HANDLE))
    {
        return;
    }
    
    new sourceClientTeam = GetClientTeam(sourceClient);
    
    for (new targetClient = MaxClients; 0 < targetClient; targetClient--)
    {
        if (!IsClientInGame(targetClient) || targetClient == sourceClient)
        {
            continue;
        }
        
        if (!IsPlayerAlive(targetClient))
        {
            // Dead players can hear dead client and vice versa
            SetClientListening(targetClient, sourceClient, LISTEN_YES);
            SetClientListening(sourceClient, targetClient, LISTEN_YES);
        }
        
        if (GetClientTeam(targetClient) == sourceClientTeam)
        {
            // Client can listen to own team
            SetClientListening(sourceClient, targetClient, LISTEN_YES);
        }
    }
}