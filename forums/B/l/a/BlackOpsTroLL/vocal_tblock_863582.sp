/*
 * vim: set ts=4 :
 * =============================================================================
 * Left 4 Dead Vocalize Guard
 * Guards against Player's Abusing the Vocalize System
 * Variation of the 'Left 4 Dead Vote Gaurd Plugin by CrimsonGT
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

#define PLUGIN_VERSION "T-1.0.0"

new g_VocalCalled[MAXPLAYERS+1];
new Float:g_LastVocalTime[MAXPLAYERS+1];

/* CVARS */
new Handle:cEnabled = INVALID_HANDLE;
new Handle:cVocalLimit = INVALID_HANDLE;
new Handle:cVocalDelay = INVALID_HANDLE;
new Handle:cVocalTime = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "L4D Vocalize Guard",
	author = "Crimson - TeddyRuxpin, TroLL",
	description = "Left 4 Dead Vocalize Spam Blocker",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
}

public OnPluginStart()
{
	RegConsoleCmd("vocalize", Command_CallVocal);

	CreateConVar("sm_vocalize_guard_version", PLUGIN_VERSION, "L4D Vocalize Guard Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	cEnabled = CreateConVar("sm_vocalize_guard_enabled", "1", "Enable/Disable L4D Vocalize Guardian [0 = FALSE, 1 = TRUE]", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cVocalLimit = CreateConVar("sm_vocalize_guard_vlimit", "5", "Max Vocalize Spam Calls Allowed [0 = NO LIMIT]", FCVAR_PLUGIN, true, 0.0);
	cVocalDelay = CreateConVar("sm_vocalize_guard_vdelay", "3", "Delay before a player can call another Vocalize command [0 = DISABLED]", FCVAR_PLUGIN, true, 0.0);
	cVocalTime = CreateConVar("sm_vocalize_guard_vtime", "3", "Amount of time a player can hit vlimt [0 = DISABLED]", FCVAR_PLUGIN, true, 0.0);
	
	HookEvent("player_disconnect", Event_PlayerDisconnect);
}

public OnMapStart()
{
	new iMaxPlayers = GetMaxClients();
	
	for(new i=1;i<=iMaxPlayers;i++)
	{
		g_VocalCalled[i] = 0;
		g_LastVocalTime[i] = 0.0;
	}
}

public Action:Event_PlayerDisconnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	g_VocalCalled[client] = 0;
	g_LastVocalTime[client] = 0.0;
}

public Action:Command_CallVocal(client, args)
{
if(GetConVarBool(cEnabled))
{
	new iMaxVocal = GetConVarInt(cVocalLimit);
	new flTimeDelay = GetConVarInt(cVocalDelay);
	new f1TimeSpan = GetConVarInt(cVocalTime);
		
	/* If this player hasnt called any votes */
	if(g_VocalCalled[client] == 0)
	{
		g_LastVocalTime[client] = GetEngineTime();
		g_VocalCalled[client]++;
	}
	else 
	{
		if((GetEngineTime() - g_LastVocalTime[client]) < f1TimeSpan) 
			{
				if (g_VocalCalled[client] < iMaxVocal)
				{
					g_VocalCalled[client]++;
				}
				else
				{
				PrintToChat(client, "\x04[SM] \x01You must wait before starting another Vocalize"); 
				return Plugin_Handled; 
				}

			}
		else
			{
				if((GetEngineTime() - g_LastVocalTime[client]) > flTimeDelay)
				{
				g_LastVocalTime[client] = GetEngineTime();
				g_VocalCalled[client] = 1;
				}
				else
				{
				PrintToChat(client, "\x04[SM] \x01You must wait before starting another Vocalize"); 
				return Plugin_Handled; 
				}
			}
	}
}
	
return Plugin_Continue;
}


