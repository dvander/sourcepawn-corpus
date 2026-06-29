/**
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
 */

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define VERSION "1.1"

public Plugin:myinfo = 
{
	name = "ND Mutiny Immunity",
	author = "psychonic",
	description = "Provides admins with immunity from mutiny votes",
	version = VERSION,
	url = "http://www.nicholashastings.com/"
};

#define ND_TEAM_CT 2
#define ND_TEAM_EMP 3

public OnPluginStart()
{
	CreateConVar("nd_mutiny_immunity", "1.1", "ND Mutiny Immunity Version", FCVAR_PLUGIN|FCVAR_NOTIFY);
	AddCommandListener(startmutiny, "startmutiny");
}

public Action:startmutiny(client, const String:command[], argc)
{
	if (client == 0 || !IsClientInGame(client))
		return Plugin_Continue;
	
	new team = GetClientTeam(client);
	if (team != ND_TEAM_CT && team != ND_TEAM_EMP)
		return Plugin_Continue;
	
	new commander = GameRules_GetPropEnt("m_hCommanders", team-2);
	if (commander == -1)
		return Plugin_Continue;
	
	if (!CheckCommandAccess(commander, "mutiny_immunity", ADMFLAG_BAN, true))
		return Plugin_Continue;
	
	PrintToChat(client, "\x04This commander is immune and cannot be kicked from the commander seat!");
	return Plugin_Handled;
}
