#include <sdktools>

#define PLUGIN_VERSION "1.0.1"
public Plugin myinfo = {
    name = "Trigger Teleport Velocity",
    author = "Mitchell",
    description = "Sets the player's velocity to zero after teleporting.",
    version = PLUGIN_VERSION,
    url = "mtch.tech"
};

float emptyVec[3];
ConVar enabled;

public void OnPluginStart() {
	CreateConVar("sm_trigtele_version", PLUGIN_VERSION, "Trigger Teleport Velocity Version", FCVAR_DONTRECORD);
	enabled = CreateConVar("sm_trigtele_enable", "0", "Set the player's velocity to 0 on teleport");
	AutoExecConfig();
	HookEntityOutput("trigger_teleport", "OnTrigger", teleTrigger);
}

public void teleTrigger(const char[] output, int caller, int activator, float delay) {
	if(activator > 0 && activator <= MaxClients && IsPlayerAlive(activator) && enabled.BoolValue) {
		TeleportEntity(activator, NULL_VECTOR, NULL_VECTOR, emptyVec);
	}
}