/*
*	Explosive Chains Credit
*	Copyright (C) 2021 Silvers
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

*	Name	:	[L4D & L4D2] Explosive Chains Credit
*	Author	:	SilverShot
*	Descrp	:	Gives kill credit to who destroyed or ignited an explosive or gascan which spread to other entities.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=334655
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.3 (26-Nov-2021)
	- Removed the "m_flLastPhysicsInfluenceTime" datamap being set. Explosive delay should not occur. Thanks to "Shao" for reporting.

1.2 (07-Nov-2021)
	- Fixed physics entities becoming non-solid to last person damaging them. Thanks to "larrybrains" for reporting.

1.1 (11-Oct-2021)
	- Fixed "Callback-provided entity 12 for attacker is invalid" errors. Thanks to "Psyk0tik" for reporting.

1.0 (11-Oct-2021)
	- Initial release.

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>


#define MODEL_GASCAN		"models/props_junk/gascan001a.mdl"
#define MODEL_CRATE			"models/props_junk/explosive_box001.mdl"
#define MODEL_OXYGEN		"models/props_equipment/oxygentank01.mdl"
#define MODEL_PROPANE		"models/props_junk/propanecanister001a.mdl"


bool g_bLeft4Dead2;
int g_iWatchRemove;
int g_iOwners[2048];



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D & L4D2] Explosive Chains Credit",
	author = "SilverShot",
	description = "Gives kill credit to who destroyed or ignited an explosive or gascan which spread to other entities.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=334655"
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
	// Late Load
	char sModel[64];
	int entity;

	entity = -1;
	while( (entity = FindEntityByClassname(entity, "weapon_gascan")) != INVALID_ENT_REFERENCE )
	{
		SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamageGas);
	}

	entity = -1;
	while( (entity = FindEntityByClassname(entity, "prop_physics")) != INVALID_ENT_REFERENCE )
	{
		GetEntPropString(entity, Prop_Data, "m_ModelName", sModel, sizeof(sModel));

		if( strcmp(sModel, MODEL_GASCAN) == 0 || strcmp(sModel, MODEL_OXYGEN) == 0 || strcmp(sModel, MODEL_PROPANE) == 0 || (g_bLeft4Dead2 && strcmp(sModel, MODEL_CRATE) == 0) )
		{
			SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamageProp);
		}
	}

	entity = -1;
	while( (entity = FindEntityByClassname(entity, "physics_prop")) != INVALID_ENT_REFERENCE )
	{
		GetEntPropString(entity, Prop_Data, "m_ModelName", sModel, sizeof(sModel));

		if( strcmp(sModel, MODEL_GASCAN) == 0 || strcmp(sModel, MODEL_OXYGEN) == 0 || strcmp(sModel, MODEL_PROPANE) == 0 || (g_bLeft4Dead2 && strcmp(sModel, MODEL_CRATE) == 0) )
		{
			SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamageProp);
		}
	}

	entity = -1;
	while( (entity = FindEntityByClassname(entity, "prop_fuel_barrel")) != INVALID_ENT_REFERENCE )
	{
		SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamageProp);
	}

	entity = -1;
	while( (entity = FindEntityByClassname(entity, "prop_fuel_barrel_piece")) != INVALID_ENT_REFERENCE )
	{
		SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamageProp);
	}

	entity = -1;
	while( (entity = FindEntityByClassname(entity, "infected")) != INVALID_ENT_REFERENCE )
	{
		SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamageInfected);
	}

	entity = -1;
	while( (entity = FindEntityByClassname(entity, "witch")) != INVALID_ENT_REFERENCE )
	{
		SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamageInfected);
	}

	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) )
		{
			SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamagePlayer);
		}
	}

	// Cvars
	CreateConVar("l4d_explosive_chains_version", PLUGIN_VERSION, "Explosive Chains Credit plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
}



// ====================================================================================================
// EVENTS - ENTITY: CREATED / DESTROYED
// ====================================================================================================
public void OnEntityCreated(int entity, const char[] classname)
{
	// Explosives and fires
	if( strcmp(classname, "inferno") == 0 || strcmp(classname, "entityflame") == 0 || (g_bLeft4Dead2 && strcmp(classname, "fire_cracker_blast") == 0) )
	{
		SDKHook(entity, SDKHook_SpawnPost, OnSpawnFire);
	}
	else if( strcmp(classname, "weapon_gascan") == 0 )
	{
		SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamageGas);
	}
	else if( strcmp(classname, "prop_fuel_barrel") == 0 || strcmp(classname, "prop_fuel_barrel_piece") == 0 )
	{
		SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamageProp);
	}
	else if( strcmp(classname, "prop_physics") == 0 || strcmp(classname, "physics_prop") == 0 )
	{
		SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamageProp); // Must hook on creation since some are created and exploded in the same frame
		RequestFrame(OnFramePhysicsSpawn, EntIndexToEntRef(entity)); // Delay to get modelname and test if valid entity, otherwise unhook
	}

	// Infected
	else if( strcmp(classname, "infected") == 0 || strcmp(classname, "witch") == 0 )
	{
		SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamageInfected);
	}
}

public void OnFramePhysicsSpawn(int entity)
{
	if( EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE )
	{
		static char sModel[64];
		GetEntPropString(entity, Prop_Data, "m_ModelName", sModel, sizeof(sModel));

		if( strcmp(sModel, MODEL_GASCAN) != 0 && strcmp(sModel, MODEL_OXYGEN) != 0 && strcmp(sModel, MODEL_PROPANE) != 0 && (!g_bLeft4Dead2 || strcmp(sModel, MODEL_CRATE) != 0) )
		{
			SDKUnhook(entity, SDKHook_OnTakeDamage, OnTakeDamageProp);
		}
	}
}

public void OnEntityDestroyed(int entity)
{
	if( entity > 0 && entity < 2048 && IsValidEntity(entity) )
	{
		static char classname[32];
		GetEdictClassname(entity, classname, sizeof(classname));

		if( strcmp(classname, "weapon_gascan") == 0 || strcmp(classname, "prop_fuel_barrel") == 0 || strcmp(classname, "prop_fuel_barrel_piece") == 0 )
		{
			g_iWatchRemove = g_iOwners[entity];
		}

		if( strcmp(classname, "prop_physics") == 0 || strcmp(classname, "physics_prop") == 0 )
		{
			static char sModel[64];
			GetEntPropString(entity, Prop_Data, "m_ModelName", sModel, sizeof(sModel));

			if( strcmp(sModel, MODEL_GASCAN) == 0 || strcmp(sModel, MODEL_OXYGEN) == 0 || strcmp(sModel, MODEL_PROPANE) == 0 || (g_bLeft4Dead2 && strcmp(sModel, MODEL_CRATE) == 0) )
			{
				g_iWatchRemove = g_iOwners[entity];
			}
		}
	}
}

public void OnSpawnFire(int entity)
{
	if( g_iWatchRemove > 0 && g_iWatchRemove <= MaxClients && IsClientInGame(g_iWatchRemove) )
	{
		SetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity", g_iWatchRemove);
	}

	g_iWatchRemove = 0;
}



// ====================================================================================================
// DAMAGE HOOKS - CLIENT and COMMON
// ====================================================================================================
public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamagePlayer);
}

public Action OnTakeDamagePlayer(int entity, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if( attacker > MaxClients )
	{
		int client = g_iOwners[inflictor];
		if( client > 0 && client <= MaxClients )
		{
			if( !IsClientInGame(client) )
			{
				g_iOwners[inflictor] = 0;
				return Plugin_Continue;
			}

			attacker = client;
			return Plugin_Changed;
		}

		client = g_iOwners[attacker];
		if( client > 0 && client <= MaxClients )
		{
			if( !IsClientInGame(client) )
			{
				g_iOwners[attacker] = 0;
				return Plugin_Continue;
			}

			attacker = client;
			return Plugin_Changed;
		}
	}

	return Plugin_Continue;
}

public Action OnTakeDamageInfected(int entity, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if( attacker > MaxClients )
	{
		int client = g_iOwners[inflictor];
		if( client > 0 && client <= MaxClients )
		{
			if( !IsClientInGame(client) )
			{
				g_iOwners[inflictor] = 0;
				return Plugin_Continue;
			}

			attacker = client;
			return Plugin_Changed;
		}

		client = g_iOwners[attacker];
		if( client > 0 && client <= MaxClients )
		{
			if( !IsClientInGame(client) )
			{
				g_iOwners[attacker] = 0;
				return Plugin_Continue;
			}

			attacker = client;
			return Plugin_Changed;
		}
	}

	return Plugin_Continue;
}



// ====================================================================================================
// DAMAGE HOOKS - PROPS
// ====================================================================================================
public Action OnTakeDamageGas(int entity, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if( attacker > 0 && attacker <= MaxClients )
	{
		g_iOwners[entity] = attacker;
		SetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity", attacker);
	}
	else if( attacker > MaxClients && attacker < 2048 )
	{
		int client = g_iOwners[attacker];
		if( client > 0 && client <= MaxClients )
		{
			if( !IsClientInGame(client) )
			{
				g_iOwners[attacker] = 0;
				return Plugin_Continue;
			}

			g_iOwners[entity] = client;
			SetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity", client);
		}
	}
	else if( inflictor > MaxClients && inflictor < 2048 )
	{
		int client = g_iOwners[inflictor];
		if( client > 0 && client <= MaxClients )
		{
			if( !IsClientInGame(client) )
			{
				g_iOwners[inflictor] = 0;
				return Plugin_Continue;
			}

			g_iOwners[entity] = client;
			SetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity", client);
		}
	}

	return Plugin_Continue;
}

public Action OnTakeDamageProp(int entity, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if( attacker > 0 && attacker <= MaxClients )
	{
		g_iOwners[entity] = attacker;
		SetEntPropEnt(entity, Prop_Data, "m_hBreaker", attacker);
		SetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity", attacker);
		SetEntPropEnt(entity, Prop_Data, "m_hPhysicsAttacker", attacker);
		// SetEntPropFloat(entity, Prop_Data, "m_flLastPhysicsInfluenceTime", GetGameTime() - 0.1);
	}
	else if( attacker > MaxClients && attacker < 2048 )
	{
		int client = g_iOwners[attacker];
		if( client > 0 && client <= MaxClients )
		{
			if( !IsClientInGame(client) )
			{
				g_iOwners[attacker] = 0;
				return Plugin_Continue;
			}

			g_iOwners[entity] = client;
			SetEntPropEnt(entity, Prop_Data, "m_hBreaker", client);
			SetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity", client);
			SetEntPropEnt(entity, Prop_Data, "m_hPhysicsAttacker", client);
			// SetEntPropFloat(entity, Prop_Data, "m_flLastPhysicsInfluenceTime", GetGameTime() - 0.1);
		}
	}
	else if( inflictor > MaxClients && inflictor < 2048 )
	{
		int client = g_iOwners[inflictor];
		if( client > 0 && client <= MaxClients )
		{
			if( !IsClientInGame(client) )
			{
				g_iOwners[inflictor] = 0;
				return Plugin_Continue;
			}

			g_iOwners[entity] = client;
			SetEntPropEnt(entity, Prop_Data, "m_hBreaker", client);
			SetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity", client);
			SetEntPropEnt(entity, Prop_Data, "m_hPhysicsAttacker", client);
			// SetEntPropFloat(entity, Prop_Data, "m_flLastPhysicsInfluenceTime", GetGameTime() - 0.1);
		}
	}

	return Plugin_Continue;
}