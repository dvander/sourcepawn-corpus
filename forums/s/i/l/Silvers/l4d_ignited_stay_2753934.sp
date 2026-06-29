/*
*	Throwables Stay Ignited
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



#define PLUGIN_VERSION 		"1.9"

/*======================================================================================
	Plugin Info:

*	Name	:	[L4D & L4D2] Throwables Stay Ignited
*	Author	:	SilverShot
*	Descrp	:	Keeps ignited throwables on fire and prevents them from randomly extinguishing. Adjust burning duration. Can also block picking up ignited.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=333679
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.9 (28-Dec-2022)
	- Fixed not respawning Scavenge gascans under certain conditions. Thanks to "thewintersoldier97" for reporting.

1.8 (27-Dec-2022)
	- Fixed not respawning Scavenge gascans on the first map from server start. Thanks to "HarryPotter" for reporting.
	- Fixed not respawning Scavenge gascans when "Scavenge Score Fix - Gascan Pouring" plugin is installed.

1.7 (06-Nov-2022)
	- Fixed Oxygen Tanks not whistling before exploding. Thanks to "Iizuka07" for reporting.

1.6 (14-Jul-2022)
	- Changes to fix warnings when compiling on SourceMod 1.11.

1.5 (10-Oct-2021)
	- Fixed an error that could occur with invalid clients.

1.4 (07-Oct-2021)
	- Fixed not respawning Scavenge gascans correctly.
	- Minor changes to code to clean and fix a potential issue with respawning gascans.
	- Prevents conflicts with "Scavenge Score Fix" plugin version 2.3+ when using "l4d2_scavenge_score_respawn" feature.

1.3 (29-Sep-2021)
	- Changed method of creating an explosive to prevent it being visible (still sometimes shows, but probably less).
	- L4D2: Fixed GasCans not registering the thrower for damage credit when exploding.

1.2 (04-Aug-2021)
	- L4D2: Made the plugin compatible with "Saferoom Lock: Scavenge" plugin by "Eärendil". Thanks to "Maur0" for reporting.

1.1 (04-Aug-2021)
	- Fixed Scavenge GasCans not respawning and skin not showing when held. Thanks to "Maur0" for reporting.
	- Fixed throwables exploding in hand when owner take damage. Thanks to "Maur0" for reporting.
	- L4D2: Added cvar "l4d_ignited_respawn" to control when to respawn Scavenge gascans after they are destroyed.

1.0 (29-Jul-2021)
	- Initial release.

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define CVAR_FLAGS			FCVAR_NOTIFY
#define DEBUGGING			0

#define MODEL_GASCAN		"models/props_junk/gascan001a.mdl"
#define MODEL_CRATE			"models/props_junk/explosive_box001.mdl"
#define MODEL_OXYGEN		"models/props_equipment/oxygentank01.mdl"
#define MODEL_PROPANE		"models/props_junk/propanecanister001a.mdl"

// After a player is ignited/walks in fire, the throwable flames will disappear a second or so later. This fixes that by equipping a new throwable and igniting it.
// Set to 0.0 to disable.
#define REFIRE_TIME			0.3

// Maximum range for Scavenge gascans to match with their spawner
#define RANGE_MAX			30.0


ConVar g_hCvarAllow, g_hCvarModes, g_hCvarModesOff, g_hCvarModesTog, g_hCvarMPGameMode, g_hCvarOxygen, g_hCvarRespawn, g_hCvarTimeF, g_hCvarTimeG, g_hCvarTimeP, g_hCvarTimeO, g_hCvarTypes;
bool g_bCvarAllow, g_bMapStarted, g_bLeft4Dead2, g_bRemovingItem, g_bBlockGrab;
int g_iCvarOxygen, g_iCvarTypes, g_iDroppingItem;
float g_fCvarRespawn, g_fCvarTimeF, g_fCvarTimeG, g_fCvarTimeP, g_fCvarTimeO;
float g_fFireTime[2048];
int g_iLastClient[2048];
int g_iHolding2[MAXPLAYERS+1];
int g_iHolding1[MAXPLAYERS+1];
int g_iOxygen[MAXPLAYERS+1];
int g_iFlamed;		// Last entity on fire when dropped/grabbed - tracking entity changes
int g_iSpawned;		// Last oxygen tank damaged when dropped - tracking entity changes
Handle g_hTimerReflame[MAXPLAYERS+1];
int g_iScavenge[2048];
int g_iPlayerSpawn, g_iRoundStart;



// ====================================================================================================
//					PLUGIN START
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D & L4D2] Throwables Stay Ignited",
	author = "SilverShot",
	description = "Keeps ignited throwables on fire and prevents them from randomly extinguishing. Adjust burning duration. Can also block picking up ignited.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=333679"
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
	// ====================
	// CVARS
	// ====================
	g_hCvarAllow =			CreateConVar(	"l4d_ignited_allow",			"1",							"0=Plugin off, 1=Plugin on.", CVAR_FLAGS );
	g_hCvarModes =			CreateConVar(	"l4d_ignited_modes",			"",								"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS );
	g_hCvarModesOff =		CreateConVar(	"l4d_ignited_modes_off",		"",								"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS );
	g_hCvarModesTog =		CreateConVar(	"l4d_ignited_modes_tog",		"0",							"Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS );
	g_hCvarOxygen =			CreateConVar(	"l4d_ignited_oxygen",			"1",							"What to do with damaged Oxygen Tanks that are about to explode: 0=Prevent picking up. 1=Explode in players hands.", CVAR_FLAGS );
	if( g_bLeft4Dead2 )
	{
		g_hCvarRespawn =	CreateConVar(	"l4d_ignited_respawn",			"20.0",							"How many seconds after a Scavenge Gascan is destroyed until it respawns.", CVAR_FLAGS );
		g_hCvarTimeF =		CreateConVar(	"l4d_ignited_time_fireworks",	"2.0",							"How many seconds should Firework Crates stay ignited on fire before exploding.", CVAR_FLAGS, true, 0.2 );
	}
	g_hCvarTimeG =			CreateConVar(	"l4d_ignited_time_gascan",		"2.0",							"How many seconds should Gascans stay ignited on fire before exploding.", CVAR_FLAGS, true, 0.2 );
	g_hCvarTimeO =			CreateConVar(	"l4d_ignited_time_oxygen",		"2.0",							"How many seconds should Oxygen Tanks stay ignited on fire before exploding.", CVAR_FLAGS, true, 0.2 );
	g_hCvarTimeP =			CreateConVar(	"l4d_ignited_time_propane",		"2.0",							"How many seconds should Propane Tanks stay ignited on fire before exploding.", CVAR_FLAGS, true, 0.2 );
	g_hCvarTypes =			CreateConVar(	"l4d_ignited_types",			"15",							"Which throwables can be picked up while ignited, otherwise they cannot. 0=All, 1=GasCan, 2=Oxygen Tank, 4=Propane Tank, 8=Firework Crate, 15=All. Add numbers together.", CVAR_FLAGS );
	CreateConVar(							"l4d_ignited_version",			PLUGIN_VERSION,					"Throwables Stay Ignited plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	AutoExecConfig(true,					"l4d_ignited");

	g_hCvarMPGameMode = FindConVar("mp_gamemode");
	g_hCvarMPGameMode.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModes.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesOff.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesTog.AddChangeHook(ConVarChanged_Allow);
	g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);
	g_hCvarOxygen.AddChangeHook(ConVarChanged_Cvars);
	if( g_bLeft4Dead2 )
	{
		g_hCvarRespawn.AddChangeHook(ConVarChanged_Cvars);
		g_hCvarTimeF.AddChangeHook(ConVarChanged_Cvars);
	}
	g_hCvarTimeG.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarTimeP.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarTimeO.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarTypes.AddChangeHook(ConVarChanged_Cvars);

	g_iRoundStart = 1;

	// ====================
	// Test commands
	// ====================
	// RegAdminCmd("sm_flame",		CmdFlame,	ADMFLAG_ROOT, "Ignites the currently held gascan.");
	// RegAdminCmd("sm_flameme",	CmdFlameMe,	ADMFLAG_ROOT, "Ignites the player for testing.");
	// RegAdminCmd("sm_ignites",	CmdIgnite,	ADMFLAG_ROOT, "Ignites the entity aimed at.");
}



// ====================================================================================================
//					COMMANDS
// ====================================================================================================
stock Action CmdFlameMe(int client, int args)
{
	SDKHooks_TakeDamage(client, 0, 0, 1.0, DMG_BURN);
	return Plugin_Handled;
}

stock Action CmdIgnite(int client, int args)
{
	int entity = GetClientAimTarget(client, false);
	if( entity != -1 )
		IgniteEntity(entity, 60.0);
	return Plugin_Handled;
}

stock Action CmdFlame(int client, int args)
{
	g_iFlamed = 0;

	int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if( weapon != -1 )
	{
		float time;
		char classname[32];
		GetEdictClassname(weapon, classname, sizeof(classname));

		if(							strcmp(classname[7], "gascan") == 0 )					time = g_fCvarTimeG;
		else if(					strcmp(classname[7], "oxygentank") == 0 )				time = g_fCvarTimeO;
		else if(					strcmp(classname[7], "propanetank") == 0 )				time = g_fCvarTimeP;
		else if( g_bLeft4Dead2 &&	strcmp(classname[7], "fireworkcrate") == 0 )			time = g_fCvarTimeF;

		if( time )
		{
			if( g_bLeft4Dead2 )		g_iHolding2[client] = EntIndexToEntRef(weapon);
			else					g_iHolding1[client] = weapon;

			g_fFireTime[weapon] = GetGameTime() + time;

			AcceptEntityInput(weapon, "Ignite");

			int flame = GetEntPropEnt(weapon, Prop_Send, "m_hEffectEntity");
			if( flame != -1 && IsValidEntity(flame) )
			{
				SetEntPropFloat(flame, Prop_Data, "m_flLifetime", GetGameTime() + time);
				ReplyToCommand(client, "Ignited weapon (%d) flame (%d)", weapon, flame);
			}
		}
	}

	return Plugin_Handled;
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
	g_iFlamed = 0;
	g_iRoundStart = 0;
	g_iPlayerSpawn = 0;
	g_bMapStarted = false;
}

public void OnConfigsExecuted()
{
	IsAllowed();
}

void ConVarChanged_Cvars(Handle convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_iCvarOxygen = g_hCvarOxygen.IntValue;
	if( g_bLeft4Dead2 )
	{
		g_fCvarTimeF = g_hCvarTimeF.FloatValue;
		g_fCvarRespawn = g_hCvarRespawn.FloatValue;
	}
	g_fCvarTimeG = g_hCvarTimeG.FloatValue;
	g_fCvarTimeP = g_hCvarTimeP.FloatValue;
	g_fCvarTimeO = g_hCvarTimeO.FloatValue;
	g_iCvarTypes = g_hCvarTypes.IntValue;
}

void ConVarChanged_Allow(Handle convar, const char[] oldValue, const char[] newValue)
{
	IsAllowed();
}

void IsAllowed()
{
	bool bCvarAllow = g_hCvarAllow.BoolValue;
	bool bAllowMode = IsAllowedGameMode();
	GetCvars();

	if( g_bCvarAllow == false && bCvarAllow == true && bAllowMode == true )
	{
		// Hook clients
		for( int i = 1; i <= MaxClients; i++ )
		{
			if( IsClientInGame(i) )
			{
				SDKHook(i, SDKHook_WeaponSwitch, OnSwitch);

				#if REFIRE_TIME
				SDKHook(i, SDKHook_OnTakeDamage, OnPlayerDamage);
				#endif
			}
		}

		// Hook entities
		int entity = -1;
		while( (entity = FindEntityByClassname(entity, "physics_prop")) != INVALID_ENT_REFERENCE )
		{
			static char modelname[45];
			GetEntPropString(entity, Prop_Data, "m_ModelName", modelname, sizeof(modelname));

			if( strcmp(modelname, MODEL_OXYGEN) == 0 )
			{
				SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
			}
		}

		// Events
		if( g_bLeft4Dead2 )
			HookEvent("weapon_drop_to_prop",	Event_DropToProp);
		HookEvent("round_end",					Event_RoundEnd,		EventHookMode_PostNoCopy);
		HookEvent("round_start",				Event_RoundStart,	EventHookMode_PostNoCopy);
		HookEvent("player_spawn",				Event_PlayerSpawn,	EventHookMode_PostNoCopy);

		// Find Scavenge gascans and their spawner
		if( g_bLeft4Dead2 )
		{
			FindScavengeGas();
		}

		g_bCvarAllow = true;
	}

	else if( g_bCvarAllow == true && (bCvarAllow == false || bAllowMode == false) )
	{
		// Unhook clients
		for( int i = 1; i <= MaxClients; i++ )
		{
			if( IsClientInGame(i) )
			{
				SDKUnhook(i, SDKHook_WeaponSwitch, OnSwitch);

				#if REFIRE_TIME
				SDKUnhook(i, SDKHook_OnTakeDamage, OnPlayerDamage);
				#endif
			}
		}

		// Unhook entities
		int entity = -1;
		while( (entity = FindEntityByClassname(entity, "physics_prop")) != INVALID_ENT_REFERENCE )
		{
			static char modelname[45];
			GetEntPropString(entity, Prop_Data, "m_ModelName", modelname, sizeof(modelname));

			if( strcmp(modelname, MODEL_OXYGEN) == 0 )
			{
				SDKUnhook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
			}
		}

		// Events
		if( g_bLeft4Dead2 )
			UnhookEvent("weapon_drop_to_prop",	Event_DropToProp);
		UnhookEvent("round_end",				Event_RoundEnd,		EventHookMode_PostNoCopy);
		UnhookEvent("round_start",				Event_RoundStart, EventHookMode_PostNoCopy);
		UnhookEvent("player_spawn",				Event_PlayerSpawn,	EventHookMode_PostNoCopy);

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
			if( IsValidEntity(entity) ) // Because sometimes "PostSpawnActivate" seems to 3 the ent.
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
public void OnClientPutInServer(int client)
{
	if( g_bCvarAllow )
	{
		SDKHook(client, SDKHook_WeaponSwitch, OnSwitch);

		#if REFIRE_TIME
		SDKHook(client, SDKHook_OnTakeDamage, OnPlayerDamage);
		#endif
	}
}

public void OnClientDisconnect(int client)
{
	delete g_hTimerReflame[client];
}

// ====================
// Re-ignite the held throwable if player ran into fire, since this makes the flames on the held object disappear
// ====================
Action OnPlayerDamage(int client, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if( (damagetype & DMG_BURN|DMG_SLOWBURN) && GetClientTeam(client) == 2 )
	{
		// Verify holding object on fire
		if( g_bLeft4Dead2 ?
			g_iHolding2[client] && EntRefToEntIndex(g_iHolding2[client]) != INVALID_ENT_REFERENCE :
			g_iHolding1[client] && EntRefToEntIndex(g_iHolding1[client]) != INVALID_ENT_REFERENCE )
		{
			int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if( weapon != -1 )
			{
				char classname[32];
				GetEdictClassname(weapon, classname, sizeof(classname));
				if(
					strcmp(classname[7], "gascan") == 0 ||
					strcmp(classname[7], "oxygentank") == 0 ||
					strcmp(classname[7], "propanetank") == 0 ||
					(g_bLeft4Dead2 && strcmp(classname[7], "fireworkcrate") == 0)
				)
				{
					delete g_hTimerReflame[client];
					g_hTimerReflame[client] = CreateTimer(REFIRE_TIME, TimerReflame, GetClientUserId(client));
				}
			}
		}
	}

	return Plugin_Continue;
}

Action TimerReflame(Handle timer, int client)
{
	if( (client = GetClientOfUserId(client)) && IsClientInGame(client) )
	{
		g_hTimerReflame[client] = null;

		int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if( weapon != -1 )
		{
			char classname[32];
			GetEdictClassname(weapon, classname, sizeof(classname));
			if(
				strcmp(classname[7], "gascan") == 0 ||
				strcmp(classname[7], "oxygentank") == 0 ||
				strcmp(classname[7], "propanetank") == 0 ||
				(g_bLeft4Dead2 && strcmp(classname[7], "fireworkcrate") == 0)
			)
			{
				OnUseGrab(weapon, client);
			}
		}
	}

	return Plugin_Continue;
}

// ====================
// Watch for flame creation and oxygen tank
// ====================
public void OnEntityCreated(int entity, const char[] classname)
{
	if( !g_bCvarAllow ) return;

	if( strcmp(classname, "entityflame") == 0 )
	{
		if( g_bLeft4Dead2 )
		{
			// Prevent multiple timers firing when ignited in hands
			if( !g_bBlockGrab )
			{
				SDKHook(entity, SDKHook_Spawn, OnSpawnFire);
			}
		}
		else
		{
			OnSpawnFire(entity);
		}
	}
	else if( strcmp(classname, "physics_prop") == 0 )
	{
		if( g_bRemovingItem )
		{
			RemoveEntity(entity);
			return;
		}
		else if( !g_bLeft4Dead2 )
		{
			g_iDroppingItem = EntIndexToEntRef(entity);
		}

		SDKHook(entity, SDKHook_SpawnPost, OnSpawnAir);
	}
	else if( g_bLeft4Dead2 && strcmp(classname, "weapon_gascan") == 0 )
	{
		#if DEBUGGING
		PrintToChatAll("IS: weapon_gascan SPAWNED %d", entity);
		#endif

		CreateTimer(0.1, TimerDelayedSpawn, EntIndexToEntRef(entity));
	}
}

// Delay before finding matching spawner. Next frame required for getting vPos, but too early because the gascan takes time to fall into position so it would be near enough to spawner
Action TimerDelayedSpawn(Handle timer, int entity)
{
	entity = EntRefToEntIndex(entity);

	if( entity != INVALID_ENT_REFERENCE )
	{
		#if DEBUGGING
		PrintToChatAll("IS: TimerDelayedSpawn FIND %d", entity);
		#endif

		FindScavengeGas(entity);
	}

	return Plugin_Continue;
}

// ====================
// OXYGEN TANK
// ====================
// Watch Oxygen Tanks for damage
// With no life they whistle for 2.0 seconds then explode, but if picked up this cancels the explosion
// This fixes that
// ====================
void OnSpawnAir(int entity)
{
	static char modelname[45];
	GetEntPropString(entity, Prop_Data, "m_ModelName", modelname, sizeof(modelname));

	if( strcmp(modelname, MODEL_OXYGEN) == 0 )
	{
		g_iSpawned = entity;
		SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
	}
}

Action OnTakeDamage(int entity, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	// Taken more damage than health, it's going to explode!
	if( GetEntProp(entity, Prop_Data, "m_iHealth") - RoundToFloor(damage) <= 0.0 )
	{
		SDKUnhook(entity, SDKHook_OnTakeDamage, OnTakeDamage);

		g_fFireTime[entity] = GetGameTime() + g_fCvarTimeO;

		// Block picking up, or watch for when picked up
		if( g_iCvarOxygen == 0 )			SDKHook(entity, SDKHook_Use, OnUseOxygenBlock);
		else								SDKHook(entity, SDKHook_Use, OnUseOxygenGrab);
	}

	return Plugin_Continue;
}

Action OnUseOxygenGrab(int entity, int client)
{
	// Must wait a frame to get the new held entity index.
	// When picking up a prop_physics Oxygen Tank (and other prop_physics), it changes to weapon_oxygentank (etc) when held.
	// Not passing entity ref because it won't exist, we simply need the index to get damage/detonation time.
	DataPack dPack = new DataPack();
	dPack.WriteCell(GetClientUserId(client));
	dPack.WriteCell(entity);
	RequestFrame(OnNextFrameOxygen, dPack);

	return Plugin_Continue;
}

void OnNextFrameOxygen(DataPack dPack)
{
	dPack.Reset();
	int client = dPack.ReadCell();
	int entity = dPack.ReadCell();
	delete dPack;

	if( (client = GetClientOfUserId(client)) && IsClientInGame(client) )
	{
		int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");

		char classname[64];
		GetEdictClassname(weapon, classname, sizeof(classname));
		if( strcmp(classname, "weapon_oxygentank") ==0 )
		{
			g_fFireTime[weapon] = g_fFireTime[entity];
			g_iOxygen[client] = EntIndexToEntRef(weapon);

			CreateTimer(0.1, TimerTest, EntIndexToEntRef(weapon), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

Action OnUseOxygenBlock(int entity, int client)
{
	return Plugin_Handled;
}



// ====================
// ENTITY FLAME
// ====================
// Watch for entityflame entities spawning
// ====================
void OnSpawnFire(int entity)
{
	// Only on next frame is the owner populated
	RequestFrame(OnNextFrameSpawnFire, EntIndexToEntRef(entity));
}

void OnNextFrameSpawnFire(int entity)
{
	entity = EntRefToEntIndex(entity);
	if( entity == INVALID_ENT_REFERENCE || !IsValidEntity(entity) ) return;

	// Is being held by someone?
	int attached = GetEntPropEnt(entity, Prop_Send, "m_hEntAttached");

	// Flames can attach to clients etc, we want to verify it's attached to target classnames
	if( attached > MaxClients )
	{
		static char sTemp[45];
		GetEdictClassname(attached, sTemp, sizeof(sTemp));

		// Gascan - L4D2 uses the weapon_gascan entity, L4D1 uses prop_physics, but we'll check both anyway
		if( strcmp(sTemp[7], "gascan") == 0 )
		{
			SetEntPropFloat(entity, Prop_Data, "m_flLifetime", GetGameTime() + g_fCvarTimeG);

			if( g_iFlamed )
			{
				g_fFireTime[entity] = g_fFireTime[g_iFlamed];
				g_fFireTime[attached] = g_fFireTime[g_iFlamed];
				g_iFlamed = 0;
			} else {
				g_fFireTime[entity] = GetGameTime() + g_fCvarTimeG;
				g_fFireTime[attached] = GetGameTime() + g_fCvarTimeG;
			}

			SDKHook(attached, SDKHook_OnTakeDamage, OnPropTakeDamage);

			#if DEBUGGING
			PrintToChatAll("TAKING DMG %d", attached);
			#endif

			CreateTimer(0.1, TimerTest, EntIndexToEntRef(attached), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);

			if( g_iCvarTypes & 1 )			SDKHook(attached, SDKHook_Use, OnUseGrab);
			else							SDKHook(attached, SDKHook_Use, OnUseBlock);
		}
		else if( (strcmp(sTemp, "prop_physics") == 0 || strcmp(sTemp, "physics_prop") == 0) )
		{
			float time;
			GetEntPropString(attached, Prop_Data, "m_ModelName", sTemp, sizeof(sTemp));

			bool oxygen;

			if( strcmp(sTemp, MODEL_GASCAN) == 0 )
			{
				time = g_fCvarTimeG;
				if( g_iCvarTypes & 1 )		SDKHook(attached, SDKHook_Use, OnUseGrab);
				else						SDKHook(attached, SDKHook_Use, OnUseBlock);
			}
			else if( strcmp(sTemp, MODEL_OXYGEN) == 0 )
			{
				time = g_fCvarTimeO;
				if( g_iCvarTypes & 2 )		SDKHook(attached, SDKHook_Use, OnUseGrab);
				else						SDKHook(attached, SDKHook_Use, OnUseBlock);

				oxygen = true;
			}
			else if( strcmp(sTemp, MODEL_PROPANE) == 0 )
			{
				time = g_fCvarTimeP;
				if( g_iCvarTypes & 4 )		SDKHook(attached, SDKHook_Use, OnUseGrab);
				else						SDKHook(attached, SDKHook_Use, OnUseBlock);
			}
			else if( g_bLeft4Dead2 && strcmp(sTemp, MODEL_CRATE) == 0 )
			{
				time = g_fCvarTimeF;
				if( g_iCvarTypes & 8 )		SDKHook(attached, SDKHook_Use, OnUseGrab);
				else						SDKHook(attached, SDKHook_Use, OnUseBlock);
			}

			// Set burning duration
			SetEntPropFloat(entity, Prop_Data, "m_flLifetime", GetGameTime() + time);

			if( g_iFlamed )
			{
				g_fFireTime[entity] = g_fFireTime[g_iFlamed];
				g_fFireTime[attached] = g_fFireTime[g_iFlamed];
				g_iFlamed = 0;
			} else {
				g_fFireTime[entity] = GetGameTime() + time;
				g_fFireTime[attached] = GetGameTime() + time;
			}

			if( oxygen )
				SDKHook(attached, SDKHook_OnTakeDamage, OxygenTakeDamage);
			else
				SDKHook(attached, SDKHook_OnTakeDamage, OnPropTakeDamage);

			CreateTimer(0.1, TimerTest, EntIndexToEntRef(attached), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

// ====================
// Cvar setting to block picking up objects on fire
// ====================
Action OnUseBlock(int entity, int client)
{
	// Sometimes the game makes it not on fire, lets verify or unhook.
	int flame = GetEntPropEnt(entity, Prop_Send, "m_hEffectEntity");
	if( flame != -1 && IsValidEntity(flame) )
	{
		static char classname[16];
		GetEdictClassname(entity, classname, sizeof(classname));

		if( strcmp(classname, "entityflame") == 0 )
		{
			return Plugin_Handled;
		}
	}

	// Unhook, not valid
	SDKUnhook(entity, SDKHook_Use, OnUseBlock);
	return Plugin_Continue;
}

void OnUseGrab(int entity, int client)
{
	// Explode?
	float time = g_fFireTime[entity];
	if( time < GetGameTime() )
	{
		DetonateExplosive(client, entity);
		return;
	}

	// Pickup

	// Get modelname
	static char modelname[45];
	GetEntPropString(entity, Prop_Data, "m_ModelName", modelname, sizeof(modelname));

	// ==========
	// L4D1 requires frame delay, because the entity is not yet equipped and we have no entity index
	// ==========
	if( !g_bLeft4Dead2 )
	{
		int index;

		// Change from prop_physics to held classnames, weapon_gascan doesn't change, except in L4D1
		if( strcmp(modelname, MODEL_OXYGEN) == 0 )						index = 1;
		else if( strcmp(modelname, MODEL_PROPANE) == 0 )				index = 2;
		else 															index = 3;

		DataPack dPack = new DataPack();
		dPack.WriteCell(GetClientUserId(client));
		dPack.WriteCell(index);
		dPack.WriteFloat(time);

		RequestFrame(OnGrabFrame, dPack);
		return;
	}

	// ==========
	// L4D2 is different
	// ==========

	// Get classname
	static char classname[32];

	// Change from prop_physics to held classnames, weapon_gascan doesn't change, except in L4D1
	if( g_bLeft4Dead2 && strcmp(modelname, MODEL_CRATE) == 0 )			classname = "weapon_fireworkcrate";
	else if( strcmp(modelname, MODEL_OXYGEN) == 0 )						classname = "weapon_oxygentank";
	else if( strcmp(modelname, MODEL_PROPANE) == 0 )					classname = "weapon_propanetank";
	else 																classname = "weapon_gascan";

	// Copy skin
	int skin = GetEntProp(entity, Prop_Send, "m_nSkin");

	// Delete picked up
	RemoveEntity(entity);

	// Create new, this is so the flame lifetime continues
	int weapon = CreateEntityByName(classname);
	DispatchSpawn(weapon);
	SetEntProp(weapon, Prop_Send, "m_nSkin", skin);

	EquipPlayerWeapon(client, weapon);

	g_bBlockGrab = true;
	AcceptEntityInput(weapon, "Ignite");
	g_bBlockGrab = false;

	int flame = GetEntPropEnt(weapon, Prop_Send, "m_hEffectEntity");
	SetEntPropFloat(flame, Prop_Data, "m_flLifetime", time);

	g_iFlamed = weapon;
	g_fFireTime[weapon] = time;

	g_iScavenge[weapon] = g_iScavenge[entity];
	g_iScavenge[entity] = 0;

	CreateTimer(0.1, TimerTest, EntIndexToEntRef(weapon), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);

	g_iHolding2[client] = EntIndexToEntRef(weapon);
}

// ====================
// L4D1: Picking up object that's on fire
// ====================
void OnGrabFrame(DataPack dPack)
{
	dPack.Reset();
	int client = dPack.ReadCell();
	int index = dPack.ReadCell();
	float time = dPack.ReadFloat();
	delete dPack;

	if( (client = GetClientOfUserId(client)) && IsClientInGame(client) )
	{
		int entity = GetPlayerWeaponSlot(client, 5);
		if( entity == -1 ) return;

		// Copy skin
		int skin = GetEntProp(entity, Prop_Send, "m_nSkin");

		g_bRemovingItem = true;
		RemovePlayerItem(client, entity);
		g_bRemovingItem = false;
		RemoveEntity(entity);

		// Create new, this is so the flame lifetime continues
		char classname[20];
		switch( index )
		{
			case 1: classname = "weapon_oxygentank";
			case 2: classname = "weapon_propanetank";
			case 3: classname = "weapon_gascan";
		}

		int weapon = CreateEntityByName(classname);
		DispatchSpawn(weapon);
		ActivateEntity(weapon);
		EquipPlayerWeapon(client, weapon);

		AcceptEntityInput(weapon, "Ignite");

		int flame = GetEntPropEnt(weapon, Prop_Send, "m_hEffectEntity");
		SetEntPropFloat(flame, Prop_Data, "m_flLifetime", time);
		SetEntProp(weapon, Prop_Send, "m_nSkin", skin);

		g_fFireTime[weapon] = time;

		CreateTimer(0.1, TimerTest, EntIndexToEntRef(weapon), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);

		if( g_bLeft4Dead2 )		g_iHolding2[client] = EntIndexToEntRef(weapon);
		else					g_iHolding1[client] = weapon;

		if( g_bLeft4Dead2 && classname[7] == 'g' )
		{
			g_iScavenge[weapon] = g_iScavenge[entity];
			g_iScavenge[entity] = 0;
		}
	}
}

// ====================
// Block prop damage to allow flames
// ====================
Action OxygenTakeDamage(int entity, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if( attacker > MaxClients )
	{
		static char classname[12];
		GetEdictClassname(attacker, classname, sizeof(classname));
		if( strcmp(classname, "entityflame") == 0 )
		{
			// Allow whistle effect for last 2 seconds by setting health to 1 and removing damage block
			int flame = GetEntPropEnt(entity, Prop_Send, "m_hEffectEntity");
			if( GetEntPropFloat(flame, Prop_Data, "m_flLifetime") - GetGameTime() > 2.0 )
			{
				return Plugin_Handled;
			}
			else
			{
				SetEntProp(entity, Prop_Data, "m_iHealth", 2);
				SDKUnhook(entity, SDKHook_OnTakeDamage, OxygenTakeDamage);
			}
		}
	}
	return Plugin_Continue;
}

Action OnPropTakeDamage(int entity, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if( attacker > MaxClients )
	{
		static char classname[12];
		GetEdictClassname(attacker, classname, sizeof(classname));
		if( strcmp(classname, "entityflame") == 0 )
		{
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

// ====================
// Watch time until detonate
// ====================
Action TimerTest(Handle timer, int entity)
{
	entity = EntRefToEntIndex(entity);
	if( entity != INVALID_ENT_REFERENCE )
	{
		if( g_fFireTime[entity] > GetGameTime() )
		{
			return Plugin_Continue;
		} else {
			int client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
			DetonateExplosive(client, entity);
			return Plugin_Stop;
		}
	}

	return Plugin_Stop;
}

// ====================
// Create explosion
// ====================
void DetonateExplosive(int client, int entity)
{
	g_iFlamed = 0;

	int doExplode;
	bool isHolding;

	// Check if holding entity and delete
	if( client > 0 && client <= MaxClients )
	{
		int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if( weapon == entity ) isHolding = true;

		// Remove held throwable - when detonating from hand
		if( isHolding )
		{
			// Verify classname
			static char classname[32];
			GetEdictClassname(weapon, classname, sizeof(classname));

			if( strcmp(classname[7], "gascan") == 0 )
			{
				doExplode = 2;
			}
			else if(
				strcmp(classname[7], "oxygentank") == 0 ||
				strcmp(classname[7], "propanetank") == 0 ||
				(g_bLeft4Dead2 && strcmp(classname[7], "fireworkcrate") == 0)
			)
			{
				doExplode = 1;
			}

			if( doExplode == 2 )
			{
				g_bRemovingItem = true;
				RemovePlayerItem(client, weapon);
				g_bRemovingItem = false;

				RemoveEntity(weapon);
			}
			else if( g_bLeft4Dead2 )
			{
				RemoveEntity(weapon);
			}
		}
	}

	if( isHolding == false )
	{
		// Verify client
		client = g_iLastClient[entity];
		if( client ) client = GetClientOfUserId(client);
		if( client && !IsClientInGame(client) ) client = 0;

		doExplode = 1;
	}

	RemoveEntity(entity);

	// Create explosion
	if( doExplode )
	{
		static char modelname[42];
		GetEntPropString(entity, Prop_Data, "m_ModelName", modelname, sizeof(modelname));

		int explosive = CreateEntityByName("prop_physics");
		if( explosive != -1 )
		{
			DispatchKeyValue(explosive, "model", modelname);

			// Hide from view (multiple hides still show the gascan for a split second sometimes, but works better than only using 1 of them)
			SDKHook(explosive, SDKHook_SetTransmit, OnTransmitExplosive);

			// Hide from view
			int flags = GetEntityFlags(explosive);
			SetEntityFlags(explosive, flags|FL_EDICT_DONTSEND);

			// Make invisible
			SetEntityRenderMode(explosive, RENDER_TRANSALPHAADD);
			SetEntityRenderColor(explosive, 0, 0, 0, 0);

			// Prevent collision and movement
			SetEntProp(explosive, Prop_Send, "m_CollisionGroup", 1, 1);
			SetEntityMoveType(explosive, MOVETYPE_NONE);

			// Teleport
			static float vPos[3];

			if( isHolding )
				GetClientAbsOrigin(client, vPos);
			else
				GetEntPropVector(entity, Prop_Data, "m_vecOrigin", vPos);

			vPos[2] += 10.0;
			TeleportEntity(explosive, vPos, NULL_VECTOR, NULL_VECTOR);

			// Spawn
			DispatchSpawn(explosive);

			// Set attacker
			SetEntPropEnt(explosive, Prop_Data, "m_hPhysicsAttacker", client);
			SetEntPropFloat(explosive, Prop_Data, "m_flLastPhysicsInfluenceTime", GetGameTime());

			// Explode
			AcceptEntityInput(explosive, "Break");

			// Fix Scavenge Gascans not respawning
			if( modelname[18] == 'g' && GetEntProp(entity, Prop_Send, "m_nSkin") )
			{
				#if DEBUGGING
				PrintToChatAll("IS: SCAV CAN %d", entity);
				#endif

				if( g_iScavenge[entity] && EntRefToEntIndex(g_iScavenge[entity]) != INVALID_ENT_REFERENCE )
				{
					#if DEBUGGING
					PrintToChatAll("IS: SCAV VALID, RESPAWNING %d", entity);
					#endif

					CreateTimer(g_fCvarRespawn, TimerRespawn, g_iScavenge[entity]);
				}
			}
		}
	}
}

Action OnTransmitExplosive(int entity, int client)
{
	return Plugin_Handled;
}

// ====================
// Fix Scavenge Gascans not respawning
// ====================
Action TimerRespawn(Handle timer, int entity)
{
	entity = EntRefToEntIndex(entity);

	#if DEBUGGING
	PrintToChatAll("IS: SCAV TimerRespawn");
	#endif

	if( entity != INVALID_ENT_REFERENCE )
	{
		AcceptEntityInput(entity, "SpawnItem");

		#if DEBUGGING
		PrintToChatAll("IS: SCAV SpawnItem");
		#endif
	}

	return Plugin_Continue;
}

// ====================
// Events
// ====================
void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	g_iRoundStart = 0;
	g_iPlayerSpawn = 0;
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if( g_iPlayerSpawn == 1 && g_iRoundStart == 0 )
		CreateTimer(1.0, TimerStart, _, TIMER_FLAG_NO_MAPCHANGE);
	g_iRoundStart = 1;
}

void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if( g_iPlayerSpawn == 0 && g_iRoundStart == 1 )
		CreateTimer(1.0, TimerStart, _, TIMER_FLAG_NO_MAPCHANGE);
	g_iPlayerSpawn = 1;
}

Action TimerStart(Handle timer)
{
	g_iFlamed = 0;

	for( int i = 0; i < 2048; i++ )
	{
		g_iScavenge[i] = 0;
	}

	// Find Scavenge gascans and their spawner
	if( g_bLeft4Dead2 )
	{
		CreateTimer(5.0, TimerDelayedFind, _, TIMER_FLAG_NO_MAPCHANGE);
	}

	return Plugin_Continue;
}

// Dropped: L4D2 prop_physics is thrown, ignite if required
void Event_DropToProp(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	int entity = event.GetInt("propid");
	OnDropWeapon(client, entity);
}

// ====================
// Match Scavenge spawners with Gascans
// ====================
Action TimerDelayedFind(Handle timer)
{
	FindScavengeGas();
	return Plugin_Continue;
}

void FindScavengeGas(int target = 0)
{
	#if DEBUGGING
	int counter;
	PrintToChatAll("IS: FindScavengeGas %d", target);
	#endif

	float vPos[3], vVec[3];

	int entity = -1;
	int gascan = -1;
	float dist = 99999.9;
	float range;
	int matched;

	// Find matching spawner for given entity
	if( target )
	{
		GetEntPropVector(target, Prop_Send, "m_vecOrigin", vVec);
	}

	while( (entity = FindEntityByClassname(entity, "weapon_scavenge_item_spawn")) != INVALID_ENT_REFERENCE )
	{
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vPos);

		// Find spawner for specific gascan
		if( target )
		{
			range = GetVectorDistance(vPos, vVec);

			if( range < dist )
			{
				dist = range;
				matched = entity;
			}
		}
		// Search through all and match
		else
		{
			gascan = -1;
			dist = 99999.9;

			while( (gascan = FindEntityByClassname(gascan, "weapon_gascan")) != INVALID_ENT_REFERENCE )
			{
				GetEntPropVector(gascan, Prop_Send, "m_vecOrigin", vVec);
				range = GetVectorDistance(vPos, vVec);

				if( range < dist )
				{
					dist = range;
					matched = gascan;
				}
			}

			// All
			if( matched && dist <= RANGE_MAX )
			{
				#if DEBUGGING
				counter++;
				PrintToChatAll("IS: MATCHED %d == %d", matched, entity);
				#endif

				g_iScavenge[matched] = EntIndexToEntRef(entity);
				matched = 0;
			}
		}
	}

	#if DEBUGGING
	PrintToChatAll("IS: MATCHED TOTAL %d", counter);
	#endif

	// Specific
	if( target && matched && dist <= RANGE_MAX )
	{
		#if DEBUGGING
		PrintToChatAll("IS: MATCHED TARGET %d == %d", target, matched);
		#endif

		g_iScavenge[target] = EntIndexToEntRef(matched);
	}
}

// ====================
// Dropped: weapon_gascan is thrown, ignite if required
// ====================
void OnSwitch(int client, int weapon)
{
	if( weapon == -1 ) return;

	static char classname[16];
	GetEdictClassname(weapon, classname, sizeof(classname));

	if( !g_bLeft4Dead2 && g_iHolding1[client] && EntRefToEntIndex(g_iHolding1[client]) != INVALID_ENT_REFERENCE && g_iDroppingItem && EntRefToEntIndex(g_iDroppingItem) != INVALID_ENT_REFERENCE )
	{
		OnDropWeapon(client, EntRefToEntIndex(g_iDroppingItem));
	}
	else if( g_bLeft4Dead2 && g_iHolding2[client] && EntRefToEntIndex(g_iHolding2[client]) != INVALID_ENT_REFERENCE )
	{
		OnDropWeapon(client, EntRefToEntIndex(g_iHolding2[client]));
	}
}

void OnDropWeapon(int client, int entity)
{
	if( client > 0 && entity > 0 )
	{
		// Ignited throwable dropped
		int target;
		if( g_bLeft4Dead2 )
		{
			target = g_iHolding2[client];
			g_iHolding2[client] = 0;
		}
		else
		{
			target = g_iHolding1[client];
			g_iHolding1[client] = 0;
		}

		if( target && (!g_bLeft4Dead2 || (target = EntRefToEntIndex(target)) != INVALID_ENT_REFERENCE) )
		{
			g_iFlamed = entity;
			g_fFireTime[entity] = g_fFireTime[target];
			g_iLastClient[entity] = GetClientUserId(client);

			AcceptEntityInput(entity, "Ignite");
			CreateTimer(0.1, TimerTest, EntIndexToEntRef(entity), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		} else {
			// Damage Oxygen Tank dropped/thrown:
			target = g_iOxygen[client];
			g_iOxygen[client] = 0;

			if( target && (target = EntRefToEntIndex(target)) != INVALID_ENT_REFERENCE )
			{
				// The prop_physics entity is created before OnDropWeapon is called, so we can use g_iSpawned for the new entity index
				g_fFireTime[g_iSpawned] = g_fFireTime[target];
				CreateTimer(0.1, TimerTest, EntIndexToEntRef(g_iSpawned), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
}