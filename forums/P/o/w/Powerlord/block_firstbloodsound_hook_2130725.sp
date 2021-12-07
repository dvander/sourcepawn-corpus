/**
 * vim: set ts=4 :
 * =============================================================================
 * [TF2] Block First Blood Sound
 * Block the First Blood Sound
 *
 * Block First Blood Sound (C)2014 Powerlord (Ross Bemrose).  All rights reserved.
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
#include <sdktools>
#pragma semicolon 1

#define VERSION "1.0.0 Hook"

new Handle:g_Cvar_Enabled;

public Plugin:myinfo = {
	name			= "[TF2] Block First Blood Sound",
	author			= "Powerlord",
	description		= "Block the First Blood sound (hook version)",
	version			= VERSION,
	url				= "https://forums.alliedmods.net/showthread.php?t=239470"
};

public OnPluginStart()
{
	CreateConVar("blockfirstblood_version", VERSION, "Block First Blood Sound version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_SPONLY);
	g_Cvar_Enabled = CreateConVar("blockfirstblood_enable", "1", "Enable Block First Blood Sound?", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD, true, 0.0, true, 1.0);

	AddNormalSoundHook(FirstBloodSoundHook);
}

public Action:FirstBloodSoundHook(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
{
	if (!GetConVarBool(g_Cvar_Enabled))
	{
		return Plugin_Continue;
	}
	
	if (StrContains(sample, "announcer_AM_FirstBlood") != -1)
	{
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}
