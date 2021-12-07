/*
*	Common Infected Health - PipeBomb, Physics and Melee Damage
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



#define PLUGIN_VERSION		"1.4"

/*=======================================================================================
	Plugin Info:

*	Name	:	[L4D & L4D2] Common Infected - Damage Received
*	Author	:	SilverShot
*	Descrp	:	Specify or scale the damage Pipebombs, Propane, Oxygen, Grenade Launcher, Melee and Chainsaw damage caused to common infected.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=332832
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

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

// models/infected/
#define MODEL_CEDA			"common_male_ceda.mdl"
#define MODEL_CLOWN			"common_male_clown.mdl"
#define MODEL_FALLEN		"common_male_fallen_survivor.mdl"
#define MODEL_JIMMY			"common_male_jimmy.mdl"
#define MODEL_MUD			"common_male_mud.mdl"
#define MODEL_RIOT			"common_male_riot.mdl"
#define MODEL_ROAD			"common_male_roadcrew.mdl"


ConVar g_hCvarAllow, g_hCvarMPGameMode, g_hCvarModes, g_hCvarModesOff, g_hCvarModesTog, g_hCvarChainsaw, g_hCvarChainsaw2, g_hCvarLauncher, g_hCvarLauncher2, g_hCvarMelee, g_hCvarMelee2, g_hCvarOxygen, g_hCvarOxygen2, g_hCvarPipebomb, g_hCvarPipebomb2, g_hCvarPropane, g_hCvarPropane2;
ConVar g_hCvarHealthCeda, g_hCvarHealthClown, g_hCvarHealthFallen, g_hCvarHealthJimmy, g_hCvarHealthMud, g_hCvarHealthRiot, g_hCvarHealthRoad;
bool g_bCvarAllow, g_bLeft4Dead2, g_bPipebombIgnore;
int g_iMaxHealth[2048], g_iPropType, g_iCvarChainsaw2, g_iCvarLauncher2, g_iCvarMelee2, g_iCvarOxygen2, g_iCvarPipebomb2, g_iCvarPropane2;
int g_iCvarHealthCeda, g_iCvarHealthClown, g_iCvarHealthFallen, g_iCvarHealthJimmy, g_iCvarHealthMud, g_iCvarHealthRiot, g_iCvarHealthRoad;
float g_fLastHit[2048][2048], g_fGameTime, g_fCvarChainsaw, g_fCvarLauncher, g_fCvarMelee, g_fCvarOxygen, g_fCvarPipebomb, g_fCvarPropane;



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
	g_hCvarAllow = CreateConVar(			"l4d_common_health_allow",			"1",			"0=Plugin off, 1=Plugin on.", CVAR_FLAGS );
	g_hCvarModes = CreateConVar(			"l4d_common_health_modes",			"",				"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS );
	g_hCvarModesOff = CreateConVar(			"l4d_common_health_modes_off",		"",				"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS );
	g_hCvarModesTog = CreateConVar(			"l4d_common_health_modes_tog",		"0",			"Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS );
	if( g_bLeft4Dead2 )
	{
		g_hCvarChainsaw = CreateConVar(		"l4d_common_health_chainsaw",		"50.0",			"L4D2 only. 0.0=Off (games default damage). Amount of damage each Chainsaw hit causes to a common infected, or scale according to related cvar.", CVAR_FLAGS );
		g_hCvarChainsaw2 = CreateConVar(	"l4d_common_health_chainsaw2",		"1",			"L4D2 only. 0=Deal the damage value specified. 1=Deal the specified damage value as a percentage of their maximum health. 2=Scale original damage.", CVAR_FLAGS );
		g_hCvarLauncher = CreateConVar(		"l4d_common_health_launcher",		"50.0",			"L4D2 only. 0.0=Off (games default damage). Amount of damage each Grenade Launcher hit causes to a common infected, or scale according to related cvar.", CVAR_FLAGS );
		g_hCvarLauncher2 = CreateConVar(	"l4d_common_health_launcher2",		"1",			"L4D2 only. 0=Deal the damage value specified. 1=Deal the specified damage value as a percentage of their maximum health. 2=Scale original damage.", CVAR_FLAGS );
		g_hCvarMelee = CreateConVar(		"l4d_common_health_melee",			"50.0",			"L4D2 only. 0.0=Off (games default damage). Amount of damage each Melee weapon hit causes to a common infected, or scale according to related cvar.", CVAR_FLAGS );
		g_hCvarMelee2 = CreateConVar(		"l4d_common_health_melee2",			"1",			"L4D2 only. 0=Deal the damage value specified. 1=Deal the specified damage value as a percentage of their maximum health. 2=Scale original damage.", CVAR_FLAGS );

		g_hCvarHealthCeda = CreateConVar(	"l4d_common_health_u_ceda",			"150",			"L4D2 only. Game default: 150. Default amount of health for CEDA Hazmat uncommon infected.", CVAR_FLAGS );
		g_hCvarHealthClown = CreateConVar(	"l4d_common_health_u_clown",		"150",			"L4D2 only. Game default: 150. Default amount of health for Clown uncommon infected.", CVAR_FLAGS );
		g_hCvarHealthFallen = CreateConVar(	"l4d_common_health_u_fallen",		"1000",			"L4D2 only. Game default: 1000. Default amount of health for Fallen Survivor uncommon infected.", CVAR_FLAGS );
		g_hCvarHealthJimmy = CreateConVar(	"l4d_common_health_u_jimmy",		"3000",			"L4D2 only. Game default: 3000. Default amount of health for Jimmy Gibbs Junior uncommon infected.", CVAR_FLAGS );
		g_hCvarHealthMud = CreateConVar(	"l4d_common_health_u_mud",			"150",			"L4D2 only. Game default: 150. Default amount of health for Mud Men uncommon infected.", CVAR_FLAGS );
		g_hCvarHealthRiot = CreateConVar(	"l4d_common_health_u_riot",			"50",			"L4D2 only. Game default: 50. Default amount of health for Riot Security uncommon infected.", CVAR_FLAGS );
		g_hCvarHealthRoad = CreateConVar(	"l4d_common_health_u_road",			"150",			"L4D2 only. Game default: 150. Default amount of health for Road Crew Worker uncommon infected.", CVAR_FLAGS );
	}
	g_hCvarOxygen = CreateConVar(			"l4d_common_health_oxygen",			"100.0",		"0.0=Off (games default damage). Amount of damage each Oxygen Tank explosion causes to a common infected, or scale according to related cvar.", CVAR_FLAGS );
	g_hCvarOxygen2 = CreateConVar(			"l4d_common_health_oxygen2",		"1",			"0=Deal the damage value specified. 1=Deal the specified damage value as a percentage of their maximum health. 2=Scale original damage.", CVAR_FLAGS );
	g_hCvarPropane = CreateConVar(			"l4d_common_health_propane",		"100.0",		"0.0=Off (games default damage). Amount of damage each Propane explosion causes to a common infected, or scale according to related cvar.", CVAR_FLAGS );
	g_hCvarPropane2 = CreateConVar(			"l4d_common_health_propane2",		"1",			"0=Deal the damage value specified. 1=Deal the specified damage value as a percentage of their maximum health. 2=Scale original damage.", CVAR_FLAGS );
	g_hCvarPipebomb = CreateConVar(			"l4d_common_health_pipebomb",		"50.0",			"0.0=Off (games default damage). Amount of damage each PipeBomb explosion causes to a common infected, or scale according to related cvar.", CVAR_FLAGS );
	g_hCvarPipebomb2 = CreateConVar(		"l4d_common_health_pipebomb2",		"0",			"0=Deal the damage value specified. 1=Deal the specified damage value as a percentage of their maximum health. 2=Scale original damage.", CVAR_FLAGS );
	CreateConVar(							"l4d_common_health_version",		PLUGIN_VERSION,	"Molotov Shove plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	AutoExecConfig(true,					"l4d_common_health");

	g_hCvarMPGameMode = FindConVar("mp_gamemode");
	g_hCvarMPGameMode.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesTog.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModes.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesOff.AddChangeHook(ConVarChanged_Allow);
	g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);
	if( g_bLeft4Dead2 )
	{
		g_hCvarChainsaw.AddChangeHook(ConVarChanged_Cvars);
		g_hCvarChainsaw2.AddChangeHook(ConVarChanged_Cvars);
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
	g_hCvarOxygen.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarOxygen2.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarPipebomb.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarPipebomb2.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarPropane.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarPropane2.AddChangeHook(ConVarChanged_Cvars);
}



// ====================================================================================================
//					CVARS
// ====================================================================================================
public void OnConfigsExecuted()
{
	IsAllowed();
}

public void ConVarChanged_Allow(Handle convar, const char[] oldValue, const char[] newValue)
{
	IsAllowed();
}

public void ConVarChanged_Cvars(Handle convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	if( g_bLeft4Dead2 )
	{
		g_fCvarChainsaw = g_hCvarChainsaw.FloatValue;
		g_iCvarChainsaw2 = g_hCvarChainsaw2.IntValue;
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

		HookEvent("round_end",		Event_RoundEnd, EventHookMode_PostNoCopy);
		HookEvent("break_prop",		Event_BreakProp);

		int entity = -1;
		while( (entity = FindEntityByClassname(entity, "infected")) != INVALID_ENT_REFERENCE )
		{
			SDKHook(entity, SDKHook_OnTakeDamageAlive, OnTakeDamage);
			g_iMaxHealth[entity] = GetEntProp(entity, Prop_Data, "m_iHealth");
		}

		ResetVars();
	}

	else if( g_bCvarAllow == true && (bCvarAllow == false || bAllowMode == false) )
	{
		g_bCvarAllow = false;

		UnhookEvent("round_end",	Event_RoundEnd, EventHookMode_PostNoCopy);
		UnhookEvent("break_prop",	Event_BreakProp);

		int entity = -1;
		while( (entity = FindEntityByClassname(entity, "infected")) != INVALID_ENT_REFERENCE )
		{
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

public void OnGamemode(const char[] output, int caller, int activator, float delay)
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

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	ResetVars();
}

public void Event_BreakProp(Event event, const char[] name, bool dontBroadcast)
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

void ResetVars()
{
	g_iPropType = 0;
	g_fGameTime = 0.0;

	for( int i = 0; i < 2048; i++ )
	{
		for( int x = 0; x < 2048; x++ )
		{
			g_fLastHit[i][x] = 0.0;
		}
	}
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if( strcmp(classname, "infected") == 0 )
	{
		// Using OnTakeDamagAlive because of riot zombies (L4D2), otherwise they would take visual damage but not die until struck from behind, this way they don't take damage until they really should
		SDKHook(entity, SDKHook_OnTakeDamageAlive, OnTakeDamage);
		SDKHook(entity, SDKHook_SpawnPost, SpawnPost);
	}
	// else if( strcmp(classname, "pipe_bomb_projectile") == 0 )
	// {
		// SetEntPropFloat(entity, Prop_Send, "m_flCreateTime", GetGameTime());
	// }
}

public void SpawnPost(int entity)
{
	// Get maximum health on spawn, supports "Mutant Zombies" plugin for example, maybe some other plugins require a longer delay, either next frame or e.g. 0.1 timer.

	if( g_bLeft4Dead2 )
	{
		static char model[64];
		GetEntPropString(entity, Prop_Data, "m_ModelName", model, sizeof(model));

		if(			g_iCvarHealthCeda	!= 150	&&	strcmp(model[16], MODEL_CEDA) == 0 )	SetEntProp(entity, Prop_Data, "m_iHealth", g_iCvarHealthCeda);
		else if(	g_iCvarHealthClown	!= 150	&&	strcmp(model[16], MODEL_CLOWN) == 0 )	SetEntProp(entity, Prop_Data, "m_iHealth", g_iCvarHealthClown);
		else if(	g_iCvarHealthFallen	!= 1000	&&	strcmp(model[16], MODEL_FALLEN) == 0 )	SetEntProp(entity, Prop_Data, "m_iHealth", g_iCvarHealthFallen);
		else if(	g_iCvarHealthJimmy	!= 3000	&&	strcmp(model[16], MODEL_JIMMY) == 0 )	SetEntProp(entity, Prop_Data, "m_iHealth", g_iCvarHealthJimmy);
		else if(	g_iCvarHealthMud	!= 150	&&	strcmp(model[16], MODEL_MUD) == 0 )		SetEntProp(entity, Prop_Data, "m_iHealth", g_iCvarHealthMud);
		else if(	g_iCvarHealthRiot	!= 50	&&	strcmp(model[16], MODEL_RIOT) == 0 )	SetEntProp(entity, Prop_Data, "m_iHealth", g_iCvarHealthRiot);
		else if(	g_iCvarHealthRoad	!= 150	&&	strcmp(model[16], MODEL_ROAD) == 0 )	SetEntProp(entity, Prop_Data, "m_iHealth", g_iCvarHealthRoad);
	}

	g_iMaxHealth[entity] = GetEntProp(entity, Prop_Data, "m_iHealth");
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	// Validate entity and timeout on hits
	if( inflictor > MaxClients && inflictor < 2048 && GetGameTime() > g_fLastHit[victim][inflictor] )
	{
		// Ignore just in case, noticed NaN produced when 0 health, maybe some other bug before plugin was finished
		int health = GetEntProp(victim, Prop_Data, "m_iHealth");
		if( health <= 0 ) return Plugin_Continue;

		// Type of weapon used in attack
		int type;
		static char classname[32];
		GetEdictClassname(inflictor, classname, sizeof(classname));

		if( g_bLeft4Dead2 && g_fCvarMelee && strcmp(classname, "weapon_melee") == 0 )								type = 1;
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

		if( type )
		{
			switch( type )
			{
				// Melee
				case 1:
				{
					switch( g_iCvarMelee2 )
					{
						case 0:		damage = g_fCvarMelee;
						case 1:		damage = g_fCvarMelee * g_iMaxHealth[victim] / 100.0;
						case 2:		damage = g_fCvarMelee * damage / 100.0;
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

			// Ignore damage killing the zombie otherwise the zombie would disappear instantly, don't think we actually need to damage them, expecting them to die normally
			// if( health - damage <= 0 )
			// {
				// return Plugin_Continue;

				// g_fLastHit[victim][inflictor] = GetGameTime() + 0.1; // Setting this to avoid affecting on multiple hits within the same frame (e.g. melee weapons)
				// damage = health - 1.0;
				// return Plugin_Changed;
			// }

			// Ignore 0 damage, in case max health var is 0 for example
			if( damage <= 0 )
			{
				return Plugin_Continue;
			}

			// Prevent multiple hits from the same weapon in the same few frames otherwise we affect multiple times
			switch( type )
			{
				case 1:		g_fLastHit[victim][inflictor] = GetGameTime() + 0.5;	// Melee, block same swing
				case 2:		g_fLastHit[victim][inflictor] = GetGameTime();			// Chainsaw, block same frame, allow multiple hits
				default:	g_fLastHit[victim][inflictor] = GetGameTime() + 0.1;	// Others, block close hits (just in case), allow multiple hits
			}

			// PrintToChatAll("Hurt %d with %f (%f)", victim, damage, health - damage);

			// Prevent certain gibbed wounds, e.g. to stop legless zombies running around after multiple melee hits or explosions
			if( health - damage > 0.0 )
			{
				SetEntProp(victim, Prop_Send, "m_iRequestedWound1", 0);
				SetEntProp(victim, Prop_Send, "m_iRequestedWound2", 0);
			}

			// Change damage
			return Plugin_Changed;
		}
	}

	return Plugin_Continue;
}