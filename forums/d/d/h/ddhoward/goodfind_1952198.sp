#define PLUGIN_VERSION "1.0"

#include <sourcemod>
#include <sdktools>
#include <colors>

new Handle:cvar_string = INVALID_HANDLE;
new Handle:cvar_type = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "[TF2] GOOD FIND GOOD FIND GOOD FIND",
	author = "Derek D. Howard",
	description = "GOOD FIND",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=215982"
};

public OnPluginStart() {
	HookEvent("item_found", OnItemFound);
	cvar_string = CreateConVar("sm_goodfind_string", "good find.", "Sets the string to display. Supports colors through colors.inc", FCVAR_PLUGIN);
	cvar_type = CreateConVar("sm_goodfind_type", "-1", "What type of find to look for? -1 to disable plugin. 0 for drops, 1 for traded items, etc.", FCVAR_PLUGIN);
}

public OnItemFound(Handle:event, const String:name[], bool:dontBroadcast) {
	if (GetConVarInt(cvar_type) > -1) {
		new method = GetEventInt(event, "method");
		if (method == GetConVarInt(cvar_type)) {
			new String:message[250];
			GetConVarString(cvar_string, message, sizeof(message));
			CPrintToChatAll("%s", message);
		}
	}
}