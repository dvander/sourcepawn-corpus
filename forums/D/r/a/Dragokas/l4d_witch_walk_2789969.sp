#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <evil_witch>

#define PLUGIN_VERSION "1.0"

#define DEBUG 0

public Plugin myinfo =
{
	name = "[L4D] Walking witch",
	author = "Dragokas",
	description = "Witch can walk",
	version = PLUGIN_VERSION,
	url = ""
}

/*
	Version history:
	
	 * 1.0 (12-Mar-2020)
	  - First release
		
*/

#define CVAR_FLAGS	FCVAR_NOTIFY

ConVar g_hConVarEnable;
ConVar g_hConVarWalkChance;
ConVar g_hConVarWalkTimeMin;
ConVar g_hConVarWalkTimeMax;
ConVar g_hConVarSitTimeMin;
ConVar g_hConVarSitTimeMax;

bool g_bEvilWitchLib;
bool g_bEnabled;
int g_iWalkChance;
float g_fWalkTimeMin;
float g_fWalkTimeMax;
float g_fSitTimeMin;
float g_fSitTimeMax;

public void OnPluginStart()
{
	CreateConVar("l4d_witch_walk_version", PLUGIN_VERSION, "Plugin version", CVAR_FLAGS | FCVAR_DONTRECORD);
	
	g_hConVarEnable = CreateConVar("l4d_witch_walk_enable", "1", "Enable plugin (1 - Yes, 0 - No)", CVAR_FLAGS);
	g_hConVarWalkChance = CreateConVar("l4d_witch_walk_chance", "50", "% chance the witch become 'walking witch'", CVAR_FLAGS);
	g_hConVarWalkTimeMin = CreateConVar("l4d_witch_walk_time_min", "10", "Count of seconds (minimum) witch will walk (0 - for always walk)", CVAR_FLAGS);
	g_hConVarWalkTimeMax = CreateConVar("l4d_witch_walk_time_max", "15", "Count of seconds (maximum) witch will walk", CVAR_FLAGS);
	g_hConVarSitTimeMin = CreateConVar("l4d_witch_sit_time_min", "3", "Count of seconds (minimum) witch will sit down before walking again (0 - to disable walking again after witch sit down)", CVAR_FLAGS);
	g_hConVarSitTimeMax = CreateConVar("l4d_witch_sit_time_max", "7", "Count of seconds (maximum) witch will sit down before walking again", CVAR_FLAGS);
	
	AutoExecConfig(true, "l4d_witch_walk");
	
	GetCvars();
	
	HookEvent("witch_spawn", 			Event_WitchSpawn);
	
	g_hConVarEnable.AddChangeHook(OnConVarEnableChanged);
	
	g_hConVarWalkChance.AddChangeHook(OnConVarChanged);
	g_hConVarWalkTimeMin.AddChangeHook(OnConVarChanged);
	g_hConVarWalkTimeMax.AddChangeHook(OnConVarChanged);
	g_hConVarSitTimeMin.AddChangeHook(OnConVarChanged);
	g_hConVarSitTimeMax.AddChangeHook(OnConVarChanged);
}

public void OnAllPluginsLoaded()
{
	g_bEvilWitchLib = LibraryExists("evil_witch");
}

public void OnConVarEnableChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bEnabled = g_hConVarEnable.BoolValue;

	if ( !g_bEnabled && g_bEvilWitchLib )
	{
		for (int i = MaxClients + 1; i <= 2048; i++)
		{
			if ( IsWitch(i) )
			{
				EW_WitchWalk(i, 0);
			}
		}
	}
}

public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_bEnabled = g_hConVarEnable.BoolValue;
	g_iWalkChance = g_hConVarWalkChance.IntValue;
	g_fWalkTimeMin = g_hConVarWalkTimeMin.FloatValue;
	g_fWalkTimeMax = g_hConVarWalkTimeMax.FloatValue;
	g_fSitTimeMin = g_hConVarSitTimeMin.FloatValue;
	g_fSitTimeMax = g_hConVarSitTimeMax.FloatValue;
}

public void Event_WitchSpawn(Event event, const char[] sName, bool bDontBroadcast)
{
	#if DEBUG
	PrintToChatAll("Witch: %i spawned", event.GetInt("witchid"));
	#endif

	if ( g_bEnabled && GetRandomInt(1, 100) <= g_iWalkChance )
	{
		#if DEBUG
		PrintToChatAll("chance is success.");
		#endif
		
		CreateTimer(0.2, Timer_DelayHookWitch, EntIndexToEntRef(event.GetInt("witchid")), TIMER_FLAG_NO_MAPCHANGE );
	}
}

Action Timer_DelayHookWitch(Handle timer, int witchRef)
{
	if ( g_bEvilWitchLib && IsValidEntRef(witchRef) && IsWitch(witchRef) )
	{
		int witchid = EntRefToEntIndex(witchRef);
		
		#if DEBUG
		PrintToChatAll("Witch: %i started to walk", witchid);
		#endif
	
		EW_WitchWalk(witchid, 1);
		
		if ( g_fWalkTimeMin != 0.0 )
		{
			CreateTimer( GetRandomFloat(g_fWalkTimeMin, g_fWalkTimeMax), Timer_WitchStop, EntIndexToEntRef(witchid), TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	return Plugin_Continue;
}

Action Timer_WitchStop(Handle timer, int witchRef)
{
	if ( IsValidEntRef(witchRef) )
	{
		int witchid = EntRefToEntIndex(witchRef);
		
		#if DEBUG
		PrintToChatAll("Witch: %i stopped and sit down", witchid);
		#endif
		
		EW_WitchWalk(witchid, 0);
		
		if ( g_fSitTimeMin != 0.0)
		{
			CreateTimer(GetRandomFloat(g_fSitTimeMin, g_fSitTimeMax), Timer_DelayHookWitch, witchRef, TIMER_FLAG_NO_MAPCHANGE );
		}
	}
	return Plugin_Continue;
}

bool IsWitch(int witch)
{
	if( witch && IsValidEdict(witch) && IsValidEntity(witch) )
	{
		static char classname[32];
		GetEdictClassname(witch, classname, sizeof(classname));
		if(strcmp(classname, "witch") == 0)
		{
			return true;
		}
	}
	return false;
}

bool IsValidEntRef(int entity)
{
	if( entity && entity != -1 && EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE )
		return true;
	return false;
}