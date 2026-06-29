/*
buyitdammitsource.sp
Plant and Run: Source
This plugin is coded by Alican "AlicanC" Çubukçuoðlu (alicancubukcuoglu@gmail.com)
Copyright (C) 2007 Alican Çubukçuoðlu
*/
/*
Plugin Change Log (N: New, C: Changed, S: Same, R: Removed)

v0.0.1
Files included:
	N|scripting/buyitdammitsource.sp
Release Notes:
	SStocks is needed to compile this plugin.
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

#include <sourcemod>
#include <sdktools>
#include <sstocks>

#define PLUGIN_VERSION "0.0.1"

public Plugin:myinfo=
	{
	name= "Buy it, dammit!: Source",
	author= "Alican 'AlicanC' Çubukçuoðlu",
	description= "Removes all weapons on the floor on round start.",
	version= PLUGIN_VERSION,
	url= "http://www.sourcemod.net/"
	}

public OnPluginStart()
	{
	//||||||||Create Version CVar
	CreateConVar("buyitdammitsource_version", PLUGIN_VERSION, "Buy it, dammit!: Source Version", FCVAR_PLUGIN|FCVAR_SPONLY);
	
	//||||||||CVars
	CreateConVar("buyitdammitsource_enable", "1", "Enable/Disable Buy it, dammit!: Source.", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);

	//||||||||Hooks
	HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
	}

//||||||||||||||||||||EVENTS

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
	{
	if(!Running()){return;}
	//Remove all weapons
	RemoveAllWeapons();
	}

//||||||||||||||||||||FUNCTIONS

public Running()
	{
	return GetConVarBool(FindConVar("buyitdammitsource_enable"));
	}