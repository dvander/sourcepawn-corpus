#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <left4downtown>


#define PLUGIN_VERSION 						  "1.0.2"

#define TEST_DEBUG 		0
#define TEST_DEBUG_LOG 	0


static const String:ENTPROP_ZOMBIE_CLASS[] 	= "m_zombieClass";
static const L4D2_TEAM_SURVIVORS			= 2;
static const L4D2_TEAM_INFECTED				= 3;

/*
enum SI_ZOMBIE_CLASSES
{
	CLASS_SMOKER = 1,
	CLASS_BOOMER = 2,
	CLASS_HUNTER = 3,
	CLASS_SPITTER = 4,
	CLASS_JOCKEY = 5
}
*/

static flag[] =
{
	0, // UNDEF
	1, // SMOKER
	2, // BOOMER
	4, // HUNTER
	8, // SPITTER
	16 // JOCKEY
};

static Handle:cvarisEnabled					= INVALID_HANDLE;
static Handle:cvarFlags						= INVALID_HANDLE;
static bool:isEnabled						= true;


public Plugin:myinfo = 
{
	name = "L4D2 Melee Immortals",
	author = " AtomicStryker",
	description = " Removes the mandatory SI Death after four melee strikes ",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1257365"
}

public OnPluginStart()
{
	CreateConVar(					"l4d2_melee_immortals_version", PLUGIN_VERSION, " L4D2 Melee Immortals Plugin Version ", 														FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	cvarFlags =		CreateConVar(	"l4d2_melee_immortals_flags", 	"31", 			" binary flag of immortal SI. 1 = smoker, 2 = boomer, 4 = hunter, 8 = spitter, 16 = jockey", 	FCVAR_PLUGIN | FCVAR_NOTIFY);
	cvarisEnabled = CreateConVar(	"l4d2_melee_immortals_enabled", "1", 			" Turn Melee Immortals on and off ", 															FCVAR_PLUGIN|FCVAR_REPLICATED);

	HookConVarChange(cvarisEnabled, _cvarChange);
	
	isEnabled = GetConVarBool(cvarisEnabled);
}

public _cvarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	isEnabled = GetConVarBool(cvarisEnabled);
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
	|| !(GetSIFlag(client) & GetConVarInt(cvarFlags)))
	{
		return Plugin_Continue;
	}
	
	DebugPrintToAll("Melee Immortals: SI %N shoved by survivor %N, replacing stagger function", client, attacker);
	
	L4D_StaggerPlayer(client, attacker, NULL_VECTOR);

	return Plugin_Handled;
}

static GetSIFlag(client)
{
	return flag[GetEntProp(client, Prop_Send, ENTPROP_ZOMBIE_CLASS)];
}

stock DebugPrintToAll(const String:format[], any:...)
{
	#if (TEST_DEBUG || TEST_DEBUG_LOG)
	decl String:buffer[256];
	
	VFormat(buffer, sizeof(buffer), format, 2);
	
	#if TEST_DEBUG
	PrintToChatAll("[MI] %s", buffer);
	PrintToConsole(0, "[MI] %s", buffer);
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