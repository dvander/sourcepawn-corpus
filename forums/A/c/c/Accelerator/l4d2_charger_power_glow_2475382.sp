#define PLUGIN_VERSION 		"1.1"

/*=======================================================================================
	Plugin Info:

*	Name	:	[L4D2] Charger Power - Objects Glow
*	Author	:	SilverShot
*	Descrp	:	Creates a glow for the objects which chargers can move.
*	Link	:	http://forums.alliedmods.net/showthread.php?t=186556

========================================================================================
	Change Log:

1.1 (02-Jun-2012)
	- Support for the "Charger Power" plugins cvar "l4d2_charger_power_push_limit".

1.0 (01-Jun-2012)
	- Initial release.

======================================================================================*/

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define CVAR_FLAGS			FCVAR_NOTIFY
#define MAX_ALLOWED			64

#define PROP_CAR (1<<0)
#define PROP_CAR_ALARM (1<<1)
#define PROP_CONTAINER (1<<2)
#define PROP_TRUCK (1<<3)


static	Handle:g_hCvarObjects, Handle:g_hCvarLimit, Handle:g_hCvarAllow, Handle:g_hCvarColor, Handle:g_hCvarRange, Handle:g_hMPGameMode, Handle:g_hTimerStart,
		g_iCvarColor, g_iCvarLimit, g_iCvarRange, bool:g_bLoaded, g_iCount, g_iEntities[MAX_ALLOWED], g_iTarget[MAX_ALLOWED], bool:g_bShowProp[MAXPLAYERS+1];



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin:myinfo =
{
	name = "[L4D2] Charger Power - Objects Glow",
	author = "SilverShot",
	description = "Creates a glow for the objects which chargers can move.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=186556"
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	decl String:sGameName[12];
	GetGameFolderName(sGameName, sizeof(sGameName));
	if( strcmp(sGameName, "left4dead2", false) )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public OnPluginStart()
{
	g_hCvarAllow =	CreateConVar(	"l4d2_charger_power_glow_allow",		"1",				"0=Plugin off, 1=Plugin on.", CVAR_FLAGS);
	g_hCvarColor =	CreateConVar(	"l4d2_charger_power_glow_color",		"255 0 0",			"Three values between 0-255 separated by spaces. RGB Color255 - Red Green Blue.", CVAR_FLAGS);
	g_hCvarRange =	CreateConVar(	"l4d2_charger_power_glow_range",		"500",				"How near to props do players need to be to enable their glow.", CVAR_FLAGS);
	CreateConVar(					"l4d2_charger_power_glow_version",		PLUGIN_VERSION,		"Charger Power - Objects Glow plugin version.", FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	AutoExecConfig(true,			"l4d2_charger_power_glow");

	g_hMPGameMode = FindConVar("mp_gamemode");
	HookConVarChange(g_hMPGameMode,		ConVarChanged_Allow);
	HookConVarChange(g_hCvarAllow,		ConVarChanged_Allow);
	HookConVarChange(g_hCvarRange,		ConVarChanged_Cvars);
	HookConVarChange(g_hCvarColor,		ConVarChanged_Glow);
}

public OnPluginEnd()
{
	ResetPlugin(false);
}

public OnAllPluginsLoaded()
{
	g_hCvarObjects = FindConVar("l4d2_charger_power_objects"); // "15", "Can move objects this type (1 - car, 2 - car alarm, 4 - container, 8 - truck)", FCVAR_NOTIFY, true, 1.0, true, 15.0)
	if( g_hCvarObjects == INVALID_HANDLE )
		SetFailState("Failed to find handle 'l4d2_charger_power_objects'. Missing required plugin 'Charger Power'.");

	if( g_hCvarLimit == INVALID_HANDLE )
	{
		g_hCvarLimit = FindConVar("l4d2_charger_power_push_limit");
		if( g_hCvarLimit != INVALID_HANDLE )
			HookConVarChange(g_hCvarLimit, ConVarChanged_Cvars);
	}
}

public OnClientDisconnect(client)
{
	g_bShowProp[client] = false;
}

LateLoad()
{
	g_hTimerStart = CreateTimer(1.0, tmrStart, _, TIMER_FLAG_NO_MAPCHANGE);

	for( new i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == 3 && IsPlayerAlive(i) && GetEntProp(i, Prop_Send, "m_zombieClass") == 6 )
		{
			g_bShowProp[i] = true;
		}
	}
}

ResetPlugin(bool:all)
{
	g_bLoaded = false;

	for( new i = 0; i < MAX_ALLOWED; i++ )
	{
		if( IsValidEntRef(g_iEntities[i]) )
		{
			AcceptEntityInput(g_iEntities[i], "Kill");
		}
		g_iEntities[i] = 0;
	}

	if( all == true )
	{
		g_iCount = 0;

		for( new i = 0; i <= MAXPLAYERS; i++ )
		{
			g_bShowProp[i] = false;
		}

		if( g_hTimerStart != INVALID_HANDLE )
		{
			CloseHandle(g_hTimerStart);
			g_hTimerStart = INVALID_HANDLE;
		}
	}
}



// ====================================================================================================
//					CVARS
// ====================================================================================================
public OnConfigsExecuted()
	IsAllowed();

public ConVarChanged_Allow(Handle:convar, const String:oldValue[], const String:newValue[])
	IsAllowed();

public ConVarChanged_Cvars(Handle:convar, const String:oldValue[], const String:newValue[])
	GetCvars();

GetCvars()
{
	g_iCvarColor = GetColor(g_hCvarColor);
	if( g_hCvarLimit != INVALID_HANDLE )
		g_iCvarLimit = GetConVarInt(g_hCvarLimit);
	g_iCvarRange = GetConVarInt(g_hCvarRange);
}

public ConVarChanged_Glow(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_iCvarColor = GetColor(g_hCvarColor);

	new entity;

	for( new i = 0; i < MAX_ALLOWED; i++ )
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

GetColor(Handle:hCvar)
{
	decl String:sTemp[12];
	GetConVarString(hCvar, sTemp, sizeof(sTemp));

	if( strcmp(sTemp, "") == 0 )
		return 0;

	decl String:sColors[3][4];
	new color = ExplodeString(sTemp, " ", sColors, 3, 4);

	if( color != 3 )
		return 0;

	color = StringToInt(sColors[0]);
	color += 256 * StringToInt(sColors[1]);
	color += 65536 * StringToInt(sColors[2]);

	return color;
}

IsAllowed()
{
	new bool:bCvarAllow = GetConVarBool(g_hCvarAllow);
	new bool:bAllowMode = IsAllowedGameMode();
	GetCvars();

	static bool:g_bCvarAllow;

	if( g_bCvarAllow == false && bCvarAllow == true && bAllowMode == true )
	{
		g_bCvarAllow = true;
		LateLoad();

		HookEvent("player_team",		Event_PlayerDeath);
		HookEvent("player_death",		Event_PlayerDeath);
		HookEvent("tank_frustrated",	Event_PlayerDeath);
		HookEvent("tank_spawn",			Event_PlayerDeath);
		HookEvent("player_spawn",		Event_PlayerSpawn);
		HookEvent("round_end",			Event_RoundEnd,		EventHookMode_PostNoCopy);
		HookEvent("round_start",		Event_RoundStart,	EventHookMode_PostNoCopy);
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
		UnhookEvent("round_end",		Event_RoundEnd,		EventHookMode_PostNoCopy);
		UnhookEvent("round_start",		Event_RoundStart,	EventHookMode_PostNoCopy);
	}
}

static g_iCurrentMode;

bool:IsAllowedGameMode()
{
	if( g_hMPGameMode == INVALID_HANDLE )
		return false;

	g_iCurrentMode = 0;

	new entity = CreateEntityByName("info_gamemode");
	DispatchSpawn(entity);
	HookSingleEntityOutput(entity, "OnVersus", OnGamemode, true);
	HookSingleEntityOutput(entity, "OnScavenge", OnGamemode, true);
	AcceptEntityInput(entity, "PostSpawnActivate");
	AcceptEntityInput(entity, "Kill");

	if( g_iCurrentMode == 0 )
		return false;

	return true;
}

public OnGamemode(const String:output[], caller, activator, Float:delay)
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
public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if( client > 0 )
	{
		CheckClient(client);
	}
}

CheckClient(client)
{
	if( g_bShowProp[client] == true )
	{
		g_bShowProp[client] = false;

		RequestFrame(ResetHook, client);
	}
}

public ResetHook(client)
{
	new entity, done;
	for( new i = 0; i < MAX_ALLOWED; i++ )
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

public Action:TimerHook(Handle:timer)
{
	new entity;
	for( new i = 0; i < MAX_ALLOWED; i++ )
	{
		entity = g_iEntities[i];
		if( entity && (entity = EntRefToEntIndex(entity)) != INVALID_ENT_REFERENCE )
		{
			SetEntProp(entity, Prop_Send, "m_nGlowRange", g_iCvarRange);
			SDKHook(entity, SDKHook_SetTransmit, OnTransmit);
		}
	}
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
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

public OnMapEnd()
{
	ResetPlugin(true);
}

public Event_RoundEnd(Handle:h_Event, const String:s_Name[], bool:b_DontBroadcast)
{
	ResetPlugin(true);
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if( g_hTimerStart == INVALID_HANDLE )
		g_hTimerStart = CreateTimer(4.0, tmrStart, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:tmrStart(Handle:timer)
{
	g_hTimerStart = INVALID_HANDLE;

	if( g_bLoaded == true )
		return;

	g_bLoaded = true;
	g_iCount = 0;

	decl String:sClassName[64], String:sModelName[64];
	new ents = GetEntityCount();
	new iType = GetConVarInt(g_hCvarObjects);

	new iEntities[MAX_ALLOWED];

	for( new entity = MaxClients+1; entity < ents; entity++ )
	{
		if( g_iCount >= MAX_ALLOWED )
			break;

		if( IsValidEdict(entity) )
		{
			if( GetEntityMoveType(entity) == MOVETYPE_VPHYSICS )
			{
				GetEdictClassname(entity, sClassName, sizeof(sClassName));

				if( (iType & PROP_CAR_ALARM) && strcmp(sClassName, "prop_car_alarm") == 0 )
				{
					iEntities[g_iCount++] = entity;
				}
				else if( strcmp(sClassName, "prop_physics") == 0 )
				{
					GetEntPropString(entity, Prop_Data, "m_ModelName", sModelName, sizeof(sModelName));

					if( (iType & PROP_CAR) &&
					(
						strcmp(sModelName, "models/props_vehicles/cara_69sedan.mdl") == 0 ||
						strcmp(sModelName, "models/props_vehicles/cara_82hatchback.mdl") == 0 ||
						strcmp(sModelName, "models/props_vehicles/cara_82hatchback_wrecked.mdl") == 0 ||
						strcmp(sModelName, "models/props_vehicles/cara_84sedan.mdl") == 0 ||
						strcmp(sModelName, "models/props_vehicles/cara_95sedan.mdl") == 0 ||
						strcmp(sModelName, "models/props_vehicles/cara_95sedan_wrecked.mdl") == 0 ||
						strcmp(sModelName, "models/props_vehicles/police_car_city.mdl") == 0 ||
						strcmp(sModelName, "models/props_vehicles/police_car_rural.mdl") == 0 ||
						strcmp(sModelName, "models/props_vehicles/taxi_cab.mdl") == 0 )
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
	}

	new target;
	decl Float:vPos[3], Float:vAng[3];
	for( new i = 0; i < g_iCount; i++ )
	{
		target = iEntities[i];

		GetEntPropString(target, Prop_Data, "m_ModelName", sModelName, sizeof(sModelName));

		new entity = CreateEntityByName("prop_dynamic");
		g_iEntities[i] = EntIndexToEntRef(entity);

		DispatchKeyValue(entity, "model", sModelName);
		GetEntPropVector(target, Prop_Send, "m_vecOrigin", vPos);
		GetEntPropVector(target, Prop_Send, "m_angRotation", vAng);
		DispatchKeyValueVector(entity, "origin", vPos);
		DispatchKeyValueVector(entity, "angles", vAng);
		DispatchSpawn(entity);

		SetVariantString("!activator");
		AcceptEntityInput(entity, "SetParent", target);
		
		SetEntProp(entity, Prop_Send, "m_CollisionGroup", 0);
		SetEntProp(entity, Prop_Send, "m_nSolidType", 0);
		SetEntProp(entity, Prop_Send, "m_nGlowRange", g_iCvarRange);
		SetEntProp(entity, Prop_Send, "m_iGlowType", 3);
		SetEntProp(entity, Prop_Send, "m_glowColorOverride", g_iCvarColor);

		SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
		SetEntityRenderColor(entity, 0, 0, 0, 0);

		if( g_iCvarLimit != 0 )
			HookSingleEntityOutput(target, "OnHealthChanged", OnHealthChanged);
		g_iTarget[i] = EntIndexToEntRef(target);

		SDKHook(entity, SDKHook_SetTransmit, OnTransmit);
	}
}

public OnHealthChanged(const String:output[], caller, activator, Float:delay)
{
	if( GetEntProp(caller, Prop_Data, "m_iHealth") >= g_iCvarLimit )
	{
		UnhookSingleEntityOutput(caller, "OnHealthChanged", OnHealthChanged);

		caller = EntIndexToEntRef(caller);
		for( new i = 0; i < MAX_ALLOWED; i++ )
		{
			if( caller == g_iTarget[i] )
			{
				if( IsValidEntRef(g_iEntities[i]) )
				{
					AcceptEntityInput(g_iEntities[i], "Kill");
				}

				g_iTarget[i] = 0;
				g_iEntities[i] = 0;
				break;
			}
		}
	}
}

public Action:OnTransmit(entity, client)
{
	if( g_bShowProp[client] )
		return Plugin_Continue;
	return Plugin_Handled;
}

bool:IsValidEntRef(entity)
{
	if( entity && EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE )
		return true;
	return false;
}