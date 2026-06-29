/*	Copyright © 2009, fezh

	Spawn with Armor is free software;
	you can redistribute it and/or modify it under the terms of the
	GNU General Public License as published by the Free Software Foundation.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with Spawn with Armor; if not, write to the
	Free Software Foundation, Inc., 59 Temple Place - Suite 330,
	Boston, MA 02111-1307, USA.
*/

#pragma semicolon 1
#include < sourcemod >

#define PLUGIN_VERSION	"2.0.0"
#define CVAR_FLAGS	(FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)

new Handle:cvar_armor = INVALID_HANDLE;
new Handle:cvar_only_ct = INVALID_HANDLE;
new Handle:cvar_set_helmet = INVALID_HANDLE;
new Handle:cvar_armor_amount = INVALID_HANDLE;

new String:g_armor_prop[ ] = { "m_ArmorValue" };
new String:g_helmet_prop[ ] = { "m_bHasHelmet" };

public Plugin:myinfo = 
{
	name = "Spawn with Armor",
	author = "fezh and Maya Lodd",
	description = "When you spawn you will get free armor",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=106245"
}

public OnPluginStart()
{
	cvar_armor = CreateConVar("sv_armor", "1", "Enables/disables the plugin");
	cvar_only_ct = CreateConVar("sv_only_ct", "1", "Enables/disables set armor only for CT");
	cvar_set_helmet = CreateConVar("sv_set_helmet", "1", "Enables/disables set Helmet for CT and T");
	cvar_armor_amount = CreateConVar("sv_armor_amount", "100", "How much armor player will get on spawn");
	
	HookEvent("player_spawn", HookPlayerSpawn, EventHookMode_Post);
	
	AutoExecConfig(true, "spawn_with_armor");
	
	CreateConVar("sm_spawn_armor", PLUGIN_VERSION, "Spawn with Armor version", CVAR_FLAGS);
}

public HookPlayerSpawn(Handle:event, const String:name[ ], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (IsPlayerAlive(client) && GetConVarInt(cvar_armor))
	{
		if (GetConVarInt(cvar_only_ct))
		{
			if (GetClientTeam(client) == 3)
			{
				SetEntProp(client, Prop_Send, g_armor_prop, GetConVarInt(cvar_armor_amount), 1);
				if(GetConVarInt(cvar_set_helmet))
				{
					SetEntProp(client, Prop_Send, g_helmet_prop, 1);
				}
			}
		}
		else
		{
			SetEntProp(client, Prop_Send, g_armor_prop, GetConVarInt(cvar_armor_amount), 1, 1);
			if(GetConVarInt(cvar_set_helmet))
			{
				SetEntProp(client, Prop_Send, g_helmet_prop, 1, 1);
			}
		}
	}
}
