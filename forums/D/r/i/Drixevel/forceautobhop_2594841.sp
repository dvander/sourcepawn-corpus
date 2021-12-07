#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

public Plugin myinfo =
{
	name = "Force Autobhop",
	author = "Keith Warren (Shaders Allen)",
	description = "Forces autobhop every round.",
	version = "1.0.0",
	url = "https://github.com/ShadersAllen"
};

public void OnPluginStart()
{
	HookEvent("round_start", Event_OnRoundStart);
}

public void Event_OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	CreateTimer(0.3, Timer_DelaySetConVar, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_DelaySetConVar(Handle timer)
{
	FindConVar("sv_autobunnyhopping").SetInt(1);
}