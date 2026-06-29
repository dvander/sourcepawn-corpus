/**
 * Includes.
 */
#include <sourcemod>

/**
 * Defines.
 */
#define PLUGIN_VERSION		"0.2"

#pragma newdecls required

/**
 * Variables.
 */
ConVar g_cvTimerInterval = null;
ConVar g_cvCommand = null;

static Handle g_hCommandTime = null;
static char g_sCommand[128];

/**
 * Plugin Init.
 */
public Plugin myinfo =
{
	name = "[SM] AutoSendCommandConsole",
	author = "Kelvao",
	description = "#",
	version = PLUGIN_VERSION,
	url = "https://steamcommunity.com/id/kelviniano"
};

public void OnPluginStart()
{
	CreateConVar("sm_autosendcmdconsole_version", PLUGIN_VERSION, "Plugin Version", FCVAR_DONTRECORD|FCVAR_SPONLY|FCVAR_REPLICATED);
	g_cvTimerInterval = CreateConVar("sm_autosendcmdconsole_interval", "5", "Number of seconds used for the repeat timer (0 = disabled).", FCVAR_NOTIFY, true, 0.0);
	g_cvCommand = CreateConVar("sm_autosendcmdconsole_command", "sm_reloadadmins", "Command to send to the console (null = disabled)", FCVAR_NOTIFY);

	AutoExecConfig(true, "AutoSendCommandConsole");
	HookConVarChange(g_cvCommand, OnCommandChanged);
}

/**
 * Forwards.
 */
public void OnCommandChanged(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	// Update convar.
	g_cvCommand.GetString(g_sCommand, sizeof(g_sCommand));
}

public void OnConfigsExecuted()
{
	// Delete old timer.
	if (g_hCommandTime != null)
	{
		KillTimer(g_hCommandTime);
		g_hCommandTime = null;
	}

	// Initialize new timer if plugin are enabled.
	if (g_cvTimerInterval.BoolValue) {
		g_hCommandTime = CreateTimer(g_cvTimerInterval.FloatValue, Timer_SendCommand, _, TIMER_REPEAT);
	}

	// Get command convar.
	g_cvCommand.GetString(g_sCommand, sizeof(g_sCommand));
}

/**
 * Callbacks.
 */
public Action Timer_SendCommand(Handle timer)
{
	int clients = 0;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i)) {
			clients++;
		}
	}

	if (clients > 0 && !StrEqual(g_sCommand, "null", false)) {
		ServerCommand(g_sCommand);
	}

	return Plugin_Continue;
}