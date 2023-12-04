#define PLUGIN_VERSION	"1.0.1"
#define PLUGIN_NAME		"l4d2_no_fail_lite"

/**
 *	v1.0 just releases; 16-March-2022
 *	v1.0.1 support online compile; 16-March-2022
 */

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>

native void L4D2_FullRestart();
native bool L4D_IsCoopMode();
native bool L4D2_IsRealismMode();

ConVar Enabled;

public Plugin myinfo = {
	name = "[L4D2] No Fail Lite",
	author = "NoroHime",
	description = "we have to be a little challenged",
	version = PLUGIN_VERSION,
	url = "https://steamcommunity.com/id/NoroHime/"
}

public void OnPluginStart() {

	Enabled = 					CreateConVar("no_fail_enabled", "1",		"Enabled 'No Fail Lite'", FCVAR_NOTIFY);
	AutoExecConfig(true, PLUGIN_NAME);
	HookEvent("mission_lost", OnMissionLost, EventHookMode_PostNoCopy);
}

public void OnMissionLost(Event event, const char[] name, bool dontBroadcast) {

	if ( (L4D_IsCoopMode() || L4D2_IsRealismMode()) && Enabled.BoolValue)
		L4D2_FullRestart();
}
