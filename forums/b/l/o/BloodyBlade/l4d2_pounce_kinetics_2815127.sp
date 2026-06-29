#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <left4dhooks>

#define PLUGIN_VERSION 						"1.0.0"

#define TEST_DEBUG 		0
#define TEST_DEBUG_LOG 	0

static const char ENTPROP_ZOMBIE_CLASS[] 	= "m_zombieClass";
static const int ZOMBIE_CLASS_HUNTER		= 3;
static const int L4D2_TEAM_SURVIVORS		= 2;
static const int L4D2_TEAM_INFECTED			= 3;

static ConVar cvarisEnabled, triggeringDistance;
static bool isEnabled = true, isPouncing[MAXPLAYERS + 1];
static float criticalRange = 450.0, positionArray[MAXPLAYERS + 1][3];

public Plugin myinfo = 
{
	name = "L4D2 Pounce Kinetics",
	author = " AtomicStryker",
	description = " Applies laws of physics to Hunter Pouncing ",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1257376"
}

public void OnPluginStart()
{
	if (FindConVar("l4d2_melee_immortals_version") != null)
	{
		ServerCommand("sm plugins reload l4d2_melee_immortals.smx");
	}

	CreateConVar("l4d2_pounce_kinetics_version", 						PLUGIN_VERSION, " L4D2 Pounce Kinetics Plugin Version ", 			FCVAR_NOTIFY|FCVAR_DONTRECORD);
	cvarisEnabled = 		CreateConVar("l4d2_pounce_kinetics_enabled", "1", 			" Turn Pounce Kinetics on and off ", 				FCVAR_NOTIFY);
	triggeringDistance = 	CreateConVar("l4d2_pounce_kinetics_range",	"450.0", 		" What Pounce Range is considered unstoppable ",	FCVAR_NOTIFY);

	cvarisEnabled.AddChangeHook(_cvarEnabledChange);
	triggeringDistance.AddChangeHook(_cvarDistanceChange);
}

public void OnConfigsExecuted()
{
	IsAllowed();
}

void IsAllowed()
{
	bool PluginOn = cvarisEnabled.BoolValue;
	if(PluginOn)
	{
		GetCvars();
		HookEvent("ability_use", event_AbilityUsed);
		HookEvent("pounce_end", event_PounceEnded);
	}
	else
	{
		UnhookEvent("ability_use", event_AbilityUsed);
		UnhookEvent("pounce_end", event_PounceEnded);
	}
}

void GetCvars()
{
	criticalRange = triggeringDistance.FloatValue;
}

void _cvarEnabledChange(ConVar convar, const char[] oldValue, const char[] newValue)
{
	IsAllowed();
}

void _cvarDistanceChange(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

Action event_AbilityUsed(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client)
	{
		GetClientAbsOrigin(client, positionArray[client]);
		isPouncing[client] = true;
	}
	return Plugin_Continue;
}

Action event_PounceEnded(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client)
	{
		isPouncing[client] = false;
	}
	return Plugin_Continue;
}

public Action L4D_OnShovedBySurvivor(int attacker, int client, const float vector[3])
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

	float newpos[3];
	GetClientAbsOrigin(client, newpos);

	float jumplength = GetVectorDistance(newpos, positionArray[client]);
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

stock void DebugPrintToAll(const char[] format, any ...)
{
	#if (TEST_DEBUG || TEST_DEBUG_LOG)
	char buffer[256];

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
