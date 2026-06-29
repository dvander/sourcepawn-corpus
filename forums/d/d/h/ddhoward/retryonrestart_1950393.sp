#include <sourcemod>

#define COMMAND_NAME "sm_retryandrestart"
new bool:listening = true;
new Handle:cvar_enabled = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "Retry On Restart",
	author = "Franc1sco steam: franug",
	version = "1.1",
	description = "Force retry on restart",
	url = "www.uea-clan.com"
};

public OnPluginStart() {
	CreateConVar("sm_retryonrestart", "v1.0", _, FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	cvar_enabled = CreateConVar("sm_retryonrestart_enabled", "1", _, FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD);
   	RegServerCmd("quit", OnDown);
	RegServerCmd("_restart", OnDown);
	RegAdminCmd(COMMAND_NAME, RestartServerCmd, ADMFLAG_RCON, "Forces all players to RETRY connection, and restarts the server.");
	HookConVarChange(cvar_enabled, enabledCvarChange);
}

public OnConfigsExecuted() {
	listening = GetConVarBool(cvar_enabled);
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
	CreateTimer(0.1, DoRestart);
}

public Action:DoRestart(Handle:timer) {
	ServerCommand("_restart");
}

public enabledCvarChange(Handle:hHandle, const String:strOldValue[], const String:strNewValue[]) {
	listening = GetConVarBool(cvar_enabled);
}