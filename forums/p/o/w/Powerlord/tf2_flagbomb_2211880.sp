/**
 * vim: set ts=4 :
 * =============================================================================
 * TF2 Flags to Bombs
 * Turn item_teamflags into MvM Bombs.
 *
 * TF2 Flags to Bombs (C)2014 Powerlord (Ross Bemrose).  All rights reserved.
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
 * Version: 1.0.0
 */
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#pragma semicolon 1

#define VERSION "1.0.0"

new const String:BRIEFCASE_MODEL[] = "models/flag/briefcase.mdl";
new const String:BOMB_MODEL[] = "models/props_td/atom_bomb.mdl";
new Handle:g_Cvar_Enabled;

public Plugin:myinfo = {
	name			= "TF2 Flags to Bombs",
	author			= "Powerlord",
	description		= "Turn item_teamflags into MvM Bombs.",
	version			= VERSION,
	url				= ""
};

public OnPluginStart()
{
	CreateConVar("tf2_flagstobombs_version", VERSION, "TF2 Flags to Bombs version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_SPONLY);
	g_Cvar_Enabled = CreateConVar("tf2_flagstobombs_enable", "1", "Enable TF2 Flags to Bombs?", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD, true, 0.0, true, 1.0);
	
}

public OnEntityCreated(entity, const String:classname[])
{
	if (GetConVarBool(g_Cvar_Enabled) && StrEqual(classname, "item_teamflag"))
	{
		SDKHook(entity, SDKHook_Spawn, FlagSpawn);
	}
}

public Action:FlagSpawn(entity)
{
	new String:model[PLATFORM_MAX_PATH];
	GetEntPropString(entity, Prop_Data, "m_iszModel", model, sizeof(model));
	if (model[0] == '\0' || StrEqual(model, BRIEFCASE_MODEL))
	{
		DispatchKeyValue(entity, "flag_model", BOMB_MODEL);
	}
	
	return Plugin_Continue;
}
