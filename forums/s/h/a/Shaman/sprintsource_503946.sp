/*
sprintsource.sp
Sprint: Source Plugin - This file is needed to run Sprint: Source
This plugin is coded by Alican "AlicanC" Çubukçuoğlu (alicancubukcuoglu@gmail.com)
Copyright (C) 2007 Alican Çubukçuoğlu
*/
/*
Plugin Change Log

v0.0.1b
Files included:
	scripting/sprintsource.sp
	translations/sprintsource.base.txt
Added files:
	None
Changed files:
	scripting/sprintsource.sp
Release Notes:
	None
Changes:
	Removed annoying message at round start.

v0.0.1a
Files included:
	scripting/sprintsource.sp
	translations/sprintsource.base.txt
Added files:
	First release
Changed files:
	First release
Release Notes:
	First release
Changes:
	First release
*/
/*
This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
*/

#pragma semicolon 1

//||||||Includes (These files must be in your "includes" directory to compile.)
#include <sourcemod>

#define PLUGIN_DESCRIPTION "Sprint: Source Plugin"
#define PLUGIN_VERSION "0.0.1a"

#define YELLOW 0x01
#define NAME_TEAMCOLOR 0x02
#define TEAMCOLOR 0x03
#define GREEN 0x04

//|||||||Create Variables
//||||||Handles
//||||CVar's
new Handle:sm_sprintsource_enabled;
new Handle:sm_sprintsource_time;
new Handle:sm_sprintsource_cooldown;
new Handle:sm_sprintsource_sprintspeed;
//||||KeyValues
//new Handle:kv;
//||||||Client Variables
new bool:client_connected[MAXPLAYERS+1];
new bool:client_sprintusing[MAXPLAYERS+1];
new bool:client_sprintcool[MAXPLAYERS+1];

public Plugin:myinfo =
	{
	name = "Sprint: Source Plugin",
	author = "Alican 'AlicanC' Çubukçuoğlu",
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
	}

public OnPluginStart()
	{
	//||||||||Load Translations
	LoadTranslations("plugin.sprintsource.base");
	
	//||||||||Create Version CVar
	CreateConVar("sprintsource_version", PLUGIN_VERSION, "Sprint: Source Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	//||||||||CVars
	sm_sprintsource_enabled= CreateConVar("sm_sprintsource_enable", "1", "Enable/Disable Sprint: Source.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	sm_sprintsource_time= CreateConVar("sm_sprintsource_time", "3", "Sprint: Source sprint time.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	sm_sprintsource_cooldown= CreateConVar("sm_sprintsource_cooldown", "10", "Sprint: Source sprint cooldown time.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	sm_sprintsource_sprintspeed= CreateConVar("sm_sprintsource_sprintspeed", "2", "Sprint: Source sprint speed.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	
	//Event Hooks
	HookEvent("round_start", Event_RoundStart);
	
	//Commands
	//RegAdminCmd("sm_sprint_take", Cmd_TakeSprint, ADMFLAG_GENERIC);
	//RegAdminCmd("sm_sprint_give", Cmd_GiveSprint, ADMFLAG_GENERIC);
	RegConsoleCmd("ss_sprint", Cmd_StartSprint);
	}

//||||||||||||||||||||EVENTS

public OnClientPutInServer(client)
	{
	if(!GetConVarBool(sm_sprintsource_enabled))
		return;
	//
	client_connected[client]= true;
	//
	Skill_Sprint_Reset(client);
	//
	PrintToChat(client, "%c[Sprint: Source]%c %t", GREEN, YELLOW, "SprintSource Running", PLUGIN_VERSION);
	PrintToChat(client, "%c[Sprint: Source]%c %t", GREEN, YELLOW, "SprintSource Command");
	//
	return;
	}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
	{
	if(!GetConVarBool(sm_sprintsource_enabled))
		return;
	//Get clients
	new clients= GetMaxClients();		
	//
	for(new client= 1; client<=clients; client++)
		{
		//
		if(IsClientInGame(client))
			{
			Skill_Sprint_Reset(client);
			PrintToChat(client, "%c[Sprint: Source]%c %t", GREEN, YELLOW, "SprintSource Command");
			}
		}
	}

public Skill_Sprint_Reset(client)
	{
	SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0);
	client_sprintusing[client]=false;
	client_sprintcool[client]=true;
	}

public Action:Cmd_StartSprint(client, args)
	{
	if(!GetConVarBool(sm_sprintsource_enabled))
		return;
	if(client_sprintusing[client])
		{
		return;
		}
	if(!client_sprintcool[client])
		{
		return;
		}
	client_sprintusing[client]=true;
	client_sprintcool[client]=false;
	SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", GetConVarFloat(sm_sprintsource_sprintspeed));
	PrintToChat(client, "%c[Sprint: Source]%c %t", GREEN, YELLOW, "SprintSource Start");
	CreateTimer(GetConVarFloat(sm_sprintsource_time), Timer_SprintEnd, client);
	}

public Action:Timer_SprintEnd(Handle:timer, any:client)
	{
	SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0);
	if(!client_sprintusing[client])
		{
		return;
		}
	client_sprintusing[client]=false;
	PrintToChat(client, "%c[Sprint: Source]%c %t", GREEN, YELLOW, "SprintSource End");
	CreateTimer(GetConVarFloat(sm_sprintsource_cooldown), Timer_SprintCooldown, client);
	}

public Action:Timer_SprintCooldown(Handle:timer, any:client)
	{
	if(client_sprintcool[client])
		{
		return;
		}
	client_sprintcool[client]=true;
	PrintToChat(client, "%c[Sprint: Source]%c %t", GREEN, YELLOW, "SprintSource Cool");
	}