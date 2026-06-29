#pragma semicolon 1
#define PLUGIN_VERSION "1.0"

#include <sourcemod>

ConVar cv_Enabled;

public Plugin myinfo = {
	name        = "[TF2/ANY] Block Kill Feed",
	author      = "Sgt. Gremulock",
	description = "The title says it all.",
	version     = PLUGIN_VERSION,
	url         = "sourcemod.net"
};

public void OnPluginStart()
{
	CreateConVar("sm_blockkillfeed_version", PLUGIN_VERSION, "Plugin's version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	cv_Enabled = CreateConVar("sm_blockkillfeed_enable", "1", "Enable/disable the plugin.\n(1 = Enable, 0 = Disable)", _, true, 0.0, true, 1.0);

	AutoExecConfig();

	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if (cv_Enabled.BoolValue)
	{
		event.BroadcastDisabled = true;
	}

	return Plugin_Continue;
}