/*
*	Explosive Flash
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



#define PLUGIN_VERSION 		"1.1"

/*======================================================================================
	Plugin Info:

*	Name	:	[L4D & L4D2] Explosive Flash
*	Author	:	SilverShot
*	Descrp	:	Creates a dynamic light flash on various explosions.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=344438
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.1 (22-Nov-2023)
	- Fixed property not found errors. Thanks to "Iizuka07" for reporting.
	- Removed some unused code.

1.0 (07-Nov-2023)
	- Initial release.

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <left4dhooks>

#define CVAR_FLAGS			FCVAR_NOTIFY
#define MAX_LIGHTS			32
#define MAX_TYPES			5
#define MODEL_BARREL		"models/props_industrial/barrel_fuel.mdl"
#define MODEL_PROPANE		"models/props_junk/propanecanister001a.mdl"
#define MODEL_OXYGEN		"models/props_equipment/oxygentank01.mdl"

enum
{
	TYPE_BARREL,
	TYPE_PROPANE,
	TYPE_OXYGEN,
	TYPE_PIPEBOMB,
	TYPE_GRENADE
}

enum
{
	INDEX_ENTITY = 0,
	INDEX_TYPES = 1
}

ConVar g_hCvarAllow, g_hCvarColor[MAX_TYPES], g_hCvarDist[MAX_TYPES], g_hCvarSpeed, g_hCvarTypes, g_hCvarMPGameMode, g_hCvarModes, g_hCvarModesOff, g_hCvarModesTog;
bool g_bCvarAllow, g_bMapStarted, g_bLeft4Dead2;
int g_iCvarTypes, g_iBarrel, g_iOxygen, g_iPropane, g_iTick[MAX_LIGHTS], g_iEntities[MAX_LIGHTS][2];
float g_fCvarSpeed, g_fCvarDist[MAX_TYPES + 1];
char g_sCvarCols[MAX_TYPES + 1][12];



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D & L4D2] Explosive Flash",
	author = "SilverShot",
	description = "Creates a dynamic light flash on various explosions.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=344438"
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
	g_hCvarAllow =						CreateConVar(	"l4d_explosive_flash_allow",			"1",				"0=Plugin off, 1=Plugin on.", CVAR_FLAGS );
	g_hCvarModes =						CreateConVar(	"l4d_explosive_flash_modes",			"",					"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS );
	g_hCvarModesOff =					CreateConVar(	"l4d_explosive_flash_modes_off",		"",					"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS );
	g_hCvarModesTog =					CreateConVar(	"l4d_explosive_flash_modes_tog",		"0",				"Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS );
	g_hCvarColor[TYPE_BARREL] =			CreateConVar(	"l4d_explosive_flash_color_barrel",		"255 35 0",			"The flash color for Explosive Barrels explosions. Three values between 0-255 separated by spaces. RGB Color255 - Red Green Blue.", CVAR_FLAGS );
	if( g_bLeft4Dead2 )
		g_hCvarColor[TYPE_GRENADE] =	CreateConVar(	"l4d_explosive_flash_color_grenade",	"255 50 0",			"The flash color for Grenade Launcher explosions. Three values between 0-255 separated by spaces. RGB Color255 - Red Green Blue.", CVAR_FLAGS );
	g_hCvarColor[TYPE_PIPEBOMB] =		CreateConVar(	"l4d_explosive_flash_color_pipe",		"255 50 0",			"The flash color Pipe Bomb explosions. Three values between 0-255 separated by spaces. RGB Color255 - Red Green Blue.", CVAR_FLAGS );
	g_hCvarColor[TYPE_PROPANE] =		CreateConVar(	"l4d_explosive_flash_color_propane",	"255 50 0",			"The flash color Propane Tank explosions. Three values between 0-255 separated by spaces. RGB Color255 - Red Green Blue.", CVAR_FLAGS );
	g_hCvarColor[TYPE_OXYGEN] =			CreateConVar(	"l4d_explosive_flash_color_oxygen",		"255 50 0",			"The flash color Oxygen Tank explosions. Three values between 0-255 separated by spaces. RGB Color255 - Red Green Blue.", CVAR_FLAGS );
	g_hCvarDist[TYPE_BARREL] =			CreateConVar(	"l4d_explosive_flash_dist_barrel",		"500.0",			"How far does the Explosive Barrels flash illuminate the area.", CVAR_FLAGS );
	if( g_bLeft4Dead2 )
		g_hCvarDist[TYPE_GRENADE] =		CreateConVar(	"l4d_explosive_flash_dist_grenade",		"500.0",			"How far does the Grenade Launcher flash illuminate the area.", CVAR_FLAGS );
	g_hCvarDist[TYPE_PIPEBOMB] =		CreateConVar(	"l4d_explosive_flash_dist_pipe",		"500.0",			"How far does the Pipe Bomb flash illuminate the area.", CVAR_FLAGS );
	g_hCvarDist[TYPE_PROPANE] =			CreateConVar(	"l4d_explosive_flash_dist_propane",		"500.0",			"How far does the Propane Tank flash illuminate the area.", CVAR_FLAGS );
	g_hCvarDist[TYPE_OXYGEN] =			CreateConVar(	"l4d_explosive_flash_dist_oxygen",		"500.0",			"How far does the Oxygen Tank flash illuminate the area.", CVAR_FLAGS );
	g_hCvarSpeed =						CreateConVar(	"l4d_explosive_flash_speed",			"0.4",				"Duration of the flash for all types.", CVAR_FLAGS, true, 0.0, true, 1.0 );
	g_hCvarTypes =						CreateConVar(	"l4d_explosive_flash_types",			"31",				"Which types to allow: 1=Explosive Barrel. 2=Propane Tank. 4=Oxygen Tank. 8=PipeBomb. 16=Grenade Launcher (L4D2) 31=All.", CVAR_FLAGS );
	CreateConVar(										"l4d_explosive_flash_version",			PLUGIN_VERSION,		"Explosive Flash plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	AutoExecConfig(true,								"l4d_explosive_flash");

	g_hCvarMPGameMode = FindConVar("mp_gamemode");
	g_hCvarMPGameMode.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesTog.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModes.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesOff.AddChangeHook(ConVarChanged_Allow);
	g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);
	for( int i = 0; i < MAX_TYPES; i++ )
	{
		if( !g_bLeft4Dead2 && i == TYPE_GRENADE ) continue;

		g_hCvarDist[i].AddChangeHook(ConVarChanged_Cvars);
		g_hCvarColor[i].AddChangeHook(ConVarChanged_Cvars);
	}
	g_hCvarSpeed.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarTypes.AddChangeHook(ConVarChanged_Cvars);
}

public void OnPluginEnd()
{
	ResetPlugin();
}

public void OnMapStart()
{
	g_bMapStarted = true;

	g_iBarrel = PrecacheModel(MODEL_BARREL);
	g_iPropane = PrecacheModel(MODEL_PROPANE);
	g_iOxygen = PrecacheModel(MODEL_OXYGEN);
}

public void OnMapEnd()
{
	g_bMapStarted = false;
	ResetPlugin();
}

void ResetPlugin()
{
	for( int i = 0; i < MAX_LIGHTS; i++ )
	{
		if( IsValidEntRef(g_iEntities[i][INDEX_ENTITY]) == true )
		{
			RemoveEntity(g_iEntities[i][INDEX_ENTITY]);
		}

		g_iEntities[i][INDEX_ENTITY] = 0;
		g_iEntities[i][INDEX_TYPES] = 0;
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
	for( int i = 0; i < MAX_TYPES; i++ )
	{
		if( !g_bLeft4Dead2 && i == TYPE_GRENADE ) continue;

		g_fCvarDist[i] = g_hCvarDist[i].FloatValue;
		g_hCvarColor[i].GetString(g_sCvarCols[i], sizeof(g_sCvarCols[]));
	}

	g_fCvarSpeed = g_hCvarSpeed.FloatValue;
	g_iCvarTypes = g_hCvarTypes.IntValue;
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
		ResetPlugin();
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
//					EVENTS
// ====================================================================================================
float g_fBreakable;
public void L4D_PipeBomb_Detonate_Post(int entity, int client)
{
	if( g_fBreakable == GetGameTime() ) return; // Various explosions caused the PipeBomb to trigger, mostly breakable props, so if a breakable prop detonates before the pipebomb then ignore

	CreateFlash(entity, TYPE_PIPEBOMB);
}

public void L4D2_GrenadeLauncher_Detonate_Post(int entity, int client)
{
	CreateFlash(entity, TYPE_GRENADE);
}

public void L4D_CBreakableProp_Break(int prop, int entity)
{
	g_fBreakable = GetGameTime();

	if( !HasEntProp(entity, Prop_Send, "m_nModelIndex") ) return;

	int type = GetEntProp(entity, Prop_Send, "m_nModelIndex");

	if( type == g_iBarrel )			CreateFlash(prop, TYPE_BARREL);
	else if( type == g_iOxygen )	CreateFlash(prop, TYPE_OXYGEN);
	else if( type == g_iPropane )	CreateFlash(prop, TYPE_PROPANE);
}



// ====================================================================================================
//					LIGHTS
// ====================================================================================================
void CreateFlash(int target, int type)
{
	if( g_iCvarTypes & (1 << type) == 0 ) return;

	if( (target = EntRefToEntIndex(target)) != INVALID_ENT_REFERENCE )
	{
		// Find empty index
		int index = -1;

		for( int i = 0; i < MAX_LIGHTS; i++ )
		{
			if( IsValidEntRef(g_iEntities[i][INDEX_ENTITY]) == false )
			{
				index = i;
				break;
			}
		}

		if( index == -1 )
			return;

		// Create light
		int entity = CreateEntityByName("light_dynamic");
		if( entity == -1)
		{
			LogError("Failed to create 'light_dynamic'");
			return;
		}

		g_iEntities[index][INDEX_ENTITY] = EntIndexToEntRef(entity);

		static char sTemp[16];
		FormatEx(sTemp, sizeof(sTemp), "%s 255", g_sCvarCols[type]);

		DispatchKeyValue(entity, "_light", sTemp);
		DispatchKeyValue(entity, "brightness", "2");
		DispatchKeyValueFloat(entity, "spotlight_radius", g_fCvarDist[type]);
		DispatchKeyValueFloat(entity, "distance", g_fCvarDist[type]);
		DispatchKeyValue(entity, "style", "6");
		DispatchSpawn(entity);

		float vPos[3];
		GetEntPropVector(target, Prop_Send, "m_vecOrigin", vPos);
		vPos[2] += 10.0;
		TeleportEntity(entity, vPos, NULL_VECTOR, NULL_VECTOR);

		// Fade
		RequestFrame(OnFrameFadeOut, index);

		g_iTick[index] = 20 - RoundFloat(30 * g_fCvarSpeed); // Determines how fast it fades
	}
}

void OnFrameFadeOut(int index)
{
	if( !IsValidEntRef(g_iEntities[index][INDEX_ENTITY]) )
	{
		g_iEntities[index][INDEX_ENTITY] = 0;
		return;
	}

	float fDist;
	float flTickInterval = GetTickInterval();
	int iTickRate = RoundFloat(1 / flTickInterval);
	int type = g_iEntities[index][INDEX_TYPES];

	fDist = (g_fCvarDist[type] / iTickRate) * (iTickRate - g_iTick[index]);
	g_iTick[index]++;

	if( fDist > 0.0 )
	{
		if( fDist < g_fCvarDist[type] )
		{
			SetVariantFloat(fDist);
			AcceptEntityInput(g_iEntities[index][INDEX_ENTITY], "Distance");
		}

		RequestFrame(OnFrameFadeOut, index);
	} else {
		RemoveEntity(g_iEntities[index][INDEX_ENTITY]);

		g_iTick[index] = 0;
		g_iEntities[index][INDEX_ENTITY] = 0;
	}
}

bool IsValidEntRef(int entity)
{
	if( entity && EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE )
		return true;
	return false;
}