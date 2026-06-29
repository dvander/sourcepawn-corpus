#include <sourcemod>
#define PLUGIN_VERSION "1.2"
#define COMMAND_NAME "sm_retryandrestart"
new bool:listening = true;
new Float:delay = 0.0;
new Handle:cvar_enabled = INVALID_HANDLE;
new Handle:cvar_delay = INVALID_HANDLE;
new Handle:cvar_version = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "Retry On Restart",
	author = "Franc1sco steam: franug",
	version = PLUGIN_VERSION,
	description = "Force retry on restart",
	url = "www.uea-clan.com"
};

public OnPluginStart() {
	cvar_version = CreateConVar("sm_retryonrestart", PLUGIN_VERSION, _, FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	cvar_enabled = CreateConVar("sm_retryonrestart_enabled", "1", _, FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	cvar_delay = CreateConVar("sm_retryonrestart_delay", "0.1", _, FCVAR_PLUGIN);
   	RegServerCmd("quit", OnDown);
	RegServerCmd("_restart", OnDown);
	RegAdminCmd(COMMAND_NAME, RestartServerCmd, ADMFLAG_RCON, "Forces all players to RETRY connection, and restarts the server.");
	HookConVarChange(cvar_enabled, cvarChange);
	HookConVarChange(cvar_delay, cvarChange);
	HookConVarChange(cvar_version, versionCvarChange);
}

public OnConfigsExecuted() {
	listening = GetConVarBool(cvar_enabled);
	delay = GetConVarFloat(cvar_delay);
	SetConVarString(cvar_version, PLUGIN_VERSION)
}
 
public Action:OnDown(args) {
	if (listening) {
		LogAction(-1, -1, "The server was restarted, attempted to reconnect all players.");
		for(new i = 1; i <= MaxClients; i++) {
			if (IsClientInGame(i) && !IsFakeClient(i)) {
					ClientCommand(i, "retry"); // force retry
			}
		}
	}
}

public Action:RestartServerCmd(client, args) {
	listening = false;
	new numargs = GetCmdArgs();
	new String:arg1[2]
	if (numargs > 0) {
		GetCmdArg(1, arg1, sizeof(arg1))
		if (StrEqual(arg1, "0")) {
			LogAction(client, -1, "\"%L\" restarted the server, and did not try to auto-reconnect all players.", client);
			ServerCommand("_restart");
		} else {
			RetryAndRestart(client);
		}
	} else {
		RetryAndRestart(client);
	}
	return Plugin_Handled
}

RetryAndRestart(client) {
	LogAction(client, -1, "\"%L\" restarted the server, attempting to reconnect all players.", client);
	for(new i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && !IsFakeClient(i)) {
            	ClientCommand(i, "retry"); // force retry
		}
	}
	if (delay == 0.0) {
		ServerCommand("_restart");
	} else {
		CreateTimer(delay, DoRestart);
	}
}

public Action:DoRestart(Handle:timer) {
	ServerCommand("_restart");
}

public cvarChange(Handle:hHandle, const String:strOldValue[], const String:strNewValue[]) {
	listening = GetConVarBool(cvar_enabled);
	delay = GetConVarFloat(cvar_delay);
}

public versionCvarChange(Handle:hHandle, const String:strOldValue[], const String:strNewValue[]) {
	SetConVarString(hHandle, PLUGIN_VERSION)
}