#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PL_VERSION "1.1"

new Handle:g_CVarAutoTime;
new Handle:g_Cvar;
new Float:g_AutoTime;
new bool:g_Enabled = false;

public Plugin:myinfo =
{
	name = "Force Auto Assign",
	author = "Geit",
	description = "Enables mp_forceautoteam for a set time on map start",
	version = PL_VERSION,
	url = "http://gamingmasters.co.uk"
}

public OnPluginStart()
{
	CreateConVar("sm_forceautoteam_version", PL_VERSION, "Force Auto Team Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_CVarAutoTime = CreateConVar("sm_forceautoteamtime", "0", "Sets the amount of time in seconds that players can only use the auto assign button after map start");
	HookConVarChange(g_CVarAutoTime, OnConvarChanged);
	g_Cvar = FindConVar("mp_forceautoteam");
}

public OnConvarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	new Float:value = StringToFloat(newValue);
	if (value > 0.0)
	{
		g_AutoTime =  value;
		g_Enabled = true;
	}
	else
	g_Enabled = false;
}

public OnMapStart()
{
	if (g_Enabled)
	{
		SetConVarBool(g_Cvar, true, true);
		CreateTimer(g_AutoTime, Timer_Disable, _,  TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:Timer_Disable(Handle:timer, any:client)
{
	SetConVarBool(g_Cvar, false, true);
}