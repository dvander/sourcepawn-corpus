/**
 * vim: set ts=4 :
 * =============================================================================
 * [TF2] Block Building Pickups
 * Don't allow players to pick up and move buildings
 *
 * [TF2] Block Building Pickups (C)2014 Powerlord (Ross Bemrose).
 * All rights reserved.
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
#include <tf2items>
#pragma semicolon 1

#define VERSION "1.0.0"

#define EUREKA_EFFECT_INDEX 589
new Handle:g_Cvar_Enabled;

public Plugin:myinfo = {
	name			= "[TF2] Block Building Pickups",
	author			= "Powerlord",
	description		= "Don't allow players to pick up and move buildings",
	version			= VERSION,
	url				= ""
};

public OnPluginStart()
{
	CreateConVar("tf2_blockbuildingpickup_version", VERSION, "[TF2] Block Building Pickups version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_SPONLY);
	g_Cvar_Enabled = CreateConVar("tf2_blockbuildingpickup_enable", "1", "Enable [TF2] Block Building Pickups?", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD, true, 0.0, true, 1.0);
	
}

public Action:TF2Items_OnGiveNamedItem(client, String:classname[], iItemDefinitionIndex, &Handle:hItem)
{
	// routine method to close unused handle
	static Handle:item;
	if (item != INVALID_HANDLE)
	{
		CloseHandle(item);
		item = INVALID_HANDLE;
	}
	
	// Are we enabled?
	if (!GetConVarBool(g_Cvar_Enabled))
	{
		return Plugin_Continue;
	}
	
	// Only work on wrenches that aren't the Eureka Effect
	if ((StrEqual(classname, "tf_weapon_wrench") || StrEqual(classname, "tf_weapon_robot_arm")) && iItemDefinitionIndex != EUREKA_EFFECT_INDEX)
	{
		// Keep existing attributes and add a new one
		item = TF2Items_CreateItem(PRESERVE_ATTRIBUTES|OVERRIDE_ATTRIBUTES);
		TF2Items_SetNumAttributes(item, 1);
		TF2Items_SetAttribute(item, 0, 353, 1.0);
		
		hItem = item;
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}