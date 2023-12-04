/*
*	Drop Secondary Weapons on Death
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



#define PLUGIN_VERSION 		"1.1"

/*=======================================================================================
	Plugin Info:

*	Name	:	[L4D & L4D2] Drop Secondary Weapons on Death
*	Author	:	SilverShot
*	Descrp	:	Drops a players secondary weapons when they die.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=337958
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.1 (29-May-2022)
	- Renamed the plugin and added support for L4D1.
	- Plugin now drops Pistols and Melee weapons. Thanks to "Maur0" for reporting.

1.0 (29-May-2022)
	- Initial release.

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

int g_iWeapon[MAXPLAYERS+1];
bool g_bLeft4Dead2;



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D & L4D2] Drop Secondary Weapons on Death",
	author = "SilverShot",
	description = "Drops a players secondary weapons when they die.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=337958"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();

	if( test == Engine_Left4Dead ) g_bLeft4Dead2 = false;
	else if( test == Engine_Left4Dead2 ) g_bLeft4Dead2 = true;
	else
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}

	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("l4d_drop_secondary_version", PLUGIN_VERSION, "Drop Secondary Weapons on Death plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	HookEvent("player_death", Event_PlayerDeath);

	// Late load
	int weapon;
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) )
		{
			OnClientPutInServer(i);

			weapon = GetPlayerWeaponSlot(i, 1);
			if( weapon != -1 )
			{
				OnWeaponEquip(i, weapon);
			}
		}
	}
}



// ====================================================================================================
//					EVENTS
// ====================================================================================================
public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_WeaponCanUsePost, OnWeaponEquip);
}

Action OnWeaponEquip(int client, int weapon)
{
	static char sTemp[32];
	GetEdictClassname(weapon, sTemp, sizeof(sTemp));

	if( g_bLeft4Dead2 && strcmp(sTemp[7], "melee") == 0 )
	{
		g_iWeapon[client] = EntIndexToEntRef(weapon);
	}
	else if( g_bLeft4Dead2 && strcmp(sTemp[7], "pistol_magnum") == 0 )
	{
		g_iWeapon[client] = EntIndexToEntRef(weapon);
	}
	else if( strcmp(sTemp[7], "pistol") == 0 )
	{
		int dual = GetPlayerWeaponSlot(client, 1);
		if( dual != -1 )
		{
			GetEdictClassname(dual, sTemp, sizeof(sTemp));
			if( strcmp(sTemp[7], "pistol") == 0 )
			{
				g_iWeapon[client] = EntIndexToEntRef(dual);

				return; // 2nd pistol being equipped is deleted, original is kept
			}
		}

		g_iWeapon[client] = EntIndexToEntRef(weapon);
	}
}

void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if( client && IsClientInGame(client) && GetClientTeam(client) == 2 )
	{
		int entity = g_iWeapon[client];
		if( entity && EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE && GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity") == client )
		{
			// Old weapon remains at 0,0,0, still with the client as the "m_hOwnerEntity".
			int type;
			static char sTemp[32];
			GetEdictClassname(entity, sTemp, sizeof(sTemp));

			if( strcmp(sTemp[7], "pistol") == 0 )
			{
				type = 1;
			}
			else if( g_bLeft4Dead2 && strcmp(sTemp[7], "pistol_magnum") == 0 )
			{
				type = 2;
			}
			else if( g_bLeft4Dead2 && strcmp(sTemp[7], "melee") == 0 )
			{
				type = 3;
				GetEntPropString(entity, Prop_Data, "m_strMapSetScriptName", sTemp, sizeof(sTemp));
			}

			bool dual;
			if( type == 1 && GetEntProp(entity, Prop_Send, "m_isDualWielding") ) dual = true;

			RemoveEntity(entity);
			entity = -1;

			// Create new and drop
			switch( type )
			{
				case 1: entity = CreateEntityByName("weapon_pistol");
				case 2: entity = CreateEntityByName("weapon_pistol_magnum");
				case 3: entity = CreateEntityByName("weapon_melee");
			}

			if( entity != -1 )
			{
				float vPos[3];
				GetClientAbsOrigin(client, vPos);

				vPos[0] += 30;
				vPos[1] += 30;
				vPos[2] += 35.0;

				if( type == 3 )
				{
					DispatchKeyValue(entity, "melee_script_name", sTemp);
				}

				DispatchKeyValue(entity, "solid", "6");
				TeleportEntity(entity, vPos, view_as<float>({ 10.0, 10.0, 1.0 }), NULL_VECTOR);
				DispatchSpawn(entity);

				// Create dual pistol and drop
				if( dual && g_bLeft4Dead2 ) // L4D1 already drops 1 pistol of dual wielding
				{
					entity = CreateEntityByName("weapon_pistol");

					if( entity != -1 )
					{
						vPos[0] += 10;
						vPos[1] += 10;

						DispatchKeyValue(entity, "solid", "6");
						TeleportEntity(entity, vPos, view_as<float>({ 30.0, 30.0, 10.0 }), NULL_VECTOR);
						DispatchSpawn(entity);
					}
				}
			}
		}
	}
}