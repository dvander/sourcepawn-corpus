/*
*	Common Limiter
*	Copyright (C) 2024 Silvers
*
*	This program is free software: you can redistribute it and/or modify
*	it under the terms of the GNU General Public License as published by
*	the Free Software Foundation, either version 3 of the License, or
*	(at your option) any later version.
*
*	This program is distributed in the hope that it will be useful,
*	but WITHOUT ANY WARRANTY; without even the implied warranty of
*	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*	GNU General Public License for more details.
*
*	You should have received a copy of the GNU General Public License
*	along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/



#define PLUGIN_VERSION 		"1.3"

/*======================================================================================
	Plugin Info:

*	Name	:	[L4D & L4D2] Common Limiter
*	Author	:	SilverShot
*	Descrp	:	Limit number of common infected to the z_common_limit cvar value.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=338337
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.3 (22-Sep-2024)
	- Removed delay deleting. Now counts common on each spawn instead of internally tracking.

1.2 (05-May-2024)
	- This version delays deleting by 1 second. Requested by "ball2hi".

1.1 (02-Oct-2023)
	- Changes to fix possible entity count errors.

1.0 (27-Jun-2022)
	- Initial release.

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

int g_iLimitCommon;
ConVar g_hCvarLimit;

public Plugin myinfo =
{
	name = "[L4D & L4D2] Common Limiter",
	author = "SilverShot",
	description = "Limit number of common infected to the z_common_limit cvar value.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=338337"
}

public void OnPluginStart()
{
	CreateConVar("l4d_common_limiter_version", PLUGIN_VERSION, "Common Limiter plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);

	g_hCvarLimit = FindConVar("z_common_limit");
	g_hCvarLimit.AddChangeHook(ConVarChanged_Cvars);
	g_iLimitCommon = g_hCvarLimit.IntValue;

	RegAdminCmd("sm_common_limit", CmdLimit, ADMFLAG_ROOT);
}

void ConVarChanged_Cvars(Handle convar, const char[] oldValue, const char[] newValue)
{
	g_iLimitCommon = g_hCvarLimit.IntValue;
}

Action CmdLimit(int client, int args)
{
	int total;
	int entity = -1;
	while( (entity = FindEntityByClassname(entity, "infected")) != INVALID_ENT_REFERENCE )
	{
		total++;
	}

	ReplyToCommand(client, "Common Limiter: %d common infected", total);
	return Plugin_Handled;
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if( entity > 0 && entity < 2048 && strcmp(classname, "infected") == 0 )
	{
		int total;
		int common = -1;
		while( (common = FindEntityByClassname(common, "infected")) != INVALID_ENT_REFERENCE )
		{
			if( ++total > g_iLimitCommon )
			{
				SDKHook(entity, SDKHook_SpawnPost, OnSpawn);
				return;
			}
		}
	}
}

void OnSpawn(int entity)
{
	RemoveEntity(entity);
}