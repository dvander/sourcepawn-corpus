#pragma semicolon 1

#include <sourcemod>

native SBBanPlayer(client, target, time, const String:reason[]);

public Plugin:myinfo = {
	name		= "[ANY] SourceBans Listener",
	author      = "Dr. McKay",
	description = "Listens for player bans and converts them to SourceBans",
	version     = "1.0.1",
	url         = "http://www.doctormckay.com"
};


public Action:OnBanClient(client, time, flags, const String:reason[], const String:kick_message[], const String:command[], any:source) {
	if(StrEqual(command, "banid")) {
		return Plugin_Continue;
	}
	if(source < 0 || source > MaxClients) {
		return Plugin_Continue;
	}
	if(source > 0 && (!IsClientInGame(source) || GetUserAdmin(source) == INVALID_ADMIN_ID)) {
		return Plugin_Continue;
	}
	
	SBBanPlayer(source, client, time, reason);
	return Plugin_Handled;
}