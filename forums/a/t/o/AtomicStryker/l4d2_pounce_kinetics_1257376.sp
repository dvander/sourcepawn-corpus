#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <left4downtown>

#define PLUGIN_VERSION 						  "1.0.0"

#define TEST_DEBUG 		0
#define TEST_DEBUG_LOG 	0


static const String:ENTPROP_ZOMBIE_CLASS[] 	= "m_zombieClass";
static const ZOMBIE_CLASS_HUNTER			= 3;
static const L4D2_TEAM_SURVIVORS			= 2;
static const L4D2_TEAM_INFECTED				= 3;

static Handle:cvarisEnabled					= INVALID_HANDLE;
static Handle:triggeringDistance			= INVALID_HANDLE;


static bool:isEnabled						= true;
static Float:criticalRange					= 450.0;
static bool:isPouncing[MAXPLAYERS+1];
static Float:positionArray[MAXPLAYERS+1][3];


public Plugin:myinfo = 
{
	name = "L4D2 Pounce Kinetics",
	author = " AtomicStryker",
	description = " Applies laws of physics to Hunter Pouncing ",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1257376"
}

public OnPluginStart()
{
	if (FindConVar("l4d2_melee_immortals_version") != INVALID_HANDLE)
	{
		ServerCommand("sm plugins unload l4d2_melee_immortals.smx");
		ServerCommand("sm plugins load l4d2_melee_immortals.smx");
	}

	HookEvent("ability_use", event_AbilityUsed);
	HookEvent("pounce_end", event_PounceEnded);
	
	CreateConVar("l4d2_pounce_kinetics_version", 						PLUGIN_VERSION, " L4D2 Pounce Kinetics Plugin Version ", 			FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	triggeringDistance = 	CreateConVar("l4d2_pounce_kinetics_range",	"450.0", 		" What Pounce Range is considered unstoppable ",	FCVAR_PLUGIN);
	cvarisEnabled = 		CreateConVar("l4d2_pounce_kinetics_enabled", "1", 			" Turn Pounce Kinetics on and off ", 				FCVAR_PLUGIN);
	
	HookConVarChange(cvarisEnabled, 		_cvarChange);
	HookConVarChange(triggeringDistance, 	_cvarChange);
	
	isEnabled = 	GetConVarBool(cvarisEnabled);
	criticalRange = GetConVarFloat(triggeringDistance);
}

public _cvarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	isEnabled = 	GetConVarBool(cvarisEnabled);
	criticalRange = GetConVarFloat(triggeringDistance);
}

public Action:event_AbilityUsed(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client)
	{
		GetClientAbsOrigin(client, positionArray[client]);
		isPouncing[client] = true;
	}
}

public Action:event_PounceEnded(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client)
	{
		isPouncing[client] = false;
	}
}

public Action:L4D_OnShovedBySurvivor(attacker, client, const Float:vector[3])
{
	if (!isEnabled
	|| !client
	|| !attacker
	|| !IsClientInGame(client)
	|| !IsClientInGame(attacker)
	|| GetClientTeam(client) != L4D2_TEAM_INFECTED
	|| GetClientTeam(attacker) != L4D2_TEAM_SURVIVORS
	|| GetEntProp(client, Prop_Send, ENTPROP_ZOMBIE_CLASS) != ZOMBIE_CLASS_HUNTER
	|| !isPouncing[client]
	|| GetEntityFlags(client) & FL_ONGROUND)
	{
		return Plugin_Continue;
	}
	
	DebugPrintToAll("Midpounce Hunter Melee caught, hunter %N survivor %N", client, attacker);
	
	decl Float:newpos[3];
	GetClientAbsOrigin(client, newpos);
	
	new Float:jumplength = GetVectorDistance(newpos, positionArray[client]);
	DebugPrintToAll("Jump Lenght of %f detected", jumplength);
	
	if (jumplength > criticalRange)
	{
		DebugPrintToAll("Jump Lenght critical, blocking melee");
		return Plugin_Handled;
	}
	else
	{
		DebugPrintToAll("Jump Lenght short, staggering Survivor");
		L4D_StaggerPlayer(attacker, client, NULL_VECTOR);
	}
	
	return Plugin_Continue;
}

stock DebugPrintToAll(const String:format[], any:...)
{
	#if (TEST_DEBUG || TEST_DEBUG_LOG)
	decl String:buffer[256];
	
	VFormat(buffer, sizeof(buffer), format, 2);
	
	#if TEST_DEBUG
	PrintToChatAll("[PK] %s", buffer);
	PrintToConsole(0, "[PK] %s", buffer);
	#endif
	
	LogMessage("%s", buffer);
	#else
	//suppress "format" never used warning
	if(format[0])
		return;
	else
		return;
	#endif
}