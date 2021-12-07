#pragma semicolon 1

#include <sourcemod>

#define PLUGIN_VERSION		"1.1.0"

public Plugin:myinfo = {
	name        = "[ANY] Anti-Anti-Pinion",
	author      = "Dr. McKay",
	description = "Prevents clients from bypassing the Pinion timer",
	version     = PLUGIN_VERSION,
	url         = "http://www.doctormckay.com"
};

new bool:executedCommand[MAXPLAYERS + 1];

public OnPluginStart() {
	HookEvent("player_team", Event_PlayerTeam);
	AddCommandListener(Command_ClosedPage, "closed_htmlpage");
	CreateConVar("anti_anti_pinion_version", PLUGIN_VERSION, "Anti-Pinion-Bypass Version", FCVAR_NOTIFY);
}

public OnClientConnected(client) {
	executedCommand[client] = false;
}

public Action:Command_ClosedPage(client, const String:command[], argc) {
	executedCommand[client] = true;
}

public Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsFakeClient(client)) {
		return;
	}
	if(!executedCommand[client]) {
		CreateTimer(120.0, Timer_CheckCommand, GetClientUserId(client));
	}
}

public Action:Timer_CheckCommand(Handle:timer, any:userid) {
	new client = GetClientOfUserId(userid);
	if(client == 0) {
		return;
	}
	if(!executedCommand[client] && !CheckCommandAccess(client, "advertisement_immunity", ADMFLAG_RESERVATION)) {
		QueryClientConVar(client, "cl_disablehtmlmotd", OnConVarQueried);
	}
}

public OnConVarQueried(QueryCookie:cookie, client, ConVarQueryResult:result, const String:cvarName[], const String:cvarValue[]) {
	if(result == ConVarQuery_Okay && !bool:StringToInt(cvarValue)) {
		KickClient(client, "Please do not bypass our advertisement timer");
	}
}