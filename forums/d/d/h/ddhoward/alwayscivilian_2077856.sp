#include <tf2_stocks>

#define PLUGIN_VERSION "13.1229.0"

new Handle:cvar_version = INVALID_HANDLE;
new Handle:cvar_enabled = INVALID_HANDLE;

public Plugin:myinfo = {
	name = "[TF2] Always Civilian",
	author = "Derek D. Howard",
	description = "No weapons. EVAR.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=232318"
}

public APLRes:AskPluginLoad2(Handle:hMyself, bool:bLate, String:strError[], iErr_Max) {
	new String:strGame[32];
	GetGameFolderName(strGame, sizeof(strGame));
	if(!StrEqual(strGame, "tf")) {
		Format(strError, iErr_Max, "This plugin only works for Team Fortress 2.");
		return APLRes_Failure;
	}
	return APLRes_Success;
}

public OnPluginStart() {
	cvar_version = CreateConVar("sm_alwayscivilian_version", PLUGIN_VERSION, "Plugin Version", FCVAR_DONTRECORD|FCVAR_NOTIFY|FCVAR_CHEAT|FCVAR_PLUGIN);
	SetConVarString(cvar_version, PLUGIN_VERSION);
	HookConVarChange(cvar_version, cvarChange);
	
	cvar_enabled = CreateConVar("sm_alwayscivilian_enabled", "1", "0 to disable the plugin, 1 to enable", FCVAR_PLUGIN);
	
	HookEvent("post_inventory_application", Inventory_App, EventHookMode_Post);
}

public cvarChange(Handle:hHandle, const String:oldValue[], const String:newValue[]) {
	if (hHandle == cvar_version) {
		SetConVarString(hHandle, PLUGIN_VERSION);
	}
}

public Action:Inventory_App(Handle:event, const String:name[], bool:dontBroadcast) {
	if (GetConVarBool(cvar_enabled)) {
		new clientUserID = GetEventInt(event, "userid");
		CreateTimer(0.1, RemoveAllWeapons, clientUserID);
	}
}

public Action:RemoveAllWeapons(Handle:timer, any:clientUserID) {
	new client = GetClientOfUserId(clientUserID);
	if (client < 1 || client > MaxClients || !IsClientInGame(client))
		return;
	TF2_RemoveAllWeapons(client);
}