/*
// ====================================================================================================
// BASED ON https://forums.alliedmods.net/showthread.php?p=2674363
// Smoker Release by Axel Juan Nieves
// BASED ON https://forums.alliedmods.net/showthread.php?t=98794
// [L4D & L4D2] Boomer Splash Damage by AtomicStryker
// BASED ON https://forums.alliedmods.net/showthread.php?t=234442 
// L4D2 - Noxious Smoker by Mortiegama
// BASED ON https://forums.alliedmods.net/showthread.php?t=335105
// Marttts whole programming contruction I took from his tank car smash plugin.
//
// idea by eyal282 https://forums.alliedmods.net/showthread.php?p=2777620
// but I got the idea all wrong, so well I release the wrong idea anyways
// ====================================================================================================

Change Log:
1.0.1 (19-June-2022)
    - Initial release.
1.0.2 (12-November-2022)
    - Crash on Tonguerelease & Dealdamage / Test with Dealdamage on grab now.
// ====================================================================================================
*/

// ====================================================================================================
// Plugin Info - define
// ====================================================================================================
#define PLUGIN_NAME                   "[L4D] Smoker Sharpshooter"
#define PLUGIN_AUTHOR                 "Finishlast"
#define PLUGIN_DESCRIPTION            "Chance to spawn a smoker with tongue sharpshooter capability"
#define PLUGIN_VERSION                "1.0.2"
#define PLUGIN_URL                    "https://forums.alliedmods.net/showthread.php?p=2781923"

// ====================================================================================================
// Plugin Cvars
// ====================================================================================================
static ConVar g_hCvar_damage
static ConVar g_hCvar_delay
static ConVar g_hCvar_chance

// ====================================================================================================
// int - Plugin Variables
// ====================================================================================================
static int g_iCvar_damage
static int g_iCvar_delay
static int g_iCvar_chance

// ====================================================================================================
// int - Plugin Variables
// ====================================================================================================
bool g_bCvar_spawned

// ====================================================================================================
// Plugin Info
// ====================================================================================================
public Plugin myinfo =
{
    name        = PLUGIN_NAME,
    author      = PLUGIN_AUTHOR,
    description = PLUGIN_DESCRIPTION,
    version     = PLUGIN_VERSION,
    url         = PLUGIN_URL
}

// ====================================================================================================
// Includes
// ====================================================================================================
#include <sourcemod>
#include <sdktools>

// ====================================================================================================
// Pragmas
// ====================================================================================================
#pragma semicolon 1
#pragma newdecls required

// ====================================================================================================
// Cvar Flags
// ====================================================================================================
#define CVAR_FLAGS                    FCVAR_NOTIFY
#define CVAR_FLAGS_PLUGIN_VERSION     FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_SPONLY

// ====================================================================================================
// Filenames
// ====================================================================================================
#define CONFIG_FILENAME               "l4d_smoker_sharpshooter"

// ====================================================================================================
// Defines
// ====================================================================================================


#define TEAM_SURVIVOR	2
#define DMG_GENERIC			0
#define ZOMBIECLASS_SMOKER 1
int g_Attacker[MAXPLAYERS+1];
 

// ====================================================================================================
// Plugin Start
// ====================================================================================================
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    EngineVersion engine = GetEngineVersion();

    if (engine != Engine_Left4Dead && engine != Engine_Left4Dead2)
    {
        strcopy(error, err_max, "This plugin only runs in \"Left 4 Dead\" and \"Left 4 Dead 2\" game");
        return APLRes_SilentFailure;
    }

    return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("l4d_smoker_tonguepunch_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
        g_hCvar_damage = CreateConVar("l4d_smoker_tonguepunchdamage", 	"10", "Damage done to survivor per tonguepunch 1-100", CVAR_FLAGS);  
        g_hCvar_delay = CreateConVar("l4d_smoker_tonguedelay", 	"0", "Delay between tonguepunches 0-100", CVAR_FLAGS); 
  	g_hCvar_chance = CreateConVar("l4d_smoker_chance", 		"20", 	"Percent chance to become a smoker sharpshooter. 1-100", CVAR_FLAGS);

   	 // Load plugin configs from .cfg
    	AutoExecConfig(true, CONFIG_FILENAME);

	g_iCvar_damage = g_hCvar_damage.IntValue;
	g_iCvar_delay = g_hCvar_delay.IntValue;
	g_iCvar_chance = g_hCvar_chance.IntValue;

	HookEvent("tongue_grab", event_tongue_grab);
	HookEvent("tongue_release", event_tongue_release);
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	HookEvent("player_death", reset_stats, EventHookMode_Post);
	HookEvent("round_start", reset_stats, EventHookMode_Post);
	HookEvent("round_end", reset_stats, EventHookMode_Post);  
}

public void OnMapStart()
{
	SetConVarInt(FindConVar("tongue_miss_delay"), g_iCvar_delay);
}

public void reset_stats(Handle event, const char[] name, bool dontBroadcast)
{
	if ( StrEqual(name, "round_start") || StrEqual(name, "round_end") )
	{
		for (int i=1; i<=MAXPLAYERS; i++)
		{
			g_Attacker[i] = 0;
		}
		return;
	}
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	g_Attacker[client] = 0;
}


public void Event_PlayerSpawn (Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event,"userid"));
	
	if (IsValidSmoker(client))
	{
	int tempchance=GetRandomInt(1, 100);
	//PrintToChatAll("random number:  %i", tempchance);
	//PrintToChatAll("percent chance:  %i", g_iCvar_chance);
	if(tempchance <= g_iCvar_chance)
	{
		PrintToChatAll("[SM] A smoker sharpshooter is around, take care.");
		g_bCvar_spawned = true;
	}
	else
	{
		g_bCvar_spawned = false;
	}
	}
}

public bool IsValidSmoker(int client)
{
	if (IsValidClientInGame(client) && GetClientTeam(client) == 3)
	{
		int class = GetEntProp(client, Prop_Send, "m_zombieClass");
		
		if (class == ZOMBIECLASS_SMOKER)
			return true;
		
		return false;
	}
	
	return false;
}

//smoker grabbed someone...
public void event_tongue_grab(Handle event, const char[] name, bool dontBroadcast)
{
	if (g_bCvar_spawned == true)
	{

	int victim = GetClientOfUserId(GetEventInt(event, "victim"));
	int attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!victim) return;
	if (!attacker) return;
	
	g_Attacker[victim] = attacker;
	DealDamage(victim, g_iCvar_damage, attacker, DMG_GENERIC);
	SetEntityMoveType(attacker, MOVETYPE_NOCLIP);
	SetEntPropFloat(attacker, Prop_Data, "m_flLaggedMovementValue", 0.0);    
	CreateTimer(0.1, SetMovetype, g_Attacker[victim]);
	}
}

//smoker released someone...
public void event_tongue_release(Handle event, const char[] name, bool dontBroadcast)
{
	if (g_bCvar_spawned == true)
	{

	int victim = GetClientOfUserId(GetEventInt(event, "victim"));
	int smoker = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!victim) return;
	if (!smoker) return;
	
	
	//we need to check this because hunters can steal victims to smokers...
	if (g_Attacker[victim] == smoker)
	{
		g_Attacker[victim] = 0;
	}
	}
}


public Action SetMovetype(Handle timer, int client)
{
	if ( !IsValidClientInGame(client) )
		return Plugin_Stop;
 
	SetEntityMoveType(client, MOVETYPE_WALK);
	SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0);    
	return Plugin_Stop;
}

stock int IsValidClientInGame(int client)
{
	if (IsValidClientIndex(client))
	{
		if (IsClientInGame(client))
			return 1;
	}
	return 0;
}

stock int IsValidClientIndex(int index)
{
	if (index>0 && index<=MaxClients)
	{
		return 1;
	}
	return 0;
}

stock void DealDamage(int victim, int damage, int attacker=0, int dmg_type=DMG_GENERIC, char[] weapon="")
{
	if ( !IsValidClientInGame(victim) ) return;
	if ( !IsPlayerAlive(victim) ) return;
	if ( damage<=0 ) return;
	
	char dmg_str[16];
	IntToString(damage, dmg_str, 16);
	char dmg_type_str[32];
	IntToString(dmg_type, dmg_type_str, 32);
	int pointHurt = CreateEntityByName("point_hurt");
	if (!pointHurt) return;
	
	DispatchKeyValue(victim, "targetname", "war3_hurtme");
	DispatchKeyValue(pointHurt, "DamageTarget", "war3_hurtme");
	DispatchKeyValue(pointHurt, "Damage", dmg_str);
	DispatchKeyValue(pointHurt, "DamageType", dmg_type_str);
	if(!StrEqual(weapon,""))
		DispatchKeyValue(pointHurt, "classname", weapon);
	
	DispatchSpawn(pointHurt);
	AcceptEntityInput(pointHurt, "Hurt", (attacker>0)?attacker:-1);
	DispatchKeyValue(pointHurt, "classname", "point_hurt");
	DispatchKeyValue(victim, "targetname", "war3_donthurtme");
	RemoveEdict(pointHurt);
}