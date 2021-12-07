/**
 * =============================================================================
 * CS:GO Basic Kickvote Immunity
 * Causes CS:GO player kick votes to obey SM immunity levels.
 * Also restricts other callvotes when an admin is in-game.
 * 
 * (C)2014 Stephen Bevan
 *
 * Credits to psychonic - https://forums.alliedmods.net/showthread.php?t=161586 for
 * original code and example with TF2 Basic Kickvote Immunity
 * (C)2011 Nicholas Hastings
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
 
#pragma semicolon 1
#include <sourcemod>

#define 	PLUGIN_VERSION 		"0.0.1.0"

new bool:PlayerIsAdmin[MAXPLAYERS+1];

public Plugin:myinfo =
{
	name = "CS:GO Vote Kick Immunity",
	author = "TnTSCS aka ClarkKent",
	description = "Provides in-game vote kick immunity from built-in votes",
	version = PLUGIN_VERSION,
	url = "http://www.dhgamers.com"
};

public OnPluginStart()
{
	AddCommandListener(callvote, "callvote");
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	if (late)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && !IsFakeClient(i))
			{
				OnClientPostAdminCheck(i);
			}
		}
	}
	
	return APLRes_Success;
}

public OnClientPostAdminCheck(client)
{
	PlayerIsAdmin[client] = CheckCommandAccess(client, "player_is_admin", ADMFLAG_GENERIC);
}

public OnClientDisconnect(client)
{
	if (IsClientInGame(client))
	{
		PlayerIsAdmin[client] = false;
	}
}

bool:IsAdminInGame()
{
	new bool:result = false;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && PlayerIsAdmin[i])
		{
			result = true;
			break;
		}
	}
	
	LogMessage("There [%s] an admin in-game", (result ? "is" : "is not"));
	return result;
}

public Action:callvote(client, const String:cmd[], argc)
{
	if (!(1 <= client <= MaxClients))
	{
		return Plugin_Continue;
	}
	
	new String:g_sCommand[192];
	GetCmdArgString(g_sCommand, sizeof(g_sCommand));
	LogAction(client, -1, "\"%L\" called a vote: \"%s\"", client, g_sCommand);
	
	new String:votereason[16];
	GetCmdArg(1, votereason, sizeof(votereason));
	
	/* kick vote from client, "callvote %s \"%d %s\"\n;"
	* Thank you to psychonic for code used in this section */
	if (StrEqual(votereason, "kick", false))
	{
		new String:therest[256];
		GetCmdArg(2, therest, sizeof(therest));
		
		new userid = 0;
		new spacepos = FindCharInString(therest, ' ');
		if (spacepos > -1)
		{
			new String:temp[12];
			strcopy(temp, min(spacepos+1, sizeof(temp)), therest);
			userid = StringToInt(temp);
		}
		else
		{
			userid = StringToInt(therest);
		}
		
		new target = GetClientOfUserId(userid);
		if (target < 1)
		{
			LogMessage("ERROR: callvote for userid [%i] failed.", userid);
			return Plugin_Continue;
		}
		
		/* Player calling the vote is not an admin and player being targeted is not an admin */
		if (!PlayerIsAdmin[client] && !PlayerIsAdmin[target])
		{
			/* If there is an admin in game, do not let this vote continue. */
			return ( (IsAdminInGame()) ? (Plugin_Handled) : (Plugin_Continue) );
		}
		
		new AdminId:clientAdmin = GetUserAdmin(client);
		new AdminId:targetAdmin = GetUserAdmin(target);
		
		/* Check if client can target the target */
		if (CanAdminTarget(clientAdmin, targetAdmin))
		{
			return Plugin_Continue;
		}
		
		/* Client cannot target the target, do not let the vote continue */
		PrintToChat(client, "You may not start a kick vote against \"%N\"", target);
		return Plugin_Handled;
	}
	
	/* The callvote is something other than kick */
	
	if (PlayerIsAdmin[client])
	{
		/* Admins can use the callvote at any time */
		return Plugin_Continue;
	}
	
	/* At this point, the player calling the vote is not an admin */
	if (IsAdminInGame())
	{
		/* Since there's an admin in game, let's not allow this vote */
		PrintToChat(client, "You cannot vote yet.");
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

min(a, b)
{
	return ( ((a) < (b)) ? (a) : (b) );
}