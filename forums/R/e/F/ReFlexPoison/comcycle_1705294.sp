#include <sourcemod>

#define PLUGIN_VERSION "1.0"

new Handle:sm_comcycle_enabled;
new Handle:sm_comcycle_timez;
new Handle:timez_handle;
new Float:timez

public Plugin:myinfo = 
{
	name = "Command Cycle",
	author = "ReFlexPoison",
	description = "Execute Commands via Config File Every Designated Amount of Time",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1705294#post1705294"
}

public OnPluginStart()
{
	CreateConVar("sm_comcycle_version", PLUGIN_VERSION, "Command Cycle Version", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);
	
	sm_comcycle_enabled = CreateConVar("sm_comcycle_enabled", "1", "Enable Command Cycle\n1=Enabled\n0=Disabled", FCVAR_NONE, true, 0.0, true, 1.0);
	
	sm_comcycle_timez = CreateConVar("sm_comcycle_time", "120", "Time Increment to Run Commands");
	timez = GetConVarFloat(sm_comcycle_timez);
	HookConVarChange(sm_comcycle_timez, timezCVarChanged);
}

stock ClearTimer(&Handle:timer)
{
	if (timer != INVALID_HANDLE)
	{
		KillTimer(timer);
		timer = INVALID_HANDLE;
	}	 
}

public OnMapStart()
{
	timez_handle = CreateTimer(timez, execute, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

//Failsafe
public OnMapEnd()
{
	KillTimer(timez_handle);
}

public Action:execute(Handle:timer)
{
	if(GetConVarInt(sm_comcycle_enabled) == 1)
	{
		ServerCommand("exec sourcemod/comcycle.cfg");
	}
}

public timezCVarChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	timez = GetConVarFloat(cvar);
	KillTimer(timez_handle);
	{
		timez_handle = CreateTimer(timez, execute, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	}
}