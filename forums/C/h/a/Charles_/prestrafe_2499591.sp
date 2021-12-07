#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <smlib/entities>

#pragma semicolon 1
//#pragma newdecls required

public Plugin myinfo = {
	name = "CS:GO Enable Prestrafe",
	description = "Makes Prestrafe work on CSGO",
	author = "Charles_",
	version = "1.0",
	url = "http://steamcommunity.com/id/hypnos_/"
}

public void OnPluginStart()
{
	HookEvent("server_cvar", 		HookServerVariables, 	EventHookMode_Pre);
}

public void OnMapStart()
{
	// Enforce settings
	CreateTimer(5.0, Timer_CheckConvars, _, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
}

stock ForceConVar(String:cvarname[], String:value[]){
	ConVar cvar = FindConVar(cvarname);
	if(cvar != null)
		cvar.SetString(value, true);
}

public Action HookServerVariables(Handle event, const char[] name, bool dontBroadcast){
	SetEventBroadcast(event, true);

	char cvar_string[64];
	GetEventString(event, "cvarname", cvar_string, sizeof(cvar_string));

	if(StrEqual(cvar_string, "sv_enablebunnyhopping", false))
		SetEventInt(event, "cvarvalue", 1);

	if(StrEqual(cvar_string, "sv_accelerate", false))
		SetEventInt(event, "cvarvalue", 5);

	if(StrEqual(cvar_string, "sv_friction", false))
		SetEventInt(event, "cvarvalue", 4);

	if(StrEqual(cvar_string, "sv_staminamax", false))
		SetEventInt(event, "cvarvalue", 0);

	if(StrEqual(cvar_string, "sv_staminalandcost", false))
		SetEventInt(event, "cvarvalue", 0);
		
	if(StrEqual(cvar_string, "sv_staminajumpcost", false))
		SetEventInt(event, "cvarvalue", 0);

	return Plugin_Continue;
}

public Action Timer_CheckConvars(Handle timer)
{
	ForceConVar("sv_enablebunnyhopping", "1");
	ForceConVar("sv_accelerate", "5");
	ForceConVar("sv_friction", "4");
	ForceConVar("sv_staminamax", "0");
	ForceConVar("sv_staminalandcost", "0");
	ForceConVar("sv_staminajumpcost", "0");
}

