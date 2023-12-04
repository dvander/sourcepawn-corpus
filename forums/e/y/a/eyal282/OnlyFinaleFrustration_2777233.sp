#include <left4dhooks>
#include <sdkhooks>
#include <sdktools>
#include <sourcemod>

#define PLUGIN_VERSION "1.0"
#pragma newdecls required

#pragma semicolon 1

public void OnMapStart()
{
	CreateTimer(1.0, Timer_SetFrustration, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_SetFrustration(Handle hTimer)
{
	SetConVarBool(FindConVar("z_frustration"), L4D_IsMissionFinalMap());

	return Plugin_Stop;
}