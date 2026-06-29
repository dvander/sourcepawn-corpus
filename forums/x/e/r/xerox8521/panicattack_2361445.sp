#pragma semicolon 1
#include <sourcemod>
#pragma newdecls required

#define PLUGIN_VERSION "3.0"

#define TEAM_SPECTATOR	1
#define TEAM_SURVIVOR	2
#define TEAM_ZOMBIE		3
#define TEAM_LOBBY		4

ConVar sm_panic_delay = null;
ConVar sm_panic_enabled = null;

public Plugin myinfo =
{
	name = "ZPS Panic Attack",
	author = "Will2Tango",
	description = "Blocks Survivors from Panicing at Round Start.",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
}

public void OnPluginStart()
{
	CreateConVar("sm_panic_version",PLUGIN_VERSION,"Version of the panic attack plugin",FCVAR_PLUGIN|FCVAR_NOTIFY);
	sm_panic_enabled = CreateConVar("sm_panic_enabled","1","1 = plugin enabled 0 = plugin disabled",FCVAR_NOTIFY,true,0.0,true,1.0);
	sm_panic_delay = CreateConVar("sm_panic_delay","10.0","How long (in seconds) after round start the panic is delayed",FCVAR_NOTIFY);
	
	sm_panic_enabled.AddChangeHook(OnConVarChanged);
	sm_panic_delay.AddChangeHook(OnConVarChanged);
	
	HookEvent("player_spawn",Event_PlayerSpawn);
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if(sm_panic_enabled.BoolValue == true)
	{
		int client = GetClientOfUserId(event.GetInt("userid"));
	
		if(GetClientTeam(client) == TEAM_SURVIVOR)
		{
			SetEntPropFloat(client,Prop_Data,"m_fPanicLimit",GetGameTime() + sm_panic_delay.FloatValue);
		}
	}
}

public void OnConVarChanged(ConVar cvar,const char[] oldValue, const char[] newValue)
{
	if(cvar == sm_panic_enabled)
	{
		sm_panic_enabled.BoolValue = view_as<bool>(StringToInt(newValue));
	}
	else if(cvar == sm_panic_delay)
	{
		sm_panic_delay.FloatValue = StringToFloat(newValue);
	}
}