/**
 * vim: set ts=4 :
 * =============================================================================
 * Horsemann Health Bar
 * Give the Horseless Headless Horsemann the Monoculus health bar.
 *
 * Horsemann Health Bar (C)2012-2014 Powerlord (Ross Bemrose).
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
#include <sdkhooks>

#pragma semicolon 1

#define VERSION "1.4.1"

#define RESOURCE 				"monster_resource"
#define RESOURCE_PROP			"m_iBossHealthPercentageByte"
#define HEALTHBAR_MAX			255.0
#define HORSEMANN 				"headless_hatman"
#define HEALTH_MAP				"m_iHealth"
#define MAXHEALTH_MAP			"m_iMaxHealth"

public Plugin:myinfo = 
{
	name = "Horsemann Health Bar",
	author = "Powerlord",
	description = "Give the Horseless Headless Horsemann the Monoculus health bar",
	version = VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=188543"
}

new Handle:g_Cvar_Enabled = INVALID_HANDLE;
new g_HealthBar = -1;

new Handle:g_hHorsemen;

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	if (GetEngineVersion() != Engine_TF2)
	{
		strcopy(error, err_max, "Plugin only works on Team Fortress 2.");
		return APLRes_Failure;
	}
	
	return APLRes_Success;
}

public OnPluginStart()
{
	CreateConVar("horsemann_healthbar_version", VERSION, "Horsemann Healthbar Version", FCVAR_DONTRECORD | FCVAR_NOTIFY | FCVAR_PLUGIN);
	g_Cvar_Enabled = CreateConVar("horsemann_healthbar_enabled", "1", "Enabled Horsemann Healthbar?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(g_Cvar_Enabled, Cvar_Enabled);
	
	g_hHorsemen = CreateArray();
}

public Cvar_Enabled(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (!GetConVarBool(convar))
	{
		SetHealthBar(0.0);
	}
}

public OnEntityCreated(entity, const String:classname[])
{
	if (StrEqual(classname, RESOURCE))
	{
		g_HealthBar = EntIndexToEntRef(entity);
	}
	else
	if (StrEqual(classname, HORSEMANN))
	{
		SDKHook(entity, SDKHook_SpawnPost, HorsemannSpawned);
		SDKHook(entity, SDKHook_OnTakeDamagePost, HorsemannDamaged);
	}
}

public OnEntityDestroyed(entity)
{
	if (entity == EntRefToEntIndex(g_HealthBar))
	{
		g_HealthBar = INVALID_ENT_REFERENCE;
	}
	else
	{
		new pos = FindValueInArray(g_hHorsemen, entity);
		if (pos > -1)
		{
			RemoveFromArray(g_hHorsemen, pos);
			if (GetConVarBool(g_Cvar_Enabled))
			{
				SetHealthBar(0.0);
			}
		}
	}
}

public HorsemannSpawned(entity)
{
	if (!GetConVarBool(g_Cvar_Enabled))
	{
		return;
	}
	
	PushArrayCell(g_hHorsemen, entity);
	
	SetHealthBar(100.0);
}

public HorsemannDamaged(victim, attacker, inflictor, Float:damage, damagetype, weapon, const Float:damageForce[3], const Float:damagePosition[3])
{
	if (!GetConVarBool(g_Cvar_Enabled) || victim < 0 || !IsValidEntity(victim))
	{
		return;
	}
	
	new health = GetEntProp(victim, Prop_Data, HEALTH_MAP);
	new maxHealth = GetEntProp(victim, Prop_Data, MAXHEALTH_MAP);
	
	new Float:newPercent = float(health) / float(maxHealth) * 100.0;
	SetHealthBar(newPercent);
}

SetHealthBar(Float:percent)
{
	new healthBar = EntRefToEntIndex(g_HealthBar);
	if (healthBar == INVALID_ENT_REFERENCE || !IsValidEntity(healthBar))
	{
		return;
	}
	// In practice, the multiplier is 2.55
	new Float:value = percent * (HEALTHBAR_MAX / 100.0);

	SetEntProp(healthBar, Prop_Send, RESOURCE_PROP, RoundToNearest(value));
}
