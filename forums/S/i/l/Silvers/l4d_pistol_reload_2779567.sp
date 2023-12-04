/*
*	Pistol Reload
*	Copyright (C) 2022 Silvers
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



#define PLUGIN_VERSION 		"1.0"

/*======================================================================================
	Plugin Info:

*	Name	:	[L4D & L4D2] Pistol Reload
*	Author	:	SilverShot
*	Descrp	:	Sets a pistols clip to 0 when reloading.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=337807
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.0 (16-May-2022)
	- Initial release.

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D & L4D2] Pistol Reload",
	author = "SilverShot",
	description = "Sets a pistols clip to 0 when reloading.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=337807"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();

	if( test != Engine_Left4Dead && test != Engine_Left4Dead2 )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}

	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("l4d_pistol_reload_version", PLUGIN_VERSION, "Pistol Reload plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);

	HookEvent("weapon_reload", Event_WeaponReload);
}



// ====================================================================================================
//					EVENTS
// ====================================================================================================
public void Event_WeaponReload(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if( client && !IsFakeClient(client) )
	{
		int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if( weapon != -1 && GetEntProp(weapon, Prop_Send, "m_bInReload") )
		{
			static char classname[16];
			GetEdictClassname(weapon, classname, sizeof(classname));
			if( strncmp(classname, "weapon_pistol", 13) == 0 )
			{
				SetEntProp(weapon, Prop_Send, "m_iClip1", 0);
			}
		}
	}
}