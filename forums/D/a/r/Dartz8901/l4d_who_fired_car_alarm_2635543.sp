/************************************************************************
  [L4D] Who Fired Car Alarm (v1.0.0, 2019-01-19)

  DESCRIPTION: 

    The purpose of this plugin is to display the name of the 
    player who fired a car alarm.

  CHANGELOG:

  2019-01-19 (v1.0.0)
    - Initial release.

 ************************************************************************/

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

/**
 * Compiler requires semicolons and the new syntax.
 */
#pragma semicolon 	1
#pragma newdecls 	required

/**
 * Semantic versioning <https://semver.org/>
 */
#define PLUGIN_VERSION 	"1.0.0"

public Plugin myinfo = 
{
	name 			= "[L4D] Who Fired Car Alarm",
	author 			= "samuelviveiros a.k.a Dartz8901",
	description 	= "Displays the name of the player who fired the car alarm",
	version 		= PLUGIN_VERSION,
	url 			= "https://github.com/samuelviveiros/l4d_who_fired_car_alarm"
};

#define CL_DEFAULT 		"\x01"
#define CL_LIGHTGREEN 	"\x03"
#define CL_YELLOW 		"\x04"
#define CL_GREEN 		"\x05"

#define TEAM_SURVIVOR 	2

bool AlarmStarted 		= false;
Handle PluginEnabled 	= null;

//
// Ripped directly from the "[L4D & L4D2] Flashlight Package" plugin (by SilverShot)
// http://forums.alliedmods.net/showthread.php?t=173257
//
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion engine = GetEngineVersion();
	if( engine != Engine_Left4Dead )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("l4d_who_fired_car_alarm_version", PLUGIN_VERSION, "[L4D] Who Fired Car Alarm version", FCVAR_REPLICATED | FCVAR_NOTIFY);
	PluginEnabled = CreateConVar("l4d_who_fired_car_alarm_enable", "1", "Enable or disable this plugin.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	AutoExecConfig(true, "l4d_who_fired_car_alarm");
}

public void HookOutput_PropCarAlarm(const char[] output, int caller, int activator, float delay)
{
    if ( StrEqual(output, "OnCarAlarmStart") )
    {
        AlarmStarted = true;
    }
    else if ( StrEqual(output, "OnTakeDamage") )
    {
        if ( AlarmStarted )
        {
            AlarmStarted = false;
            DisplayTrollName(activator);
        }
    }
}

// Snippet adapted from https://forums.alliedmods.net/showthread.php?t=210782
public void OnEntityCreated(int entity, const char[] classname)
{
	if ( GetConVarInt(PluginEnabled) != 0 && StrEqual(classname, "prop_car_alarm") )
	{
        SDKHook(entity, SDKHook_Spawn, Hook_PropCarAlarmSpawned);
        SDKHook(entity, SDKHook_StartTouch, Hook_PropCarAlarmTouched);
	}
}

public Action Hook_PropCarAlarmSpawned(int entity)
{
	HookSingleEntityOutput(entity, "OnCarAlarmStart", HookOutput_PropCarAlarm);
	HookSingleEntityOutput(entity, "OnTakeDamage", HookOutput_PropCarAlarm);
}

public Action Hook_PropCarAlarmTouched(int entity, int who_start_touch)
{
    if ( AlarmStarted )
    {
        AlarmStarted = false;
        DisplayTrollName(who_start_touch);
    }
}

void DisplayTrollName(int troll)
{
    if (IsValidPlayer(troll) && 
        IsClientInGame(troll) && 
        GetClientTeam(troll) == TEAM_SURVIVOR)
    {
        char name[MAX_NAME_LENGTH];
        if ( GetClientName(troll, name, sizeof(name)) )
        {
            PrintToChatAll("%s%s fired the car alarm.%s", CL_YELLOW,name,CL_DEFAULT);
        }
    }
}

stock bool IsValidPlayer(int entity)
{
    return ( IsValidEntity(entity) && entity > 0 && entity <= MaxClients );
}
