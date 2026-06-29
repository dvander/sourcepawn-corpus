#pragma semicolon 	1
#include <colors>
#pragma newdecls 	required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "2.0"

ConVar PluginEnabled = null;

bool AlarmStarted = false;

public Plugin myinfo = 
{
	name  = "[L4D] Who Fired Car Alarm",
	author = "samuelviveiros a.k.a Dartz8901",
	description = "Displays the name of the player who fired the car alarm",
	version = PLUGIN_VERSION,
	url = "N/A"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion engine = GetEngineVersion();
	if(engine != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("l4d2_car_alarm_version", PLUGIN_VERSION, "[L4D2] Who Fired Car Alarm version");
	PluginEnabled = CreateConVar("l4d2_car_alarm_enable", "1", "Enable or disable this plugin.", _, true, 0.0, true, 1.0);
	LoadTranslations("l4d2_caralarm.phrases");
	AutoExecConfig(true, "l4d2_car_alarm");
}

public void HookOutput_PropCarAlarm(const char[] output, int caller, int activator, float delay)
{
    if (StrEqual(output, "OnCarAlarmStart"))
    {
        AlarmStarted = true;
    }
    else if (StrEqual(output, "OnTakeDamage"))
    {
        if (AlarmStarted)
        {
            AlarmStarted = false;
            DisplayTrollName(activator);
        }
    }
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (PluginEnabled.IntValue != 0 && StrEqual(classname, "prop_car_alarm") )
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
    if (AlarmStarted)
    {
        AlarmStarted = false;
        DisplayTrollName(who_start_touch);
    }
}

void DisplayTrollName(int troll)
{
    if (IsValidPlayer(troll) && 
        IsClientInGame(troll) && 
        GetClientTeam(troll) == 2)
    {
        char name[MAX_NAME_LENGTH];
        if (GetClientName(troll, name, sizeof(name)))
        {
            CPrintToChatAll("%t", "Car Alarm Triggered by %s", name);
        }
    }
}

stock bool IsValidPlayer(int entity)
{
    return (IsValidEntity(entity) && entity > 0 && entity <= MaxClients);
}
