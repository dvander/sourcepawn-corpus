/*
*	Tank Rock Pops Explosives
*	Copyright (C) 2023 Silvers
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



#define PLUGIN_VERSION 		"1.0"

/*======================================================================================
	Plugin Info:

*	Name	:	[L4D & L4D2] Tank Rock Pops Explosives
*	Author	:	SilverShot
*	Descrp	:	Allows the Tanks thrown rock to pop explosives.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=343302
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.0 (10-Jul-2023)
	- Initial release.

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <left4dhooks>

#define CVAR_FLAGS			FCVAR_NOTIFY

#define MODEL_CRATE			"models/props_junk/explosive_box001.mdl"
#define MODEL_OXYGEN		"models/props_equipment/oxygentank01.mdl"
#define MODEL_PROPANE		"models/props_junk/propanecanister001a.mdl"


ConVar g_hCvarAllow, g_hCvarMPGameMode, g_hCvarModes, g_hCvarModesOff, g_hCvarModesTog, g_hCvarObjects;
bool g_bCvarAllow, g_bLeft4Dead2;
int g_iCvarObjects;

// Testing:
/*
sm_v; jointeam 3; z_spawn tank;
z_spawn boomer; sm_freeze boomer 9999; sm_sethealth boomer 1
// */



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D & L4D2] Tank Rock Pops Explosives",
	author = "SilverShot",
	description = "Allows the Tanks thrown rock to pop explosives.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=343302"
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
	g_hCvarAllow =		CreateConVar(	"l4d_tank_rock_pops_allow",			"1",			"0=Plugin off, 1=Plugin on.", CVAR_FLAGS );
	g_hCvarModes =		CreateConVar(	"l4d_tank_rock_pops_modes",			"",				"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS );
	g_hCvarModesOff =	CreateConVar(	"l4d_tank_rock_pops_modes_off",		"",				"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS );
	g_hCvarModesTog =	CreateConVar(	"l4d_tank_rock_pops_modes_tog",		"0",			"Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS );
	g_hCvarObjects =	CreateConVar(	"l4d_tank_rock_pops_objects",		"31",			"Which entities can explode: 1=GasCan, 2=Oxygen Tank, 4=Propane Tank, 8=Firework Crate, 16=Fuel Barrel, 31=All. Add numbers together.", CVAR_FLAGS );
	CreateConVar(						"l4d_tank_rock_pops_version",		PLUGIN_VERSION, "Tank Rock Pops Explosives plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	AutoExecConfig(true,				"l4d_tank_rock_pops");

	g_hCvarMPGameMode = FindConVar("mp_gamemode");
	g_hCvarMPGameMode.AddChangeHook(ConVarChanged_Allow);
	g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModes.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesOff.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesTog.AddChangeHook(ConVarChanged_Allow);
	g_hCvarObjects.AddChangeHook(ConVarChanged_Cvars);
}

public void OnAllPluginsLoaded()
{
	if( Left4DHooks_Version() < 1134 ) // Forwards "L4D_TankRock_BounceTouch*" were only added in 1.134
	{
		SetFailState("This plugin requires \"Left 4 DHooks\" version 1.134 or newer. Please update.");
	}
}



// ====================================================================================================
//					CVARS
// ====================================================================================================
public void OnConfigsExecuted()
{
	IsAllowed();
}

void ConVarChanged_Allow(Handle convar, const char[] oldValue, const char[] newValue)
{
	IsAllowed();
}

void ConVarChanged_Cvars(Handle convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_iCvarObjects = g_hCvarObjects.IntValue;
}

void IsAllowed()
{
	bool bCvarAllow = g_hCvarAllow.BoolValue;
	bool bAllowMode = IsAllowedGameMode();
	GetCvars();

	if( g_bCvarAllow == false && bCvarAllow == true && bAllowMode == true )
	{
		g_bCvarAllow = true;
	}

	else if( g_bCvarAllow == true && (bCvarAllow == false || bAllowMode == false) )
	{
		g_bCvarAllow = false;
	}
}

int g_iCurrentMode;
public void L4D_OnGameModeChange(int gamemode)
{
	g_iCurrentMode = gamemode;
}

bool IsAllowedGameMode()
{
	if( g_hCvarMPGameMode == null )
		return false;

	if( g_iCurrentMode == 0 ) g_iCurrentMode = L4D_GetGameModeType();

	int iCvarModesTog = g_hCvarModesTog.IntValue;

	if( iCvarModesTog && !(iCvarModesTog & g_iCurrentMode) )
		return false;

	char sGameModes[64], sGameMode[64];
	g_hCvarMPGameMode.GetString(sGameMode, sizeof(sGameMode));
	Format(sGameMode, sizeof(sGameMode), ",%s,", sGameMode);

	g_hCvarModes.GetString(sGameModes, sizeof(sGameModes));
	if( sGameModes[0] )
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if( StrContains(sGameModes, sGameMode, false) == -1 )
			return false;
	}

	g_hCvarModesOff.GetString(sGameModes, sizeof(sGameModes));
	if( sGameModes[0] )
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if( StrContains(sGameModes, sGameMode, false) != -1 )
			return false;
	}

	return true;
}



// ====================================================================================================
//					POP
// ====================================================================================================
public Action L4D_TankRock_BounceTouch(int tank, int rock, int entity)
{
	if( g_bCvarAllow && entity > MaxClients )
	{
		static char sTemp[45];
		GetEdictClassname(entity, sTemp, sizeof(sTemp));

		if( g_iCvarObjects & 1 && strcmp(sTemp, "weapon_gascan") == 0 )
		{
			DetonateExplosive(entity, tank);
		}
		else if( strcmp(sTemp, "prop_physics") == 0 )
		{
			GetEntPropString(entity, Prop_Data, "m_ModelName", sTemp, sizeof(sTemp));

			if( g_bLeft4Dead2 && g_iCvarObjects & 8 && strcmp(sTemp, MODEL_CRATE) == 0 ) // Firework crate
			{
				DetonateExplosive(entity, tank);
			}
			else if( g_iCvarObjects & 2 && strcmp(sTemp, MODEL_OXYGEN) == 0 ) // Oxygen
			{
				DetonateExplosive(entity, tank);
			}
			else if( g_iCvarObjects & 4 && strcmp(sTemp, MODEL_PROPANE) == 0 ) // Propane
			{
				DetonateExplosive(entity, tank);
			}
		}
		else if( g_iCvarObjects & 16 && strcmp(sTemp, "prop_fuel_barrel") == 0 )
		{
			DetonateExplosive(entity, tank);
		}
	}

	return Plugin_Continue;
}

void DetonateExplosive(int entity, int tank)
{
	SDKHooks_TakeDamage(entity, tank, tank, 99999.9, DMG_BULLET);
}