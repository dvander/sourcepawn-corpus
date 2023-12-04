/*
*	Car Alarm - Bots Block
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



#define PLUGIN_VERSION 		"1.6"

/*======================================================================================
	Plugin Info:

*	Name	:	[L4D] Car Alarm - Bots Block
*	Author	:	SilverShot
*	Descrp	:	Blocks the car alarm when bots shoot the vehicle or stand on it.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=319513
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.6 (07-Nov-2023)
	- Fixed not deleting 1 handle on plugin start.

1.5 (11-Dec-2022)
	- Changes to fix compile warnings on SourceMod 1.11.

1.4 (28-Jul-2021)
	- Fixed errors on Linux. Thanks to "ReCreator" for reporting.
	- Removed DHooks requirement. Plugin will use some more processing resources.
	- Thanks to "Lux", "nosoop", "Crasher_3637" and "asherkin" for help trying to fix the detour method.
	- Would prefer to use detour method if that worked.
	- GameData file and plugin updated.

1.3a (23-Jul-2021)
	- Fixed the signature being broken on Linux. Thanks to "ReCreator" for reporting.

1.3 (30-Sep-2020)
	- Fixed compile errors on SM 1.11.

1.2 (10-May-2020)
	- Added better error log message when gamedata file is missing.
	- Extra checks to prevent "IsAllowedGameMode" throwing errors.
	- Fixed the plugin not following the allow cvar.
	- Various changes to tidy up code.

1.1 (01-Apr-2020)
	- Fixed "IsAllowedGameMode" from throwing errors when the "_tog" cvar was changed before MapStart.

1.0 (05-Nov-2019)
	- Initial release.

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
// #include <dhooks> // DETOUR METHOD

#define CVAR_FLAGS			FCVAR_NOTIFY
#define GAMEDATA			"l4d_car_alarm_bots"


ConVar g_hCvarAllow, g_hCvarMPGameMode, g_hCvarModes, g_hCvarModesOff, g_hCvarModesTog, g_hCvarType;
bool g_bCvarAllow, g_bMapStarted;
int g_iCvarType, g_iOffset;
// float g_fLastDmg; // DETOUR METHOD

enum
{
	TYPE_SHOOT = (1<<0),
	TYPE_STAND = (1<<1)
}



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D] Car Alarm - Bots Block",
	author = "SilverShot",
	description = "Sets off the car alarm when bots shoot the vehicle or stand on it.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=319513"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if( test != Engine_Left4Dead )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	// ====================================================================================================
	// DETOUR
	// ====================================================================================================
	/*
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "gamedata/%s.txt", GAMEDATA);
	if( FileExists(sPath) == false ) SetFailState("\n==========\nMissing required file: \"%s\".\nRead installation instructions again.\n==========", sPath);

	Handle hGameData = LoadGameConfigFile(GAMEDATA);
	if( hGameData == null ) SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);

	Handle hDetour = DHookCreateFromConf(hGameData, "InputSurvivorStandingOnCar");
	delete hGameData;

	if( !hDetour )
		SetFailState("Failed to find \"CCarProp::InputSurvivorStandingOnCar\" signature.");

	if( !DHookEnableDetour(hDetour, false, InputSurvivorStandingOnCar) )
		SetFailState("Failed to detour \"CCarProp::InputSurvivorStandingOnCar\".");

	delete hDetour;
	*/



	// ====================================================================================================
	// OFFSET
	// ====================================================================================================
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "gamedata/%s.txt", GAMEDATA);
	if( FileExists(sPath) == false ) SetFailState("\n==========\nMissing required file: \"%s\".\nRead installation instructions again.\n==========", sPath);

	Handle hGameData = LoadGameConfigFile(GAMEDATA);
	if( hGameData == null ) SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);

	g_iOffset = GameConfGetOffset(hGameData, "Alarm_Patch_Offset");
	if( g_iOffset == -1 ) SetFailState("\n==========\nMissing required offset: \"Alarm_Patch_Offset\".\nPlease update your GameData file for this plugin.\n==========");

	delete hGameData;



	// ====================================================================================================
	// CVARS
	// ====================================================================================================
	g_hCvarAllow =			CreateConVar(	"l4d_car_alarm_bots_allow",			"1",				"0=Plugin off, 1=Plugin on.", CVAR_FLAGS );
	g_hCvarModes =			CreateConVar(	"l4d_car_alarm_bots_modes",			"",					"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS );
	g_hCvarModesOff =		CreateConVar(	"l4d_car_alarm_bots_modes_off",		"",					"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS );
	g_hCvarModesTog =		CreateConVar(	"l4d_car_alarm_bots_modes_tog",		"0",				"Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS );
	g_hCvarType =			CreateConVar(	"l4d_car_alarm_bots_type",			"3",				"1=Block alarm trigger when bots shoot the car. 2=Block alarm trigger when bots stand on the car. 3=Both.", CVAR_FLAGS );
	CreateConVar(							"l4d_car_alarm_bots_version",		PLUGIN_VERSION,		"Car Alarm - Bots Trigger plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	AutoExecConfig(true,					"l4d_car_alarm_bots");

	g_hCvarMPGameMode = FindConVar("mp_gamemode");
	g_hCvarMPGameMode.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModes.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesOff.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesTog.AddChangeHook(ConVarChanged_Allow);
	g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);
	g_hCvarType.AddChangeHook(ConVarChanged_Cvars);

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
	g_iCvarType = g_hCvarType.IntValue;
}

void IsAllowed()
{
	bool bCvarAllow = g_hCvarAllow.BoolValue;
	bool bAllowMode = IsAllowedGameMode();
	GetCvars();

	if( g_bCvarAllow == false && bCvarAllow == true && bAllowMode == true )
	{
		g_bCvarAllow = true;
		HookEntities(true);
	}

	else if( g_bCvarAllow == true && (bCvarAllow == false || bAllowMode == false) )
	{
		g_bCvarAllow = false;
		HookEntities(false);
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
//					HOOKS
// ====================================================================================================
void HookEntities(bool hook)
{
	static bool hooked;

	if( !hooked && hook )
	{
		hooked = true;

		int entity = -1;
		while( (entity = FindEntityByClassname(entity, "prop_car_alarm")) != INVALID_ENT_REFERENCE )
		{
			SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
			SDKHook(entity, SDKHook_Touch, OnTouch);
			SetEntData(entity, g_iOffset, 1, 1, false);
		}
	}
	else if( hooked && !hook )
	{
		hooked = false;

		int entity = -1;
		while( (entity = FindEntityByClassname(entity, "prop_car_alarm")) != INVALID_ENT_REFERENCE )
		{
			SDKUnhook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
			SDKUnhook(entity, SDKHook_Touch, OnTouch);
			SetEntData(entity, g_iOffset, 0, 1, false);
		}
	}
}



// ====================================================================================================
//					EVENTS
// ====================================================================================================
public void OnEntityCreated(int entity, const char[] classname)
{
	if( g_bCvarAllow && strcmp(classname, "prop_car_alarm") == 0 )
	{
		SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
		SDKHook(entity, SDKHook_Touch, OnTouch);
		SetEntData(entity, g_iOffset, 1, 1, false);
	}
}

// Nothing worked to return the client index who triggered the detour on Linux, so using OnTouch method to block bots
void OnTouch(int entity, int client)
{
	if( client >= 1 && client <= MaxClients && GetClientTeam(client) == 2 )
	{
		if( !(g_iCvarType & TYPE_STAND) || (!IsFakeClient(client) && GetEntPropEnt(client, Prop_Send, "m_hGroundEntity") == entity) )
		{
			TriggerAlarm(entity, client);
		}
	}
}

// Real survivor clients can trigger when shooting
Action OnTakeDamage(int entity, int &client, int &inflictor, float &damage, int &damagetype)
{
	if( client >= 1 && client <= MaxClients && GetClientTeam(client) == 2 )
	{
		if( !(g_iCvarType & TYPE_SHOOT) || !IsFakeClient(client) )
		{
			TriggerAlarm(entity, client);
		}
	}

	/* DETOUR METHOD:
	if( attacker >= 1 && attacker <= MaxClients && IsFakeClient(attacker) )
	{
		g_fLastDmg = GetGameTime();
	}
	*/

	return Plugin_Continue;
}

void TriggerAlarm(int entity, int client)
{
	SetEntData(entity, g_iOffset, 0, 1, false);

	SDKUnhook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKUnhook(entity, SDKHook_Touch, OnTouch);

	AcceptEntityInput(entity, "SurvivorStandingOnCar", client, client);
}

/* DETOUR METHOD:
MRESReturn InputSurvivorStandingOnCar(Handle hReturn, Handle hParams)
{
	if( g_bCvarAllow )
	{
		int client = DHookGetParam(hParams, 1);

		if( (g_iCvarType & TYPE_SHOOT && GetGameTime() - g_fLastDmg < 0.1) || (g_iCvarType & TYPE_STAND && GetGameTime() - g_fLastDmg > 0.1 && IsFakeClient(client)) )
			return MRES_Supercede;
	}

	return MRES_Ignored;
}
*/