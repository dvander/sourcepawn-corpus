/*
 * Copyright (C) 2021  Mikusch
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

#include <sourcemod>
#include <memorypatch>

#pragma semicolon 1
#pragma newdecls required

ConVar tf_allclass_air_dash;
MemoryPatch g_MemoryPatchCanAirDashClassCheck;

public Plugin myinfo = 
{
	name = "[TF2] All-Class Air Dash",
	author = "Mikusch",
	description = "Enables all classes to perform air dashes (double jumps)",
	version = "1.2.0",
	url = "https://github.com/Mikusch/allclass-air-dash"
}

public void OnPluginStart()
{
	if (GetEngineVersion() != Engine_TF2)
		SetFailState("This plugin is only compatible with Team Fortress 2");
	
	tf_allclass_air_dash = CreateConVar("tf_allclass_air_dash", "1", "When set to 1, enables all classes to perform air dashes");
	tf_allclass_air_dash.AddChangeHook(OnConVarChanged);
	
	GameData gamedata = new GameData("allclass-air-dash");
	if (gamedata == null)
		SetFailState("Could not find allclass-air-dash gamedata");
	
	MemoryPatch.SetGameData(gamedata);
	CreateMemoryPatch(g_MemoryPatchCanAirDashClassCheck, "MemoryPatch_CanAirDashClassCheck");
	
	delete gamedata;
}

public void OnPluginEnd()
{
	if (g_MemoryPatchCanAirDashClassCheck)
		g_MemoryPatchCanAirDashClassCheck.Disable();
}

public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (g_MemoryPatchCanAirDashClassCheck)
	{
		if (convar.BoolValue)
			g_MemoryPatchCanAirDashClassCheck.Enable();
		else
			g_MemoryPatchCanAirDashClassCheck.Disable();
	}
}

void CreateMemoryPatch(MemoryPatch &handle, const char[] name)
{
	handle = new MemoryPatch(name);
	if (handle)
		handle.Enable();
	else
		LogError("Failed to create memory patch: %s", name);
}
