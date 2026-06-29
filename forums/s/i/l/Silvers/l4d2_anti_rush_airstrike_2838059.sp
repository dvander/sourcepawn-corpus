/*
*	Anti Rush - Airstrike
*	Copyright (C) 2025 Silvers
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

*	Name	:	[L4D2] Anti Rush - Airstrike
*	Author	:	SilverShot
*	Descrp	:	Calls an Airstrike on a player who is rushing or slacking.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=351249
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.0 (01-Jul-2025)
	- Initial release.

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#define CVAR_FLAGS			FCVAR_NOTIFY
#define TYPE_SLACK			(1 << 0)
#define TYPE_RUSH			(1 << 1)
#define TYPE_WARN			(1 << 2)
#define TYPE_PUNISH			(1 << 3)

#include <sourcemod>
#include <sdktools>

native void F18_ShowAirstrike(float origin[3], float direction);

ConVar g_hCvarAllow, g_hCvarMPGameMode, g_hCvarModes, g_hCvarModesOff, g_hCvarModesTog, g_hCvarTime, g_hCvarType;
bool g_bCvarAllow, g_bMapStarted, g_bPluginAirstrike, g_bPluginAntiRush;
int g_iCvarType;
float g_fCvarTime;
float g_fTiming[MAXPLAYERS+1];



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D & L4D2] Anti Rush - Airstrike",
	author = "SilverShot",
	description = "Calls an Airstrike on a player who is rushing or slacking.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=351249"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();

	if( test != Engine_Left4Dead2 )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}

	return APLRes_Success;
}

public void OnAllPluginsLoaded()
{
	if( !g_bPluginAirstrike )
	{
		if( LibraryExists("l4d2_airstrike") == false )
			LogError("\n==========\nThis plugin requires the \"F-18 Airstrike\" plugin, please install: https://forums.alliedmods.net/showthread.php?t=187567\n==========\n");
		else
			g_bPluginAirstrike = true;
	}

	if( !g_bPluginAntiRush )
	{
		if( LibraryExists("l4d_anti_rush") == false )
			LogError("\n==========\nThis plugin requires the \"Anti Rush\" plugin version 1.25 or newer, please install: https://forums.alliedmods.net/showthread.php?t=322392\n==========\n");
		else
			g_bPluginAirstrike = true;
	}
}

public void OnLibraryAdded(const char[] name)
{
	if( strcmp(name, "l4d2_airstrike") == 0 )
		g_bPluginAirstrike = true;
	else if( strcmp(name, "l4d_anti_rush") == 0 )
		g_bPluginAntiRush = true;
}

public void OnLibraryRemoved(const char[] name)
{
	if( strcmp(name, "l4d2_airstrike") == 0 )
		g_bPluginAirstrike = false;
	else if( strcmp(name, "l4d_anti_rush") == 0 )
		g_bPluginAntiRush = false;
}

public void OnPluginStart()
{
	g_hCvarAllow =		CreateConVar(	"l4d_anti_rush_airstrike_allow",			"1",							"0=Plugin off, 1=Plugin on.", CVAR_FLAGS );
	g_hCvarModes =		CreateConVar(	"l4d_anti_rush_airstrike_modes",			"",								"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS );
	g_hCvarModesOff =	CreateConVar(	"l4d_anti_rush_airstrike_modes_off",		"",								"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS );
	g_hCvarModesTog =	CreateConVar(	"l4d_anti_rush_airstrike_modes_tog",		"0",							"Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS );
	g_hCvarTime =		CreateConVar(	"l4d_anti_rush_airstrike_time",				"10.0",							"How many seconds delay between multiple Airstrikes per player.", CVAR_FLAGS );
	g_hCvarType =		CreateConVar(	"l4d_anti_rush_airstrike_type",				"11",							"When to call an airstrike on a player: 1=Slacking, 2=Rushing, 4=Warning, 8=Punished. Add numbers together.", CVAR_FLAGS );
	CreateConVar(						"l4d_anti_rush_airstrike_version",			PLUGIN_VERSION,					"Anti Rush - Airstrike plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	AutoExecConfig(true,				"l4d_anti_rush_airstrike");

	g_hCvarMPGameMode = FindConVar("mp_gamemode");
	g_hCvarMPGameMode.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModes.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesOff.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesTog.AddChangeHook(ConVarChanged_Allow);
	g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);
	g_hCvarTime.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarType.AddChangeHook(ConVarChanged_Cvars);
}

public void Anti_Rush_Trigger(int client, bool rushing, int punishment)
{
	// Air strike plugin, this plugin enabled, punishment is not set to teleport
	if( g_bPluginAirstrike && g_bCvarAllow && punishment != 2 )
	{
		// Rushing or slacking mode enabled
		if( rushing ? g_iCvarType & TYPE_RUSH : g_iCvarType & TYPE_SLACK )
		{
			// Punishment or warning mode enabled
			if( punishment ? g_iCvarType & TYPE_PUNISH : g_iCvarType & TYPE_WARN )
			{
				if( g_fTiming[client] < GetGameTime() )
				{
					g_fTiming[client] = GetGameTime() + g_fCvarTime;

					float vPos[3], vAng[3];
					GetClientAbsOrigin(client, vPos);
					GetClientEyeAngles(client, vAng);
					F18_ShowAirstrike(vPos, vAng[1]);
				}
			}
		}
	}
}



// ====================================================================================================
//					CVARS
// ====================================================================================================
public void OnConfigsExecuted()
{
	IsAllowed();
}

public void OnMapStart()
{
	g_bMapStarted = true;
}

public void OnMapEnd()
{
	g_bMapStarted = false;

	ResetPlugin();
}

void ResetPlugin()
{
	for( int i = 1; i <= MaxClients; i++ )
	{
		g_fTiming[i] = 0.0;
	}
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
	g_fCvarTime = g_hCvarTime.FloatValue;
	g_iCvarType = g_hCvarType.IntValue;
}

void IsAllowed()
{
	bool bAllowCvar = g_hCvarAllow.BoolValue;
	bool bAllowMode = IsAllowedGameMode();
	GetCvars();

	if( g_bCvarAllow == false && bAllowCvar == true && bAllowMode == true )
	{
		g_bCvarAllow = true;
	}

	else if( g_bCvarAllow == true && (bAllowCvar == false || bAllowMode == false) )
	{
		g_bCvarAllow = false;
		ResetPlugin();
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