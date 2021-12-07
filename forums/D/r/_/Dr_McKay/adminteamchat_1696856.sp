#pragma semicolon 1

#include <sourcemod>
#include <colors>

#define PLUGIN_VERSION "1.0.0"

public Plugin:myinfo = {
	name = "[ANY] Admin Team Chat",
	author = "Dr. McKay",
	description = "Lets admins see all team chat",
	version = "1.0.0",
	url = "http://www.doctormckay.com"
};

public OnPluginStart() {
	RegConsoleCmd("say_team", Command_TeamSay);
}

public Action:Command_TeamSay(client, args) {
	decl String:argString[256];
	GetCmdArgString(argString, sizeof(argString));
	new team = GetClientTeam(client);
	for(new i = 1; i < MaxClients; i++) {
		if(!IsClientConnected(i) || !IsClientInGame(i) || IsFakeClient(i) || !CheckCommandAccess(client, "sm_say", ADMFLAG_CHAT) || GetClientTeam(i) == team) {
			continue;
		}
		CPrintToChatEx(i, client, "(TEAM) {teamcolor}%N {default}: %s", client, argString);
	}
	return Plugin_Continue;
}