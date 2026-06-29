/**
 * =============================================================================
 * TF2 Basic Kickvote Immunity
 * Causes TF2 player kick votes to obey SM immunity levels.
 *
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

public Plugin:myinfo =
{
	name = "TF2 Basic Kickvote Immunity",
	author = "psychoninc",
	description = "Causes TF2 player kick votes to obey SM immunity levels",
	version = "1.2",
	url = "http://nicholashastings.com"
};

stock min(a, b) { return (((a) < (b)) ? (a) : (b)); }

public OnPluginStart()
{
	AddCommandListener(callvote, "callvote");
}

public Action:callvote(client, const String:cmd[], argc)
{
	// kick vote from client, "callvote %s \"%d %s\"\n;"
	if (argc < 2)
		return Plugin_Continue;
	
	decl String:votereason[16];
	GetCmdArg(1, votereason, sizeof(votereason));
	
	if (!!strcmp(votereason, "kick", false))
		return Plugin_Continue;
	
	decl String:therest[256];
	GetCmdArg(2, therest, sizeof(therest));
	
	new userid = 0;
	new spacepos = FindCharInString(therest, ' ');
	if (spacepos > -1)
	{
		decl String:temp[12];
		strcopy(temp, min(spacepos+1, sizeof(temp)), therest);
		userid = StringToInt(temp);
	}
	else
	{
		userid = StringToInt(therest);
	}
	
	new target = GetClientOfUserId(userid);
	if (target < 1)
		return Plugin_Continue;
	
	new AdminId:clientAdmin = GetUserAdmin(client);
	new AdminId:targetAdmin = GetUserAdmin(target);
	
	if (clientAdmin == INVALID_ADMIN_ID && targetAdmin == INVALID_ADMIN_ID)
		return Plugin_Continue;
	
	if (CanAdminTarget(clientAdmin, targetAdmin))
		return Plugin_Continue;
	
	PrintToChat(client, "You may not start a kick vote against \"%N\"", target);
	
	return Plugin_Handled;
}
