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

#define PLUGIN_VERSION	"0.1.0b"
#define CVAR_FLAGS	(FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)

new Handle:cvar_armor = INVALID_HANDLE;
new Handle:cvar_armor_amount = INVALID_HANDLE;

new String:g_armor_prop[ ] = { "m_ArmorValue" };

public Plugin:myinfo = 
{
	name = "Spawn with Armor",
	author = "fezh",
	description = "When you spawn you will get free armor",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
}

public OnPluginStart()
{
	cvar_armor = CreateConVar( "sv_armor", "1", "Enables/disables the plugin" );
	cvar_armor_amount = CreateConVar( "sv_armor_amount", "100", "How much armor player will get on spawn" );
	
	HookEvent( "player_spawn", HookPlayerSpawn, EventHookMode_Post );
	
	CreateConVar( "sm_spawn_armor", PLUGIN_VERSION, "Spawn with Armor version", CVAR_FLAGS );
}

public HookPlayerSpawn( Handle:event, const String:name[ ], bool:dontBroadcast )
{
	new client = GetClientOfUserId( GetEventInt( event, "userid" ) );
	
	if ( IsPlayerAlive( client ) && GetConVarInt( cvar_armor ) )
	{
		SetEntProp( client, Prop_Send, g_armor_prop, GetConVarInt( cvar_armor_amount ), 1 );
	}
}
