#include <sourcemod>

#pragma semicolon 1
#pragma newdecls required

ConVar cvarConnectMessage;
ConVar cvarConnectTime;
ConVar cvarFailureMethod;
StringMap g_strmapAuthCount;

public Plugin myinfo = {
	name = "Force Auth",
	author = "JoinedSenses",
	description = "Forces players to authenticate by reconnecting them.",
	version = "1.0.0",
	url = ""
}

public void OnPluginStart() {
	cvarConnectMessage = CreateConVar("sm_forceauth_connect", "0", "Enable connect message until player has authenticated?", FCVAR_NONE, true, 0.0, true, 1.0);
	cvarConnectTime = CreateConVar("sm_forceauth_time", "10.0", "How many seconds to wait until checking that the client has authenticated.", FCVAR_NONE, true, 0.0);
	cvarFailureMethod = CreateConVar("sm_forceauth_method", "reconnect", "Method of dealing with clients who have failed to authenticate (Options: reconnect, kick");
	cvarFailureMethod.AddChangeHook(cvarChanged_FailureMethod);

	g_strmapAuthCount = new StringMap();

	HookEvent("player_connect", eventPlayerConnect, EventHookMode_Pre);
}

public void cvarChanged_FailureMethod(ConVar convar, const char[] oldValue, const char[] newValue) {
	if (!StrEqual(newValue, "reconnect", false) && !StrEqual(newValue, "kick", false)) {
		convar.SetString(oldValue);
		return;
	}
	convar.SetString(newValue);
}

public void OnMapEnd() {
	g_strmapAuthCount.Clear();
}

public void OnClientPostAdminCheck(int client) {
	if (cvarConnectMessage.BoolValue) {
		PrintToChatAll("%N connected", client);
	}	
}

public void OnClientPutInServer(int client) {
	CreateTimer(cvarConnectTime.FloatValue, timerCheckAuth, GetClientUserId(client));
}

public Action eventPlayerConnect(Event event, const char[] name, bool dontBroadcast) {
	if (cvarConnectMessage.BoolValue) {
		event.BroadcastDisabled = true;
	}

	return Plugin_Continue;
}

Action timerCheckAuth(Handle timer, int userid) {
	int client;
	if ((client = GetClientOfUserId(userid)) == 0 || IsFakeClient(client)) {
		return;
	}
	char clientName[MAX_NAME_LENGTH];
	Format(clientName, sizeof(clientName), "%N", client);

	int count;
	if (!IsClientAuthorized(client)) {
		char dealMethod[10];
		cvarFailureMethod.GetString(dealMethod, sizeof(dealMethod));
		
		bool exceededConnectCount;
		bool reconnect;
		if ((reconnect = StrEqual(dealMethod, "reconnect", false))) {
			if (g_strmapAuthCount.GetValue(clientName, count)) {
				if (++count > 2) {
					exceededConnectCount = true;
					g_strmapAuthCount.Remove(clientName);
				}
				else {
					g_strmapAuthCount.SetValue(clientName, count);
				}
			}
			else {
				g_strmapAuthCount.SetValue(clientName, 1);
			}
		}

		if (exceededConnectCount || StrEqual(dealMethod, "kick", false)) {
			LogError("%N failed to authenticate. Kicking.", client);
			KickClient(client, "Authentication failure");
		}
		else if (reconnect) {
			CreateTimer(5.0, timerReconnect, GetClientUserId(client));
			if (cvarConnectTime.FloatValue >= 5.0) {
				PrintToChat(client, "Failed to authenticate. Reconnecting in 5 seconds.");
			}
		}
		else {
			LogError("Unknown auth failure method (%s) for sm_forceauth_method. Options are reconnect or kick.", dealMethod);
		}
	}
	else if (g_strmapAuthCount.GetValue(clientName, count)) {
		g_strmapAuthCount.Remove(clientName);
	}
}

Action timerReconnect(Handle timer, int userid) {
	int client;
	if ((client = GetClientOfUserId(userid) > 0)) {
		LogError("%N failed to authenticate. Reconnecting.", client);
		ClientCommand(client, "retry");	
	}
}