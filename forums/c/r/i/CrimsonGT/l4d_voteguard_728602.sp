/*
 * vim: set ts=4 :
 * =============================================================================
 * Left 4 Dead Vote Guard
 * Guards against Player's Abusing the Voting System
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

#define PLUGIN_VERSION "1.0.2"

new g_VotesCalled[MAXPLAYERS+1];
new Float:g_LastVoteTime[MAXPLAYERS+1];

/* CVARS */
new Handle:cEnabled = INVALID_HANDLE;
new Handle:cAdminsImmune = INVALID_HANDLE;
new Handle:cVoteLimit = INVALID_HANDLE;
new Handle:cVoteDelay = INVALID_HANDLE;
new Handle:cBanTime = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "L4D Vote Guard",
	author = "Crimson",
	description = "Left 4 Dead Vote Features",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
}

public OnPluginStart()
{
	RegConsoleCmd("callvote", Command_CallVote);

	CreateConVar("sm_voteguard_version", PLUGIN_VERSION, "L4D Vote Guard Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	cEnabled = CreateConVar("sm_voteguard_enabled", "1", "Enable/Disable L4D Vote Guardian [0 = FALSE, 1 = TRUE]", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cAdminsImmune = CreateConVar("sm_voteguard_adminimmune", "1", "Enable/Disable Admin Immunity to Penalties [0 = FALSE, 1 = TRUE]", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cVoteLimit = CreateConVar("sm_voteguard_vlimit", "3", "Max Vote Calls Allowed [0 = NO LIMIT]", FCVAR_PLUGIN, true, 0.0);
	cVoteDelay = CreateConVar("sm_voteguard_vdelay", "60", "Delay before a player can call another Vote [0 = DISABLED]", FCVAR_PLUGIN, true, 0.0);
	cBanTime = CreateConVar("sm_voteguard_bantime", "10", "Duration of Ban [0 = KICKS PLAYER]", FCVAR_PLUGIN, true, 0.0);
	
	HookEvent("player_disconnect", Event_PlayerDisconnect);
}

public OnMapStart()
{
	new iMaxPlayers = GetMaxClients();
	
	for(new i=1;i<=iMaxPlayers;i++)
	{
		g_VotesCalled[i] = 0;
		g_LastVoteTime[i] = 0.0;
	}
}

public Action:Event_PlayerDisconnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	g_VotesCalled[client] = 0;
	g_LastVoteTime[client] = 0.0;
}

public Action:Command_CallVote(client, args)
{
	new iMaxVotes = GetConVarInt(cVoteLimit);
	new flTimeDelay = GetConVarInt(cVoteDelay);
	
	decl String:sVoteType[32], String:sTarget[12];
	GetCmdArg(1, sVoteType, sizeof(sVoteType));
	GetCmdArg(2, sTarget, sizeof(sTarget));
	
	new target = GetClientOfUserId(StringToInt(sTarget));
	
	/* If the Callvote is a Kick, Check Immunity */
	if(strcmp(sVoteType, "Kick")==0)
	{
		if(IsAdmin(target))
		{
			PrintToChat(client, "\x04[SM] \x01You Cannot Call a Votekick Against this Player!");
			return Plugin_Handled;
		}
	}
	
	/* If this player hasnt called any votes */
	if(g_VotesCalled[client] == 0)
	{
		g_LastVoteTime[client] = GetEngineTime();
		g_VotesCalled[client]++;
	}
	else if(g_LastVoteTime[client] < (GetEngineTime() - flTimeDelay))
	{
		g_LastVoteTime[client] = GetEngineTime();

		/* If the plugin is enabled */
		if(GetConVarBool(cEnabled))
		{
			/*If Client Has Exceeded Max Call Votes */
			if((g_VotesCalled[client] == iMaxVotes) && (iMaxVotes != 0))
			{
				/* If the players not an admin */
				if(!IsAdmin(client))
				{
					RemovePlayer(client);
				}
			}
			/*Warns Client upon reaching the Max Call Votes */
			else if(g_VotesCalled[client] == (iMaxVotes-1))
			{
				PrintToChat(client, "\x04[SM] \x01You Have Reached the Max Amount of Call Votes");
				
				g_VotesCalled[client]++;
			}
			else
			{
				g_VotesCalled[client]++;
			}
		}
	}
	else
	{
		new iTimeLeft = RoundToNearest(flTimeDelay - (GetEngineTime() - g_LastVoteTime[client]));
		PrintToChat(client, "\x04[SM] \x01You must wait %d Seconds before starting another Vote", iTimeLeft);
		
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

/* Is Player Admin Check */
bool:IsAdmin(client)
{
	if(GetConVarInt(cAdminsImmune) == 0)
	{
		return false;
	}

	new AdminId:admin = GetUserAdmin(client);
	
	if(admin == INVALID_ADMIN_ID)
	{
		return false;
	}

	return true;
}

/* Kick OR Ban Player Based on CVAR Value */
RemovePlayer(client)
{
	new iBanTime = GetConVarInt(cBanTime);

	if(IsClientConnected(client))
	{
		if(iBanTime == 0)
		{
			KickClient(client, "Kicked for Vote Abuse");
			
			decl String:sName[MAX_NAME_LENGTH];
			GetClientName(client, sName, sizeof(sName));

			PrintToChatAll("\x04[SM] \x01%s was Kicked for Vote Abuse", sName);
		}
		else if(iBanTime > 0)
		{
			BanClient(client, iBanTime, BANFLAG_AUTO, "Banned", "Banned", _, client);
			
			decl String:sName[MAX_NAME_LENGTH];
			GetClientName(client, sName, sizeof(sName));
			PrintToChatAll("\x04[SM] \x01%s was Banned %d Minutes for Vote Abuse", sName, iBanTime);
		}
	}
}