#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "1.01"

new Handle:Cvar_COUNTDOWN_ENABLED
new Handle:Cvar_COUNTDOWN_BEGIN_MIN
new Handle:Cvar_COUNTDOWN_BEGIN_SEC
new SecsLeft = 0, MinsLeft = 0

public Plugin:myinfo = 
{
	name = "Map SecsLeft countdown",
	author = "simoneaolson",
	description = "Displays the SecsLeft beginning at x seconds remaining",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
}

public OnPluginStart()
{
	CreateConVar("sm_tcountdown_version", PLUGIN_VERSION, "Current plugin version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
	Cvar_COUNTDOWN_ENABLED = CreateConVar("sm_tcountdown_enabled", "1", "Enable SecsLeft countdown 0/1", FCVAR_PLUGIN)
	Cvar_COUNTDOWN_BEGIN_MIN = CreateConVar("sm_tcountdown_begin_min", "1", "Minutes to start countdown at", FCVAR_PLUGIN)
	Cvar_COUNTDOWN_BEGIN_SEC = CreateConVar("sm_tcountdown_begin_sec", "0", "Seconds (added on to minutes) to start countdown at", FCVAR_PLUGIN)

	AutoExecConfig(true, "sm_tcountdown", "sm_tcountdown")
}

public OnMapStart()
{
	if (GetConVarBool(Cvar_COUNTDOWN_ENABLED)==false) return
	CreateTimer(5.0, CheckSecsLeft)
}

public Action:CheckSecsLeft(Handle:timer)
{
	GetMapTimeLeft(SecsLeft)
	if (SecsLeft==GetConVarInt(Cvar_COUNTDOWN_BEGIN_MIN)*60+GetConVarInt(Cvar_COUNTDOWN_BEGIN_SEC))
	{
		MinsLeft = GetConVarInt(Cvar_COUNTDOWN_BEGIN_MIN)
		SecsLeft = GetConVarInt(Cvar_COUNTDOWN_BEGIN_SEC)
		CreateTimer(0.0, DisplaySecsLeft)
	} else {
		CreateTimer(1.0, CheckSecsLeft)
	}
}

public Action:DisplaySecsLeft(Handle:timer)
{
	if (SecsLeft>9)
	{
		PrintCenterTextAll("Time left: 0%i:%i", MinsLeft, SecsLeft)
	} else {
		PrintCenterTextAll("Time left: 0%i:0%i", MinsLeft, SecsLeft)
	}
	if (MinsLeft==0 && SecsLeft==0) return
	if (SecsLeft==0)
	{
		MinsLeft -= 1
		SecsLeft = 59
	} else {
		SecsLeft -= 1
	}
	CreateTimer(0.99, DisplaySecsLeft)
}