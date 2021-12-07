#pragma semicolon 1
#define PLUGIN_VERSION "13.0523"
new Handle:hcvar_version = INVALID_HANDLE;

public Plugin:myinfo = {
	name = "[TF2] Print Building Destruction to Console",
	author = "Derek D. Howard",
	description = "Prints the destruction of buildings to the console, just like when players die.",
	version = "PLUGIN_VERSION",
	url = "https://forums.alliedmods.net/showthread.php?t=216666"
};

public APLRes:AskPluginLoad2(Handle:hMyself, bool:bLate, String:strError[], iErr_Max)
{
	new String:strGame[32];
	GetGameFolderName(strGame, sizeof(strGame));
	if(!StrEqual(strGame, "tf")) {
		Format(strError, iErr_Max, "This plugin only works for Team Fortress 2!");
		return APLRes_Failure;
	}
	return APLRes_Success;
}

public OnPluginStart() {
	hcvar_version = CreateConVar("sm_buildingkilltoconsole_version", PLUGIN_VERSION, "Building Destruction to Console Plugin Version", FCVAR_DONTRECORD|FCVAR_NOTIFY|FCVAR_CHEAT|FCVAR_PLUGIN);
	SetConVarString(hcvar_version, PLUGIN_VERSION);
	HookConVarChange(hcvar_version, cvarChange);
	HookEvent("object_destroyed", OnBuildingDestroyed);
}

public OnBuildingDestroyed(Handle:event, const String:name[], bool:dontBroadcast) {
	new engie = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new building = GetEventInt(event, "objecttype");
	new String:weaponstring[32];
	GetEventString(event, "weapon", weaponstring, sizeof(weaponstring));
	new String:buildingstring[20];
	if (building == 0) {
		buildingstring = "dispenser";
	} else if (building == 1) {
		buildingstring = "teleporter";
	} else if (building == 2) {
		buildingstring = "sentry";
	}
	if (engie > 0 && engie <= MaxClients && attacker > 0 && attacker <= MaxClients && building >= 0 && building <= 2) {
		for (new i=1; i <= MaxClients; i++) {
			if (IsClientInGame(i)) {
				PrintToConsole(i, "%N killed %N's %s with %s.", attacker, engie, buildingstring, weaponstring);
			}
		}
	}
}

public cvarChange(Handle:hHandle, const String:strOldValue[], const String:strNewValue[]) {
	if (hHandle == hcvar_version) {
		SetConVarString(hcvar_version, PLUGIN_VERSION);
	}
}