#pragma semicolon 1

#include <sourcemod>

public OnClientPostAdminCheck(client) {
	if(CheckCommandAccess(client, "IsAdmin", ADMFLAG_GENERIC)) {
		PrintToChatAll("\x04ADMIN connected [%N]", client);
	}
}