/*
*	Vomitjar Shove
*	Copyright (C) 2021 Silvers
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



#define PLUGIN_VERSION 		"1.9"

/*======================================================================================
	Plugin Info:

*	Name	:	[L4D2] Vomitjar Shove
*	Author	:	SilverShot
*	Descrp	:	Biles infected when shoved by players holding vomitjars.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=188045
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.9 (01-Nov-2022)
	- Added cvar "l4d2_vomitjar_shove_keys" to optionally require holding "R" before shoving. Requested by "Iciaria".

1.8a (14-Nov-2021)
	- Updated GameData signatures to avoid breaking when detoured by the "Left4DHooks" plugin.

1.8 (10-May-2020)
	- Added better error log message when gamedata file is missing.
	- Extra checks to prevent "IsAllowedGameMode" throwing errors.
	- Various changes to tidy up code.
	- Various optimizations and fixes.

1.7 (01-Apr-2020)
	- Fixed "IsAllowedGameMode" from throwing errors when the "_tog" cvar was changed before MapStart.

1.6 (05-Dec-2019)
	- Added breaking sound effect - Requested by "Tonblader".

1.5 (05-May-2018)
	- Converted plugin source to the latest syntax utilizing methodmaps. Requires SourceMod 1.8 or newer.

1.4 (24-Mar-2018)
	- Added a couple checks to prevent errors being logged - Thanks to "Crasher_3637" for reporting.
	- Fixed self-vomit effect disappearing after ~5 seconds.
	- Updated gamedata txt file.

1.3 (14-May-2017)
	- Added cvar "l4d2_vomitjar_shove_radius" - Distance to splash nearby survivors when the vomitjar breaks.
	- Added cvar "l4d2_vomitjar_shove_splash" - Chance out of 100 to splash self and nearby players when the vomitjar breaks.

1.2 (07-Aug-2013)
	- Fixed the cvar "l4d2_vomitjar_shove_punch" to work correctly.

1.1 (21-Jul-2013)
	- Added cvar "l4d2_vomitjar_shove_punch" to control how many hits a vomitjar can make before breaking.

1.0 (21-Jun-2012)
	- Initial release.

========================================================================================

	This plugin was made using source code from the following plugins.
	If I have used your code and not credited you, please let me know.

*	Thanks to "AtomicStryker" for "Bile the World" - Used SDK code and gamedata file to bile players.
	https://forums.alliedmods.net/showthread.php?t=132264

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define CVAR_FLAGS			FCVAR_NOTIFY
#define GAMEDATA			"l4d2_vomitjar_shove"
#define SOUND_BREAK			"weapons/ceda_jar/ceda_jar_explode.wav"
#define MAX_ENTS			64


Handle sdkOnVomitedUpon, sdkVomitInfected, sdkVomitSurvivor;
ConVar g_hCvarAllow, g_hCvarMPGameMode, g_hCvarModes, g_hCvarModesOff, g_hCvarModesTog, g_hCvarInfected, g_hCvarKeys, g_hCvarPunch, g_hCvarRadius, g_hCvarSplash;
int g_iCvarInfected, g_iCvarKeys, g_iCvarPunch, g_iCvarRadius, g_iCvarSplash, g_iPunches[MAX_ENTS][2];
bool g_bCvarAllow, g_bMapStarted;



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D2] Vomitjar Shove",
	author = "SilverShot",
	description = "Biles infected when shoved by players holding vomitjars.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=188045"
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

public void OnPluginStart()
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "gamedata/%s.txt", GAMEDATA);
	if( FileExists(sPath) == false ) SetFailState("\n==========\nMissing required file: \"%s\".\nRead installation instructions again.\n==========", sPath);

	Handle hGameData = LoadGameConfigFile(GAMEDATA);
	if( hGameData == null ) SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);

	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "Infected_OnHitByVomitJar");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	sdkVomitInfected = EndPrepSDKCall();
	if( sdkVomitInfected == null )
	{
		SetFailState("Unable to find the \"Infected_OnHitByVomitJar\" signature, check the file version!");
	}

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer_OnHitByVomitJar");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	sdkVomitSurvivor = EndPrepSDKCall();
	if( sdkVomitSurvivor == null )
	{
		SetFailState("Unable to find the \"CTerrorPlayer_OnHitByVomitJar\" signature, check the file version!");
	}

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer_OnVomitedUpon");
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	sdkOnVomitedUpon = EndPrepSDKCall();
	if( sdkOnVomitedUpon == null )
	{
		SetFailState("Unable to find the \"CTerrorPlayer_OnVomitedUpon\" signature, check the file version!");
	}

	delete hGameData;


	g_hCvarAllow = CreateConVar(	"l4d2_vomitjar_shove_allow",			"1",			"0=Plugin off, 1=Plugin on.", CVAR_FLAGS );
	g_hCvarModes = CreateConVar(	"l4d2_vomitjar_shove_modes",			"",				"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS );
	g_hCvarModesOff = CreateConVar(	"l4d2_vomitjar_shove_modes_off",		"",				"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS );
	g_hCvarModesTog = CreateConVar(	"l4d2_vomitjar_shove_modes_tog",		"0",			"Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS );
	g_hCvarInfected = CreateConVar(	"l4d2_vomitjar_shove_infected",			"511",			"Which infected to affect: 1=Common, 2=Witch, 4=Smoker, 8=Boomer, 16=Hunter, 32=Spitter, 64=Jockey, 128=Charger, 256=Tank, 511=All.", CVAR_FLAGS );
	g_hCvarKeys = CreateConVar(		"l4d2_vomitjar_shove_keys",				"1",			"Which key combination to use when shoving: 1=Shove key. 2=Reload + Shove keys.", CVAR_FLAGS );
	g_hCvarPunch = CreateConVar(	"l4d2_vomitjar_shove_punch",			"5",			"0=Unlimited. How many times can a player hit zombies with the vomitjar before it breaks.", CVAR_FLAGS );
	g_hCvarRadius = CreateConVar(	"l4d2_vomitjar_shove_radius",			"50",			"0=Only the player holding the vomitjar. Distance to splash nearby survivors when the vomitjar breaks.", CVAR_FLAGS );
	g_hCvarSplash = CreateConVar(	"l4d2_vomitjar_shove_splash",			"10",			"Chance out of 100 to splash self and nearby players when the vomitjar breaks.", CVAR_FLAGS );
	CreateConVar(					"l4d2_vomitjar_shove_version",			PLUGIN_VERSION,	"Vomitjar Shove plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	AutoExecConfig(true,			"l4d2_vomitjar_shove");

	g_hCvarMPGameMode = FindConVar("mp_gamemode");
	g_hCvarMPGameMode.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModes.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesOff.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesTog.AddChangeHook(ConVarChanged_Allow);
	g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);
	g_hCvarInfected.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarKeys.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarPunch.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarRadius.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarSplash.AddChangeHook(ConVarChanged_Cvars);
}

public void OnMapStart()
{
	g_bMapStarted = true;
	PrecacheSound(SOUND_BREAK);
}

public void OnMapEnd()
{
	g_bMapStarted = false;
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
	g_iCvarInfected = g_hCvarInfected.IntValue;
	g_iCvarKeys = g_hCvarKeys.IntValue;
	g_iCvarPunch = g_hCvarPunch.IntValue;
	g_iCvarRadius = g_hCvarRadius.IntValue;
	g_iCvarSplash = g_hCvarSplash.IntValue;
}

void IsAllowed()
{
	bool bCvarAllow = g_hCvarAllow.BoolValue;
	bool bAllowMode = IsAllowedGameMode();
	GetCvars();

	if( g_bCvarAllow == false && bCvarAllow == true && bAllowMode == true )
	{
		g_bCvarAllow = true;
		HookEvent("entity_shoved", Event_EntityShoved);
		HookEvent("player_shoved", Event_PlayerShoved);
	}

	else if( g_bCvarAllow == true && (bCvarAllow == false || bAllowMode == false) )
	{
		g_bCvarAllow = false;
		UnhookEvent("entity_shoved", Event_EntityShoved);
		UnhookEvent("player_shoved", Event_PlayerShoved);
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
//					EVENTS
// ====================================================================================================
void Event_EntityShoved(Event event, const char[] name, bool dontBroadcast)
{
	int infected = g_iCvarInfected & (1<<0);
	int witch = g_iCvarInfected & (1<<1);
	if( infected || witch )
	{
		int client = GetClientOfUserId(event.GetInt("attacker"));

		if( g_iCvarKeys == 1 || GetClientButtons(client) & IN_RELOAD )
		{
			int weapon = CheckWeapon(client);
			if( weapon )
			{
				int target = event.GetInt("entityid");

				static char sTemp[12];
				GetEdictClassname(target, sTemp, sizeof(sTemp));

				if( (infected && strcmp(sTemp, "infected") == 0 ) || (witch && strcmp(sTemp, "witch") == 0) )
				{
					HurtPlayer(target, client, false);
					DoRemove(client, weapon);
				}
			}
		}
	}
}

void Event_PlayerShoved(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("attacker"));

	if( g_iCvarKeys == 1 || GetClientButtons(client) & IN_RELOAD )
	{
		int target = GetClientOfUserId(event.GetInt("userid"));

		if( GetClientTeam(target) == 3 )
		{
			int weapon = CheckWeapon(client);
			if( weapon )
			{
				int class = GetEntProp(target, Prop_Send, "m_zombieClass") + 1;
				if( class == 9 ) class = 8;
				if( g_iCvarInfected & (1 << class) )
				{
					HurtPlayer(target, client, true);
					DoRemove(client, weapon);
				}
			}
		}
	}
}

void DoRemove(int client, int weapon)
{
	bool remove = false;

	if( g_iCvarPunch )
	{
		if( g_iCvarPunch == 1 )
		{
			remove = true;
		} else {
			int index = GetEnt(weapon);
			if( index == -1 )
			{
				SetEnt(weapon);
			} else {
				g_iPunches[index][1]++;
				int count = g_iPunches[index][1];

				if( count >= g_iCvarPunch )
				{
					remove = true;
					g_iPunches[index][0] = 0;
					g_iPunches[index][1] = 0;
				}
			}
		}
	}

	if( remove )
	{
		RemovePlayerItem(client, weapon);
		RemoveEntity(weapon);
		EmitSoundToAll(SOUND_BREAK, client);

		if( g_iCvarSplash > 0 )
		{
			if( g_iCvarSplash >= GetRandomInt(1, 100) )
			{
				// Nearby g_iCvarRadius
				float vPos[3];
				float vOur[3];

				GetClientAbsOrigin(client, vOur);

				for( int i = 1; i <= MaxClients; i++ )
				{
					if( IsClientInGame(i) && IsPlayerAlive(i) )
					{
						GetClientAbsOrigin(i, vPos);
						if( GetVectorDistance(vPos, vOur) <= g_iCvarRadius )
						{
							HurtPlayer(i, client, true);
						}
					}
				}
			}
		}
	}
}

void HurtPlayer(int target, int client, bool special)
{
	if( special )
	{
		if( GetClientTeam(target) == 2 )
			SDKCall(sdkOnVomitedUpon, target, false);
		else
			SDKCall(sdkVomitSurvivor, target, client, true);
	}
	else
		SDKCall(sdkVomitInfected, target, client, true);
}

int CheckWeapon(int client)
{
	if( client && IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2 )
	{
		int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if( weapon > 0 && IsValidEntity(weapon) )
		{
			static char sTemp[16];
			GetEdictClassname(weapon, sTemp, sizeof(sTemp));
			if( strcmp(sTemp[7], "vomitjar") == 0 )
			{
				return weapon;
			}
		}
	}
	return 0;
}

int GetEnt(int entity)
{
	entity = EntIndexToEntRef(entity);

	for( int i = 0; i < MAX_ENTS; i++ )
	{
		if( g_iPunches[i][0] == entity )
		{
			return i;
		}
	}

	return -1;
}

void SetEnt(int entity)
{
	entity = EntIndexToEntRef(entity);

	for( int i = 0; i < MAX_ENTS; i++ )
	{
		if( IsValidEntRef(g_iPunches[i][0]) == false )
		{
			g_iPunches[i][0] = entity;
			g_iPunches[i][1] = 1;
		}
	}
}

bool IsValidEntRef(int entity)
{
	if( entity && EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE )
		return true;
	return false;
}