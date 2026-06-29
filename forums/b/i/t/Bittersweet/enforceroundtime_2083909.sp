#include <sourcemod>
#include <cstrike>
#include <updater>

#define UPDATE_URL "http://bbgcss.servegame.com/updater/enforceroundtime.txt"

new const String:PLUGIN_NAME[]= "enforceroundtime"
new const String: PLUGIN_AUTHOR[]= "Bittersweet"
new const String:PLUGIN_DESCRIPTION[]= "Enforces round time limits for CS:S.  When mp_roundtime expires, the round ends with a round draw"
new const String: PLUGIN_VERSION[]= "2014.01.10.001"

/*
* Version History
* 2014.01.10.001 - Initial release
*/

new Handle:c_mp_roundtime = INVALID_HANDLE
new Handle:c_mp_round_restart_delay = INVALID_HANDLE
new Handle:t_roundtimer = INVALID_HANDLE
new Float:timelimitseconds = 0.0
new Float:roundrestartdelayseconds = 0.0

public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
}
public OnPluginStart()
{
	PrintToServer("[%s %s] - Loaded", PLUGIN_NAME, PLUGIN_VERSION)
	CreateConVar("enforceroundtime_version", PLUGIN_VERSION, "Enforces round times in CS:S.  Use for maps that don't end rounds correctly.", FCVAR_DONTRECORD|FCVAR_NOTIFY)
	HookEvent("round_freeze_end", OnRoundFreezeEnd)
	HookEvent("round_end", OnRoundEnd)
	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL)
	}
}
public OnConfigsExecuted()
{
	c_mp_roundtime = FindConVar("mp_roundtime")
	if (c_mp_roundtime == INVALID_HANDLE)
	{
		PrintToServer("[%s %s] - ERROR!  Fatal error - could not obtain handle to mp_roundtime, exiting...", PLUGIN_NAME, PLUGIN_VERSION)
		return 
	}
	HookConVarChange(c_mp_roundtime, OnCvar_mp_roundtime_changed)
	timelimitseconds = GetConVarFloat(c_mp_roundtime) * 60.0
	c_mp_round_restart_delay = FindConVar("mp_round_restart_delay")
	if (c_mp_round_restart_delay == INVALID_HANDLE)
	{
		PrintToServer("[%s %s] - ERROR!  Fatal error - could not obtain handle to mp_round_restart_delay, exiting...", PLUGIN_NAME, PLUGIN_VERSION)
		return 
	}
	roundrestartdelayseconds = GetConVarFloat(c_mp_round_restart_delay)
	HookConVarChange(c_mp_round_restart_delay, OnCvar_c_mp_round_restart_delay_changed)
	if (!Updater_ForceUpdate())
	{
		PrintToServer("[%s %s] - Updater failed to check for updates", PLUGIN_NAME, PLUGIN_VERSION)
	}
}
public OnRoundFreezeEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetClientCount() > 0) t_roundtimer = CreateTimer(timelimitseconds, ForceRoundEnd)
}
public OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (t_roundtimer != INVALID_HANDLE) KillTimer(t_roundtimer)
}
public OnGameFrame()
{
	if (!IsServerProcessing() && t_roundtimer != INVALID_HANDLE) KillTimer(t_roundtimer)
}
public OnCvar_mp_roundtime_changed(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	timelimitseconds = GetConVarFloat(c_mp_roundtime) * 60.0
	PrintToServer("[%s %s] - Round time changed to %0.2f seconds", PLUGIN_NAME, PLUGIN_VERSION, timelimitseconds)
}
public OnCvar_c_mp_round_restart_delay_changed(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	roundrestartdelayseconds = GetConVarFloat(c_mp_round_restart_delay)
	PrintToServer("[%s %s] - Round restart delay changed to %f seconds", PLUGIN_NAME, PLUGIN_VERSION, roundrestartdelayseconds)
}
public Action:ForceRoundEnd(Handle:timer)
{
	t_roundtimer = INVALID_HANDLE
	PrintToServer("[%s %s] - Enforcing %.2f second round time", PLUGIN_NAME, PLUGIN_VERSION, timelimitseconds)
	CS_TerminateRound(roundrestartdelayseconds, CSRoundEnd_Draw)
}
public Action:Updater_OnPluginChecking()
{
	PrintToServer("[%s %s] - Contacting update server...", PLUGIN_NAME, PLUGIN_VERSION)
	return Plugin_Continue
}
public Action:Updater_OnPluginDownloading()
{
	PrintToServer("[%s %s] - Downloading update(s)...", PLUGIN_NAME, PLUGIN_VERSION)
	return Plugin_Continue
}
public Updater_OnPluginUpdated()
{
	ReloadPlugin(INVALID_HANDLE)
}
//End of code