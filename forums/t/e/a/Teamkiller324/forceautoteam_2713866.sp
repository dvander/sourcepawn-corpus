#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#pragma semicolon 1
#pragma newdecls required

#define PL_VERSION "1.1"

ConVar	g_CVarAutoTime;
ConVar	g_Cvar;
float	g_AutoTime;
bool	g_Enabled = false;

public Plugin myinfo =
{
	name = "Force Auto Assign",
	author = "Geit",
	description = "Enables mp_forceautoteam for a set time on map start",
	version = PL_VERSION,
	url = "http://gamingmasters.co.uk"
}

public void OnPluginStart()
{
	CreateConVar("sm_forceautoteam_version", PL_VERSION, "Force Auto Team Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_CVarAutoTime = CreateConVar("sm_forceautoteamtime", "0", "Sets the amount of time in seconds that players can only use the auto assign button after map start");
	HookConVarChange(g_CVarAutoTime, OnConvarChanged);
	g_Cvar = FindConVar("mp_forceautoteam");
}

public void OnConvarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	float value = StringToFloat(newValue);
	if (value > 0.0)
	{
		g_AutoTime =  value;
		g_Enabled = true;
	}
	else
	g_Enabled = false;
}

public void OnMapStart()
{
	if (g_Enabled)
	{
		SetConVarBool(g_Cvar, true, true);
		CreateTimer(g_AutoTime, Timer_Disable, _,  TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action Timer_Disable(Handle timer, any client)
{
	SetConVarBool(g_Cvar, false, true);
}