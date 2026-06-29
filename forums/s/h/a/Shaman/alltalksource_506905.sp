/*
alltalksource.sp
AllTalk: Source Base Plugin - This file is needed to run AllTalk: Source
This plugin is coded by Alican "AlicanC" Çubukçuoðlu (alicancubukcuoglu@gmail.com)
Copyright (C) 2007 Alican Çubukçuoðlu
*/
/*
Plugin Change Log

v0.0.1a
Files included:
	scripting/alltalksource.sp
Added files:
	First release
Changed files:
	First release
Removed files:
	First release
Release notes:
	First Release
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

//#define DEBUG

#define PLUGIN_DESCRIPTION "AllTalk: Source Base Plugin"
#define PLUGIN_VERSION "0.0.1a"

//|||||||Create Variables
//||||||Handles
//||||CVar's
new Handle:sm_alltalksource_enabled;
new Handle:sm_alltalksource_notify;
new Handle:sv_alltalk;

public Plugin:myinfo=
	{
	name= "AllTalk: Source Base Plugin",
	author= "Alican 'AlicanC' Çubukçuoðlu",
	description= PLUGIN_DESCRIPTION,
	version= PLUGIN_VERSION,
	url= "http://www.sourcemod.net/"
	}

public OnPluginStart()
	{
	//||||||||Create Version CVar
	CreateConVar("alltalksource_version", PLUGIN_VERSION, "AllTalk: Source Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	//||||||||CVars
	//||||Main CVars
	sm_alltalksource_enabled= CreateConVar("sm_alltalksource_enable", "1", "Enable/Disable AllTalk: Source.", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	sm_alltalksource_notify= CreateConVar("sm_alltalksource_notify", "1", "AllTalk: Source notify players when sv_alltalk changed.", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	//
	sv_alltalk= FindConVar("sv_alltalk");
	
	//Event Hooks
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
	}

//||||||||||||||||||||EVENTS

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
	{
	if(!GetConVarBool(sm_alltalksource_enabled))
		return;
	if(GetConVarBool(sv_alltalk))
		SetConVarBool(sv_alltalk, false, false, GetConVarBool(sm_alltalksource_notify));
	}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
	{
	if(!GetConVarBool(sm_alltalksource_enabled))
		return;
	if(!GetConVarBool(sv_alltalk))
		SetConVarBool(sv_alltalk, true, false, GetConVarBool(sm_alltalksource_notify));
	}