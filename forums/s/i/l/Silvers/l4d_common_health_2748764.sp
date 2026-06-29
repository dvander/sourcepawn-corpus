/*
*	Common Infected Health - PipeBomb, Physics and Melee Damage
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



#define PLUGIN_VERSION		"1.9"

/*=======================================================================================
	Plugin Info:

*	Name	:	[L4D & L4D2] Common Infected - Damage Received
*	Author	:	SilverShot
*	Descrp	:	Specify or scale the damage Pipebombs, Propane, Oxygen, Grenade Launcher, Melee and Chainsaw damage caused to common infected.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=332832
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.9 (10-Aug-2022)
	- Fixed weapons not following the "l4d_common_health_headshot" scale value to prevent insta-kill headshots.
	- Fixed client crashes related to changing headless zombies into half-headless. Thanks to "Toranks" for reporting and testing.

1.8 (29-May-2022)
	- Fixed errors in L4D1 about "m_iRequestedWound1" missing.

1.7 (27-May-2022)
	- Combined code with "Common Headshot" plugin.
	- Better handling of wounds. Thanks to "Toranks" for help fixing.
	- Added new cvars "l4d_common_health_headshot", "l4d_common_health_headshot_melee" to control headshot damage.
	- Added new cvar "l4d_common_health_headshot_one" to control if single shots to common infected heads insta-kill them.
	- Fixed crashing clients when multiple common have wounds within the same frame.

	- Thanks to "Toranks" for tons of testing and feedback.

1.6 (16-May-2022)
	- Now blocks insta-killing common infected when multiple common are struck by melee weapons. Thanks to "Toranks" for reporting.
	- Instant kills are only blocked when the cvar "l4d_common_health_melee" value is not "0.0".

1.5 (29-Oct-2021)
	- Compatibility update for "Prototype Grenades" plugin. Now sets the "m_iMaxHealth" on Common Infected when the value is changed.

1.4 (14-Jul-2021)
	- Compatibility update for "Bots Ignore PipeBombs and Shoot" plugin.

1.3 (11-Jul-2021)
	- L4D2: Optimized model checks slightly.

1.2 (20-Jun-2021)
	- L4D2: Added cvars to set default uncommon infected health:
		"l4d_common_health_u_ceda", "l4d_common_health_u_clown", "l4d_common_health_u_fallen", "l4d_common_health_u_jimmy",
		"l4d_common_health_u_mud", "l4d_common_health_u_riot", "l4d_common_health_u_road"
	- Requested by "Enduh".

1.1 (04-Jun-2021)
	- L4D2: Added 2 new cvars and support to customize damage for the Grenade Launcher weapon.

1.0 (03-Jun-2021)
	- Initial release.

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define CVAR_FLAGS			FCVAR_NOTIFY
#define MODEL_OXYGEN		"models/props_equipment/oxygentank01.mdl"
#define MODEL_PROPANE		"models/props_junk/propanecanister001a.mdl"

#define RANDOM_WOUND_MIN			26
#define RANDOM_WOUND_MAX			34
#define RANDOM_WOUND_CEDA_MIN		0
#define RANDOM_WOUND_CEDA_MAX		3
#define RANDOM_WOUND_RIOT_MIN		6
#define RANDOM_WOUND_RIOT_MAX		13

#define NO_WOUND					0
#define GENDER_FEMALE_L4D1			22
#define GENDER_FEMALE_L4D2			2
#define GENDER_MALE1				0
#define GENDER_MALE2				1
#define GENDER_MALE3				12
#define GENDER_MALE4				13
#define GENDER_MALE5				14
#define GENDER_MALE6				16
#define GENDER_MALE7				20
#define GENDER_MALE8				21

#define GENDER_CEDA 				11
#define GENDER_MUD	 				12
#define GENDER_ROAD 				13
#define GENDER_FALLEN 				14
#define GENDER_RIOT 				15
#define GENDER_CLOWN 				16
#define GENDER_JIMMY 				17

#define PART_A						3
#define PART_B						4
#define PART_C						5
#define PART_E						12
#define PART_F						9
#define PART_G						13
#define PART_H						14
#define PART_I						15
#define PART_J						16
#define PART_K						17
#define PART_L						19
#define PART_M						20
#define PART_N						21
#define PART_O						22
#define PART_P						23
#define PART_Q						24
#define PART_R						25
#define PART_S						18
#define HEAD_1						8
#define HEAD_2						41

ConVar g_hCvarAllow, g_hCvarMPGameMode, g_hCvarModes, g_hCvarModesOff, g_hCvarModesTog, g_hCvarChainsaw, g_hCvarChainsaw2, g_hCvarHeadshot, g_hCvarHeadshotMelee, g_hCvarHeadshotOne, g_hCvarLauncher, g_hCvarLauncher2, g_hCvarMelee, g_hCvarMelee2, g_hCvarOxygen, g_hCvarOxygen2, g_hCvarPipebomb, g_hCvarPipebomb2, g_hCvarPropane, g_hCvarPropane2;
ConVar g_hCvarHealthCeda, g_hCvarHealthClown, g_hCvarHealthFallen, g_hCvarHealthJimmy, g_hCvarHealthMud, g_hCvarHealthRiot, g_hCvarHealthRoad;
bool g_bCvarAllow, g_bLeft4Dead2, g_bTraceAttack, g_bPipebombIgnore, g_bCvarHeadshotOne;
int g_iMaxHealth[2048], g_iPropType, g_iCvarChainsaw2, g_iCvarLauncher2, g_iCvarMelee2, g_iCvarOxygen2, g_iCvarPipebomb2, g_iCvarPropane2;
int g_iCvarHealthCeda, g_iCvarHealthClown, g_iCvarHealthFallen, g_iCvarHealthJimmy, g_iCvarHealthMud, g_iCvarHealthRiot, g_iCvarHealthRoad;
float g_fLastHit[2048][2048], g_fMelee[MAXPLAYERS+1], g_fGameTime, g_fCvarChainsaw, g_fCvarHeadshot, g_fCvarHeadshotMelee, g_fCvarLauncher, g_fCvarMelee, g_fCvarOxygen, g_fCvarPipebomb, g_fCvarPropane;



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D & L4D2] Common Infected Health - Damage Received",
	author = "SilverShot",
	description = "Specify or scale the damage Pipebombs, Propane, Oxygen, Grenade Launcher, Melee and Chainsaw damage caused to common infected.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=332832"
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

public void OnAllPluginsLoaded()
{
	g_bPipebombIgnore = FindConVar("l4d_pipebomb_ignore_version") != null;
}

public void OnPluginStart()
{
	g_hCvarAllow = CreateConVar(				"l4d_common_health_allow",				"1",			"0=Plugin off, 1=Plugin on.", CVAR_FLAGS );
	g_hCvarModes = CreateConVar(				"l4d_common_health_modes",				"",				"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS );
	g_hCvarModesOff = CreateConVar(				"l4d_common_health_modes_off",			"",				"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS );
	g_hCvarModesTog = CreateConVar(				"l4d_common_health_modes_tog",			"0",			"Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS );
	g_hCvarHeadshot = CreateConVar(				"l4d_common_health_headshot",			"0.0",			"0.0=Ignore headshot damage. 1.0=100% damage. Scale damage value applied on headshots.");
	g_hCvarHeadshotOne = CreateConVar(			"l4d_common_health_headshot_one",		"1",			"0=Block instant kill headshots. 1=Allow instant kill headshots.");
	if( g_bLeft4Dead2 )
	{
		g_hCvarChainsaw = CreateConVar(			"l4d_common_health_chainsaw",			"0.0",			"L4D2 only. 0.0=Off (use games default damage). Amount of damage each Chainsaw hit causes to a common infected, or scale according to related cvar.", CVAR_FLAGS );
		g_hCvarChainsaw2 = CreateConVar(		"l4d_common_health_chainsaw2",			"2",			"L4D2 only. 0=Deal the damage value specified. 1=Deal the specified damage value as a percentage of their maximum health. 2=Scale original damage.", CVAR_FLAGS );
		g_hCvarLauncher = CreateConVar(			"l4d_common_health_launcher",			"0.0",			"L4D2 only. 0.0=Off (use games default damage). Amount of damage each Grenade Launcher hit causes to a common infected, or scale according to related cvar.", CVAR_FLAGS );
		g_hCvarLauncher2 = CreateConVar(		"l4d_common_health_launcher2",			"2",			"L4D2 only. 0=Deal the damage value specified. 1=Deal the specified damage value as a percentage of their maximum health. 2=Scale original damage.", CVAR_FLAGS );
		g_hCvarHeadshotMelee = CreateConVar(	"l4d_common_health_headshot_melee",		"0.0",			"0.0=Ignore headshot damage. 1.0=100% damage. Scale damage value applied on headshots with melee weapons.");
		g_hCvarMelee = CreateConVar(			"l4d_common_health_melee",				"0.0",			"L4D2 only. 0.0=Off (use games default damage). Amount of damage each Melee weapon hit causes to a common infected, or scale according to related cvar.", CVAR_FLAGS );
		g_hCvarMelee2 = CreateConVar(			"l4d_common_health_melee2",				"2",			"L4D2 only. 0=Deal the damage value specified. 1=Deal the specified damage value as a percentage of their maximum health. 2=Scale original damage.", CVAR_FLAGS );

		g_hCvarHealthCeda = CreateConVar(		"l4d_common_health_u_ceda",				"150",			"L4D2 only. Game default: 150. Default amount of health for CEDA Hazmat uncommon infected.", CVAR_FLAGS );
		g_hCvarHealthClown = CreateConVar(		"l4d_common_health_u_clown",			"150",			"L4D2 only. Game default: 150. Default amount of health for Clown uncommon infected.", CVAR_FLAGS );
		g_hCvarHealthFallen = CreateConVar(		"l4d_common_health_u_fallen",			"1000",			"L4D2 only. Game default: 1000. Default amount of health for Fallen Survivor uncommon infected.", CVAR_FLAGS );
		g_hCvarHealthJimmy = CreateConVar(		"l4d_common_health_u_jimmy",			"3000",			"L4D2 only. Game default: 3000. Default amount of health for Jimmy Gibbs Junior uncommon infected.", CVAR_FLAGS );
		g_hCvarHealthMud = CreateConVar(		"l4d_common_health_u_mud",				"150",			"L4D2 only. Game default: 150. Default amount of health for Mud Men uncommon infected.", CVAR_FLAGS );
		g_hCvarHealthRiot = CreateConVar(		"l4d_common_health_u_riot",				"50",			"L4D2 only. Game default: 50. Default amount of health for Riot Security uncommon infected.", CVAR_FLAGS );
		g_hCvarHealthRoad = CreateConVar(		"l4d_common_health_u_road",				"150",			"L4D2 only. Game default: 150. Default amount of health for Road Crew Worker uncommon infected.", CVAR_FLAGS );
	}
	g_hCvarOxygen = CreateConVar(				"l4d_common_health_oxygen",				"0.0",			"0.0=Off (use games default damage). Amount of damage each Oxygen Tank explosion causes to a common infected, or scale according to related cvar.", CVAR_FLAGS );
	g_hCvarOxygen2 = CreateConVar(				"l4d_common_health_oxygen2",			"2",			"0=Deal the damage value specified. 1=Deal the specified damage value as a percentage of their maximum health. 2=Scale original damage.", CVAR_FLAGS );
	g_hCvarPropane = CreateConVar(				"l4d_common_health_propane",			"0.0",			"0.0=Off (use games default damage). Amount of damage each Propane explosion causes to a common infected, or scale according to related cvar.", CVAR_FLAGS );
	g_hCvarPropane2 = CreateConVar(				"l4d_common_health_propane2",			"2",			"0=Deal the damage value specified. 1=Deal the specified damage value as a percentage of their maximum health. 2=Scale original damage.", CVAR_FLAGS );
	g_hCvarPipebomb = CreateConVar(				"l4d_common_health_pipebomb",			"0.0",			"0.0=Off (use games default damage). Amount of damage each PipeBomb explosion causes to a common infected, or scale according to related cvar.", CVAR_FLAGS );
	g_hCvarPipebomb2 = CreateConVar(			"l4d_common_health_pipebomb2",			"2",			"0=Deal the damage value specified. 1=Deal the specified damage value as a percentage of their maximum health. 2=Scale original damage.", CVAR_FLAGS );
	CreateConVar(								"l4d_common_health_version",			PLUGIN_VERSION,	"Molotov Shove plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	AutoExecConfig(true,						"l4d_common_health");

	g_hCvarMPGameMode = FindConVar("mp_gamemode");
	g_hCvarMPGameMode.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesTog.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModes.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesOff.AddChangeHook(ConVarChanged_Allow);
	g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);
	g_hCvarHeadshot.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarHeadshotOne.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarOxygen.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarOxygen2.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarPipebomb.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarPipebomb2.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarPropane.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarPropane2.AddChangeHook(ConVarChanged_Cvars);
	if( g_bLeft4Dead2 )
	{
		g_hCvarChainsaw.AddChangeHook(ConVarChanged_Cvars);
		g_hCvarChainsaw2.AddChangeHook(ConVarChanged_Cvars);
		g_hCvarHeadshotMelee.AddChangeHook(ConVarChanged_Cvars);
		g_hCvarLauncher.AddChangeHook(ConVarChanged_Cvars);
		g_hCvarLauncher2.AddChangeHook(ConVarChanged_Cvars);
		g_hCvarMelee.AddChangeHook(ConVarChanged_Cvars);
		g_hCvarMelee2.AddChangeHook(ConVarChanged_Cvars);

		g_hCvarHealthCeda.AddChangeHook(ConVarChanged_Cvars);
		g_hCvarHealthClown.AddChangeHook(ConVarChanged_Cvars);
		g_hCvarHealthFallen.AddChangeHook(ConVarChanged_Cvars);
		g_hCvarHealthJimmy.AddChangeHook(ConVarChanged_Cvars);
		g_hCvarHealthMud.AddChangeHook(ConVarChanged_Cvars);
		g_hCvarHealthRiot.AddChangeHook(ConVarChanged_Cvars);
		g_hCvarHealthRoad.AddChangeHook(ConVarChanged_Cvars);
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
	if( g_bLeft4Dead2 )
	{
		g_fCvarChainsaw = g_hCvarChainsaw.FloatValue;
		g_iCvarChainsaw2 = g_hCvarChainsaw2.IntValue;
		g_fCvarHeadshotMelee = g_hCvarHeadshotMelee.FloatValue;
		g_fCvarLauncher = g_hCvarLauncher.FloatValue;
		g_iCvarLauncher2 = g_hCvarLauncher2.IntValue;
		g_fCvarMelee = g_hCvarMelee.FloatValue;
		g_iCvarMelee2 = g_hCvarMelee2.IntValue;

		g_iCvarHealthCeda = g_hCvarHealthCeda.IntValue;
		g_iCvarHealthClown = g_hCvarHealthClown.IntValue;
		g_iCvarHealthFallen = g_hCvarHealthFallen.IntValue;
		g_iCvarHealthJimmy = g_hCvarHealthJimmy.IntValue;
		g_iCvarHealthMud = g_hCvarHealthMud.IntValue;
		g_iCvarHealthRiot = g_hCvarHealthRiot.IntValue;
		g_iCvarHealthRoad = g_hCvarHealthRoad.IntValue;
	}

	g_fCvarHeadshot = g_hCvarHeadshot.FloatValue;
	g_bCvarHeadshotOne = g_hCvarHeadshotOne.BoolValue;
	g_fCvarOxygen = g_hCvarOxygen.FloatValue;
	g_iCvarOxygen2 = g_hCvarOxygen2.IntValue;
	g_fCvarPipebomb = g_hCvarPipebomb.FloatValue;
	g_iCvarPipebomb2 = g_hCvarPipebomb2.IntValue;
	g_fCvarPropane = g_hCvarPropane.FloatValue;
	g_iCvarPropane2 = g_hCvarPropane2.IntValue;
}

void IsAllowed()
{
	bool bCvarAllow = g_hCvarAllow.BoolValue;
	bool bAllowMode = IsAllowedGameMode();
	GetCvars();

	if( g_bCvarAllow == false && bCvarAllow == true && bAllowMode == true )
	{
		g_bCvarAllow = true;

		HookEvent("round_end",			Event_RoundEnd, EventHookMode_PostNoCopy);
		HookEvent("break_prop",			Event_BreakProp);
		if( g_bLeft4Dead2 )
			HookEvent("weapon_fire",	Event_WeaponFire);

		int entity = -1;
		while( (entity = FindEntityByClassname(entity, "infected")) != INVALID_ENT_REFERENCE )
		{
			SDKHook(entity, SDKHook_TraceAttack, OnTraceAttack);
			SDKHook(entity, SDKHook_OnTakeDamageAlive, OnTakeDamage);

			g_iMaxHealth[entity] = GetEntProp(entity, Prop_Data, "m_iHealth");

			for( int x = 0; x < 2048; x++ )
			{
				g_fLastHit[entity][x] = 0.0;
			}
		}

		ResetVars();
	}

	else if( g_bCvarAllow == true && (bCvarAllow == false || bAllowMode == false) )
	{
		g_bCvarAllow = false;

		UnhookEvent("round_end",		Event_RoundEnd, EventHookMode_PostNoCopy);
		UnhookEvent("break_prop",		Event_BreakProp);
		if( g_bLeft4Dead2 )
			UnhookEvent("weapon_fire",	Event_WeaponFire);

		int entity = -1;
		while( (entity = FindEntityByClassname(entity, "infected")) != INVALID_ENT_REFERENCE )
		{
			SDKUnhook(entity, SDKHook_TraceAttack, OnTraceAttack);
			SDKUnhook(entity, SDKHook_OnTakeDamageAlive, OnTakeDamage);
		}
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
public void OnMapEnd()
{
	ResetVars();
}

void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	ResetVars();
}

void ResetVars()
{
	g_iPropType = 0;
	g_fGameTime = 0.0;

	for( int i = 1; i <= MaxClients; i++ )
	{
		g_fMelee[i] = 0.0;
	}

	for( int i = 0; i < 2048; i++ )
	{
		for( int x = 0; x < 2048; x++ )
		{
			g_fLastHit[i][x] = 0.0;
		}
	}
}

void Event_BreakProp(Event event, const char[] name, bool dontBroadcast)
{
	// Reset
	g_iPropType = 0;
	int entity = GetEventInt(event, "entindex");

	// Verify explosive model
	static char classname[48];
	GetEntPropString(entity, Prop_Data, "m_ModelName", classname, sizeof(classname));

	if(			g_fCvarPropane && strcmp(classname, MODEL_PROPANE) == 0 )		g_iPropType = 4;
	else if(	g_fCvarOxygen && strcmp(classname, MODEL_OXYGEN) == 0 )			g_iPropType = 5;

	// Type to determine explosion damage
	if( g_iPropType )
	{
		g_fGameTime = GetGameTime();
	}
}

void Event_WeaponFire(Event event, const char[] name, bool dontBroadcast)
{
	if( g_fCvarMelee )
	{
		static char classname[6];
		event.GetString("weapon", classname, sizeof(classname));
		if( strcmp(classname, "melee") == 0 )
		{
			int client = GetClientOfUserId(event.GetInt("userid"));
			g_fMelee[client] = GetGameTime();
		}
	}
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if( g_bCvarAllow && strcmp(classname, "infected") == 0 )
	{
		SDKHook(entity, SDKHook_SpawnPost, SpawnPost);
	}
	// else if( strcmp(classname, "pipe_bomb_projectile") == 0 )
	// {
		// SetEntPropFloat(entity, Prop_Send, "m_flCreateTime", GetGameTime());
	// }
}

void SpawnPost(int entity)
{
	// Get maximum health on spawn, supports "Mutant Zombies" plugin for example, maybe some other plugins require a longer delay, either next frame or e.g. 0.1 timer.

	if( g_bLeft4Dead2 )
	{
		int gender = GetEntProp(entity, Prop_Send, "m_Gender");

		switch( gender )
		{
			case GENDER_CEDA:
			{
				if( g_iCvarHealthCeda	!= 150 )		{ SetEntProp(entity, Prop_Data, "m_iHealth", g_iCvarHealthCeda);	SetEntProp(entity, Prop_Data, "m_iMaxHealth", g_iCvarHealthCeda); }
			}

			case GENDER_MUD:
			{
				if( g_iCvarHealthMud	!= 150 )		{ SetEntProp(entity, Prop_Data, "m_iHealth", g_iCvarHealthMud);		SetEntProp(entity, Prop_Data, "m_iMaxHealth", g_iCvarHealthMud); }
			}

			case GENDER_ROAD:
			{
				if( g_iCvarHealthRoad	!= 150 )		{ SetEntProp(entity, Prop_Data, "m_iHealth", g_iCvarHealthRoad);	SetEntProp(entity, Prop_Data, "m_iMaxHealth", g_iCvarHealthRoad); }
			}

			case GENDER_FALLEN:
			{
				if( g_iCvarHealthFallen	!= 1000 )		{ SetEntProp(entity, Prop_Data, "m_iHealth", g_iCvarHealthFallen);	SetEntProp(entity, Prop_Data, "m_iMaxHealth", g_iCvarHealthFallen); }
			}

			case GENDER_RIOT:
			{
				if( g_iCvarHealthRiot	!= 50 )			{ SetEntProp(entity, Prop_Data, "m_iHealth", g_iCvarHealthRiot);	SetEntProp(entity, Prop_Data, "m_iMaxHealth", g_iCvarHealthRiot); }
			}

			case GENDER_CLOWN:
			{
				if( g_iCvarHealthClown	!= 150 )		{ SetEntProp(entity, Prop_Data, "m_iHealth", g_iCvarHealthClown);	SetEntProp(entity, Prop_Data, "m_iMaxHealth", g_iCvarHealthClown); }
			}

			case GENDER_JIMMY:
			{
				if( g_iCvarHealthJimmy	!= 3000 )		{ SetEntProp(entity, Prop_Data, "m_iHealth", g_iCvarHealthJimmy);	SetEntProp(entity, Prop_Data, "m_iMaxHealth", g_iCvarHealthJimmy); }
			}
		}
	}

	SDKHook(entity, SDKHook_TraceAttack, OnTraceAttack);
	SDKHook(entity, SDKHook_OnTakeDamageAlive, OnTakeDamage);

	g_iMaxHealth[entity] = GetEntProp(entity, Prop_Data, "m_iHealth");

	for( int x = 0; x < 2048; x++ )
	{
		g_fLastHit[entity][x] = 0.0;
	}
}

Action OnTraceAttack(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int hitgroup)
{
	g_bTraceAttack = true;

	// Change the hitgroup here, so it's registered when calling OnTakeDamage, otherwise we won't get the accurate value 
	SetEntProp(victim, Prop_Data, "m_LastHitGroup", hitgroup);

	// Fire this here, but without changing damage, so that wounds can be set as early as possible (TraceAttack = before wounds are set, TraceAttack post = after wounds are set)
	// This way the server doesn't crash or update the wounds conflicting with our changes
	OnTakeDamage(victim, attacker, inflictor, damage, damagetype);

	// Allow damage again
	g_bTraceAttack = false;

	return Plugin_Continue;
}

Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	// Validate entity and timeout on hits
	if( inflictor > MaxClients && inflictor < 2048 )
	{
		int health = GetEntProp(victim, Prop_Data, "m_iHealth");

		if( GetGameTime() > g_fLastHit[victim][inflictor] )
		{
			// Ignore just in case, noticed NaN produced when 0 health, maybe some other bug before plugin was finished
			if( health <= 0 ) return Plugin_Continue;

			// Type of weapon used in attack
			int type;
			static char classname[32];
			GetEdictClassname(inflictor, classname, sizeof(classname));

			if( g_bLeft4Dead2 && (g_fCvarMelee || g_fCvarHeadshotMelee) && strcmp(classname, "weapon_melee") == 0 )		type = 1;
			else if( g_bLeft4Dead2 && g_fCvarChainsaw && strcmp(classname, "weapon_chainsaw") == 0 )					type = 2;
			else if( g_bLeft4Dead2 && g_fCvarLauncher && strcmp(classname, "grenade_launcher_projectile") == 0 )		type = 6;
			else if( (g_fCvarPipebomb || g_fCvarPropane || g_fCvarOxygen) && (strcmp(classname, "pipe_bomb_projectile") == 0 || (g_bPipebombIgnore && strcmp(classname, "prop_physics") == 0 && GetEntProp(inflictor, Prop_Data, "m_iHammerID") == 19712806)) )
			{
				// METHOD 1:
				// Determine if a real pipebomb was created earlier and thrown, else a physics prop explosion just created (using OnEntityCreated to detect pipe_bomb_projectile)
				// if( GetEntPropFloat(inflictor, Prop_Send, "m_flCreateTime") == GetGameTime() )

				// METHOD 2: Seems to work fine, less resource intensive
				if( g_fGameTime == GetGameTime() ) // Physics explosion
					type = g_iPropType; // If physics prop, the break event tells us which type if allowed
				else
					type = 3;
			}

			g_iPropType = 0; // Reset to be sure there are no false positives

			// Damage scales
			if( type )
			{
				switch( type )
				{
					// Melee
					case 1:
					{
						if( g_fCvarMelee )
						{
							switch( g_iCvarMelee2 )
							{
								case 0:		damage = g_fCvarMelee;
								case 1:		damage = g_fCvarMelee * g_iMaxHealth[victim] / 100.0;
								case 2:		damage = g_fCvarMelee * damage / 100.0;
							}
						}

						if( g_fCvarHeadshotMelee && GetEntProp(victim, Prop_Data, "m_LastHitGroup") == 1 )
						{
							damage *= g_fCvarHeadshotMelee;
						}
					}
					// Chainsaw
					case 2:
					{
						switch( g_iCvarChainsaw2 )
						{
							case 0:		damage = g_fCvarChainsaw;
							case 1:		damage = g_fCvarChainsaw * g_iMaxHealth[victim] / 100.0;
							case 2:		damage = g_fCvarChainsaw * damage / 100.0;
						}
					}
					// Pipebomb
					case 3:
					{
						switch( g_iCvarPipebomb2 )
						{
							case 0:		damage = g_fCvarPipebomb;
							case 1:		damage = g_fCvarPipebomb * g_iMaxHealth[victim] / 100.0;
							case 2:		damage = g_fCvarPipebomb * damage / 100.0;
						}
					}
					// Propane
					case 4:
					{
						switch( g_iCvarPropane2 )
						{
							case 0:		damage = g_fCvarPropane;
							case 1:		damage = g_fCvarPropane * g_iMaxHealth[victim] / 100.0;
							case 2:		damage = g_fCvarPropane * damage / 100.0;
						}
					}
					// Oxygen
					case 5:
					{
						switch( g_iCvarOxygen2 )
						{
							case 0:		damage = g_fCvarOxygen;
							case 1:		damage = g_fCvarOxygen * g_iMaxHealth[victim] / 100.0;
							case 2:		damage = g_fCvarOxygen * damage / 100.0;
						}
					}
					// Grenade Launcher
					case 6:
					{
						switch( g_iCvarLauncher2 )
						{
							case 0:		damage = g_fCvarLauncher;
							case 1:		damage = g_fCvarLauncher * g_iMaxHealth[victim] / 100.0;
							case 2:		damage = g_fCvarLauncher * damage / 100.0;
						}
					}
				}

				// Ignore 0 damage, in case max health var is 0 for example
				if( damage <= 0 )
				{
					return Plugin_Continue;
				}

				if( !g_bTraceAttack )
				{
					// Prevent multiple hits from the same weapon in the same few frames otherwise we affect multiple times
					switch( type )
					{
						case 1:		g_fLastHit[victim][inflictor] = GetGameTime() + 0.5;	// Melee, block same swing
						case 2:		g_fLastHit[victim][inflictor] = GetGameTime();			// Chainsaw, block same frame, allow multiple hits
						default:	g_fLastHit[victim][inflictor] = GetGameTime() + 0.1;	// Others, block close hits (just in case), allow multiple hits
					}
				}

				// Prevent certain gibbed wounds, e.g. to stop legless zombies running around after multiple melee hits or explosions
				if( g_bLeft4Dead2 && health - damage > 0.0 )
				{
					DoWounds(victim);
				}

				// Change damage
				if( !g_bTraceAttack )
					return Plugin_Changed;
			}
			else
			{
				// Headshot scale
				if( g_fCvarHeadshot && attacker >= 1 && attacker <= MaxClients && GetClientTeam(attacker) == 2 && GetEntProp(victim, Prop_Data, "m_LastHitGroup") == 1 )
				{
					damage *= g_fCvarHeadshot;

					if( g_bLeft4Dead2 && GetEntProp(victim, Prop_Data, "m_iHealth") - damage > 0.0 )
					{
						DoWounds(victim);
					}

					if( !g_bTraceAttack )
						return Plugin_Changed;
				}
			}
		}
		else
		{
			// Prevent insta-kill from headshots - triggers on multiple hits with 0.0 damage killing them.
			if( !g_bTraceAttack && g_fCvarHeadshot && health - damage > 0.0 && GetEntProp(victim, Prop_Data, "m_LastHitGroup") == 1 )
			{
				SetEntProp(victim, Prop_Data, "m_LastHitGroup", 2);
			}
		}
	}
	else
	{
		// Block insta-kill with melee weapon (prevents common death when multiple are hit at once):
		if( !g_bTraceAttack && g_bLeft4Dead2 && g_fCvarMelee && attacker >= 1 && attacker <= MaxClients && GetGameTime() - g_fMelee[attacker] < 0.6 )
		{
			float test = GetEntProp(victim, Prop_Data, "m_iHealth") - damage;

			if( test == 0.0 || test == -1.0 )
			{
				return Plugin_Handled;
			}
		}
	}

	// Prevent insta-kill from headshots - for weapons etc
	if( !g_bCvarHeadshotOne && GetEntProp(victim, Prop_Data, "m_LastHitGroup") == 1 )
	{
		bool changed;

		// Headshot scale
		if( g_fCvarHeadshot && attacker >= 1 && attacker <= MaxClients && GetClientTeam(attacker) == 2)
		{
			damage *= g_fCvarHeadshot;
			changed = true;
		}

		// Prevent headless and insta-kill
		if( GetEntProp(victim, Prop_Data, "m_iHealth") - damage > 0.0 )
		{
			DoWounds(victim);
		}

		if( changed && !g_bTraceAttack )
		{
			return Plugin_Changed;
		}
	}

	return Plugin_Continue;
}

void DoWounds(int victim)
{
	bool headless;

	if( GetEntProp(victim, Prop_Data, "m_LastHitGroup") == 1 )
	{
		headless = true;

		// Prevent insta-kill from headshots
		SetEntProp(victim, Prop_Data, "m_LastHitGroup", 2);
	}



	// Main wounds changing routine to prevent: armless, legless, headless
	int wound1 = GetEntProp(victim, Prop_Send, "m_iRequestedWound1");
	int wound2 = GetEntProp(victim, Prop_Send, "m_iRequestedWound2");
	int gender = GetEntProp(victim, Prop_Send, "m_Gender");

	switch( gender )
	{
		case GENDER_MALE1, GENDER_MALE2, GENDER_MALE3, GENDER_MALE4, GENDER_MALE5, GENDER_MALE6, GENDER_MALE7, GENDER_MALE8:
		{
			switch( wound1 )
			{
				case PART_G, PART_H, PART_I, PART_J, PART_K, PART_L, PART_M, PART_N, PART_O, PART_P, PART_Q, PART_R:
				{
					int wound = GetRandomInt(RANDOM_WOUND_MIN, RANDOM_WOUND_MAX);

					SetEntProp(victim, Prop_Send, "m_iRequestedWound1", wound);
					if( wound2 == -1 )
						SetEntProp(victim, Prop_Send, "m_iRequestedWound2", wound);
				}
				/*
				case HEAD_1, HEAD_2:
				{
					SetEntProp(victim, Prop_Send, "m_iRequestedWound1", 6);
					if( wound2 == -1 )
						SetEntProp(victim, Prop_Send, "m_iRequestedWound2", 6);
				}
				*/
				case -1:
				{
					if( headless )
					{
						SetHeadless(victim);
					}
				}
			}

			switch( wound2 )
			{
				case PART_G, PART_H, PART_I, PART_J, PART_K, PART_L, PART_M, PART_N, PART_O, PART_P, PART_Q, PART_R:
				{
					int wound = GetRandomInt(RANDOM_WOUND_MIN, RANDOM_WOUND_MAX);

					if( wound1 == -1 )
						SetEntProp(victim, Prop_Send, "m_iRequestedWound1", wound);
					SetEntProp(victim, Prop_Send, "m_iRequestedWound2", wound);
				}
				/*
				case HEAD_1, HEAD_2:
				{
					if( wound1 == -1 )
						SetEntProp(victim, Prop_Send, "m_iRequestedWound1", 6);
					SetEntProp(victim, Prop_Send, "m_iRequestedWound2", 6);
				}
				*/
				case -1:
				{
					if( headless )
					{
						SetHeadless(victim);
					}
				}
			}
		}

		case GENDER_FEMALE_L4D1, GENDER_FEMALE_L4D2:
		{
			switch( wound1 )
			{
				case PART_E, PART_G, PART_H, PART_I, PART_J, PART_L, PART_M, PART_N, PART_O, PART_P, PART_Q, PART_S:
				{
					int wound = GetRandomInt(RANDOM_WOUND_MIN, RANDOM_WOUND_MAX);

					SetEntProp(victim, Prop_Send, "m_iRequestedWound1", wound);
					if( wound2 == -1 )
						SetEntProp(victim, Prop_Send, "m_iRequestedWound2", wound);
				}
				/*
				case HEAD_1, HEAD_2:
				{
					SetEntProp(victim, Prop_Send, "m_iRequestedWound1", 6);
					if( wound2 == -1 )
						SetEntProp(victim, Prop_Send, "m_iRequestedWound2", 6);
				}
				*/
				case -1:
				{
					if( headless )
					{
						SetHeadless(victim);
					}
				}
			}

			switch( wound2 )
			{
				case PART_E, PART_G, PART_H, PART_I, PART_J, PART_L, PART_M, PART_N, PART_O, PART_P, PART_Q, PART_S:
				{
					int wound = GetRandomInt(RANDOM_WOUND_MIN, RANDOM_WOUND_MAX);

					if( wound1 == -1 )
						SetEntProp(victim, Prop_Send, "m_iRequestedWound1", wound);
					SetEntProp(victim, Prop_Send, "m_iRequestedWound2", wound);
				}
				/*
				case HEAD_1, HEAD_2:
				{
					if( wound1 == -1 )
						SetEntProp(victim, Prop_Send, "m_iRequestedWound1", 6);
					SetEntProp(victim, Prop_Send, "m_iRequestedWound2", 6);
				}
				*/
				case -1:
				{
					if( headless )
					{
						SetHeadless(victim);
					}
				}
			}
		}

		case GENDER_CEDA:
		{
			switch( wound1 )
			{
				case PART_B, PART_C, PART_F:
				{
					int wound = GetRandomInt(RANDOM_WOUND_CEDA_MIN, RANDOM_WOUND_CEDA_MAX);

					if( wound2 == -1 )
						SetEntProp(victim, Prop_Send, "m_iRequestedWound1", wound);
					SetEntProp(victim, Prop_Send, "m_iRequestedWound2", wound);
				}
			}

			switch( wound2 )
			{
				case PART_B, PART_C, PART_F:
				{
					int wound = GetRandomInt(RANDOM_WOUND_CEDA_MIN, RANDOM_WOUND_CEDA_MAX);

					if( wound1 == -1 )
						SetEntProp(victim, Prop_Send, "m_iRequestedWound1", wound);
					SetEntProp(victim, Prop_Send, "m_iRequestedWound2", wound);
				}
			}
		}

		case GENDER_RIOT:
		{
			switch( wound1 )
			{
				case PART_A, PART_B, PART_C:
				{
					int wound = GetRandomInt(RANDOM_WOUND_RIOT_MIN, RANDOM_WOUND_RIOT_MAX);

					SetEntProp(victim, Prop_Send, "m_iRequestedWound1", wound);
					if( wound2 == -1 )
						SetEntProp(victim, Prop_Send, "m_iRequestedWound2", wound);
				}
			}

			switch( wound2 )
			{
				case PART_A, PART_B, PART_C:
				{
					int wound = GetRandomInt(RANDOM_WOUND_RIOT_MIN, RANDOM_WOUND_RIOT_MAX);

					if( wound1 == -1 )
						SetEntProp(victim, Prop_Send, "m_iRequestedWound1", wound);
					SetEntProp(victim, Prop_Send, "m_iRequestedWound2", wound);
				}
			}
		}
	}
}

void SetHeadless(int victim)
{
	// Set headless to half-head wounds
	if( GetEntProp(victim, Prop_Send, "m_iRequestedWound1") == -1 )
		SetEntProp(victim, Prop_Send, "m_iRequestedWound1", 6);

	if( GetEntProp(victim, Prop_Send, "m_iRequestedWound2") == -1 )
		SetEntProp(victim, Prop_Send, "m_iRequestedWound2", 6);
}