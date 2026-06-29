/*
*	Charger Power - Objects Glow
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



#define PLUGIN_VERSION 		"1.7"

/*=======================================================================================
	Plugin Info:

*	Name	:	[L4D2] Charger Power - Objects Glow
*	Author	:	SilverShot
*	Descrp	:	Creates a glow for the objects which chargers can move.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=186556
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.7 (27-Jul-2023)
	- Changes to fix warnings when compiling on SourceMod 1.11.

1.6 (15-Aug-2021)
	- Fixed "Cannot create new entity when no map is running" error. Thanks to "noto3" for reporting.

1.5 (13-Aug-2021)
	- Fixed not displaying a glow for all vehicle types. Thanks to "DonProof" for reporting.

1.4 (10-May-2020)
	- Extra checks to prevent "IsAllowedGameMode" throwing errors.
	- Various changes to tidy up code.
	- Various optimizations and fixes.

1.3 (05-May-2018)
	- Converted plugin source to the latest syntax utilizing methodmaps. Requires SourceMod 1.8 or newer.

1.2 (04-Mar-2017)
	- Added "attacker" on moved objects.

1.1 (02-Jun-2012)
	- Support for the "Charger Power" plugins cvar "l4d2_charger_power_push_limit".

1.0 (01-Jun-2012)
	- Initial release.

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define CVAR_FLAGS			FCVAR_NOTIFY
#define MAX_ALLOWED			64

#define PROP_CAR (1<<0)
#define PROP_CAR_ALARM (1<<1)
#define PROP_CONTAINER (1<<2)
#define PROP_TRUCK (1<<3)


Handle g_hTimerStart;
ConVar g_hCvarAllow, g_hCvarColor, g_hCvarLimit, g_hCvarMPGameMode, g_hCvarObjects, g_hCvarRange;
int g_iCount, g_iCvarColor, g_iCvarLimit, g_iCvarRange, g_iEntities[MAX_ALLOWED], g_iTarget[MAX_ALLOWED];
bool g_bLoaded, g_bMapStarted, g_bShowProp[MAXPLAYERS+1];



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D2] Charger Power - Objects Glow",
	author = "SilverShot",
	description = "Creates a glow for the objects which chargers can move.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=186556"
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
	g_hCvarAllow =	CreateConVar(	"l4d2_charger_power_glow_allow",		"1",				"0=Plugin off, 1=Plugin on.", CVAR_FLAGS);
	g_hCvarColor =	CreateConVar(	"l4d2_charger_power_glow_color",		"255 0 0",			"Three values between 0-255 separated by spaces. RGB Color255 - Red Green Blue.", CVAR_FLAGS);
	g_hCvarRange =	CreateConVar(	"l4d2_charger_power_glow_range",		"500",				"How near to props do players need to be to enable their glow.", CVAR_FLAGS);
	CreateConVar(					"l4d2_charger_power_glow_version",		PLUGIN_VERSION,		"Charger Power - Objects Glow plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	AutoExecConfig(true,			"l4d2_charger_power_glow");

	g_hCvarMPGameMode = FindConVar("mp_gamemode");
	g_hCvarMPGameMode.AddChangeHook(ConVarChanged_Allow);
	g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);
	g_hCvarRange.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarColor.AddChangeHook(ConVarChanged_Glow);
}

public void OnPluginEnd()
{
	ResetPlugin(false);
}

public void OnAllPluginsLoaded()
{
	g_hCvarObjects = FindConVar("l4d2_charger_power_objects"); // "15", "Can move objects this type (1 - car, 2 - car alarm, 4 - container, 8 - truck)", FCVAR_NOTIFY, true, 1.0, true, 15.0)
	if( g_hCvarObjects == null )
		SetFailState("Failed to find handle 'l4d2_charger_power_objects'. Missing required plugin 'Charger Power'.");

	if( g_hCvarLimit == null )
	{
		g_hCvarLimit = FindConVar("l4d2_charger_power_push_limit");
		if( g_hCvarLimit != null )
			g_hCvarLimit.AddChangeHook(ConVarChanged_Cvars);
	}
}

public void OnClientDisconnect(int client)
{
	g_bShowProp[client] = false;
}

void LateLoad()
{
	g_hTimerStart = CreateTimer(1.0, TimerStart, _, TIMER_FLAG_NO_MAPCHANGE);

	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == 3 && IsPlayerAlive(i) && GetEntProp(i, Prop_Send, "m_zombieClass") == 6 )
		{
			g_bShowProp[i] = true;
		}
	}
}

void ResetPlugin(bool all)
{
	g_bLoaded = false;

	for( int i = 0; i < MAX_ALLOWED; i++ )
	{
		if( IsValidEntRef(g_iEntities[i]) )
		{
			RemoveEntity(g_iEntities[i]);
		}
		g_iEntities[i] = 0;
	}

	if( all == true )
	{
		g_iCount = 0;

		for( int i = 0; i <= MAXPLAYERS; i++ )
		{
			g_bShowProp[i] = false;
		}

		delete g_hTimerStart;
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
	g_iCvarColor = GetColor(g_hCvarColor);
	if( g_hCvarLimit != null )
		g_iCvarLimit = g_hCvarLimit.IntValue;
	g_iCvarRange = g_hCvarRange.IntValue;
}

void ConVarChanged_Glow(Handle convar, const char[] oldValue, const char[] newValue)
{
	g_iCvarColor = GetColor(g_hCvarColor);

	int entity;

	for( int i = 0; i < MAX_ALLOWED; i++ )
	{
		entity = g_iEntities[i];
		if( IsValidEntRef(entity) )
		{
			SetEntProp(entity, Prop_Send, "m_iGlowType", 3);
			SetEntProp(entity, Prop_Send, "m_glowColorOverride", g_iCvarColor);
			SetEntProp(entity, Prop_Send, "m_nGlowRange", g_iCvarRange);
		}
	}
}

int GetColor(ConVar hCvar)
{
	char sTemp[12];
	hCvar.GetString(sTemp, sizeof(sTemp));

	if( sTemp[0] == 0 )
		return 0;

	char sColors[3][4];
	int color = ExplodeString(sTemp, " ", sColors, sizeof(sColors), sizeof(sColors[]));

	if( color != 3 )
		return 0;

	color = StringToInt(sColors[0]);
	color += 256 * StringToInt(sColors[1]);
	color += 65536 * StringToInt(sColors[2]);

	return color;
}

void IsAllowed()
{
	bool bCvarAllow = g_hCvarAllow.BoolValue;
	bool bAllowMode = IsAllowedGameMode();
	GetCvars();

	static bool g_bCvarAllow;

	if( g_bCvarAllow == false && bCvarAllow == true && bAllowMode == true )
	{
		g_bCvarAllow = true;
		LateLoad();

		HookEvent("player_team",		Event_PlayerDeath);
		HookEvent("player_death",		Event_PlayerDeath);
		HookEvent("tank_frustrated",	Event_PlayerDeath);
		HookEvent("tank_spawn",			Event_PlayerDeath);
		HookEvent("player_spawn",		Event_PlayerSpawn);
		HookEvent("round_start",		Event_RoundStart,	EventHookMode_PostNoCopy);
		HookEvent("round_end",			Event_RoundEnd,		EventHookMode_PostNoCopy);
	}

	else if( g_bCvarAllow == true && (bCvarAllow == false || bAllowMode == false) )
	{
		g_bCvarAllow = false;
		ResetPlugin(true);

		UnhookEvent("player_team",		Event_PlayerDeath);
		UnhookEvent("player_death",		Event_PlayerDeath);
		UnhookEvent("tank_frustrated",	Event_PlayerDeath);
		UnhookEvent("tank_spawn",		Event_PlayerDeath);
		UnhookEvent("player_spawn",		Event_PlayerSpawn);
		UnhookEvent("round_start",		Event_RoundStart,	EventHookMode_PostNoCopy);
		UnhookEvent("round_end",		Event_RoundEnd,		EventHookMode_PostNoCopy);
	}
}

int g_iCurrentMode;
bool IsAllowedGameMode()
{
	if( g_hCvarMPGameMode == null )
		return false;

	if( g_bMapStarted == false )
		return false;

	g_iCurrentMode = 0;

	int entity = CreateEntityByName("info_gamemode");
	if( IsValidEntity(entity) )
	{
		DispatchSpawn(entity);
		HookSingleEntityOutput(entity, "OnVersus", OnGamemode, true);
		HookSingleEntityOutput(entity, "OnScavenge", OnGamemode, true);
		ActivateEntity(entity);
		AcceptEntityInput(entity, "PostSpawnActivate");
		if( IsValidEntity(entity) ) // Because sometimes "PostSpawnActivate" seems to kill the ent.
			RemoveEdict(entity); // Because multiple plugins creating at once, avoid too many duplicate ents in the same frame
	}

	if( g_iCurrentMode == 0 )
		return false;

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
void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if( client > 0 )
	{
		CheckClient(client);
	}
}

void CheckClient(int client)
{
	if( g_bShowProp[client] == true )
	{
		g_bShowProp[client] = false;

		int entity, done;
		for( int i = 0; i < MAX_ALLOWED; i++ )
		{
			entity = g_iEntities[i];
			if( entity && (entity = EntRefToEntIndex(entity)) != INVALID_ENT_REFERENCE )
			{
				SetEntProp(entity, Prop_Send, "m_nGlowRange", 1);
				SDKUnhook(entity, SDKHook_SetTransmit, OnTransmit);
				done++;
			}
		}

		if( done )
		{
			CreateTimer(0.1, TimerHook);
		}
	}
}

Action TimerHook(Handle timer)
{
	int entity;
	for( int i = 0; i < MAX_ALLOWED; i++ )
	{
		entity = g_iEntities[i];
		if( entity && (entity = EntRefToEntIndex(entity)) != INVALID_ENT_REFERENCE )
		{
			SetEntProp(entity, Prop_Send, "m_nGlowRange", g_iCvarRange);
			SDKHook(entity, SDKHook_SetTransmit, OnTransmit);
		}
	}

	return Plugin_Continue;
}

void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if( client > 0 )
	{
		if( !IsFakeClient(client) && GetClientTeam(client) == 3 && GetEntProp(client, Prop_Send, "m_zombieClass") == 6 )
		{
			g_bShowProp[client] = true;
		}
		else
		{
			CheckClient(client);
		}
	}
}

public void OnMapStart()
{
	g_bMapStarted = true;
}

public void OnMapEnd()
{
	g_bMapStarted = false;

	ResetPlugin(true);
}

void Event_RoundEnd(Handle event, const char[] name, bool dontBroadcast)
{
	ResetPlugin(true);
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if( g_hTimerStart == null )
		g_hTimerStart = CreateTimer(4.0, TimerStart, _, TIMER_FLAG_NO_MAPCHANGE);
}

Action TimerStart(Handle timer)
{
	g_hTimerStart = null;

	if( g_bLoaded == true )
		return Plugin_Continue;

	g_bLoaded = true;
	g_iCount = 0;

	char sClassName[64], sModelName[64];
	int iType = g_hCvarObjects.IntValue;
	int ents = GetEntityCount();

	int iEntities[MAX_ALLOWED];

	for( int entity = MaxClients+1; entity < ents; entity++ )
	{
		if( g_iCount >= MAX_ALLOWED )
			break;

		if( IsValidEdict(entity) && GetEntityMoveType(entity) == MOVETYPE_VPHYSICS )
		{
			GetEdictClassname(entity, sClassName, sizeof(sClassName));

			if( (iType & PROP_CAR_ALARM) && strcmp(sClassName, "prop_car_alarm") == 0 )
			{
				iEntities[g_iCount++] = entity;
			}
			else if( strcmp(sClassName, "prop_physics") == 0 )
			{
				GetEntPropString(entity, Prop_Data, "m_ModelName", sModelName, sizeof(sModelName));

				if( (iType & PROP_CAR && strncmp(sModelName, "models/props_vehicles/", 22) == 0) &&
				(
					strcmp(sModelName[22], "cara_69sedan.mdl") == 0 ||
					strcmp(sModelName[22], "cara_82hatchback.mdl") == 0 ||
					strcmp(sModelName[22], "cara_82hatchback_wrecked.mdl") == 0 ||
					strcmp(sModelName[22], "cara_84sedan.mdl") == 0 ||
					strcmp(sModelName[22], "cara_95sedan.mdl") == 0 ||
					strcmp(sModelName[22], "cara_95sedan_wrecked.mdl") == 0 ||
					strcmp(sModelName[22], "police_car_city.mdl") == 0 ||
					strcmp(sModelName[22], "police_car_rural.mdl") == 0 ||
					strcmp(sModelName[22], "taxi_cab.mdl") == 0
				)
				)
				{
					iEntities[g_iCount++] = entity;
				}
				else if( (iType & PROP_CONTAINER) &&
				(
					strcmp(sModelName, "models/props_junk/dumpster_2.mdl") == 0 ||
					strcmp(sModelName, "models/props_junk/dumpster.mdl") == 0 )
				)
				{
					iEntities[g_iCount++] = entity;
				}
				else if( (iType & PROP_TRUCK) && strcmp(sModelName, "models/props/cs_assault/forklift.mdl") == 0 )
				{
					iEntities[g_iCount++] = entity;
				}
				else if
				(
					strcmp(sModelName, "models/props_fairgrounds/bumpercar.mdl") == 0 ||
					strcmp(sModelName, "models/props_foliage/Swamp_FallenTree01_bare.mdl") == 0 ||
					strcmp(sModelName, "models/props_foliage/tree_trunk_fallen.mdl") == 0 ||
					strcmp(sModelName, "models/props_vehicles/airport_baggage_cart2.mdl") == 0 ||
					strcmp(sModelName, "models/props_unique/airport/atlas_break_ball.mdl") == 0 ||
					strcmp(sModelName, "models/props_unique/haybails_single.mdl") == 0
				)
				{
					iEntities[g_iCount++] = entity;
				}
			}
		}
	}

	int target;
	for( int i = 0; i < g_iCount; i++ )
	{
		target = iEntities[i];

		GetEntPropString(target, Prop_Data, "m_ModelName", sModelName, sizeof(sModelName));

		int entity = CreateEntityByName("prop_physics_override");
		g_iEntities[i] = EntIndexToEntRef(entity);

		SetEntityModel(entity, sModelName);
		DispatchSpawn(entity);

		SetEntProp(entity, Prop_Send, "m_CollisionGroup", 0);
		SetEntProp(entity, Prop_Send, "m_nSolidType", 0);
		SetEntProp(entity, Prop_Send, "m_nGlowRange", g_iCvarRange);
		SetEntProp(entity, Prop_Send, "m_iGlowType", 2);
		SetEntProp(entity, Prop_Send, "m_glowColorOverride", g_iCvarColor);
		AcceptEntityInput(entity, "StartGlowing");

		SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
		SetEntityRenderColor(entity, 0, 0, 0, 0);

		float vPos[3], vAng[3];
		GetEntPropVector(target, Prop_Send, "m_vecOrigin", vPos);
		GetEntPropVector(target, Prop_Send, "m_angRotation", vAng);
		DispatchKeyValueVector(entity, "origin", vPos);
		DispatchKeyValueVector(entity, "angles", vAng);

		SetVariantString("!activator");
		AcceptEntityInput(entity, "SetParent", target);

		HookSingleEntityOutput(target, "OnAwakened", OnAwakened);

		if( g_iCvarLimit != 0 )
			HookSingleEntityOutput(target, "OnHealthChanged", OnHealthChanged);
		g_iTarget[i] = EntIndexToEntRef(target);

		SDKHook(entity, SDKHook_SetTransmit, OnTransmit);
	}

	return Plugin_Continue;
}

void OnAwakened(const char[] output, int caller, int activator, float delay)
{
	SetEntPropEnt(caller, Prop_Data, "m_hPhysicsAttacker", activator);
	SetEntPropFloat(caller, Prop_Data, "m_flLastPhysicsInfluenceTime", GetGameTime());
}

void OnHealthChanged(const char[] output, int caller, int activator, float delay)
{
	if( GetEntProp(caller, Prop_Data, "m_iHealth") >= g_iCvarLimit )
	{
		UnhookSingleEntityOutput(caller, "OnHealthChanged", OnHealthChanged);

		caller = EntIndexToEntRef(caller);
		for( int i = 0; i < MAX_ALLOWED; i++ )
		{
			if( caller == g_iTarget[i] )
			{
				if( IsValidEntRef(g_iEntities[i]) )
				{
					RemoveEntity(g_iEntities[i]);
				}

				g_iTarget[i] = 0;
				g_iEntities[i] = 0;
				break;
			}
		}
	}
}

Action OnTransmit(int entity, int client)
{
	if( g_bShowProp[client] )
		return Plugin_Continue;
	return Plugin_Handled;
}

bool IsValidEntRef(int entity)
{
	if( entity && EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE )
		return true;
	return false;
}