/*
Bug Fix - Death Spit
Copyright (C) 2014  Buster "Mr. Zero" Nielsen

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/
#pragma semicolon 1
#pragma newdecls required
/* Includes */
#include <sourcemod>
#include <sdktools>
#include <left4dhooks>

/* Globals */
#define PLUGIN_VERSION "1.0"
#define CVAR_FLAGS FCVAR_NOTIFY
#define DEBUG 0
#define DEBUG_TAG "BugFix_DeathSpit"
#define MAXENTITIES 2048
#define MAXEDICTS 4096

/* Plugin Information */
public Plugin myinfo = 
{
	name		= "Bug Fix - Death Spit",
	author		= "Buster \"Mr. Zero\" Nielsen",
	description	= "Fixes the invisible spit area from killing a Spitter",
	version		= PLUGIN_VERSION,
	url			= "mrzerodk@gmail.com"
}

ConVar hPluginOn;
bool bHooked = false;

/* Plugin Functions */
public void OnPluginStart()
{
	CreateConVar("l4d2_bug_fix_death_spit_version", PLUGIN_VERSION, "Version of the Bug Fix - Death Spit plugin.", CVAR_FLAGS|FCVAR_SPONLY|FCVAR_DONTRECORD);
	hPluginOn = CreateConVar("l4d2_bug_fix_death_spit_plugin_on", "1", "Plugin On/Off.", CVAR_FLAGS);
	hPluginOn.AddChangeHook(OnConVarChanged_Allow);
	AutoExecConfig(true, "l4d2_bug_fix_death_spit");
}

public void OnConfigsExecuted()
{
	IsAllowed();
}

void OnConVarChanged_Allow(ConVar cvar, const char[] sOldValue, const char[] sNewValue)
{
	IsAllowed();
}

void IsAllowed()
{
	bool bPluginOn = hPluginOn.BoolValue;
	if(bPluginOn && !bHooked)
	{
		HookEvent("spitter_killed", SpitterKilled_Event, EventHookMode_PostNoCopy);
	}
	else if(!bPluginOn && bHooked)
	{
		UnhookEvent("spitter_killed", SpitterKilled_Event, EventHookMode_PostNoCopy);
	}
}

void SpitterKilled_Event(Event event, const char[] name, bool dontBroadcast)
{
#if DEBUG
	Debug_PrintText("Spitter Killed");
#endif
	CreateTimer(1.0, FindDeathSpit_Timer);
}

Action FindDeathSpit_Timer(Handle timer)
{
	int entity = -1;
	while ((entity = FindEntityByClassname(entity, "insect_swarm")) != -1)
	{
		int maxFlames = L4D2Direct_GetInfernoMaxFlames(entity);
		int currentFlames = GetEntProp(entity, Prop_Send, "m_fireCount");
		if (maxFlames == 2 && currentFlames == 2)
		{
			SetEntProp(entity, Prop_Send, "m_fireCount", 1);
			L4D2Direct_SetInfernoMaxFlames(entity, 1);
		}
    }
	return Plugin_Stop;
}

#if DEBUG
stock void Debug_PrintText(const char[] format, any ...)
{
	char buffer[256];
	VFormat(buffer, sizeof(buffer), format, 2);

	LogMessage(buffer);

	AdminId adminId
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && IsFakeClient(client))
		{
			adminId = GetUserAdmin(client)
			if (adminId != INVALID_ADMIN_ID && GetAdminFlag(adminId, Admin_Root))
			{
				PrintToChat(client, "[%s] %s", DEBUG_TAG, buffer);
			}
		}
	}
}
#endif
