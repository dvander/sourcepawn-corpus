#pragma semicolon 1
#include <sourcemod>

#include <sdktools_sound>

#pragma newdecls required

ConVar g_ShredAlertVolume;

public void OnPluginStart() {
	g_ShredAlertVolume = CreateConVar("sm_shred_alert_volume", "0.1",
			"Sets the volume of the Shred Alert taunt.");
	AddNormalSoundHook(OnShredAlertPlayed);
}

public Action OnShredAlertPlayed(int clients[MAXPLAYERS], int &numClients,
		char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level,
		int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed) {
	if (StrContains(sample, "brutal_legend_taunt.wav") != -1) {
		volume = g_ShredAlertVolume.FloatValue;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}
