/*
*	Tank Punch Force
*	Copyright (C) 2022 Silvers
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



#define PLUGIN_VERSION 		"2.0"

/*=======================================================================================
	Plugin Info:

*	Name	:	[L4D & L4D2] Tank Punch Force
*	Author	:	SilverShot
*	Descrp	:	Scales the Tanks punching force for standing or incapped survivors.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=320908
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

2.0 (12-Nov-2022)
	- Added cvars "l4d_tank_punch_force_forcez" and "l4d_tank_punch_force_fling" to control the z velocity and type of fling.
	- Compatibility with the "Block Stumble From Tanks" plugin by "Silvers".
	- Plugin now requires "Left 4 DHooks Direct" plugin by "Silvers".
	- Removed gamedata dependency.

1.3 (14-Nov-2021)
	- Changes to fix warnings when compiling on SourceMod 1.11.
	- Updated GameData signatures to avoid breaking when detoured by the "Left4DHooks" plugin.

1.2 (10-May-2020)
	- Added better error log message when gamedata file is missing.
	- Extra checks to prevent "IsAllowedGameMode" throwing errors.

1.1 (01-Apr-2020)
	- Fixed "IsAllowedGameMode" from throwing errors when the "_tog" cvar was changed before MapStart.

1.0 (14-Jan-2020)
	- Initial release.

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <left4dhooks>

#define CVAR_FLAGS			FCVAR_NOTIFY


ConVar g_hCvarAllow, g_hCvarMPGameMode, g_hCvarModes, g_hCvarModesOff, g_hCvarModesTog, g_hCvarFling, g_hCvarForceZ, g_hCvarForce, g_hCvarIncap;
bool g_bCvarAllow, g_bMapStarted, g_bLeft4Dead2;
float g_fCvarForce, g_fCvarForceZ, g_fCvarIncap;
int g_iCvarFling;



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D & L4D2] Tank Punch Force",
	author = "SilverShot",
	description = "Scales the Tanks punching force for standing or incapped survivors.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=320908"
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
	// ====================================================================================================
	// CVARS
	// ====================================================================================================
	g_hCvarAllow =			CreateConVar(	"l4d_tank_punch_force_allow",			"1",				"0=Plugin off, 1=Plugin on.", CVAR_FLAGS );
	g_hCvarModes =			CreateConVar(	"l4d_tank_punch_force_modes",			"",					"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS );
	g_hCvarModesOff =		CreateConVar(	"l4d_tank_punch_force_modes_off",		"",					"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS );
	g_hCvarModesTog =		CreateConVar(	"l4d_tank_punch_force_modes_tog",		"0",				"Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS );
	g_hCvarForce =			CreateConVar(	"l4d_tank_punch_force_force",			"1.0",				"Scales a Survivors velocity when punched by the Tank (_fling cvar 2) or sets the velocity (_fling cvar 1).", CVAR_FLAGS );
	g_hCvarForceZ =			CreateConVar(	"l4d_tank_punch_force_forcez",			"251.0",			"The vertical velocity a survivors is flung when punched by the Tank. Must be greater than 250 to lift a Survivor.", CVAR_FLAGS );
	g_hCvarFling =			CreateConVar(	"l4d_tank_punch_force_fling",			"1",				"The type of fling. 1=Fling with get up animation (L4D2 only). 2=Teleport player away from Tank.", CVAR_FLAGS );
	g_hCvarIncap =			CreateConVar(	"l4d_tank_punch_force_incap",			"0.0",				"Scales an Incapped Survivors velocity when punched by the Tank.", CVAR_FLAGS );
	CreateConVar(							"l4d_tank_punch_force_version",			PLUGIN_VERSION,		"Tank Punch Force plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	AutoExecConfig(true,					"l4d_tank_punch_force");

	g_hCvarMPGameMode = FindConVar("mp_gamemode");
	g_hCvarMPGameMode.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModes.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesOff.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesTog.AddChangeHook(ConVarChanged_Allow);
	g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);
	g_hCvarForce.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarFling.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarIncap.AddChangeHook(ConVarChanged_Cvars);

	IsAllowed();
}



// ====================================================================================================
//					CVARS
// ====================================================================================================
public void OnMapStart()
{
	g_bMapStarted = true;
}

public void OnMapEnd()
{
	g_bMapStarted = false;
}

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
	g_fCvarForce = g_hCvarForce.FloatValue;
	g_fCvarForceZ = g_hCvarForceZ.FloatValue;
	g_iCvarFling = g_hCvarFling.IntValue;
	g_fCvarIncap = g_hCvarIncap.FloatValue;
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
bool IsAllowedGameMode()
{
	if( g_hCvarMPGameMode == null )
		return false;

	int iCvarModesTog = g_hCvarModesTog.IntValue;
	if( iCvarModesTog != 0 )
	{
		if( g_bMapStarted == false )
			return false;

		g_iCurrentMode = 0;

		int entity = CreateEntityByName("info_gamemode");
		if( IsValidEntity(entity) )
		{
			DispatchSpawn(entity);
			HookSingleEntityOutput(entity, "OnCoop", OnGamemode, true);
			HookSingleEntityOutput(entity, "OnSurvival", OnGamemode, true);
			HookSingleEntityOutput(entity, "OnVersus", OnGamemode, true);
			HookSingleEntityOutput(entity, "OnScavenge", OnGamemode, true);
			ActivateEntity(entity);
			AcceptEntityInput(entity, "PostSpawnActivate");
			if( IsValidEntity(entity) ) // Because sometimes "PostSpawnActivate" seems to kill the ent.
				RemoveEdict(entity); // Because multiple plugins creating at once, avoid too many duplicate ents in the same frame
		}

		if( g_iCurrentMode == 0 )
			return false;

		if( !(iCvarModesTog & g_iCurrentMode) )
			return false;
	}

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

void OnGamemode(const char[] output, int caller, int activator, float delay)
{
	if( strcmp(output, "OnCoop") == 0 )
		g_iCurrentMode = 1;
	else if( strcmp(output, "OnSurvival") == 0 )
		g_iCurrentMode = 2;
	else if( strcmp(output, "OnVersus") == 0 )
		g_iCurrentMode = 4;
	else if( strcmp(output, "OnScavenge") == 0 )
		g_iCurrentMode = 8;
}



// ====================================================================================================
//					DETOUR
// ====================================================================================================
public void L4D_TankClaw_OnPlayerHit_Post(int tank, int claw, int player)
{
	OnTankClawHit(tank, player, false);
}

public void L4D_TankClaw_OnPlayerHit_PostHandled(int tank, int claw, int player)
{
	OnTankClawHit(tank, player, true);
}

void OnTankClawHit(int tank, int player, bool handled)
{
	if( g_bCvarAllow && GetClientTeam(player) == 2 )
	{
		float vPos[3], vEnd[3];
		GetClientAbsOrigin(tank, vPos);
		GetClientAbsOrigin(player, vEnd);

		if( handled ) // Stagger blocked by "Block Stumble From Tanks"
		{
			MakeVectorFromPoints(vPos, vEnd, vEnd);
			NormalizeVector(vEnd, vEnd);
			ScaleVector(vEnd, 200.0);
		}
		else 
		{
			GetEntPropVector(player, Prop_Data, "m_vecVelocity", vEnd);
		}

		if( GetEntProp(player, Prop_Send, "m_isIncapacitated", 1) )
		{
			ScaleVector(vEnd, g_fCvarIncap);
			if( g_fCvarIncap )
				vEnd[2] = g_fCvarForceZ;
		}
		else
		{
			ScaleVector(vEnd, g_fCvarForce);
			vEnd[2] = g_fCvarForceZ;
		}

		if( g_bLeft4Dead2 && g_iCvarFling == 1 && GetEntProp(player, Prop_Send, "m_isIncapacitated") == 0 )
			L4D2_CTerrorPlayer_Fling(player, tank, vEnd);
		else
			TeleportEntity(player, NULL_VECTOR, NULL_VECTOR, vEnd);
	}
}